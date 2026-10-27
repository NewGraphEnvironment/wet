# PCIC's per-year routed flow against donor-carried departures (#122,
# component 3 of #118): weight donor gauges by how PCIC's modelled years move
# together, then score donors, PCIC's own years and a blend of the two, held
# out at every calibration gauge PCIC covers, 1951-2012. The rule below was
# fixed in this header, and committed alone, before any candidate was coded or
# scored; the body that runs it came later (planning/archive, issue 122). The
# report names the commit this header was registered at.
#
#   WET_HYDAT_RELEASE=20260717 WET_FWAPG_COMMIT=<sha> WET_PCIC_YEARS=<dir> \
#     Rscript scripts/departure_pcic.R
#
# Reads HYDAT 20260717 only (scripts/wb_fit_lib.R's wb_hydat()); the shipped
# fit's calibration gauges through scripts/wb_cv_lib.R (`cal`, held to its
# scores by scripts/pcic_routed_lib.R's shipped_heldout()); fwapg through the
# WET_PG* env vars (pcic.segment_weights, pcic.subbasin_daily and pcic.runs
# for the 1951-2012 run, pcic.series for the per-year catalogue, and the FWA
# for snapping the box gauges); and the per-year product under WET_PCIC_YEARS
# (the interface section below). Writes
# the tracked report data/checks/departure_pcic_20260717.txt and, after it,
# the gitignored data/departure/departure_pcic_20260717.rds: per gauge the
# observed, modelled and carried series per statistic and window, what each
# stage shipped, `release`, the two fwapg commits and `code_md5` (the md5 of
# the script file Rscript runs, as it stands at the start of the run), which
# #130 reads. Run a frozen copy (cp scripts/departure_pcic.R "$TMPDIR/d.R" &&
# Rscript "$TMPDIR/d.R"), since Rscript reads a script as it runs. Nothing is
# published and no fit is written.
#
# ---- decided at the plan gate (user, 2026-10-26) ---------------------------------------------
#
# Windows: the CH rows of inst/vignette-data/life_history_bulk.csv, migration
#   05-01..08-01 and spawning 08-01..09-15, both days inclusive, as fixed
#   calendar windows at every gauge in the province (#120's, not refitted to
#   a region's runs).
# Statistic that decides: the migration-window mean, as a log departure.
#   Reported, deciding nothing: the spawning mean, and min7 and cov_day in
#   both windows (wet_window_stats()).
# Scale, as #120: a departure is log(value / baseline mean), the baseline
#   mean the arithmetic mean of the 1981-2010 values; cov_day is a day of the
#   window, so its departure is a difference in days.
# Observed: HYDAT release 20260717, approved daily flows only
#   (wet_station_daily(sources = "hydat")). Scored years: 1951-2012, PCIC's
#   run, intersected with each gauge's complete window-years.
# Blend: fixed equal weights in log units (days for cov_day), 0.5 * donors +
#   0.5 * pcic; 0.25 and 0.75 reported, deciding nothing.
# Cross-validation: leave-one-gauge-out and the leak-free pool, not the fit's
#   blocked folds. The issue says "blocked CV ... as #102 did"; this departs
#   because a donor method has no fitted parameters to hold out, and a
#   blocked fold (a WSC sub-sub-drainage) removes most of a gauge's nearest
#   donors, which is the method itself. The leak-free pool removes exactly
#   the donors that share the target's water, the leak blocked folds exist
#   to stop.
#
# ---- the pool ----------------------------------------------------------------------------------
#
# The shipped fit's calibration gauges, `cal` from scripts/wb_cv_lib.R on
# release 20260717 (natural flow, accepted snap, basin >= 95 % in BC and on
# the grid; 315 gauges), whose snapped segment (cal$linear_feature_id) has a
# row in pcic.segment_weights. That row is what "PCIC routes flow to the
# gauge's segment" means in this script, for the pool and the test set alike.
# The report prints that count and, beside it, the count under #58's
# definition (a pcic.discharge_monthly row; 290 there).
#
# Per (variable, period): a gauge enters that statistic's pool if it has at
# least 10 complete window-years of the observed statistic inside 1981-2010
# with a value > 0 (any value for cov_day), so its own baseline is defined
# and wet_departure_carry(), which drops values <= 0 from a log statistic,
# accepts it as a donor. A complete window-year is a row wet_window_stats() returns at its
# default min_frac = 0.8; cov_day's are the window-years with every day
# present, which wet_window_stats() alone returns. The headline pool, and
# the counts the rule reports, are the migration mean's. Donors and held-out
# targets of a statistic both come from its pool. The rule refuses a
# migration-mean pool under 100 gauges.
#
# Predictors, as #70, #102 and #120: easting and northing in km (HYDAT
# STATIONS lon/lat projected to EPSG:3005) and log gross drainage area (km2),
# each divided by its SD (wet_station_space()). ONE stations table serves
# every call: the union of every statistic's pool and the short-record test
# set, so the scaling is the same in every leave-one-out, leak-free and
# test-set call. Distance is Euclidean in that space. k = 5.
#
# ---- the modelled series -----------------------------------------------------------------------
#
# Each pool and test gauge's segment is routed day by day over 1951-2012 from
# the per-year product (wet_routed_years()): q = max(sum of q_acc over the
# segment's upstream_subids + q_local of its subid * share, 0), rounded to 5
# decimals as fwapg rounds its published days. The parity check (below) reads
# the unrounded sub-basin values, never these. wet_window_stats() on the same
# windows and statistics then gives a modelled value per window-year; every
# modelled day exists, so every modelled window-year is complete.
#
# A modelled departure is log(value / mean over 1981-2010 of the modelled
# values), days for cov_day. Scoring centres every series (below), so this
# constant cancels: PCIC's bias and its baseline do not touch its score, only
# how its years vary. A modelled window-year whose mean or min7 is <= 0 is
# dropped from the logs and counted; the gauges #58 found routed to about 0
# (08JA015, 08JA016, 08JA014, 08JA028, 08DB013) are expected there.
#
# Limit, stated in the report and deciding nothing: PCIC does not publish the
# gauges its model was calibrated to (research/water_balance_method.md, #58),
# so `pcic`'s score at a calibration gauge may be partly in sample, while
# donors are always held out.
#
# ---- stage 1: how donors are weighted ----------------------------------------------------------
#
# r, per (variable, period), between a target and a candidate donor: the
# Pearson correlation of the two gauges' modelled departures (log, or days)
# over the years 1951-2012 both modelled series have. r needs at least 30
# such years; an r resting on fewer, or NA (a constant series, as at a
# segment routed to 0), counts as 0. Only modelled series enter r, so a
# held-out target's observations never weight its donors.
#
# Candidates, every setting fixed here. w_d is wet_donor_mean()'s distance
# weight: 1 / (d + 1e-6 * m), d the donor's distance to the target and m the
# median of the target's distances to every donor in its pool, except that
# when any of the chosen donors is at distance 0, those take weight 1 and
# the rest 0.
#
#   distance         the incumbent, wet_departure_carry() as #120 shipped it:
#                    the k nearest, weight w_d.
#   covariance       the same k nearest, weight w_d * max(r, 0).
#   covariance_pick  among the 15 nearest, the k with the highest r (a tie
#                    to the nearer), weight max(r, 0).
#
# In every candidate, a donor without a value in a year is dropped for that
# year and the remaining weights renormalised to sum 1 (wet_departure_carry()
# as shipped); a year in which no donor is present, or every donor present
# weighs 0, is missing for that candidate. A target whose k chosen donors all
# weigh 0 (for covariance_pick: none of the 15 has r > 0) falls back to
# `distance` for that target, and the report counts it.
#
# The rule: the challenger is whichever of covariance and covariance_pick has
# the higher median per-gauge NSE under leave-one-gauge-out (a tie to
# covariance, listed first). It ships if its median exceeds distance's by at
# least 0.01 (unrounded, 1e-9 allowed for floating point; #16's margin) under
# leave-one-gauge-out AND in the leak-free pool; otherwise distance ships.
#
# The expected null, stated before any score: PNWNAmet's forcing is shared
# across a region, so modelled r among nearby segments should be high and
# flat, and covariance ~ distance is the likely result. With 62 years r's
# sampling SD is about 0.13, so covariance_pick picks partly on noise; that
# is why a win must also hold in the leak-free pool. The report gives the
# median distance (km) to the donors each candidate used.
#
# ---- stage 2: donors, PCIC or a blend ----------------------------------------------------------
#
# On the stage-1 shipper:
#
#   donors  observed departures carried from donor gauges (stage 1's shipper).
#   pcic    the target's own modelled departure at its segment.
#   blend   0.5 * donors + 0.5 * pcic, in log units (days for cov_day); a
#           year either component lacks is missing from blend.
#
# The rule: the challenger is whichever of pcic and blend has the higher
# median per-gauge NSE under leave-one-gauge-out (a tie to pcic, listed
# first). It ships if its median exceeds donors' by at least 0.01 (1e-9
# allowed) under leave-one-gauge-out AND in the leak-free pool; otherwise
# donors ship. After 2012 only donors carry values, whatever ships.
#
# Stated before any score: averaging two centred, imperfectly correlated
# predictors reduces error variance, so blend is expected to beat both of its
# components on that alone, and a blend win says little about PCIC's own
# skill. The informative outcome is whether pcic alone clears donors; the
# report prints pcic's median minus donors' under both pools whatever ships.
#
# ---- scoring -------------------------------------------------------------------------------------
#
# Leave-one-gauge-out at every pool gauge: its donors are its statistic's pool
# without it. Every candidate of a stage is scored at a held-out gauge on the
# SAME years: 1951-2012, intersected with the gauge's complete window-years
# of the statistic, intersected with the years every candidate of that stage
# has a value for (#120's question 1). The score is wet:::wet_nse() of the
# candidate against the gauge's observed log window value (days for
# cov_day), BOTH CENTRED ON THEIR MEAN OVER THOSE YEARS (#120's question 2),
# so no target baseline is needed and NSE 0 is "no departure". A gauge with
# fewer than 3 such years, or an NA NSE, is not scored and is counted. The
# median over gauges decides; quartiles are reported. Per stage the script
# asserts that every candidate is scored at the same gauges on the same years,
# and the report prints n per candidate.
#
# ---- the leak-free pool --------------------------------------------------------------------------
#
# A held-out gauge's upstream and downstream pool gauges
# (wet:::wet_fwa_upstream() on cal$wscode and cal$localcode, either
# direction) are removed from its donors, and every candidate of both stages
# is refitted and rescored on its own common years. A co-located pair shares
# codes, so each removes the other; the report counts such pairs. pcic's
# values do not change, only the years it is scored on. Runs always: `cal`
# carries the codes.
#
# ---- the short-record test set -------------------------------------------------------------------
#
# The union of the stations rds `test` gauges (natural, 1 to 9 complete years
# inside 1981-2010, already snapped) and #120's box short-record gauges
# reproduced by its rule (natural BC gauges in lon -128.8..-125.0, lat
# 53.6..55.8 with 3 to 10 complete migration windows; 08EE018 is among them
# and in neither stations rds set), snapped with wet_station_snap() through
# WET_PG*. A gauge is kept where its snap is accepted, its segment has a
# pcic.segment_weights row, it is not in the migration-mean pool, and 3 to 10
# of its complete migration-window years fall inside 1951-2012; each drop is
# counted by reason. Every candidate of both stages is scored there from the
# full pool, on the same common-years rule, separately, deciding nothing.
# 08EE018's row is printed by name (#130 reads it).
#
# ---- sensitivities (reported, unable to ship; a winning one is a new rule in a new issue) --------
#
# k = 3 and 8; the spawning mean; min7 and cov_day in both windows; blend
# weights 0.25 and 0.75 (on donors); PCIC's own skill, as centred NSE and as
# correlation (they differ where its amplitude is off), by major basin
# (routed_basin()), drainage-area class (cal$area_class) and cal$nesting; the
# number of target-donor pairs whose r rests on fewer than 62 years, and of
# targets where covariance or covariance_pick fell back to distance.
#
# ---- the per-year product: what wet consumes from fwapg#42 ---------------------------------------
#
# THIS SECTION ALONE IS AMENDABLE, by NewGraphEnvironment/fwapg#42's plan gate
# and before this script's body is written, in a commit of its own that the
# report names. The scoring rule above is frozen. Amended once, before any
# body existed, to what fwapg#42's gate decided on 2026-10-26 (its decisions
# 1 to 3), which had not seen the first version (float64, year/month/day
# ints, a commit in a sidecar).
#
# The per-year sub-basin days of the PNWNAmet historical run as fwapg#42
# publishes them: one parquet file per year,
# pcic.subbasin_days.PNWNAmet_historical.<year>.parquet, with columns `subid`
# (int32), `date` (date32, the calendar date, so 29 February is its own day
# and the bins match cdo ydaymean's) and `q_local`, `q_acc` (m3/s, float32),
# in one directory, WET_PCIC_YEARS. fwapg publishes 1950 to 2012; wet reads
# the 62 files of 1951-2012, 22,646 days per sub-basin, and refuses a missing
# one.
#
# The catalogue is fwapg's pcic.series (decision 3), one row per (model,
# scenario, year): crosswalk_md5, rows, subbasins, q_local_sum, q_acc_sum
# (each the sum of floor(double(v) * 1000 + 0.5) over the stored float32
# values, as a 64-bit integer) and bytes. Each of the 62 files read must
# equal its row in bytes, rows, subbasins and both sums, computed by wet from
# the file, and every row's crosswalk_md5 must be the one pcic.runs records
# for the 1951-2012 run. The catalogue's `commit` column names the fwapg
# commit that built the files (fwapg#42 kept it); the 62 rows must name one
# commit, which the report prints beside WET_FWAPG_COMMIT (the one that built
# the Postgres tables, which pcic.runs does not record) and the md5 of the 62
# catalogue rows. (Amended a second time at b518ebc, once the catalogue
# shipped with the column: after the body was written, so outside the window
# above, and before any run on the product. It changes which commit the report
# names for the files, not the scoring, and replaces WET_FWAPG_DAYS_COMMIT.)
#
# Parity, over every sub-basin the pool's and the test set's segments name
# (subid and upstream_subids): for each (month, day) bin of q_local and of
# q_acc, the mean over 1951-2012 of the stored values is within
# 2^-23 * (the mean over the same years of their absolute values) + 1e-9 m3/s
# of pcic.subbasin_daily's 1951-2012 row. Each stored float32 is within
# 2^-24 of its float64 value relative to that value, so the bin mean is
# within 2^-24 of the mean absolute value, and the float64 means agree but
# for summation order; a bound relative to the mean alone would fail at a
# bin whose values change sign (a losing reach). pcic.subbasin_daily holds
# full float64 means (measured 2026-10-26: neither float32 nor 5-decimal
# values). The 1951-2012 run's tables must match pcic.runs
# (routed_daily_fingerprint() for that period).
#
# ---- what it refuses -----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; WET_FWAPG_COMMIT unset or not 7 to
# 40 hex characters; uncommitted changes under R/ or scripts/ (as
# scripts/pcic_routed_compare.R, so the recorded commit rebuilds the report);
# a `cal` whose scores were made under other scoring code (shipped_heldout()'s
# guards); a year of 1951-2012 without its file, or a file unlike its
# pcic.series row, or a row on another crosswalk than the run's, or rows
# naming more than one commit or none; a read sub-basin missing from a
# year, without its 22,646 days of 1951-2012, with a day twice or an NA flow,
# or failing parity in any bin; 1951-2012 tables that differ from
# pcic.runs; a migration-mean pool under 100 gauges; a stage whose
# candidates are not scored at the same gauges on the same years. The report
# carries no timestamp, so a rerun on the same inputs reproduces it byte for
# byte.

