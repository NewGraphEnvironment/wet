# Publish per-segment and per-watershed discharge (#7) to
# s3://fresh-bc/discharge/fwa/v1/ (layout: research/discharge_publish.md).
#
#   Rscript scripts/discharge_publish.R                 # BUILD: the local tree, its manifest, the report
#   WET_PUBLISH=1 Rscript scripts/discharge_publish.R   # PUBLISH: upload the built tree, then verify it
#
# BUILD reads the shipped fit's segment table (scripts/segment_output.R, #57),
# its daily table (scripts/segment_daily_output.R, #99) and balance output
# (scripts/wb_output.R), adds each feature's watershed
# group from fwapg, conforms every part to its crate schema, checks every
# written flow (and four segment columns) against its source (#64), and writes
#   data/publish/discharge/fwa/v1/<unit>_monthly/scenario=/forcing=/source=/part-<code>.parquet
#   data/publish/discharge/fwa/v1/segment_daily/scenario=/forcing=/source=/part-<GROUP>.parquet
#   data/publish/discharge/fwa/v1/manifest.json
# with one parquet row group per watershed group, plus the tracked report
# wb_report("discharge_publish", release). It prints what PUBLISH would
# upload and delete, and writes nothing to S3.
#
# PUBLISH uploads that tree, each part with a single PUT whose Content-MD5 S3
# checks (skipping a part whose live object's ETag is already its md5), then
# the manifest, then deletes keys under the prefix the manifest
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
source("scripts/pcic_routed_lib.R")  # routed_table, routed_where, routed_run, routed_fingerprint()
# the routed source's forcing key is the run's model
stopifnot(identical(publish_forcing[["pcic_routed"]], routed_run$model))
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
  dr <- readLines(wb_report("segment_daily_output", release))
  if (!any(grepl(paste0("^wet commit ", attr(cat_local, "provenance")$segment_commit, ";"), sr)) ||
        !any(grepl(paste0("^wet commit ", attr(cat_local, "provenance")$segment_daily_commit, " "), dr))) {
    stop("the segment or daily report has moved on since the tree was built: rerun the build")
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
  # a part whose live object already has this md5 (a single PUT's ETag, read
  # by an anonymous HEAD) is not sent again: the daily parts are most of the
  # bytes and rarely change. An object a failed upload left is not skipped,
  # since its ETag is not the local md5
  live <- cat_local
  live$href <- paste(sub("/manifest.json$", "", publish_url), live$key, sep = "/")
  same <- wet_catalog_verify(live)$ok
  stamp(sum(same), " of ", nrow(cat_local), " parts already live with these bytes")
  for (i in which(!same)) {
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
  stamp("published ", nrow(cat_pub), " parts (", sum(!same), " uploaded), ", length(stale),
        " stale keys deleted; all verify at ", publish_url)
  quit(save = "no")
}

# ---- BUILD ------------------------------------------------------------------------------------------
if (!requireNamespace("crate", quietly = TRUE)) stop("install crate (with crate#31's schemas)")
crate_version <- as.character(utils::packageVersion("crate"))
ds_seg <- paste0(publish_id, "/segment_monthly")
ds_ws <- paste0(publish_id, "/watershed_monthly")
ds_day <- paste0(publish_id, "/segment_daily")
invisible(publish_schema_cols(ds_seg))
invisible(publish_schema_cols(ds_ws))
invisible(publish_schema_cols(ds_day))
# the manifest names each schema at the installed crate's release tag, so
# that tag must hold it: a branch install reports the last release's version
# and hold it as installed: a later edit under an unbumped version would not
for (ds in c(ds_seg, ds_ws, ds_day)) {
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
day_files <- list.files(file.path(fit_dir, "segment_daily"), "\\.parquet$", full.names = TRUE)
if (!length(day_files)) stop("no daily segment table in ", fit_dir, ": run scripts/segment_daily_output.R")
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
# the daily table is made after the monthly one and from it, so its script is
# no input of the monthly table
daily_own <- "scripts/segment_daily_output.R"
# DESCRIPTION is left out: its version moves at every release
changed <- git("diff", "--name-only", seg_commit, "HEAD", "--", "R", "scripts",
               paste0(":(exclude)", c(publish_own, daily_own)))
if (length(changed)) {
  stop("code changed since ", f_seg_report, " was built at ", seg_commit, " (", paste(changed, collapse = ", "),
       "): rerun scripts/wb_output.R and scripts/segment_output.R")
}
# and the fit both tables came from is the one the scoring code ships
source("scripts/wb_score_md5.R")  # score_code_md5
fits <- readRDS(file.path(fit_dir, "fits.rds"))
winner <- readLines(file.path(fit_dir, "aet_winner.txt"))
if (!identical(fits$code_md5, score_code_md5) || !identical(winner[1:2], c(fits$aet, score_code_md5)) ||
      !any(grepl(paste0("scoring code ", score_code_md5, "$"), sr[3]))) {
  stop("the fit, its AET choice or the segment report was made under other scoring code")
}
# The balance's source description names cfu. A switch comes only from a
# user-recorded aet_decision.txt, so the description is rewritten then, for the
# AET chosen, rather than kept for every variant now (#85).
if (!identical(fits$aet, "cfu")) {
  stop("the fit ships AET ", fits$aet, ", but the wet_balance description below names cfu: rewrite it for ",
       fits$aet, " first, with README.md and research/discharge_publish.md, which name it too (#85)")
}
mt <- function(f) max(file.mtime(f))
if (min(file.mtime(seg_files)) < mt(ws_files) || mt(seg_files) > file.mtime(f_seg_report)) {
  stop("the segment table predates the balance output, or postdates its report: rerun scripts/segment_output.R")
}
# the daily table: made from this monthly table, by the daily code as it stands
f_day_report <- wb_report("segment_daily_output", release)
dr <- readLines(f_day_report)
re_day <- "^wet commit ([0-9a-f]+) \\(segment table built at ([0-9a-f]+)\\);"
day_head <- Filter(length, regmatches(dr, regexec(re_day, dr)))
if (length(day_head) != 1L || day_head[[1]][3] != seg_commit) {
  stop(f_day_report, " was not made from the segment table ", f_seg_report, " describes: rerun ",
       "scripts/segment_daily_output.R")
}
day_commit <- day_head[[1]][2]
changed <- git("diff", "--name-only", day_commit, "HEAD", "--", "R", "scripts", paste0(":(exclude)", publish_own))
if (length(changed)) {
  stop("code changed since ", f_day_report, " was built at ", day_commit, " (", paste(changed, collapse = ", "),
       "): rerun scripts/segment_daily_output.R")
}
if (min(file.mtime(day_files)) < mt(seg_files) || mt(day_files) > file.mtime(f_day_report) ||
      !identical(grep("^routed: |^table: ", dr, value = TRUE), grep("^routed: |^table: ", sr, value = TRUE))) {
  stop("the daily table predates the segment table, postdates its report, or names another routed table: ",
       "rerun scripts/segment_daily_output.R")
}
daily_fp <- sub("^daily: ", "", grep("^daily: ", dr, value = TRUE))
stopifnot(length(daily_fp) == 1L)
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
groups_day <- sort(sub("\\.parquet$", "", basename(day_files)))
# a daily part is keyed by its watershed group, labelled with the group's name
drainage <- c(publish_drainage_labels(conn, codes), publish_group_labels(conn, groups_day))
if (!identical(routed_daily_fingerprint(conn), daily_fp)) {
  stop("fwapg's routed days or weights are not those ", f_day_report, " was built from (", daily_fp, ")")
}
# the routed days, read again, for the daily value check
day_inp <- routed_daily_inputs(conn)
# what the value cross-checks compare against: the routed table the segment
# table was built from, all of it, and the lut that gives a segment its watershed
if (!identical(routed_fingerprint(conn), routed_fp)) {
  stop("fwapg's ", routed_table, " is not the table ", f_seg_report, " was built from (", routed_fp, ")")
}
rt_all <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::int AS linear_feature_id, month, q_m3s FROM %s WHERE %s", routed_table, routed_where))
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
# the daily parts: one per source and watershed group, in row groups of 2,048
# segments' days
cols_day <- c("linear_feature_id", "doy", "runoff_mm", "q_m3s", "coverage", "source", "period", "pick")
for (f in day_files) {
  g <- sub("\\.parquet$", "", basename(f))
  x <- as.data.frame(arrow::read_parquet(f))
  if (!identical(names(x), cols_day)) stop(f, " has columns ", paste(names(x), collapse = ", "))
  x$watershed_group_code <- seg_grp$g[match(x$linear_feature_id, seg_grp$id)]
  if (!all(x$watershed_group_code == g)) stop(f, " holds segments of another watershed group")
  key <- paste(x$linear_feature_id, x$doy)
  stopifnot(all(tabulate(match(key[x$pick], unique(key)), nbins = length(unique(key))) == 1L))
  for (src in names(publish_forcing)) {
    p <- x[x$source == src, ]
    if (!nrow(p)) next
    publish_part_write(publish_part_prepare(p, ds_day, "linear_feature_id"), part_path(ds_day, src, g),
                       rows_per_group = 365L * 2048L)
    tally[[length(tally) + 1L]] <- data.frame(dataset = "segment_daily", source = src, code = g, rows = nrow(p),
                                              segments = length(unique(p$linear_feature_id)),
                                              picked = sum(p$pick & p$doy == 1L))
  }
  rm(x, p)
  gc(verbose = FALSE)
}
stamp(length(day_files), " daily groups written")
tally <- do.call(rbind, tally)

sources <- list(
  list(source = "pcic_routed",
       description = paste("PCIC's routed streamflow (Raven routing over VIC-GL, hydromosaic, PNWNAmet forcing),",
                           sprintf("monthly and day-of-year means %s placed on FWA segments by", routed_run$period),
                           "NewGraphEnvironment/fwapg#6 and #25; annual is the mean of the 12 monthly means.",
                           "Each month and each day is routed and clamped at zero on its own, so a month's",
                           "days can average above the month where a clamp applied; 29 February is folded",
                           "into 28 February."),
       citation = "Pacific Climate Impacts Consortium, University of Victoria. Hydromosaic routed streamflow. https://services.pacificclimate.org/",
       provenance = list(routed = sub("^routed: ", "", routed_line), routed_fingerprint = routed_fp,
                    routed_daily_fingerprint = daily_fp)),
  list(source = "wet_balance",
       description = paste(c("wet's open water balance (#11): climr 1981-2010 precipitation and temperature,",
                             "CGIAR actual evapotranspiration floored by Fu-Budyko, fitted at HYDAT gauges,",
                             "accumulated upstream over FWA fundamental watersheds.",
                             # how the monthly shares are made (#102), and the snow predictors they use,
                             # when the fit ships them (#16)
                             paste("Daily values lay each published month on a within-month shape, the",
                                   "inverse-distance mean of the within-month shapes of the five most similar",
                                   "calibration gauges (#70), so a calendar month's days average to its month."),
                             switch(fits$share_method,
                                    regression = if (identical(fits$share_spec, "snow")) {
                                      paste("Monthly shares also use ERA5-Land 1981-2010 snowmelt timing and peak",
                                            "snow water equivalent (via NewGraphEnvironment/cd); contains modified",
                                            "Copernicus Climate Change Service information.")
                                    },
                                    donor = paste("Monthly shares are the inverse-distance mean of the observed",
                                                  "monthly shares of the five most similar HYDAT calibration gauges",
                                                  "(#102), similar in",
                                                  if (identical(fits$share_spec, "snow")) {
                                                    paste("elevation, location, and ERA5-Land 1981-2010 snowmelt",
                                                          "timing and peak snow water equivalent (via",
                                                          "NewGraphEnvironment/cd); contains modified Copernicus",
                                                          "Climate Change Service information.")
                                                  } else {
                                                    "elevation and location."
                                                  }),
                                    stop("the wet_balance description has no text for share method ",
                                         fits$share_method)),
                             NULL), collapse = " "),
       citation = "New Graph Environment Ltd. wet: stream flow for the BC Freshwater Atlas. https://github.com/NewGraphEnvironment/wet",
       provenance = list(fit_release = release, province_run = basename(key_dir)))
)
# the manifest is publishable only once every check below passes: until then
# it is manifest.pending.json, which PUBLISH does not read
f_pending <- file.path(root, "manifest.pending.json")
wet_manifest_write(root, publish_id, drainage = drainage, sources = sources,
                   provenance = list(wet_version = as.character(utils::packageVersion("wet")),
                                     wet_commit = wet_commit, segment_commit = seg_commit,
                                     segment_daily_commit = day_commit),
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
# ---- the daily parts (#99) -------------------------------------------------------------------------
# Routed days are routed again here by another path than the build's (each
# distinct upstream set summed once, by colSums), so they are compared after
# rounding: equal, or one 1e-5 step apart where the raw value sits on a
# rounding tie, counted on its own. The balance's days are made again from the
# fit's output and shape, through the lut, and must be equal; their months
# must be the segment parts' months (relative 1e-9). Four columns of every
# daily part are checked against the daily table it was cut from.
shape <- readRDS(file.path(fit_dir, "shape_daily.rds"))
stopifnot(identical(shape$method, "donor"), identical(shape$code_md5, fits$code_md5))
m_doy <- wet:::wet_doy_month()
bal_days <- list()  # by drainage: watershed IDs and their 365 days
for (code in codes_ws) {
  out <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "output", paste0(code, ".parquet")),
                                           col_select = c("watershed_feature_id", "month", "discharge_m3s")))
  up <- readRDS(file.path(key_dir, "upstream", paste0(code, ".rds")))
  nws <- nrow(up)
  stopifnot(identical(out$watershed_feature_id[seq_len(nws)], up$watershed_feature_id))
  q_mon <- matrix(out$discharge_m3s[out$month > 0L], nws, 12)
  ok <- which(!is.na(out$discharge_m3s[seq_len(nws)]))
  bal_days[[code]] <- list(id = up$watershed_feature_id[ok],
                           q = wet_shape_daily(q_mon[ok, , drop = FALSE],
                                               wet_shape_predict(shape$fit, up[ok, shape$static])))
  rm(out, up, q_mon)
}
bal_ws <- unlist(lapply(bal_days, `[[`, "id"), use.names = FALSE)
bal_at <- cbind(rep(seq_along(bal_days), vapply(bal_days, function(b) length(b$id), 1L)),
                unlist(lapply(bal_days, function(b) seq_along(b$id)), use.names = FALSE))
