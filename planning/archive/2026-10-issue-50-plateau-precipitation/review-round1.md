# Code-check round 1: scripts/wb_plateau_p.R (#50)

Reviewer read the rule (Pre-registered rule, Amendment 2, Deviation 1), review-rule.md, the full
script, the report and the helpers it calls. Probes were read-only against `data/plateau_p/` caches
and raw snapshots. The script itself was not run.

Checked and found consistent with the rule: T1 thresholds, conditions and statuses (LOO on both groups,
flagged years, era, |dz| <= 200 m, unflagged/PRISM including "not high needs it available"); B3
(product/product, WY <= 2012, R >= 1.10, per zone); T2 as a veto (>= 3 gauges, share < 1.00 >= 1/2);
T3 window, 1 Sep to survey with the (day - 1)/dim fraction, WY 1982-2010, >= 10 surveys, median
SWE >= 100, zero-sum drop, PNWNAmet 100 m check; the verdict and attribution branches; water-year and
month alignment for all three products (PREC 1967-2012 by layer count, TerraClimate months from time
units, climr periods); hourly resets, the 72 h hold, LST days, >= 12 readings, 100 mm cap, Deviation 1
floor and the signed-net flag; covered months for gauge and product sums. Raw-data probes: the PC and
SW archive/current files do not overlap in time (archive ends 2026-09-30 23:00, current starts
2026-10-01), no station id appears under two column names, the daily archive has no duplicate
(id, date, variable) keys, the WFS returned all features (173 gauges, 390 courses) in lon/lat order,
and the PRISM list yields 23 ids. The reported dz check (1.15, "holds") is 1.1491 unrounded, so
"inconclusive" and "holds" is correct.

## Findings

- **[severity: bug]** scripts/wb_plateau_p.R:262-270. The catch-factor ratio's denominator is gauge P
  summed over **covered months only** (`gdc`), but the numerator, peak SWE, builds up over every day
  from 1 October. In any year with an uncovered month between 1 October and the peak, the P from that
  month is missing from the denominator while its snow is still in the peak, so that year's ratio is
  too high. The rule says "gauge P from 1 October to the day of the peak". The covered-months clause in
  Amendment 2 is about the gauge-vs-product sums, not this ratio.
  - Measured on `obs_7839f4f088.rds`: 337 of 1,616 catch-factor years (21 %) have 1-3 uncovered
    months before the peak.
  - Using climr's monthly P to weight the missing months, those years' ratios are inflated by a
    median of x1.21 (90th percentile x1.53, max x2.97).
  - Per site, a median of 17 % of the years are affected, and one site has >= 50 %.
  - c feeds the T2 veto (through `adj`) and G1 (`use_adj`). The bias raises c, which pushes toward a
    veto and toward adjusting.
  - It does not change this run's verdict: T1 is not "high", so T2 is not consulted. Both group
    medians sit at the floor 1.00, and a correction can only lower c, so `use_adj` stays FALSE.
  - T2's reported share (0.23) can move.
  - Fix: compute the per-year ratio only on years where every month from October to the peak month is
    covered, or sum over all valid days and require that coverage. Then bump `obs_method`, and record
    the change as a deviation, since stage 2 has run.

- **[severity: fragile]** scripts/wb_plateau_p.R:327 and 487-488. `cmed` uses `tapply(..., stats::median)`
  without `na.rm`. `obs$cf$c` is already NA at 2 gauges: 4B12P and 4D13P, both outside `use` today
  (4D13P is in a contrast zone). If an in-use gauge ever had an NA c, its group median would be NA.
  The `!any(is.na(cmed[...]))` guard would then set `use_adj` to FALSE without a word, and the report
  would print "raw". The guard fails toward skipping G1, so it fails toward pass. Fix: use
  `median(na.rm = TRUE)`, or stop on NA.

- **[severity: fragile]** scripts/wb_plateau_p.R:464 with 615-617. `gyear(product, months)` adds the
  whole-year catch term `(c - 1) * p_to_peak` to a sum over a seasonal subset of months. Under
  `use_adj = TRUE`, the May-Sep D would carry the winter catch adjustment on summer sums. This is
  latent, because `use_adj` is FALSE in this run and the seasonal D is reported, not deciding. It
  would be wrong the first time G1 fires.

- **[severity: fragile]** scripts/wb_plateau_p.R:428. The `cellz_*.rds` key is
  `site_key, tc_bb, climr_method`. It leaves out the climr version, even though the DEM comes from
  `climr::input_refmap()` and the climr product cache does key on the version (line 348-349).
  Δz decides T1's elevation condition and T3's PNWNAmet check. After a climr upgrade that changes
  `dem2_WNA`, the old Δz would be reused against the new climr P. Add
  `utils::packageVersion("climr")` to the key.

## Notes (not bugs against the rule as written; for the author)

- Attribution (lines 641-648) compares D(climr) on WY <= 2024 site-years (13 dry, 46 contrast) with
  D(PNWNAmet) on WY <= 2012 (7 dry, 29 contrast). Review B2 asked for "the same site-years".
  Amendment 2's text says only "under the same conditions", and the code follows the amendment. The
  attribution is "unresolved" either way in this run.
- B3 `met` (line 554) is also FALSE when a group has < 4 gauges. That case would be reported as "the
  gauge sites do not show #45's gap", which is not the reason. It is not reached here (7 / 29).
- Years with a pillow peak < 100 mm use the site's median peak day for `p_to_peak` (lines 276-280),
  not that year's own peak. The rule does not say which to use. It affects only `adj`.
- Snow-course surveys with Survey Code `EST AREAL AVG` (estimated, not measured) are kept. There are
  5 such rows province-wide in the 20 Mar-10 Apr window over 1982-2010, which is negligible.
