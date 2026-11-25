# Which copy of the province's 2021-2026 non-integrated discharge is current (#190)
#
# Usage:
#   WET_PORTAL_PICK_ONLY=1 Rscript scripts/station_sources_portal.R   # the pick alone, no request
#   WET_DATA_ROOT=<main checkout>/data Rscript scripts/station_sources_portal.R
#
# From 2021 the province's pinned non-integrated files (wet_bcenv_snapshot) and
# the BC Water Tool's copy of the same stations (wet_bcwatertool_snapshot) part:
# the survey report (data/checks/station_sources_20260717.txt, "The BC Water
# Tool against the province") has 99.8-100 % of their common 24-hour UTC days
# within 0.1 % to 2020, and 61-92 % per year from 2021. This script reads a few
# stations from the province's own Aquarius WebPortal (the Real-time Water Data
# Tool, aqrt.nrs.gov.bc.ca, served at bcmoe-prod.aquaticinformatics.net) and
# says, per year, which copy the portal agrees with. The owner accepted the
# portal's disclaimer on 2026-11-25 (#210; it restricts no use).
#
# Rules, registered here before any portal value was read (the pick-only run's
# report is committed first):
#
# 1. Days are the survey's, not the shipped reader's: a 24-hour UTC day is the
#    mean of a station's hourly values on one UTC date, kept only when all 24
#    hours are there. The province's are wet_bcenv_days(utc = TRUE) with
#    hours == 24, no bound, as the survey's (its probe's prov_q24). The Tool's
#    are its "Preliminary Discharge" rows (wet_bcwatertool_days()), each one
#    date, as the survey compared them. Never wet_station_daily(), whose days
#    are local standard time with the 20-hour rule and the bound.
# 2. The pick, from the cached copies alone: for each provincial station the
#    Tool also lists (the survey's station list rule: listings with years, not
#    Water Survey of Canada, one per nid), its common days 2021-01-01 to the
#    day before the provincial snapshot, and the share of them within 0.1 %
#    (|tool - province| / max(|province|, 0.001) <= 0.001, the survey's
#    measure). Stations with at least 365 common days are eligible. Picked, in
#    order: the 5 with the lowest share; the 3 with the highest (ties: more
#    days, then station number); then, for each of drainages 07, 08H and 08N,
#    the eligible station not yet picked with the most common days (ties:
#    station number). Ties elsewhere fall to the station number.
# 3. The portal: each picked station's "Discharge.Working" data set (the
#    portal's working series; a station without one is reported and skipped),
#    exported as points as recorded in m^3/s with UTC timestamps, from
#    2021-01-01 00:00 to the provincial snapshot's date 00:00. Read once into
#    <WET_DATA_ROOT>/station_sources/raw/portal/<WET_PORTAL_SNAPSHOT>/
#    (untracked; md5s in the report); a rerun reads that copy and makes no
#    request.
# 4. A portal hour is its point at the top of a UTC hour (minute and second
#    0); a portal day is the mean of a UTC date's 24 portal hours, kept only
#    when all 24 are there. The province's hourly values are the portal's
#    points at the hour, rounded (to 0.001 m^3/s where the file holds m^3/s),
#    so two values agree when they differ by at most 0.1 % of the reference
#    or 0.0005 m^3/s, whichever is larger: hours, portal against province
#    (reference the province); days, portal against province (reference the
#    province) and portal against Tool (reference the Tool).
#    Amendment 1 (after the first read, before any share was computed): the
#    exports mark gaps as rows of grade -3 (GAP) with the value NaN; those
#    rows are no value, and rows of grade -2 (UNUSABLE) are left out, as the
#    province's Unusable hours are. Any other value that is not a finite
#    number is still refused.
# 5. The verdict per year, on the station-days where the portal, the province
#    and the Tool all have a day: "province" when the portal agrees with the
#    province on at least 90 % of them and on at least 5 points more than
#    with the Tool; "Tool" the same way round; "both" when it agrees with
#    each on at least 99 %; otherwise "unresolved".
#
# The report holds counts and shares only, never a portal value. It carries
# no timestamp and is byte-identical on a rerun from the cached copy:
# data/checks/station_sources_portal_<WET_PORTAL_SNAPSHOT>.txt (the pick-only
# run writes the same file, with its pick and no comparison).

