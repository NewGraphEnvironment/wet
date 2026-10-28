# Data for vignettes/articles/chinook-sites.Rmd (#126), which runs on this file
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
#     extension donor, carried donor, snow)
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

    # the scores, held to section 2's rule line and section 3's headline
    r <- x$race
    held(sprintf("#120's rule here: the highest median is %s (%s); ratio's is %s; margin %s. It would pick %s. The target is extended by ols (fixed at #126's gate)%s.",
                 names(r$med)[which.max(r$med)], fmt(max(r$med), 3), fmt(r$med[["ratio"]], 3), 0.01, r$rule_pick,
                 if (r$rule_pick == "ols") ", which #120's rule also picks here" else ", which #120's rule would NOT pick here"),
         rp$lines, paste(id, group, "race"))
    cq <- x$carried
    held(sprintf("HEADLINE: median per-gauge NSE %s (quartiles %s to %s) over %d gauges scored; %d not scored (fewer than 3 years).",
                 fmt(cq$q[2]), fmt(cq$q[1]), fmt(cq$q[3]), cq$n,
                 as.integer(sub(".* (\\d+) not scored.*", "\\1", grep("^HEADLINE: ", rp$lines, value = TRUE)))),
         rp$lines, paste(id, group, "headline"))
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
        e <- nm$error[nm$error$window == w & !is.na(nm$error$log_ratio), ]
        eu <- e[!e$calib, ]
        q <- stats::quantile(e$log_ratio, c(0.25, 0.5, 0.75), names = FALSE)
        held(sprintf("  %-10s %5d %9s %9s %9s   %9d %9s %9s", w, nrow(e), fmt(q[1], 3), fmt(q[2], 3), fmt(q[3], 3), nrow(eu),
                     if (nrow(eu)) fmt(stats::median(eu$log_ratio), 3) else "-",
                     if (nrow(eu)) fmt(stats::median(abs(eu$log_ratio)), 3) else "-"), rp$lines, paste(id, group, "error", w))
        normal[[length(normal) + 1]] <- data.frame(site_id = id, group = group, window = w,
          pcic_routed = nm$sources$q_m3s[nm$sources$window == w & nm$sources$source == "pcic_routed"],
          wet_balance = nm$sources$q_m3s[nm$sources$window == w & nm$sources$source == "wet_balance"],
          pick = nm$pick, normal = nm$normal$q_m3s[nm$normal$window == w], err_n = nrow(e), err_q25 = q[1],
          err_median = q[2], err_q75 = q[3], err_n_out = nrow(eu),
          err_median_out = if (nrow(eu)) stats::median(eu$log_ratio) else NA_real_,
          err_abs_out = if (nrow(eu)) stats::median(abs(eu$log_ratio)) else NA_real_)
      }
    }

    # the gauges the numbers rest on (the Bulkley windows' run names them)
    if (group == "BULK") {
      mm <- x$mx[["q_mean migration"]]
      ext_don <- if (site$kind == "extend") sort(unique(stats::na.omit(mm$e$donor))) else character()
      car_don <- sort(unique(sub(":.*", "", unlist(strsplit(mm$a$donors, " ")))))
      gauges[[length(gauges) + 1]] <- rbind(
        if (site$kind == "extend") data.frame(site_id = id, station_number = target, role = "target"),
        if (length(ext_don)) data.frame(site_id = id, station_number = ext_don, role = "extension donor"),
        data.frame(site_id = id, station_number = car_don, role = "carried donor"),
        data.frame(site_id = id, station_number = s$gauges, role = "snow"))
      sites[[length(sites) + 1]] <- data.frame(site_id = id, name = site$name, wsg_code = site$wsg_code,
        kind = site$kind, target = target, blue_line_key = site$blue_line_key,
        target_lon = if (site$kind == "ungauged") site$target_lon else NA_real_,
        target_lat = if (site$kind == "ungauged") site$target_lat else NA_real_,
        km2 = if (site$kind == "ungauged") x$normal$km2 else x$pool$drainage_area_gross_km2[x$pool$station_number == target],
        windows = paste(names(site_windows(site)), collapse = " "),
        obs_first = if (site$kind == "extend") min(mm$e$year[mm$e$source == "observed"]) else NA_integer_,
        obs_last = if (site$kind == "extend") max(mm$e$year[mm$e$source == "observed"]) else NA_integer_,
        obs_n = if (site$kind == "extend") sum(mm$e$source == "observed") else 0L)
    }
  }
}

values <- list(
  sites = do.call(rbind, sites), change = do.call(rbind, change), scores = do.call(rbind, scores),
  snow = do.call(rbind, snow), normal = do.call(rbind, normal), gauges = do.call(rbind, gauges),
  provenance = list(wet_commit = wet_commit, built = format(Sys.Date()), hydat = release, scripts = md5,
                    reports = reports))
rownames(values$change) <- NULL
rownames(values$snow) <- NULL
saveRDS(values, out, compress = "xz")
message("chinook_sites_values.rds: ", round(file.size(out) / 1024), " KB; ", nrow(values$change), " change rows")
