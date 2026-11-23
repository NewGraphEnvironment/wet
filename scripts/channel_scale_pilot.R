# PCIC's channel-scale output on the FWA (#9, #168): whether the routed CMIP6
# runs PCIC serves can carry wet's scenarios (#4) and coverage (#5).
#
#   WET_FWAPG_COMMIT=<sha> WET_DATA_ROOT=<data dir> Rscript scripts/channel_scale_pilot.R
#
# PCIC's channel-scale portal (services.pacificclimate.org/chyp) reads
# collections keyed on PCIC's sub-basin outlets (subid); its hydromosaic API
# serves daily streamflow, water temperature and oxygen saturation at the same
# outlets, for PNWNAmet (observed weather, 1950-2012) and 9 CMIP6 GCMs under
# SSP2-4.5 and SSP5-8.5 (1950-2100). fwapg's crosswalk (extras/pcic_crosswalk)
# places those outlets on the FWA, and wet publishes its PNWNAmet run as
# routed PCIC. This script reads PCIC's outlet series directly and compares
# them with what wet publishes, with HYDAT and with wet's own accumulation of
# PCIC's gridded runoff, under the rules registered below.
#
# Inputs, each held to the record it must equal:
#   - fwapg's pcic schema (crosswalk, segment weights, the routed run), its
#     run fingerprint refused unless it equals pcic.runs's row, and the fwapg
#     commit (WET_FWAPG_COMMIT) the tracked routed report's;
#   - the scored gauges, observed months and routed months of the
#     segment-discharge article's bundle (inst/vignette-data/monthly_values.rds);
#   - routed PCIC and the balance as published (the live manifest), the routed
#     months refused unless they equal fwapg's table;
#   - hydromosaic's series, fetched once into <data root>/channel_scale/raw/
#     (bulk NetCDF; the listing of each outlet beside them), each refused unless
#     its days are its listing's;
#   - HYDAT (WET_HYDAT_RELEASE, default the shipped release) for the gauged
#     sites; PCIC's gridded PNWNAmet runoff, cached under <data root>/pcic/;
#   - water-temp-bc's daily water temperature at the gauged sites.
# Every fetch is logged to <data root>/logs/168/channel_scale_fetch.tsv
# (requests, bytes, seconds), which the report reads, so a rerun from the cache
# prints the same report.
#
# Report: data/checks/channel_scale_pilot_<release>.txt (tracked). Findings:
# research/pcic_channel_scale.md. PCIC is a reference here (CLAUDE.md, "Own
# estimates first"). Connection from WET_PG*.
#
# ---- rules registered before any flow value was read (#168) ------------------------------------
# Population. The scored gauges are the segment-discharge article's: its
# bundle's gauges where routed PCIC has flow and carries at least
# routed_far_low (0.2) of the gauge's observed annual flow. A gauge's outlet is
# the sub-basin its segment belongs to (pcic.segment_weights.subid) when that
# outlet is placed (flag NULL) on the gauge's own segment; rules 1 and 2 are
# scored at the gauges that have one. A domain is PCIC's: an outlet's subid
# over 1e6 is 1-4 Fraser, 5-6 Columbia, 200 or more Peace, any other the coast.
#
# Sites. Six worked cases in the Fraser: 08KC001 Salmon River near Prince
# George (mid-size tributary), 08KH001 Quesnel River at Likely (lake outlet),
# 08MF005 Fraser River at Hope (large main stem; regulated since 1952, a column,
# not a filter), 08MG005 Lillooet River near Pemberton (glacier-fed), and two
# chosen by rule:
#   - the headwater: among FWA main-flow segments (edge type 1000, 1050, 1200,
#     1250 or 1450) on their watershed's own line, upstream of 08KC001's
#     fundamental watershed, whose segment weights give a share under 1 and on
#     which no outlet is placed, the one with the largest upstream area (wet's
#     accumulated area, not fwapg's stored one) under 10 km2; ties by
#     linear_feature_id. (The plan said the smallest-area segment, which
#     would be a catchment of a few hectares.)
#   - the confluence: among fwapg's junctions (sql/qa.sql: a blue line whose
#     mouth is within 1 mm of the start of a segment on the line it joins, from
#     fwapg.blk_paths) in the Fraser, where the joining line's lowest segment
#     carries more than 1 m3/s in June in the routed run and June's step lands
#     on the segment above the junction (upper minus the next segment up more
#     than half the joining line's flow), the one whose upper segment is
#     nearest, in BC Albers, to a scored gauge with an outlet; ties by
#     linear_feature_id. The site is the upper segment.
# Gauged sites take their segment from data/wb/stations_<release>.rds, and a
# station that file lacks (08MF005, regulated) from wet_station_snap(); full
# years are the years 1981-2010 whose twelve months each have 20 days of flow.
#
# Rule 1, the crosswalk reproduces PCIC. At a gauge's outlet, PCIC's raw
# PNWNAmet series over 1981-2010 (each month the mean of its days, the year
# the plain mean of the twelve months, as fwapg and the published month 0 take
# them) against routed PCIC as published on the segment: passes when the
# annual flow is within 1 % and each month within max(2 %, 1e-4 m3/s). The
# annual ratio is reported, and one past 1e-4 relative is marked "not exact".
# A failure is typed, in this order: the networks disagree (the placed outlets
# above the outlet on the FWA tree are not those in its PCIC subtree, as
# scripts/gauge_monthly_compare.R tests); a lake outlet; the series differs
# between services.pacificclimate.org and beehive.pacificclimate.org (fetched
# again from beehive); otherwise unresolved with the networks agreeing (a
# series revised since fwapg's build cannot be told from a crosswalk fault
# without fwapg's own NetCDF, which this machine lacks). At an interior site the
# published value is rebuilt from raw series, sum raw(upstream_subids) +
# (raw(subid) - sum raw(the placed outlets first reached in its PCIC subtree))
# x share, clamped at zero per month: this checks the arithmetic only, and the
# site's routed flow is set beside wet's accumulation of the gridded runoff.
#
# Rule 2, the CMIP6 runs are usable. From the "historical, ssp245" series
# (after checking at the six sites that "historical, ssp585" equals it before
# 2015, reported either way): at each gauge with an outlet,
# |median over the 9 GCMs of their 1981-2010 annual flow - PNWNAmet's| /
# observed annual flow <= 0.05, and the share NSE (wet:::wet_nse() on the
# twelve monthly shares of the year against the gauge's) of the 9-GCM median
# month no more than 0.05 below PNWNAmet's.
#
# By domain (decision 5): rule 1 passes when at least 90 % of the domain's
# gauges with an outlet pass it; rule 2 when the median over those gauges of
# each statistic meets it. Failing gauges are listed with their type.
#
# Rule 3, the verdict for move 7, by domain. Where hydromosaic lists CMIP6
# streamflow at the domain's outlets and rules 1 and 2 pass: CMIP6 through
# fwapg's crosswalk. Otherwise CMIP5 gridded where PCIC's gridded runs cover the
# domain (the Fraser, Peace and Columbia), and nothing on the coast. Move 7's
# first check is stated with it: whether each CMIP6 run's outlets with series
# are PNWNAmet's, which fwapg's crosswalk needs. Change signals (2041-2070 and
# 2070-2099 against 1981-2010) and water temperature are reported and decide
# nothing.
# ---- end of registered rules --------------------------------------------------------------------

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")      # wb_release(), wb_hydat(), wb_stations_path()
source("scripts/pcic_routed_lib.R") # routed_*

f_self <- "scripts/channel_scale_pilot.R"
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
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
raw_dir <- file.path(data_root, "channel_scale", "raw")
log_dir <- file.path(data_root, "logs", "168")
f_fetch <- file.path(log_dir, "channel_scale_fetch.tsv")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
f_report <- file.path("data", "checks", sprintf("channel_scale_pilot_%s.txt", release))
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)

