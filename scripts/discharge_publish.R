# Publish per-segment and per-watershed discharge (#7) to
# s3://fresh-bc/discharge/fwa/v1/ (layout: research/discharge_publish.md).
#
#   Rscript scripts/discharge_publish.R                 # BUILD: the local tree, its manifest, the report
#   WET_PUBLISH=1 Rscript scripts/discharge_publish.R   # PUBLISH: upload the built tree, then verify it
#
# BUILD reads the shipped fit's segment table (scripts/segment_output.R, #57)
# and balance output (scripts/wb_output.R), adds each feature's watershed
# group from fwapg, conforms every part to its crate schema, checks every
# written value against what it was built from (#64), and writes
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

publish <- identical(Sys.getenv("WET_PUBLISH"), "1")
message(if (publish) "PUBLISH run" else "BUILD run (no upload)")
# A BUILD that goes on to refuse must not leave the last tree publishable, so
# its manifest goes first, before anything that can refuse (loading and
# sourcing included), as segment_output.R's old table does
root <- file.path("data", "publish", "discharge", "fwa", "v1")
if (!publish) {
  unlink(file.path(root, c("manifest.json", "manifest.pending.json")))
  # unlink() reports a failure by its return value, not an error
  stopifnot(!file.exists(file.path(root, c("manifest.json", "manifest.pending.json"))))
}
devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")
source("scripts/discharge_publish_lib.R")
source("scripts/pcic_routed_lib.R")  # routed_table, routed_fingerprint()
stopifnot(identical(root, file.path("data", "publish", publish_id)))
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)