devtools::load_all(quiet = TRUE)

self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) stop("run with Rscript", call. = FALSE)
pick_only <- identical(Sys.getenv("WET_PORTAL_PICK_ONLY"), "1")
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
portal_root <- file.path(data_root, "station_sources", "raw", "portal")
portal_snapshot <- Sys.getenv("WET_PORTAL_SNAPSHOT")
if (!nzchar(portal_snapshot)) {
  have <- if (dir.exists(portal_root)) list.files(portal_root, pattern = "^[0-9]{8}$") else character()
  portal_snapshot <- if (length(have) == 1) have else format(Sys.time(), "%Y%m%d", tz = "UTC")
  if (length(have) > 1) stop("several portal copies in ", portal_root, "; name one with WET_PORTAL_SNAPSHOT",
                             call. = FALSE)
}
if (!grepl("^[0-9]{8}$", portal_snapshot)) stop("WET_PORTAL_SNAPSHOT must be YYYYMMDD", call. = FALSE)
raw_dir <- file.path(portal_root, portal_snapshot)
report <- file.path("data", "checks", sprintf("station_sources_portal_%s.txt", portal_snapshot))

snapshot <- wet_bcenv_snapshot
tool_snapshot <- wet_bcwatertool_snapshot
cache <- tools::R_user_dir("wet", "cache")
from <- as.Date("2021-01-01")
to <- as.Date(snapshot, "%Y%m%d") - 1   # the last whole day before the provincial snapshot
min_days <- 365
host <- "https://bcmoe-prod.aquaticinformatics.net"
agent <- paste("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)",
               "Chrome/130.0 Safari/537.36")

# ---- the cached copies: the province's and the Tool's 24-hour UTC days -------------------------
prov <- wet_bcenv_days_read(wet_bcenv_days(snapshot, cache, utc = TRUE), NULL)
prov <- prov[prov$hours == 24 & prov$date >= from & prov$date <= to, c("station_number", "date", "q_m3s")]

list_file <- wet_bcwatertool_list_file(tool_snapshot)
man <- wet_bcwatertool_manifest(tool_snapshot)
list_path <- file.path(cache, "station_sources", "bcwatertool", tool_snapshot, list_file)
wet_bcenv_check(list_path, man$bytes[man$file == list_file], man$md5[man$file == list_file])
feat <- jsonlite::fromJSON(list_path, simplifyVector = FALSE)$features
wt <- do.call(rbind, lapply(feat, function(f) {
  p <- f$properties
  data.frame(id = as.character(p$id), nid = if (is.null(p$nid)) NA_character_ else p$nid, net = p$net,
             n_yr = length(p$yr), stringsAsFactors = FALSE)
}))
wt <- wt[wt$n_yr > 0 & wt$net != "Water Survey of Canada", ]
wt <- wt[order(wt$nid, as.numeric(wt$id), method = "radix"), ]   # the survey's ids are numbers
wt <- wt[!duplicated(wt$nid), ]
wt <- wt[wt$nid %in% prov$station_number, ]
tool <- wet_bcwatertool_days(wt$id, tool_snapshot, cache)
tool$station_number <- wt$nid[match(tool$id, wt$id)]
tool <- tool[tool$date >= from & tool$date <= to, c("station_number", "date", "q_m3s")]

pt <- merge(setNames(prov, c("station_number", "date", "prov")), setNames(tool, c("station_number", "date", "tool")))
pt$rel <- abs(pt$tool - pt$prov) / pmax(abs(pt$prov), 1e-3)
rank <- do.call(rbind, lapply(split(pt, pt$station_number), function(d) {
  data.frame(station_number = d$station_number[1], days = nrow(d), share = mean(d$rel <= 0.001))
}))
rank <- rank[order(rank$station_number, method = "radix"), ]
elig <- rank[rank$days >= min_days, ]

