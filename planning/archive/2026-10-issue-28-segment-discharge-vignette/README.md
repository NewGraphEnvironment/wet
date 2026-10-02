## Outcome

Added the second vignette, `vignettes/segment-discharge.Rmd`, on mean annual discharge per FWA segment.
- **Parity:** wet reproduces fwapg on SALR.
- **Sampling:** how area-weighted sampling moves small watersheds.
- **Maps:** SALR from PCIC through wet, and BULK from the open water balance, where fwapg has no rows.
- **Skill:** blocked-CV skill of the balance at the 290 calibration gauges.

The data comes from `data-raw/segment_vignette_data.R` and `data-raw/segment_vignette_map.R`, 417 KB in all. The data script reruns `scripts/mad_parity.R`. It refuses an uncommitted tree, so the recorded commit can rebuild the data, and refuses a fit made under other scoring code.

The shipped fit used HYDAT 2025-10-14, which is no longer downloadable, so the water balance could not be rebuilt on m1. It was copied from m4 as a reduced bundle, with md5s identical for the fit, the stations and the CV results.

Learned along the way:
- fwapg's bigint ids reach R as integer64, which a reader without bit64 sees as raw bits. A join then matched 0 of 2,181 segments, silently.
- The gap between the two products on SALR is shared, not one product's error.

## Measurement

- **Parity:** 9,000 of 9,000 SALR segments with an fwapg value are identical after 5-decimal rounding. Live and stored upstream area move 0 SALR segments. Fraser-wide, 1,731 of 644,710 polygons are stale (`data/checks/upstream_area_100_full.txt`).
- **Area-weighted against centroid sampling, SALR:**
  - under 10 km², 11 % of watersheds move by more than 5 %, 24 % at the 99th percentile;
  - over 100 km², the 99th percentile is 2.8 %.
- **Open water balance on SALR:** a median 1.47 times PCIC per order ≥ 3 segment. Against the 5 gauges near SALR (within 30 km, plus outlet 08KC001), held-out balance error is +6 % to +38 %. fwapg is −1 % and −2 % at the two small basins and −14 % to −25 % at the three large ones.
  - **Wrong turn:** this was first read as "both miss", then as "most of the gap is the balance's".
  - **Corrected:** split in log terms, the gap is 94–98 % the balance's at the small basins and 28–52 % at the large ones. So PCIC holds an equal or larger share there. Recorded in `research/water_balance_method.md` §0.
- **BULK:** the balance gives 7,748 of 7,755 order ≥ 3 segments a value; 7 have no lut watershed. Mean absolute held-out error at the 7 BULK gauges is 37 %.
- **Skill:** blocked-CV MAE 27.7 % (31.2 % headwater, 17.4 % nested), equal to `data/checks/wb_validation.txt`. Zone 24 is the only zone above twice the overall MAE (102 %).
- **Review:** five reviewer agents. Each code-check loop ended by enumeration after a defect turned up inside a fix: the dirty-tree guard (data scripts), and the attribution sentence (vignette).

## Evidence

The SALR parity runs are `data/logs/20261002_mad_parity_salr.log` and `data/parity/SALR_run.log`. Both are gitignored and stay on m1; the tracked record is this README and `findings.md`.

Closed by: PR (see `gh pr list --head 28-vignette-mean-annual-discharge-per-segme`)