git <- function(...) {
  # system2() hands its args to sh unquoted, and "(exclude)" is a syntax error there
  x <- suppressWarnings(system2("git", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data/checks", "DESCRIPTION")
if (length(dirty)) stop("commit these first, so the manifest's commit can rebuild the tree:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
release <- wb_release()
if (!identical(release, wb_shipped_release)) stop("publish the shipped fit, ", wb_shipped_release)

if (publish) {
  # ---- PUBLISH: the tree BUILD wrote, unchanged, from this commit --------------------------------
  cat_local <- wet_catalog(file.path(root, "manifest.json"))
  # committing the build's report moves HEAD, so compare the code, not the commit
  built_at <- attr(cat_local, "provenance")$wet_commit
  if (!is.character(built_at) || length(built_at) != 1L || !grepl("^[0-9a-f]{7,40}$", built_at)) {
    stop("the manifest names no build commit")
  }
  changed <- git("diff", "--name-only", built_at, "HEAD", "--", "R", "scripts")
  if (length(changed)) {
    stop("the code changed since the tree was built at ", built_at, " (", paste(changed, collapse = ", "),
         "): rerun the build")
  }
  # the inputs too: the segment table the tree was built from is the one the
  # current segment report describes, and the build's own report is committed,
  # names this build and failed no check
  sr <- readLines(wb_report("segment_output", release))
  if (!any(grepl(paste0("^wet commit ", attr(cat_local, "provenance")$segment_commit, ";"), sr))) {
    stop("the segment report has moved on since the tree was built: rerun the build")
  }
  f_report <- wb_report("discharge_publish", release)
  rep_head <- tryCatch(git("show", paste0("HEAD:", f_report)), error = function(e) character())
  if (!any(grepl(paste0("^wet commit ", built_at, " "), rep_head)) || any(grepl("FAIL", rep_head))) {
    stop("commit the build's report ", f_report, " first; it must name build ", built_at, " and fail no check")
  }
  v <- wet_catalog_verify(cat_local)
  if (!all(v$ok)) stop("the local tree no longer matches its manifest: ", paste(v$key[!v$ok], collapse = ", "))
  aws <- function(...) {
    x <- suppressWarnings(system2("aws", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
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
# the manifest names each schema at the installed crate's release tag, so
# that tag must hold it: a branch install reports the last release's version
# and hold it as installed: a later edit under an unbumped version would not
for (ds in c(ds_seg, ds_ws)) {
  url <- sprintf("https://raw.githubusercontent.com/NewGraphEnvironment/crate/v%s/inst/extdata/schemas/nge/%s.yaml",
                 crate_version, ds)
  r <- curl::curl_fetch_memory(url)
  if (r$status_code != 200L) stop("crate v", crate_version, " has no released schema for ", ds, " (HTTP ",
                                  r$status_code, "): install the crate release that carries crate#31")
  installed <- system.file("extdata", "schemas", "nge", paste0(ds, ".yaml"), package = "crate")
  if (!identical(unname(tools::md5sum(installed)), digest_raw_md5(r$content))) {
    stop("the installed crate's schema for ", ds, " differs from crate v", crate_version, "'s: install that release")
  }
}

key_dir <- wb_key_dir()
fit_dir <- wb_fit_dir(key_dir, release)
seg_files <- list.files(file.path(fit_dir, "segment"), "\\.parquet$", full.names = TRUE)
ws_files <- list.files(file.path(fit_dir, "output"), "\\.parquet$", full.names = TRUE)
if (!length(seg_files)) stop("no segment table in ", fit_dir, ": run scripts/segment_output.R")
if (!length(ws_files)) stop("no balance output in ", fit_dir, ": run scripts/wb_output.R")
# every basin of the province run, and only those: a partial copy is refused
codes_up <- sub("\\.rds$", "", list.files(file.path(key_dir, "upstream"), "\\.rds$"))
codes_ws <- sub("\\.parquet$", "", basename(ws_files))
codes_seg <- sub("\\.parquet$", "", basename(seg_files))
if (!setequal(codes_ws, codes_up) || !all(codes_seg %in% codes_up)) {
  stop("the balance output, the segment table and the province run's upstream/ hold different basins")
}
# and each basin whole: 13 rows per watershed the balance report counts
wr <- readLines(wb_report("wb_output", release))
by_basin <- grep("^[0-9]{3} +[0-9]+ ", wr, value = TRUE)
ws_expected <- stats::setNames(13 * as.numeric(sub("^[0-9]{3} +([0-9]+) .*", "\\1", by_basin)),
                               sub(" .*", "", by_basin))
if (!setequal(names(ws_expected), codes_up)) stop("the balance report does not list every basin")

# the segment table must be the one its tracked report describes, built by
# the segment code as it stands now
f_seg_report <- wb_report("segment_output", release)
sr <- readLines(f_seg_report)
seg_commit <- sub("^wet commit ([0-9a-f]+);.*", "\\1", grep("^wet commit ", sr, value = TRUE))
if (length(seg_commit) != 1L) stop(f_seg_report, " names no wet commit")
# Every file under R/ and scripts/ but this publish code's own, rather than a
# list of what the tables depend on: a list misses a dependency and passes,
# while a file left off the exclusions only forces a rebuild.
publish_own <- c("R/wet_catalog.R", "R/wet_db_load.R", "R/wet_values_compare.R", "scripts/discharge_publish.R",
                 "scripts/discharge_publish_lib.R")
# DESCRIPTION is left out: its version moves at every release
changed <- git("diff", "--name-only", seg_commit, "HEAD", "--", "R", "scripts",
               paste0(":(exclude)", publish_own))
if (length(changed)) {
  stop("code changed since ", f_seg_report, " was built at ", seg_commit, " (", paste(changed, collapse = ", "),
       "): rerun scripts/wb_output.R and scripts/segment_output.R")
}
# and the fit both tables came from is the one the scoring code ships
source("scripts/wb_score_md5.R")  # score_code_md5, aet_code_md5
fits <- readRDS(file.path(fit_dir, "fits.rds"))
winner <- readLines(file.path(fit_dir, "aet_winner.txt"))
if (!identical(fits$code_md5, score_code_md5) || !identical(winner[1:2], c(fits$aet, aet_code_md5)) ||
      !any(grepl(paste0("scoring code ", score_code_md5, "$"), sr[3]))) {
  stop("the fit, its AET choice or the segment report was made under other scoring code")
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
# what the value cross-checks compare against: the routed table the segment
# table was built from, all of it, and the lut that gives a segment its watershed
if (!identical(routed_fingerprint(conn), routed_fp)) {
  stop("fwapg's ", routed_table, " is not the table ", f_seg_report, " was built from (", routed_fp, ")")
}
rt_all <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, month, q_m3s FROM %s", routed_table))
lut <- DBI::dbGetQuery(conn, "
  SELECT linear_feature_id::int AS linear_feature_id, watershed_feature_id::int AS watershed_feature_id
  FROM whse_basemapping.fwa_streams_watersheds_lut")
stopifnot(!anyDuplicated(lut$linear_feature_id))
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
  if (!all(x$source %in% names(publish_forcing))) {
    stop(f, " has a source with no forcing label: ", paste(setdiff(unique(x$source), names(publish_forcing)), collapse = ", "))
  }
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
  if (nrow(x) != ws_expected[[code]]) stop(f, " has ", nrow(x), " rows; the balance report says ", ws_expected[[code]])
  n_na <- sum(is.na(x$q_m3s))
  # a watershed with no balance value has no row, as in the segment table
  x <- x[!is.na(x$q_m3s), ]
  if (nrow(x)) {
    x$watershed_group_code <- ws_grp$g[match(x$watershed_feature_id, ws_grp$id)]
    x$period <- period_balance
    publish_part_write(publish_part_prepare(x, ds_ws, "watershed_feature_id"), part_path(ds_ws, "wet_balance", code))
  }
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
# the manifest is publishable only once every check below passes: until then
# it is manifest.pending.json, which PUBLISH does not read
f_pending <- file.path(root, "manifest.pending.json")
wet_manifest_write(root, publish_id, drainage = drainage, sources = sources,
                   provenance = list(wet_version = as.character(utils::packageVersion("wet")),
                                     wet_commit = wet_commit, segment_commit = seg_commit),
                   crate_version = crate_version, path = f_pending)
cat_local <- wet_catalog(f_pending)
v <- wet_catalog_verify(cat_local)
stopifnot(all(v$ok), sum(cat_local$rows) == sum(tally$rows))

# ---- cross-checks against the segment report, and what a reader sees --------------------------------
num <- function(pattern) {
  # one number, or the check it feeds would drop out of `checks` and pass
  x <- as.numeric(sub(pattern, "\\1", grep(pattern, sr, value = TRUE)))
  if (length(x) != 1L || is.na(x)) stop(f_seg_report, " has no single line matching ", pattern)
  x
}
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

# ---- value cross-checks: every published flow, and four segment columns, against their sources ------
# Each written part is read back. Routed months 1-12 against fwapg's table,
# routed month 0 against the mean of the part's own twelve months, the
# balance's 13 months against the fit's output reached through the lut (the
# segment table's join, done again here), four columns of every segment row
# against the segment table it was cut from, and each watershed row against
# the fit's output. Counts alone cannot see a value that moved; these count
# and size every one that did. Values copied from a double are compared
# exactly; only the two means of twelve months meet within 1e-9, since R's
# mean() and a sum over 12 round differently in the last bits.
cols_val <- c("linear_feature_id", "month", "q_m3s", "runoff_mm", "coverage", "pick")
read_part <- function(path, cols = cols_val) {
  # a source with no segment in a drainage writes no part
  if (!file.exists(path)) return(stats::setNames(data.frame(matrix(numeric(), 0, length(cols))), cols))
  as.data.frame(arrow::read_parquet(path, col_select = cols))
}
vc <- list()
vc_add <- function(check, code, r) {
  vc[[length(vc) + 1L]] <<- data.frame(check = check, code = code, compared = r[["compared"]],
                                       differing = r[["differing"]], max_abs_diff = r[["max_abs_diff"]])
}
routed_seen <- integer()
routed_micro <- 0  # the routed total in 1e-6 m3/s, rounded per value as the fingerprint rounds
for (code in codes_seg) {
  pr <- read_part(part_path(ds_seg, "pcic_routed", code))
  m112 <- pr[pr$month > 0L, ]
  routed_seen <- c(routed_seen, unique(m112$linear_feature_id))
  routed_micro <- routed_micro + sum(round(m112$q_m3s * 1e6))
  vc_add("routed months 1-12 = fwapg", code,
         wet_values_compare(m112, rt_all[rt_all$linear_feature_id %in% m112$linear_feature_id, ], tol = 0))
  # a drainage with no routed segment (800, 945, 990) has nothing to derive
  s12 <- rowsum(m112$q_m3s, m112$linear_feature_id)
  n12 <- rowsum(rep(1, nrow(m112)), m112$linear_feature_id)
  derived <- data.frame(linear_feature_id = as.integer(rownames(s12)), month = rep(0L, nrow(s12)),
                        q_m3s = ifelse(n12[, 1] == 12, s12[, 1] / 12, NA_real_))
  vc_add("routed month 0 = mean of 1-12", code, wet_values_compare(pr[pr$month == 0L, ], derived))

  pb <- read_part(part_path(ds_seg, "wet_balance", code))
  out <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", paste0(code, ".parquet")),
                                           col_select = c("watershed_feature_id", "month", "discharge_m3s")))
  k_out <- as.numeric(out$watershed_feature_id) * 16 + out$month
  valued <- out$watershed_feature_id[out$month == 0L & !is.na(out$discharge_m3s)]
  l <- lut[lut$watershed_feature_id %in% valued, ]
  expected <- data.frame(linear_feature_id = rep(l$linear_feature_id, 13), month = rep(0:12, each = nrow(l)))
  expected$q_m3s <- out$discharge_m3s[match(as.numeric(rep(l$watershed_feature_id, 13)) * 16 + expected$month, k_out)]
  vc_add("balance = fit output via lut", code, wet_values_compare(pb, expected, tol = 0))

  st <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "segment", paste0(code, ".parquet")),
                                          col_select = c(cols_val, "source")))
  for (v in c("q_m3s", "runoff_mm", "coverage", "pick")) {
    for (src in c("pcic_routed", "wet_balance")) {
      vc_add(paste("segment parts = table:", v), code,
             wet_values_compare(if (src == "pcic_routed") pr else pb, st[st$source == src, ], value = v, tol = 0))
    }
  }
  stamp(code, ": values checked")
  rm(pr, m112, pb, out, l, expected, st)
  gc(verbose = FALSE)
}
# the watershed parts: each row the fit's output for that watershed and month,
# and every watershed with a value published
for (code in codes_ws) {
  pw <- read_part(part_path(ds_ws, "wet_balance", code), c("watershed_feature_id", "month", "q_m3s"))
  out <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", paste0(code, ".parquet")),
                                           col_select = c("watershed_feature_id", "month", "discharge_m3s")))
  out <- out[!is.na(out$discharge_m3s), ]
  names(out)[3] <- "q_m3s"
  vc_add("watershed parts = fit output", code, wet_values_compare(pw, out, "watershed_feature_id", tol = 0))
}
# fwapg's routed rows on no published segment
unpub <- sum(!rt_all$linear_feature_id %in% routed_seen)
vc_add("routed months 1-12 = fwapg", "none", c(compared = unpub, differing = unpub, max_abs_diff = 0))
vc <- do.call(rbind, vc)
vc_sum <- do.call(rbind, lapply(split(vc, factor(vc$check, unique(vc$check))), function(x) {
  data.frame(check = x$check[1], compared = sum(x$compared), differing = sum(x$differing),
             max_abs_diff = max(x$max_abs_diff), codes_differing = paste(x$code[x$differing > 0], collapse = " "))
}))
routed_total <- sprintf("%.0f.%06.0f", floor(routed_micro / 1e6), routed_micro %% 1e6)
fp_total <- sub(".*, total ([0-9.]+) m3/s$", "\\1", routed_fp)
n_vc <- function(chk, x) vc_sum[vc_sum$check == chk, x]
checks["routed_values"] <- n_vc("routed months 1-12 = fwapg", "differing") == 0 &&
  n_vc("routed months 1-12 = fwapg", "compared") == nrow(rt_all) && !anyDuplicated(routed_seen)
checks["routed_annual"] <- n_vc("routed month 0 = mean of 1-12", "differing") == 0 &&
  n_vc("routed month 0 = mean of 1-12", "compared") == sum(rt$segments)
checks["routed_total"] <- identical(routed_total, fp_total)
checks["balance_values"] <- n_vc("balance = fit output via lut", "differing") == 0 &&
  n_vc("balance = fit output via lut", "compared") == sum(bt$rows)
tbl_checks <- grep("^segment parts = table: ", vc_sum$check, value = TRUE)
checks["parts_as_table"] <- length(tbl_checks) == 4L &&
  all(vapply(tbl_checks, n_vc, 0, "differing") == 0) &&
  all(vapply(tbl_checks, n_vc, 0, "compared") == sum(seg_t$rows))
ws_t <- tally[tally$dataset == "watershed_monthly", ]
checks["watershed_values"] <- n_vc("watershed parts = fit output", "differing") == 0 &&
  n_vc("watershed parts = fit output", "compared") == sum(ws_t$rows)
stamp("value cross-checks: ", sum(vc_sum$compared), " values compared, ", sum(vc_sum$differing), " differing")

# the parts against the live manifest's: a rebuild of the same inputs and code
# writes the same bytes, and a new release is meant to differ, so this is
# reported, not checked
cat_pub <- tryCatch(wet_catalog(publish_url), error = function(e) NULL)
pub_line <- if (is.null(cat_pub)) {
  sprintf("could not read %s", publish_url)
} else {
  same <- sum(cat_local$md5 == cat_pub$md5[match(cat_local$key, cat_pub$key)], na.rm = TRUE)
  sprintf("parts identical to the published build %s: %d of %d here, %d published (%s)",
          attr(cat_pub, "provenance")$wet_commit, same, nrow(cat_local), nrow(cat_pub), publish_url)
}
stamp(pub_line)

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
  sprintf("arrow %s, duckdb %s (a part's bytes depend on the writer's version)",
          utils::packageVersion("arrow"), utils::packageVersion("duckdb")),
  routed_line, sprintf("table: %s", routed_fp),
  sprintf("tree: %s -> s3://%s/%s/", root, publish_bucket, publish_id), "",
  "## Cross-checks against the segment report, and value by value",
  sprintf("%-15s %s", names(checks), ifelse(checks, "ok", "FAIL")), "",
  "## Value cross-checks (#64): every published flow, and four segment columns, against their sources",
  sprintf("%-30s %11s %10s %13s  %s", "check", "compared", "differing", "largest diff", "codes differing"),
  sprintf("%-30s %11.0f %10.0f %13.3g  %s", vc_sum$check, vc_sum$compared, vc_sum$differing, vc_sum$max_abs_diff,
          vc_sum$codes_differing),
  sprintf("routed months 1-12, total rounded to 1e-6 per value: %s m3/s; the table's fingerprint: %s m3/s",
          routed_total, fp_total), "",
  "## Against the published tree", pub_line, "",
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
if (!file.rename(f_pending, file.path(root, "manifest.json"))) stop("could not move ", f_pending)
stamp("built ", nrow(cat_local), " parts; report ", f_report)
message("DRY RUN: WET_PUBLISH=1 would upload ", nrow(cat_local), " parts (", sprintf("%.2f GB", sum(cat_local$bytes) / 1e9),
        ") and the manifest to s3://", publish_bucket, "/", publish_id, "/, then delete keys it no longer names")
