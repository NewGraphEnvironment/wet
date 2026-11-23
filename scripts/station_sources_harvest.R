# The province's non-integrated discharge as wet reads it: the harvest report (#142, #179)
#
# Usage: WET_HYDAT_RELEASE=20260717 Rscript scripts/station_sources_harvest.R
#
# Two tiers, on the pinned snapshot (wet_bcenv_snapshot) and HYDAT 20260717:
#
# (i) Under the survey's own rules (UTC days of >= 20 hours, no plausibility
#     bound, no negative day dropped; scripts/station_sources_probe.R, #123),
#     the reader must reproduce the survey:
#     - its daily rows exactly: the probe's own query, copied verbatim below,
#       run on the same files, against wet_bcenv_days(utc = TRUE);
#     - every provincial row of the tracked survey report's "Every station
#       read" table (first-last years, HYDAT match and class, window-years
#       all/new, seasonal) and its provincial "Per network" line (211 read, 110
#       passing), through scripts/station_sources_lib.R's copies of the
#       probe's HYDAT match.
#     Any difference fails the run (exit 1).
# (ii) Under the shipped rules (local-standard-time days, the bound, negative
#     days dropped, status), each station whose first-last years, window-years
#     outside HYDAT or pass moved is listed with the rule that moved it:
#     "LST" where local-standard-time days alone move it, "bound" where only
#     the bound and the negative rule do. Per network: stations, days, the
#     status shares, and days the bound dropped.
#
# The Water Tool's third-party gauges (#144, #195), on the pinned Tool snapshot
# (wet_bcwatertool_snapshot), in the same two tiers:
#
# (i) Under the survey's rules (every "Preliminary Discharge" row with a value,
#     no bound, no negative day dropped), the reader must reproduce the survey:
#     - its daily rows exactly: the probe's read_wt() parse, copied verbatim
#       below, on every pinned third-party CSV, against wet_bcwatertool_days();
#     - the survey report's 103 third-party "Every station read" rows (the
#       Tool's listings outside "BC ENV - Real-time Water Data Reporting" and
#       the provincial registry), cut to their first 13 fields;
#     - its third-party "Per network" lines;
#     - its passing third-party stations (35), and the seven listings it puts
#       at a provincial station's site, which must be the registry's
#       continuing listings, each with the same provincial station.
#     Any difference fails the run (exit 1).
# (ii) Under the shipped rules (wet_bcwatertool_daily(): the bound of the
#     nearest HYDAT station's sub-drainage, negative days dropped, QA as
#     status): per network, stations, days and status shares; every day the
#     bound drops; every listing the registry leaves out, with its reason;
#     per continuing listing, the days it adds before its provincial station's
#     record begins (the first day the provincial files hold any usable hour
#     of it, the registry's continues_before); and the Tool registry
#     (inst/extdata/station_sources/bcwatertool_<snapshot>_hydat.csv) held to
#     the reader's first and last days, the selection rule recomputed from the
#     station list, the nearest HYDAT station, the HYDAT match and the name
#     rule; a mismatch fails the run (rewrite it with
#     data-raw/station_sources_bcwatertool.R).
#
# It also holds the shipped station registry's first and last days
# (inst/extdata/station_sources/bcenv_<snapshot>_hydat.csv, which
# wet_station_list() returns) to what the shipped reader returns: the
# registry records them when the snapshot is pinned, so a change to the
# reader's rules (the bound, the hours rule) must rewrite it
# (data-raw/station_sources_snapshot.R); a mismatch fails the run.
#
# Report: data/checks/station_sources_harvest_<snapshot>.txt (no timestamp; a
# rerun on the same snapshot and HYDAT reproduces it byte for byte).

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/station_sources_lib.R")

release <- wb_release()
if (release != "20260717") stop("the survey names HYDAT 20260717, not ", release, call. = FALSE)
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) {
  stop("run with Rscript, so the script's own md5 can be recorded", call. = FALSE)
}
code_md5 <- unname(tools::md5sum(self))
snapshot <- wet_bcenv_snapshot
cache <- tools::R_user_dir("wet", "cache")
survey <- readLines(file.path("data", "checks", "station_sources_20260717.txt"))
report <- file.path("data", "checks", sprintf("station_sources_harvest_%s.txt", snapshot))
hy <- hydat_stations(wb_hydat(release))
paths <- wet_bcenv(snapshot)

lh <- utils::read.csv("inst/vignette-data/life_history_bulk.csv")
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stopifnot(identical(windows$start, c("05-01", "08-01")), identical(windows$end, c("08-01", "09-15")))
min_years <- 3

