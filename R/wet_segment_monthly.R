#' Monthly and annual flow on FWA segments
#'
#' Reads mean flow per month on Freshwater Atlas stream segments, by source,
#' in the shape of [wet_station_monthly()] (`month` 1-12, and 0 for the mean
#' annual flow), so a gauge comparison is a join on `month` after
#' [wet_station_snap()].
#'
#' @section Where the values come from:
#' With `from = "published"` (the default) the values are wet's published
#' product, `discharge/fwa/v1/segment_monthly` ([wet_catalog()]): from the
#' Postgres table `discharge.fwa_v1_segment_monthly` that [wet_db_load()]
#' writes when `conn` is given, otherwise straight from the parquet parts the
#' manifest lists, through duckdb. Its routed month 0 is the plain mean of
#' the twelve months, and fresh joins the same rows.
#'
#' With `from = "fwapg"`, `pcic_routed` is read from fwapg's own routed table
#' (`pcic.discharge_monthly`), the run PCIC's hydromosaic made with PNWNAmet
#' forcing, `historical`, averaged over 1981-2010 (`model`, `scenario` and
#' `period` `PNWNAmet`, `historical`, `1981-2010`), with month 0 computed by
#' the same rule as the published one: the mean of the twelve months, `NA`
#' unless all twelve have flow. That table is loaded by the
#' NewGraphEnvironment fork of fwapg (`load/pcic_schema.sql`, `load/pcic.sql`,
#' then `load/pcic_run.sql` per run), not by upstream fwapg; a table without
#' the run's rows is an error. Scoring the table before it is published
#' (`scripts/pcic_routed_compare.R`) reads it this way.
#'
#' Reading parts with no `groups` reads the segment ID column of every part
#' (about half a minute for a few segments over HTTPS, and nearly the whole
#' 1.8 GB for many). The parts are sorted by watershed group, so naming the
#' groups that hold the segments keeps a read to seconds. Parts are read in
#' place, unlike [wet_db_load()], which checks each one's size and md5 first:
#' a read during a publish can mix two builds, so retry once it completes.
#'
#' @param conn `NULL`, or a [DBI::DBIConnection-class] to Postgres: the
#'   database [wet_db_load()] wrote to for `from = "published"`, fwapg for
#'   `from = "fwapg"`.
#' @param segments `linear_feature_id`s. Repeats are read once.
#' @param source Any of `"pcic_routed"` (PCIC's routed flow placed on the
#'   FWA) and `"wet_balance"` (wet's open water balance). Left out, every
#'   source `from` holds: both for `"published"`, `"pcic_routed"` for
#'   `"fwapg"`.
#' @param from `"published"` or `"fwapg"`, as described above.
#' @param scenario Scenario of the published product, e.g. `"historical"`.
#'   fwapg's run is `"historical"` only.
#' @param groups Optional watershed group codes that hold the segments. A
#'   segment outside them reads as missing.
#' @param catalog For parts read without `conn`: the output of
#'   [wet_catalog()], which is read when `NULL`.
#' @return `data.frame(linear_feature_id, month, q_m3s, source)`, ordered by
#'   source as given, segment as given and month. A segment with no value for
#'   a source has all 13 rows, with `q_m3s` `NA`, so missing coverage stays
#'   visible after a join.
#' @seealso [wet_flow_window()] for flow over a date window;
#'   [wet_station_monthly()] for the gauge's side of a comparison.
#' @examples
#' \dontrun{
#' # Buck Creek at its mouth, where gauge 08EE013 sits, from the published
#' # parts over HTTPS (about 3 s)
#' q <- wet_segment_monthly(NULL, 17094080, groups = "BULK")
#' reshape(q[q$month > 0, ], idvar = c("linear_feature_id", "month"),
#'         timevar = "source", direction = "wide")
#'
#' # the same from Postgres, after wet_db_load()
#' conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
#' wet_segment_monthly(conn, 17094080)
#' }
#' @export
wet_segment_monthly <- function(conn, segments, source = c("pcic_routed", "wet_balance"),
                                from = c("published", "fwapg"), scenario = "historical",
                                groups = NULL, catalog = NULL) {
  from <- match.arg(from)
  if (missing(source)) source <- NULL
  wet_segment_read(conn, "discharge/fwa/v1/segment_monthly", segments, source, from, scenario, groups, catalog)
}