# ---- the pick (rule 2) ------------------------------------------------------------------------
low <- elig[order(elig$share, elig$station_number, method = "radix"), ][1:5, ]
low$role <- "differs most"
rest <- elig[!elig$station_number %in% low$station_number, ]
high <- rest[order(-rest$share, -rest$days, rest$station_number, method = "radix"), ][1:3, ]
high$role <- "agrees"
picked <- rbind(low, high)
for (dr in c("07", "08H", "08N")) {
  cand <- elig[startsWith(elig$station_number, dr) & !elig$station_number %in% picked$station_number, ]
  if (!nrow(cand)) next
  one <- cand[order(-cand$days, cand$station_number, method = "radix"), ][1, ]
  one$role <- paste("drainage", dr)
  picked <- rbind(picked, one)
}
rownames(picked) <- NULL

pick_lines <- c(
  sprintf("The pick (rule 2), from the cached copies: provincial snapshot %s, Tool snapshot %s, days %s to %s",
          snapshot, tool_snapshot, from, to),
  sprintf("  provincial stations the Tool also lists, with a common 24-hour UTC day: %d; eligible (>= %d days): %d",
          nrow(rank), min_days, nrow(elig)),
  sprintf("  eligible stations' Tool-province days within 0.1 %%: %.1f %% of %d station-days",
          100 * sum(elig$share * elig$days) / sum(elig$days), sum(elig$days)),
  "  station, role, common days, share within 0.1 %:",
  sprintf("    %s  %-14s %5d  %5.1f %%", picked$station_number, picked$role, picked$days, 100 * picked$share))

head_lines <- c(
  "Which copy of the province's 2021-2026 non-integrated discharge is current: the Aquarius portal (#190)",
  "Rules: the header of scripts/station_sources_portal.R. Counts and shares only; no portal value.",
  "")

if (pick_only) {
  writeLines(c(head_lines, pick_lines, "", "Pick only (WET_PORTAL_PICK_ONLY=1): no portal value read."), report)
  message("wrote ", report)
  quit(save = "no")
}

# ---- the portal (rule 3) ----------------------------------------------------------------------
# One handle keeps the session cookie the disclaimer sets.
handle <- NULL
portal_get <- function(path, query = NULL) {
  if (is.null(handle)) {
    handle <<- curl::new_handle(useragent = agent, cookiefile = "", followlocation = TRUE)
    r <- curl::curl_fetch_memory(paste0(host, "/Disclaimer"), handle = handle)
    if (r$status_code != 200) stop("the portal's disclaimer page answered HTTP ", r$status_code, call. = FALSE)
    tok <- regmatches(rawToChar(r$content),
                      regexpr('name="__RequestVerificationToken" type="hidden" value="[^"]+"', rawToChar(r$content)))
    if (length(tok) != 1) stop("no verification token on the portal's disclaimer page", call. = FALSE)
    tok <- sub('.*value="([^"]+)"$', "\\1", tok)
    curl::handle_setopt(handle, postfields = paste0("__RequestVerificationToken=", curl::curl_escape(tok),
                                                    "&returnUrl=%2FData"))
    r <- curl::curl_fetch_memory(paste0(host, "/AcceptDisclaimer"), handle = handle)
    curl::handle_setopt(handle, httpget = TRUE)
    if (r$status_code != 200) stop("accepting the portal's disclaimer answered HTTP ", r$status_code, call. = FALSE)
  }
  q <- if (is.null(query)) "" else paste0("?", paste(names(query), vapply(query, curl::curl_escape, ""), sep = "=",
                                                    collapse = "&"))
  Sys.sleep(1)
  r <- curl::curl_fetch_memory(paste0(host, path, q), handle = handle)
  if (r$status_code != 200) stop(path, " answered HTTP ", r$status_code, call. = FALSE)
  r$content
}

dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
cached <- function(file, get) {
  f <- file.path(raw_dir, file)
  if (!file.exists(f)) {
    tmp <- tempfile(tmpdir = raw_dir)
    writeBin(get(), tmp)
    if (!file.rename(tmp, f)) stop("could not write ", f, call. = FALSE)
  }
  f
}