# ---- the rule block as run, and the commit that registered it ------------------------------------
rule_block <- function(lines) {
  a <- grep("^# ---- rules registered before any flow value was read", lines)
  b <- grep("^# ---- end of registered rules", lines)
  stopifnot(length(a) == 1L, length(b) == 1L, b > a)
  lines[a:b]
}
md5_text <- function(x) {
  f <- tempfile()
  on.exit(unlink(f))
  writeLines(x, f)
  unname(tools::md5sum(f))
}
rule_md5 <- md5_text(rule_block(readLines(f_self)))
hist <- git("log", "--reverse", "--format=%H %ct", "--", f_self)
reg <- NULL
for (h in hist) {
  sha <- strsplit(h, " ")[[1]]
  txt <- git("show", paste0(sha[1], ":", f_self))
  if (identical(md5_text(rule_block(txt)), rule_md5)) {
    reg <- list(sha = substr(sha[1], 1, 7), utc = as.POSIXct(as.numeric(sha[2]), origin = "1970-01-01", tz = "UTC"))
    break
  }
}
if (is.null(reg)) stop("the rule block as run is in no commit of ", f_self, call. = FALSE)
utc_txt <- function(x) format(x, "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")

# ---- constants ----------------------------------------------------------------------------------
hosts <- c(services = "https://services.pacificclimate.org", beehive = "https://beehive.pacificclimate.org")
gcms <- c("CNRM-ESM2-1", "FGOALS-g3", "IPSL-CM6A-LR", "MIROC-ES2L", "MPI-ESM1-2-HR", "MRI-ESM2-0",
          "NorESM2-LM", "TaiESM1", "UKESM1-0-LL")
ssp245 <- "historical, ssp245"
ssp585 <- "historical, ssp585"
base_years <- 1981:2010
windows <- list(`1981-2010` = 1981:2010, `2041-2070` = 2041:2070, `2070-2099` = 2070:2099)
main_flow <- c(1000L, 1050L, 1200L, 1250L, 1450L)
batch_max <- 500L
pass1 <- 0.90       # decision 5: the share of a domain's gauges that must pass rule 1
r1_ann <- 0.01
r1_mon <- 0.02
r1_floor <- 1e-4
r1_exact <- 1e-4
r2_ann <- 0.05
r2_nse <- 0.05
domain_of <- function(subid) {
  p <- subid %/% 1e6
  ifelse(p >= 200, "Peace", ifelse(p <= 4, "Fraser", ifelse(p <= 6, "Columbia", "Coast")))
}
domains <- c("Fraser", "Coast", "Columbia", "Peace")
month_days <- wet_month_days()

# ---- database ------------------------------------------------------------------------------------
conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"),
                       connect_timeout = 10)