# Where each source's values are, by store: a published dataset ID or a
# database table, what loads it (for the error when it is missing), and for a
# table that holds several runs, the run read (model, scenario, period; NA
# where the store has no runs). The one place a source is mapped to a table
# and a run.
wet_segment_sources <- function(dataset) {
  out <- data.frame(
    from = "published", source = c("pcic_routed", "wet_balance"), location = dataset,
    origin = "wet's published product (wet_catalog(), loaded into Postgres by wet_db_load())",
    model = NA_character_, scenario = NA_character_, period = NA_character_
  )
  if (wet_timebase(dataset)$col == "month") {
    out <- rbind(out, data.frame(
      from = "fwapg", source = "pcic_routed", location = "pcic.discharge_monthly",
      origin = paste("the NewGraphEnvironment fork of fwapg (its newgraph branch, NewGraphEnvironment/fwapg#25):",
                     "load/pcic_schema.sql, load/pcic.sql, then load/pcic_run.sql for each run;",
                     "upstream fwapg does not load it"),
      model = "PNWNAmet", scenario = "historical", period = "1981-2010"
    ))
  }
  out
}

# The time column a dataset's timebase gives, and its values.
wet_timebase <- function(dataset) {
  tb <- sub("^.*_", "", wet_dataset_table(dataset)[["table"]])
  switch(tb,
         monthly = list(col = "month", values = 0:12),
         daily = list(col = "doy", values = 1:365),
         stop("no reader for the ", tb, " timebase of ", dataset, call. = FALSE))
}

# The reader behind wet_segment_monthly(): one dataset ID, any store. Returns
# every source x segment x time value, NA where there is none.
wet_segment_read <- function(conn, dataset, segments, source, from, scenario, groups, catalog) {
  if (!is.numeric(segments) || anyNA(segments) || any(segments != round(segments))) {
    stop("`segments` must be whole-number linear_feature_ids, none NA", call. = FALSE)
  }
  ids <- unique(as.integer(segments))
  stopifnot(is.character(scenario), length(scenario) == 1L, !is.na(scenario))
  if (!is.null(groups) && (!is.character(groups) || !length(groups) || anyNA(groups))) {
    stop("`groups` must be NULL or watershed group codes, none NA", call. = FALSE)
  }
  if (from == "fwapg" && is.null(conn)) stop("from = \"fwapg\" needs `conn`, a connection to fwapg", call. = FALSE)
  tb <- wet_timebase(dataset)
  # a daily part holds one watershed group, and segment IDs do not sort by
  # group, so without groups a read of the parts would fetch all of them
  if (tb$col == "doy" && is.null(conn) && from == "published" && is.null(groups)) {
    stop("reading ", dataset, " from its parts needs `groups`, the watershed groups that hold the segments",
         call. = FALSE)
  }
  lk <- wet_segment_sources(dataset)
  lk <- lk[lk$from == from, , drop = FALSE]
  if (is.null(source)) source <- lk$source
  if (!is.character(source) || !length(source) || anyNA(source) || anyDuplicated(source) ||
        !all(source %in% lk$source)) {
    stop("`source` must be some of ", paste(lk$source, collapse = ", "), " for from = \"", from, "\"; got ",
         paste(source, collapse = ", "), call. = FALSE)
  }

  grid <- expand.grid(t = tb$values, linear_feature_id = ids, source = source, stringsAsFactors = FALSE,
                      KEEP.OUT.ATTRS = FALSE)
  grid <- grid[c("linear_feature_id", "t", "source")]
  names(grid)[2] <- tb$col
  if (!length(ids)) return(cbind(grid[c("linear_feature_id", tb$col)], q_m3s = numeric(), grid["source"]))

  got <- if (from == "fwapg") {
    wet_segment_fwapg(conn, lk[match(source, lk$source), , drop = FALSE], ids, scenario, groups)
  } else if (is.null(conn)) {
    wet_segment_parts(dataset, ids, source, scenario, groups, catalog)
  } else {
    wet_segment_pg(conn, dataset, ids, source, scenario, groups)
  }
  got$linear_feature_id <- as.integer(got$linear_feature_id)
  got[[tb$col]] <- as.integer(got[[tb$col]])
  if (!all(got[[tb$col]] %in% tb$values)) stop(dataset, " has a ", tb$col, " outside its timebase", call. = FALSE)
  key <- function(d) paste(d$source, d$linear_feature_id, d[[tb$col]])
  k <- key(got)
  if (anyDuplicated(k)) {
    d <- got[duplicated(k), ][1, ]
    stop(dataset, " has more than one row for source ", d$source, ", segment ", d$linear_feature_id, ", ",
         tb$col, " ", d[[tb$col]], " in scenario ", scenario, call. = FALSE)
  }
  grid$q_m3s <- as.numeric(got$q_m3s[match(key(grid), k)])
  out <- grid[c("linear_feature_id", tb$col, "q_m3s", "source")]
  rownames(out) <- NULL
  out
}

