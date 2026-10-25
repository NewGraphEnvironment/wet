# Maxan Creek Chinook pilot (#120, component 1 of #118): extend a short-record
# gauge's window flows from its long-record neighbours, with an error per year,
# and score donor-carried departures held out at every gauge in the region.
# The rule below was fixed in this header, and committed alone, before any
# candidate was coded or scored; the body that runs it came later
# (planning/archive, issue 120).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_pilot.R
#
# Reads HYDAT 20260717 only (scripts/wb_fit_lib.R's wb_hydat(), wet's
# per-user cache), and fwapg through the PG* env vars for the leak-free
# sensitivity alone. Writes the tracked report
# data/checks/departure_pilot_20260717.txt and nothing else. Nothing is
# published, no fit is read or touched: 08EE018 and 08EE003 are not
# calibration gauges, and 08EE013 is used here only as a HYDAT record.
#
# ---- decided at the plan gate (user, 2026-10-24) ---------------------------------------------
#
# Windows: the CH rows of inst/vignette-data/life_history_bulk.csv,
#   migration 05-01..08-01 and spawning 08-01..09-15, both days inclusive.
# Statistics: wet_window_stats() mean, min7 and cov_day per window; max is
#   computed and reported, never scored.
# Periods: baseline 1981-2010 (as #25); before/after is the mean departure
#   over the years before 1981 against 2011-2025; cd::cd_trend() over the
#   whole extended record.
# Scale: a departure is a log ratio, log(value / baseline mean), the baseline
#   mean being the arithmetic mean of the 1981-2010 values (cd_baseline()'s
#   mean); it is reported as % of normal, 100 * (exp(departure) - 1).
#   cov_day is a day of the window, so its departure is a difference in days.
# Source: HYDAT release 20260717, approved daily flows only
#   (wet_station_daily(sources = "hydat")); no provisional or real-time day.
#
# ---- the pool ----------------------------------------------------------------------------------
#
# The box: BC HYDAT gauges (PROV_TERR_STATE_LOC = "BC") with STN_REGULATION
# REGULATED = 0, inside lon -128.8..-125.0 and lat 53.6..55.8 (Bulkley,
# Morice, Babine, Kispiox, Zymoetz, Kitimat, Nechako headwaters; the issue's
# "Bulkley and neighbouring watershed groups"). A complete window-year is a
# row wet_window_stats() returns at its default min_frac = 0.8 (at least 80 %
# of the window's days present, the window inside the record); for cov_day
# it is a window-year with every day present, which wet_window_stats() alone
# returns, so cov_day's years are its own. A gauge with no drainage area or
# no coordinates in STATIONS is excluded and counted.
#
#   box pool         natural box gauges with >= 3 complete migration-window
#                    years. Predictor scaling and the short-record set come
#                    from it.
#   extension pool   box-pool gauges with >= 30 complete migration-window
#                    years and at least one run of 5 consecutive complete
#                    years. Question 1's donors and its test gauges.
#   departure pool   box-pool gauges with >= 10 complete window-years of the
#                    statistic inside 1981-2010, so the gauge's own baseline
#                    is defined. Question 2's donors and its held-out gauges,
#                    per window and statistic; the counts on the migration
#                    mean are the headline ones.
#   short-record     box-pool gauges with 3..10 complete migration-window
#                    years (08EE018 among them). Scored from the full
#                    departure pool, separately from it.
#
# Predictors, as #70 and #102: easting and northing in km (the station's
# STATIONS lon/lat projected to EPSG:3005) and log drainage area (km2), each
# divided by its SD over the box pool. Distance is Euclidean in that space.
# k = 5 nearest; k = 3 and k = 8 are reported sensitivities.
#
# Donor availability per year (plan review item 1). Extension: the donors are
# the k nearest extension-pool gauges (target excluded) that have a value in
# every one of the target's observed years, ordered by distance; in each year
# to be extended, the nearest of them with a value that year supplies it, and
# a year none of them has stays missing. Each donor's relation is fitted on
# the target's observed years. Carried departures: the k nearest
# departure-pool gauges (target excluded), fixed once by distance; their
# inverse-distance weights are wet_donor_mean()'s (1 / (d + 1e-6 * median d),
# a donor at distance 0 taking the whole weight); a donor without a value in
# a year is dropped for that year and the remaining weights renormalised to
# sum 1; a year with no donor present is missing. wet_departure_carry() does
# the renormalisation; wet_donor_mean()'s contract, shared with #70 and #102,
# is unchanged.
#
# Both functions take the window values in wet_window_stats()'s long format
# and a station table in wet_station_select()'s shape (station_number, lon,
# lat, drainage_area_gross_km2) for the predictors.
#
# ---- question 1: record extension, wet_window_extend() ----------------------------------------
#
# Candidates, every setting fixed here. x is the donor's value and y the
# target's in the same year, both log for mean and min7, days for cov_day; n
# is the number of the target's observed years.
#
#   (a) ols     OLS of y on x over the observed years; the point is the
#               fitted line (back-transformed with exp(), the median, for a
#               log statistic); the 90 % interval is OLS's prediction
#               interval, t(0.95, n - 2) * s * sqrt(1 + 1/n + (x0 - mean x)^2
#               / Sxx), with n - 2 degrees of freedom.
#   (b) move1   the line of organic correlation (MOVE.1): y = mean y +
#               sign(r) * (sd y / sd x) * (x - mean x), which keeps the
#               target's variance where OLS shrinks it.
#   (c) ratio   the incumbent: target value = donor value * (mean of the
#               target's observed values / mean of the donor's in the same
#               years), means taken on the original scale (m3/s; days for
#               cov_day), a ratio of means, not a mean of ratios.
#
# Intervals for (b) and (c) are the 5th and 95th percentiles of the residuals
# (observed minus predicted, log or days) on the held-out years of the OTHER
# extension-pool gauges' pseudo-records (leave-gauge-out), so a gauge's own
# residuals never set its interval. One nominal level, 90 %, for all three.
#
# Reported sensitivities, unable to ship (a winning sensitivity is a new rule
# in a new issue):
#   multi-donor OLS on the min(k, n - 2) nearest covering donors, a year
#     needing every one of them;
#   (d) day by day: OLS of the target's log daily flow on the nearest covering
#     donor's same-day log flow over the window days of the observed years
#     (days with flow <= 0 dropped), the extended days back-transformed and the
#     window statistic taken from them with wet_window_stats() (the issue's
#     "day by day");
#   k = 3 and 8; the spawning window; min7 and cov_day; leak-free (below).
#
# The test. At every extension-pool gauge, its complete migration-window
# years are cut into pseudo-short records: within each maximal run of
# consecutive complete years, non-overlapping blocks of 5 from the run's first
# year (tiled; a remainder shorter than 5 is not one). Each block is the
# gauge's observed record; the gauge is extended from the other
# extension-pool gauges under the donor rule above and scored on its
# HELD-OUT years only, its complete years outside the block, over the years
# every candidate (a), (b), (c) has a value for. A gauge with no block is
# dropped and counted; a block with fewer than 3 held-out years scored is
# dropped and counted. The score is wet:::wet_nse() of predicted against
# observed log migration-window mean. Per gauge, the median NSE over its
# blocks; the median over gauges decides.
#
# The rule: the candidate with the highest median ships for Maxan if that
# median exceeds (c)'s by at least 0.01 (unrounded, 1e-9 allowed for floating
# point; #16's margin); otherwise (c) ships. NSE 0 is the observed years' mean
# repeated, the margin of no skill. Reported beside it, deciding nothing:
# coverage of each candidate's 90 % interval on held-out years; the same test
# on the spawning window, min7 and cov_day (cov_day scored on days, NSE of
# predicted against observed day; a window-year whose mean or min7 is <= 0 is
# dropped from a log score and counted); the sensitivities; and at 08EE018,
# leave-one-year-out over its observed years (fit on the rest, predict the
# one left out) for each candidate.
#
# ---- question 2: donor-carried departures, wet_departure_carry() ------------------------------
#
# Each donor's log departure per year from its own 1981-2010 baseline mean;
# carried onto the target as the per-year weighted mean of its k donors under
# the availability rule above. The target's own value is given only where it
# has its own baseline (>= 10 baseline years).
#
# The test. Leave-one-gauge-out at every departure-pool gauge: its donors are
# the departure pool without it. The carried series is scored against the
# gauge's observed log values over the years both have, BOTH SERIES CENTRED
# ON THEIR MEAN OVER THOSE YEARS (in log space), so no target baseline is
# needed and a short-record gauge is scored the same way (plan review item 3).
# Score: wet:::wet_nse() per gauge; a gauge with fewer than 3 such years is
# not scored and is counted. NSE 0 is "no departure" (climatology), the
# margin the issue asks about. The short-record gauges are scored the same
# way from the full departure pool, separately.
#
# No ship decision: the question is whether a carried departure tracks the
# target's. The report gives the median per-gauge NSE over the departure pool
# on the migration-window mean, with its quartiles, as the headline, and the
# short-record median beside it. The method is USABLE for #122's competition
# if that departure-pool median is >= 0.5; the threshold is set here so #122
# inherits it rather than choosing it after seeing the number. Reported,
# deciding nothing: the spawning window, min7 and cov_day (centred days),
# k = 3 and 8, and leak-free.
#
# ---- leak-free sensitivity (both questions) ---------------------------------------------------
#
# Houston (08EE003) and Quick (08EE004) contain Maxan. When the PG* env vars
# reach an fwapg database, the box pool is snapped with wet_station_snap()
# and a held-out gauge's upstream and downstream gauges
# (wet:::wet_fwa_upstream() on wscode and localcode, either direction) are
# removed from its donors, every candidate refitted. A gauge whose snap is not
# accepted keeps all its donors and is counted. Without a database the report
# says "not run". It decides nothing.
#
# ---- the Maxan answer (reported, deciding nothing beyond question 1's ship) -------------------
#
# 08EE018's migration and spawning series per statistic, observed in its own
# years and extended by the shipped question-1 candidate in every other year
# its donor chain reaches up to 2025, with the 90 % interval and the donor per
# year. Its departures from the extended series' own 1981-2010 mean. Beside it
# the carried route, departures only, and the two routes compared as centred
# departures over the observed years and over the record. The before/after:
# mean departure 2011-2025 minus mean departure before 1981, in log units and
# % of normal, with a 90 % interval from 2000 bootstrap draws that resample
# years within each period and add to each extended year a residual drawn from
# the shipped candidate's leave-gauge-out residuals (observed years add none);
# set.seed(120). The limit stated in the report: the years before 1961 rest on
# the one or two donors in the chain that reach them. cd::cd_baseline(),
# cd_anomaly() (% of normal, cd's cap of 200) and cd_trend() on the extended
# series, from its first year and from 1981.
#
# ---- what it refuses ----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; a target or donor with fewer than 3
# complete window-years in common (wet_window_extend()); a donor with fewer
# than 10 baseline years (wet_departure_carry()); an extension pool with
# fewer than 15 gauges holding a pseudo-record; pilot-gauge counts that differ
# from the issue's table (08EE018 5, 08EE013 51, 08EE003 43 or 44, the report
# fixing which). The report carries no timestamp, so a rerun reproduces it
# byte for byte.