fetched <- list()
for (s in picked$station_number) {
  loc <- cached(sprintf("%s_location.json", s), function() portal_get("/Data/SearchLocations/",
                                                                      list(term = s, limit = "21")))
  loc <- jsonlite::fromJSON(jsonlite::fromJSON(loc))
  loc <- if (is.data.frame(loc) && "Id" %in% names(loc)) loc[loc$Id %in% s, ] else NULL
  if (!NROW(loc)) {
    fetched[[s]] <- list(why = "no portal location")
    next
  }
  ds <- cached(sprintf("%s_datasets.json", s), function() portal_get("/Data/DataSets/",
                                                                     list(locationid = as.character(loc$IDNumber[1]))))
  ds <- jsonlite::fromJSON(ds)
  if (is.character(ds)) ds <- jsonlite::fromJSON(ds)
  want <- sprintf("Discharge.Working@%s", s)
  if (!want %in% ds$DisplayText) {
    fetched[[s]] <- list(why = "no Discharge.Working data set")
    next
  }
  csv <- cached(sprintf("%s_discharge_working.csv", s), function() portal_get("/Export/BulkExport", c(
    DateRange = "Custom", StartTime = paste(format(from), "00:00"), EndTime = paste(format(to + 1), "00:00"),
    TimeZone = "0", Calendar = "CALENDARYEAR", Interval = "PointsAsRecorded", Step = "1", ExportFormat = "csv",
    TimeAligned = "True", RoundData = "False", IncludeGradeCodes = "True", IncludeApprovalLevels = "True",
    IncludeQualifiers = "False", IncludeInterpolationTypes = "False", "Datasets[0].DatasetName" = want,
    "Datasets[0].Calculation" = "Instantaneous", "Datasets[0].UnitId" = "350")))
  fetched[[s]] <- list(csv = csv)
}