wet_sql_in <- function(conn, x) {
  if (is.character(x)) paste(DBI::dbQuoteString(conn, x), collapse = ", ") else paste(x, collapse = ", ")
}

# the optional watershed-group filter, every table and part carrying the column
wet_sql_groups <- function(conn, groups) {
  if (is.null(groups)) "" else sprintf(" AND watershed_group_code IN (%s)", wet_sql_in(conn, groups))
}

# The filter on one run of a table keyed by run (wet_segment_sources()).
wet_sql_run <- function(conn, lk) {
  sprintf("(model, scenario, period) = (%s)", wet_sql_in(conn, c(lk$model, lk$scenario, lk$period)))
}

# The published dataset from the Postgres table wet_db_load() writes.
wet_segment_pg <- function(conn, dataset, ids, source, scenario, groups) {
  tbl <- wet_dataset_table(dataset)
  name <- paste(tbl, collapse = ".")
  id <- DBI::Id(schema = tbl[["schema"]], table = tbl[["table"]])
  if (!DBI::dbExistsTable(conn, id)) {
    stop(name, " does not exist: load it with wet_db_load(conn, wet_catalog(), \"", dataset, "\")", call. = FALSE)
  }
  qid <- DBI::dbQuoteIdentifier(conn, id)
  comment <- DBI::dbGetQuery(conn, "SELECT obj_description(to_regclass($1), 'pg_class') AS c",
                             params = list(as.character(qid)))$c
  if (length(comment) && !is.na(comment) && grepl("; subset ", comment, fixed = TRUE)) {
    warning(name, " was loaded as a subset (", sub("^.*; subset ", "", comment),
            "): a row outside it reads as missing", call. = FALSE)
  }
  # an unloaded scenario or source would read as every segment missing. The
  # loaded sources come from a walk of the key's distinct (forcing, source)
  # pairs, one index seek each: a DISTINCT, or an EXISTS whose source sits
  # behind another's rows in the table, would scan the table
  have <- DBI::dbGetQuery(conn, sprintf(
    "WITH RECURSIVE p AS (
       (SELECT forcing, source FROM %1$s WHERE scenario = %2$s ORDER BY forcing, source LIMIT 1)
       UNION ALL
       SELECT n.forcing, n.source FROM p, LATERAL (
         SELECT t.forcing, t.source FROM %1$s t
         WHERE t.scenario = %2$s AND (t.forcing, t.source) > (p.forcing, p.source)
         ORDER BY t.forcing, t.source LIMIT 1) n
     ) SELECT DISTINCT source FROM p",
    qid, DBI::dbQuoteString(conn, scenario)
  ))$source
  absent <- setdiff(source, have)
  if (length(absent)) {
    stop(name, " has no rows for scenario ", scenario, ", source ", paste(absent, collapse = ", "),
         ": load it with wet_db_load(conn, wet_catalog(), \"", dataset, "\", scenario = \"", scenario, "\")",
         call. = FALSE)
  }
  sql <- sprintf(
    "SELECT linear_feature_id, %s, q_m3s, source FROM %s
     WHERE scenario = %s AND source IN (%s) AND linear_feature_id IN (%s)%s",
    wet_timebase(dataset)$col, qid, DBI::dbQuoteString(conn, scenario), wet_sql_in(conn, source),
    wet_sql_in(conn, ids), wet_sql_groups(conn, groups)
  )
  DBI::dbGetQuery(conn, sql)
}

