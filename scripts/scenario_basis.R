# What wet's scenarios can be built on (#169, #4): the two checks move 6 (#168,
# research/pcic_channel_scale.md) left open, each under a rule registered below
# before any value it scores was read.
#
#   WET_FWAPG_COMMIT=<sha> WET_DATA_ROOT=<data dir> Rscript scripts/scenario_basis.R
#
# Rule 4 reads hydromosaic's listing of each outlet's series (no flow value) and
# says what each CMIP6 run lacks against the crosswalk fwapg stores. Rule 5 scores
# PCIC's six RCP 4.5 CMIP5 gridded runs against PNWNAmet in the Fraser, accumulated
# as the channel-scale pilot accumulated PNWNAmet.
#
# PCIC's robots.txt disallows /data/ and /hydromosaic, and the owner chose to ask
# PCIC first (#169 decision 1, 2026-11-25). So no request is made unless
# WET_SCENARIO_FETCH=1: without it every gridded read goes to an address that
# refuses (option wet.pcic_base), and the checks that need a request report
# "not run". Every request made is logged to
# <data root>/logs/169/scenario_basis_fetch.tsv, which the report reads.
#
# Report: data/checks/scenario_basis_<release>.txt (tracked). Findings:
# research/pcic_scenarios.md. Connection from WET_PG*.
#
# ---- rules registered before any flow value was read (#169) ------------------------------------
# Rule 4, each CMIP6 run against the stored crosswalk. Known before
# registration, from fwapg's own notes: 3 of PNWNAmet's 28 outlets with no
# series also lacked one for CNRM-ESM2-1 when it was last fetched, so that run
# has series where PNWNAmet has none, and fwapg's job, which refuses a run
# whose crosswalk differs from the stored one, would refuse it. The rule
# therefore measures what each run lacks, not whether the job runs unchanged.
# Population: every outlet of pcic.fwa_crosswalk. The reference set S is the
# outlets the stored crosswalk treats as having a series (flag is not
# no_series). An outlet's row for a run (a model and scenario) is its listing's
# streamflow row for that model and scenario; two such rows at one outlet stop
# the script. A row passes the day test when num_times equals the days from
# start_time to end_time, both ends counted, it starts on or before 1951-01-01
# and it ends on or after 2012-12-31 (PNWNAmet, historical) or 2099-12-31 (a
# GCM under "historical, ssp245" or "historical, ssp585"). An outlet has a
# series for the run when its row passes; an outlet whose row fails is counted
# apart ("listed, fails the day test") and has none. No flow value is read.
# Reported first, deciding nothing: the outlets where PNWNAmet's listing and S
# disagree (hydromosaic may have changed since the build). Then, per run of the
# 9 GCMs x 2 scenarios: A, the outlets of S with no series for the run, and B,
# the outlets outside S with one, each counted over the network, by PCIC
# domain (the pilot's domain_of()) and by crosswalk flag. Verdict per run,
# typed in this order: "runs as the job stands" (A and B empty); "runs on the
# stored crosswalk" (A empty, B not: the job need only keep the stored
# crosswalk and leave B's series out); "lacks series the crosswalk places" (A
# holds an outlet whose flag is NULL), with A's placed outlets by domain and
# whether the run's outlets with no series pass 100, where the job stops;
# otherwise "lacks series at unplaced outlets only". A run is "whole in a
# domain" when A holds none of that domain's outlets. A listing is a proxy for
# what a bulk request returns, which is what fwapg's job reads, so the pilot's
# cache is set against it: every outlet in a kept NetCDF of a model and
# scenario must have a series by its listing, and every single-outlet missing
# marker (batch_name() of the one outlet) must have none; the outlets where
# they disagree are listed and that run's verdict gains "listing and bulk
# disagree at n outlets". Nothing here chooses a GCM.
#
# Rule 5, CMIP5 gridded in the Fraser. Population: the pilot's scored gauges
# with an outlet whose domain is the Fraser (73 in the pilot's report), with
# their segments and observed annual flow as the pilot takes them (q_obs: the
# bundle's month-0 obs_mm over area_km2 at 365.25 days). Depth at a gauge, for
# PNWNAmet (TPS_gridded_obs_init) and for each CMIP5 run: RUNOFF + BASEFLOW,
# each month the mean over 1981-2010 of the month's total per cell
# (wet_pcic_monthly(), on the pilot's bbox for the Fraser), accumulated as the
# pilot's "wet's accumulation" was: the polygons of wet_ws_fetch(conn, "100"),
# centroid sampling, and for each month wet_upstream_mean(ws, <the month>,
# "total", irregular_pairs = wet_upstream_irregular(conn, "100")), read at the
# watershed of the gauge's segment. That gives twelve depths in mm. The annual
# flow is wet_mm_to_m3s(their sum, the accumulated area) at its default 365
# days; the monthly shares are the twelve depths over their sum. Parity before
# any CMIP5 file is asked for: PNWNAmet's annual flow at the pilot's sites
# salmon, quesnel, hope and lillooet (segments from
# scripts/channel_scale_sites.csv) equals the "wet acc" column of the pilot's
# tracked report at its two decimals. The rule is the pilot's rule 2 with the
# six RCP 4.5 runs in place of the nine "historical, ssp245" series, all six
# required at every gauge: |median over the 6 GCMs of annual flow -
# PNWNAmet's| / q_obs <= 0.05, and the share NSE (wet:::wet_nse() against the
# gauge's observed shares, the bundle's twelve obs_mm over their sum) of the
# 6-GCM median month (the median of the six depths month by month, then
# shares) no more than 0.05 below PNWNAmet's. The Fraser passes when the
# median over its gauges of each statistic meets it. RCP 8.5: each GCM's
# RCP 8.5 file is set against its RCP 4.5 file for 1981, 1993 and 2005 (the
# CMIP5 historical experiment ends in 2005), day by day and cell by cell, per
# variable, and the largest absolute difference reported; 2008, where the
# scenarios differ by construction, is compared the same way and only
# reported. Where a difference in 1981, 1993 or 2005 exceeds the larger
# scale_factor of the two files, the rule is scored on the six RCP 8.5 runs
# too, and the Fraser passes only if both sets do. Verdict: pass, "the Fraser
# builds on CMIP5 gridded"; fail, "DECISION TO USER: neither generation meets
# rule 2 in the Fraser", with the pilot's CMIP6 statistics for the Fraser
# beside these. Reported, deciding nothing: each GCM's own statistics; the
# rule with the gauges left out whose watershed is more than 5 % glacier (the
# CMIP5 runs carry no glacier model and PNWNAmet's does); the signed annual
# difference.
# ---- end of registered rules --------------------------------------------------------------------

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")         # wb_release(), wb_report()
source("scripts/pcic_routed_lib.R")    # routed_*
source("scripts/scenario_basis_lib.R") # domain_of(), listing(), fetch_log(), the guards