stopifnot(!anyDuplicated(bal_ws))
route_by_set <- function(fold, w) {
  key <- vapply(w$upstream_subids, paste, "", collapse = ",")
  u <- unique(key)
  sums <- t(vapply(u, function(k) {
    if (!nzchar(k)) return(numeric(365))
    colSums(fold$q_acc[match(as.integer(strsplit(k, ",", fixed = TRUE)[[1]]), fold$subid), , drop = FALSE])
  }, numeric(365), USE.NAMES = FALSE))
  sums <- matrix(sums, ncol = 365)
  sums[match(key, u), , drop = FALSE] + fold$q_local[match(w$subid, fold$subid), , drop = FALSE] * w$share
}
cols_dval <- c("linear_feature_id", "doy", "q_m3s", "runoff_mm", "coverage", "pick")
# the balance's published months 1-12, read once
seg_bal <- do.call(rbind, lapply(codes_seg, function(code) {
  x <- read_part(part_path(ds_seg, "wet_balance", code), c("linear_feature_id", "month", "q_m3s"))
  x[x$month > 0L, ]
}))
day_tie <- 0
day_seen <- list()
for (g in groups_day) {
  pr <- read_part(part_path(ds_day, "pcic_routed", g), cols_dval)
  pb <- read_part(part_path(ds_day, "wet_balance", g), cols_dval)
  day_seen[[g]] <- rbind(data.frame(source = "pcic_routed", id = unique(pr$linear_feature_id)),
                         data.frame(source = "wet_balance", id = unique(pb$linear_feature_id)))
  if (nrow(pr)) {
    ids <- unique(pr$linear_feature_id)
    w <- day_inp$weights[match(ids, day_inp$weights$linear_feature_id), ]
    stopifnot(!anyNA(w$linear_feature_id))
    raw <- route_by_set(day_inp$fold, w)
    mine <- data.frame(linear_feature_id = rep(ids, each = 365), doy = rep(1:365, length(ids)),
                       q_m3s = wet:::wet_routed_round(pmax(as.vector(t(raw)), 0)), raw = as.vector(t(raw)))
    r <- wet_values_compare(pr, mine, tol = 0, time = "doy")
    # the one-step differences that sit on a tie, which two summation orders may round apart
    j <- match(as.numeric(pr$linear_feature_id) * 512 + pr$doy, as.numeric(mine$linear_feature_id) * 512 + mine$doy)
    f <- abs(mine$raw[j]) * 1e5
    tie <- !is.na(j) & pr$q_m3s != mine$q_m3s[j] & abs(pr$q_m3s - mine$q_m3s[j]) <= 1.000001e-5 &
      abs(f - floor(f) - 0.5) < 1e-6 + 1e-10 * f
    day_tie <- day_tie + sum(tie)
    vc_add("daily routed = routed again", g,
           c(compared = r[["compared"]], differing = r[["differing"]] - sum(tie), max_abs_diff = r[["max_abs_diff"]]))
    rm(raw, mine)
  }
  if (nrow(pb)) {
    ids <- unique(pb$linear_feature_id)
    ws <- lut$watershed_feature_id[match(ids, lut$linear_feature_id)]
    at <- bal_at[match(ws, bal_ws), , drop = FALSE]
    stopifnot(!anyNA(at))
    q <- t(vapply(seq_along(ids), function(i) bal_days[[at[i, 1]]]$q[at[i, 2], ], numeric(365)))
    expected <- data.frame(linear_feature_id = rep(ids, each = 365), doy = rep(1:365, length(ids)),
                           q_m3s = as.vector(t(q)))
    vc_add("daily balance = output x shape via lut", g, wet_values_compare(pb, expected, tol = 0, time = "doy"))
    # the balance's months, as the segment parts publish them
    mon <- stats::aggregate(q_m3s ~ linear_feature_id + month,
                            data.frame(pb[c("linear_feature_id", "q_m3s")], month = m_doy[pb$doy]), mean)
    vc_add("daily balance months = segment parts", g,
           wet_values_compare(mon, seg_bal[seg_bal$linear_feature_id %in% ids, ]))
    rm(q, expected, mon)
  }
  st <- as.data.frame(arrow::read_parquet(file.path(fit_dir, "segment_daily", paste0(g, ".parquet")),
                                          col_select = c(cols_dval, "source")))
  for (v in c("q_m3s", "runoff_mm", "coverage", "pick")) {
    for (src in c("pcic_routed", "wet_balance")) {
      vc_add(paste("daily parts = table:", v), g,
             wet_values_compare(if (src == "pcic_routed") pr else pb, st[st$source == src, ], value = v, tol = 0,
                                time = "doy"))
    }
  }
  rm(pr, pb, st)
  gc(verbose = FALSE)
}
stamp("daily values checked")

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
# the daily parts: every monthly segment's 365 days, the same picks, and every value checked
day_t <- tally[tally$dataset == "segment_daily", ]
day_seen <- do.call(rbind, day_seen)
seg_ids <- function(src) {
  unlist(lapply(codes_seg, function(code) {
    unique(read_part(part_path(ds_seg, src, code), c("linear_feature_id", "month"))$linear_feature_id)
  }), use.names = FALSE)
}
checks["daily_segments"] <- all(vapply(names(publish_forcing), function(src) {
  setequal(day_seen$id[day_seen$source == src], seg_ids(src)) && !anyDuplicated(day_seen$id[day_seen$source == src])
}, TRUE)) && all(day_t$rows == 365 * day_t$segments)
checks["daily_picked"] <- sum(day_t$picked[day_t$source == "pcic_routed"]) == picked_routed &&
  sum(day_t$picked[day_t$source == "wet_balance"]) == picked_balance
