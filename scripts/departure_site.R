# The Maxan method at other Chinook streams (#126, component of #118): a
# short-record gauge's window flows extended from its long-record neighbours,
# and donor-carried departures scored held out at every gauge in the site's
# box; at a stream with no gauge, carried departures alone, laid on wet's
# published flow there. The rule below is #120's (scripts/departure_pilot.R's
# header), taken over per site and fixed at what shipped for Maxan. It was
# committed in this header alone, before any body code (planning/archive,
# issue 126).
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_site.R <site_id>
#
# <site_id> is a row of scripts/departure_sites.csv (scripts/departure_site_lib.R,
# site_get()): its box, its target (a HYDAT station, or for an ungauged site
# a blue line and its mouth), and the watershed groups whose Chinook windows
# it runs under (inst/vignette-data/life_history_<group>.csv, BULK first).
# One run per window set; each writes the tracked report
# data/checks/departure_site_<site>_<group>_20260717.txt (no timestamp, so a
# rerun reproduces it byte for byte) and, after it, the gitignored
# data/departure/departure_site_<site>_<group>_20260717.rds: `site`,
# `windows`, `release`, `ship`, `k_main`, `baseline`, `level`, `mx` (the
# target's series per statistic and window, as the pilot's), `ws` (the box
# pool's window statistics before the value > 0 filter), `stations`, `pool`,
# `donors` (the target's carried donors per statistic and window), `normal`
# (ungauged only) and `code_md5` (the md5 of the script file Rscript runs, as
# it stands at the start of the run). Run a frozen copy
# (cp scripts/departure_site.R "$TMPDIR/s.R" && Rscript "$TMPDIR/s.R" <site>),
# as for the pilot. Nothing is published and no fit is read or touched.
#
# Reads HYDAT 20260717 only, and fwapg through libpq's bare PG* variables, as
# the pilot does, for the snaps behind the leak-free sensitivity and the
# normal's error (so the maxan row's leak-free lines are the pilot report's);
# the published product through wet_catalog() and its parts over HTTPS.
#
# ---- what is #120's, unchanged ------------------------------------------------------------------
#
# Statistics (mean, min7, cov_day scored; max reported), the baseline
# (1981-2010), the log-ratio scale, HYDAT approved days only, a complete
# window-year (min_frac 0.8; cov_day every day), the four pools (box,
# extension, departure, short-record) and their thresholds, the predictors
# (easting, northing, log area, each over its box-pool SD), k = 5 with k = 3
# and 8 as sensitivities, the donor availability rules, question 1's
# pseudo-short-record test (tiled 5-year blocks, leave-gauge-out, NSE of log
# values on held-out years, per-gauge median, median over gauges) and its
# sensitivities, question 2's leave-one-gauge-out centred NSE and its
# sensitivities, the usable threshold (departure-pool median >= 0.5), the
# leak-free sensitivity, the target's answer (extended series, departures
# from its own 1981-2010 mean, the carried route beside it, the two routes
# compared, the before/after with its 2000-draw bootstrap under
# set.seed(120), cd's baseline, anomaly and trend), and the report's sections.
#
# ---- what changes per site (decided at #126's plan gate, user, 2026-10-28) ------------------------
#
# The box is the site's. Maxan's row carries #120's box verbatim; every other
# box is the same size (3.8 deg by 2.2 deg) centred on the target.
#
# The method is fixed at Maxan's. The target is extended by OLS (k = 5),
# whatever the race returns. The race of ols, move1 and ratio still runs in
# every box, and the report says which candidate #120's rule (highest median,
# 0.01 over ratio) would pick there. That decides nothing. Fewer than 15
# extension-pool gauges with a pseudo-record no longer stops the run: the
# report flags the box as below #120's floor and goes on.
#
# The carried departures are #120's: inverse distance, k = 5, from the
# departure pool less the target (not #122's covariance_pick).
#
# The windows: each window set the site names gets its own run and report, so a
# site runs under the Bulkley windows and, where cited windows exist for its
# own group, under those too.
#
# The target, an extend site: the site's target_station, which must be in the
# box pool (>= 3 complete migration years). The leave-one-year-out at the
# target (#120 did it at 08EE018) runs at every extend target. The
# short-record set is the box's 3..10-year gauges, the target among them only
# where it qualifies.
#
# The target, an ungauged site: there is no record to extend, so question 1's
# race runs in the box (it scores the box) and the target gets only carried
# departures, per statistic and window, k = 5 from the departure pool, under
# the predictors of a station at the mouth: the site's target_lon/target_lat
# and, for area, the fundamental watersheds whose wscode_ltree descends from
# the blue line's (the stream's whole basin). Its window flow per year is
# the published normal (below) times exp(carried departure), for the window
# mean only. min7 and cov_day get departures only, because the product
# publishes no normal for them. The report says that the result at the
# ungauged point itself is untested: there is nothing there to score against.
#
# The normal (ungauged only): wet's published segment_daily (wet_catalog(),
# the part for the site's group, read with duckdb over HTTPS) on the mouth
# segment, the lowest-measure segment on the blue line that has rows in the
# part. Each source's window mean comes from its days (wet_flow_window(),
# basis "daily"), and the normal is the `pick` source's. Both sources and the
# pick are reported, with the build's tree digest (wet:::wet_catalog_digest()).
#
# The normal's error: at every box gauge in the migration-mean departure pool
# whose snap (wet_station_snap()) is accepted, the published pick's window mean
# on the snapped segment against the gauge's observed 1981-2010 mean of that
# window's complete years. Each is reported as a log ratio, with its source.
# A gauge in the water balance's station set (data/wb/stations_20260717.rds,
# `stations`) is flagged, because the balance publishes a calibration gauge's
# own observed monthly shares, so there it is partly in sample. Reported: the
# median and quartiles of the log ratio over all of these gauges and over the
# unflagged ones, per window. It decides nothing.
#
# New in #126, at every site, deciding nothing: a 90 % interval on the
# carried before/after change (2011-2025 against the years before 1981),
# from 2000 draws that resample years within each period and add to each year
# a residual drawn from the box's held-out carried residuals for that
# statistic and window (each departure-pool gauge's centred observed minus
# centred carried log value, or days, over its scored years, all gauges
# pooled), under set.seed(126) after the extension's bootstrap, so the
# extension's draws are #120's. For an ungauged site this is the headline.
#
# ---- the parity gate ----------------------------------------------------------------------------
#
# The maxan row under the BULK windows must reproduce #120's run. Its `mx`
# must be identical() to data/departure/departure_pilot_20260717.rds's
# `mx`, whose code_md5 must be the current scripts/departure_pilot.R's (rerun
# the pilot otherwise). The extension it uses must be OLS, and these lines of
# the tracked data/checks/departure_pilot_20260717.txt must appear verbatim in
# the site report: the pool counts line, section 2's three method rows, and
# section 3's HEADLINE and short-record lines. The run stops before writing
# anything otherwise.
#
# ---- what it refuses ----------------------------------------------------------------------------
#
# WET_HYDAT_RELEASE other than 20260717; a site_id not in the table; a target
# outside its box; an extend target not in the box pool; an ungauged blue line
# with no watershed code, or with no segment in the published part; a window
# set whose CSV lacks one CH migration and one CH spawning row; the parity
# gate above; the usual refusals of wet_window_extend() and
# wet_departure_carry().