# The published dataset straight from its parquet parts.
wet_segment_parts <- function(dataset, ids, source, scenario, groups, catalog) {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("install duckdb to read the parquet parts, or pass `conn` after wet_db_load()", call. = FALSE)
  }
  if (is.null(catalog)) catalog <- wet_catalog()
  parts <- catalog[catalog$dataset == dataset & catalog$scenario == scenario, , drop = FALSE]
  if (!nrow(parts)) {
    stop("the catalog has no parts for ", dataset, " ", scenario, "; it has: ",
         paste(unique(paste(catalog$dataset, catalog$scenario)), collapse = "; "), call. = FALSE)
  }
  absent <- setdiff(source, parts$source)
  if (length(absent)) {
    stop("the catalog has no ", dataset, " ", scenario, " parts for source ", paste(absent, collapse = ", "),
         call. = FALSE)
  }
  parts <- wet_parts_groups(parts, groups)
  col <- wet_timebase(dataset)$col
  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE), add = TRUE)
  if (any(grepl("^https?://", parts$href))) DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;")
  out <- lapply(source, function(s) {
    href <- parts$href[parts$source == s]
    # a source whose groups hold no part has no rows there
    if (!length(href)) {
      return(stats::setNames(data.frame(integer(), integer(), numeric(), character()),
                             c("linear_feature_id", col, "q_m3s", "source")))
    }
    # the keys come from the catalog, as in wet_db_load()
    sql <- sprintf(
      "SELECT linear_feature_id, %s, q_m3s FROM read_parquet([%s], hive_partitioning = false)
       WHERE linear_feature_id IN (%s)%s",
      col, wet_sql_in(duck, href), wet_sql_in(duck, ids), wet_sql_groups(duck, groups)
    )
    d <- DBI::dbGetQuery(duck, sql)
    if (nrow(d)) d$source <- s else d$source <- character()
    d
  })
  do.call(rbind, out)
}

# The parts that can hold `groups`: a part keyed by watershed group (a daily
# dataset's) only where its group is named; a part keyed by drainage code
# holds many groups, so all of those.
wet_parts_groups <- function(parts, groups) {
  by_group <- grepl("^[A-Z]{4}$", parts$code)
  if (is.null(groups)) return(parts)
  parts[!by_group | parts$code %in% groups, , drop = FALSE]
}

# pcic_routed from fwapg's routed table, the run wet_segment_sources() names,
# month 0 by the published rule. `lk` is that lookup's row for the source.
wet_segment_fwapg <- function(conn, lk, ids, scenario, groups) {
  stopifnot(nrow(lk) == 1L)
  if (scenario != lk$scenario) {
    stop("fwapg's routed run is the ", lk$scenario, " scenario only, not ", scenario, call. = FALSE)
  }
  there <- DBI::dbGetQuery(conn, "SELECT to_regclass($1) IS NOT NULL AS ok", params = list(lk$location))$ok
  if (!isTRUE(there)) stop(lk$location, " does not exist: it is loaded by ", lk$origin, call. = FALSE)
  run <- wet_sql_run(conn, lk)
  # a run never loaded would read as every segment missing; the run is the
  # primary key's prefix, so this is one index seek
  have <- DBI::dbGetQuery(conn, sprintf("SELECT EXISTS (SELECT 1 FROM %s WHERE %s) AS ok", lk$location, run))$ok
  if (!isTRUE(have)) {
    stop(lk$location, " has no rows for the run ", paste(lk$model, lk$scenario, lk$period),
         ": load it with fwapg's load/pcic_run.sql (", lk$origin, ")", call. = FALSE)
  }
  sql <- sprintf(
    "SELECT linear_feature_id::int AS linear_feature_id, month::int AS month, q_m3s FROM %s
     WHERE %s AND linear_feature_id IN (%s) AND month BETWEEN 1 AND 12%s
     ORDER BY 1, 2",
    lk$location, run, wet_sql_in(conn, ids), wet_sql_groups(conn, groups)
  )
  d <- DBI::dbGetQuery(conn, sql)
  d <- rbind(d, wet_segment_annual(d))
  d$source <- rep("pcic_routed", nrow(d))
  d
}

# Month 0 as the published product defines it: the plain mean of months 1-12,
# NA unless all twelve have flow. The mean adds the months in the order given,
# so callers pass them in month order, as scripts/segment_output.R sums them.
wet_segment_annual <- function(d) {
  d <- d[d$month %in% 1:12, , drop = FALSE]
  ids <- unique(d$linear_feature_id)
  by_id <- split(d$q_m3s, factor(d$linear_feature_id, levels = ids))
  q <- vapply(by_id, function(v) if (length(v) == 12L && !anyNA(v)) mean(v) else NA_real_, 0, USE.NAMES = FALSE)
  data.frame(linear_feature_id = ids, month = rep(0L, length(ids)), q_m3s = q)
}