# One portal export: the rows under "Timestamp (UTC),Value (m^3/s),Grade Code,Approval Level".
portal_read <- function(path, s) {
  lines <- readLines(path, warn = FALSE)
  hdr <- which(lines == "Timestamp (UTC),Value (m^3/s),Grade Code,Approval Level")
  if (length(hdr) != 1 || !any(lines == sprintf(",%s,,", s)) || !any(lines == ",Discharge.Working,,")) {
    stop(path, " is not one Discharge.Working export of ", s, " in m^3/s with UTC timestamps", call. = FALSE)
  }
  x <- utils::read.csv(text = lines[hdr:length(lines)], colClasses = "character", na.strings = character(),
                       check.names = FALSE)
  x <- x[nzchar(x[[2]]), ]
  # amendment 1: grade -3 (GAP) rows carry NaN, and grade -2 (UNUSABLE) is left out as the province's Unusable
  x <- x[!(x[[3]] == "-3" & x[[2]] == "NaN") & x[[3]] != "-2", ]
  v <- suppressWarnings(as.numeric(x[[2]]))
  if (any(!is.finite(v))) stop(path, ": a value that is not a finite number", call. = FALSE)
  t <- as.POSIXct(x[[1]], format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  if (anyNA(t)) stop(path, ": a timestamp not written YYYY-MM-DD HH:MM:SS", call. = FALSE)
  data.frame(station_number = s, t = t, value = v)
}

agree <- function(a, ref) abs(a - ref) <= pmax(0.001 * abs(ref), 0.0005)

# ---- the comparison (rules 4 and 5) -----------------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb())
wet_bcenv_hours(con, wet_bcenv(snapshot))
ok <- names(fetched)[vapply(fetched, function(f) !is.null(f$csv), FALSE)]
hours <- DBI::dbGetQuery(con, sprintf("SELECT id AS station_number, CAST(t AS TIMESTAMP) AS t, value FROM h
  WHERE grade <> 'Unusable' AND id IN (%s)", paste(DBI::dbQuoteString(con, ok), collapse = ", ")))
DBI::dbDisconnect(con, shutdown = TRUE)
attr(hours$t, "tzone") <- "UTC"
hours <- hours[as.Date(hours$t) >= from & as.Date(hours$t) <= to, ]

portal <- do.call(rbind, lapply(ok, function(s) portal_read(fetched[[s]]$csv, s)))
ph <- portal[format(portal$t, "%M:%S") == "00:00" & as.Date(portal$t) >= from & as.Date(portal$t) <= to, ]
hh <- merge(setNames(ph, c("station_number", "t", "portal")), setNames(hours, c("station_number", "t", "prov")))
hh$year <- format(hh$t, "%Y")
hh$ok <- agree(hh$portal, hh$prov)

ph$date <- as.Date(ph$t)
pday <- stats::aggregate(cbind(portal = value, n = 1) ~ station_number + date, data = ph, FUN = sum)
pday <- pday[pday$n == 24, ]
pday$portal <- pday$portal / 24
dd <- merge(merge(pday[, c("station_number", "date", "portal")], setNames(prov, c("station_number", "date", "prov"))),
            setNames(tool, c("station_number", "date", "tool")))
dd$year <- format(dd$date, "%Y")
dd$p_ok <- agree(dd$portal, dd$prov)
dd$t_ok <- agree(dd$portal, dd$tool)

verdict <- function(p, t) {
  if (p >= 0.99 && t >= 0.99) "both" else if (p >= 0.9 && p - t >= 0.05) "province" else
    if (t >= 0.9 && t - p >= 0.05) "Tool" else "unresolved"
}

files <- sort(list.files(raw_dir), method = "radix")
md5 <- tools::md5sum(file.path(raw_dir, files))
yrs <- sort(unique(dd$year), method = "radix")
by_year <- vapply(yrs, function(y) {
  d <- dd[dd$year == y, ]
  h <- hh[hh$year == y, ]
  sprintf("    %s %6d %5.1f %5.1f  %-10s %7d %5.1f", y, nrow(d), 100 * mean(d$p_ok), 100 * mean(d$t_ok),
          verdict(mean(d$p_ok), mean(d$t_ok)), nrow(h), 100 * mean(h$ok))
}, "")
st_year <- unlist(lapply(ok, function(s) {
  d <- dd[dd$station_number == s, ]
  h <- hh[hh$station_number == s, ]
  vapply(sort(unique(c(d$year, h$year)), method = "radix"), function(y) {
    dy <- d[d$year == y, ]
    hy <- h[h$year == y, ]
    sprintf("    %s %s %5d %5s %5s %6d %5s", s, y, nrow(dy),
            if (nrow(dy)) sprintf("%.1f", 100 * mean(dy$p_ok)) else "-",
            if (nrow(dy)) sprintf("%.1f", 100 * mean(dy$t_ok)) else "-", nrow(hy),
            if (nrow(hy)) sprintf("%.1f", 100 * mean(hy$ok)) else "-")
  }, "")
}))
hh$month <- format(hh$t, "%Y-%m")
mons <- sort(unique(hh$month), method = "radix")
by_month <- vapply(mons, function(m) {
  h <- hh[hh$month == m, ]
  sprintf("    %s %6d %5.1f %3d", m, nrow(h), 100 * mean(h$ok), length(unique(h$station_number)))
}, "")
skipped <- names(fetched)[!names(fetched) %in% ok]

out <- c(head_lines, pick_lines, "",
  sprintf("The portal copy (rule 3): %s, %d files (file, md5):", portal_snapshot, length(files)),
  sprintf("    %s %s", files, unname(md5)),
  if (length(skipped)) sprintf("  picked but not read: %s", paste(sprintf("%s (%s)", skipped,
    vapply(fetched[skipped], function(f) f$why, "")), collapse = ", ")) else "  every picked station read",
  "",
  "By year (rules 4 and 5), on the station-days where the portal, the province and the Tool all have a day:",
  "  year, station-days, % portal agrees with province, % with Tool, verdict; hours compared, % portal hours agree with province",
  by_year,
  "",
  "By station and year: station, year, station-days, % with province, % with Tool; hours, % hours with province",
  st_year,
  "",
  "By month, every picked station's hours: month, hours compared, % portal hours agree with province, stations",
  by_month)
writeLines(out, report)
message("wrote ", report)