routed_fp <- routed_fingerprint(conn)
f_routed_report <- wb_report("pcic_routed_compare", release)
rr <- readLines(f_routed_report)
if (!routed_report_line(fwapg_commit) %in% rr || !paste("table:", routed_fp) %in% rr) {
  stop("the routed table or WET_FWAPG_COMMIT is not the tracked routed report's (", f_routed_report, ")",
       call. = FALSE)
}
xw <- DBI::dbGetQuery(conn, "
  SELECT subid, dowsubid, fwa_parent_subid, islake, linear_feature_id::double precision AS linear_feature_id,
         subltree(wscode_ltree, 0, 1)::text AS root, distance_to_stream, candidate_rank, flag
  FROM pcic.fwa_crosswalk ORDER BY subid")
stopifnot(!anyDuplicated(xw$subid), all(xw$subid %/% 1e6 %in% c(1:9, 11, 12, 206, 207, 210)))
xw$domain <- domain_of(xw$subid)
root_dom <- c(`100` = "Fraser", `300` = "Columbia", `200` = "Peace")
pl <- is.na(xw$flag)
want_dom <- ifelse(xw$root[pl] %in% names(root_dom), root_dom[xw$root[pl]], "Coast")
if (any(want_dom != xw$domain[pl])) stop("a placed outlet's FWA basin is not its subid's domain", call. = FALSE)
placed <- xw$subid[pl]
kids_pcic <- split(xw$subid, xw$dowsubid)
kids_fwa <- split(xw$subid[pl & !is.na(xw$fwa_parent_subid)], xw$fwa_parent_subid[pl & !is.na(xw$fwa_parent_subid)])
below <- function(kids, root) {
  out <- integer()
  front <- root
  while (length(front)) {
    nxt <- unlist(kids[as.character(front)], use.names = FALSE)
    nxt <- nxt[!nxt %in% out]
    out <- c(out, nxt)
    front <- nxt
  }
  out
}
agree_at <- function(s) setequal(intersect(below(kids_pcic, s), placed), below(kids_fwa, s))
# the placed outlets first reached in an outlet's PCIC subtree, through unplaced ones
frontier <- function(s) {
  out <- integer()
  front <- s
  while (length(front)) {
    nxt <- unlist(kids_pcic[as.character(front)], use.names = FALSE)
    out <- c(out, nxt[nxt %in% placed])
    front <- nxt[!nxt %in% placed]
  }
  sort(out)
}

# ---- the scored gauges ---------------------------------------------------------------------------
bundle <- readRDS(file.path("inst", "vignette-data", "monthly_values.rds"))
gb <- bundle$gauges
g <- gb[gb$month == 0, c("station_number", "station_name", "linear_feature_id", "area_km2", "lake",
                          "watershed_group_code", "obs_mm", "routed_mm")]
g$scored <- !is.na(g$routed_mm) & g$routed_mm / g$obs_mm >= routed_far_low
g <- g[g$scored, ]
g <- g[order(g$station_number), ]
rownames(g) <- NULL
w_g <- routed_weights(conn, g$linear_feature_id)
wi <- match(g$linear_feature_id, w_g$linear_feature_id)
own_seg <- xw$linear_feature_id[match(w_g$subid[wi], xw$subid)]
g$outlet <- ifelse(!is.na(wi) & !is.na(own_seg) & own_seg == g$linear_feature_id & w_g$subid[wi] %in% placed,
                   w_g$subid[wi], NA_integer_)
stopifnot(all(w_g$share[wi[!is.na(g$outlet)]] == 1))
g$domain <- ifelse(is.na(g$outlet), NA, domain_of(g$outlet))
g$agree <- NA
for (k in which(!is.na(g$outlet))) g$agree[k] <- agree_at(g$outlet[k])
g$islake <- xw$islake[match(g$outlet, xw$subid)]
# observed annual flow (m3/s) and monthly shares, from the bundle's mm
obs_m <- reshape(gb[gb$month > 0, c("station_number", "month", "obs_mm")], idvar = "station_number",
                 timevar = "month", direction = "wide")
obs_m <- as.matrix(obs_m[match(g$station_number, obs_m$station_number), paste0("obs_mm.", 1:12)])
g_share <- obs_m / rowSums(obs_m)
g$q_obs <- g$obs_mm / 1000 * g$area_km2 * 1e6 / (365.25 * 86400)
stamp(nrow(g), " scored gauges, ", sum(!is.na(g$outlet)), " with an outlet")

# ---- hydromosaic: listings and bulk series --------------------------------------------------------
h_curl <- function(url, file, body = NULL, timeout = 1800) {
  h <- curl::new_handle(timeout = timeout, connecttimeout = 60, useragent = "wet-channel-scale-pilot",
                        followlocation = TRUE)
  if (!is.null(body)) {
    curl::handle_setheaders(h, `Content-Type` = "application/json")
    curl::handle_setopt(h, customrequest = "POST", postfields = body)
  }
  t0 <- Sys.time()
  r <- tryCatch(curl::curl_fetch_disk(url, file, handle = h), error = function(e) NULL)
  list(code = if (is.null(r)) 0L else r$status_code, secs = as.numeric(Sys.time() - t0, units = "secs"),
       bytes = if (file.exists(file)) file.size(file) else 0)
}
fetch_log <- function(host, what, n, code, bytes, secs, file) {
  row <- data.frame(utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), host = host, what = what,
                    n = n, code = code, bytes = bytes, secs = round(secs, 2), file = file)
  utils::write.table(row, f_fetch, sep = "\t", quote = FALSE, row.names = FALSE, col.names = !file.exists(f_fetch),
                     append = file.exists(f_fetch))
}
# each outlet's listing: the series hydromosaic holds there
listing <- function(subid, host = "services") {
  f <- file.path(raw_dir, host, "listing", paste0(subid, ".json"))
  if (!file.exists(f)) {
    dir.create(dirname(f), recursive = TRUE, showWarnings = FALSE)
    tmp <- paste0(f, ".tmp")
    r <- h_curl(sprintf("%s/hydromosaic/outlets/%d/timeseries", hosts[[host]], subid), tmp, timeout = 120)
    fetch_log(host, "listing", 1L, r$code, r$bytes, r$secs, basename(f))
    if (r$code == 404L) {
      writeLines("[]", f)
      unlink(tmp)
    } else {
      if (r$code != 200L) stop("listing of outlet ", subid, " answered ", r$code, call. = FALSE)
      file.rename(tmp, f)
    }
  }
  x <- jsonlite::fromJSON(f)
  if (!length(x)) return(data.frame(model = character(), scenario = character(), variable = character(),
                                    start_time = character(), end_time = character(), num_times = integer()))
  x[c("model", "scenario", "variable", "start_time", "end_time", "num_times")]
}
batch_name <- function(ids) {
  paste0("b", ids[1] %/% 1e6, "_", substr(md5_text(paste(sort(ids), collapse = ",")), 1, 12))
}
nc_read <- function(f, variable) {
  nc <- ncdf4::nc_open(f)
  on.exit(ncdf4::nc_close(nc))
  ids <- as.integer(trimws(ncdf4::ncvar_get(nc, "basin_name")))
  tv <- ncdf4::ncvar_get(nc, "time")
  tu <- ncdf4::ncatt_get(nc, "time", "units")$value
  origin <- as.Date(sub("^days since ([0-9-]+).*$", "\\1", tu))
  stopifnot(grepl("^days since [0-9]{4}-[0-9]{2}-[0-9]{2}", tu))
  cal <- ncdf4::ncatt_get(nc, "time", "calendar")
  if (cal$hasatt && !tolower(cal$value) %in% c("standard", "gregorian", "proleptic_gregorian")) {
    stop(f, " is on a ", cal$value, " calendar", call. = FALSE)
  }
  v <- ncdf4::ncvar_get(nc, variable, collapse_degen = FALSE)
  dn <- vapply(nc$var[[variable]]$dim, function(d) d$len, 1)
  if (length(dn) != 2) stop(f, ": ", variable, " is not two-dimensional", call. = FALSE)
  if (dn[1] == length(ids) && dn[2] == length(tv)) v <- t(v) else stopifnot(dn[1] == length(tv), dn[2] == length(ids))
  list(ids = ids, dates = origin + tv, v = matrix(v, nrow = length(tv)))
}
# one run's series at `ids`, by domain batches of at most 500, halved on a
# mixed-domain 422 (as fwapg's job does); an outlet with no series alone is
# returned missing. Each NetCDF is kept; a kept one is reused.
bulk <- function(ids, model, scenario, variable, host = "services") {
  dir <- file.path(raw_dir, host, gsub("[^A-Za-z0-9]+", "_", paste(model, scenario, variable)))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ids <- sort(unique(ids))
  out <- list()
  missing <- integer()
  get_batch <- function(b) {
    nm <- batch_name(b)
    f <- file.path(dir, paste0(nm, ".nc"))
    fm <- file.path(dir, paste0(nm, ".missing"))
    if (file.exists(fm)) {
      missing <<- c(missing, b)
      return(invisible())
    }
    if (!file.exists(f)) {
      body <- jsonlite::toJSON(list(subids = as.character(b), model = model, scenario = scenario,
                                    variable = variable, format = "netcdf"), auto_unbox = TRUE)
      # a one-outlet request still sends an array
      if (length(b) == 1L) body <- sub('"subids":"([0-9]+)"', '"subids":["\\1"]', body)
      tmp <- paste0(f, ".tmp")
      code <- 0L
      for (try in 1:3) {
        r <- h_curl(paste0(hosts[[host]], "/hydromosaic/bulk-downloads"), tmp, body = as.character(body))
        fetch_log(host, paste(model, scenario, variable), length(b), r$code, r$bytes, r$secs, basename(f))
        code <- r$code
        if (code == 422L) break
        if (code == 200L && !inherits(try(nc_read(tmp, variable), silent = TRUE), "try-error")) break
        code <- -1L
        Sys.sleep(try * 30)
      }
      if (code == 200L) {
        file.rename(tmp, f)
      } else {
        unlink(tmp)
        if (code == 422L && length(b) == 1L) {
          writeLines("", fm)
          missing <<- c(missing, b)
          return(invisible())
        }
        if (code != 422L && length(b) <= 50L) stop("bulk download failed for ", nm, call. = FALSE)
        h <- length(b) %/% 2
        get_batch(b[seq_len(h)])
        get_batch(b[-seq_len(h)])
        return(invisible())
      }
    }
    x <- nc_read(f, variable)
    if (!setequal(x$ids, b)) stop(f, " holds other outlets than its batch", call. = FALSE)
    out[[length(out) + 1]] <<- x
  }
  for (p in split(ids, ids %/% 1e6)) {
    for (b in split(p, ceiling(seq_along(p) / batch_max))) get_batch(b)
  }
  list(series = out, missing = sort(missing), files = list.files(dir, pattern = "\\.nc$", full.names = TRUE))
}
# each series' days checked against its outlet's listing, day 1 dropped; the
# monthly climatology of `years` (each month the mean of its days) per window
check_days <- function(x, model, scenario, variable, host = "services") {
  for (j in seq_along(x$ids)) {
    li <- listing(x$ids[j], host)
    li <- li[li$model == model & li$scenario == scenario & li$variable == variable, ]
    if (nrow(li) != 1L || li$num_times != length(x$dates) || as.Date(li$start_time) != min(x$dates) ||
          as.Date(li$end_time) != max(x$dates)) {
      stop("outlet ", x$ids[j], "'s ", model, " ", scenario, " ", variable, " series is not its listing's",
           call. = FALSE)
    }
  }
  if (any(diff(x$dates) != 1)) stop("a ", model, " ", scenario, " series leaves a gap", call. = FALSE)
  keep <- x$dates > as.Date("1950-01-01")
  x$dates <- x$dates[keep]
  x$v <- x$v[keep, , drop = FALSE]
  x
}
clim <- function(x, years) {
  yr <- as.integer(format(x$dates, "%Y"))
  mo <- as.integer(format(x$dates, "%m"))
  i <- yr %in% years
  if (!all(years %in% yr) || anyNA(x$v[i, ])) stop("a series lacks days of ", min(years), "-", max(years), call. = FALSE)
  m <- rowsum(x$v[i, , drop = FALSE], mo[i]) / as.vector(table(mo[i]))
  dimnames(m) <- list(1:12, x$ids)
  m
}
# a run's monthly climatologies per window, outlets in columns
run_clim <- function(ids, model, scenario, variable = "streamflow", wins = windows["1981-2010"], host = "services",
                     keep_daily = NULL) {
  b <- bulk(ids, model, scenario, variable, host)
  res <- lapply(wins, function(w) NULL)
  daily <- list()
  for (x in b$series) {
    x <- check_days(x, model, scenario, variable, host)
    for (w in names(wins)) res[[w]] <- cbind(res[[w]], clim(x, wins[[w]]))
    k <- x$ids %in% keep_daily
    if (any(k)) daily[[length(daily) + 1]] <- list(ids = x$ids[k], dates = x$dates, v = x$v[, k, drop = FALSE])
  }
  for (w in names(wins)) if (!is.null(res[[w]])) res[[w]] <- res[[w]][, order(as.integer(colnames(res[[w]]))), drop = FALSE]
  list(clim = res, missing = b$missing, daily = daily, files = b$files)
}
ann <- function(m) colMeans(m)                        # the plain mean of twelve monthly means
shares <- function(m) {
  v <- m * month_days
  sweep(v, 2, colSums(v), "/")
}

