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

## Errors Encountered

| Error | Resolution |
|-------|------------|
