# Snow and the window flows at the Maxan pilot (#121, component 2 of #118):
# regress the Chinook migration- and spawning-window flows at 08EE003 (Bulkley
# near Houston), 08EE013 (Buck Creek) and 08EE018 (Maxan Creek, extended and
# carried by the #120 pilot) on each year's ERA5-Land peak snow water
# equivalent and 50 % melt date over the gauge's own watershed. The
# specification below was fixed in this header, and committed alone, before
# any body code was written (planning/archive, issue 121). Nothing is chosen:
# every fit is reported, nothing ships, nothing is published and no fit is
# read or touched.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_snow.R
#
# Inputs:
#   - data/departure/departure_pilot_20260717.rds (gitignored), written by
#     scripts/departure_pilot.R after its report: Maxan's extended and carried
#     series per statistic and window (`mx`), the pilot gauges' window
#     statistics before the pilot's value > 0 filter, `release`, `ship` (the
#     question-1 candidate the pilot's rule shipped), `k_main`, `baseline`,
#     `level`, and `code_md5` (tools::md5sum of scripts/departure_pilot.R).
#   - HYDAT 20260717 (scripts/wb_fit_lib.R's wb_hydat(), wet's per-user
#     cache), for the gauges' coordinates and drainage areas and the window
#     statistics guard.
#   - fwapg through the WET_PG* env vars, as every other wet script
#     (WET_PGHOST, WET_PGPORT, WET_PGDATABASE, WET_PGUSER, WET_PGPASSWORD,
#     defaulting to localhost:5432 fwapg postgres). The pilot alone reads
#     libpq's bare PG* for its leak-free sensitivity; this script does not.
#   - cd's annual ERA5-Land snow layers (cd::cd_catalog(), period "annual",
#     fetched once with cd::cd_cache_fetch()); the report gives each file's
#     CD_RUN_TIME and CD_SHA tags.
#   - The shipped snow normals data/snow/snow_19812010_*.tif (gitignored,
#     local), for the parity line only.
# Output: the tracked report data/checks/departure_snow_20260717.txt and
# nothing else. It carries no timestamp, so a rerun reproduces it byte for
# byte.
#
# ---- the watersheds ----------------------------------------------------------------------------
#
# Each gauge is snapped with wet_station_snap() from its STATIONS lon, lat and
# gross drainage area; the snap must be accepted and land on the fundamental
# watershed found at the plan (08EE003 7653689, 08EE013 7619666, 08EE018
# 9939958). Its watershed is every fundamental watershed upstream of it:
# fwa_watersheds_poly b joined to the gauge's polygon a on
# FWA_Upstream(a.wscode_ltree, a.localcode_ltree, b.wscode_ltree,
# b.localcode_ltree) with b.wscode_ltree <@ a.wscode_ltree
# (scripts/upstream_area_check.R), the gauge's own polygon included. Houston
# contains Buck and Maxan; each watershed is sampled on its own.
#
# ---- the predictors ----------------------------------------------------------------------------
#
# wet_snow_annual() over each watershed's polygons (dissolved, then sampled
# once with wet_ws_sample(method = "area")), every year 1950-2025, for
# swe_max (mm, capped per cell and year at 3,000 mm), snowmelt_doy_50 (day of
# year) and snowmelt_rate_peak (mm/wk). In the models swe_max enters per
# 100 mm and snowmelt_doy_50 per 10 days, each centred on the watershed's own
# 1981-2010 mean, so a fit's intercept is the departure in a year of normal
# snow; snowmelt_rate_peak is reported per year and is in no model. The report refuses a year whose cover is below 1
# at any gauge (none was found at the plan: no band has an NA cell over the
# pilot box).
#
# ---- the responses (8 series) ------------------------------------------------------------------
#
# The window mean only (wet_window_stats()'s q_mean), in the migration
# (05-01..08-01) and spawning (08-01..09-15) windows, as the pilot defines
# them. Each response is a log departure, so log flow and its departure share
# every slope.
#
#   (i)   08EE003 and 08EE013 observed: log(value / m), m the arithmetic mean
#         of the gauge's complete window-years in 1981-2010 (at least 10;
#         08EE003 has 18 migration years, 1981-1998, and 08EE013 30), from
#         the rds's window statistics (HYDAT 20260717 approved days, a complete window-year as
#         the pilot defines it). A window-year whose mean is <= 0 is dropped
#         and counted.
#   (ii)  08EE018 extended, under the pilot's shipped route (`ship`, read
#         from the rds and reported, not assumed): `mx[["q_mean <window>"]]$e$dep`,
#         the departure from the extended series' own 1981-2010 mean. Every
#         one of those years is extended, Maxan's observed years being
#         1975-1979. The donor of each extended year is listed.
#   (iii) 08EE018 carried: `mx[["q_mean <window>"]]$a$anomaly`, the
#         donor-carried log departure (wet_departure_carry(), k = 5).
#
# ---- the models (24 fits) ----------------------------------------------------------------------
#
# Per series, three OLS fits (stats::lm()): departure ~ swe + doy,
# departure ~ swe, departure ~ doy, each over the same years: every year in
# 1950-2025 with a response and both predictors (no series reaches 2025;
# Maxan's extension ends 2024). Extended years before 1950 are excluded and
# counted. Reported per fit: each coefficient with its 90 % interval
# (confint(fit, level = 0.9), t), residual SE, R2, n, and the lag-1
# autocorrelation of the residuals over pairs of consecutive years both in the
# fit (08EE003 has no complete window 1999-2010, so its gap contributes no
# pair), with the number of pairs; per series, the correlation of the two
# predictors over the fit's years. No fit, predictor or series is chosen.
#
# Reported beside the fits, deciding nothing:
#   - per year, each watershed's swe_max, snowmelt_doy_50 and
#     snowmelt_rate_peak, and each series' departure (and Maxan's donor);
#   - each watershed's mean swe_max and snowmelt_doy_50 over 2011-2025 against
#     1950-1980, beside the pilot's before/after on the extended and carried
#     migration and spawning means (`mx[[...]]$diff`, `$carried`; the pilot's
#     "before" runs from 1931 where its series does).
#
# ---- the parity line ---------------------------------------------------------------------------
#
# Over each watershed, the 1981-2010 mean of wet_snow_annual()'s per-year
# swe_max and snowmelt_doy_50 against the shipped normals grid
# (data/snow/snow_19812010_*.tif, exactly one file, as scripts/wb_province.R
# finds it) sampled over the same dissolved watershed with
# wet_ws_sample(method = "area"). A per-cell mean commutes with an
# area-weighted mean over full-cover cells, and the cap never binds in the
# pilot box (largest swe_max 1,783 mm), so the difference is the normals'
# bilinear resampling onto the 30-arcsecond grid alone, provided the normals
# were built from the bands read here. That proviso is checked: the report
# says whether wet_snow_normals(<the shipped grid>, dir = tempdir(),
# catalog = <the files read here>) reproduces the shipped file's name, which
# is its cache key over the bands' values. With no file the report says
# "parity not run" and the rest proceeds; with more than one it stops.
#
# ---- what it refuses ---------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; no pilot rds; an rds whose `release`
# is not 20260717 or whose `code_md5` is not the current
# scripts/departure_pilot.R's (rerun the pilot); a snap not accepted or not on
# the fundamental watershed above; a year with cover below 1; the pilot
# gauges' window statistics in the rds differing from wet_window_stats()
# recomputed from HYDAT for them (all.equal(), the pilot's windows and
# statistics); counts other than these:
#   - 08EE018 extended migration mean: n = 75 (1950-2024, every year, the
#     tracked pilot report's per-year table);
#   - 08EE003 and 08EE013: n in each window equals the complete window-years
#     in the tracked pilot report's pool table (08EE003 44 migration and 44
#     spawning; 08EE013 51 and 50) less those years before 1950 and less any
#     dropped for a mean <= 0, both counted from the rds.
