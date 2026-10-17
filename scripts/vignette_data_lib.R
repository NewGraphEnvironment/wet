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
  routed_line <- sprintf("routed: %s, built by NewGraphEnvironment/fwapg at %s", routed_table, commit)
  if (!(any(lines == routed_line) && any(lines == sprintf("table: %s", fp)))) {
    stop(f, " was not made from this routed table at fwapg ", commit,
         ": rerun scripts/pcic_routed_compare.R")
  }
  list(commit = commit, fingerprint = fp, report = f, lines = lines)
}

# The live manifest must be the build the tracked publish report checked value
# by value (scripts/discharge_publish.R, #64): that report failed no check, and
# its parts were byte-identical to the live ones. Returns the catalog, the
# report's path, the commit its segment table was built at (whose tracked
# segment report therefore describes the live build, even when the live
# manifest names an earlier commit: a rerun that left every part identical,
# #93), and what a reader of the segment table sees per source: its rows, and
# those fresh's `month = 0 AND pick` returns (the report's duckdb read of the
# tree).
vd_published <- function(release) {
  cat_pub <- wet_catalog()
  stopifnot(identical(attr(cat_pub, "manifest"), wet:::wet_catalog_url))
  pub_commit <- attr(cat_pub, "provenance")$wet_commit
  f <- wb_report("discharge_publish", release)
  lines <- readLines(f)
  re_same <- "^parts identical to the published build ([0-9a-f]+): ([0-9]+) of ([0-9]+) here, ([0-9]+) published"
  same <- Filter(length, regmatches(lines, regexec(re_same, lines)))
  if (any(grepl("FAIL", lines)) || length(same) != 1L || same[[1]][2] != pub_commit ||
        length(unique(c(same[[1]][3:5], nrow(cat_pub)))) != 1L) {
    stop(f, " is not a passing value check of the live build ", pub_commit, ": rerun scripts/discharge_publish.R")
  }
  re_seg <- "^wet commit [0-9a-f]+ \\(segment table built at ([0-9a-f]+)\\);"
  seg <- Filter(length, regmatches(lines, regexec(re_seg, lines)))
  if (length(seg) != 1L) stop(f, " names no single segment table commit")
  re_seen <- "^historical +([A-Za-z0-9-]+) +([a-z_]+) +([0-9]+) rows +([0-9]+) fresh-subquery rows$"
  seen <- do.call(rbind, Filter(length, regmatches(lines, regexec(re_seen, lines))))
  stopifnot(!is.null(seen), setequal(seen[, 3], c("pcic_routed", "wet_balance")))
  reader <- data.frame(source = seen[, 3], forcing = seen[, 2], rows = as.numeric(seen[, 4]),
                       picked = as.numeric(seen[, 5]))
  list(catalog = cat_pub, report = f, segment_commit = seg[[1]][2], reader = reader)
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
