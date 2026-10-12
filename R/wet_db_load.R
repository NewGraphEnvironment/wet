#' Load one scenario of published discharge into Postgres
#'
#' Fetches the parts of one dataset and scenario listed by [wet_catalog()],
#' checks each against the manifest's size and md5, and writes them to the
#' Postgres table the dataset ID names: `discharge/fwa/v1/segment_monthly`
#' becomes `discharge.fwa_v1_segment_monthly`. The scenario's rows already in
#' the table are replaced, in one transaction, so a reload never duplicates
#' and a failed load leaves the table as it was.
#'
#' A load with `months` or `pick_only` set still replaces the whole
#' scenario, so it leaves only that subset for every reader of the table; the
#' table comment records it.
#'
#' The table holds the files' columns plus `scenario`, `forcing` and
#' `source`. Where the dataset has `pick`, the load is refused unless each
#' feature and month has at most one picked row in the scenario. On the first load it is created with a primary key on
#' `(scenario, forcing, source, <id>, month, period)` and an index on the
#' feature ID. fresh then joins the default annual flow per segment with
#' `frs_col_join(from = "(select linear_feature_id, q_m3s as mad_m3s from
#' discharge.fwa_v1_segment_monthly where scenario = 'historical' and
#' month = 0 and pick)")`.
#'
#' @param conn A [DBI::DBIConnection-class] to Postgres (RPostgres).
#' @param catalog The parts, from [wet_catalog()].
#' @param dataset Dataset ID, e.g. `"discharge/fwa/v1/segment_monthly"`.
#' @param scenario Scenario to load, e.g. `"historical"`.
#' @param months Months to keep, from `0` (annual) to `12`.
#' @param pick_only Keep only the default source's rows (`pick`), about half
#'   the segment table. Datasets without `pick` refuse it.
#' @param cache_dir Where fetched parts are kept between loads. A cached part
#'   is reused only while its md5 matches the manifest.
#' @return Invisibly, `data.frame(key, rows)`: the rows loaded from each part.
#' @seealso [wet_catalog()]
#' @examples
#' \dontrun{
#' conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
#' wet_db_load(conn, wet_catalog())
#' DBI::dbGetQuery(conn, "
#'   select linear_feature_id, q_m3s as mad_m3s
#'   from discharge.fwa_v1_segment_monthly
#'   where scenario = 'historical' and month = 0 and pick
#'   limit 5")
#' }
#' @export
wet_db_load <- function(conn, catalog, dataset = "discharge/fwa/v1/segment_monthly",
                        scenario = "historical", months = 0:12, pick_only = FALSE,
                        cache_dir = tools::R_user_dir("wet", "cache")) {
  if (!requireNamespace("duckdb", quietly = TRUE)) {
    stop("install duckdb to read the parquet parts", call. = FALSE)
  }
  stopifnot(is.character(dataset), length(dataset) == 1L, is.character(scenario), length(scenario) == 1L,
            is.numeric(months), length(months) > 0L, all(months %in% 0:12), !anyNA(months),
            isTRUE(pick_only) || isFALSE(pick_only))
  tbl <- wet_dataset_table(dataset)
  parts <- catalog[catalog$dataset == dataset & catalog$scenario == scenario, , drop = FALSE]
  if (!nrow(parts)) {
    have <- unique(paste(catalog$dataset, catalog$scenario))
    stop("the catalog has no parts for ", dataset, " ", scenario, "; it has: ",
         paste(have, collapse = "; "), call. = FALSE)
  }
  paths <- vapply(seq_len(nrow(parts)), function(i) wet_part_fetch(parts[i, ], cache_dir), "")

  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE), add = TRUE)
  # the keys come from the catalog: duckdb would otherwise read them out of a
  # local path that is laid out as the tree
  cols <- DBI::dbGetQuery(duck, "SELECT * FROM read_parquet(?, hive_partitioning = false) LIMIT 0",
                          params = list(paths[1]))
  if (pick_only && !"pick" %in% names(cols)) stop(dataset, " has no `pick` column", call. = FALSE)
  id_col <- grep("_feature_id$", names(cols), value = TRUE)
  if (length(id_col) != 1L) stop(dataset, ": expected one *_feature_id column", call. = FALSE)
  template <- cbind(data.frame(scenario = character(), forcing = character(), source = character()), cols)

  where <- sprintf("month IN (%s)%s", paste(as.integer(months), collapse = ", "),
                   if (pick_only) " AND pick" else "")
  id <- DBI::Id(schema = tbl[["schema"]], table = tbl[["table"]])
  qid <- DBI::dbQuoteIdentifier(conn, id)
  loaded <- DBI::dbWithTransaction(conn, {
    DBI::dbExecute(conn, paste("CREATE SCHEMA IF NOT EXISTS", DBI::dbQuoteIdentifier(conn, tbl[["schema"]])))
    created <- !DBI::dbExistsTable(conn, id)
    if (created) {
      DBI::dbCreateTable(conn, id, template)
    } else {
      have <- DBI::dbListFields(conn, id)
      if (!setequal(have, names(template))) {
        stop(paste(tbl, collapse = "."), " has columns ", paste(have, collapse = ", "),
             ", but the parts give ", paste(names(template), collapse = ", "),
             ": a new schema version belongs in a new table", call. = FALSE)
      }
    }
    DBI::dbExecute(conn, paste("DELETE FROM", qid, "WHERE scenario = $1"), params = list(scenario))
    n <- numeric(nrow(parts))
    for (i in seq_len(nrow(parts))) {
      res <- DBI::dbSendQuery(duck, sprintf("SELECT * FROM read_parquet(?, hive_partitioning = false) WHERE %s", where),
                              params = list(paths[i]))
      while (!DBI::dbHasCompleted(res)) {
        chunk <- DBI::dbFetch(res, n = 1e6)
        if (!nrow(chunk)) next
        chunk <- cbind(data.frame(scenario = scenario, forcing = parts$forcing[i], source = parts$source[i]),
                       chunk)
        DBI::dbAppendTable(conn, id, chunk[names(template)])
        n[i] <- n[i] + nrow(chunk)
      }
      DBI::dbClearResult(res)
    }
    got <- DBI::dbGetQuery(conn, paste("SELECT count(*)::float8 AS n FROM", qid, "WHERE scenario = $1"),
                           params = list(scenario))$n
    if (got != sum(n)) stop("loaded ", got, " rows but read ", sum(n), call. = FALSE)
    if ("pick" %in% names(cols)) {
      # the default is one source per feature and month within a scenario
      dup <- DBI::dbGetQuery(conn, sprintf(
        "SELECT %s AS id, month FROM %s WHERE scenario = $1 AND pick GROUP BY 1, 2 HAVING count(*) > 1 LIMIT 1",
        DBI::dbQuoteIdentifier(conn, id_col), qid), params = list(scenario))
      if (nrow(dup)) {
        stop(id_col, " ", dup$id, " month ", dup$month, " has more than one picked row", call. = FALSE)
      }
    }
    if (created) {
      key_cols <- c("scenario", "forcing", "source", id_col, "month", "period")
      DBI::dbExecute(conn, sprintf("ALTER TABLE %s ADD PRIMARY KEY (%s)", qid,
                                   paste(DBI::dbQuoteIdentifier(conn, key_cols), collapse = ", ")))
      DBI::dbExecute(conn, sprintf("CREATE INDEX ON %s (%s)", qid, DBI::dbQuoteIdentifier(conn, id_col)))
    }
    DBI::dbExecute(conn, sprintf(
      "COMMENT ON TABLE %s IS %s", qid,
      DBI::dbQuoteLiteral(conn, sprintf(
        "wet_db_load(): %s, scenario %s last loaded from %s (built %s, wet %s)%s",
        dataset, scenario, attr(catalog, "manifest") %||% "?", attr(catalog, "built") %||% "?",
        attr(catalog, "provenance")$wet_commit %||% "?",
        if (pick_only || !setequal(months, 0:12)) paste0("; subset ", where) else ""
      ))
    ))
    data.frame(key = parts$key, rows = n, stringsAsFactors = FALSE)
  })
  invisible(loaded)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# "discharge/fwa/v1/segment_monthly" -> schema "discharge", table "fwa_v1_segment_monthly"
