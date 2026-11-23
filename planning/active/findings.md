# Findings — Backlog move 11: Small-basin error and the zone adjustment (#188)

## Issue context

**If we do it:** we know why the open balance runs about 14 % high at gauges under 100 km², how WALLY's flows compare at the gauges, and whether a trait regression or zone blending improves the adjustment, decided by a rule registered before the numbers. **If we never do:** small streams, where most fish habitat decisions are made, keep flow that is often 15 % or more too high with nothing saying why, and the zone steps stay on the annual map.

Order: `planning/backlog.md`, move 11. Run `/planning-init <this issue>`: one phase, one PR.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 11, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

### Batch 13: small-basin error and the zone adjustment

**Why here:** one oracle, the held-out balance at the calibration gauges (`cv_ann`, `cv_share`, `data/checks/gauge_monthly_compare_20260717.txt`). #176 diagnoses the small-basin error; #178's candidate (a per-zone regression on catchment traits, from our own inputs) and #44's (blending the adjustment across zone lines) are both changes to the zone adjustment, so they are scored in one rescore under one registered rule, and the refit chain is paid once. #185 consolidates `research/monthly_error.md` in the same move, so the diagnosis revises its statement in place.

**Touches:** a new diagnosis script under `scripts/`, `research/monthly_error.md`, `data/checks/`; if a candidate ships, `R/wet_wb_fit.R`, `scripts/wb_validate.R` and the refit and republish chain.

**Decided at the gate:** the rule, registered in a script's header before any candidate is scored; which candidates enter; the hosted WALLY tool used only where its written terms allow.

| issue | title |
|---|---|
| #176 | Open balance runs high at small basins: +14 % median at the gauges under 100 km² |
| #178 | WALLY: score its flows against the gauges, and test its approach as a candidate adjustment |
| #44 | Blend the zone adjustment across hydrologic zone boundaries |
| #185 | Consolidate research/monthly_error.md around the current state |

## Planning exploration (2026-11-23, at origin/main 97f07599)

- **Comments:** #188 holds only claim notices; #176, #178, #44 and #185 have none.
- **The held-out values are on this machine.** The main checkout's `data/wb/768876badf/fit_20260717/cv_aet-cfu.rds` holds `station_number`, `raw`, `cv_ann` (315 values) and the share objects; `data/wb/768876badf/upstream/<basin>.rds` holds, per gauged watershed, `p_yr`, `aet_yr`, `ro_raw`, `t_yr`, `elev`, `e_km`, `n_km`, monthly `ppt_`/`tave_`/`aet_`, `pet_yr`, the AET variants, `snowmelt_doy_50`, `swe_max` and the zone shares `z<k>`, `zp<k>` (100 columns). No slope, solar exposure or glacier cover.
- **No DEM, CGIAR or climr grids on this machine** (`data/dem`, `data/cgiar` absent in the main checkout), so a new raster trait is computed where the full runs are.
- **#45's per-gauge PCIC terms are cached:** `data/wb_term/diagnose_20260717.rds` (`basins`: 192 gauges by 41 columns; `zones`; `eccc`). Check C reads it; whether `basins` carries every column #45's rule needs per gauge, and the area, is checked in Phase 3.
- **The province run samples area-weighted:** `scripts/wb_province.R:212`, `wet_ws_sample(st, ws, "area")`. #176's "small-watershed sampling" candidate (centroid against area-weighted, measured in #1) therefore does not describe the shipped run.
- **Gauge counts differ by set:** #176 counts 84 calibration gauges under 100 km²; the tracked gauge report's size table counts 76, the ones shared with routed PCIC (`data/checks/gauge_monthly_compare_20260717.txt:74`). The diagnosis uses the calibration set and prints its count.
- **Scoring-code hashes:** `scripts/wb_score_md5.R`'s `score_files_for()` lists the files whose change stales the fit; `scripts/wb_cv_lib.R` is one, so the new script joins its extra columns itself.
- **The scripts read `data/` relative to the working directory** (`scripts/wb_fit_lib.R`: `wb_key_dir()`, `wb_stations_path()`, `wb_report()`); only `scripts/channel_scale_pilot.R` reads `WET_DATA_ROOT`. The worktree holds `data/basin` and `data/checks` only.
- **A `psql -h 127.0.0.1` probe of the local fwapg did not return in 120 s** (2026-11-23 about 06:00 UTC; cause not found: a password prompt or a stalled Docker engine). Whether `whse_basemapping.fwa_glaciers_poly` exists there is unmeasured; Phase 3 probes it with a connect timeout.
- **Stale first-party installs:** soul's `check_pkg_stale.sh` reported 10 of 21 stale. The planned scripts load wet from source and no other first-party package; if the build finds one it needs among the `PKGSTALE` lines, the upgrade is asked for, not worked around.

## WALLY (Phase 2, 2026-11-23)

- Training table `4_training/sept13_2021/all_data.csv`: 534 stations (WALLY area within 20 % of HYDAT's, more than 10 years); the model's allocation filter keeps 482 (PDF Figure 14). 4 have no hydrologic zone. Table 1's N sums to 480.
- HYDAT 20260717 flags 110 of the 482 regulated. 280 of our 315 calibration gauges are training stations.
- The report's R² is over training and test together (p. 23); the model script at the pinned commit scores test sets. Which one Table 1's MIN R² is cannot be told.
- The number guard of Phase 1 strips issue numbers and commit shas: moving a heading's issue number onto each statement multiplies it, which is not a typed claim number.

## The clock (2026-11-23)

- m1's clock read 7 hours early at the start of this session: `date -u` printed 07:20 UTC while the true time was about 14:20 UTC, and the files and commits made before about 14:25 UTC carry the early time (fetch-log rows 1 and 2, commits ef2e88e and 8864113). R formats UTC correctly (`format(Sys.time(), tz = "UTC")` agreed with `date -u` once corrected). No report prints a time.

## Errors Encountered

| Error | Resolution |
|-------|------------|
