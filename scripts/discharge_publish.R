# Publish per-segment and per-watershed discharge (#7) to
# s3://fresh-bc/discharge/fwa/v1/ (layout: research/discharge_publish.md).
#
#   Rscript scripts/discharge_publish.R                 # BUILD: the local tree, its manifest, the report
#   WET_PUBLISH=1 Rscript scripts/discharge_publish.R   # PUBLISH: upload the built tree, then verify it
#
# BUILD reads the shipped fit's segment table (scripts/segment_output.R, #57)
# and balance output (scripts/wb_output.R), adds each feature's watershed
# group from fwapg, conforms every part to its crate schema, and writes
#   data/publish/discharge/fwa/v1/<unit>_monthly/scenario=/forcing=/source=/part-<code>.parquet
#   data/publish/discharge/fwa/v1/manifest.json
# with one parquet row group per watershed group, plus the tracked report
# wb_report("discharge_publish", release). It prints what PUBLISH would
# upload and delete, and writes nothing to S3.
#
# PUBLISH uploads that tree, each part with a single PUT whose Content-MD5 S3
# checks, then the manifest, then deletes keys under the prefix the manifest
# no longer names. It then reads the public manifest anonymously and checks
# every part's size and ETag (wet_catalog_verify()), which also proves the
# bucket policy opens the prefix. The bucket has no versioning: an overwrite
# is final, and a reader during the upload can see a part that no longer
# matches the old manifest.
#
# Run where the full province run is: the segment table is built there, and
# BUILD refuses a reduced bundle. Needs arrow, duckdb, crate (with crate#31's
# schemas), the fwapg connection from WET_PG*, and for PUBLISH the aws CLI
# with write access to the bucket.

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
source("scripts/discharge_publish_lib.R")
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
publish <- identical(Sys.getenv("WET_PUBLISH"), "1")
message(if (publish) "PUBLISH run" else "BUILD run (no upload)")

