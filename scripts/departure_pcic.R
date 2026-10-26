# PCIC's per-year routed flow against donor-carried departures (#122,
# component 3 of #118): weight donor gauges by how PCIC's modelled years move
# together, then score donors, PCIC's own years and a blend of the two, held
# out at every calibration gauge PCIC covers, 1951-2012. The rule below was
# fixed in this header, and committed alone, before any candidate was coded or
# scored; the body that runs it came later (planning/archive, issue 122). The
# report names the commit this header was registered at.
#
#   WET_HYDAT_RELEASE=20260717 WET_FWAPG_COMMIT=<sha> WET_FWAPG_DAYS_COMMIT=<sha> \
#     WET_PCIC_YEARS=<dir> Rscript scripts/departure_pcic.R
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
# for the 1951-2012 run. The catalogue names no commit, as pcic.runs names
# none, so WET_FWAPG_DAYS_COMMIT names the fwapg commit that built the files,
# as WET_FWAPG_COMMIT names the one that built the Postgres tables. The report
# prints both commits and the md5 of the 62 catalogue rows.
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
# guards); WET_FWAPG_DAYS_COMMIT unset or not 7 to 40 hex characters; a year
# of 1951-2012 without its file, or a file unlike its pcic.series row, or a
# row on another crosswalk than the run's; a read sub-basin missing from a
# year, without its 22,646 days of 1951-2012, with a day twice or an NA flow,
# or failing parity in any bin; 1951-2012 tables that differ from
# pcic.runs; a migration-mean pool under 100 gauges; a stage whose
# candidates are not scored at the same gauges on the same years. The report
# carries no timestamp, so a rerun on the same inputs reproduces it byte for
# byte.
