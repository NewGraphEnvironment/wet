# Findings — Vignette: mean annual discharge per segment (#28)

## Issue context

**If we do it:** wet's core product (per-segment mean annual discharge, fwapg parity, the open water balance) gets a readable account with its skill measured out of sample. That is the second vignette for going public. **If we never do:** the method lives only in `research/` and the scripts.

## Problem

Per-segment discharge is wet's main output (#1, #2, #11, #15), but it is explained only in `research/fwapg_mad_method.md` and `research/water_balance_method.md`, and reproduced only by scripts that need fwapg and PCIC downloads.

## Proposed Solution

- `data-raw/segment_vignette_data.R` → `inst/vignette-data/`, under 500 KB:
  - one headwater watershed group: SALR (Salmon River, 1,794 km²), the parity group from #1, with stream order ≥ 3 and simplified geometry to stay inside the budget;
  - BULK (Bulkley River, 7,762 km²), the #27 watershed, with the same filters. fwapg's `fwa_stream_networks_discharge` has no rows there, so this is where wet's open water balance (#11) supplies discharge that fwapg does not;
  - the blocked-CV scores summarised by region.
- `vignettes/segment-discharge.Rmd`, in the same shape as #27. Four figures:
  - **Parity:** wet against fwapg MAD on SALR, 9,000 segments.
  - **Sampling change:** how area-weighted sampling moves small watersheds compared with centroid sampling.
  - **Map:** MAD per segment for SALR, and for BULK from the open water balance.
  - **Skill:** blocked-CV skill at 290 HYDAT stations by region.
- Close with what it does not show:
  - fwapg's stored upstream area is a stale snapshot;
  - PCIC covers only the Peace, Fraser and Columbia;
  - the Chapman zone adjustment passes its gate only under a variant added later (`research/water_balance_method.md`).

Depends on #27's scaffold (merged in #30). The data is rebuilt on m1: PCIC for SALR, then `wb_inputs` → `wb_province` → `wb_validate`.

