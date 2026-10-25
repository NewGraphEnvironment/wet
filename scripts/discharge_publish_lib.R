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

# The report's line on the live build, which vd_published()
# (scripts/vignette_data_lib.R) parses: how many of the local parts are
# byte-identical to the live manifest's, and the live parts' digest (#94).
# BUILD writes it against whatever is live; PUBLISH writes it again once its
# upload verifies (publish_report_live()). `cat_pub` NULL: the manifest could
# not be read
publish_live_line <- function(cat_local, cat_pub) {
  if (is.null(cat_pub)) return(sprintf("could not read %s", publish_url))
  same <- sum(cat_local$md5 == cat_pub$md5[match(cat_local$key, cat_pub$key)], na.rm = TRUE)
  sprintf("parts identical to the published build %s: %d of %d here, %d published (%s); live parts md5 %s",
          attr(cat_pub, "provenance")$wet_commit, same, nrow(cat_local), nrow(cat_pub), publish_url,
          wet:::wet_catalog_digest(cat_pub))
}

# The report's line naming the build's own parts by their digest (#94): PUBLISH
# uploads a tree only when its committed report carries this line, and
# vd_published() takes a report only when the live parts carry it too, so a
# report is never certified for parts another build wrote
publish_tree_line <- function(cat_local) sprintf("tree parts md5 %s", wet:::wet_catalog_digest(cat_local))

# The report's section holding the live-build line; BUILD writes it
publish_live_heading <- "## Against the published tree"

# Whether `lines` (the report at `f_report`) may carry the upload of the tree
# `cat_local`: it names that build's commit and its tree's digest once, failed
# no check, and has one live-build line under publish_live_heading. PUBLISH
# asks it of the committed report before the upload, so a report it could not
# rewrite is refused while nothing has moved, and publish_report_live() asks
# it again. Returns the live-build line's index
publish_report_check <- function(lines, cat_local, f_report) {
  built_at <- attr(cat_local, "provenance")$wet_commit
  if (!any(startsWith(lines, paste0("wet commit ", built_at, " "))) ||
        sum(lines == publish_tree_line(cat_local)) != 1L || any(grepl("FAIL", lines))) {
    stop("commit the build's report ", f_report, " first; it must name build ", built_at,
         " and this tree's parts (", publish_tree_line(cat_local), ") and fail no check")
  }
  h <- which(lines == publish_live_heading)
  if (length(h) != 1L || h == length(lines) ||
        !grepl("^(parts identical to the published build |could not read )", lines[h + 1L])) {
    stop(f_report, " has no single live-build line under its \"", publish_live_heading, "\"")
  }
  h + 1L
}

# After an upload, the build's report gets the live-build line the upload
# proved, so no second BUILD is needed to write it (#117). Refuses unless
# `verified` (wet_catalog_verify() of `cat_pub`) passed for every published
# part, the published parts are the local ones byte for byte, and the report
# is this build's (its commit and its tree's digest) and failed no check.
# Only the line under publish_live_heading changes; the file is
# left for a commit, as after a BUILD. A refusal comes after the upload, so
# the live tree has moved and the report has not: rerun PUBLISH, which skips
# every part already live
publish_report_live <- function(f_report, cat_local, cat_pub, verified) {
  if (!nrow(verified) || !all(verified$ok) || !setequal(verified$key, cat_pub$key)) {
    stop("the published parts did not all verify; ", f_report, " is left as it was")
  }
  if (wet:::wet_catalog_digest(cat_pub) != wet:::wet_catalog_digest(cat_local)) {
    stop("the published parts are not the local ones; ", f_report, " is left as it was")
  }
  lines <- readLines(f_report)
  i <- publish_report_check(lines, cat_local, f_report)
  out <- lines
  out[i] <- publish_live_line(cat_local, cat_pub)
  stopifnot(identical(out[-i], lines[-i]))
  writeLines(out, f_report)
  invisible(out[i])
}

# md5 of bytes held in memory, as tools::md5sum() gives a file's
digest_raw_md5 <- function(bytes) {
  f <- tempfile()
  on.exit(unlink(f), add = TRUE)
  writeBin(bytes, f)
  unname(tools::md5sum(f))
}

# the ordered columns crate declares for a dataset
publish_schema_cols <- function(dataset) {
  reg <- crate::crt_files("nge")
  row <- reg[reg$file_name == dataset, ]
  if (nrow(row) != 1L) stop("crate has no schema for ", dataset, ": install crate with crate#31's schemas")
  y <- yaml::read_yaml(system.file("extdata", row$schema_yaml, package = "crate"))
  vapply(y$canonical$cols, function(col) col$name, "")
}

# One part, ready to write: `x` holds one source's rows of one drainage code
# (a monthly dataset) or one watershed group (a daily one).
# Drops `source` (it is in the path), puts the columns in crate's order,
# conforms them, and asserts what crate does not check. Conform is a check
# here, not a repair: it must change no class and no NA.
publish_part_prepare <- function(x, dataset, id_col) {
  time <- wet:::wet_timebase(dataset)$col
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
    !anyNA(y[[id_col]]), !anyNA(y$watershed_group_code), is.integer(y[[time]]),
    all(y[[time]] %in% wet:::wet_timebase(dataset)$values),
    all(grepl("^[0-9]{4}-[0-9]{4}$", y$period)), all(is.na(y$q_m3s) | y$q_m3s >= 0),
    !anyDuplicated(y[c(id_col, time, "period")])
  )
  if ("pick" %in% cols) stopifnot(!anyNA(y$pick))
  y[order(y$watershed_group_code, y[[id_col]], y[[time]]), ]
}

# Write a prepared part with one row group per watershed group, so a read for
# one group skips the rest on row-group statistics; a part of one group (a
# daily part) in row groups of `rows_per_group`, so a read of a few segments
# skips the rest on the segment ID's statistics. Written to a temporary file
# and moved.
publish_part_write <- function(x, path, rows_per_group = NULL) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tab <- arrow::Table$create(x)
  tmp <- paste0(path, ".tmp")
  sink <- arrow::FileOutputStream$create(tmp)
  props <- arrow::ParquetWriterProperties$create(names(x), compression = "zstd", write_statistics = TRUE)
  w <- arrow::ParquetFileWriter$create(tab$schema, sink, properties = props)
  runs <- rle(x$watershed_group_code)
  if (!is.null(rows_per_group)) {
    stopifnot(length(runs$lengths) == 1L)
    runs$lengths <- diff(unique(c(seq(0, nrow(x), by = rows_per_group), nrow(x))))
  }
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

# A label per watershed group code: its name in the FWA.
publish_group_labels <- function(conn, groups) {
  g <- DBI::dbGetQuery(conn, "
    SELECT watershed_group_code AS code, watershed_group_name AS name FROM whse_basemapping.fwa_watershed_groups_poly")
  if (!all(groups %in% g$code)) stop("no FWA watershed group ", paste(setdiff(groups, g$code), collapse = ", "))
  stats::setNames(g$name[match(groups, g$code)], groups)
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