# ---- the probe's provincial daily rows, its own query (station_sources_probe.R, verbatim) -----
probe_prov_q <- function(prov_paths) {
  prov_tmp <- vapply(prov_paths, function(path) {
    out <- tempfile(fileext = ".csv")
    i <- file(path, "rb")
    o <- file(out, "wb")
    while (length(b <- readBin(i, "raw", 64e6))) {
      b[b == as.raw(0x96)] <- as.raw(0x2d)
      writeBin(b, o)
    }
    close(i)
    close(o)
    out
  }, "")
  csv_cols <- "columns = {'id': 'VARCHAR', 'name': 'VARCHAR', 'status': 'VARCHAR', 'lat': 'DOUBLE', 'lon': 'DOUBLE',
  't': 'VARCHAR', 'param': 'VARCHAR', 'value': 'DOUBLE', 'unit': 'VARCHAR', 'grade': 'VARCHAR'}"
  tmp_list <- paste(sprintf("'%s'", prov_tmp), collapse = ", ")
  duck <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(duck, shutdown = TRUE))
  invisible(DBI::dbExecute(duck, sprintf("
  CREATE TABLE raw AS
  SELECT *, row_number() OVER (PARTITION BY id, t ORDER BY list_position([%s], filename)) AS k
  FROM read_csv([%s], header = true, auto_detect = false, strict_mode = false, filename = true, %s)
  WHERE trim(param) = 'Discharge' AND value IS NOT NULL", tmp_list, tmp_list, csv_cols)))
  unlink(prov_tmp)
  invisible(DBI::dbExecute(duck, "
  CREATE TABLE h AS
  SELECT id, name, status, lat, lon, t, grade,
         CASE WHEN trim(unit) = 'l/s' THEN value / 1000 ELSE value END AS value
  FROM raw WHERE k = 1 AND NOT isnan(value)"))
  prov_q <- DBI::dbGetQuery(duck, "
  SELECT trim(id) AS station_number, CAST(substr(t, 1, 10) AS DATE) AS date, avg(value) AS q_m3s, count(*) AS hours
  FROM h WHERE trim(grade) <> 'Unusable' GROUP BY 1, 2 ORDER BY 1, 2")
  prov_q$date <- as.Date(prov_q$date)
  prov_q[prov_q$hours >= 20, c("station_number", "date", "q_m3s")]
}

# ---- the survey's per-station quantities, from any set of daily rows --------------------------
st_meta <- wet_bcenv_stations(snapshot)
station_table <- function(q) {
  rng <- lapply(split(q$date, q$station_number), range)
  yr <- function(i) {
    vapply(st_meta$station_number, function(s) {
      if (is.null(rng[[s]])) NA_integer_ else as.integer(format(rng[[s]][i], "%Y"))
    }, 0L)
  }
  s <- data.frame(station_id = st_meta$station_number, name = st_meta$name, lon = st_meta$lon, lat = st_meta$lat,
                  first = yr(1), last = yr(2))
  s <- hydat_match(s, hy)
  ws <- wet_window_stats(q[, c("station_number", "date", "q_m3s")], windows, stats = "mean")
  q_from <- hy$q_from[match(s$hydat, hy$station_number)]
  q_to <- hy$q_to[match(s$hydat, hy$station_number)]
  count <- function(i, new_only) {
    r <- ws[ws$station_number == s$station_id[i], ]
    if (new_only && !is.na(q_from[i])) r <- r[r$year < q_from[i] | r$year > q_to[i], ]
    if (!nrow(r)) return(0L)
    max(table(factor(r$period, levels = windows$window)))
  }
  s$wy <- vapply(seq_len(nrow(s)), count, 0L, new_only = FALSE)
  s$wy_new <- vapply(seq_len(nrow(s)), count, 0L, new_only = TRUE)
  winter <- unique(q$station_number[format(q$date, "%m") %in% c("12", "01", "02")])
  s$daily <- !is.na(s$first)
  s$seasonal <- ifelse(s$daily, !s$station_id %in% winter, NA)
  s$new <- s$class != "duplicate"
  s$pass <- s$new & s$daily & s$wy_new >= min_years
  s
}

# ---- tier (i): the survey's rules -------------------------------------------------------------
fail <- character()
probe <- probe_prov_q(paths)
utc <- wet_bcenv_days_read(wet_bcenv_days(snapshot, cache, utc = TRUE), NULL)
utc <- utc[utc$hours >= 20, c("station_number", "date", "q_m3s")]
utc <- utc[order(utc$station_number, utc$date, method = "radix"), ]
probe <- probe[order(probe$station_number, probe$date, method = "radix"), ]
same_rows <- identical(paste(utc$station_number, utc$date), paste(probe$station_number, probe$date))
max_rel <- if (same_rows) max(abs(utc$q_m3s - probe$q_m3s) / pmax(abs(probe$q_m3s), 1e-9)) else NA_real_
if (!same_rows || max_rel > 1e-12) fail <- c(fail, "daily rows")

t1 <- station_table(utc)
mine <- sprintf(paste0("  bcenv | BC ENV non-integrated (provincial files) | %s | %s |",
         " %.4f | %.4f | %s-%s | %s | %s | %s | %s | %d/%d | %s"),
                t1$station_id, t1$name, t1$lon, t1$lat, t1$first, t1$last, ifelse(t1$daily, "daily", "no complete day"),
                regulation_of(t1$name),
                ifelse(is.na(t1$hydat), "-", sprintf("%s (%.2f km, %s)", t1$hydat, t1$hydat_km, t1$hydat_q)),
                t1$class, t1$wy, t1$wy_new, ifelse(is.na(t1$seasonal), "-", t1$seasonal))
theirs <- grep("^  bcenv \\| ", survey, value = TRUE)
# the survey's rows carry near misses and other listings after these columns
theirs <- sub("^((?:[^|]*\\|){12}[^|]*?) \\|.*$", "\\1", theirs, perl = TRUE)
theirs_id <- vapply(strsplit(theirs, " \\| "), `[`, "", 3)
row_diff <- setdiff(union(mine, theirs), intersect(mine, theirs))
# as multisets: a set difference cannot see a line given twice
if (length(row_diff) || !identical(sort(mine, method = "radix"), sort(theirs, method = "radix"))) {
  fail <- c(fail, "station rows")
}
net_mine <- sprintf("read %4d  Q %4d  new %4d  same-site %3d  dup %3d  >=1 %4d  >=3 %4d  seasonal %s",
                    nrow(t1), nrow(t1), sum(t1$class == "not in HYDAT"), sum(t1$class == "same site, new years"),
                    sum(t1$class == "duplicate"), sum(t1$new & t1$wy_new >= 1), sum(t1$new & t1$wy_new >= min_years),
                    sum(t1$seasonal, na.rm = TRUE))
net_theirs <- sub("^.*(read .*seasonal [0-9-]+).*$", "\\1", grep("^  bcenv  ", survey, value = TRUE))
if (!identical(net_mine, net_theirs)) fail <- c(fail, "network line")

# ---- tier (ii): the shipped rules -------------------------------------------------------------
lst <- wet_bcenv_days_read(wet_bcenv_days(snapshot, cache), NULL)
held <- unique(lst$station_number)  # every station with a usable hour, complete day or not
lst_all <- lst
lst <- lst[lst$hours >= 20, ]
shipped <- wet_bcenv_daily(NULL, snapshot)
t2 <- station_table(lst[, c("station_number", "date", "q_m3s")])
t3 <- station_table(shipped)
# per station, element by element; two NAs are equal
differs <- function(x, y) ifelse(is.na(x) | is.na(y), is.na(x) != is.na(y), x != y)
moved <- function(a, b) {
  stopifnot(identical(a$station_id, b$station_id))
  differs(a$first, b$first) | differs(a$last, b$last) | a$wy_new != b$wy_new | a$pass != b$pass
}
by_lst <- moved(t1, t2)
by_bound <- moved(t2, t3)
any_move <- by_lst | by_bound
drop_bound <- nrow(lst[lst$q_m3s >= 0, ]) - nrow(shipped)
rng <- lapply(split(shipped$date, shipped$station_number), range)
reg_first <- as.Date(vapply(st_meta$station_number, function(s) if (is.null(rng[[s]])) NA_real_ else
  as.numeric(rng[[s]][1]), 0), origin = "1970-01-01")
reg_last <- as.Date(vapply(st_meta$station_number, function(s) if (is.null(rng[[s]])) NA_real_ else
  as.numeric(rng[[s]][2]), 0), origin = "1970-01-01")
reg_off <- st_meta$station_number[is.na(match(paste(st_meta$station_number, reg_first, reg_last),
                                              paste(st_meta$station_number, st_meta$first, st_meta$last)))]
# a station the reader returns that the registry lacks would be unreachable from wet_station_daily()
reg_missing <- setdiff(held, st_meta$station_number)
# the registry's HYDAT site against the survey's match, which tier (i) verifies (the site does not depend on years)
stopifnot(identical(t1$station_id, st_meta$station_number))
reg_site <- st_meta$station_number[differs(st_meta$hydat_site, t1$hydat) | differs(st_meta$hydat_km, t1$hydat_km)]
# the registry's regulation against the name rule it was written by
reg_reg <- st_meta$station_number[differs(st_meta$regulation, ifelse(regulation_of(st_meta$name) == "unknown",
                                                                     "unknown", "regulated by name"))]
# wet_station_daily() sends a HYDAT-shaped number to the federal sources, never to the registry
reg_hydat <- st_meta$station_number[grepl(wet_hydat_number, st_meta$station_number)]
reg_fail <- length(reg_off) > 0 || length(reg_missing) > 0 || length(reg_site) > 0 || length(reg_reg) > 0 ||
  length(reg_hydat) > 0
neg <- sum(lst$q_m3s < 0)

# ---- the Water Tool: tier (i), the survey's rules ---------------------------------------------
tool_snapshot <- wet_bcwatertool_snapshot
tool_man <- wet:::wet_bcwatertool_manifest(tool_snapshot)
tool_dir <- file.path(cache, "station_sources", "bcwatertool", tool_snapshot)
`%||%` <- function(a, b) if (is.null(a)) b else a
tool_list_path <- file.path(tool_dir, wet:::wet_bcwatertool_list_file(tool_snapshot))
wet:::wet_bcenv_check(tool_list_path, tool_man$bytes[tool_man$file == basename(tool_list_path)],
                      tool_man$md5[tool_man$file == basename(tool_list_path)])
feat <- jsonlite::fromJSON(tool_list_path, simplifyVector = FALSE)$features
wt_all <- do.call(rbind, lapply(feat, function(f) {
  p <- f$properties
  data.frame(id = p$id, nid = p$nid %||% NA_character_, name = p$name, net = p$net,
             status = p$status %||% NA_character_, n_yr = length(p$yr),
             lon = f$geometry$coordinates[[1]], lat = f$geometry$coordinates[[2]], stringsAsFactors = FALSE)
}))
# the survey's listings (scripts/station_sources_probe.R, verbatim)
wt <- wt_all[wt_all$n_yr > 0 & wt_all$net != "Water Survey of Canada", ]
wt <- wt[order(wt$nid, wt$id, method = "radix"), ]
wt_dup <- wt[duplicated(wt$nid), ]
wt <- wt[!duplicated(wt$nid), ]   # the tool repeats some stations under one nid
tool_benv <- "BC ENV - Real-time Water Data Reporting"
tp <- wt[wt$net != tool_benv & !wt$nid %in% st_meta$station_number, ]
tool_paths <- wet:::wet_bcwatertool(as.character(tp$id), tool_snapshot)
# the probe's read_wt(), its parse verbatim; the fetch replaced by the pinned file
read_wt <- function(id, path) {
  if (is.na(path)) return(list(licence = NA_character_, area = NA_real_, q = NULL, analyses = "csv HTTP status"))
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  meta <- grep("^# ", lines, value = TRUE)
  field <- function(k) {
    m <- grep(paste0("^# ", k, ","), meta, value = TRUE)
    if (length(m)) gsub('^"|"$', "", sub(paste0("^# ", k, ","), "", m[1])) else NA_character_
  }
  body <- lines[!grepl("^#", lines) & nzchar(lines)]
  x <- if (length(body) > 1) utils::read.csv(text = body, quote = "", na.strings = c("", "NA"),
                                              stringsAsFactors = FALSE) else NULL
  q <- if (!is.null(x)) x[x$Analysis == "Preliminary Discharge" & !is.na(x$Value), ] else NULL
  list(licence = field("Data Licence Information"), area = suppressWarnings(as.numeric(field("Drainage Area"))),
       q = if (!is.null(q) && nrow(q)) data.frame(station_number = as.character(id), date = as.Date(q$Datetime),
                                                  q_m3s = as.numeric(q$Value), qa = q$QA) else NULL,
       analyses = if (!is.null(x)) paste(sort(unique(x$Analysis), method = "radix"), collapse = "; ") else "")
}
tp_read <- lapply(seq_len(nrow(tp)), function(i) read_wt(tp$id[i], tool_paths[i]))
tp$discharge <- vapply(tp_read, function(r) !is.null(r$q), FALSE)
probe_wt <- do.call(rbind, lapply(tp_read, function(r) r$q))
probe_wt <- probe_wt[order(probe_wt$station_number, probe_wt$date, method = "radix"), ]
mine_wt <- wet:::wet_bcwatertool_days(as.character(tp$id), tool_snapshot)
mine_wt <- mine_wt[order(mine_wt$id, mine_wt$date, method = "radix"), ]
tool_same_rows <- identical(paste(mine_wt$id, mine_wt$date, mine_wt$qa),
                            paste(probe_wt$station_number, probe_wt$date, probe_wt$qa)) &&
  identical(mine_wt$q_m3s, probe_wt$q_m3s)
tool_fail <- character()
if (!tool_same_rows) tool_fail <- c(tool_fail, "Tool daily rows")

# the survey's per-listing quantities, from the survey's days
sq <- probe_wt
sq$station_number <- tp$nid[match(sq$station_number, as.character(tp$id))]
rng_y <- lapply(split(sq$date, sq$station_number), function(d) as.integer(format(range(d), "%Y")))
ts <- data.frame(station_id = tp$nid, name = tp$name, lon = tp$lon, lat = tp$lat,
                 first = vapply(tp$nid, function(s) rng_y[[s]][1] %||% NA_integer_, 0L),
                 last = vapply(tp$nid, function(s) rng_y[[s]][2] %||% NA_integer_, 0L))
ts <- hydat_match(ts, hy)
ws_t <- wet_window_stats(sq[, c("station_number", "date", "q_m3s")], windows, stats = "mean")
tq_from <- hy$q_from[match(ts$hydat, hy$station_number)]
tq_to <- hy$q_to[match(ts$hydat, hy$station_number)]
tcount <- function(i, new_only) {
  r <- ws_t[ws_t$station_number == ts$station_id[i], ]
  if (new_only && !is.na(tq_from[i])) r <- r[r$year < tq_from[i] | r$year > tq_to[i], ]
  if (!nrow(r)) return(0L)
  max(table(factor(r$period, levels = windows$window)))
}
ts$wy <- vapply(seq_len(nrow(ts)), tcount, 0L, new_only = FALSE)
ts$wy_new <- vapply(seq_len(nrow(ts)), tcount, 0L, new_only = TRUE)
ts$basis <- ifelse(tp$discharge, "daily", "no discharge series")
twinter <- unique(sq$station_number[format(sq$date, "%m") %in% c("12", "01", "02")])
ts$seasonal <- ifelse(ts$basis == "daily", !ts$station_id %in% twinter, NA)
ts$new <- ts$class != "duplicate" & ts$basis == "daily"
ts$pass <- ts$new & ts$wy_new >= min_years
ts$network <- tp$net
tmine <- sprintf("  bcwatertool | %s | %s | %s | %.4f | %.4f | %s-%s | %s | %s | %s | %s | %d/%d | %s",
                 ts$network, ts$station_id, ts$name, ts$lon, ts$lat, ts$first, ts$last, ts$basis,
                 regulation_of(ts$name),
                 ifelse(is.na(ts$hydat), "-", sprintf("%s (%.2f km, %s)", ts$hydat, ts$hydat_km, ts$hydat_q)),
                 ts$class, ts$wy, ts$wy_new, ifelse(is.na(ts$seasonal), "-", ts$seasonal))
tsurvey <- grep("^  bcwatertool \\| ", survey, value = TRUE)
tsurvey <- tsurvey[!startsWith(tsurvey, paste0("  bcwatertool | ", tool_benv, " | "))]
ttheirs <- sub("^((?:[^|]*\\|){12}[^|]*?) \\|.*$", "\\1", tsurvey, perl = TRUE)
trow_diff <- setdiff(union(tmine, ttheirs), intersect(tmine, ttheirs))
if (length(trow_diff) || !identical(sort(tmine, method = "radix"), sort(ttheirs, method = "radix"))) {
  tool_fail <- c(tool_fail, "Tool station rows")
}
tnets <- sort(unique(ts$network), method = "radix")
tnet_mine <- vapply(tnets, function(n) {
  x <- ts[ts$network == n, ]
  q <- x$basis == "daily"
  sprintf("  %-12s %-60s read %4d  Q %4d  new %4d  same-site %3d  dup %3d  >=1 %4d  >=3 %4d  seasonal %s",
          "bcwatertool", substr(n, 1, 60), nrow(x), sum(q), sum(q & x$class == "not in HYDAT"),
          sum(q & x$class == "same site, new years"), sum(q & x$class == "duplicate"),
          sum(x$new & x$wy_new >= 1), sum(x$new & x$wy_new >= min_years),
          if (all(is.na(x$seasonal))) "-" else as.character(sum(x$seasonal, na.rm = TRUE)))
}, "")
tnet_theirs <- sub("  \\[.*$", "", grep("^  bcwatertool  ", survey, value = TRUE))
tnet_theirs <- tnet_theirs[!grepl(paste0("^  bcwatertool  ", tool_benv, " "), tnet_theirs)]
if (!identical(unname(tnet_mine), tnet_theirs)) tool_fail <- c(tool_fail, "Tool network lines")
# passing, read from the survey's rows: not a duplicate, daily, >= 3 new window-years
tf <- strsplit(ttheirs, " \\| ")
tpass_theirs <- vapply(tf[vapply(tf, function(f) f[11] != "duplicate" && f[8] == "daily" &&
                                    as.integer(sub("^.*/", "", f[12])) >= min_years, FALSE)], `[`, "", 3)
if (!setequal(ts$station_id[ts$pass], tpass_theirs) || length(tpass_theirs) != 35) {
  tool_fail <- c(tool_fail, "Tool passing stations")
}
# the survey's shared sites: third-party rows whose "same site listed as" names a provincial station
prov_re <- "BC ENV non-integrated \\(provincial files\\) ([0-9A-Z]+)"
tshared <- tsurvey[grepl(prov_re, tsurvey)]
tshared <- data.frame(nid = vapply(strsplit(tshared, " \\| "), `[`, "", 3),
                      prov = sub(paste0("^.*", prov_re, ".*$"), "\\1", tshared))
treg <- wet:::wet_bcwatertool_against(wet_bcwatertool_stations(tool_snapshot), snapshot)
tcont <- treg[!is.na(treg$continues), ]
tshared_ok <- nrow(tshared) == 7 &&
  setequal(paste(tshared$nid, tshared$prov), paste(tcont$station_number, tcont$continues))
if (!tshared_ok) tool_fail <- c(tool_fail, "Tool shared sites")

# ---- the Water Tool: tier (ii), the shipped rules ---------------------------------------------
tshipped <- wet_bcwatertool_daily(treg$station_number, tool_snapshot)
tnobound <- wet_bcwatertool_daily(treg$station_number, tool_snapshot, bound = Inf)
tparsed <- wet:::wet_bcwatertool_days(treg$id, tool_snapshot)
tneg <- sum(tparsed$q_m3s < 0)
tdropped <- tnobound[is.na(match(paste(tnobound$station_number, tnobound$date),
                                 paste(tshipped$station_number, tshipped$date))), ]
# the registry: first and last days, the selection, the nearest HYDAT station, the HYDAT match, the name rule
# a continuing listing's registry days are those before its cut, the first day the provincial
# files hold any usable hour of its station (complete or not)
pstart <- vapply(split(as.numeric(lst_all$date), lst_all$station_number), min, 0)
tcut <- as.Date(unname(pstart[tcont$continues]), origin = "1970-01-01")
treg_cut <- tcont$station_number[differs(as.numeric(tcont$continues_before), as.numeric(tcut))]
tk_cut <- tcont$continues_before[match(tshipped$station_number, tcont$station_number)]
tin <- tshipped[is.na(match(tshipped$station_number, tcont$station_number)) | is.na(tk_cut) |
                  tshipped$date < tk_cut, ]
trng <- lapply(split(tin$date, tin$station_number), range)
tday <- function(k) as.Date(vapply(treg$station_number, function(s) if (is.null(trng[[s]])) NA_real_ else
  as.numeric(trng[[s]][k]), 0), origin = "1970-01-01")
treg_off <- treg$station_number[differs(as.numeric(treg$first), as.numeric(tday(1))) |
                                  differs(as.numeric(treg$last), as.numeric(tday(2)))]
tsel <- tp$nid[tp$discharge]
treg_sel <- setdiff(union(tsel, treg$station_number), intersect(tsel, treg$station_number))
tk <- match(treg$station_number, ts$station_id)
treg_site <- treg$station_number[is.na(tk) | differs(treg$hydat_site, ts$hydat[tk]) |
                                   differs(treg$hydat_km, ts$hydat_km[tk])]
hy_xy <- albers(hy$lon, hy$lat)
t_xy <- albers(treg$lon, treg$lat)
tnear <- vapply(seq_len(nrow(treg)), function(i) {
  hy$station_number[which.min((hy_xy[, 1] - t_xy[i, 1])^2 + (hy_xy[, 2] - t_xy[i, 2])^2)]
}, "")
treg_near <- treg$station_number[tnear != treg$nearest_hydat | substr(tnear, 1, 3) != treg$subdrainage]
treg_reg <- treg$station_number[differs(treg$regulation, ifelse(regulation_of(treg$name) == "unknown", "unknown",
                                                                  "regulated by name"))]
treg_bad <- treg$station_number[grepl(wet_hydat_number, treg$station_number) |
                                  treg$station_number %in% st_meta$station_number]
treg_fail <- length(treg_off) > 0 || length(treg_cut) > 0 || length(treg_sel) > 0 || length(treg_site) > 0 || length(treg_near) > 0 ||
  length(treg_reg) > 0 || length(treg_bad) > 0
# what the chain adds: per continuing listing, its days before the provincial record begins
tchain <- do.call(rbind, lapply(seq_len(nrow(tcont)), function(i) {
  d <- tshipped$date[tshipped$station_number == tcont$station_number[i]]
  f <- tcont$continues_before[i]
  a <- d[is.na(f) | d < f]
  data.frame(nid = tcont$station_number[i], prov = tcont$continues[i], cut = f,
             prov_first = st_meta$first[st_meta$station_number == tcont$continues[i]], added = length(a),
             span = if (length(a)) paste(min(a), "to", max(a)) else "none", left = sum(!is.na(f) & d >= f))
}))
# every listing left out of the registry, by reason
tleft <- rbind(
  data.frame(nid = wt_dup$nid, id = wt_dup$id, net = wt_dup$net,
             reason = "behind the first listing of its nid (the survey's rule)"),
  data.frame(nid = wt$nid[wt$net == tool_benv], id = wt$id[wt$net == tool_benv], net = tool_benv,
             reason = "the Tool's copy of the provincial network"),
  data.frame(nid = wt$nid[wt$net != tool_benv & wt$nid %in% st_meta$station_number],
             id = wt$id[wt$net != tool_benv & wt$nid %in% st_meta$station_number],
             net = wt$net[wt$net != tool_benv & wt$nid %in% st_meta$station_number],
             reason = "a provincial station the Tool files under another network"),
  data.frame(nid = tp$nid[!tp$discharge], id = tp$id[!tp$discharge], net = tp$net[!tp$discharge],
             reason = "no discharge series (stage or other series only)"))
# the Tool's provincial listings with discharge the provincial files lack (#195, decision 3: not read)
tbenv_q <- wt[wt$net == tool_benv & !wt$nid %in% st_meta$station_number, ]
tbenv_q <- tbenv_q$nid[vapply(wet:::wet_bcwatertool(as.character(tbenv_q$id), tool_snapshot), function(p)
  !is.na(p) && nrow(wet:::wet_bcwatertool_read(p, "x")$q) > 0, FALSE)]
wrap_ids <- function(x) strwrap(paste(x, collapse = ", "), width = 110, indent = 6, exdent = 6)

# ---- report -----------------------------------------------------------------------------------
out <- c(
  "The province's non-integrated discharge as wet reads it: the harvest report (#142, #179)",
  sprintf("HYDAT release %s; snapshot %s; reader v%d; code_md5 %s", release, snapshot, wet_bcenv_reader, code_md5),
  "Windows: CH migration 05-01..08-01 and spawning 08-01..09-15, as the survey (#123).",
  "",
  "Tier (i): the survey's rules (UTC days of >= 20 hours, no bound, no negative day dropped)",
  sprintf(paste0("  daily rows, the probe's own query against wet_bcenv_days(utc = TRUE): %d against",
           " %d; same station-days %s; largest relative difference in flow %s"),
          nrow(utc), nrow(probe), same_rows,
          if (is.na(max_rel)) "-" else if (max_rel <= 1e-12) "under 1e-12" else format(signif(max_rel, 3))),
  sprintf("  survey report rows \"Every station read\", provincial: %d ours, %d the survey's; differing rows %d",
          length(mine), length(theirs), length(row_diff)),
  if (length(row_diff)) paste0("    ", utils::head(row_diff, 20)),
  sprintf("  \"Per network\", provincial: ours   %s", net_mine),
  sprintf("                               survey %s", net_theirs),
  sprintf(paste0("  passing stations (>= %d complete window-years",
           " outside HYDAT's years at the site): %d"), min_years, sum(t1$pass)),
  sprintf("  verdict: %s",
          if (length(fail)) paste("FAIL:", paste(fail, collapse = ", ")) else "PASS, the survey reproduced"),
  "",
  "Tier (ii): the shipped rules (local standard time days, the plausibility bound, negative days dropped, status)",
  sprintf(paste0("  complete days: %d under the survey's rules, %d",
           " under local standard time, %d shipped"), nrow(utc), nrow(lst),
          nrow(shipped)),
  sprintf("  days dropped: %d by the plausibility bound, %d negative", drop_bound, neg),
  sprintf(paste0("  stations: %d read, %d with a complete day; passing %d under the",
           " survey's rules, %d under local standard time, %d shipped"),
          nrow(t3), sum(t3$daily), sum(t1$pass), sum(t2$pass), sum(t3$pass)),
  sprintf("  station registry's first and last days against the shipped reader: %d stations, %d differing%s",
          nrow(st_meta), length(reg_off), if (length(reg_off)) paste0(" (", paste(reg_off, collapse = ", "), ")") else ""),
  sprintf("  stations whose registry HYDAT site or distance differs from the survey's match: %d%s", length(reg_site),
          if (length(reg_site)) paste0(" (", paste(reg_site, collapse = ", "), ")") else ""),
  sprintf("  stations whose registry regulation differs from what their name gives: %d%s", length(reg_reg),
          if (length(reg_reg)) paste0(" (", paste(reg_reg, collapse = ", "), ")") else ""),
  sprintf("  registry numbers shaped like HYDAT's, which wet_station_daily() would not read here: %d%s",
          length(reg_hydat), if (length(reg_hydat)) paste0(" (", paste(reg_hydat, collapse = ", "), ")") else ""),
  sprintf("  stations the hours hold that the registry lacks: %d%s; registry verdict: %s", length(reg_missing),
          if (length(reg_missing)) paste0(" (", paste(reg_missing, collapse = ", "), ")") else "",
          if (reg_fail) "FAIL, rewrite it with data-raw/station_sources_snapshot.R" else "PASS"),
  sprintf("  status of shipped days: provisional %d (%.1f %%), unchecked %d (%.1f %%)",
          sum(shipped$status == "provisional"), 100 * mean(shipped$status == "provisional"),
          sum(shipped$status == "unchecked"), 100 * mean(shipped$status == "unchecked")),
  "",
  sprintf(paste0("Stations whose first-last years, window-years outside HYDAT or pass",
           " moved (%d): station, rule, survey -> LST -> shipped"),
          sum(any_move)),
  sprintf("  %s  %-9s  %s-%s %d %s  ->  %s-%s %d %s  ->  %s-%s %d %s", t1$station_id[any_move],
          ifelse(by_lst & by_bound, "LST+bound", ifelse(by_lst, "LST", "bound"))[any_move],
          t1$first[any_move], t1$last[any_move], t1$wy_new[any_move], ifelse(t1$pass, "pass", "-")[any_move],
          t2$first[any_move], t2$last[any_move], t2$wy_new[any_move], ifelse(t2$pass, "pass", "-")[any_move],
          t3$first[any_move], t3$last[any_move], t3$wy_new[any_move], ifelse(t3$pass, "pass", "-")[any_move]),
  "",
  "The BC Water Tool's third-party gauges (#144, #195)",
  sprintf("Water Tool snapshot %s: %d manifest files; station list %s", tool_snapshot, nrow(tool_man),
          tool_man$md5[tool_man$file == basename(tool_list_path)]),
  "",
  "Tier (i): the survey's rules (every discharge row with a value, no bound, no negative day dropped)",
  sprintf(paste0("  daily rows, the probe's read_wt() against wet_bcwatertool_days(), over the %d third-party",
                 " listings: %d against %d; identical %s"), nrow(tp), nrow(mine_wt), nrow(probe_wt), tool_same_rows),
  sprintf("  survey report rows \"Every station read\", third-party: %d ours, %d the survey's; differing rows %d",
          length(tmine), length(ttheirs), length(trow_diff)),
  if (length(trow_diff)) paste0("    ", utils::head(trow_diff, 20)),
  sprintf("  \"Per network\", third-party: %d lines ours, %d the survey's; identical %s", length(tnet_mine),
          length(tnet_theirs), identical(unname(tnet_mine), tnet_theirs)),
  sprintf("  passing third-party stations: %d ours, %d the survey's", sum(ts$pass), length(tpass_theirs)),
  sprintf("  at a provincial station's site in the survey: %d (%s); the registry's continuing listings agree: %s",
          nrow(tshared), paste(sprintf("%s at %s", tshared$nid, tshared$prov), collapse = ", "), tshared_ok),
  sprintf("  verdict: %s",
          if (length(tool_fail)) paste("FAIL:", paste(tool_fail, collapse = ", ")) else "PASS, the survey reproduced"),
  "",
  "Tier (ii): the shipped rules (the nearest HYDAT station's sub-drainage bound, negative days dropped, QA as status)",
  sprintf("  listings read: %d, %d stations of their own and %d continuing a provincial station", nrow(treg),
          sum(is.na(treg$continues)), nrow(tcont)),
  sprintf("  days: %d discharge rows with a value, %d negative, %d dropped by the bound, %d shipped", nrow(tparsed),
          tneg, nrow(tdropped), nrow(tshipped)),
  sprintf("  status of shipped days: provisional %d (%.1f %%), unchecked %d (%.1f %%)",
          sum(tshipped$status == "provisional"), 100 * mean(tshipped$status == "provisional"),
          sum(tshipped$status == "unchecked"), 100 * mean(tshipped$status == "unchecked")),
  "  per network (stations of their own, shipped days, unchecked share; continuing listings apart):",
  vapply(sort(unique(treg$network[is.na(treg$continues)]), method = "radix"), function(n) {
    ids <- treg$station_number[treg$network == n & is.na(treg$continues)]
    d <- tshipped[tshipped$station_number %in% ids, ]
    sprintf("    %-48s %3d stations  %7d days  unchecked %5.1f %%", n, length(ids), nrow(d),
            100 * mean(d$status == "unchecked"))
  }, ""),
  sprintf("  days the bound drops (%d): station, sub-drainage, date, flow", nrow(tdropped)),
  if (nrow(tdropped)) sprintf("    %s  %s  %s  %.3f", tdropped$station_number,
                              treg$subdrainage[match(tdropped$station_number, treg$station_number)],
                              tdropped$date, tdropped$q_m3s),
  sprintf(paste0("  continuing listings (%d): the days each adds before its provincial station's record begins",
                 " (the first day the provincial files hold any usable hour of it)"), nrow(tcont)),
  sprintf("    %s -> %s (record begins %s, first complete day %s): %d days added (%s); %d from then on not read",
          tchain$nid, tchain$prov, tchain$cut, tchain$prov_first, tchain$added, tchain$span, tchain$left),
  sprintf("  registry cut (continues_before) against the provincial files' first hour: %d differing%s",
          length(treg_cut), if (length(treg_cut)) paste0(" (", paste(treg_cut, collapse = ", "), ")") else ""),
  sprintf("  the Tool's provincial listings with discharge the provincial files lack, not read: %s",
          paste(tbenv_q, collapse = ", ")),
  sprintf("  listings left out of the registry (%d), by reason:", nrow(tleft)),
  unlist(lapply(unique(tleft$reason), function(r) {
    x <- tleft[tleft$reason == r, ]
    c(sprintf("    %s (%d; nid:id):", r, nrow(x)), wrap_ids(sprintf("%s:%s", x$nid, x$id)))
  })),
  sprintf("  registry against the reader's first and last days: %d listings, %d differing%s", nrow(treg),
          length(treg_off), if (length(treg_off)) paste0(" (", paste(treg_off, collapse = ", "), ")") else ""),
  sprintf("  registry listings against the selection recomputed from the station list: %d differing%s",
          length(treg_sel), if (length(treg_sel)) paste0(" (", paste(treg_sel, collapse = ", "), ")") else ""),
  sprintf("  registry HYDAT site or distance against the survey's match: %d differing%s", length(treg_site),
          if (length(treg_site)) paste0(" (", paste(treg_site, collapse = ", "), ")") else ""),
  sprintf("  registry nearest HYDAT station or sub-drainage recomputed: %d differing%s", length(treg_near),
          if (length(treg_near)) paste0(" (", paste(treg_near, collapse = ", "), ")") else ""),
  sprintf("  registry regulation against the name rule: %d differing; numbers shaped like HYDAT's or provincial: %d%s",
          length(treg_reg), length(treg_bad),
          if (length(c(treg_reg, treg_bad))) paste0(" (", paste(c(treg_reg, treg_bad), collapse = ", "), ")") else ""),
  sprintf("  sub-drainages read (nearest HYDAT station): %s; farthest nearest station %.2f km (%s)",
          paste(sprintf("%s %d", names(table(treg$subdrainage)), table(treg$subdrainage)), collapse = ", "),
          max(treg$nearest_km), treg$station_number[which.max(treg$nearest_km)]),
  sprintf("  Tool registry verdict: %s",
          if (treg_fail) "FAIL, rewrite it with data-raw/station_sources_bcwatertool.R" else "PASS")
)
writeLines(out, report)
message("wrote ", report)
if (length(fail) || reg_fail || length(tool_fail) || treg_fail) {
  message("failed: ", paste(c(fail, if (reg_fail) "station registry", tool_fail,
                              if (treg_fail) "Water Tool registry"), collapse = ", "))
  quit(status = 1)
}