# ==================================================================================================
# The body: written after the header and its amendments (5904cd7, a8ff752, 5a67a46), before any candidate
# was scored; the interface section was amended again after it, at b518ebc. Everything below implements
# the rule above; nothing here changes it.
# ==================================================================================================

source("scripts/wb_cv_lib.R")  # load_all(), cal, release, fit_dir, score_code_md5
source("scripts/pcic_routed_lib.R")

if (release != "20260717") stop("the rule names HYDAT 20260717, not ", release, call. = FALSE)
# the script this run executes (a frozen copy, say), hashed before anything else can change it
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) {
  stop("run with Rscript, not through source(), so the script's own md5 can be recorded", call. = FALSE)
}
code_md5 <- unname(tools::md5sum(self))
if (is.na(code_md5)) stop("cannot read the running script at ", self, " to record its md5", call. = FALSE)

# the report cites the commit it was built at, so that commit must hold the code
git <- function(...) {
  x <- suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = TRUE))
  if (!is.null(attr(x, "status"))) stop("git ", paste(c(...), collapse = " "), " failed: ", paste(x, collapse = " "))
  x
}
dirty <- git("status", "--porcelain", "--", "R", "scripts")
if (length(dirty)) stop("commit these first, so the recorded commit can rebuild the report:\n",
                        paste(dirty, collapse = "\n"))
