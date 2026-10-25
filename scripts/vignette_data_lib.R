# Guards shared by the vignette data scripts that read the published product
# (data-raw/segment_vignette_data.R, #64; data-raw/monthly_vignette_data.R,
# #65), so both refuse the same things. Sourced, not run on its own: source
# it first, then call vd_commit() before anything else reads the tree.

# system2() only warns when git fails and returns character(0), which would
# read as a clean tree, so check its status
vd_git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}

# The vignette cites the commit its data were built at, so that commit must
# hold what built them: the code, and the tracked reports the scripts parse.
# Refuses uncommitted changes to either; returns the short commit.
vd_commit <- function() {
  dirty <- vd_git("status", "--porcelain", "--", "R", "scripts", "data-raw", "data/checks")
  if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the data:\n",
                          paste(dirty, collapse = "\n"))
  commit <- vd_git("rev-parse", "--short", "HEAD")
  stopifnot(length(commit) == 1, nzchar(commit))
  commit
}

# fwapg from the WET_PG* variables
vd_connect <- function() {
  DBI::dbConnect(RPostgres::Postgres(),
                 host = Sys.getenv("WET_PGHOST", "localhost"),
                 port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                 dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                 user = Sys.getenv("WET_PGUSER", "postgres"),
                 password = Sys.getenv("WET_PGPASSWORD", "postgres"))
}

# The routed table must be the one the tracked report
# (data/checks/pcic_routed_compare_<release>.txt) scored, built at the commit
# it names (WET_FWAPG_COMMIT). Needs scripts/wb_fit_lib.R and
# scripts/pcic_routed_lib.R. Returns the commit, the table's fingerprint, the
# report's path and its lines.
vd_routed_check <- function(release = wb_release()) {
  commit <- routed_commit()
  f <- wb_report("pcic_routed_compare", release)
  lines <- readLines(f)
  conn <- vd_connect()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)
  fp <- routed_fingerprint(conn)
  if (!(any(lines == routed_report_line(commit)) && any(lines == sprintf("table: %s", fp)))) {
    stop(f, " was not made from this routed table at fwapg ", commit,
         ": rerun scripts/pcic_routed_compare.R")
  }
  list(commit = commit, fingerprint = fp, report = f, lines = lines)
}

# The live manifest must be the build the tracked publish report checked value
# by value (scripts/discharge_publish.R, #64): that report failed no check, and
# its parts were byte-identical to the live ones: the report's own tree and its
# live-build line both carry the live parts' digest (#94), so a report naming
# the live commit and part count over other parts is refused. The line is written by publish_live_line()
# (scripts/discharge_publish_lib.R), by a BUILD or after an upload verifies.
# Returns the catalog, the report's path, the commit the build ran at and the
# one its segment table was built at (vd_segment_report()), and what a reader
# of the segment table sees per source: its rows, and those fresh's
# `month = 0 AND pick` returns (the report's duckdb read of the tree).
vd_published <- function(release) {
  cat_pub <- wet_catalog()
  stopifnot(identical(attr(cat_pub, "manifest"), wet:::wet_catalog_url))
  pub_commit <- attr(cat_pub, "provenance")$wet_commit
  f <- wb_report("discharge_publish", release)
  lines <- readLines(f)
  re_same <- paste0("^parts identical to the published build ([0-9a-f]+): ([0-9]+) of ([0-9]+) here, ",
                    "([0-9]+) published \\(.*\\); live parts md5 ([0-9a-f]{32})$")
  same <- Filter(length, regmatches(lines, regexec(re_same, lines)))
  if (any(grepl("FAIL", lines)) || length(same) != 1L || same[[1]][2] != pub_commit ||
        length(unique(c(same[[1]][3:5], nrow(cat_pub)))) != 1L ||
        same[[1]][6] != wet:::wet_catalog_digest(cat_pub) ||
        sum(lines == sprintf("tree parts md5 %s", wet:::wet_catalog_digest(cat_pub))) != 1L) {
    stop(f, " is not a passing value check of the live build ", pub_commit, ": rerun scripts/discharge_publish.R")
  }
  re_seg <- "^wet commit ([0-9a-f]+) \\(segment table built at ([0-9a-f]+)\\);"
  seg <- Filter(length, regmatches(lines, regexec(re_seg, lines)))
  if (length(seg) != 1L) stop(f, " names no single segment table commit")
  re_seen <- "^historical +([A-Za-z0-9-]+) +([a-z_]+) +([0-9]+) rows +([0-9]+) fresh-subquery rows$"
  seen <- do.call(rbind, Filter(length, regmatches(lines, regexec(re_seen, lines))))
  stopifnot(!is.null(seen), setequal(seen[, 3], c("pcic_routed", "wet_balance")))
  reader <- data.frame(source = seen[, 3], forcing = seen[, 2], rows = as.numeric(seen[, 4]),
                       picked = as.numeric(seen[, 5]))
  list(catalog = cat_pub, report = f, build_commit = seg[[1]][2], segment_commit = seg[[1]][3], reader = reader)
}

# The tracked segment report must be the one the publish report's build read,
# so that its counts describe parts byte-identical to the live build's. The
# build refuses uncommitted data/checks, so that is the report as committed at
# the build's commit: compared whole, since its head names only a commit, and
# a rerun at the same commit would name the same one. The live manifest may
# name an earlier segment commit, from before a rerun that changed no part
# (#93). Takes vd_published()'s result; returns the report's path and lines.
vd_segment_report <- function(pb, release) {
  f <- wb_report("segment_output", release)
  lines <- readLines(f)
  if (!identical(lines, vd_git("show", paste0(pb$build_commit, ":", f)))) {
    stop(f, " is not the segment report ", pb$report, " was built from (at ", pb$build_commit,
         ", segment table at ", pb$segment_commit, "): rerun scripts/discharge_publish.R (BUILD)")
  }
  list(report = f, lines = lines)
}

# The parts must match their manifest; call before and after a read, so a
# read during a publish is refused
vd_verify <- function(parts) {
  v <- wet:::wet_catalog_verify(parts)
  if (!all(v$ok)) {
    stop("published parts do not match their manifest: ", paste(v$key[!v$ok], v$reason[!v$ok], collapse = "; "))
  }
  invisible(v)
}