wet_dataset_table <- function(dataset) {
  re <- "^([a-z][a-z_]*)/([a-z][a-z0-9]*)/(v[0-9]+)/([a-z]+_[a-z]+)$"
  if (!is.character(dataset) || length(dataset) != 1L || !grepl(re, dataset)) {
    stop("a dataset ID is `<variable>/<network>/v<n>/<unit>_<timebase>`; got ",
         paste(format(dataset), collapse = " "), call. = FALSE)
  }
  c(schema = sub(re, "\\1", dataset), table = sub(re, "\\2_\\3_\\4", dataset))
}

# One part as a local file whose size and md5 match the manifest: a local
# href is checked in place, a URL is fetched into the cache (reused while it
# still matches).
wet_part_fetch <- function(part, cache_dir) {
  ok <- function(f) {
    file.exists(f) && file.size(f) == part$bytes && unname(tools::md5sum(f)) == part$md5
  }
  if (!grepl("^https?://", part$href)) {
    if (!ok(part$href)) stop(part$href, " does not match the manifest's size and md5", call. = FALSE)
    return(part$href)
  }
  dest <- file.path(cache_dir, sub("/[^/]*$", "", part$dataset), part$key)
  if (ok(dest)) return(dest)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  tmp <- paste0(dest, ".part")
  on.exit(unlink(tmp), add = TRUE)
  r <- curl::curl_fetch_disk(part$href, tmp)
  if (r$status_code != 200L) stop("could not fetch ", part$href, ": HTTP ", r$status_code, call. = FALSE)
  if (!ok(tmp)) stop(part$href, " does not match the manifest's size and md5", call. = FALSE)
  if (!file.rename(tmp, dest)) stop("could not move ", tmp, call. = FALSE)
  dest
}
