# Findings — Vignette: Chinook flow at two stations, last five years vs 1981–2010, with a map (#27)

## Issue context

**If we do it:** the station-flow vignette answers one question a reviewer can check in a minute: were the last five years wetter or drier than 1981–2010 in the Chinook windows, at two stations they can find on a map? **If we never do:** the vignette stays as shipped in #29: correct, but 11 windows, four figures and a trend panel, so it is slow to read and easy to misread.

## Problem

The first pass (#29) built the path and the pkgdown scaffold, but the vignette is hard to review:

- **Too much at once.** 11 BULK windows across five species, so the hydrograph carries 11 strips per station and the heat strip 22 rows.
- **No sense of place.** Nothing shows where Buck Creek (08EE013) and Bulkley River near Houston (08EE003) are, or how they relate to each other.
- **The comparison a reader wants is not drawn on its own.** The question is how the last five years compare with 1981–2010, window by window. The heat strip holds the answer, but it is buried among 45 years and 11 windows.
- **Little interpretation.** The prose explains how to read the figures, not what they show.

## Proposed Solution

Revise `vignettes/station-flow.Rmd`. The data path (`wet_station_daily()` → `wet_window_stats()` → cd) and the scaffold stay as they are.

1. **A map of the two stations.** A static map in the Bulkley watershed: the stations, the mainstem and Buck Creek, and the watershed boundary, with a keymap for BC. Station coordinates come from HYDAT, and the context layers from fwapg, bundled small in `inst/vignette-data/` by `data-raw/station_vignette_data.R`. No tiles or network at build. Styles come from the gq registry, following the cartography conventions.
2. **Chinook, open water only.** Three CH windows: migration (May 1 – Aug 1), spawning (Aug 1 – Sep 15) and fry migration (Jul 15 – Sep 7). Incubation and emergence reach into November–April, when flows are ice estimates. Including them would bring back the ice discussion, the provisional-winter drop rule and Houston's missing winter baseline, so they are left out, with one sentence saying why. The vignette is about flow, not about the gauge record.
3. **The last five years against 1981–2010.** For each station and Chinook window, each of the last five years' window mean sits beside the window's 1981–2010 mean. One figure, built to be read at a glance: few marks, direct labels, and one reference line.
4. **A short interpretation.** Three or four sentences on the patterns, with every number computed and guarded, as in #29.
5. **Limits, two or three lines.** The most recent years are provisional (open-water provisional flows are close to final), and the windows come from the literature. The record-by-source figure and the ice prose go.

Decided 2026-10-01:

- **Long-term mean:** 1981–2010, the baseline the vignette already uses. Houston has summer baseline years from 1981 to 1998 only, which is still above the 10-year minimum.
- **Last five years:** 2022–2026. All three windows end by September 15, and the record runs to September 30, 2026. The 2025–26 values are provisional.
- **Heat-strip and trend figures stay,** cut down to the three Chinook windows. With fewer species and life stages, they become readable.

## First pass, shipped in #29

- The pkgdown scaffold and workflow; vignette packages in Suggests.
- `data-raw/station_vignette_data.R` → `inst/vignette-data/` (61 KB): daily series with provenance, and the BULK windows from knowledge's `life_history_timing.csv` at a pinned commit.
- `vignettes/station-flow.Rmd`: four figures (record by source, hydrograph with species windows, departure heat strip, Theil-Sen trends), computed captions, gq colours, and a word cap.
- The provisional-winter drop rule: a window touching November–April drops years with provisional days.

Findings are in `research/station_flow_departure.md` § Species windows.

*Body revised 2026-10-01 when the issue was reopened. The original proposal is in the #29 description and the archive at `planning/archive/2026-10-issue-27-station-flow-vignette/`.*

Relates to #25


## Plan-mode exploration (2026-10-01)

- **Data path stays:** `wet_window_stats()` → `cd::cd_baseline()`/`cd_anomaly()`/`cd_trend()`, with `vignettes/station-flow.Rmd` running live on `inst/vignette-data/` (61 KB).
- **Map styles exist in `gq::gq_reg_main()`:** `watershed_group_boundary`, `streams_all`, `lake`, `hydrometric_stations_environment_canada` and `town` (sourced from `gns_geographical_names_sp`). Only a station-catchment fill is custom.
- **fwapg (`fresh-db`) is up.**
  - Bulkley River is BLK 360873822 and Buck Creek is BLK 360886221. Pull them by BLK, not GNIS name.
  - BULK has 1,861 order-≥5 segments with 39k vertices. Simplified, that fits the 500 KB cap.
  - `wet_station_snap()` gives each station's FWA position; the upstream catchments come from `fwa_watershedatmeasure()`.
- **Station coordinates come from the HYDAT `STATIONS` table**, as in `wet_station_select()` and `scripts/wb_output.R`.
- **Locally installed `cd` is 0.4.0; DESCRIPTION needs ≥ 0.5.0.** The vignette fails to build on this machine (an `all(spawn$anomaly < 0)` stop on NA anomalies). CI is fine.
- **The registry needs changes.** `inst/cartography/wet_station.csv` `recent_year` has four ordinal classes and needs five. `record_source` and the `dropped`/`no_baseline` departure classes become unused.
- `tmap` 4.4.1, `sf` 1.1.2 and `bcdata` are installed. `sf` and `tmap` are not yet in Suggests.

## Phase 1: map inputs (2026-10-01)

- **Separate script, not a section of `station_vignette_data.R`.** The daily bundle was retrieved 2026-10-01 against HYDAT 2026-07-17, the same release that tidyhydat's default path holds on m1. Re-running the daily script would refetch S3 and real-time for no change, so the map has its own `data-raw/station_vignette_map.R`. The plan said one script.
- **rds, not GeoPackage.** The six layers as a gpkg were 2.9 MB, 804 KB of it the BC outline: `fwa_bcboundary` unioned and simplified at 2 km keeps 144k vertices in its islands. The fix keeps parts of at least 2,000 km² and simplifies them at 5 km, giving 736 vertices. The layers are then saved as one xz rds, like `station_daily.rds`: 64 KB. The total bundle is 132 KB.
- **Catchments check against HYDAT.** FWA upstream area / HYDAT gross area is 0.997 for 08EE013 (567 km²) and 0.998 for 08EE003 (2,315 km²). `wet_station_snap()` accepted both, and the catchment is cut with `fwa_watershedatmeasure()` at the snapped segment's measure.
- **Streams grouped by `blue_line_key` alone.** Grouping by key and `gnis_name` split the Bulkley into several rows, because some segments have no name.

## Phases 2–4: the vignette (2026-10-01)

- **One commit for Phases 2–4.** Filtering the windows breaks the ice and thin-baseline guards, the `dropped`/`kept` cascade and the registry assertions all at once (review-27b items 1–3 and 20). An intermediate commit would not render.
- **ggplot2 for the map, not tmap.** gq's main-registry styles for streams are classed by FWA `feature_code`, which the bundled layers do not carry. `gq_tmap_keymap()` prints a second viewport, which knitr would emit as a second figure. The map takes its colours from the registries (`streams_all` WA24111110, `lake`, `town`, plus the custom `station_map`), its frame from `gq_bbox_aspect()` and its scale bar from `gq_scale_breaks()`. tmap stays out of Suggests.
- **The key figure is bars at 100 + cd's anomaly.** Each panel carries cd's `baseline_mean` in m³/s and a dashed line for the median baseline year, at 64–96% of the mean. Provisional years (2025, 2026) are drawn lighter.
- **A silent zero, caught on reading the render.** "0 of those 24 window-years were drier than nine years in ten" came from `low$value`. `anom` has no `value` column, so `$` returned NULL, and `sum(NULL < x)` is 0. Fixed by carrying `value` through `cols_flag`, with `stopifnot(is.numeric(low[["value"]]))` and `n_dec > 0`. The corrected figures are 21 of 24 below the 10th percentile and 6 below the baseline minimum, matching the plan review's independent count.
- **Hydrograph clipped to May–October.** April 2026 at Buck Creek opened at about 8 m³/s against a median of 0.7: a provisional under-ice reading.
- **Prose:** 480 words, under the 600 cap.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `sum(streams$main) == 2` failed | group by blue_line_key only (unnamed segments split the group) |
| Interpretation said 0 of 24 below the 10th percentile | `anom` had no `value`; carry it through `cols_flag` and guard it |
| R CMD check: `test-wet_pcic_annual.R` fails, no package 'ncdf4' | Fails the same way on main; `terra::writeCDF()` needs ncdf4, which is not in Suggests. Outside this issue; drafted as a follow-up issue |
| Vignette render stops at `all(spawn$anomaly < 0)` with NA anomalies | Locally installed cd is 0.4.0; DESCRIPTION needs >= 0.5.0. Upgrade cd (Phase 1). |