# ---- the portal's bundle: does it name hydromosaic? ----------------------------------------------
portal_dir <- file.path(raw_dir, "portal")
dir.create(portal_dir, showWarnings = FALSE)
f_idx <- file.path(portal_dir, "index.html")
if (!file.exists(f_idx)) {
  r <- h_curl(paste0(hosts[["services"]], "/chyp/"), f_idx, timeout = 120)
  fetch_log("services", "portal", 1L, r$code, r$bytes, r$secs, "index.html")
  stopifnot(r$code == 200L)
}
js <- regmatches(readLines(f_idx, warn = FALSE), regexpr("/chyp/assets/index-[A-Za-z0-9_-]+\\.js", readLines(f_idx, warn = FALSE)))
stopifnot(length(js) == 1L)
f_js <- file.path(portal_dir, basename(js))
if (!file.exists(f_js)) {
  r <- h_curl(paste0(hosts[["services"]], js), f_js, timeout = 120)
  fetch_log("services", "portal", 1L, r$code, r$bytes, r$secs, basename(js))
  stopifnot(r$code == 200L)
}
js_txt <- paste(readLines(f_js, warn = FALSE), collapse = "\n")
portal_hits <- vapply(c("hydromosaic", "streamflow", "water_temp", "bulk-downloads", ".csv", "bbox-server"),
                      function(s) lengths(regmatches(js_txt, gregexpr(s, js_txt, fixed = TRUE))), 1L)

# ---- sites ---------------------------------------------------------------------------------------
sites_csv <- file.path("scripts", "channel_scale_sites.csv")
sites <- utils::read.csv(sites_csv, colClasses = "character", na.strings = "")
stopifnot(!anyDuplicated(sites$site_id),
          identical(sort(sites$type), sort(c("headwater", "tributary", "lake_outlet", "confluence", "mainstem",
                                              "glacier"))))
