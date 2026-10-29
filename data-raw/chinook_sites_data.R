# Data for vignettes/articles/flow-change-sparse-gauges.Rmd (#126), which runs on this file
# and never touches HYDAT, fwapg, S3 or the network at build.
#
#   WET_HYDAT_RELEASE=20260717 Rscript data-raw/chinook_sites_data.R
#
# Reads, for every site of scripts/departure_sites.csv and every window set it
# names, the series that scripts/departure_site.R and
# scripts/departure_site_snow.R save after their reports (gitignored):
#   data/departure/departure_site_<site>_<group>_20260717.rds
#   data/departure/departure_site_snow_<site>_<group>_20260717.rds
# It refuses unless each one's code_md5 is the md5 of its script as committed
# here, and unless R/, scripts/, data-raw/ and data/checks/ hold nothing
# uncommitted (vd_commit()), so the commit the bundle names rebuilds it. Every
# number the article can quote is held to its tracked report: the line the
# script printed for it is printed again, with the script's own formats, from
# the series file, and must appear in
# data/checks/departure_site[_snow]_<site>_<group>_20260717.txt verbatim.
#
# Also reads wet's published discharge (wet_catalog(), the segment_daily parts
# over HTTPS) for each site's typical year, and fwapg through the WET_PG*
# variables for the gauged targets' segments (wet_station_snap()).
#
# Writes inst/vignette-data/chinook_sites_values.rds, a list:
#   - sites: one row per site (site_id, name, wsg_code, kind, target, the
#     mouth for an ungauged site, km2, window sets)
#   - change: per site, window set, statistic (mean, min7, cov_day) and
#     window, each route's change 2011-2025 against the years before 1981
#     (log, or days), % of normal and its 90 % interval, and years per period
#   - scores: per site and window set, the extension race in the box (median
#     NSE of ols, move1 and ratio, what #120's rule would pick, gauges, below
#     #120's floor) and the carried departures held out (median and quartiles,
#     gauges, usable, short-record median)
#   - snow: the one-predictor snow fits (swe, doy) for every series: slope,
#     90 % interval, R2, n
#   - normal: the ungauged site's published window normal per source and the
#     pick, and the normal's error at its box gauges per window
#   - gauges: every gauge a site's numbers rest on, with its role (target,
#     extension donor, carried donor, snow), over every scored statistic,
#     window and window set
#   - windows: each site's window sets, as its runs used them
#   - score_settings: per site and window set, each statistic and window's
#     held-out scores, both routes, read from the report's two score tables
#   - use: the candidate streams' Chinook records, as
#     data/checks/chinook_sites_use.txt prints them (NuSEDS rows, use records,
#     distinct use years and their span; provincial records, spawning records),
#     and the provincial records one per row (stream, date, metres from the
#     mouth, activity)
#   - daily: each site's typical year, 1981-2010, on its stream: the
#     published segment_daily (both sources, and which is the pick) on the
#     gauged target's snapped segment or the ungauged site's mouth segment;
#     refused unless the build is the one the ungauged site's report names and
#     the picked days' window means equal that report's normal
#   - years: per site, the window mean's year-by-year departure from its
#     1981-2010 typical flow (log), by route: measured and filled-in (with the
#     90 % interval) at a gauged site, borrowed at every site; every year held
#     to its line in the site report's per-year tables
#   - provenance: wet commit, build date, HYDAT release, the scripts' and the
#     reports' md5s

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release()
source("scripts/vignette_data_lib.R")  # vd_commit()
source("scripts/departure_site_lib.R")  # site_get(), site_windows()

wet_commit <- vd_commit()
release <- wb_release()
if (release != "20260717") stop("the article's data are HYDAT 20260717's, not ", release, call. = FALSE)
out <- file.path("inst", "vignette-data", "chinook_sites_values.rds")
site_ids <- utils::read.csv(site_file, colClasses = "character")$site_id
md5 <- c(site = unname(tools::md5sum("scripts/departure_site.R")),
         snow = unname(tools::md5sum("scripts/departure_site_snow.R")))