**Why BULK.** link v0.55.0 (link#286) lets a bundle classify a group on `mad_m3s` from `fwa_stream_networks_discharge`. A BULK group set to `mad` loses all stream habitat with no error, because there is no discharge there. Scoring `mad` against observations is link#300, and it can reach groups outside PCIC's coverage only through wet's estimate.

*Body revised 2026-10-02: BULK added, and the data rebuild on m1 noted.*

## Exploration on m1 (2026-10-02)

- fwapg (`fresh-db`): `fwa_stream_networks_discharge` has 9,000 SALR rows and 0 BULK rows. Order >= 3 segments: SALR 2,181 of 9,384; BULK 7,755 of 32,472. BULK sits in top-level basin 400.
- The water balance (#11/#15/#18) was fit against HYDAT 2025-10-14 (`data/checks/stations_wb.txt`). m1's only HYDAT is 2026-07-17, at tidyhydat's default path, which `wet_hydat_path()` reads. ECCC's collaboration site now lists only `Hydat_sqlite3_20260717.zip`.
  - A rebuild on m1 would change `data/wb/stations.rds`. That moves the scores, so `wb_aet_compare.R`'s stage-1 reproduction check (ref15) stops, and `wb_output.R` then refuses to ship.
  - m1 has no `~/.netrc`, and `wb_inputs.R` calls `wet_mod16_aet()` unconditionally (3.9 GB of granules).
  - Decision at the plan gate (user): copy `data/wb/` from the original machine; no rebuild.
- `scripts/mad_parity.R SALR` writes `data/parity/SALR_parity.csv` and `SALR_{area,centroid}_{total,covered}.csv`.
- 7 calibration gauges in 08EE (`stations_wb.txt`).

## Data build (2026-10-02)

- `scripts/mad_parity.R SALR` on m1 (log `data/logs/20261002_mad_parity_salr.log`, gitignored):
  - 9,000 of 9,000 segments are identical to fwapg after 5-decimal rounding.
  - Live upstream area against fwapg's stored table: **0** SALR segments change. So the vignette's "stale snapshot" limit cites the Fraser-wide check instead: 1,731 of 644,710 polygons (`data/checks/upstream_area_100_full.txt`).
  - Area-weighted against centroid sampling: median 0.00 %, 1–99 % range −10.75 % to +19.85 %; 9.59 % of watersheds move more than 5 %.
- `data/wb/` came from m4 as a 21 MB reduced bundle, cut down on m4:
  - `stations.rds`, `fits.rds`, `aet_winner.txt` and `cv_aet-*.rds`, md5 identical to m4;
  - each `upstream/*.rds` cut to the 309 accepted station watersheds, which is what `wb_cv_lib.R` keeps;
  - `output/{100,400}.parquet` cut to month 0 (annual).
  The full copy ran at about 1 MB/s (2.5 GB) and m4 had to go off. Every guard in `segment_vignette_data.R` passed: `fits$code_md5 == score_code_md5` under m1's code, the winner is `cfu`, and the MAE equals the tracked report.
- **SALR: the open water balance runs a median 1.47x PCIC through wet.** Attributed against the calibration gauges within 30 km plus SALR's outlet gauge 08KC001. The water balance is high at all five (+6 to +38 %) and fwapg low at all five (−1 to −25 %). At 08KC001, which holds SALR: WB +38 %, fwapg −25 %. So the gap is **both** products, bracketing the observation.
- BULK: 7,748 of 7,755 order ≥ 3 segments get a value from the water balance; 7 have no lut watershed. BULK holds 7 calibration gauges (08EE004 Bulkley at Quick, nested; the others headwater).
- Vignette data: 416 KB of the 500 KB budget (`segment_map.rds` 193 KB, `segment_values.rds` 223 KB).

## Code-check on the data scripts (rounds 1-3)

| Round | Finding | Inside previous fix? | Outcome |
|---|---|---|---|
| 1 | `linear_feature_id` (bigint) saved as integer64; a fresh session joins 0 of 2,181 | — | fixed: `::int` in SQL + no-integer64 guard |
| 2 | integer64 fix complete; provenance records HEAD while the scripts were uncommitted | n | fixed: refuse a dirty tree |
| 3 | dirty guard passes when git fails (`system2` warns, returns `character(0)`); guard misses `data/checks/`; `data/parity` CSVs are unstamped | **y** | fixed: `git()` checks status; scope adds `data/checks`; the build runs `mad_parity.R` itself after deleting the old CSVs |

Ended by enumeration, after round 3 found a defect inside round 2's fix. Mechanism (round 3): the script treated its own session as where the output is read, so every saved value and provenance claim must trace to a commit or a code-stamped input. The inputs, found by grepping every read in the scripts:
- **Tied to the recorded commit:**
  - code in `R/`, `scripts/` and `data-raw/`, and the three `data/checks` reports: the clean-tree guard;
  - the parity CSVs: regenerated in the run;
  - `stations.rds`, `fits.rds`, the CV results and the winner file: the md5 check.
- **Accepted:**
  - `upstream/*.rds`: the run key, with the station set asserted;
  - the output parquet: `wb_output.R` is not in `score_files`;
  - fwapg, PCIC and BC Geographic Names: external.
- Both guards were shown to fire: git fails outside a repo, and the tree is dirty.

## Code-check on the vignette (rounds 1-2)

| Round | Findings | Inside previous fix? | Outcome |
|---|---|---|---|
| 1 | 9,000 is fwapg's count, not SALR's 9,384; the no-watershed bullet miscounted and its segments are not drawn; NEWS "five nearest gauges" false; "fwapg runs low" overstated (−1, −2 % at two); two claims unpinned | — | all fixed |
| 2 | "most of the gap is the balance's" is wrong at the large basins, where PCIC holds 48–72 % of the gap in log terms; the guard `mean(abs(wb)) > mean(abs(fw))` was a proxy carried by the two small basins. The "order 3" lower bound came from the threshold, not the data | **y** | rewritten per size class, guarded by the per-gauge log share; range from data |

Ended by enumeration: every paragraph's quantitative claims were listed against their pins (progress.md, session 2026-10-02). Separately, `R CMD check` failed #27's whole-directory 500 KB cap on `inst/vignette-data` (548 KB). Made it per vignette, matching each issue's own budget; a test pins the file list so no file escapes both budgets.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `ST_SnapToGrid` collapsed sub-metre segments to empty | Keep the unsnapped line when the snapped one is empty |
| `bcdata::BBOX(sf::st_bbox(groups))`: "No known SQL translation" | Compute the bbox first, pass `local(bb)` |
| `fwa_upstream()` puts 4,586 of 4,587 SALR polygons upstream of 08KC001, so the "all" containment test found no outlet gauge | 99 % test, plus `stopifnot(length(outlet) == 1)` |
