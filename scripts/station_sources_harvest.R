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
if (length(row_diff)) fail <- c(fail, "station rows")
net_mine <- sprintf("read %4d  Q %4d  new %4d  same-site %3d  dup %3d  >=1 %4d  >=3 %4d  seasonal %s",
                    nrow(t1), nrow(t1), sum(t1$class == "not in HYDAT"), sum(t1$class == "same site, new years"),
                    sum(t1$class == "duplicate"), sum(t1$new & t1$wy_new >= 1), sum(t1$new & t1$wy_new >= min_years),
                    sum(t1$seasonal, na.rm = TRUE))
net_theirs <- sub("^.*(read .*seasonal [0-9-]+).*$", "\\1", grep("^  bcenv  ", survey, value = TRUE))
if (!identical(net_mine, net_theirs)) fail <- c(fail, "network line")

# ---- tier (ii): the shipped rules -------------------------------------------------------------
lst <- wet_bcenv_days_read(wet_bcenv_days(snapshot, cache), NULL)
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
reg_missing <- setdiff(unique(c(lst$station_number, utc$station_number)), st_meta$station_number)
# the registry's HYDAT site against the survey's match, which tier (i) verifies (the site does not depend on years)
stopifnot(identical(t1$station_id, st_meta$station_number))
reg_site <- st_meta$station_number[differs(st_meta$hydat_site, t1$hydat) | differs(st_meta$hydat_km, t1$hydat_km)]
reg_fail <- length(reg_off) > 0 || length(reg_missing) > 0 || length(reg_site) > 0
neg <- sum(lst$q_m3s < 0)

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
  sprintf("  stations the reader returns that the registry lacks: %d%s; registry verdict: %s", length(reg_missing),
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
          t3$first[any_move], t3$last[any_move], t3$wy_new[any_move], ifelse(t3$pass, "pass", "-")[any_move])
)
writeLines(out, report)
message("wrote ", report)
if (length(fail) || reg_fail) {
  message("failed: ", paste(c(fail, if (reg_fail) "station registry"), collapse = ", "))
  quit(status = 1)
}
