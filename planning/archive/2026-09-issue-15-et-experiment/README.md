## Outcome

The open water balance overpredicted the semi-arid interior because CGIAR's AET is capped by its own WorldClim precipitation, which is lower than climr's there. Four alternative annual AETs were scored under the #11 blocked CV:
- Chapman's land-cover ratio (Table 3, NRCan 2020);
- TerraClimate 1981–2010;
- Fu–Budyko from climr P and Hargreaves PET;
- max(CGIAR, Fu–Budyko).

The rule deciding what ships was fixed before any variant was scored: a 2-point headwater margin, no loss on all stations or nested basins, and a fully nested selection. It chose `max(CGIAR, Fu–Budyko)`, which now ships (`scripts/wb_validate.R` ships the winner that `scripts/wb_aet_compare.R` records).

Chapman's land-cover step made the interior worse. Published Table 3 values sit below CGIAR's BC means, so the ratios fall below 1, and the calibrated ratios Chapman used were never published.

The durable verdict is in `research/water_balance_method.md` §0, "The ET experiment".

Learned along the way:
- A single GDAL average warp from a rotated source CRS mis-weights footprints badly.
- A review's same-method oracle cannot catch that.
- Every stored stamp must be checked against the current code, not against another stored stamp.

## Measurement

**Blocked-CV MAE on annual runoff, as shipped** (`data/checks/wb_aet_compare.txt`):

| AET | Headwater | All 290 | Nested | Nested within ±20 % |
|---|---|---|---|---|
| CGIAR | 38.1 % | 33.1 % | 17.9 % | 72.2 % |
| land cover | 44.1 % | 37.1 % | 16.0 % | 76.4 % |
| TerraClimate | 33.5 % | 29.0 % | 15.3 % | 81.9 % |
| Fu–Budyko | 32.0 % | 28.1 % | 16.3 % | 75.0 % |
| **max(CGIAR, Fu–Budyko)** | **31.2 %** | **27.7 %** | 17.4 % | 70.8 % |

- **Fully nested selection:** 32.3 % headwater against CGIAR's 38.1 %, the honest estimate after selection. 87 of 93 outer folds chose `cfu`.
- **Semi-arid zones, mean error:** zone 23 +57 → +20 %; zone 24 +231 → +102 %.
- **Small basins:** under 100 km², MAE 61 → 44 %.
- **Greata Creek:** 462 → 243 mm, against 50 mm observed.
- **The cost:** major-river mouth ratios move 0.01–0.05; Skeena goes 0.86 → 0.83.

**Land-cover fractions.** The first method, one average warp from EPSG:3979, was off by up to 0.30 per cell (median max-class 0.07 over 40 cells). The fix, nearest to an aligned 1″ grid then a block mean, is within 0.009. This was found by my own spot check after a review round had passed the method; that review's oracle was the same warp.

**Baseline held.** The new run reproduces #11's upstream means to within 5.9e-16 relative, once rows are aligned by id (the database row order differs). The cgiar report matches #11's byte for byte apart from the run-key line.

**Timings:**
- Land-cover fractions: 14.1 min (one step), then 28.1 min for all inputs (two steps).
- Province run: 11.6 min.
- Scoring: about 3.9 min per variant; compare 6.6 min.

**Wrong turns kept:**
- **The dead nearest-fill.** A TerraClimate nearest-cell fill was dead code, because GDAL's bilinear reweights around missing neighbours. It was found by a restore-the-bug check and removed.
- **The CRS failure.** The first province smoke run stopped on TerraClimate's unnamed-datum CRS. The fixture had declared EPSG:4326, so it could not see this.
- **The deleted output loop.** A guard edit deleted `wb_output.R`'s output loop. Review round 3 caught it before any output ran.

## Evidence

- Run logs: `data/logs/2026092[78]_*`
- Province log: `data/wb/province_run_15.log`
- Reports: `data/checks/wb_aet_compare.txt`, `data/checks/wb_validation_aet-*.txt`, `data/checks/wb_inputs.txt`, `data/checks/wb_output.txt`
- Review rounds: `review-*.md` in this directory

Closed by: the PR for #15
