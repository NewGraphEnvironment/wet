# Small-stream logger records: each site on the network, and the series' check report (#235, #215)
#
#   Rscript scripts/temp_loggers.R place [nhg]   # once, with fwapg: writes the placement file
#   Rscript scripts/temp_loggers.R [nhg]         # the report, from the cache and the tracked files
#
# place: every registry site snapped with fwa_indexpoint() (rg_snap_tolerance_m, 1000 m, and
#   rg_snap_candidates, 5, from scripts/station_regulation_rule.R) and picked by rg_snap_pick():
#   the candidate on the stream the site's name gives (leg "name"). Loggers carry no drainage
#   area, so the rule's area leg never applies; a site with no candidate on its named stream
#   takes the nearest candidate within nearest_m (100 m), leg "nearest", or stays unplaced with
#   the reason. Each placed site is given its segment on fwapg's main-flow tree
#   (whse_basemapping.fwa_stream_networks_mainflow_tree): the snapped segment where the tree
#   holds it ("on tree"), else the tree segment on the same blue line nearest by measure
#   ("same blue line"), else none ("off tree"). Refused without the tree table; its row count is
#   written beside each row. Writes inst/extdata/temp_loggers/<series>_<version>_placement.csv,
#   keyed to the registry by its md5 (`registry_md5`). Connects with the WET_PG* variables.
#
# report: reads the series through wet's own reader, the placement file (never the database)
#   and the earlier record, and writes data/checks/temp_loggers_<series>_<version>.txt:
#   - the manifests and the files and members read, with md5s; sites, readings and days;
#   - days dropped by each logger rule, and the holder's own flags beside them;
#   - the two records compared on the readings and days they share;
#   - placement, and the sites within 0.5 km of an ECCC water temperature station;
#   - per site, complete growing seasons (a wet_temp_gsdd() value), seasons that need only their
#     shoulders filled (every missing day of 1 March-30 November in 1 March-15 May or
#     1 October-30 November), and observed days against wet_temp_fill(min_days = 365).
#   Nothing in it depends on the run's time, so a rerun from the cache writes it byte for byte.

devtools::load_all(quiet = TRUE)
source("scripts/station_sources_lib.R")  # stream_of()
source("scripts/station_regulation_rule.R")  # rg_snap_pick(), rg_snap_tolerance_m, rg_snap_candidates
source("scripts/station_regulation_lib.R")  # rg_sql_snap

args <- commandArgs(trailingOnly = TRUE)
place <- length(args) && args[1] == "place"
series <- if (length(args) > place) args[place + 1] else "nhg"
version <- wet_logger_versions[[series]]
prior <- "6426024"
out_dir <- file.path("inst", "extdata", "temp_loggers")
reg_path <- file.path(out_dir, sprintf("%s_%s_sites.csv", series, version))
place_path <- file.path(out_dir, sprintf("%s_%s_placement.csv", series, version))
report <- file.path("data", "checks", sprintf("temp_loggers_%s_%s.txt", series, version))
nearest_m <- 100
same_site_km <- 0.5
reg <- wet_logger_sites(series, version)
reg_md5 <- unname(tools::md5sum(reg_path))

