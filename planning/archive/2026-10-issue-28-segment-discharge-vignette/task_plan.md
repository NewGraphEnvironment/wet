# Task: Vignette: mean annual discharge per segment (#28)


Per-segment discharge is wet's main output (#1, #2, #11, #15), but it is explained only in `research/fwapg_mad_method.md` and `research/water_balance_method.md`, and reproduced only by scripts that need fwapg and PCIC downloads.


## Context

Per-segment discharge is wet's main output, but it is explained only in `research/` and reproduced only by scripts that need fwapg, PCIC and the province run. #28 adds a second vignette in the shape of #27 (`vignettes/station-flow.Rmd`). The data is built by `data-raw/` scripts into `inst/vignette-data/`, and the vignette reads only those files at build time.

What exploring m1 found:
- fwapg is up. It has 9,000 SALR rows in `fwa_stream_networks_discharge` and 0 for BULK. Order ≥ 3 segments: SALR 2,181, BULK 7,755.
- The shipped water-balance fit used HYDAT **2025-10-14** (`data/checks/stations_wb.txt`). m1 has only 2026-07-17, and ECCC hosts only that release. m1 also has no Earthdata netrc for MOD16.
- **Decision (user, at the plan gate):** copy `data/wb/` from the machine that ran #11/#15/#18; do not rebuild. Copy the **whole** `data/wb/` to `~/Projects/repo/wet/data/wb/`: `stations.rds` and `962a9cc2c4/` with `fits.rds`, `aet_winner.txt`, `cv_aet-cfu.rds`, `upstream/` (including `_complete`), and `output/`. `wb_cv_lib.R` reads every `upstream/*.rds`. The `output/` parquet means `wb_output.R` never runs on m1. It would rewrite `data/checks/wb_output.txt` against the newer HYDAT.
- Parity and the sampling change come from `scripts/mad_parity.R SALR`. It fetches PCIC for SALR (about 1.5 min cold) and writes `data/parity/SALR_parity.csv` (per segment: wet against fwapg, and live against stored upstream area) and `SALR_area_total.csv` (area-weighted against centroid).
- Skill: `cv_aet-cfu.rds` holds `cv_v$stations` (per-station `err_pct`). Zone, nesting and area class come from `groups` in `scripts/wb_cv_lib.R`. BULK holds 7 calibration gauges (08EE).

## Phase 1: SALR data (no dependency on the copy)
- [x] Run `Rscript scripts/mad_parity.R SALR` on m1 (PCIC fetch) and record the parity line it prints
- [x] `data-raw/segment_vignette_data.R`, SALR part. It reads `data/parity/SALR_*.csv` and stops if they are missing. From those it writes the parity pairs (wet against fwapg `mad_m3s`, all 9,000 segments) and the sampling change (area-weighted against centroid `mad_mm`, with upstream area, per SALR watershed). It also counts the segments that change between stored and live upstream area, for the limits section.
- [x] `data-raw/segment_vignette_map.R`: SALR order ≥ 3 segments, simplified, each with MAD (`mad_m3s`), joined through `fwa_streams_watersheds_lut`, plus the group outline. Also the BC outline for the keymap, reusing `station_vignette_map.R`'s query. Fixed `linear_feature_id`/WSG keys, never GNIS names.
- [x] Provenance attribute: wet commit, fwapg/PCIC run, date

## Phase 2: Water-balance data (after the `data/wb/` copy lands)
- [x] Guard the copy before reading it:
  - one complete key;
  - `fits$code_md5 == score_code_md5` (`scripts/wb_score_md5.R`);
  - `aet_winner.txt` names `cfu` under the same md5;
  - `fits$aet == "cfu"`.
  Stop otherwise.
- [x] BULK: annual `discharge_m3s` (month 0) from `output/400.parquet`, joined to BULK order ≥ 3 segments, plus the group outline. Add the BULK calibration gauges with their held-out blocked-CV error, from `stations.rds` and `cv_aet-cfu.rds`.
- [x] Skill: per-station blocked-CV `err_pct` for the 290 stations, with zone, nesting and area class (`source("scripts/wb_cv_lib.R")` for `groups`). Assert that the all, headwater and nested MAE equal the tracked `data/checks/wb_validation.txt` (27.7 / 31.2 / 17.4).
- [x] One number for the prose: SALR median ratio, open water balance (`output/100.parquet`) to PCIC through wet. This scores the reference against our own estimate.
- [x] Assert that the new `inst/vignette-data/` files total < 500 KB (xz-compressed rds, as in #27)

## Phase 3: Registry and vignette
- [x] `inst/cartography/wet_segment.csv`, a gq custom registry:
  - MAD classes, sequential on a log scale;
  - parity and sampling marks;
  - headwater and nested skill marks;
  - the gauge point.
  Assert each class set in the vignette, as #27 does. No hex literals in the Rmd.
- [x] `vignettes/segment-discharge.Rmd` (`bookdown::html_vignette2`, same setup and load chunks as #27):
  - **Parity:** wet against fwapg `mad_m3s` on SALR, log-log with the 1:1 line, and the share identical after 5-decimal rounding.
  - **Sampling change:** % change from area-weighted against centroid sampling, by upstream area (log), on SALR watersheds.
  - **Map:** MAD per order ≥ 3 segment, SALR (PCIC through wet) and BULK (open water balance), with shared classes. BULK gauges are labelled with their held-out error. Keymap of both groups on BC. Follows the cartography rules: four corners, bbox aspect, legend from the registry.
  - **Skill:** per-station blocked-CV error by hydrologic zone, headwater/nested marked, with the zone MAE.
  - A short recipe chunk (`eval = FALSE`): `wet_pcic_fetch` → `wet_ws_sample` → `wet_upstream_mean` → `wet_mm_to_m3s`, and the water-balance path.
  - **What it does not show:** the stale stored upstream area (with SALR's count), PCIC covering only the Peace, Fraser and Columbia (hence BULK has no fwapg MAD, which is link#286/#300's gap), and the pooled-zone gate passing only under the later "none" variant (`research/water_balance_method.md` §0).
  - Every number in the prose is computed in a chunk and pinned with `stopifnot`, as in #27. No footnotes.
- [x] Render (`pkgdown::build_article("segment-discharge")`). Self-review each PNG against the cartography checklist (placement and communication), at the delivered width.

## Phase 4: Docs
- [x] NEWS.md entry. README line linking the vignette next to the station one.
- [x] CLAUDE.md Architecture: a paragraph on the new vignette and its data-raw scripts
- [x] `research/README.md` / `fwapg_mad_method.md`: link the vignette, and update the SALR parity numbers if the rerun moves them

## Validation
- [x] Tests pass; `devtools::check()` builds the vignette with no network or DB
- [x] `/code-check` clean on each commit
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion, then `/gh-pr-push`