git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data/checks", "DESCRIPTION")
if (length(dirty)) stop("commit these first, so the manifest's commit can rebuild the tree:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
root <- file.path("data", "publish", publish_id)
release <- wb_release()
if (!identical(release, wb_shipped_release)) stop("publish the shipped fit, ", wb_shipped_release)

if (publish) {
  # ---- PUBLISH: the tree BUILD wrote, unchanged, from this commit --------------------------------
  cat_local <- wet_catalog(file.path(root, "manifest.json"))
  if (!identical(attr(cat_local, "provenance")$wet_commit, wet_commit)) {
    stop("the tree was built at ", attr(cat_local, "provenance")$wet_commit, ", not HEAD ", wet_commit,
         ": rerun the build")
  }
  v <- wet_catalog_verify(cat_local)
  if (!all(v$ok)) stop("the local tree no longer matches its manifest: ", paste(v$key[!v$ok], collapse = ", "))
  aws <- function(...) {
    x <- suppressWarnings(system2("aws", c(...), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(x, "status"))) stop("aws ", paste(c(...)[1:2], collapse = " "), " failed: ", paste(x, collapse = " "))
    x
  }
  md5_b64 <- function(hex) jsonlite::base64_enc(as.raw(strtoi(substring(hex, seq(1, 31, 2), seq(2, 32, 2)), 16L)))
  put <- function(file, key, type, md5, ...) {
    aws("s3api", "put-object", "--bucket", publish_bucket, "--key", key, "--body", file,
        "--content-md5", md5_b64(md5), "--content-type", type, ...)
  }
  for (i in seq_len(nrow(cat_local))) {
    put(cat_local$href[i], paste(publish_id, cat_local$key[i], sep = "/"), "application/vnd.apache.parquet",
        cat_local$md5[i])
    stamp("put ", cat_local$key[i])
  }
  f_man <- file.path(root, "manifest.json")
  put(f_man, paste(publish_id, "manifest.json", sep = "/"), "application/json", unname(tools::md5sum(f_man)),
      "--cache-control", "no-cache")
  keys <- aws("s3api", "list-objects-v2", "--bucket", publish_bucket, "--prefix", paste0(publish_id, "/"),
              "--query", "Contents[].Key", "--output", "text")
  keys <- setdiff(unlist(strsplit(keys, "\t")), c("None", ""))
  keep <- c(paste(publish_id, cat_local$key, sep = "/"), paste(publish_id, "manifest.json", sep = "/"))
  stale <- setdiff(keys, keep)
  stopifnot(all(startsWith(stale, paste0(publish_id, "/"))))
  for (k in stale) {
    aws("s3api", "delete-object", "--bucket", publish_bucket, "--key", k)
    stamp("deleted stale ", k)
  }
  cat_pub <- wet_catalog(publish_url)
  stopifnot(identical(cat_pub$md5, cat_local$md5))
  v <- wet_catalog_verify(cat_pub)
  if (!all(v$ok)) stop("published parts do not verify: ", paste(v$key[!v$ok], v$reason[!v$ok], collapse = "; "))
  stamp("published ", nrow(cat_pub), " parts, ", length(stale), " stale keys deleted; all verify at ", publish_url)
  quit(save = "no")
}

# ---- BUILD ------------------------------------------------------------------------------------------
if (!requireNamespace("crate", quietly = TRUE)) stop("install crate (with crate#31's schemas)")
crate_version <- as.character(utils::packageVersion("crate"))
ds_seg <- paste0(publish_id, "/segment_monthly")
ds_ws <- paste0(publish_id, "/watershed_monthly")
invisible(publish_schema_cols(ds_seg))
invisible(publish_schema_cols(ds_ws))

key_dir <- wb_key_dir()
fit_dir <- wb_fit_dir(key_dir, release)
seg_files <- list.files(file.path(fit_dir, "segment"), "\\.parquet$", full.names = TRUE)
ws_files <- list.files(file.path(fit_dir, "output"), "\\.parquet$", full.names = TRUE)
if (!length(seg_files)) stop("no segment table in ", fit_dir, ": run scripts/segment_output.R")

# the segment table must be the one its tracked report describes, built by
# the segment code as it stands now
f_seg_report <- wb_report("segment_output", release)
sr <- readLines(f_seg_report)
seg_commit <- sub("^wet commit ([0-9a-f]+);.*", "\\1", grep("^wet commit ", sr, value = TRUE))
if (length(seg_commit) != 1L) stop(f_seg_report, " names no wet commit")
code_seg <- c("scripts/segment_output.R", "scripts/pcic_routed_lib.R", "scripts/wb_fit_lib.R",
              "scripts/wb_score_md5.R", "R/wet_source_pick.R")
changed <- git("diff", "--name-only", seg_commit, "HEAD", "--", code_seg)
if (length(changed)) {
  stop("the segment code changed since ", f_seg_report, " was built (", paste(changed, collapse = ", "),
       "): rerun scripts/segment_output.R")
}
mt <- function(f) max(file.mtime(f))
if (min(file.mtime(seg_files)) < mt(ws_files) || mt(seg_files) > file.mtime(f_seg_report)) {
  stop("the segment table predates the balance output, or postdates its report: rerun scripts/segment_output.R")
}
routed_line <- grep("^routed: ", sr, value = TRUE)
routed_fp <- sub("^table: ", "", grep("^table: ", sr, value = TRUE))
stopifnot(length(routed_line) == 1L, length(routed_fp) == 1L)

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
seg_grp <- DBI::dbGetQuery(conn, "
  SELECT linear_feature_id::int AS id, watershed_group_code AS g FROM whse_basemapping.fwa_stream_networks_sp")
ws_grp <- DBI::dbGetQuery(conn, "
  SELECT watershed_feature_id::int AS id, watershed_group_code AS g FROM whse_basemapping.fwa_watersheds_poly")
codes <- sort(unique(sub("\\.parquet$", "", basename(c(seg_files, ws_files)))))
drainage <- publish_drainage_labels(conn, codes)
DBI::dbDisconnect(conn)
stamp(nrow(seg_grp), " segments and ", nrow(ws_grp), " watersheds with their groups; ", length(codes), " codes")

unlink(root, recursive = TRUE)
dir.create(root, recursive = TRUE)
part_path <- function(dataset, source, code) {
  file.path(root, sub(".*/", "", dataset), "scenario=historical", paste0("forcing=", publish_forcing[[source]]),
            paste0("source=", source), paste0("part-", code, ".parquet"))
}
cols_seg <- c("linear_feature_id", "month", "runoff_mm", "q_m3s", "coverage", "source", "period", "pick")
period_balance <- character()
tally <- list()
for (f in seg_files) {
  code <- sub("\\.parquet$", "", basename(f))
  x <- as.data.frame(arrow::read_parquet(f))
  if (!identical(names(x), cols_seg)) stop(f, " has columns ", paste(names(x), collapse = ", "))
  x$watershed_group_code <- seg_grp$g[match(x$linear_feature_id, seg_grp$id)]
  # one default per segment and month across the two sources
  key <- paste(x$linear_feature_id, x$month)
  stopifnot(all(tabulate(match(key[x$pick], unique(key)), nbins = length(unique(key))) == 1L))
  for (s in names(publish_forcing)) {
    p <- x[x$source == s, ]
    if (!nrow(p)) next
    if (s == "wet_balance") period_balance <- union(period_balance, unique(p$period))
    publish_part_write(publish_part_prepare(p, ds_seg, "linear_feature_id"), part_path(ds_seg, s, code))
    tally[[length(tally) + 1L]] <- data.frame(dataset = "segment_monthly", source = s, code = code, rows = nrow(p),
                                              segments = length(unique(p$linear_feature_id)),
                                              picked = sum(p$pick & p$month == 0L))
  }
  stamp(code, ": ", nrow(x), " segment rows")
  rm(x, p)
  gc(verbose = FALSE)
}
if (length(period_balance) != 1L) stop("the balance rows carry periods ", paste(period_balance, collapse = ", "))
for (f in ws_files) {
  code <- sub("\\.parquet$", "", basename(f))
  x <- as.data.frame(arrow::read_parquet(f))
  if (!identical(names(x), c("watershed_feature_id", "month", "runoff_mm", "discharge_m3s", "coverage", "bc_fraction"))) {
    stop(f, " has columns ", paste(names(x), collapse = ", "))
  }
  names(x)[names(x) == "discharge_m3s"] <- "q_m3s"
  if (!setequal(x$month, 0:12)) stop(f, " does not hold all 13 months: a reduced bundle")
  n_na <- sum(is.na(x$q_m3s))
  # a watershed with no balance value has no row, as in the segment table
  x <- x[!is.na(x$q_m3s), ]
  x$watershed_group_code <- ws_grp$g[match(x$watershed_feature_id, ws_grp$id)]
  x$period <- period_balance
  if (nrow(x)) publish_part_write(publish_part_prepare(x, ds_ws, "watershed_feature_id"),
                                  part_path(ds_ws, "wet_balance", code))
  tally[[length(tally) + 1L]] <- data.frame(dataset = "watershed_monthly", source = "wet_balance", code = code,
                                            rows = nrow(x), segments = length(unique(x$watershed_feature_id)),
                                            picked = n_na)
  stamp(code, ": ", nrow(x), " watershed rows (", n_na, " NA dropped)")
}
tally <- do.call(rbind, tally)

sources <- list(
  list(source = "pcic_routed",
       description = paste("PCIC's routed streamflow (Raven routing over VIC-GL, hydromosaic, PNWNAmet forcing),",
                           "monthly means 1951-2012 placed on FWA segments by NewGraphEnvironment/fwapg#6;",
                           "annual is the mean of the 12 monthly means."),
       citation = "Pacific Climate Impacts Consortium, University of Victoria. Hydromosaic routed streamflow. https://services.pacificclimate.org/",
       provenance = list(routed = sub("^routed: ", "", routed_line), routed_fingerprint = routed_fp)),
  list(source = "wet_balance",
       description = paste("wet's open water balance (#11): climr 1981-2010 precipitation and temperature,",
                           "CGIAR actual evapotranspiration floored by Fu-Budyko, fitted at HYDAT gauges,",
                           "accumulated upstream over FWA fundamental watersheds."),
       citation = "New Graph Environment Ltd. wet: stream flow for the BC Freshwater Atlas. https://github.com/NewGraphEnvironment/wet",
       provenance = list(fit_release = release, province_run = basename(key_dir)))
)
wet_manifest_write(root, publish_id, drainage = drainage, sources = sources,
                   provenance = list(wet_version = as.character(utils::packageVersion("wet")),
                                     wet_commit = wet_commit, segment_commit = seg_commit),
                   crate_version = crate_version)
cat_local <- wet_catalog(file.path(root, "manifest.json"))
v <- wet_catalog_verify(cat_local)
stopifnot(all(v$ok), sum(cat_local$rows) == sum(tally$rows))

# ---- cross-checks against the segment report, and what a reader sees --------------------------------
num <- function(pattern) as.numeric(sub(pattern, "\\1", grep(pattern, sr, value = TRUE)))
both <- num("^both sources: ([0-9]+);.*")
routed_only <- num("^both sources: [0-9]+; routed only: ([0-9]+);.*")
balance_only <- num("^both sources: [0-9]+; routed only: [0-9]+; balance only: ([0-9]+);.*")
picked_routed <- num("^picked routed: ([0-9]+) .*")
picked_balance <- num("^picked routed: .*; picked balance: ([0-9]+),.*")
seg_t <- tally[tally$dataset == "segment_monthly", ]
rt <- seg_t[seg_t$source == "pcic_routed", ]
bt <- seg_t[seg_t$source == "wet_balance", ]
checks <- c(
  routed_rows = sum(rt$rows) == 13 * (both + routed_only),
  balance_rows = sum(bt$rows) == 13 * (both + balance_only),
  picked_routed = sum(rt$picked) == picked_routed,
  picked_balance = sum(bt$picked) == picked_balance
)
duck <- DBI::dbConnect(duckdb::duckdb())
hive <- DBI::dbGetQuery(duck, sprintf("
  SELECT scenario, forcing, source, count(*)::DOUBLE AS rows, count(*) FILTER (WHERE month = 0 AND pick)::DOUBLE AS fresh
  FROM read_parquet('%s/segment_monthly/*/*/*/*.parquet', hive_partitioning = true)
  GROUP BY ALL ORDER BY source", root))
DBI::dbDisconnect(duck, shutdown = TRUE)
checks["hive_read"] <- sum(hive$rows) == sum(seg_t$rows) && sum(hive$fresh) == picked_routed + picked_balance
seg_paths <- cat_local$href[cat_local$dataset == ds_seg]
group_probe <- "BULK"
rg <- publish_row_groups(seg_paths, group_probe)

f_report <- wb_report("discharge_publish", release)
fmt_tally <- function(x) sprintf("%-18s %-12s %-4s %11.0f %9.0f %9.0f", x$dataset, x$source, x$code, x$rows,
                                 x$segments, x$picked)
writeLines(c(
  "# Published discharge, build (#7)", "",
  sprintf("wet commit %s (segment table built at %s); fit %s, province run %s; crate %s", wet_commit, seg_commit,
          release, basename(key_dir), crate_version),
  routed_line, sprintf("table: %s", routed_fp),
  sprintf("tree: %s -> s3://%s/%s/", root, publish_bucket, publish_id), "",
  "## Cross-checks against the segment report",
  sprintf("%-15s %s", names(checks), ifelse(checks, "ok", "FAIL")), "",
  "## What a reader sees (duckdb, hive_partitioning = true, over the local tree)",
  sprintf("%-10s %-9s %-12s %11.0f rows %9.0f fresh-subquery rows", hive$scenario, hive$forcing, hive$source,
          hive$rows, hive$fresh), "",
  sprintf("## Row-group pruning: a read for %s opens %d of %d row groups in %d segment parts",
          group_probe, rg[["read"]], rg[["total"]], rg[["files"]]), "",
  "## Parts",
  "picked: for segments, annual rows picked; for watersheds, NA-flow watersheds dropped",
  sprintf("%-18s %-12s %-4s %11s %9s %9s", "dataset", "source", "code", "rows", "features", "picked"),
  fmt_tally(tally), "",
  "## Drainage labels", sprintf("%-4s %s", names(drainage), drainage), "",
  sprintf("## Totals: %d parts, %.2f GB", nrow(cat_local), sum(cat_local$bytes) / 1e9)
), f_report)
if (!all(checks)) stop("cross-checks failed: ", paste(names(checks)[!checks], collapse = ", "), "; see ", f_report)
stamp("built ", nrow(cat_local), " parts; report ", f_report)
message("DRY RUN: WET_PUBLISH=1 would upload ", nrow(cat_local), " parts (", sprintf("%.2f GB", sum(cat_local$bytes) / 1e9),
        ") and the manifest to s3://", publish_bucket, "/", publish_id, "/, then delete keys it no longer names")
