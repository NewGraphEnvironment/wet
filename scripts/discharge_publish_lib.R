# The per-part core of scripts/discharge_publish.R (#7), kept apart so it can
# be run on a small frame before the province run. Sourced after
# devtools::load_all(); not run on its own. Needs arrow, duckdb and crate.

# the published tree: S3 location and the manifest URL wet_catalog() reads
publish_bucket <- "fresh-bc"
publish_id <- "discharge/fwa/v1"
publish_url <- sprintf("https://%s.s3.us-west-2.amazonaws.com/%s/manifest.json", publish_bucket, publish_id)
stopifnot(identical(publish_url, wet:::wet_catalog_url))

# what drove each source, the `forcing` key (research/discharge_publish.md)
publish_forcing <- c(pcic_routed = "PNWNAmet", wet_balance = "climr")

# the ordered columns crate declares for a dataset
publish_schema_cols <- function(dataset) {
  reg <- crate::crt_files("nge")
  row <- reg[reg$file_name == dataset, ]
  if (nrow(row) != 1L) stop("crate has no schema for ", dataset, ": install crate with crate#31's schemas")
  y <- yaml::read_yaml(system.file("extdata", row$schema_yaml, package = "crate"))
  vapply(y$canonical$cols, function(col) col$name, "")
}

# One part, ready to write: `x` holds one source's rows of one drainage code.
# Drops `source` (it is in the path), puts the columns in crate's order,
# conforms them, and asserts what crate does not check. Conform is a check
# here, not a repair: it must change no class and no NA.
publish_part_prepare <- function(x, dataset, id_col) {
  if ("source" %in% names(x)) {
    if (length(unique(x$source)) != 1L) stop("a part holds more than one source")
    x$source <- NULL
  }
  cols <- publish_schema_cols(dataset)
  if (!setequal(names(x), cols)) {
    stop(dataset, ": columns ", paste(names(x), collapse = ", "), " are not crate's ", paste(cols, collapse = ", "))
  }
  x <- x[cols]
  before <- list(vapply(x, function(v) class(v)[1], ""), vapply(x, function(v) sum(is.na(v)), 0))
  y <- as.data.frame(crate::crt_schema_conform(x, "nge", dataset))
  after <- list(vapply(y, function(v) class(v)[1], ""), vapply(y, function(v) sum(is.na(v)), 0))
  if (!identical(before, after)) {
    stop(dataset, ": crt_schema_conform() changed a class or an NA count; fix the frame, not the schema")
  }
  stopifnot(
    !anyNA(y[[id_col]]), !anyNA(y$watershed_group_code), !anyNA(y$month), all(y$month %in% 0:12),
    all(grepl("^[0-9]{4}-[0-9]{4}$", y$period)), all(is.na(y$q_m3s) | y$q_m3s >= 0),
    !anyDuplicated(y[c(id_col, "month", "period")])
  )
  if ("pick" %in% cols) stopifnot(!anyNA(y$pick))
  y[order(y$watershed_group_code, y[[id_col]], y$month), ]
}

# Write a prepared part with one row group per watershed group, so a read for
# one group skips the rest on row-group statistics. Written to a temporary
# file and moved.
publish_part_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tab <- arrow::Table$create(x)
  tmp <- paste0(path, ".tmp")
  sink <- arrow::FileOutputStream$create(tmp)
  props <- arrow::ParquetWriterProperties$create(names(x), compression = "zstd", write_statistics = TRUE)
  w <- arrow::ParquetFileWriter$create(tab$schema, sink, properties = props)
  runs <- rle(x$watershed_group_code)
  start <- c(0, cumsum(runs$lengths)[-length(runs$lengths)])
  for (i in seq_along(runs$lengths)) {
    w$WriteTable(tab$Slice(start[i], runs$lengths[i]), chunk_size = runs$lengths[i])
  }
  w$Close()
  sink$close()
  if (!file.rename(tmp, path)) stop("could not move ", tmp)
  invisible(path)
}

# Row groups a read for one watershed group must open, against all of them,
# from the footers' statistics
publish_row_groups <- function(paths, group) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  m <- DBI::dbGetQuery(con, sprintf(
    "SELECT file_name, row_group_id, stats_min_value AS lo, stats_max_value AS hi
     FROM parquet_metadata([%s]) WHERE path_in_schema = 'watershed_group_code'",
    paste(sprintf("'%s'", paths), collapse = ", ")))
  c(read = sum(m$lo <= group & m$hi >= group), total = nrow(m), files = length(paths))
}

# A label per FWA top-level drainage code: the GNIS name most of its mainstem
# segments carry (watershed code `<code>-000000-…`), or else its three largest
# watershed groups by segment count.
publish_drainage_labels <- function(conn, codes) {
  main <- DBI::dbGetQuery(conn, "
    SELECT split_part(fwa_watershed_code, '-', 1) AS code, gnis_name, count(*)::int AS n
    FROM whse_basemapping.fwa_stream_networks_sp
    WHERE fwa_watershed_code ~ '^[0-9]{3}(-000000)+$' AND gnis_name IS NOT NULL
    GROUP BY 1, 2")
  grp <- DBI::dbGetQuery(conn, "
    SELECT split_part(s.fwa_watershed_code, '-', 1) AS code, g.watershed_group_name AS name, count(*)::int AS n
    FROM whse_basemapping.fwa_stream_networks_sp s
    JOIN whse_basemapping.fwa_watershed_groups_poly g USING (watershed_group_code)
    GROUP BY 1, 2")
  vapply(codes, function(code) {
    m <- main[main$code == code, ]
    if (nrow(m)) return(m$gnis_name[order(-m$n, m$gnis_name)][1])
    g <- grp[grp$code == code, ]
    if (!nrow(g)) stop("no FWA streams in drainage code ", code)
    paste("watershed groups", paste(head(g$name[order(-g$n, g$name)], 3), collapse = ", "))
  }, "")
}