# the site script's formats, as it prints them
fmt <- function(x, d = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
pc <- function(z, days) if (days) fmt(z, 1) else fmt(100 * (exp(z) - 1), 1)
ci_txt <- function(ci, days) {
  if (is.na(ci[1])) "-" else if (days) sprintf("%s..%s", fmt(ci[1], 1), fmt(ci[2], 1)) else
    sprintf("%s..%s %%", pc(ci[1], FALSE), pc(ci[2], FALSE))
}
is_days <- function(v) grepl("_cov_day$", v)
held <- function(line, report, what) {
  if (!sub(" +$", "", line) %in% report) stop(what, ": not in its report: ", line, call. = FALSE)
  invisible(TRUE)
}
read_series <- function(kind, site_id, group) {
  f <- file.path("data", "departure", sprintf("departure_site%s_%s_%s_%s.rds", if (kind == "snow") "_snow" else "",
                                              site_id, tolower(group), release))
  if (!file.exists(f)) stop("no ", f, ": run scripts/departure_site", if (kind == "snow") "_snow", ".R ", site_id, call. = FALSE)
  x <- readRDS(f)
  if (!identical(x$code_md5, md5[[kind]]) || !identical(x$release, release)) {
    stop(f, " was made by another script or release: rerun it", call. = FALSE)
  }
  x
}
report_of <- function(kind, site_id, group) {
  f <- file.path("data", "checks", sprintf("departure_site%s_%s_%s_%s.txt", if (kind == "snow") "_snow" else "",
                                           site_id, tolower(group), release))
  list(path = f, lines = readLines(f), md5 = unname(tools::md5sum(f)))
}

sites <- list()
change <- list()
scores <- list()
snow <- list()
normal <- list()
gauges <- list()
windows <- list()
score_rows <- list()
years <- list()
reports <- character()
for (id in site_ids) {
  site <- site_get(id)
  target <- if (site$kind == "extend") site$target_station else site$site_id
  for (group in names(site_windows(site))) {
    x <- read_series("site", id, group)
    s <- read_series("snow", id, group)
    rp <- report_of("site", id, group)
    rs <- report_of("snow", id, group)
    reports[c(rp$path, rs$path)] <- c(rp$md5, rs$md5)

    # the change, each route, held to section 4's table
    for (m in x$mx) {
      if (m$v == "q_max") next
      days <- is_days(m$v)
      if (site$kind == "extend") {
        held(sprintf("  %-9s %-9s %4d %4d %9s %9s %18s   %9s %9s %18s %4d %4d", sub("^q_", "", m$v), m$p, m$n_pre, m$n_post,
                     fmt(m$diff, 3), if (days) "-" else pc(m$diff, FALSE), ci_txt(m$ci, days),
                     fmt(m$carried, 3), if (days) "-" else pc(m$carried, FALSE), ci_txt(m$ci_c, days), m$n_pre_c, m$n_post_c),
             rp$lines, paste(id, group, m$v, m$p))
        change[[length(change) + 1]] <- data.frame(site_id = id, group = group, statistic = sub("^q_", "", m$v),
          window = m$p, route = "extended", change = m$diff, lo = m$ci[1], hi = m$ci[2], n_pre = m$n_pre,
          n_post = m$n_post)
      } else {
        held(sprintf("  %-9s %-9s %4d %4d %9s %9s %18s %8d", sub("^q_", "", m$v), m$p, m$n_pre_c, m$n_post_c,
                     fmt(m$carried, 3), if (days) "-" else pc(m$carried, FALSE), ci_txt(m$ci_c, days), m$n_resid_c),
             rp$lines, paste(id, group, m$v, m$p))
      }
      change[[length(change) + 1]] <- data.frame(site_id = id, group = group, statistic = sub("^q_", "", m$v),
        window = m$p, route = "carried", change = m$carried, lo = m$ci_c[1], hi = m$ci_c[2], n_pre = m$n_pre_c,
        n_post = m$n_post_c)
    }

    # the window mean's departures year by year, each year held to its line in the per-year tables
    for (w in x$windows$window) {
      m <- x$mx[[paste("q_mean", w)]]
      a <- m$a
      if (site$kind == "extend") {
        e <- m$e
        bm <- mean(e$value[e$year %in% x$baseline])
        for (yy in sort(union(e$year, a$year))) {
          i <- match(yy, e$year)
          k <- match(yy, a$year)
          held(sprintf("  %4d %8s %8s %8s %-8s %9s %9s", yy, fmt(e$value[i], 2), fmt(e$lower[i], 2), fmt(e$upper[i], 2),
                       if (is.na(i)) "-" else if (is.na(e$donor[i])) "observed" else e$donor[i],
                       if (is.na(i)) "-" else pc(e$dep[i], FALSE), if (is.na(k)) "-" else pc(a$anomaly[k], FALSE)),
               rp$lines, paste(id, group, w, yy))
        }
        years[[length(years) + 1]] <- data.frame(site_id = id, group = group, window = w, year = e$year,
          route = ifelse(e$source == "observed", "measured", "filled"), dep = e$dep,
          lo = log(e$lower / bm), hi = log(e$upper / bm))
      } else {
        nq <- x$normal$normal$q_m3s[x$normal$normal$window == w]
        for (j in seq_len(nrow(a))) {
          held(sprintf("  %4d %9s %9s %3d", a$year[j], pc(a$anomaly[j], FALSE), fmt(nq * exp(a$anomaly[j]), 3),
                       as.integer(a$n_donors[j])), rp$lines, paste(id, group, w, a$year[j]))
        }
      }
      years[[length(years) + 1]] <- data.frame(site_id = id, group = group, window = w, year = a$year,
        route = "borrowed", dep = a$anomaly, lo = NA_real_, hi = NA_real_)
    }

    # the scores, held to section 2's rule line and section 3's headline
    r <- x$race
    held(sprintf("#120's rule here: the highest median is %s (%s); ratio's is %s; margin %s. It would pick %s. The target is extended by ols (fixed at #126's gate)%s.",
                 names(r$med)[which.max(r$med)], fmt(max(r$med), 3), fmt(r$med[["ratio"]], 3), 0.01, r$rule_pick,
                 if (r$rule_pick == "ols") ", which #120's rule also picks here" else ", which #120's rule would NOT pick here"),
         rp$lines, paste(id, group, "race"))
    cq <- x$carried
    # the headline up to its not-scored count, which the series file does not carry and the article does not quote
    head_line <- sprintf("HEADLINE: median per-gauge NSE %s (quartiles %s to %s) over %d gauges scored;",
                         fmt(cq$q[2]), fmt(cq$q[1]), fmt(cq$q[3]), cq$n)
    if (sum(startsWith(rp$lines, head_line)) != 1) stop(id, " ", group, " headline: not in its report: ", head_line, call. = FALSE)
    # each method's median in section 2's table (the first such row per method), the gauges the race ran at,
    # the target's observed years and the area, as the report prints them
    for (mt in names(r$med)) {
      row <- grep(sprintf("^  %-6s +[-0-9.]+ +[-0-9.]+ +[-0-9.]+$", mt), rp$lines, value = TRUE)[1]
      if (is.na(row) || strsplit(trimws(row), " +")[[1]][3] != fmt(r$med[[mt]])) {
        stop(id, " ", group, " race ", mt, ": median ", fmt(r$med[[mt]]), " not in its report", call. = FALSE)
      }
    }
    if (!any(grepl(sprintf("; %d hold at least one 5-year block", r$gauges), rp$lines, fixed = TRUE))) {
      stop(id, " ", group, ": race gauges ", r$gauges, " not in its report", call. = FALSE)
    }
    # every setting's scores, both routes, from the report's two tables (the series file keeps only the
    # migration mean's); the migration-mean rows must agree with the series file
    sec <- function(from, to) rp$lines[seq(grep(from, rp$lines)[1], grep(to, rp$lines)[1])]
    s2 <- sec("^Sensitivities \\(median over gauges", "^Leak-free: ")
    s3 <- sec("^By setting \\(median and quartiles", "^Per gauge, migration mean")
    for (lab in c("migration mean, k = 5", "spawning mean", "migration min7", "spawning min7",
                  "migration cov_day \\(days\\)", "spawning cov_day \\(days\\)")) {
      e2 <- grep(sprintf("^  %s +[0-9]+ +[0-9]+ ", lab), s2, value = TRUE)
      e3 <- grep(sprintf("^  %s +[0-9]+ ", lab), s3, value = TRUE)
      if (length(e2) != 1 || length(e3) != 1) stop(id, " ", group, ": no single score row for ", lab, call. = FALSE)
      f2 <- strsplit(trimws(sub(sprintf("^  %s", lab), "", e2)), " +")[[1]]
      f3 <- strsplit(trimws(sub(sprintf("^  %s", lab), "", e3)), " +")[[1]]
      num <- function(z) if (identical(z, "-")) NA_real_ else as.numeric(z)
      score_rows[[length(score_rows) + 1]] <- data.frame(site_id = id, group = group,
        setting = gsub("\\\\", "", lab), ext_gauges = as.integer(f2[1]), ols = num(f2[3]), move1 = num(f2[4]),
        ratio = num(f2[5]), carried_n = as.integer(f3[1]), carried_q25 = num(f3[2]), carried = num(f3[3]),
        carried_q75 = num(f3[4]))
    }
    mig_row <- score_rows[[length(score_rows) - 5]]
    if (!isTRUE(all.equal(c(mig_row$ols, mig_row$carried), round(c(r$med[["ols"]], cq$median), 2)))) {
      stop(id, " ", group, ": the report's migration-mean scores differ from the series file's", call. = FALSE)
    }
    scores[[length(scores) + 1]] <- data.frame(site_id = id, group = group, ols = r$med[["ols"]],
      move1 = r$med[["move1"]], ratio = r$med[["ratio"]], rule_pick = r$rule_pick, ext_gauges = r$gauges,
      below_floor = r$below_floor, carried = cq$median, carried_q25 = cq$q[1], carried_q75 = cq$q[3],
      carried_gauges = cq$n, usable = cq$usable, short = cq$short)

    # the snow fits, held to the snow report's coefficient table
    ci3 <- function(b, lo, hi, d = 3) ifelse(is.na(b), "-", sprintf("%s [%s, %s]", fmt(b, d), fmt(lo, d), fmt(hi, d)))
    for (i in seq_len(nrow(s$fits))) {
      f <- s$fits[i, ]
      se <- s$series[[f$series]]
      held(sprintf("  %-26s %-5s %4d %26s %26s %26s %6s %5s %6s %5d", sprintf("%s %s", se$label, se$window), f$model, f$n,
                   ci3(f$b0, f$b0_lo, f$b0_hi), ci3(f$bs, f$bs_lo, f$bs_hi), ci3(f$bd, f$bd_lo, f$bd_hi),
                   fmt(f$sigma, 3), fmt(f$r2), fmt(f$lag1), f$pairs), rs$lines, paste(id, group, "snow", i))
      if (f$model == "both") next
      snow[[length(snow) + 1]] <- data.frame(site_id = id, group = group, gauge = se$gauge,
        series = sub("^\\S+ ", "", se$label), window = se$window, predictor = f$model,
        slope = if (f$model == "swe") f$bs else f$bd, lo = if (f$model == "swe") f$bs_lo else f$bd_lo,
        hi = if (f$model == "swe") f$bs_hi else f$bd_hi, r2 = f$r2, n = f$n)
    }

    # the ungauged site's normal and its error
    if (site$kind == "ungauged") {
      nm <- x$normal
      for (w in x$windows$window) {
        held(sprintf("  %-10s %12s %12s  %s", w, fmt(nm$sources$q_m3s[nm$sources$window == w & nm$sources$source == "pcic_routed"], 3),
                     fmt(nm$sources$q_m3s[nm$sources$window == w & nm$sources$source == "wet_balance"], 3), nm$pick),
             rp$lines, paste(id, group, "normal", w))
        if (!any(grepl(sprintf("build digest %s, on the mouth segment", nm$digest), rp$lines, fixed = TRUE))) {
          stop(id, " ", group, ": build digest ", nm$digest, " not in its report", call. = FALSE)
        }
        e <- nm$error[nm$error$window == w & !is.na(nm$error$log_ratio), ]
        eu <- e[!e$calib, ]
        q <- stats::quantile(e$log_ratio, c(0.25, 0.5, 0.75), names = FALSE)
        held(sprintf("  %-10s %5d %9s %9s %9s   %9d %9s %9s", w, nrow(e), fmt(q[1], 3), fmt(q[2], 3), fmt(q[3], 3), nrow(eu),
                     if (nrow(eu)) fmt(stats::median(eu$log_ratio), 3) else "-",
                     if (nrow(eu)) fmt(stats::median(abs(eu$log_ratio)), 3) else "-"), rp$lines, paste(id, group, "error", w))
        normal[[length(normal) + 1]] <- data.frame(site_id = id, group = group, window = w,
          pcic_routed = nm$sources$q_m3s[nm$sources$window == w & nm$sources$source == "pcic_routed"],
          wet_balance = nm$sources$q_m3s[nm$sources$window == w & nm$sources$source == "wet_balance"],
          pick = nm$pick, digest = nm$digest, normal = nm$normal$q_m3s[nm$normal$window == w], err_n = nrow(e), err_q25 = q[1],
          err_median = q[2], err_q75 = q[3], err_n_out = nrow(eu),
          err_median_out = if (nrow(eu)) stats::median(eu$log_ratio) else NA_real_,
          err_abs_out = if (nrow(eu)) stats::median(abs(eu$log_ratio)) else NA_real_)
      }
    }

    # the gauges the numbers rest on: every donor of every scored statistic, window and window set
    scored <- Filter(function(m) m$v != "q_max", x$mx)
    ext_don <- if (site$kind == "extend") sort(unique(unlist(lapply(scored, function(m) stats::na.omit(m$e$donor))))) else character()
    car_don <- sort(unique(sub(":.*", "", unlist(lapply(scored, function(m) strsplit(m$a$donors, " "))))))
    gauges[[length(gauges) + 1]] <- rbind(
      if (site$kind == "extend") data.frame(site_id = id, station_number = target, role = "target"),
      if (length(ext_don)) data.frame(site_id = id, station_number = ext_don, role = "extension donor"),
      data.frame(site_id = id, station_number = car_don, role = "carried donor"),
      data.frame(site_id = id, station_number = s$gauges, role = "snow"))
    windows[[length(windows) + 1]] <- data.frame(site_id = id, group = group, x$windows)
    if (group == "BULK") {
      mm <- x$mx[["q_mean migration"]]
      if (site$kind == "extend") {
        obs <- sort(mm$e$year[mm$e$source == "observed"])
        held(sprintf("Target, complete migration-window years by this definition: %s %d (%s).", target, length(obs),
                     paste(vapply(split(obs, cumsum(c(1, diff(obs) != 1))), function(r) {
                       if (length(r) > 1) sprintf("%d-%d", min(r), max(r)) else as.character(r)
                     }, ""), collapse = ", ")), rp$lines, paste(id, "observed years"))
        # the pool table's row: station, name, then the area right-aligned, then the migration years
        km2_pat <- sprintf("^  %s .* %s +%d ", target, gsub(".", "\\.", fmt(x$pool$drainage_area_gross_km2[x$pool$station_number == target], 1),
                                                             fixed = TRUE), length(obs))
        if (sum(grepl(km2_pat, rp$lines)) != 1) stop(id, ": target area not in its report's pool table", call. = FALSE)
      } else if (!any(grepl(sprintf("with the basin's FWA area, %s km2", fmt(x$normal$km2, 1)), rp$lines, fixed = TRUE))) {
        stop(id, ": basin area not in its report", call. = FALSE)
      }
      sites[[length(sites) + 1]] <- data.frame(site_id = id, name = site$name, wsg_code = site$wsg_code,
        kind = site$kind, target = target, blue_line_key = site$blue_line_key,
        target_lon = if (site$kind == "ungauged") site$target_lon else NA_real_,
        target_lat = if (site$kind == "ungauged") site$target_lat else NA_real_,
        km2 = if (site$kind == "ungauged") x$normal$km2 else x$pool$drainage_area_gross_km2[x$pool$station_number == target],
        windows = paste(names(site_windows(site)), collapse = " "),
        lon_span = site$box[["lon_max"]] - site$box[["lon_min"]], lat_span = site$box[["lat_max"]] - site$box[["lat_min"]],
        obs_first = if (site$kind == "extend") min(mm$e$year[mm$e$source == "observed"]) else NA_integer_,
        obs_last = if (site$kind == "extend") max(mm$e$year[mm$e$source == "observed"]) else NA_integer_,
        obs_n = if (site$kind == "extend") sum(mm$e$source == "observed") else 0L)
    }
  }
}

# the Chinook use behind the article's first section, read from its tracked report
use_report <- file.path("data", "checks", "chinook_sites_use.txt")
ul <- readLines(use_report)
reports[use_report] <- unname(tools::md5sum(use_report))
hdr <- grep("^  stream +wsg +blkey", ul)
stopifnot(length(hdr) == 1)
rows <- ul[(hdr + 1):(hdr + 5)]
use <- do.call(rbind, lapply(rows, function(r) {
  m <- regmatches(r, regexec(paste0("^  (.+?) +([A-Z]{4}) +([0-9]+) +(\\S+) +([0-9.]+) +(.+?) +([0-9]+) +([0-9]+) +([0-9]+) +",
                                    "(\\S+) +([0-9]+) +([0-9]+) +(\\S+) +([0-9]+)$"), r))[[1]]
  if (length(m) != 15) stop("cannot read the use table row: ", r, call. = FALSE)
  yr <- as.integer(strsplit(m[11], "-")[[1]])
  data.frame(stream = m[2], wsg = m[3], blue_line_key = as.integer(m[4]), role = m[5], km2 = as.numeric(m[6]),
             nus_rows = as.integer(m[8]), nus_use = as.integer(m[9]), nus_use_years = as.integer(m[10]),
             nus_first = if (length(yr) == 2) yr[1] else NA_integer_, nus_last = if (length(yr) == 2) yr[2] else NA_integer_,
             obs = as.integer(m[12]), obs_spawning = as.integer(m[13]))
}))
# every new site's stream is in the use table (Maxan's use is its own article's)
stopifnot(all(vapply(sites, function(x) x$site_id == "maxan" || x$blue_line_key %in% use$blue_line_key, TRUE)))
obs_rows <- grep("^  \\S.+ +([0-9]{4}-[0-9]{2}-[0-9]{2}|NA) +[0-9]+ m  ", ul, value = TRUE)
use_obs <- do.call(rbind, lapply(obs_rows, function(r) {
  m <- regmatches(r, regexec("^  (.+?) +([0-9]{4}-[0-9]{2}-[0-9]{2}|NA) +([0-9]+) m  (.{40}) ", r))[[1]]
  if (length(m) != 5) stop("cannot read the observation row: ", r, call. = FALSE)
  data.frame(stream = m[2], date = as.Date(if (m[3] == "NA") NA_character_ else m[3]), measure_m = as.integer(m[4]),
             activity = trimws(m[5]))
}))
# every observation the use table counts is a row here
if (!identical(as.integer(table(factor(use_obs$stream, levels = use$stream))), use$obs)) {
  stop("the observation rows do not add up to the use table's counts", call. = FALSE)
}

# ---- each site's typical year, from the published daily flow ----------------------------------
targets <- unlist(lapply(sites, function(x) if (x$kind == "extend") x$target))
hcon <- wet:::wet_hydat_connect(wet:::wet_hydat(release))
gauged_st <- DBI::dbGetQuery(hcon, sprintf(
  "SELECT STATION_NUMBER station_number, LONGITUDE lon, LATITUDE lat, DRAINAGE_AREA_GROSS drainage_area_gross_km2
   FROM STATIONS WHERE STATION_NUMBER IN (%s) ORDER BY STATION_NUMBER", paste0("'", targets, "'", collapse = ", ")))
DBI::dbDisconnect(hcon)
stopifnot(setequal(gauged_st$station_number, targets))
conn <- vd_connect()
sn <- wet_station_snap(conn, gauged_st)
DBI::dbDisconnect(conn)
if (!all(sn$accepted %in% TRUE)) stop("a gauged target's snap is not accepted", call. = FALSE)
catalog <- wet_catalog()
digest <- wet:::wet_catalog_digest(catalog)
nm_g <- readRDS(file.path("data", "departure", sprintf("departure_site_gosnell_bulk_%s.rds", release)))$normal
if (!identical(digest, nm_g$digest)) {
  stop("the live build (", digest, ") is not the one the Gosnell report read (", nm_g$digest, ")", call. = FALSE)
}
dly <- catalog[catalog$dataset == "discharge/fwa/v1/segment_daily" & catalog$scenario == "historical", ]
duck <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(duck, "INSTALL httpfs; LOAD httpfs;")
daily <- do.call(rbind, lapply(sites, function(x) {
  site <- site_get(x$site_id)
  lfid <- if (site$kind == "extend") sn$linear_feature_id[sn$station_number == x$target] else nm_g$segment$linear_feature_id
  parts <- dly[dly$code == site$wsg_code, ]
  stopifnot(nrow(parts) == 2, length(lfid) == 1)
  d <- do.call(rbind, lapply(seq_len(nrow(parts)), function(i) {
    # the source is a Hive key, not a column (as scripts/departure_site.R reads it)
    y <- DBI::dbGetQuery(duck, sprintf(
      "SELECT linear_feature_id, doy, q_m3s, pick FROM read_parquet(%s, hive_partitioning = false)
       WHERE linear_feature_id = %d ORDER BY doy", DBI::dbQuoteString(duck, parts$href[i]), as.integer(lfid)))
    if (nrow(y) != 365) stop(x$site_id, ": ", nrow(y), " days of ", parts$source[i], " on segment ", lfid, call. = FALSE)
    y$source <- parts$source[i]
    y
  }))
  data.frame(site_id = x$site_id, d, md5 = dly$md5[match(d$source, dly$source[dly$code == site$wsg_code])])
}))
DBI::dbDisconnect(duck, shutdown = TRUE)
if (anyDuplicated(unique(daily[daily$pick, c("site_id", "doy")]))) stop("two picked sources on one day", call. = FALSE)
# Gosnell's picked days give the window means its report holds
gd <- daily[daily$site_id == "gosnell" & daily$pick, ]
wins <- do.call(rbind, windows)
wf <- wet_flow_window(data.frame(linear_feature_id = 1L, doy = gd$doy, q_m3s = gd$q_m3s, source = "pick"),
                      wins[wins$site_id == "gosnell" & wins$group == "BULK", c("window", "start", "end")])
nb <- do.call(rbind, normal)
nb <- nb[nb$site_id == "gosnell" & nb$group == "BULK", ]
if (!isTRUE(all.equal(wf$q_m3s, nb$normal[match(wf$window, nb$window)]))) {
  stop("Gosnell's published days do not give its report's normal", call. = FALSE)
}

values <- list(
  sites = do.call(rbind, sites), change = do.call(rbind, change), scores = do.call(rbind, scores),
  snow = do.call(rbind, snow), normal = do.call(rbind, normal),
  gauges = unique(do.call(rbind, gauges)), windows = do.call(rbind, windows), use = use, use_obs = use_obs,
  score_settings = do.call(rbind, score_rows), daily = daily, years = do.call(rbind, years),
  provenance = list(wet_commit = wet_commit, built = format(Sys.Date()), hydat = release, scripts = md5,
                    reports = reports))
rownames(values$change) <- NULL
rownames(values$snow) <- NULL
saveRDS(values, out, compress = "xz")
message("chinook_sites_values.rds: ", round(file.size(out) / 1024), " KB; ", nrow(values$change), " change rows")