# ---- placement --------------------------------------------------------------------------------
if (place) {
  conn <- DBI::dbConnect(RPostgres::Postgres(), host = Sys.getenv("WET_PGHOST", "localhost"),
                         port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                         dbname = Sys.getenv("WET_PGDATABASE", "fwapg"), user = Sys.getenv("WET_PGUSER", "postgres"),
                         password = Sys.getenv("WET_PGPASSWORD", "postgres"), connect_timeout = 10)
  tree_tbl <- "whse_basemapping.fwa_stream_networks_mainflow_tree"
  if (is.na(DBI::dbGetQuery(conn, sprintf("SELECT to_regclass('%s')::text AS t", tree_tbl))$t)) {
    stop("this fwapg has no ", tree_tbl, ": place the loggers on a database that holds the main-flow tree")
  }
  tree_rows <- DBI::dbGetQuery(conn, sprintf("SELECT count(*)::double precision AS n FROM %s", tree_tbl))$n
  DBI::dbWriteTable(conn, "rg_st", reg[c("station_number", "lon", "lat")], temporary = TRUE)
  cand <- DBI::dbGetQuery(conn, sprintf(rg_sql_snap, rg_snap_tolerance_m, rg_snap_candidates))
  cand <- cand[order(cand$station_number, cand$linear_feature_id, method = "radix"), ]
  pick <- do.call(rbind, lapply(seq_len(nrow(reg)), function(i) {
    c_i <- cand[cand$station_number == reg$station_number[i], , drop = FALSE]
    p <- rg_snap_pick(c_i, reg$name[i], NA_real_)
    if (!p$accepted && p$reason == "no candidate on the named stream and no drainage area") {
      near <- c_i[!is.na(c_i$watershed_feature_id) & c_i$distance_m <= nearest_m, , drop = FALSE]
      if (nrow(near)) {
        j <- order(near$distance_m, near$linear_feature_id)[1]
        p <- data.frame(accepted = TRUE, leg = "nearest", linear_feature_id = near$linear_feature_id[j],
                        distance_m = near$distance_m[j], upstream_area_km2 = near$upstream_area_km2[j],
                        area_ratio = NA_real_, reason = "")
      } else {
        p$reason <- sprintf("no candidate on the named stream and none within %d m", nearest_m)
      }
    }
    p
  }))
  j <- match(paste(reg$station_number, pick$linear_feature_id), paste(cand$station_number, cand$linear_feature_id))
  pl <- data.frame(station_number = reg$station_number, registry_md5 = reg_md5, placed = pick$accepted,
                   leg = ifelse(pick$accepted, pick$leg, NA), distance_m = round(pick$distance_m, 1),
                   gnis_name = cand$gnis_name[j], blue_line_key = cand$blue_line_key[j],
                   downstream_route_measure = round(cand$measure[j], 1), linear_feature_id = pick$linear_feature_id,
                   watershed_group_code = cand$watershed_group_code[j], reason = pick$reason)
  for (v in c("gnis_name", "blue_line_key", "downstream_route_measure", "linear_feature_id", "watershed_group_code",
              "distance_m")) {
    pl[[v]][!pl$placed] <- NA
  }
  # the main-flow tree segment
  tree <- DBI::dbGetQuery(conn, sprintf(
    "SELECT t.linear_feature_id::double precision AS linear_feature_id, s.blue_line_key,
            s.downstream_route_measure AS m0, s.downstream_route_measure + s.length_metre AS m1
     FROM %s t JOIN whse_basemapping.fwa_stream_networks_sp s USING (linear_feature_id)
     WHERE s.blue_line_key IN (%s) ORDER BY t.linear_feature_id", tree_tbl,
    paste(unique(stats::na.omit(pl$blue_line_key)), collapse = ", ")))
  DBI::dbDisconnect(conn)
  pl$tree_linear_feature_id <- NA_real_
  pl$tree_leg <- NA_character_
  for (i in which(pl$placed)) {
    if (pl$linear_feature_id[i] %in% tree$linear_feature_id) {
      pl$tree_linear_feature_id[i] <- pl$linear_feature_id[i]
      pl$tree_leg[i] <- "on tree"
      next
    }
    t_i <- tree[tree$blue_line_key == pl$blue_line_key[i], ]
    if (!nrow(t_i)) {
      pl$tree_leg[i] <- "off tree"
      next
    }
    m <- cand$measure[match(paste(pl$station_number[i], pl$linear_feature_id[i]),
                            paste(cand$station_number, cand$linear_feature_id))]
    gap <- pmax(t_i$m0 - m, m - t_i$m1, 0)
    k <- order(gap, t_i$linear_feature_id)[1]
    pl$tree_linear_feature_id[i] <- t_i$linear_feature_id[k]
    pl$tree_leg[i] <- "same blue line"
  }
  pl$tree_rows <- tree_rows
  utils::write.csv(pl, place_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  message("wrote ", place_path, ": ", sum(pl$placed), " of ", nrow(pl), " sites placed; tree rows ",
          format(tree_rows, big.mark = ","))
  quit(save = "no")
}

# ---- report -----------------------------------------------------------------------------------
pl <- utils::read.csv(place_path, na.strings = "", encoding = "UTF-8", colClasses = c(station_number = "character"))
if (!all(pl$registry_md5 == reg_md5) || !setequal(pl$station_number, reg$station_number)) {
  stop(place_path, " was not written from the current registry: run `Rscript scripts/temp_loggers.R place` again")
}
man <- wet_logger_manifest(series, version)
man_p <- wet_logger_manifest(series, prior)
ex <- tempfile("loggers_")
paths <- wet_logger_members(series, version, reg$member, exdir = ex)

reads <- lapply(paths, wet_logger_read)
days <- lapply(seq_len(nrow(reg)), function(i) {
  wet_logger_days(reads[[i]], reg$clock_offset[i], reg$day_offset[i])
})
names(reads) <- names(days) <- reg$station_number
kept <- lapply(days, function(d) d[is.na(d$drop), ])
reasons <- c("stuck", "hours", "deployment", "air")

# the earlier record, in its own format (DateTime (UTC), Temperature (C), Flag), read for the comparison only
prior_read <- function(p) {
  x <- utils::read.csv(p, colClasses = "character", check.names = FALSE, na.strings = character())
  stopifnot(identical(names(x), c("DateTime (UTC)", "Temperature (C)", "Flag")))
  time <- as.POSIXct(x[[1]], format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  stopifnot(!anyNA(time))
  t <- suppressWarnings(as.numeric(x[[2]]))
  stopifnot(all(!is.na(t) | x[[2]] %in% c("NA", "")))
  # an hour stamped twice (at the autumn and spring clock changes) is left out, both copies, and counted
  twice <- duplicated(time) | duplicated(time, fromLast = TRUE)
  out <- data.frame(time = time, t = t, flag = x[[3]], pass = x[[3]] %in% c("P", "A"))[!twice, ]
  attr(out, "twice") <- sum(twice)
  out
}
has_prior <- which(!is.na(reg$prior_member))
ppaths <- wet_logger_members(series, prior, reg$prior_member[has_prior], exdir = file.path(ex, "prior"))
cmp <- do.call(rbind, lapply(seq_along(has_prior), function(k) {
  i <- has_prior[k]
  a <- reads[[i]]
  b <- prior_read(ppaths[k])
  twice <- attr(b, "twice")
  a <- a[!is.na(a$t), ]
  b <- b[!is.na(b$t), ]
  equal_at <- function(shift) {
    sh <- intersect(as.numeric(a$time), as.numeric(b$time) + shift)
    sum(abs(a$t[match(sh, as.numeric(a$time))] - b$t[match(sh, as.numeric(b$time) + shift)]) < 0.005)
  }
  sh <- intersect(as.numeric(a$time), as.numeric(b$time))
  ta <- a$t[match(sh, as.numeric(a$time))]
  tb <- b$t[match(sh, as.numeric(b$time))]
  da <- kept[[i]]
  db <- wet_logger_days(b, reg$clock_offset[i], reg$day_offset[i])
  db <- db[is.na(db$drop), ]
  sd <- intersect(as.numeric(da$date), as.numeric(db$date))
  diff_d <- da$t_mean_c[match(sd, as.numeric(da$date))] - db$t_mean_c[match(sd, as.numeric(db$date))]
  data.frame(station_number = reg$station_number[i], prior_code = reg$prior_code[i], prior_readings = nrow(b),
             twice = twice, shared = length(sh), equal = sum(abs(ta - tb) < 0.005),
             equal_minus1h = equal_at(-3600), equal_plus1h = equal_at(3600), only_prior = nrow(b) - length(sh),
             prior_days = nrow(db), shared_days = length(sd), only_prior_days = length(setdiff(db$date, da$date)),
             max_day_diff = if (length(sd)) max(abs(diff_d)) else NA_real_)
}))

# seasons
season <- function(d, sid) {
  if (!nrow(d)) return(data.frame(year = integer(), complete = logical(), shoulders = logical()))
  g <- wet_temp_gsdd(data.frame(station_number = sid, date = d$date, t_mean_c = d$t_mean_c, status = "provisional"))
  yrs <- sort(unique(as.integer(format(d$date, "%Y"))))
  do.call(rbind, lapply(yrs, function(y) {
    win <- seq(as.Date(sprintf("%d-03-01", y)), as.Date(sprintf("%d-11-30", y)), by = "day")
    miss <- win[!win %in% d$date]
    core <- miss >= as.Date(sprintf("%d-05-16", y)) & miss <= as.Date(sprintf("%d-09-30", y))
    complete <- any(g$year == y & is.finite(g$value))
    data.frame(year = y, complete = complete, shoulders = !complete && length(miss) < length(win) && !any(core))
  }))
}
seasons <- lapply(seq_len(nrow(reg)), function(i) season(kept[[i]], reg$station_number[i]))

# ---- write ------------------------------------------------------------------------------------
fmt <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
md5_line <- function(m) {
  sprintf("  %-70s %12s  %s%s", m$file, fmt(m$bytes), m$md5,
          ifelse(is.na(m$fetch), "", ifelse(m$fetch, "  fetch", "  no fetch")))
}
n_read <- vapply(reads, function(r) sum(!is.na(r$t)), 0)
alld <- do.call(rbind, lapply(names(days), function(s) cbind(station_number = s, days[[s]])))
flags <- table(factor(unlist(lapply(reads, function(r) r$flag[!is.na(r$t) | r$flag == "M"]))))
by_reason <- vapply(reasons, function(k) sum(alld$drop %in% k), 0)
flagged_by <- vapply(c(reasons, "kept"), function(k) {
  x <- if (k == "kept") is.na(alld$drop) else alld$drop %in% k
  sum(x & alld$n_flagged > 0)
}, 0)
near_eccc <- reg[reg$eccc_km <= same_site_km, ]
site_rows <- vapply(seq_len(nrow(reg)), function(i) {
  s <- seasons[[i]]
  d <- days[[i]]
  sprintf("  %-12s %-44s %3s %4d %6s %5d %5d %5d %5d %5d %6d %4d %4d %3s",
          reg$station_number[i], substr(reg$name[i], 1, 44), reg$subdrainage[i], sum(is.na(d$drop)),
          fmt(nrow(d)), sum(d$drop %in% "stuck"), sum(d$drop %in% "hours"), sum(d$drop %in% "deployment"),
          sum(d$drop %in% "air"), sum(d$drop %in% "air" & d$n_flagged > 0), nrow(s), sum(s$complete), sum(s$shoulders),
          if (sum(is.na(d$drop)) >= 365) "yes" else "no")
}, "")
tot_s <- do.call(rbind, seasons)
lines <- c(
  sprintf("Logger series %s, record %s (earlier record %s compared). wet's reader, logger rules registered in", series,
          version, prior),
  "research/station_water_temperature.md (\"Logger records\"); placement from the tracked file, not the database.",
  "",
  "## Pinned files",
  sprintf("Manifest %s (md5 %s):", basename(wet_logger_path(sprintf("%s_%s.csv", series, version))),
          unname(tools::md5sum(wet_logger_path(sprintf("%s_%s.csv", series, version))))),
  md5_line(man[is.na(man$fetch) == FALSE, ]),
  sprintf("  and %d zip members, each held to its md5", sum(is.na(man$fetch))),
  sprintf("Manifest %s (md5 %s):", basename(wet_logger_path(sprintf("%s_%s.csv", series, prior))),
          unname(tools::md5sum(wet_logger_path(sprintf("%s_%s.csv", series, prior))))),
  md5_line(man_p[is.na(man_p$fetch) == FALSE, ]),
  sprintf("  and %d zip members, each held to its md5", sum(is.na(man_p$fetch))),
  sprintf("Registry %s (md5 %s): %d sites.", basename(reg_path), reg_md5, nrow(reg)),
  "",
  "## Readings and days",
  sprintf("%s readings with a value at %d sites, %s to %s (UTC); %s local standard days with a valid reading,",
          fmt(sum(n_read)), nrow(reg),
          format(min(do.call(c, lapply(reads, function(r) min(r$time[!is.na(r$t)])))), "%Y-%m-%d %H:%M"),
          format(max(do.call(c, lapply(reads, function(r) max(r$time[!is.na(r$t)])))), "%Y-%m-%d %H:%M"),
          fmt(nrow(alld))),
  sprintf("%s kept.", fmt(sum(is.na(alld$drop)))),
  "Days dropped, by the first rule that dropped each:",
  sprintf("  %-11s %7s", reasons, fmt(by_reason)),
  "The holder's flags on the readings (P passed, A averaged from passing sensors, B icing, S spike or dewatering,",
  "E outside sensor limits, M missing, V site visit, C averaged from failing sensors; NHG's ReadMe):",
  sprintf("  %-2s %10s", names(flags), fmt(as.integer(flags))),
  "Days with at least one valid reading the holder did not pass, by our outcome (their flags are not used):",
  sprintf("  %-11s %7s", c(reasons, "kept"), fmt(flagged_by)),
  "",
  sprintf("## The two records compared (%d sites in both)", nrow(cmp)),
  "The earlier record's readings (times stamped twice left out: the earlier files repeat an hour at clock changes),",
  "those at a UTC time the later record holds, and how many are equal to 0.005 degC at the same time and with the",
  "earlier stamp moved an hour back or forward; then days kept by the same rules in both, and the largest difference",
  "in a shared day's mean (degC).",
  sprintf("  %-12s %-4s %8s %5s %8s %8s %8s %8s %8s %6s %6s %6s %8s", "site", "code", "earlier", "twice", "shared",
          "equal", "eq_-1h", "eq_+1h", "only_er", "days_e", "shared", "only_e", "max_diff"),
  sprintf("  %-12s %-4s %8s %5d %8s %8s %8s %8s %8s %6d %6d %6d %8s", cmp$station_number, cmp$prior_code,
          fmt(cmp$prior_readings), cmp$twice, fmt(cmp$shared), fmt(cmp$equal), fmt(cmp$equal_minus1h),
          fmt(cmp$equal_plus1h), fmt(cmp$only_prior), cmp$prior_days, cmp$shared_days, cmp$only_prior_days,
          sprintf("%.3f", cmp$max_day_diff)),
  sprintf("  all: %s earlier readings, %s at times the later record holds, %s of those equal (%s an hour back, %s an",
          fmt(sum(cmp$prior_readings)), fmt(sum(cmp$shared)), fmt(sum(cmp$equal)), fmt(sum(cmp$equal_minus1h)),
          fmt(sum(cmp$equal_plus1h))),
  sprintf("  hour forward); %d earlier days the later record does not keep.", sum(cmp$only_prior_days)),
  "",
  "## Placement",
  sprintf("From %s (main-flow tree of %s rows when placed): %d of %d sites placed; by leg: %s.", basename(place_path),
          fmt(pl$tree_rows[1]), sum(pl$placed), nrow(pl),
          paste(sprintf("%s %d", names(table(pl$leg)), as.integer(table(pl$leg))), collapse = ", ")),
  sprintf("On the tree: %s.", paste(sprintf("%s %d", names(table(pl$tree_leg)), as.integer(table(pl$tree_leg))),
                                    collapse = ", ")),
  if (any(!pl$placed)) sprintf("  unplaced: %s (%s)", pl$station_number[!pl$placed], pl$reason[!pl$placed]),
  sprintf("  %-12s %-8s %7s  %-30s %10s %11s %4s %-14s", "site", "leg", "dist_m", "stream", "blue_line",
          "measure_m", "wsg", "tree"),
  sprintf("  %-12s %-8s %7s  %-30s %10s %11s %4s %-14s", pl$station_number, ifelse(is.na(pl$leg), "-", pl$leg),
          ifelse(is.na(pl$distance_m), "-", sprintf("%.1f", pl$distance_m)),
          substr(ifelse(is.na(pl$gnis_name), "(unnamed)", pl$gnis_name), 1, 30),
          ifelse(is.na(pl$blue_line_key), "-", pl$blue_line_key),
          ifelse(is.na(pl$downstream_route_measure), "-", sprintf("%.1f", pl$downstream_route_measure)),
          ifelse(is.na(pl$watershed_group_code), "-", pl$watershed_group_code),
          ifelse(is.na(pl$tree_leg), "-", pl$tree_leg)),
  sprintf("Sites within %.1f km of an ECCC water temperature station (so not counted twice in a pool): %s.",
          same_site_km, if (nrow(near_eccc)) paste(sprintf("%s %.2f km from %s", near_eccc$station_number,
                                                           near_eccc$eccc_km, near_eccc$nearest_eccc),
                                                   collapse = "; ") else "none"),
  "",
  "## What can be scored, per site",
  "Kept days; days read; dropped by stuck, hours, deployment and air (air with a holder flag); years with any day;",
  "complete growing seasons (a wet_temp_gsdd() value, which needs 1 March-30 November all but unbroken); seasons that",
  "need only their shoulders filled; and whether the kept days reach wet_temp_fill()'s min_days = 365.",
  sprintf("  %-12s %-44s %3s %4s %6s %5s %5s %5s %5s %5s %6s %4s %4s %3s", "site", "name", "sub", "kept", "read",
          "stuck", "hours", "deplo", "air", "air_f", "years", "full", "shld", "365"),
  site_rows,
  sprintf(paste("  all: %d sites, %d site-years, %d complete growing seasons at %d sites, %d needing only shoulders",
                "at %d sites;"),
          nrow(reg), nrow(tot_s), sum(tot_s$complete),
          sum(vapply(seasons, function(s) any(s$complete), FALSE)), sum(tot_s$shoulders),
          sum(vapply(seasons, function(s) any(s$shoulders), FALSE))),
  sprintf("  %d sites reach 365 kept days.", sum(vapply(kept, nrow, 0L) >= 365)))
writeLines(lines, report)
unlink(ex, recursive = TRUE)
message("wrote ", report)