# the frozen copy that runs must be the committed script, or the report names a commit that did not make it
if (!identical(code_md5, unname(tools::md5sum("scripts/departure_pcic.R")))) {
  stop("the running copy differs from scripts/departure_pcic.R at HEAD; copy it again", call. = FALSE)
}
wet_commit <- git("rev-parse", "--short", "HEAD")
rule_commits <- c(registered = "5904cd7", weight_amended = "a8ff752", interface_amended = "5a67a46",
                  commit_amended = "b518ebc")
fwapg_commit <- routed_commit()
pcic_dir <- Sys.getenv("WET_PCIC_YEARS")
if (!nzchar(pcic_dir) || !dir.exists(pcic_dir)) stop("set WET_PCIC_YEARS to the per-year files' directory", call. = FALSE)
ho <- shipped_heldout()  # refuses a fit scored under other scoring code
hydat <- wb_hydat(release)

report <- file.path("data", "checks", sprintf("departure_pcic_%s.txt", release))
rds <- file.path("data", "departure", sprintf("departure_pcic_%s.rds", release))
years_run <- 1951:2012
period_run <- "1951-2012"
n_days_run <- sum(365 + (years_run %% 4 == 0))  # 22,646; no century year in the run
baseline <- 1981:2010
k_main <- 5
k_sens <- c(3, 8)
n_pick <- 15
margin <- 0.01
eps <- 1e-9
min_pool <- 100
w_blend <- 0.5
w_blend_sens <- c(0.25, 0.75)
box <- c(lon_min = -128.8, lon_max = -125.0, lat_min = 53.6, lat_max = 55.8)
maxan <- "08EE018"
series <- paste(routed_run$model, routed_run$scenario, sep = "_")
where_run <- routed_where_period(period_run)

lh <- utils::read.csv("inst/vignette-data/life_history_bulk.csv")
lh <- lh[lh$species_code == "CH" & lh$life_stage %in% c("migration", "spawning"), ]
windows <- data.frame(window = lh$life_stage, start = lh$start, end = lh$end)
stopifnot(identical(windows$window, c("migration", "spawning")),
          identical(windows$start, c("05-01", "08-01")), identical(windows$end, c("08-01", "09-15")))
stats_all <- expand.grid(v = c("q_mean", "q_min7", "q_cov_day"), p = c("migration", "spawning"),
                         stringsAsFactors = FALSE)
stats_all <- stats_all[order(stats_all$p, match(stats_all$v, c("q_mean", "q_min7", "q_cov_day"))), ]
is_days <- function(v) grepl("_cov_day$", v)

fmt <- function(x, d = 2) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
out <- character()
say <- function(...) out <<- c(out, ...)

conn <- DBI::dbConnect(RPostgres::Postgres(),
                       host = Sys.getenv("WET_PGHOST", "localhost"),
                       port = as.integer(Sys.getenv("WET_PGPORT", "5432")),
                       dbname = Sys.getenv("WET_PGDATABASE", "fwapg"),
                       user = Sys.getenv("WET_PGUSER", "postgres"),
                       password = Sys.getenv("WET_PGPASSWORD", "postgres"))