f_self <- "scripts/scenario_basis.R"
git <- function(...) {
  x <- suppressWarnings(system2("git", shQuote(c(...)), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts", "data-raw", "inst/vignette-data")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the report:\n",
                        paste(dirty, collapse = "\n"))
wet_commit <- git("rev-parse", "--short", "HEAD")
fwapg_commit <- routed_commit()
release <- wb_release()
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
stopifnot(dir.exists(data_root))
fetch <- identical(Sys.getenv("WET_SCENARIO_FETCH"), "1")
access <- "PCIC asked first (#169 decision 1); WET_SCENARIO_FETCH is not 1"
if (!fetch) options(wet.pcic_base = "http://127.0.0.1:9")   # a gridded cache miss fails, asking nothing
f_log <- file.path(data_root, "logs", "169", "scenario_basis_fetch.tsv")
listing_dir <- file.path(data_root, "scenario_basis", "listing")
pcic_dir <- file.path(data_root, "pcic")
pilot_raw <- file.path(data_root, "channel_scale", "raw", "services")
f_report <- file.path("data", "checks", sprintf("scenario_basis_%s.txt", release))
f_pilot <- file.path("data", "checks", sprintf("channel_scale_pilot_%s.txt", release))
pilot <- readLines(f_pilot)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
utc_txt <- function(x) format(x, "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")

# ---- the registration, and no request before it -------------------------------------------------
reg <- rule_registration(f_self, git)
first_fetch <- fetch_guard(read_fetch_log(f_log), reg$utc)

# ---- constants ----------------------------------------------------------------------------------
gcms6 <- c("CNRM-ESM2-1", "FGOALS-g3", "IPSL-CM6A-LR", "MIROC-ES2L", "MPI-ESM1-2-HR", "MRI-ESM2-0",
           "NorESM2-LM", "TaiESM1", "UKESM1-0-LL")
ssps <- c("historical, ssp245", "historical, ssp585")
cmip5 <- c(`ACCESS1-0` = "r1i1p1", CanESM2 = "r1i1p1", CCSM4 = "r2i1p1", `CNRM-CM5` = "r1i1p1",
           `HadGEM2-ES` = "r1i1p1", `MPI-ESM-LR` = "r3i1p1")
run5 <- function(gcm, rcp) sprintf("%s_%s_%s", gcm, rcp, cmip5[[gcm]])
pnw_run <- "TPS_gridded_obs_init"
base_years <- 1981:2010
r85_years <- c(1981L, 1993L, 2005L)
r85_report_only <- 2008L
vars <- c("RUNOFF", "BASEFLOW")
r5_ann <- 0.05
r5_nse <- 0.05
glacier_cut <- 0.05
domains <- c("Fraser", "Coast", "Columbia", "Peace")
parity_sites <- c("salmon", "quesnel", "hope", "lillooet")

# ---- database and the routed run ----------------------------------------------------------------
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"),
                       connect_timeout = 10)
routed_fp <- routed_fingerprint(conn)
rr <- readLines(wb_report("pcic_routed_compare", release))
if (!routed_report_line(fwapg_commit) %in% rr || !paste("table:", routed_fp) %in% rr) {
  stop("the routed table or WET_FWAPG_COMMIT is not the tracked routed report's", call. = FALSE)
}
xw <- DBI::dbGetQuery(conn, "
  SELECT subid, linear_feature_id::double precision AS linear_feature_id, flag
  FROM pcic.fwa_crosswalk ORDER BY subid")
stopifnot(!anyDuplicated(xw$subid))
xw$domain <- domain_of(xw$subid)
xw$flag_txt <- ifelse(is.na(xw$flag), "placed", xw$flag)
placed <- xw$subid[is.na(xw$flag)]

# ---- the pilot's scored gauges with an outlet, in the Fraser -----------------------------------
f_bundle <- file.path("inst", "vignette-data", "monthly_values.rds")
bundle <- readRDS(f_bundle)
gb <- bundle$gauges
g <- gb[gb$month == 0, c("station_number", "station_name", "linear_feature_id", "area_km2", "obs_mm", "routed_mm")]
g <- g[!is.na(g$routed_mm) & g$routed_mm / g$obs_mm >= routed_far_low, ]
g <- g[order(g$station_number), ]
rownames(g) <- NULL
w_g <- routed_weights(conn, g$linear_feature_id)
wi <- match(g$linear_feature_id, w_g$linear_feature_id)
own_seg <- xw$linear_feature_id[match(w_g$subid[wi], xw$subid)]
g$outlet <- ifelse(!is.na(wi) & !is.na(own_seg) & own_seg == g$linear_feature_id & w_g$subid[wi] %in% placed,
                   w_g$subid[wi], NA_integer_)
g$domain <- ifelse(is.na(g$outlet), NA, domain_of(g$outlet))
fr <- g[g$domain %in% "Fraser", ]
rownames(fr) <- NULL
n_pilot <- pilot_with_outlet(pilot, "Fraser")
if (nrow(fr) != n_pilot) {
  stop(nrow(fr), " Fraser gauges with an outlet, the pilot's Domains line says ", n_pilot, call. = FALSE)
}
obs_m <- reshape(gb[gb$month > 0, c("station_number", "month", "obs_mm")], idvar = "station_number",
                 timevar = "month", direction = "wide")
obs_m <- as.matrix(obs_m[match(fr$station_number, obs_m$station_number), paste0("obs_mm.", 1:12)])
fr_share <- obs_m / rowSums(obs_m)
fr$q_obs <- fr$obs_mm / 1000 * fr$area_km2 * 1e6 / (365.25 * 86400)
stamp(nrow(fr), " Fraser gauges with an outlet")

# ---- rule 4: what each CMIP6 run lacks against the stored crosswalk -----------------------------
day_pass <- function(li, gcm) {
  s <- as.Date(li$start_time)
  e <- as.Date(li$end_time)
  li$num_times == as.integer(e - s) + 1L & s <= as.Date("1951-01-01") &
    e >= as.Date(if (gcm) "2099-12-31" else "2012-12-31")
}
rule4 <- function() {
  ids <- xw$subid
  stamp("rule 4: ", length(ids), " listings")
  rows <- lapply(seq_along(ids), function(k) {
    li <- listing(ids[k], listing_dir, f_log, fetch)
    li <- li[li$variable == "streamflow", c("model", "scenario", "start_time", "end_time", "num_times")]
    if (nrow(li)) li$subid <- ids[k] else li$subid <- integer()
    li
  })
  lst <- do.call(rbind, rows)
  key <- paste(lst$subid, lst$model, lst$scenario)
  if (anyDuplicated(key)) stop("two streamflow rows for one run at outlet ", lst$subid[duplicated(key)][1], call. = FALSE)
  listing_md5 <- md5_text(sort(unname(tools::md5sum(file.path(listing_dir, paste0(ids, ".json.gz"))))))
  in_s <- xw$flag_txt != "no_series"
  # each outlet's state for a run: "series", "fails the day test" or "none"
  state <- function(model, scenario) {
    li <- lst[lst$model == model & lst$scenario == scenario, ]
    st <- rep("none", nrow(xw))
    i <- match(li$subid, xw$subid)
    st[i] <- ifelse(day_pass(li, model != "PNWNAmet"), "series", "fails the day test")
    st
  }
  pnw <- state("PNWNAmet", "historical")
  disagree <- xw[(pnw == "series") != in_s, c("subid", "domain", "flag_txt")]
  runs <- expand.grid(model = gcms6, scenario = ssps, stringsAsFactors = FALSE)
  res <- lapply(seq_len(nrow(runs)), function(r) {
    st <- state(runs$model[r], runs$scenario[r])
    has <- st == "series"
    a <- in_s & !has
    b <- !in_s & has
    a_placed <- a & xw$flag_txt == "placed"
    # the listing against the pilot's bulk cache, where the pilot fetched this run
    d <- file.path(pilot_raw, gsub("[^A-Za-z0-9]+", "_", paste(runs$model[r], runs$scenario[r], "streamflow")))
    n_bulk_disagree <- NA_integer_
    if (dir.exists(d)) {
      kept <- unique(unlist(lapply(list.files(d, "\\.nc$", full.names = TRUE), nc_ids)))
      marks <- sub("\\.missing$", "", list.files(d, "\\.missing$"))
      cand <- xw$subid[paste0("b", xw$subid %/% 1e6) %in% unique(sub("_.*$", "", marks))]
      marked <- cand[vapply(cand, batch_name, "") %in% marks]
      if (length(marked) != length(marks)) stop("a missing marker in ", d, " names no single outlet", call. = FALSE)
      bad <- c(kept[!has[match(kept, xw$subid)] %in% TRUE], marked[has[match(marked, xw$subid)] %in% TRUE])
      n_bulk_disagree <- length(bad)
    }
    verdict <- if (!any(a) && !any(b)) {
      "runs as the job stands"
    } else if (!any(a)) {
      "runs on the stored crosswalk"
    } else if (any(a_placed)) {
      "lacks series the crosswalk places"
    } else {
      "lacks series at unplaced outlets only"
    }
    if (!is.na(n_bulk_disagree) && n_bulk_disagree > 0L) {
      verdict <- sprintf("%s; listing and bulk disagree at %d outlets", verdict, n_bulk_disagree)
    }
    data.frame(model = runs$model[r], scenario = runs$scenario[r], a = sum(a), b = sum(b),
               fails_day = sum(st == "fails the day test"), no_series = sum(!has),
               stops_job = sum(!has) > 100, a_placed = sum(a_placed),
               a_fraser = sum(a & xw$domain == "Fraser"), a_coast = sum(a & xw$domain == "Coast"),
               a_columbia = sum(a & xw$domain == "Columbia"), a_peace = sum(a & xw$domain == "Peace"),
               whole_in = paste(domains[vapply(domains, function(dm) !any(a & xw$domain == dm), TRUE)],
                                collapse = ","),
               a_flags = paste(sprintf("%s %d", names(table(xw$flag_txt[a])), table(xw$flag_txt[a])), collapse = ", "),
               bulk_disagree = n_bulk_disagree, verdict = verdict)
  })
  list(runs = do.call(rbind, res), disagree = disagree, listing_md5 = listing_md5, n_s = sum(in_s))
}
r4 <- if (fetch || all(file.exists(file.path(listing_dir, paste0(xw$subid, ".json.gz"))))) rule4() else NULL

# ---- rule 5: CMIP5 gridded in the Fraser ---------------------------------------------------------
stamp("rule 5: the Fraser's polygons")
ws <- wet_ws_fetch(conn, "100")
irr <- wet_upstream_irregular(conn, "100")
e <- DBI::dbGetQuery(conn, "
  SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT ST_Extent(geom) e FROM whse_basemapping.fwa_watersheds_poly WHERE wscode_ltree <@ '100'::ltree) x")
ext <- terra::project(terra::ext(unlist(e)[c("xmin", "xmax", "ymin", "ymax")]), "EPSG:3005", "EPSG:4326")
bbox <- c(ext$xmin, ext$ymin, ext$xmax, ext$ymax) + c(-1, -1, 1, 1) * 0.0625
lut <- function(lfid) {
  DBI::dbGetQuery(conn, sprintf("
    SELECT linear_feature_id::double precision AS linear_feature_id, watershed_feature_id
    FROM whse_basemapping.fwa_streams_watersheds_lut WHERE linear_feature_id IN (%s)
    ORDER BY linear_feature_id", paste(sprintf("%.0f", lfid), collapse = ", ")))
}
sites <- utils::read.csv(file.path("scripts", "channel_scale_sites.csv"), colClasses = "character")
sites <- sites[match(parity_sites, sites$site_id), ]
stopifnot(!anyNA(sites$site_id))
targets <- lut(c(as.numeric(fr$linear_feature_id), as.numeric(sites$linear_feature_id)))
fr$watershed_feature_id <- targets$watershed_feature_id[match(fr$linear_feature_id, targets$linear_feature_id)]
sites$watershed_feature_id <- targets$watershed_feature_id[match(as.numeric(sites$linear_feature_id),
                                                                 targets$linear_feature_id)]
stopifnot(!anyNA(fr$watershed_feature_id), !anyNA(sites$watershed_feature_id))
want_ws <- sort(unique(c(fr$watershed_feature_id, sites$watershed_feature_id)))

# fetches each year of a gridded run one at a time; wet_pcic_fetch() reports every request it
# makes (a retry or a refused one included) to the request log option, so each is logged with
# the status it got. A cached year makes no request and logs nothing.
fetch_run <- function(run, years) {
  for (v in vars) for (y in years) {
    what <- paste(run, v, y)
    old <- options(wet.pcic_request_log = function(url, status, bytes, secs) {
      fetch_log(f_log, "services", what, 1L, status, bytes, secs, sub("\\?.*$", "", basename(url)))
    })
    wet_pcic_fetch(v, bbox, sprintf("%d-01-01", y), sprintf("%d-12-31", y), run = run, dir = pcic_dir)
    options(old)
  }
}
run_files <- function(run, years) {
  unlist(lapply(vars, function(v) vapply(years, function(y) {
    ix <- wet_pcic_index(bbox, sprintf("%d-01-01", y), sprintf("%d-12-31", y))
    file.path(pcic_dir, sprintf("%s_%s_t%d-%d_y%d-%d_x%d-%d.nc", run, v, ix$time[1], ix$time[2],
                                ix$lat[1], ix$lat[2], ix$lon[1], ix$lon[2]))
  }, "")))
}
# twelve monthly depths (mm) of RUNOFF + BASEFLOW accumulated to each target watershed
depths <- function(run) {
  stamp("rule 5: ", run)
  if (fetch) fetch_run(run, base_years)
  m <- wet_pcic_monthly("RUNOFF", bbox, base_years, run = run, dir = pcic_dir) +
    wet_pcic_monthly("BASEFLOW", bbox, base_years, run = run, dir = pcic_dir)
  cen <- wet_ws_sample(m, ws[, c("watershed_feature_id", "lon", "lat")], "centroid")
  out <- matrix(NA_real_, length(want_ws), 12, dimnames = list(want_ws, sprintf("m%02d", 1:12)))
  area <- NULL
  for (k in 1:12) {
    v <- data.frame(watershed_feature_id = cen$watershed_feature_id, value = cen[[sprintf("m%02d", k)]],
                    cover = cen$cover)
    acc <- wet_upstream_mean(ws, v, "total", irregular_pairs = irr)
    i <- match(want_ws, acc$watershed_feature_id)
    out[, k] <- acc$value[i]
    a <- acc$upstream_area_m2[i]
    if (is.null(area)) area <- a else stopifnot(identical(area, a))
  }
  list(mm = out, area_m2 = stats::setNames(area, want_ws),
       files_md5 = md5_text(sort(unname(tools::md5sum(run_files(run, base_years))))))
}
shares <- function(mm) mm / rowSums(mm)
ann_q <- function(d, ws_id) {
  i <- match(as.character(ws_id), rownames(d$mm))
  wet_mm_to_m3s(rowSums(d$mm[i, , drop = FALSE]), d$area_m2[i])
}
pnw <- depths(pnw_run)
q_par <- stats::setNames(ann_q(pnw, sites$watershed_feature_id), sites$site_id)
par_lines <- parity_lines(q_par, pilot)
fi <- match(as.character(fr$watershed_feature_id), rownames(pnw$mm))
fr$area_ratio <- pnw$area_m2[fi] / (fr$area_km2 * 1e6)
fr$q_pnw <- ann_q(pnw, fr$watershed_feature_id)
sh_pnw <- shares(pnw$mm[fi, , drop = FALSE])
fr$nse_pnw <- vapply(seq_len(nrow(fr)), function(k) wet_nse(fr_share[k, ], sh_pnw[k, ]), 1)

# glacier cover over each gauge's upstream area (the small-basin cache, deciding nothing)
f_gl <- list.files(file.path(data_root, "wb_small_basin"), "^glacier_ws_[0-9a-f]{10}\\.rds$", full.names = TRUE)
if (length(f_gl) != 1L) stop("expected one glacier cache under ", file.path(data_root, "wb_small_basin"), call. = FALSE)
gw <- readRDS(f_gl)
gw <- gw[gw$glacier_m2 > 0 & !is.na(gw$wscode) & !is.na(gw$localcode), ]
wsc <- ws[match(fr$watershed_feature_id, ws$watershed_feature_id), c("wscode", "localcode")]
fr$glacier <- vapply(seq_len(nrow(fr)), function(i) {
  sum(gw$glacier_m2[wet_fwa_upstream(wsc$wscode[i], wsc$localcode[i], gw$wscode, gw$localcode)])
}, 1) / pnw$area_m2[fi]

score_set <- function(rcp) {
  d <- lapply(names(cmip5), function(gm) depths(run5(gm, rcp)))
  names(d) <- names(cmip5)
  q <- sapply(d, function(x) ann_q(x, fr$watershed_feature_id))
  q <- matrix(q, nrow = nrow(fr), dimnames = list(NULL, names(cmip5)))
  if (anyNA(q)) stop("a CMIP5 run has no flow at a Fraser gauge", call. = FALSE)
  med_month <- t(vapply(seq_len(nrow(fr)), function(k) {
    apply(sapply(d, function(x) x$mm[as.character(fr$watershed_feature_id[k]), ]), 1, stats::median)
  }, numeric(12)))
  s <- data.frame(station_number = fr$station_number, q_med = apply(q, 1, stats::median))
  s$signed <- (s$q_med - fr$q_pnw) / fr$q_obs
  s$stat_ann <- abs(s$signed)
  sh <- med_month / rowSums(med_month)
  s$nse <- vapply(seq_len(nrow(fr)), function(k) wet_nse(fr_share[k, ], sh[k, ]), 1)
  s$d_nse <- s$nse - fr$nse_pnw
  per_gcm <- t(sapply(names(cmip5), function(gm) {
    shg <- shares(d[[gm]]$mm[fi, , drop = FALSE])
    c(stat_ann = stats::median(abs(q[, gm] - fr$q_pnw) / fr$q_obs),
      d_nse = stats::median(vapply(seq_len(nrow(fr)), function(k) wet_nse(fr_share[k, ], shg[k, ]), 1) -
                              fr$nse_pnw))
  }))
  list(s = s, per_gcm = per_gcm, md5 = vapply(d, `[[`, "", "files_md5"),
       pass = stats::median(s$stat_ann) <= r5_ann && stats::median(s$d_nse) >= -r5_nse)
}
r85_check <- function() {
  do.call(rbind, lapply(names(cmip5), function(gm) {
    if (fetch) {
      fetch_run(run5(gm, "rcp45"), r85_report_only)
      fetch_run(run5(gm, "rcp85"), c(r85_years, r85_report_only))
    }
    do.call(rbind, lapply(c(r85_years, r85_report_only), function(y) {
      do.call(rbind, lapply(vars, function(v) {
        f45 <- run_files(run5(gm, "rcp45"), y)[match(v, vars)]
        f85 <- run_files(run5(gm, "rcp85"), y)[match(v, vars)]
        sf <- vapply(c(f45, f85), function(f) {
          nc <- ncdf4::nc_open(f)
          on.exit(ncdf4::nc_close(nc))
          abs(ncdf4::ncatt_get(nc, v, "scale_factor")$value)
        }, 1)
        dv <- abs(terra::values(terra::rast(f85)) - terra::values(terra::rast(f45)))
        data.frame(gcm = gm, year = y, variable = v, max_diff = max(dv, na.rm = TRUE), step = max(sf))
      }))
    }))
  }))
}
r5 <- NULL
if (fetch) {
  r5 <- list(r45 = score_set("rcp45"), r85chk = r85_check())
  chk <- r5$r85chk[r5$r85chk$year %in% r85_years, ]
  r5$r85_scored <- any(chk$max_diff > chk$step)
  if (r5$r85_scored) r5$r85 <- score_set("rcp85")
  r5$pass <- r5$r45$pass && (!r5$r85_scored || r5$r85$pass)
  keep <- fr$glacier <= glacier_cut
  r5$no_glacier <- c(stat_ann = stats::median(r5$r45$s$stat_ann[keep]), d_nse = stats::median(r5$r45$s$d_nse[keep]),
                     n = sum(keep))
}
DBI::dbDisconnect(conn)

# ---- report ---------------------------------------------------------------------------------------
log <- read_fetch_log(f_log)
log_line <- if (is.null(log)) "requests logged: none" else {
  sprintf("requests logged: %d, %.1f MiB, %.1f minutes (<data root>/logs/169/scenario_basis_fetch.tsv)", nrow(log),
          sum(as.numeric(log$bytes)) / 2^20, sum(as.numeric(log$secs)) / 60)
}
fmt <- function(x, d = 3) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
pilot_dom <- grep("^Fraser ", pilot[grep("^## Domains", pilot):length(pilot)], value = TRUE)[1]
pf <- strsplit(trimws(pilot_dom), " +")[[1]]   # Fraser, gauges, with outlet, GCMs, ..., |dQ|, dNSE, rule 2
rep <- c(
  sprintf("# What scenarios can be built on (#169, #4), HYDAT %s", release),
  "",
  "## Provenance",
  sprintf("rules registered: %s (%s)", reg$sha, utc_txt(reg$utc)),
  sprintf("first fetch: %s", if (is.null(first_fetch)) "none" else utc_txt(first_fetch)),
  sprintf("script commit: %s", wet_commit),
  routed_report_line(fwapg_commit),
  paste("table:", routed_fp),
  sprintf("bundle: %s md5 %s", f_bundle, unname(tools::md5sum(f_bundle))),
  sprintf("pilot report: %s md5 %s", f_pilot, unname(tools::md5sum(f_pilot))),
  sprintf("PNWNAmet gridded files (%s, %d one-year files): md5 of md5s %s", pnw_run,
          length(base_years) * length(vars), pnw$files_md5),
  log_line,
  sprintf("PCIC access: %s", if (fetch) "WET_SCENARIO_FETCH=1, requests made one at a time" else access),
  "",
  "## Rule 4: what each CMIP6 run lacks against the stored crosswalk",
  sprintf("crosswalk outlets: %d; S (flag is not no_series): %d", nrow(xw), sum(xw$flag_txt != "no_series"))
)
if (is.null(r4)) {
  rep <- c(rep, sprintf("not run: %s; the listings are not cached (<data root>/scenario_basis/listing)", access))
} else {
  rep <- c(rep,
    sprintf("listings: md5 of md5s %s", r4$listing_md5),
    sprintf("outlets where PNWNAmet's listing and S disagree: %d", nrow(r4$disagree)),
    if (nrow(r4$disagree)) sprintf("  %d %s %s", r4$disagree$subid, r4$disagree$domain, r4$disagree$flag_txt),
    "model          scenario             A     B  fails day  no series  >100  A placed  A Fraser  A Coast  A Columbia  A Peace  whole in",
    sprintf("%-14s %-18s %5d %5d %10d %10d %5s %9d %9d %8d %11d %8d  %s", r4$runs$model, r4$runs$scenario,
            r4$runs$a, r4$runs$b, r4$runs$fails_day, r4$runs$no_series, ifelse(r4$runs$stops_job, "yes", "no"),
            r4$runs$a_placed, r4$runs$a_fraser, r4$runs$a_coast, r4$runs$a_columbia, r4$runs$a_peace,
            r4$runs$whole_in),
    "A by flag and verdict:",
    sprintf("  %-14s %-18s %s; %s", r4$runs$model, r4$runs$scenario,
            ifelse(nzchar(r4$runs$a_flags), r4$runs$a_flags, "none"), r4$runs$verdict))
}
rep <- c(rep,
  "",
  "## Rule 5: CMIP5 gridded in the Fraser",
  sprintf("gauges: %d Fraser gauges with an outlet; the pilot's Domains line: %s", nrow(fr), pilot_dom),
  "parity, PNWNAmet's accumulated annual flow (twelve months' total, 365 days) against the pilot's wet acc:",
  par_lines,
  "Rule 5 is the pilot's rule 2 in its thresholds, its median over gauges and its gauges, and differs in three ways:",
  "  its year is the twelve months' total, where the pilot takes the plain mean of twelve monthly mean flows;",
  "  its PNWNAmet side is the gridded run accumulated unrouted, where the pilot's is the routed outlet series;",
  "  its two sides are different models (VICGL against VICGL-RGM), so a fail can be model structure, not forcing.",
  sprintf("the pilot's rule 2 in the Fraser, beside it (%s CMIP6 GCMs against routed PNWNAmet): |dQ|/Qobs %s, dNSE %s, %s",
          pf[4], pf[8], pf[9], pf[10]),
  "",
  "PNWNAmet at each gauge (accumulated area over the bundle's area; glacier share of the accumulated area):",
  "station    area ratio  glacier   q_obs m3/s   q_pnw m3/s   share NSE",
  sprintf("%-10s %10s %8s %12s %12s %11s", fr$station_number, fmt(fr$area_ratio), fmt(fr$glacier),
          fmt(fr$q_obs, 2), fmt(fr$q_pnw, 2), fmt(fr$nse_pnw)),
  sprintf("median: area ratio %s, PNWNAmet share NSE %s", fmt(stats::median(fr$area_ratio)),
          fmt(stats::median(fr$nse_pnw))),
  ""
)
if (is.null(r5)) {
  rep <- c(rep, sprintf("CMIP5 score: not run: %s. No CMIP5 file was asked for.", access))
} else {
  rep <- c(rep,
    sprintf("RCP 4.5, the six GCMs: median |dQ|/Qobs %s, median dNSE %s: %s", fmt(stats::median(r5$r45$s$stat_ann)),
            fmt(stats::median(r5$r45$s$d_nse)), if (r5$r45$pass) "pass" else "fail"),
    "each GCM alone (deciding nothing): |dQ|/Qobs, dNSE",
    sprintf("  %-12s %s %s", rownames(r5$r45$per_gcm), fmt(r5$r45$per_gcm[, "stat_ann"]), fmt(r5$r45$per_gcm[, "d_nse"])),
    sprintf("median signed annual difference (deciding nothing): %s", fmt(stats::median(r5$r45$s$signed))),
    sprintf("without the %d gauges more than 5 %% glacier (deciding nothing): |dQ|/Qobs %s, dNSE %s",
            nrow(fr) - r5$no_glacier[["n"]], fmt(r5$no_glacier[["stat_ann"]]), fmt(r5$no_glacier[["d_nse"]])),
    "RCP 8.5 against RCP 4.5, largest daily cell difference (mm) and the larger scale_factor:",
    sprintf("  %-12s %d %-8s %10s %10s%s", r5$r85chk$gcm, r5$r85chk$year, r5$r85chk$variable, fmt(r5$r85chk$max_diff, 6),
            fmt(r5$r85chk$step, 6), ifelse(r5$r85chk$year == r85_report_only, "  (reported only)", "")),
    if (r5$r85_scored) sprintf("RCP 8.5 scored: median |dQ|/Qobs %s, dNSE %s: %s", fmt(stats::median(r5$r85$s$stat_ann)),
                               fmt(stats::median(r5$r85$s$d_nse)), if (r5$r85$pass) "pass" else "fail")
    else "RCP 8.5 not scored: its 1981, 1993 and 2005 equal RCP 4.5's within the packing step",
    sprintf("verdict: %s", if (r5$pass) "the Fraser builds on CMIP5 gridded"
            else "DECISION TO USER: neither generation meets rule 2 in the Fraser"))
}
dir.create(dirname(f_report), recursive = TRUE, showWarnings = FALSE)
writeLines(rep, f_report)
stamp("wrote ", f_report)
