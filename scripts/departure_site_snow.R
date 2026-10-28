# Snow and the window flows at a Chinook pilot site (#126): #121's regression
# (scripts/departure_snow.R's header), unchanged, run at each site of
# scripts/departure_sites.csv on the series scripts/departure_site.R saves.
# The specification was committed in this header alone, before any body code
# (planning/archive, issue 126). Every fit is reported. Nothing is chosen,
# nothing ships, nothing is published, and no fit is read or touched.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_site_snow.R <site_id>
#
# One run per window set the site names, each reading
# data/departure/departure_site_<site>_<group>_20260717.rds (refused unless
# its `code_md5` is the current scripts/departure_site.R's and its `release`
# is 20260717), writing the tracked report
# data/checks/departure_site_snow_<site>_<group>_20260717.txt (no timestamp)
# and, after it, the gitignored
# data/departure/departure_site_snow_<site>_<group>_20260717.rds (`snow`,
# `series`, `fits`, `release`, `site`, `code_md5`). fwapg through the WET_PG*
# variables, as scripts/departure_snow.R; cd's annual ERA5-Land layers as
# there, with each file's CD_RUN_TIME, CD_SHA and CD_VERSION reported.
#
# ---- what is #121's, unchanged ------------------------------------------------------------------
#
# The predictors (wet_snow_annual() over each watershed's dissolved polygons,
# 1950-2025: swe_max capped at 3,000 mm per cell and year, per 100 mm;
# snowmelt_doy_50 per 10 days; both centred on the watershed's own 1981-2010
# mean; snowmelt_rate_peak reported, in no model). The responses (the window
# mean's log departure in each of the window set's two windows). The three
# OLS fits per series (swe + doy, swe, doy) over every year 1950-2025 with a
# response and both predictors, with 90 % t intervals, residual SE, R2, the
# lag-1 autocorrelation of residuals over consecutive-year pairs, and the
# predictors' correlation. Snow before and after (1950-1980 against
# 2011-2025), beside the site run's flow change. The parity line against the
# shipped normals grid. The per-year tables. A year whose cover is below 1 is
# refused.
#
# ---- what changes per site ----------------------------------------------------------------------
#
# The series:
#   - each snow gauge observed: log(value / m), m the arithmetic mean of its
#     complete 1981-2010 window-years (at least 10), from the site rds's
#     window statistics, a mean <= 0 dropped and counted;
#   - an extend site's target extended (`mx[["q_mean <window>"]]$e$dep`, the
#     site run's OLS route) and carried (`$a$anomaly`);
#   - an ungauged site's target carried alone.
#
# The snow gauges: the site's snow_gauges column where it names them (Maxan's:
# 08EE003 and 08EE013, #121's). Otherwise the first two gauges, nearest first,
# with at least 10 complete 1981-2010 window-years in both windows. For an
# extend site they are taken from the target's extension donor chain under the
# window set's migration mean (attr(e, "donors")); for an ungauged site, from
# its carried donors there.
#
# The watersheds: a gauge's, or an extend target's, is every fundamental
# watershed upstream of its snap (wet_station_snap(), which must be
# accepted), its own polygon included, as in scripts/departure_snow_lib.R's
# ds_watershed(). The polygon count and the snapped watershed_feature_id are
# reported, not asserted, except for Maxan's three, which keep #121's. An
# ungauged target's watershed is every fundamental watershed whose
# wscode_ltree descends from its blue line's, the area its normal used.
# Nesting (a target inside a snow gauge's watershed) is reported.
#
# ---- the parity gate ----------------------------------------------------------------------------
#
# The maxan row under the BULK windows must reproduce #121's run: its `fits`
# must be identical() to data/departure/departure_snow_20260717.rds's
# `fits`, and each series' years and departures to that rds's `series`. That
# rds's code_md5 must be the current scripts/departure_snow.R's. The run
# stops before writing anything otherwise.
#
# ---- what it refuses ----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; a site_id not in the table; no site
# rds, or one made by another scripts/departure_site.R; a snap not accepted;
# a snow gauge with fewer than 10 baseline years in either window; fewer than
# two snow gauges found; a year with cover below 1; the parity gate.