daily_fp <- routed_daily_fingerprint(conn, period_run)  # refuses tables unlike pcic.runs

# ---- the pool ------------------------------------------------------------------------------------
cg <- cal[c("station_number", "station_name", "lon", "lat", "drainage_area_gross_km2", "linear_feature_id",
            "wscode", "localcode", "nesting", "area_class")]
cg$linear_feature_id <- as.integer(cg$linear_feature_id)
stopifnot(!anyNA(cg$linear_feature_id), setequal(cg$station_number, ho$stations$station_number))
w_cal <- routed_weights(conn, cg$linear_feature_id)
cg$covered <- cg$linear_feature_id %in% w_cal$linear_feature_id
ra <- routed_annual(conn, cg$linear_feature_id)
n_58 <- sum(cg$linear_feature_id %in% ra$linear_feature_id[!is.na(ra$q_m3s)])

# ---- the short-record test set: its two sources ---------------------------------------------------
s_rds <- readRDS(wb_stations_path(release))
cols_t <- c("station_number", "station_name", "lon", "lat", "drainage_area_gross_km2", "linear_feature_id",
            "wscode", "localcode", "accepted")
ta <- s_rds$test[cols_t]
ta$from <- "stations rds test"
hcon <- wet:::wet_hydat_connect(hydat)
bx <- DBI::dbGetQuery(hcon, sprintf("
  SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.LONGITUDE lon,
         s.LATITUDE lat, s.DRAINAGE_AREA_GROSS drainage_area_gross_km2
  FROM STATIONS s JOIN STN_REGULATION r USING (STATION_NUMBER)
  WHERE r.REGULATED = 0 AND s.PROV_TERR_STATE_LOC = 'BC'
    AND s.LONGITUDE BETWEEN %f AND %f AND s.LATITUDE BETWEEN %f AND %f
  ORDER BY s.STATION_NUMBER", box[["lon_min"]], box[["lon_max"]], box[["lat_min"]], box[["lat_max"]]))
DBI::dbDisconnect(hcon)
bx <- bx[stats::complete.cases(bx[c("lon", "lat", "drainage_area_gross_km2")]), ]

# ---- observed window statistics ---------------------------------------------------------------------
ids <- sort(unique(c(cg$station_number, ta$station_number, bx$station_number)))
daily <- suppressWarnings(wet_station_daily(ids, hydat, to = NULL, sources = "hydat"))
ws <- wet_window_stats(daily, windows, stats = c("mean", "min7", "cov_day"))
ws <- ws[c("station_number", "variable", "period", "year", "value")]
rm(daily)
obs_vals <- function(v, p) {
  g <- ws[ws$variable == v & ws$period == p & !is.na(ws$value), ]
  if (!is_days(v)) g <- g[g$value > 0, ]
  g
}
n_mig_all <- table(obs_vals("q_mean", "migration")$station_number)
n_mig_run <- table(with(obs_vals("q_mean", "migration"), station_number[year %in% years_run]))
n_of <- function(tab, s) ifelse(s %in% names(tab), as.integer(tab[s]), 0L)

pool_of <- function(v, p) {
  g <- obs_vals(v, p)
  b <- table(g$station_number[g$year %in% baseline])
  sort(intersect(cg$station_number[cg$covered], names(b)[b >= 10]))
}
pools <- lapply(seq_len(nrow(stats_all)), function(i) pool_of(stats_all$v[i], stats_all$p[i]))
names(pools) <- paste(stats_all$v, stats_all$p)
mig_pool <- pools[["q_mean migration"]]
if (length(mig_pool) < min_pool) {
  stop("the migration-mean pool holds ", length(mig_pool), " gauges; the rule needs ", min_pool, call. = FALSE)
}

# the box's short-record gauges by #120's rule, snapped
bx$n_mig <- n_of(n_mig_all, bx$station_number)
bx <- bx[bx$n_mig >= 3 & bx$n_mig <= 10, ]
sn <- wet_station_snap(conn, bx[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
sn <- sn[match(bx$station_number, sn$station_number), ]
tb <- data.frame(bx[c("station_number", "station_name", "lon", "lat", "drainage_area_gross_km2")],
                 linear_feature_id = sn$linear_feature_id, wscode = sn$wscode, localcode = sn$localcode,
                 accepted = sn$accepted %in% TRUE, from = "#120 box short-record")
tt <- rbind(ta, tb[!tb$station_number %in% ta$station_number, ])
tt$from[tt$station_number %in% intersect(ta$station_number, tb$station_number)] <- "both"
tt$linear_feature_id <- as.integer(tt$linear_feature_id)
w_test <- routed_weights(conn, tt$linear_feature_id[tt$accepted & !is.na(tt$linear_feature_id)])
tt$n_run <- n_of(n_mig_run, tt$station_number)
tt$drop <- ifelse(!tt$accepted, "snap not accepted",
                  ifelse(!tt$linear_feature_id %in% w_test$linear_feature_id, "no pcic.segment_weights row",
                         ifelse(tt$station_number %in% mig_pool, "in the migration-mean pool",
                                ifelse(tt$n_run < 3 | tt$n_run > 10,
                                       "not 3 to 10 migration years in 1951-2012", ""))))
test <- tt[tt$drop == "", ]
test <- test[order(test$station_number), ]

# one stations table for every call: every statistic's pool and the test set
in_pool <- sort(unique(unlist(pools)))
st_tab <- rbind(cg[cg$station_number %in% in_pool, c("station_number", "lon", "lat", "drainage_area_gross_km2")],
                test[c("station_number", "lon", "lat", "drainage_area_gross_km2")])
stopifnot(!anyDuplicated(st_tab$station_number))
seg <- rbind(cg[cg$station_number %in% in_pool, c("station_number", "linear_feature_id")],
             test[c("station_number", "linear_feature_id")])
w_need <- rbind(w_cal, w_test)
w_need <- w_need[!duplicated(w_need$linear_feature_id) & w_need$linear_feature_id %in% seg$linear_feature_id, ]
w_need <- w_need[order(w_need$linear_feature_id), ]
subs <- sort(unique(c(w_need$subid, unlist(w_need$upstream_subids))))

# ---- product: begin ----------------------------------------------------------------------------------
# The per-year files against their catalogue and the climatology (the interface section), then
# every gauge's segment routed day by day and its window statistics taken per year.
duck <- DBI::dbConnect(duckdb::duckdb())
files <- file.path(pcic_dir, sprintf("pcic.subbasin_days.%s.%d.parquet", series, years_run))
gone <- years_run[!file.exists(files)]
if (length(gone)) stop("WET_PCIC_YEARS has no ", series, " file for ", paste(gone, collapse = ", "), call. = FALSE)
catalogue <- DBI::dbGetQuery(conn, sprintf("
  SELECT year, crosswalk_md5, commit, rows::text AS rows, subbasins::text AS subbasins,
         q_local_sum::text AS q_local_sum, q_acc_sum::text AS q_acc_sum, bytes::text AS bytes
  FROM pcic.series WHERE (model, scenario) = ('%s', '%s') AND year BETWEEN %d AND %d ORDER BY year",
  routed_run$model, routed_run$scenario, min(years_run), max(years_run)))
if (!identical(as.integer(catalogue$year), years_run)) {
  stop("pcic.series lacks a row for ", paste(setdiff(years_run, catalogue$year), collapse = ", "), call. = FALSE)
}
run_md5 <- DBI::dbGetQuery(conn, sprintf("SELECT crosswalk_md5 FROM pcic.runs WHERE %s", where_run))$crosswalk_md5
stopifnot(length(run_md5) == 1L)
if (any(catalogue$crosswalk_md5 != run_md5)) {
  stop("pcic.series rows for ", paste(catalogue$year[catalogue$crosswalk_md5 != run_md5], collapse = ", "),
       " are on another crosswalk than the ", period_run, " run's", call. = FALSE)
}
days_commit <- unique(catalogue$commit)
if (length(days_commit) != 1L || !grepl("^[0-9a-f]{7,40}$", days_commit)) {
  stop("pcic.series rows for ", period_run, " must name one fwapg commit; they name: ",
       paste(days_commit, collapse = ", "), call. = FALSE)
}
sql_fp <- "SELECT count(*)::VARCHAR AS rows, count(DISTINCT subid)::VARCHAR AS subbasins,
  sum(CAST(floor(CAST(q_local AS DOUBLE) * 1000 + 0.5) AS BIGINT))::VARCHAR AS q_local_sum,
  sum(CAST(floor(CAST(q_acc AS DOUBLE) * 1000 + 0.5) AS BIGINT))::VARCHAR AS q_acc_sum,
  count(*) FILTER (WHERE q_local IS NULL OR q_acc IS NULL OR isnan(q_local) OR isnan(q_acc)) AS bad
  FROM read_parquet('%s')"
for (i in seq_along(files)) {
  f <- DBI::dbGetQuery(duck, sprintf(sql_fp, files[i]))
  got <- c(f$rows, f$subbasins, f$q_local_sum, f$q_acc_sum, format(file.size(files[i]), scientific = FALSE))
  want <- unlist(catalogue[i, c("rows", "subbasins", "q_local_sum", "q_acc_sum", "bytes")])
  if (f$bad > 0 || !identical(unname(got), unname(want))) {
    stop(basename(files[i]), " is not its pcic.series row: file ", paste(got, collapse = " "), ", row ",
         paste(want, collapse = " "), if (f$bad > 0) sprintf(", %d NULL or NaN flows", f$bad), call. = FALSE)
  }
}
f_cat <- tempfile()
writeLines(do.call(paste, catalogue), f_cat)
catalogue_md5 <- unname(tools::md5sum(f_cat))
unlink(f_cat)

# parity: every read sub-basin's bins against pcic.subbasin_daily
sql_par <- "SELECT subid, month(date)::INTEGER AS month, day(date)::INTEGER AS day, count(*)::INTEGER AS n,
  avg(CAST(q_local AS DOUBLE)) AS m_local, avg(abs(CAST(q_local AS DOUBLE))) AS a_local,
  avg(CAST(q_acc AS DOUBLE)) AS m_acc, avg(abs(CAST(q_acc AS DOUBLE))) AS a_acc
  FROM read_parquet([%s]) WHERE subid IN (%s) GROUP BY ALL"
par <- DBI::dbGetQuery(duck, sprintf(sql_par, paste0("'", files, "'", collapse = ", "), paste(subs, collapse = ", ")))
clim <- DBI::dbGetQuery(conn, sprintf("
  SELECT subid, month, day, n_days, q_local, q_acc FROM %s WHERE %s AND subid IN (%s)",
  routed_daily_table, where_run, paste(subs, collapse = ", ")))
pm <- merge(clim, par, by = c("subid", "month", "day"), all = TRUE)
if (anyNA(pm) || nrow(pm) != 366L * length(subs) || any(pm$n != pm$n_days)) {
  stop("the per-year files and pcic.subbasin_daily do not hold the same bins and days for the read sub-basins",
       call. = FALSE)
}
ratio <- pmax(abs(pm$m_local - pm$q_local) / (2^-23 * pm$a_local + 1e-9),
              abs(pm$m_acc - pm$q_acc) / (2^-23 * pm$a_acc + 1e-9))
if (any(ratio > 1)) {
  b <- pm[which.max(ratio), ]
  stop(sum(ratio > 1), " bins fail parity; worst sub-basin ", b$subid, " ", b$month, "-", b$day, call. = FALSE)
}
parity <- list(subbasins = length(subs), bins = nrow(pm), worst = max(ratio),
               max_abs = max(abs(c(pm$m_local - pm$q_local, pm$m_acc - pm$q_acc))))
DBI::dbDisconnect(duck, shutdown = TRUE)

# every gauge's segment, day by day, in chunks of segments, then its window statistics
chunk <- split(seq_len(nrow(w_need)), ceiling(seq_len(nrow(w_need)) / 40))
mws <- do.call(rbind, lapply(chunk, function(i) {
  q <- wet_routed_years(pcic_dir, w_need[i, ], years = years_run, series = series)
  stopifnot(nrow(q) == length(i) * n_days_run)
  m <- wet_window_stats(q, windows, stats = c("mean", "min7", "cov_day"), by = "linear_feature_id")
  m[c("linear_feature_id", "variable", "period", "year", "value")]
}))
# ---- product: end ------------------------------------------------------------------------------------
DBI::dbDisconnect(conn)

mod <- merge(seg, mws, by = "linear_feature_id")[c("station_number", "variable", "period", "year", "value")]
mod <- mod[order(mod$station_number, mod$variable, mod$period, mod$year), ]
rownames(mod) <- NULL
stopifnot(setequal(unique(mod$station_number), seg$station_number))
mod_low <- mod[!is_days(mod$variable) & mod$value <= 0, ]

# ---- series: observed, modelled departures, carried --------------------------------------------------
tr <- function(v, x) if (is_days(v)) x else log(x)
obs_of <- function(g, v, p) {
  o <- obs_vals(v, p)
  o <- o[o$station_number == g, ]
  stats::setNames(tr(v, o$value), o$year)
}
# a modelled departure from the modelled 1981-2010 mean (a constant, cancelled by centring)
pcic_of <- function(g, v, p) {
  m <- mod[mod$station_number == g & mod$variable == v & mod$period == p, ]
  if (!is_days(v)) m <- m[m$value > 0, ]
  b <- m$value[m$year %in% baseline]
  if (!length(b)) return(stats::setNames(numeric(), character()))
  stats::setNames(if (is_days(v)) m$value - mean(b) else log(m$value / mean(b)), m$year)
}
weightings <- c("distance", "covariance", "covariance_pick")
cands2 <- c("donors", "pcic", "blend")
# the target's carried departures under each weighting, from `donors`; the donors used and fallback
carry_all <- function(g, v, p, k, donors) {
  x <- obs_vals(v, p)
  x <- x[x$station_number %in% setdiff(donors, g), ]
  # every statistic, so a station modelled elsewhere but without rows here (no cov_day where routed to 0)
  # reads as no years, r = 0, rather than as missing
  md <- mod[mod$station_number %in% c(g, unique(x$station_number)), ]
  lapply(stats::setNames(weightings, weightings), function(w) {
    a <- wet_departure_carry(x, st_tab, g, k = k, weights = w, modelled = if (w == "distance") NULL else md)
    used <- unique(sub(":.*$", "", unlist(strsplit(a$donors, " ", fixed = TRUE))))
    list(dep = stats::setNames(a$anomaly, a$year), used = used,
         fallback = w != "distance" && identical(unique(a$weighting), "distance"))
  })
}
# the same years for every candidate: the run's years, the gauge's observed years, and every candidate's
score <- function(obs, cands) {
  yrs <- names(obs)[as.integer(names(obs)) %in% years_run]
  for (cc in cands) yrs <- intersect(yrs, names(cc)[!is.na(cc)])
  yrs <- sort(yrs)
  nse <- stats::setNames(rep(NA_real_, length(cands)), names(cands))
  if (length(yrs) >= 3) {
    o <- obs[yrs] - mean(obs[yrs])
    nse <- vapply(cands, function(cc) wet:::wet_nse(o, cc[yrs] - mean(cc[yrs])), numeric(1))
  }
  # one year set per gauge, so every candidate is scored or none is
  stopifnot(all(is.na(nse)) || !anyNA(nse))
  list(n = length(yrs), years = yrs, nse = nse)
}
stage2_cands <- function(r, ship, w = w_blend) {
  d <- r$carried[[ship]]$dep
  pc <- r$pcic
  yy <- intersect(names(d), names(pc))
  list(donors = d, pcic = pc, blend = stats::setNames(w * d[yy] + (1 - w) * pc[yy], yy))
}

# leak-free: the pool gauges upstream or downstream of each gauge (either direction)
up <- matrix(FALSE, nrow(cg), nrow(cg))
for (i in seq_len(nrow(cg))) up[i, ] <- wet:::wet_fwa_upstream(cg$wscode[i], cg$localcode[i], cg$wscode, cg$localcode)
diag(up) <- FALSE
rel <- up | t(up)
dimnames(rel) <- list(cg$station_number, cg$station_number)
related <- lapply(stats::setNames(cg$station_number, cg$station_number), function(g) colnames(rel)[rel[g, ]])
colocated <- sum(duplicated(paste(cg$wscode, cg$localcode)[cg$station_number %in% mig_pool]))

# every series for one statistic, k and donor rule; targets are a pool's gauges (leave one out) or the test set
run_set <- function(v, p, k, leakfree = FALSE, targets = NULL) {
  pool <- pools[[paste(v, p)]]
  test_mode <- !is.null(targets)
  if (!test_mode) targets <- pool
  lapply(stats::setNames(targets, targets), function(g) {
    donors <- setdiff(pool, c(g, if (leakfree) related[[g]]))
    list(obs = obs_of(g, v, p), pcic = pcic_of(g, v, p), carried = carry_all(g, v, p, k, donors))
  })
}
scores_stage1 <- function(rs) {
  lapply(rs, function(r) score(r$obs, lapply(r$carried, `[[`, "dep")))
}
scores_stage2 <- function(rs, ship, w = w_blend) lapply(rs, function(r) score(r$obs, stage2_cands(r, ship, w)))
tab_of <- function(sc, cands) {
  if (!length(sc)) {  # an empty set reports "-" for every candidate rather than stopping before the report
    na <- stats::setNames(rep(NA_real_, length(cands)), cands)
    return(list(nse = matrix(numeric(), 0, length(cands), dimnames = list(NULL, cands)), n_scored = 0L,
                n_not = 0L, med = na, q25 = na, q75 = na))
  }
  nse <- do.call(rbind, lapply(sc, `[[`, "nse"))
  stopifnot(identical(colnames(nse), cands))
  keep <- stats::complete.cases(nse)
  list(nse = nse[keep, , drop = FALSE], n_scored = sum(keep), n_not = sum(!keep),
       med = apply(nse[keep, , drop = FALSE], 2, stats::median),
       q25 = apply(nse[keep, , drop = FALSE], 2, stats::quantile, 0.25, names = FALSE),
       q75 = apply(nse[keep, , drop = FALSE], 2, stats::quantile, 0.75, names = FALSE))
}
# one challenger, chosen on the leave-one-out median (a tie to the first listed), which must clear the
# incumbent by the margin under both pools
decide <- function(t_logo, t_lf, incumbent, challengers) {
  ch <- challengers[which.max(t_logo$med[challengers])]
  gain <- c(logo = t_logo$med[[ch]] - t_logo$med[[incumbent]], leakfree = t_lf$med[[ch]] - t_lf$med[[incumbent]])
  list(challenger = ch, gain = gain, ship = if (all(gain >= margin - eps)) ch else incumbent)
}

# ---- the main run: migration mean, k = 5 --------------------------------------------------------------
main <- run_set("q_mean", "migration", k_main)
main_lf <- run_set("q_mean", "migration", k_main, leakfree = TRUE)
t1 <- tab_of(scores_stage1(main), weightings)
t1_lf <- tab_of(scores_stage1(main_lf), weightings)
d1 <- decide(t1, t1_lf, "distance", c("covariance", "covariance_pick"))
t2 <- tab_of(scores_stage2(main, d1$ship), cands2)
t2_lf <- tab_of(scores_stage2(main_lf, d1$ship), cands2)
d2 <- decide(t2, t2_lf, "donors", c("pcic", "blend"))

# ---- the test set, the sensitivities and the counts ----------------------------------------------------
tst <- run_set("q_mean", "migration", k_main, targets = test$station_number)
sc_t1 <- scores_stage1(tst)
sc_t2 <- scores_stage2(tst, d1$ship)
tt1 <- tab_of(sc_t1, weightings)
tt2 <- tab_of(sc_t2, cands2)

sens <- list()
add_sens <- function(label, rs, w = w_blend) {
  a <- tab_of(scores_stage1(rs), weightings)
  b <- tab_of(scores_stage2(rs, d1$ship, w), cands2)
  sens[[length(sens) + 1]] <<- list(label = label, n = a$n_scored, s1 = a$med, n2 = b$n_scored, s2 = b$med)
}
for (k in k_sens) add_sens(sprintf("k = %d", k), run_set("q_mean", "migration", k))
by_statistic <- list(`q_mean migration` = main)
for (i in seq_len(nrow(stats_all))[-1]) {
  rs <- run_set(stats_all$v[i], stats_all$p[i], k_main)
  by_statistic[[paste(stats_all$v[i], stats_all$p[i])]] <- rs
  add_sens(sprintf("%s %s", stats_all$p[i], sub("^q_", "", stats_all$v[i])), rs)
}
for (w in w_blend_sens) add_sens(sprintf("blend %.2f donors", w), main, w)

# PCIC's own skill on the stage-2 years of the main run: centred NSE and correlation
sc2_main <- scores_stage2(main, d1$ship)
skill <- do.call(rbind, lapply(names(sc2_main), function(g) {
  s <- sc2_main[[g]]
  if (anyNA(s$nse)) return(NULL)
  o <- main[[g]]$obs[s$years]
  data.frame(station_number = g, n = s$n, nse = s$nse[["pcic"]], r = stats::cor(o, main[[g]]$pcic[s$years]))
}))
skill <- merge(skill, cg[c("station_number", "nesting", "area_class")], by = "station_number")
skill$basin <- routed_basin(skill$station_number)

# fallbacks, short r and the distance to the donors used, on the main run
fallbacks <- vapply(c("covariance", "covariance_pick"), function(w) {
  sum(vapply(main, function(r) r$carried[[w]]$fallback, logical(1)))
}, integer(1))
n_common <- function(a, b) {
  m <- mod[mod$variable == "q_mean" & mod$period == "migration" & mod$value > 0, ]
  length(intersect(m$year[m$station_number == a], m$year[m$station_number == b]))
}
short_r <- vapply(c("covariance", "covariance_pick"), function(w) {
  sum(unlist(lapply(names(main), function(g) {
    vapply(main[[g]]$carried[[w]]$used, function(d) n_common(g, d) < length(years_run), logical(1))
  })))
}, integer(1))
xy <- terra::project(cbind(st_tab$lon, st_tab$lat), "EPSG:4326", "EPSG:3005") / 1000
rownames(xy) <- st_tab$station_number
km_used <- vapply(weightings, function(w) {
  stats::median(vapply(names(main), function(g) {
    u <- main[[g]]$carried[[w]]$used
    mean(sqrt((xy[u, 1] - xy[g, 1])^2 + (xy[u, 2] - xy[g, 2])^2))
  }, numeric(1)))
}, numeric(1))
low_by <- table(paste(mod_low$period, sub("^q_", "", mod_low$variable)))
low_gauges <- sort(unique(mod_low$station_number[mod_low$variable == "q_mean" & mod_low$period == "migration"]))

# ---- the report -----------------------------------------------------------------------------------------
med_line <- function(t, nm) {
  sprintf("  %-16s %5d %7s %7s %7s", nm, t$n_scored, fmt(t$q25[[nm]]), fmt(t$med[[nm]]), fmt(t$q75[[nm]]))
}
say("# PCIC's per-year routed flow against donor-carried departures (#122)", "",
    sprintf("Rule registered in scripts/departure_pcic.R's header at %s, amended before any candidate at %s (distance weight) and %s (the fwapg#42 interface), and before any run on the product at %s (the files' commit from pcic.series).",
            rule_commits[["registered"]], rule_commits[["weight_amended"]], rule_commits[["interface_amended"]],
            rule_commits[["commit_amended"]]),
    sprintf("wet commit %s (script md5 %s); HYDAT %s, approved daily flows only; fit %s, scoring code %s.",
            wet_commit, code_md5, release, release, score_code_md5),
    routed_report_line(fwapg_commit, period_run),
    sprintf("daily tables: %s", daily_fp),
    sprintf("per-year files: %d of %s (%d-%d), built by NewGraphEnvironment/fwapg at %s (pcic.series); rows md5 %s.",
            length(files), series, min(years_run), max(years_run), days_commit, catalogue_md5),
    sprintf("parity: %d sub-basins, %d bins; worst deviation %s of the bound (2^-23 x mean |v| + 1e-9 m3/s); largest %s m3/s.",
            parity$subbasins, parity$bins, formatC(parity$worst, format = "g", digits = 2),
            formatC(parity$max_abs, format = "g", digits = 2)),
    sprintf("Windows (CH): %s. Statistic deciding: migration-window mean, log departure. k = %d; margin %s.",
            paste(sprintf("%s %s..%s", windows$window, windows$start, windows$end), collapse = ", "), k_main, margin),
    "", "## 1. The pool", "",
    sprintf("Calibration gauges: %d. With a pcic.segment_weights row on their segment: %d (with a pcic.discharge_monthly row, #58's definition: %d).",
            nrow(cg), sum(cg$covered), n_58),
    sprintf("Pool per statistic (>= 10 baseline years with a value): %s.",
            paste(sprintf("%s %d", names(pools), lengths(pools)), collapse = "; ")),
    sprintf("Migration-mean pool: %d gauges; co-located pairs (same codes): %d; leak-free removes on average %s donors.",
            length(mig_pool), colocated, fmt(mean(lengths(lapply(related[mig_pool], intersect, mig_pool))), 1)),
    sprintf("Modelled window-years <= 0, dropped from logs: %s. Migration-mean gauges with one or more: %s.",
            if (length(low_by)) paste(sprintf("%s %d", names(low_by), as.integer(low_by)), collapse = "; ") else "none",
            if (length(low_gauges)) paste(low_gauges, collapse = ", ") else "none"),
    "", "## 2. Stage 1: how donors are weighted", "",
    "Median per-gauge NSE of centred log migration-window means, held out, on years every candidate has:", "",
    sprintf("  %-16s %5s %7s %7s %7s", "leave-one-out", "n", "q25", "median", "q75"),
    vapply(weightings, function(nm) med_line(t1, nm), ""),
    sprintf("  not scored (fewer than 3 years): %d", t1$n_not), "",
    sprintf("  %-16s %5s %7s %7s %7s", "leak-free", "n", "q25", "median", "q75"),
    vapply(weightings, function(nm) med_line(t1_lf, nm), ""),
    sprintf("  not scored (fewer than 3 years): %d", t1_lf$n_not), "",
    sprintf("Challenger %s: %s over distance under leave-one-out, %s leak-free; margin %s. SHIPS: %s.",
            d1$challenger, fmt(d1$gain[["logo"]], 3), fmt(d1$gain[["leakfree"]], 3), margin, d1$ship),
    sprintf("Fell back to distance (every chosen donor weighing 0): covariance %d, covariance_pick %d targets.",
            fallbacks[["covariance"]], fallbacks[["covariance_pick"]]),
    sprintf("Target-donor pairs used whose r rests on fewer than %d years: covariance %d, covariance_pick %d.",
            length(years_run), short_r[["covariance"]], short_r[["covariance_pick"]]),
    sprintf("Median over targets of the mean distance to the donors used (km): %s.",
            paste(sprintf("%s %s", weightings, fmt(km_used, 0)), collapse = ", ")),
    "", sprintf("## 3. Stage 2: donors (%s), PCIC or a blend", d1$ship), "",
    sprintf("  %-16s %5s %7s %7s %7s", "leave-one-out", "n", "q25", "median", "q75"),
    vapply(c("donors", "pcic", "blend"), function(nm) med_line(t2, nm), ""),
    sprintf("  not scored (fewer than 3 years): %d", t2$n_not), "",
    sprintf("  %-16s %5s %7s %7s %7s", "leak-free", "n", "q25", "median", "q75"),
    vapply(c("donors", "pcic", "blend"), function(nm) med_line(t2_lf, nm), ""),
    sprintf("  not scored (fewer than 3 years): %d", t2_lf$n_not), "",
    sprintf("Challenger %s: %s over donors under leave-one-out, %s leak-free; margin %s. SHIPS: %s.",
            d2$challenger, fmt(d2$gain[["logo"]], 3), fmt(d2$gain[["leakfree"]], 3), margin, d2$ship),
    sprintf("pcic minus donors, median NSE: %s leave-one-out, %s leak-free (the informative outcome; blend is favoured by averaging alone).",
            fmt(t2$med[["pcic"]] - t2$med[["donors"]], 3), fmt(t2_lf$med[["pcic"]] - t2_lf$med[["donors"]], 3)),
    "After 2012 only donors carry values, whatever ships.",
    "Limit: PCIC publishes no calibration gauges, so pcic's score at a calibration gauge may be partly in sample; donors are always held out.",
    "", "## 4. The short-record test set (deciding nothing)", "",
    sprintf("Candidates: %d from the stations rds test set, %d from #120's box short-record rule (%d in both). Dropped: %s.",
            sum(tt$from != "#120 box short-record"), sum(tt$from != "stations rds test"), sum(tt$from == "both"),
            paste(sprintf("%s %d", names(table(tt$drop[tt$drop != ""])), as.integer(table(tt$drop[tt$drop != ""]))),
                  collapse = "; ")),
    sprintf("Kept: %d; scored: %d. Median NSE: %s.", nrow(test), tt1$n_scored,
            paste(c(sprintf("%s %s", weightings, fmt(tt1$med[weightings])),
                    sprintf("%s %s", c("donors", "pcic", "blend"), fmt(tt2$med[c("donors", "pcic", "blend")]))),
                  collapse = ", ")),
    "", sprintf("  %-8s %-21s %3s %8s %8s %8s %8s %8s %8s", "station", "from", "n", "distance", "covar", "cov_pick",
                "donors", "pcic", "blend"))
for (g in test$station_number) {
  a <- sc_t1[[g]]
  b <- sc_t2[[g]]
  say(sprintf("  %-8s %-21s %3d %8s %8s %8s %8s %8s %8s%s", g, test$from[test$station_number == g], a$n,
              fmt(a$nse[["distance"]]), fmt(a$nse[["covariance"]]), fmt(a$nse[["covariance_pick"]]),
              fmt(b$nse[["donors"]]), fmt(b$nse[["pcic"]]), fmt(b$nse[["blend"]]), if (g == maxan) "  <- Maxan" else ""))
}
if (!maxan %in% test$station_number) {
  say(sprintf("  %s is not in the test set: %s.", maxan,
              if (maxan %in% tt$station_number) tt$drop[tt$station_number == maxan] else "not a candidate"))
}
say("", "## 5. Sensitivities (reported, unable to ship)", "",
    sprintf("  %-26s %4s %8s %8s %8s %4s %8s %8s %8s", "setting", "n", "distance", "covar", "cov_pick", "n",
            "donors", "pcic", "blend"))
for (s in sens) {
  say(sprintf("  %-26s %4d %8s %8s %8s %4d %8s %8s %8s", s$label, s$n, fmt(s$s1[["distance"]]),
              fmt(s$s1[["covariance"]]), fmt(s$s1[["covariance_pick"]]), s$n2, fmt(s$s2[["donors"]]),
              fmt(s$s2[["pcic"]]), fmt(s$s2[["blend"]])))
}
say("", "PCIC's own skill on the stage-2 years (median centred NSE, median correlation):", "",
    sprintf("  %-22s %4s %7s %7s", "group", "n", "NSE", "r"))
for (grp in c("basin", "area_class", "nesting")) {
  lvs <- if (is.factor(skill[[grp]])) levels(skill[[grp]]) else sort(unique(skill[[grp]]))
  for (lv in lvs[lvs %in% as.character(skill[[grp]])]) {
    x <- skill[as.character(skill[[grp]]) == lv, ]
    say(sprintf("  %-22s %4d %7s %7s", lv, nrow(x), fmt(stats::median(x$nse)), fmt(stats::median(x$r))))
  }
}
say("", "## 6. Per gauge, migration mean, leave-one-out", "",
    sprintf("  %-8s %-9s %-10s %-9s %3s %8s %8s %8s %8s %8s %8s", "station", "basin", "area", "nesting", "n",
            "distance", "covar", "cov_pick", "donors", "pcic", "blend"))
sc1_main <- scores_stage1(main)
for (g in mig_pool) {
  a <- sc1_main[[g]]
  b <- sc2_main[[g]]
  say(sprintf("  %-8s %-9s %-10s %-9s %3d %8s %8s %8s %8s %8s %8s", g, routed_basin(g),
              as.character(cg$area_class[cg$station_number == g]), cg$nesting[cg$station_number == g], a$n,
              fmt(a$nse[["distance"]]), fmt(a$nse[["covariance"]]), fmt(a$nse[["covariance_pick"]]),
              fmt(b$nse[["donors"]]), fmt(b$nse[["pcic"]]), fmt(b$nse[["blend"]])))
}
writeLines(out, report)
message("report: ", report)

# ---- for #130: the series behind the report, after it -------------------------------------------------------
dir.create(dirname(rds), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(release = release, ship = c(stage1 = d1$ship, stage2 = d2$ship), k_main = k_main, baseline = baseline,
             rule_commits = rule_commits, wet_commit = wet_commit, fwapg_commit = fwapg_commit,
             days_commit = days_commit, catalogue_md5 = catalogue_md5, code_md5 = code_md5,
             main = main, main_leakfree = main_lf, by_statistic = by_statistic, test = tst, test_stations = test,
             ws = ws[ws$station_number %in% seg$station_number, ], mod = mod), rds)
message("series: ", rds)