day_checks <- c("daily routed = routed again", "daily balance = output x shape via lut",
                grep("^daily parts = table: ", vc_sum$check, value = TRUE))
checks["daily_values"] <- length(day_checks) == 6L && all(vapply(day_checks, n_vc, 0, "differing") == 0) &&
  all(vapply(day_checks, n_vc, 0, "compared") ==
        c(sum(day_t$rows[day_t$source == "pcic_routed"]), sum(day_t$rows[day_t$source == "wet_balance"]),
          rep(sum(day_t$rows), 4)))
checks["daily_months"] <- n_vc("daily balance months = segment parts", "differing") == 0 &&
  n_vc("daily balance months = segment parts", "compared") == 12 * sum(day_t$segments[day_t$source == "wet_balance"])
duck <- DBI::dbConnect(duckdb::duckdb())
hive_day <- DBI::dbGetQuery(duck, sprintf("
  SELECT scenario, forcing, source, count(*)::DOUBLE AS rows, count(*) FILTER (WHERE doy = 1 AND pick)::DOUBLE AS picked
  FROM read_parquet('%s/segment_daily/*/*/*/*.parquet', hive_partitioning = true)
  GROUP BY ALL ORDER BY source", root))
DBI::dbDisconnect(duck, shutdown = TRUE)
checks["daily_hive_read"] <- sum(hive_day$rows) == sum(day_t$rows) && sum(hive_day$picked) == picked_routed + picked_balance
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
          routed_total, fp_total),
  sprintf("daily routed values one 1e-5 step apart at a rounding tie (not counted as differing): %.0f", day_tie),
  sprintf("daily: table built at %s; routed days and weights: %s", day_commit, daily_fp), "",
  "## Against the published tree", pub_line, "",
  "## What a reader sees (duckdb, hive_partitioning = true, over the local tree)",
  sprintf("%-10s %-9s %-12s %11.0f rows %9.0f fresh-subquery rows", hive$scenario, hive$forcing, hive$source,
          hive$rows, hive$fresh),
  sprintf("segment_daily %-10s %-9s %-12s %11.0f rows %9.0f picked on day 1", hive_day$scenario, hive_day$forcing,
          hive_day$source, hive_day$rows, hive_day$picked), "",
  sprintf("## Row-group pruning: a read for %s opens %d of %d row groups in %d segment parts",
          group_probe, rg[["read"]], rg[["total"]], rg[["files"]]), "",
  "## Parts",
  "picked: for segments, annual rows picked (daily: day-1 rows); for watersheds, NA-flow watersheds dropped",
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
