# Round 4 fixes, and the enumeration that ends the code-check loop (#102)

## Round 4 findings and fixes

| # | Finding | Verified | Fix |
|---|---|---|---|
| 1 | "A calibration gauge publishes its own shares" is false for 08NM240/08NM241, which are on one watershed with identical predictors | Yes: rows 284/285 of `fits$share$x` are the only zero-distance pair; April 0.096 / 0.053 | Exception named in CLAUDE.md, research #102 and the vignette's Limits |
| 2 | The #70 research section is stale against the rerun report | Yes (basis, held-out row, weights, zones led, sensitivities, Buck Creek / Quick held-out windows) | Section revised to the rerun, with #70's values in brackets; Buck Creek's larger held-out late-summer error is recorded; the `cv_share` wording in the #16 and #70 sections now names what ships |
| 3 | "Zones 27–29, where the snow regression was weakest" | Yes: 10 and 11 are lower than 28 and 29 | "three of the five zones where the regression scored under 0.75 (with 10 and 11)" |
| 4 | Buck Creek's window check (`abs < 15`) did not test its sentence | Yes | It now composes (1 + approx)(1 + annual) against the balance to within 2 points. Restored-bug test: with the annual term dropped, the render errors |
| 5 | "Lake outlets stay the weakest group" fails against the zones | Yes: zones 10 (0.783) and 17 (0.824) | "weakest of the report's non-zone groups (zones 10 and 17 score lower)" |

## Mechanism

Rounds 1–2 found prose and guards that assumed the shares are the regression. Round 3 enumerated those branches. Round 4's findings share a different cause: quantified and comparative claims ("every", "weakest", "the shipped `cv_share`") written from the data as remembered, not checked against the report they cite, and a rerun (`wb_shape_daily.R`) that overwrote a report a research section still quoted.

## Enumeration: every quantified or comparative claim this branch adds to prose

Source of truth for each: the tracked report it cites, or the code.

| Where | Claim | Source | Verdict |
|---|---|---|---|
| research #102 | blocked CV 0.8735 / 0.9389 / 0.9187; leak-free 0.8735 / 0.9353 / 0.9209 | `wb_validation_20260717.txt`, `wb_share_donor_*` line 9 | holds |
| research #102 | monthly NSE 0.727 / 0.813 / 0.810 | `wb_share_donor`, "all" | holds |
| research #102 | test gauges 0.772 / 0.837 / 0.812, 110 gauges | `wb_share_donor`, last line | holds |
| research #102 | every AET variant gives the same outcome; annual identical; #16 median 0.873517978845096 | `data/logs/102/check_scores.log` (m4) | holds (all ten) |
| research #102 | 0.9389 against #70's free curve 0.9388 | `wb_shape_daily`, free-curve line | holds |
| research #102 | peak outside May–June 0.725→0.892, monthly 0.494→0.753 | `wb_share_donor`, "peak other months" | holds |
| research #102 | Liard 0.785→0.911; Feb/Mar −74 / −80 % → within 4 % | `wb_share_donor`, "WSC area 10" and "area 10" rows (−2.2, −2.3, −3.8) | holds |
| research #102 | zones 27–29 among the five under 0.75 (10, 11, 27, 28, 29); zone 27 0.511→0.942 | `wb_share_donor`, every-zone table | holds |
| research #102 | freshet 57.7 % (66.4), −6.2 % (−12.7), 85.9 % (75.9), 241 gauges | `wb_share_donor`, peak table | holds |
| research #102 | regression higher in 4 of 29 zones: 17, 06, 16, 26 with the values given; 01 and 02 gain under 0.005 | awk over the every-zone table | holds |
| research #102 | lake outlets 0.760→0.867; below them only zones 10 and 17 | `wb_share_donor` | holds |
| research #102 | leak costs donor 0.0036; regression 0.8735 in both pools to four decimals | rule lines | holds |
| research #102 | shape rerun: observed months 0.9824 unchanged; held out 0.849→0.909 = free curve 0.9091 | `wb_shape_daily` | holds |
| research #102 | month 0 byte-identical in 24 basins; no pick moves | `check_output.log`; segment report pick counts unchanged | holds |
| research #102 | 08NM240/241 exception | `fits.rds` | holds (fix 1) |
| research #102 | published 8ca2dee, 20 of 67 then 67 of 67; 08EE003 +379 / +470 % | publish report; vignette window table | holds |
| research #70 | every bracketed and current number | `wb_shape_daily` now, and at 8745010 | holds (fix 2) |
| research discharge_publish | 1.88 GB, 67 parts, row counts, 555,857,796 compared / 0 differing, 45c6c12, 2fe90c6, 20 routed parts identical, 47 changed | publish report | holds |
| CLAUDE.md | k = 5; two pools; 0.01; donor ships; exception pair | header, code, fits | holds |
| vignette | every inline number, each with a `stopifnot` in its chunk | round 4 evaluated them all on the bundle | holds; the one weak check is fixed (fix 4) |

No claim sits above its source. The loop ends here: round 3 by an enumeration of the code, this round by an enumeration of the prose.
