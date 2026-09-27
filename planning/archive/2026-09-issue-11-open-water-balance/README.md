# #11 Open province-wide runoff estimate: water balance after Chapman et al. 2018

## Outcome

`wet` now builds its own open estimate of mean annual and monthly runoff and discharge for every FWA fundamental watershed in BC (3,245,453 watersheds), with the code shipped. It reimplements Chapman, Kerr & Wilford (2018), the BC Water Tools method, so that other groups' products can be scored against it (#5).

It is validated out of sample with blocked cross-validation at 290 HYDAT stations.

The headline finding is that Chapman's zone adjustment helps only slightly out of sample:
- blocked-CV MAE 33.1 % against 34.7 % for raw P − AET;
- in-sample, 22.6 %;
- Chapman's published figure, likely in-sample, is 16.1 %.

The adjustment passes its gate only under a pooled-zone variant added after the pre-set specification failed (46.4 % against 39.8 % on headwater stations). **Which to ship is left open for the maintainer.** The output currently applies the adjustment; `keep_adjust` flips it.

Durable record: [`research/water_balance_method.md`](../../../research/water_balance_method.md) section 0, and the map [`research/wb_runoff_annual.png`](../../../research/wb_runoff_annual.png).

## Measurement

**Inputs** (`data/checks/wb_inputs.txt`, `climr_eccc.txt`):
- Everything is on CGIAR's 30″ grid over BC, 1,428 × 3,012 cells.
- climr 1981–2010 normals, built by averaging MSWX anomalies and downscaling once. This matches climr's per-year point average within 0.1 %, and costs a thirtieth of the time.
- Against 57 ECCC WMO normals: MAP ratio median 1.03, MAT difference median about 0 °C.

**Stations** (`stations_wb.txt`):
- 352 natural stations selected, 309 snapped (median area ratio 1.000), 290 calibrated on, 93 blocked folds.
- 21 lake outlets, tested on the FWA network.

**Skill** (`wb_validation.txt`): MAE of annual runoff, raw → adjusted, under blocked CV.
- All stations: 34.7 % → 33.1 %.
- Headwater: 39.8 % → 38.1 %.
  - with their own zone in the fold (n = 118): 34.1 % → 30.9 %;
  - pooled (n = 100): 46.4 % → 46.6 %.
- Monthly shares: median NSE 0.87.

**Major rivers** (`wb_output.txt`): modelled over observed mean annual flow is 0.86–1.17. Fraser at Hope 1.05; PCIC through `wet` 0.93.

**Runtime:** province sampling 6.4 min (4 workers); accumulation 4.5 min; validation about 4 min.

**What changed because of the numbers:**
- The ClimateNA → MSWX switch (a coastal NA gap).
- The pooled-zone variant (the gate).
- The ET experiment redirected at the semi-arid interior, where CGIAR AET is far too low next to climr's P.

**Wrong turns, kept:**
- climr's "Empty tile" warning was dismissed as ocean. It turned out to be about 160 k blank coastal land cells.
- A `typeof()` guard on integer64 could never fail.
- The lake-outlet flag went through three definitions.
- Pooling was fixed once from locations, which collapsed zone 07 in one fold; it was reverted.
- The gate was PASS (ClimateNA), then FAIL (MSWX, pre-set specification), then PASS (post-hoc variant, nested).
- Each is in `findings.md` and the `review-*.md` files.

## Evidence

- `data/checks/wb_*.txt`, `data/checks/stations_wb.txt` and `data/checks/climr_eccc.txt` (tracked).
- The review rounds, `review-*.md`, in this directory.
- Run outputs, gitignored and regenerable with `scripts/wb_inputs.R`, `wb_stations.R`, `wb_province.R`, `wb_validate.R`, `wb_output.R` and `wb_map.R`: `data/wb/5c2feaefad/`.

## Open

- Follow-up issues are drafted in `issue_drafts_followup.md` and not filed. They cover transboundary area, ET in the semi-arid interior (the land-cover experiment), snow predictors for the monthly shares, and an upstream note for climr (outward-facing, needs approval).
- The terra `rasterize(filename = , INT1U)` NA-as-0 draft is in `findings.md`, also not posted.

Closed by: PR from `11-open-province-wide-runoff-estimate-water` (Relates to #11, #5, #6)