hydat <- wb_hydat(release)
st_all <- readRDS(wb_stations_path(release))$stations
gauged <- sites$station[!is.na(sites$station)]
hcon <- wet:::wet_hydat_connect(hydat)
st_meta <- DBI::dbGetQuery(hcon, sprintf("
  SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.LONGITUDE lon, s.LATITUDE lat,
         s.DRAINAGE_AREA_GROSS drainage_area_gross_km2, r.REGULATED regulated
  FROM STATIONS s LEFT JOIN STN_REGULATION r USING (STATION_NUMBER) WHERE s.STATION_NUMBER IN (%s)
  ORDER BY s.STATION_NUMBER", paste0("'", gauged, "'", collapse = ", ")))
cy <- wet:::wet_complete_years(hcon, gauged, base_years, 20L)
DBI::dbDisconnect(hcon)
stopifnot(nrow(st_meta) == length(gauged))
snap_new <- st_meta[!st_meta$station_number %in% st_all$station_number, ]
snapped <- st_all[st_all$station_number %in% gauged, c("station_number", "linear_feature_id")]
if (nrow(snap_new)) {
  sn <- wet_station_snap(conn, snap_new)
  snapped <- rbind(snapped, sn[c("station_number", "linear_feature_id")])
}
stopifnot(setequal(snapped$station_number, gauged))
st_years <- split(cy$year, cy$station_number)[gauged]
st_sel <- st_meta[c("station_number", "station_name", "lon", "lat", "drainage_area_gross_km2")]
attr(st_sel, "years") <- st_years
st_monthly <- wet_station_monthly(st_sel, hydat)

# wet's accumulation of PCIC's gridded PNWNAmet runoff over the Fraser (as
# scripts/mad_basin.R's live build: centroid, total denominator, accumulated area)
stamp("wet's accumulation over the Fraser")
ws <- wet_ws_fetch(conn, "100")
irr <- wet_upstream_irregular(conn, "100")
e <- DBI::dbGetQuery(conn, "
  SELECT ST_XMin(e) xmin, ST_YMin(e) ymin, ST_XMax(e) xmax, ST_YMax(e) ymax
  FROM (SELECT ST_Extent(geom) e FROM whse_basemapping.fwa_watersheds_poly WHERE wscode_ltree <@ '100'::ltree) x")
ext <- terra::project(terra::ext(unlist(e)[c("xmin", "xmax", "ymin", "ymax")]), "EPSG:3005", "EPSG:4326")
bbox <- c(ext$xmin, ext$ymin, ext$xmax, ext$ymax) + c(-1, -1, 1, 1) * 0.0625
pcic_dir <- file.path(data_root, "pcic")
mad_cell <- wet_pcic_annual("RUNOFF", bbox, base_years, dir = pcic_dir) +
  wet_pcic_annual("BASEFLOW", bbox, base_years, dir = pcic_dir)
cen <- wet_ws_sample(mad_cell, ws[, c("watershed_feature_id", "lon", "lat")], "centroid")
acc <- wet_upstream_mean(ws, cen, "total", irregular_pairs = irr)
acc$q_m3s <- wet_mm_to_m3s(acc$value, acc$upstream_area_m2)
lut <- function(lfid) {
  DBI::dbGetQuery(conn, sprintf("
    SELECT linear_feature_id::double precision AS linear_feature_id, watershed_feature_id
    FROM whse_basemapping.fwa_streams_watersheds_lut WHERE linear_feature_id IN (%s)",
    paste(sprintf("%.0f", lfid), collapse = ", ")))
}

# the headwater and the confluence, by the registered rules
pick_headwater <- function() {
  gw <- st_all$watershed_feature_id[st_all$station_number == "08KC001"]
  stopifnot(length(gw) == 1L)
  cand <- DBI::dbGetQuery(conn, sprintf("
    SELECT s.linear_feature_id::double precision AS linear_feature_id, l.watershed_feature_id
    FROM whse_basemapping.fwa_watersheds_poly g
    JOIN whse_basemapping.fwa_stream_networks_sp s
      ON whse_basemapping.fwa_upstream(g.wscode_ltree, g.localcode_ltree, s.wscode_ltree, s.localcode_ltree)
    JOIN whse_basemapping.fwa_streams_watersheds_lut l ON l.linear_feature_id = s.linear_feature_id
    JOIN whse_basemapping.fwa_watersheds_poly w ON w.watershed_feature_id = l.watershed_feature_id
    JOIN pcic.segment_weights sw ON sw.linear_feature_id = s.linear_feature_id
    WHERE g.watershed_feature_id = %d AND s.edge_type IN (%s) AND %s AND sw.share < 1
      AND NOT EXISTS (SELECT 1 FROM pcic.fwa_crosswalk x WHERE x.linear_feature_id = s.linear_feature_id
                      AND x.flag IS NULL)
    ORDER BY s.linear_feature_id", gw, paste(main_flow, collapse = ", "), routed_own_line_sql))
  cand$area_m2 <- acc$upstream_area_m2[match(cand$watershed_feature_id, acc$watershed_feature_id)]
  cand <- cand[!is.na(cand$area_m2) & cand$area_m2 < 10e6, ]
  cand <- cand[order(-cand$area_m2, cand$linear_feature_id), ]
  list(lfid = cand$linear_feature_id[1], n = nrow(cand))
}
# the routed run's filter on one alias of its table
run_on <- function(a) sprintf("(%1$s.model, %1$s.scenario, %1$s.period) = ('%2$s', '%3$s', '%4$s')", a,
                              routed_run$model, routed_run$scenario, routed_run$period)
pick_confluence <- function() {
  gl <- g$linear_feature_id[!is.na(g$outlet)]
  j <- DBI::dbGetQuery(conn, sprintf("
    WITH junctions AS (
      SELECT
        (SELECT t.linear_feature_id FROM whse_basemapping.fwa_stream_networks_sp t
         WHERE t.blue_line_key = bp.blue_line_key ORDER BY t.downstream_route_measure LIMIT 1) AS trib_lfid,
        u.linear_feature_id AS upper_lfid, u.geom,
        (SELECT a.linear_feature_id FROM whse_basemapping.fwa_stream_networks_sp a
         WHERE a.blue_line_key = u.blue_line_key AND a.downstream_route_measure > u.downstream_route_measure + 0.001
         ORDER BY a.downstream_route_measure LIMIT 1) AS above_lfid
      FROM fwapg.blk_paths bp
      INNER JOIN whse_basemapping.fwa_stream_networks_sp u
        ON u.blue_line_key = bp.path_blks[1] AND abs(u.downstream_route_measure - bp.path_measures[1]) < 0.001
      WHERE cardinality(bp.path_blks) > 0 AND u.wscode_ltree <@ '100'::ltree
    ), steps AS (
      SELECT j.trib_lfid::double precision AS trib_lfid, j.upper_lfid::double precision AS upper_lfid,
             j.above_lfid::double precision AS above_lfid, j.geom,
             qt.q_m3s AS q_trib, qu.q_m3s AS q_upper, qa.q_m3s AS q_above
      FROM junctions j
      JOIN %1$s qt ON qt.linear_feature_id = j.trib_lfid AND qt.month = 6 AND %2$s
      JOIN %1$s qu ON qu.linear_feature_id = j.upper_lfid AND qu.month = 6 AND %3$s
      JOIN %1$s qa ON qa.linear_feature_id = j.above_lfid AND qa.month = 6 AND %4$s
      WHERE qt.q_m3s > 1 AND qu.q_m3s - qa.q_m3s > 0.5 * qt.q_m3s
    )
    SELECT s.trib_lfid, s.upper_lfid, s.above_lfid, s.q_trib, s.q_upper, s.q_above,
           min(ST_Distance(s.geom, g.geom)) AS dist_m,
           (SELECT count(*) FROM steps) AS n_steps
    FROM steps s CROSS JOIN whse_basemapping.fwa_stream_networks_sp g
    WHERE g.linear_feature_id IN (%5$s)
    GROUP BY s.trib_lfid, s.upper_lfid, s.above_lfid, s.q_trib, s.q_upper, s.q_above
    ORDER BY dist_m, s.upper_lfid LIMIT 1",
    routed_table, run_on("qt"), run_on("qu"), run_on("qa"), paste(sprintf("%.0f", gl), collapse = ", ")))
  stopifnot(nrow(j) == 1L)
  j
}

hw <- pick_headwater()
cf <- pick_confluence()
picked <- c(headwater = hw$lfid, confluence = cf$upper_lfid)
for (ty in names(picked)) {
  got <- as.numeric(sites$linear_feature_id[sites$type == ty])
  if (!identical(got, picked[[ty]])) {
    stop("the ", ty, " row of ", sites_csv, " is not the registered rule's pick, ", sprintf("%.0f", picked[[ty]]),
         call. = FALSE)
  }
}
for (s in gauged) {
  got <- as.numeric(sites$linear_feature_id[sites$station %in% s])
  if (!identical(got, as.numeric(snapped$linear_feature_id[snapped$station_number == s]))) {
    stop(sites_csv, "'s segment for ", s, " is not the snapped station's", call. = FALSE)
  }
}
sites$linear_feature_id <- as.numeric(sites$linear_feature_id)
w_s <- routed_weights(conn, sites$linear_feature_id)
si <- match(sites$linear_feature_id, w_s$linear_feature_id)
stopifnot(!anyNA(si))
sites$subid <- w_s$subid[si]
sites$share <- w_s$share[si]
sites$n_up <- lengths(w_s$upstream_subids[si])
sites$own <- vapply(seq_len(nrow(sites)), function(i) {
  isTRUE(xw$linear_feature_id[match(sites$subid[i], xw$subid)] == sites$linear_feature_id[i]) &&
    sites$subid[i] %in% placed && sites$share[i] == 1
}, TRUE)
sites$agree <- vapply(sites$subid, agree_at, TRUE)
seg_meta <- DBI::dbGetQuery(conn, sprintf("
  SELECT linear_feature_id::double precision AS linear_feature_id, stream_order, edge_type, gnis_name
  FROM whse_basemapping.fwa_stream_networks_sp WHERE linear_feature_id IN (%s) ORDER BY linear_feature_id",
  paste(sprintf("%.0f", sites$linear_feature_id), collapse = ", ")))
sites <- merge(sites, seg_meta, by = "linear_feature_id", all.x = TRUE, sort = FALSE)
sites <- sites[match(c("headwater", "tributary", "lake_outlet", "confluence", "mainstem", "glacier"), sites$type), ]
site_ws <- lut(sites$linear_feature_id)
sites$watershed_feature_id <- site_ws$watershed_feature_id[match(sites$linear_feature_id, site_ws$linear_feature_id)]
ai <- match(sites$watershed_feature_id, acc$watershed_feature_id)
sites$area_km2 <- acc$upstream_area_m2[ai] / 1e6
sites$q_wet_acc <- acc$q_m3s[ai]
site_x <- xw[match(sites$subid, xw$subid), c("flag", "islake", "distance_to_stream", "candidate_rank")]
interior <- which(!sites$own)
extra <- unique(unlist(lapply(interior, function(i) c(w_s$upstream_subids[[si[i]]], frontier(sites$subid[i])))))
DBI::dbDisconnect(conn)

# ---- routed PCIC and the balance as published -----------------------------------------------------
stamp("published values")
cat_pub <- wet_catalog()
pub_digest <- wet:::wet_catalog_digest(cat_pub)
mon_wide <- function(d, ids) {
  m <- matrix(NA_real_, 13, length(ids), dimnames = list(0:12, sprintf("%.0f", ids)))
  m[cbind(d$month + 1L, match(sprintf("%.0f", d$linear_feature_id), colnames(m)))] <- d$q_m3s
  m
}
all_lfid <- c(g$linear_feature_id, sites$linear_feature_id)
r_fw <- mon_wide(wet_segment_monthly(DBI::dbConnect(RPostgres::Postgres(),
                                                     host = Sys.getenv("WET_PGHOST", "localhost"),
                                                     port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                                                     dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                                                     user = Sys.getenv("WET_PGUSER", "postgres"),
                                                     password = Sys.getenv("WET_PGPASSWORD", "postgres"),
                                                     connect_timeout = 10),
                                     all_lfid, "pcic_routed", from = "fwapg"), unique(all_lfid))
pp <- wet_segment_monthly(NULL, all_lfid, c("pcic_routed", "wet_balance"), from = "published",
                          groups = unique(c(g$watershed_group_code, sites$wsg_code)), catalog = cat_pub)
r_pub <- mon_wide(pp[pp$source == "pcic_routed", ], unique(all_lfid))
b_pub <- mon_wide(pp[pp$source == "wet_balance", ], unique(all_lfid))
d_pub <- max(abs(r_pub[-1, ] - r_fw[-1, ]), na.rm = TRUE)
if (!identical(is.na(r_pub), is.na(r_fw)) || d_pub > 5e-6) {
  stop("routed PCIC as published is not fwapg's table at the gauges and sites (largest difference ", d_pub, ")",
       call. = FALSE)
}
# the bundle's routed annual is the published month 0
stopifnot(isTRUE(all.equal(unname(routed_mm(r_pub["0", sprintf("%.0f", g$linear_feature_id)], g$area_km2 * 1e6)),
                           g$routed_mm, tolerance = 1e-9)))

# ---- PCIC's outlet series --------------------------------------------------------------------------
ids_g <- sort(unique(g$outlet[!is.na(g$outlet)]))
ids_s <- sort(unique(sites$subid))
stamp("PNWNAmet streamflow at ", length(unique(c(ids_g, ids_s, extra))), " outlets")
pnw <- run_clim(c(ids_g, ids_s, extra), "PNWNAmet", "historical")
pnw_m <- pnw$clim[["1981-2010"]]
gcm <- list()
for (gm in gcms) {
  stamp(gm, " ", ssp245)
  gcm[[gm]] <- list(ssp245 = run_clim(c(ids_g, ids_s), gm, ssp245, wins = windows, keep_daily = ids_s))
}
for (gm in gcms) {
  stamp(gm, " ", ssp585)
  gcm[[gm]]$ssp585 <- run_clim(ids_s, gm, ssp585, wins = windows, keep_daily = ids_s)
}
stamp("PNWNAmet water temperature at the sites")
wt <- run_clim(ids_s, "PNWNAmet", "historical", variable = "water_temp", keep_daily = ids_s)
col_of <- function(m, ids) m[, match(as.character(ids), colnames(m)), drop = FALSE]

# ---- rule 1 at the gauges ------------------------------------------------------------------------
r1 <- g[!is.na(g$outlet), c("station_number", "station_name", "linear_feature_id", "outlet", "domain", "agree",
                            "islake", "area_km2", "q_obs")]
r1$no_series <- r1$outlet %in% pnw$missing
pubm <- r_pub[as.character(1:12), sprintf("%.0f", r1$linear_feature_id), drop = FALSE]
rawm <- col_of(pnw_m, r1$outlet)
r1$q_pub <- colMeans(pubm)
r1$q_raw <- colMeans(rawm)
r1$ratio <- r1$q_pub / r1$q_raw
r1$worst_month <- apply(abs(pubm - rawm) / pmax(r1_mon * rawm, r1_floor), 2, max)
r1$pass <- !r1$no_series & abs(r1$ratio - 1) <= r1_ann & r1$worst_month <= 1
r1$exact <- abs(r1$ratio - 1) <= r1_exact
r1$type <- ifelse(r1$pass, "", ifelse(r1$no_series, "no series", ifelse(!r1$agree, "networks disagree",
                                                                         ifelse(r1$islake, "lake outlet", NA))))
recheck <- r1$outlet[is.na(r1$type)]
bee_diff <- setNames(numeric(), character())
if (length(recheck)) {
  stamp("beehive, ", length(recheck), " outlets")
  bee <- run_clim(recheck, "PNWNAmet", "historical", host = "beehive")
  bm <- col_of(bee$clim[["1981-2010"]], recheck)
  bee_diff <- setNames(apply(abs(bm - col_of(pnw_m, recheck)), 2, max), recheck)
  r1$type[is.na(r1$type)] <- ifelse(bee_diff[as.character(r1$outlet[is.na(r1$type)])] > 1e-9,
                                    "hosts differ", "unresolved, networks agree")
}

# ---- rule 2 at the gauges ------------------------------------------------------------------------
r2 <- r1[!r1$no_series, c("station_number", "station_name", "outlet", "domain", "q_obs", "q_raw")]
gi <- match(r2$station_number, g$station_number)
g_ann <- sapply(gcms, function(gm) ann(col_of(gcm[[gm]]$ssp245$clim[["1981-2010"]], r2$outlet)))
g_ann <- matrix(g_ann, nrow = nrow(r2), dimnames = list(NULL, gcms))
r2$gcm_missing <- rowSums(is.na(g_ann))
r2$q_gcm_med <- apply(g_ann, 1, stats::median, na.rm = TRUE)
r2$stat_ann <- abs(r2$q_gcm_med - r2$q_raw) / r2$q_obs
med_month <- sapply(seq_len(nrow(r2)), function(k) {
  apply(sapply(gcms, function(gm) col_of(gcm[[gm]]$ssp245$clim[["1981-2010"]], r2$outlet[k])[, 1]), 1,
        stats::median, na.rm = TRUE)
})
sh_gcm <- shares(matrix(med_month, nrow = 12))
sh_pnw <- shares(col_of(pnw_m, r2$outlet))
r2$nse_pnw <- vapply(seq_len(nrow(r2)), function(k) wet:::wet_nse(g_share[gi[k], ], sh_pnw[, k]), 1)
r2$nse_gcm <- vapply(seq_len(nrow(r2)), function(k) wet:::wet_nse(g_share[gi[k], ], sh_gcm[, k]), 1)
r2$d_nse <- r2$nse_gcm - r2$nse_pnw
r2$pass <- r2$stat_ann <= r2_ann & r2$d_nse >= -r2_nse

# ---- domains: series listed, flags and the verdict ------------------------------------------------
lst <- do.call(rbind, lapply(ids_g, function(s) {
  li <- listing(s)
  li <- li[li$variable == "streamflow", ]
  data.frame(outlet = s, pnw = any(li$model == "PNWNAmet"),
             cmip6 = sum(li$model %in% gcms & li$scenario %in% c(ssp245, ssp585)))
}))
lst$domain <- domain_of(lst$outlet)
dom <- data.frame(domain = domains)
dom$gauges <- vapply(domains, function(d) sum(g$domain %in% d), 1L)
dom$cmip6_listed <- vapply(domains, function(d) {
  x <- lst[lst$domain == d, ]
  if (!nrow(x)) NA else all(x$cmip6 == 2L * length(gcms))
}, NA)
dom$r1_n <- vapply(domains, function(d) sum(r1$domain == d), 1L)
dom$r1_share <- vapply(domains, function(d) mean(r1$pass[r1$domain == d]), 1)
dom$r1_pass <- dom$r1_share >= pass1
dom$r2_ann <- vapply(domains, function(d) stats::median(r2$stat_ann[r2$domain == d]), 1)
dom$r2_nse <- vapply(domains, function(d) stats::median(r2$d_nse[r2$domain == d]), 1)
dom$r2_pass <- dom$r2_ann <= r2_ann & dom$r2_nse >= -r2_nse
gridded <- c(Fraser = TRUE, Coast = FALSE, Columbia = TRUE, Peace = TRUE)
dom$verdict <- ifelse(dom$cmip6_listed %in% TRUE & dom$r1_pass %in% TRUE & dom$r2_pass %in% TRUE,
                      "CMIP6 routed, through fwapg's crosswalk",
                      ifelse(gridded[dom$domain], "CMIP5 gridded", "none"))
flags <- table(factor(xw$domain, levels = domains),
               factor(ifelse(is.na(xw$flag), "placed", xw$flag),
                      levels = c("placed", "no_candidate", "no_series", "broken_chain", "demoted")))
# outlets with a PNWNAmet series and none for a GCM, or the reverse, among those fetched
miss_pnw <- pnw$missing[pnw$missing %in% c(ids_g, ids_s)]
miss_gcm <- sort(unique(unlist(lapply(gcms, function(gm) gcm[[gm]]$ssp245$missing))))

# ---- the sites -------------------------------------------------------------------------------------
site_raw <- col_of(pnw_m, sites$subid)
sites$q_raw <- colMeans(site_raw)
sites$q_pub <- r_pub["0", sprintf("%.0f", sites$linear_feature_id)]
sites$q_bal <- b_pub["0", sprintf("%.0f", sites$linear_feature_id)]
sites$q_obs <- st_monthly$q_m3s[st_monthly$month == 0][match(sites$station, st_monthly$station_number[st_monthly$month == 0])]
sites$n_years <- unname(lengths(st_years)[sites$station])
rebuild <- lapply(interior, function(i) {
  up <- w_s$upstream_subids[[si[i]]]
  fr <- frontier(sites$subid[i])
  q <- rowSums(col_of(pnw_m, up)) * (length(up) > 0) +
    (col_of(pnw_m, sites$subid[i])[, 1] - rowSums(col_of(pnw_m, fr)) * (length(fr) > 0)) * sites$share[i]
  pmax(q, 0)
})
site_r1 <- lapply(seq_len(nrow(sites)), function(i) {
  mod <- if (sites$own[i]) site_raw[, i] else rebuild[[match(i, interior)]]
  pub <- r_pub[as.character(1:12), sprintf("%.0f", sites$linear_feature_id[i])]
  c(ratio = mean(pub) / mean(mod), worst = max(abs(pub - mod) / pmax(r1_mon * mod, r1_floor)))
})
sites$r1_ratio <- vapply(site_r1, `[[`, 1, "ratio")
sites$r1_pass <- abs(sites$r1_ratio - 1) <= r1_ann & vapply(site_r1, `[[`, 1, "worst") <= 1
# historical, ssp585 against historical, ssp245 before 2015, at the sites
pre2015 <- vapply(gcms, function(gm) {
  a <- gcm[[gm]]$ssp245$daily
  b <- gcm[[gm]]$ssp585$daily
  max(vapply(seq_along(a), function(k) {
    i <- a[[k]]$dates < as.Date("2015-01-01")
    jb <- which(vapply(b, function(z) setequal(z$ids, a[[k]]$ids), TRUE))
    stopifnot(length(jb) == 1L, identical(a[[k]]$dates, b[[jb]]$dates))
    vb <- b[[jb]]$v[, match(a[[k]]$ids, b[[jb]]$ids), drop = FALSE]
    max(abs(a[[k]]$v[i, , drop = FALSE] - vb[i, , drop = FALSE]))
  }, 1))
}, 1)
# change signals at the sites: each window's annual and monthly flow over 1981-2010's
change <- do.call(rbind, lapply(c(ssp245 = "ssp245", ssp585 = "ssp585"), function(sc) {
  do.call(rbind, lapply(c("2041-2070", "2070-2099"), function(w) {
    do.call(rbind, lapply(gcms, function(gm) {
      cl <- gcm[[gm]][[sc]]$clim
      b0 <- col_of(cl[["1981-2010"]], sites$subid)
      b1 <- col_of(cl[[w]], sites$subid)
      data.frame(site_id = sites$site_id, scenario = sc, window = w, gcm = gm,
                 ann = 100 * (colMeans(b1) / colMeans(b0) - 1),
                 t(100 * (b1 / b0 - 1)), check.names = FALSE)
    }))
  }))
}))
names(change)[6:17] <- month.abb

# water temperature: PNWNAmet's 1981-2010 months at the sites, and the
# gauged sites' observed days within 2002-2012 where both exist
wt_m <- col_of(wt$clim[["1981-2010"]], sites$subid)
obs_t <- tryCatch(wet_temp_daily(gauged, from = as.Date("2002-01-01"), to = as.Date("2012-12-31")),
                  error = function(e) NULL)
wt_cmp <- do.call(rbind, lapply(gauged, function(s) {
  sub <- sites$subid[sites$station %in% s]
  dl <- Filter(function(z) sub %in% z$ids, wt$daily)[[1]]
  pc <- data.frame(date = dl$dates, pcic = dl$v[, match(sub, dl$ids)])
  ob <- if (is.null(obs_t)) NULL else obs_t[obs_t$station_number == s, ]
  if (is.null(ob) || !nrow(ob)) return(data.frame(station = s, n = 0L, bias = NA, rmse = NA))
  m <- merge(pc, data.frame(date = as.Date(ob$date), obs = ob$value), by = "date")
  data.frame(station = s, n = nrow(m), bias = if (nrow(m)) mean(m$pcic - m$obs) else NA,
             rmse = if (nrow(m)) sqrt(mean((m$pcic - m$obs)^2)) else NA)
}))

# ---- the fetch log: provenance and cost --------------------------------------------------------------
fl <- utils::read.delim(f_fetch, colClasses = "character", quote = "", na.strings = character(),
                        comment.char = "")
fl$n <- as.integer(fl$n)
fl$bytes <- as.numeric(fl$bytes)
fl$secs <- as.numeric(fl$secs)
first_fetch <- as.POSIXct(min(fl$utc), format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
if (first_fetch <= reg$utc) {
  stop("the first fetch (", utc_txt(first_fetch), ") precedes the rules' registration (", utc_txt(reg$utc), ")",
       call. = FALSE)
}
used <- c(pnw$files, unlist(lapply(gcm, function(x) c(x$ssp245$files, x$ssp585$files))), wt$files)
used_md5 <- tools::md5sum(used)
okb <- fl[fl$code == "200" & fl$file %in% basename(used) & grepl("^(PNWNAmet|[A-Z])", fl$what) &
            fl$what != "listing", ]
okb <- okb[!duplicated(okb$file, fromLast = TRUE), ]
okb$gcm <- !startsWith(okb$what, "PNWNAmet")
cost <- function(x) c(req = nrow(x), series = sum(x$n), mb = sum(x$bytes) / 2^20, mins = sum(x$secs) / 60)
c_pnw <- cost(okb[!okb$gcm & grepl("streamflow", okb$what), ])
c_gcm <- cost(okb[okb$gcm, ])
n_with_series <- sum(xw$flag %in% NA | xw$flag != "no_series")

# ---- report --------------------------------------------------------------------------------------
pct <- function(x, d = 1) ifelse(is.na(x), "-", sprintf(paste0("%+.", d, "f"), 100 * x))
num <- function(x, d = 3) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
out <- c(
  sprintf("# PCIC's channel-scale output on the FWA (#9, #168), HYDAT %s", release),
  "",
  "## Provenance",
  sprintf("rules: registered at %s, %s; rule block md5 %s", reg$sha, utc_txt(reg$utc), rule_md5),
  sprintf("first fetch: %s (after the registration)", utc_txt(first_fetch)),
  sprintf("script: %s at %s", f_self, wet_commit),
  routed_report_line(fwapg_commit),
  paste("table:", routed_fp),
  sprintf("published: %d parts, live parts md5 %s", nrow(cat_pub$parts), pub_digest),
  sprintf("routed as published equals fwapg's table at the gauges and sites: largest difference %.1e m3/s", d_pub),
  sprintf("scored gauges: %s (%d), from inst/vignette-data/monthly_values.rds md5 %s", "routed carries >= 0.2 of observed",
          nrow(g), unname(tools::md5sum(file.path("inst", "vignette-data", "monthly_values.rds")))),
  sprintf("hydromosaic: %d NetCDF files, md5 of their md5s %s", length(used_md5),
          md5_text(paste(basename(used), used_md5)[order(basename(used))])),
  sprintf("gridded PNWNAmet: TPS_gridded_obs_init RUNOFF + BASEFLOW 1981-2010 over the Fraser, %d cells", terra::ncell(mad_cell)),
  "",
  "## Is the portal hydromosaic?",
  sprintf("portal bundle %s (md5 %s): %s", basename(f_js), unname(tools::md5sum(f_js)),
          paste(sprintf("'%s' %d", names(portal_hits), portal_hits), collapse = ", ")),
  paste("The portal's code names no hydromosaic path, series variable or CSV download; the identity of the portal's",
        "product and hydromosaic rests on the shared subid network, runs and variables."),
  "",
  "## Domains",
  "domain    gauges  with outlet  CMIP6 listed  rule1 n  pass %  rule1  rule2 |dQ|/Qobs  dNSE  rule2  verdict",
  sprintf("%-9s %6d %12d %13s %8d %7s %6s %17s %5s %6s  %s", dom$domain, dom$gauges, dom$r1_n,
          ifelse(is.na(dom$cmip6_listed), "-", ifelse(dom$cmip6_listed, "all", "not all")), dom$r1_n,
          ifelse(dom$r1_n > 0, sprintf("%.1f", 100 * dom$r1_share), "-"),
          ifelse(is.na(dom$r1_pass), "-", ifelse(dom$r1_pass, "pass", "fail")),
          ifelse(is.na(dom$r2_ann), "-", sprintf("%.3f", dom$r2_ann)), ifelse(is.na(dom$r2_nse), "-", sprintf("%+.3f", dom$r2_nse)),
          ifelse(is.na(dom$r2_pass), "-", ifelse(dom$r2_pass, "pass", "fail")), dom$verdict),
  sprintf("scored gauges with no outlet on their segment: %d", sum(is.na(g$outlet))),
  sprintf("among fetched outlets: %d with no PNWNAmet series, %d with no series for some GCM (%s)", length(miss_pnw),
          length(miss_gcm), if (length(miss_gcm)) paste(miss_gcm, collapse = ", ") else "none"),
  paste("Move 7's first check: whether each CMIP6 run's outlets with series are PNWNAmet's, which fwapg's crosswalk",
        "needs (it refuses a run whose crosswalk differs from the stored one)."),
  "",
  "## Outlets by crosswalk flag (share of the domain's outlets, %)",
  sprintf("%-9s %7s  %s", "domain", "outlets", paste(sprintf("%12s", colnames(flags)), collapse = "")),
  sprintf("%-9s %7d  %s", rownames(flags), rowSums(flags),
          apply(flags, 1, function(r) paste(sprintf("%12.1f", 100 * r / sum(r)), collapse = ""))),
  "",
  "## Rule 1: the crosswalk reproduces PCIC's outlet series",
  sprintf("gauges with an outlet: %d; pass %d; not exact (annual past 1e-4 relative) %d", nrow(r1), sum(r1$pass),
          sum(!r1$exact)),
  sprintf("annual ratio, published / raw: median %.6f, range %.6f to %.6f", stats::median(r1$ratio, na.rm = TRUE),
          min(r1$ratio, na.rm = TRUE), max(r1$ratio, na.rm = TRUE)),
  "failing gauges by type:",
  if (any(!r1$pass)) sprintf("  %-28s %d", names(table(r1$type[!r1$pass])), as.vector(table(r1$type[!r1$pass])))
  else "  none",
  if (length(bee_diff)) sprintf("beehive against services at %d outlets: largest monthly difference %.1e m3/s",
                                length(bee_diff), max(bee_diff)) else "beehive: no outlet needed it",
  "station   domain    outlet   annual pub  annual raw     ratio  worst/tol  type",
  with(r1[!r1$pass, ], sprintf("%-9s %-8s %8d %11s %11s %9s %10s  %s", station_number, domain, outlet, num(q_pub),
                               num(q_raw), num(ratio, 5), num(worst_month, 2), type)),
  "",
  "## Rule 2: CMIP6 against PNWNAmet at the gauges, 1981-2010 (historical, ssp245)",
  sprintf("gauges: %d; pass %d; GCM series missing at %d gauges", nrow(r2), sum(r2$pass), sum(r2$gcm_missing > 0)),
  "domain    n  |medGCM-PNW|/Qobs median  p90   share NSE PNW  GCM  diff median",
  vapply(domains, function(d) {
    x <- r2[r2$domain == d, ]
    if (!nrow(x)) return(sprintf("%-8s %2d", d, 0L))
    sprintf("%-8s %3d %26.3f %5.3f %13.3f %5.3f %+12.3f", d, nrow(x), stats::median(x$stat_ann),
            stats::quantile(x$stat_ann, 0.9, names = FALSE), stats::median(x$nse_pnw), stats::median(x$nse_gcm),
            stats::median(x$d_nse))
  }, ""),
  "gauges failing rule 2:",
  if (any(!r2$pass)) with(r2[!r2$pass, ], sprintf("  %-9s %-8s |dQ|/Qobs %.3f  dNSE %+.3f", station_number, domain,
                                                  stat_ann, d_nse)) else "  none",
  "",
  "## The sites",
  "site        station  segment     wsg   subid    own agree share  flag     lake  dist_m rank order area_km2 regulated years",
  sprintf("%-11s %-8s %10.0f %-5s %8d %4s %5s %5.3f %-8s %5s %7.1f %4s %5d %8.1f %9s %5s", sites$site_id,
          ifelse(is.na(sites$station), "-", sites$station), sites$linear_feature_id, sites$wsg_code, sites$subid,
          ifelse(sites$own, "y", "n"), ifelse(sites$agree, "y", "n"), sites$share,
          ifelse(is.na(site_x$flag), "placed", site_x$flag), ifelse(site_x$islake, "y", "n"), site_x$distance_to_stream,
          as.character(site_x$candidate_rank), sites$stream_order, sites$area_km2,
          ifelse(is.na(sites$regulated), "-", sites$regulated), ifelse(is.na(sites$n_years), "-", sites$n_years)),
  sprintf("headwater: %d candidates under 10 km2; confluence: %d junctions where June's step lands above, the pick's",
          hw$n, cf$n_steps),
  sprintf("  joining line %.3f m3/s in June, upper segment %.3f, next segment up %.3f, %.0f m from a scored gauge",
          cf$q_trib, cf$q_upper, cf$q_above, cf$dist_m),
  "",
  "annual flow, 1981-2010 (m3/s): HYDAT, PCIC raw at the outlet, routed as published, the balance as published,",
  "wet's accumulation of the gridded runoff; rule 1 at the site (own segment: raw; interior: rebuilt from raw)",
  "site        HYDAT    PCIC raw   routed pub  balance pub  wet acc    pub/rule1  rule1",
  sprintf("%-11s %8s %10s %12s %12s %9s %10s  %s", sites$site_id, num(sites$q_obs, 2), num(sites$q_raw, 2),
          num(sites$q_pub, 2), num(sites$q_bal, 2), num(sites$q_wet_acc, 2), num(sites$r1_ratio, 5),
          ifelse(sites$r1_pass, "pass", "fail")),
  sprintf("historical, ssp585 against historical, ssp245 before 2015 at the sites: largest difference %.1e m3/s",
          max(pre2015)),
  "",
  "## Change signals at the sites (%, decide nothing)",
  "annual, per GCM (columns as listed: CNRM FGOA IPSL MIRO MPI MRI NorE TaiE UKES) and median",
  unlist(lapply(sites$site_id, function(s) {
    x <- change[change$site_id == s, ]
    vapply(split(x, paste(x$scenario, x$window)), function(y) {
      sprintf("%-11s %-6s %-9s %s  med %+6.1f", s, y$scenario[1], y$window[1],
              paste(sprintf("%+6.1f", y$ann[match(gcms, y$gcm)]), collapse = ""), stats::median(y$ann))
    }, "")
  })),
  "by month, median over the 9 GCMs",
  sprintf("%-11s %-6s %-9s %s", "site", "", "", paste(sprintf("%7s", month.abb), collapse = "")),
  unlist(lapply(sites$site_id, function(s) {
    x <- change[change$site_id == s, ]
    vapply(split(x, paste(x$scenario, x$window)), function(y) {
      sprintf("%-11s %-6s %-9s %s", s, y$scenario[1], y$window[1],
              paste(sprintf("%+7.1f", apply(y[month.abb], 2, stats::median)), collapse = ""))
    }, "")
  })),
  "",
  "## Water temperature (PNWNAmet, decides nothing)",
  "monthly mean, 1981-2010 (degC)",
  sprintf("%-11s %s", "site", paste(sprintf("%6s", month.abb), collapse = "")),
  sprintf("%-11s %s", sites$site_id, apply(wt_m, 2, function(v) paste(sprintf("%6.1f", v), collapse = ""))),
  "water-temp-bc daily means on the same days, 2002-2012",
  sprintf("%-9s days %5d  bias %s  rmse %s", wt_cmp$station, wt_cmp$n, num(wt_cmp$bias, 2), num(wt_cmp$rmse, 2)),
  "",
  "## Fetching and scaling",
  sprintf("PNWNAmet streamflow: %d requests, %d series, %.1f MiB, %.1f min", c_pnw[["req"]], c_pnw[["series"]],
          c_pnw[["mb"]], c_pnw[["mins"]]),
  sprintf("CMIP6 streamflow (both SSPs): %d requests, %d series, %.1f MiB, %.1f min", c_gcm[["req"]],
          c_gcm[["series"]], c_gcm[["mb"]], c_gcm[["mins"]]),
  sprintf("a whole CMIP6 run (%d outlets with series, at this pace): %.1f GiB, %.0f min of transfer",
          n_with_series, n_with_series * c_gcm[["mb"]] / c_gcm[["series"]] / 1024,
          n_with_series * c_gcm[["mins"]] / c_gcm[["series"]]),
  "done by hand: starting the database; the site table (scripts/channel_scale_sites.csv)"
)
writeLines(out, f_report)
stamp("wrote ", f_report)
