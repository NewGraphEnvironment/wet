# Review round 4: bf84a89...29f89bc (tolerance gates, rerun reports, #16 prose)

## Findings

- **[fragile]** scripts/wb_upstream_identity.R:48-53 and scripts/wb_share_snow.R:55-58. The relative-difference gates cannot see a non-finite change. Where one side is `Inf`, `big` is `Inf`, `abs(x - y) / big` is `NaN`, and `max(..., na.rm = TRUE)` drops it. The NA-pattern check uses `is.na()`, which is FALSE for `Inf` and TRUE for both `NA` and `NaN`. So three changes pass silently: a finite value turning `Inf`, `Inf` turning `-Inf`, and `NA` turning `NaN`. The `identical()` these checks replace caught all three. Reproduced on copies of the local reduced bundle (basin 100):
  - `p_yr[5] <- Inf` in the new run: PASS
  - `Inf` in old, `-Inf` in new: PASS
  - `NA` in old, `NaN` in new: PASS
  - `rel(c(1, 2), c(1, Inf))` in wb_share_snow: returns 0

  Both gates still fail where they should on everything else I tried: a different watershed set, a changed id, a changed code, a different NA pattern, a column missing in the new run (it stops, though the message wrongly says "is NA in different watersheds"), an extra column, a changed irregular id, a dropped `irregular` attribute, and a relative difference of 1e-8. Both also pass on the real data: all 24 local basins, worst 3.0e-16. Today's data holds no Inf or NaN (basin 100 has 0 of each), so the committed reports stand. The gap is a regression in what the guard can reject. A zero-area or zero-weight divide is exactly the kind of change that produces Inf or NaN. Fix: also require `identical(is.nan(x), is.nan(y))`, and that the non-finite entries agree exactly (`nf <- !is.finite(x) | !is.finite(y); identical(x[nf], y[nf])`), before taking the relative difference over the finite ones.

- **[claim]** CLAUDE.md, the `wb_province.R` bullet: "`scripts/wb_upstream_identity.R <set-aside run>` checks two runs agree (#16)". The script checks only one pairing: a run without snow columns against one with them.
  - Line 40 stops if the set-aside run already has `snowmelt_doy_50` or `swe_max`.
  - Line 39 stops if the current run lacks them.
  - Line 63 stops unless the new run adds exactly those columns.

  Every run from now on carries the snow columns, so a reader following the sentence to check a rerun against the last one (the #76 case the same bullet describes) is refused at line 40. Say it checks the run with the snow layers against the one set aside before them, or generalise the script.

- **[claim]** research/water_balance_method.md, #16 section, "Where it helps": "gauges peaking outside May–June gain the most share NSE (+0.05)". The tracked reports show other groups gaining more.
  - `wb_share_snow_20260717.txt`: `peak other months 74 share NSE 0.678 -> 0.725 (+0.048)`, but `zone 29 13 share NSE 0.673 -> 0.743 (+0.069)`.
  - `wb_share_snow.txt`: `peak other months 63 ... (+0.071)`, but `zone 29 9 ... 0.599 -> 0.761 (+0.161)` and `zones 27-29 32 ... (+0.094)`.

  "The most" holds only against the May–June gauges (+0.007 and +0.011). Say "more than the May–June gauges".

- **[claim, low]** research/water_balance_method.md, the inputs bullet "Snow (#16)":
  - "45,879 cells in 36 passes" has no tracked artifact. Its only source is `planning/active/progress.md`, which gives one number. `wb_province.R:164` writes a count per layer to `<key>/ex_filled_cells.txt`, which is not tracked and is absent from the local reduced bundle. `findings.md` records that the two ERA5-Land layers' no-value cells differ (doy 10,842 against swe_max 10,835 at 0.1°). So the two layers' fill counts may differ too, and one figure for both needs checking against that file.
  - "513 BC land cells over 5,000 mm" adds a "BC land" qualifier its only source lacks (`review-plan.md` O3: "513 cells at 5,000–10,000 mm swe_max").

## Checked, no finding

- **13 validation reports:** there are 13 (`wb_validation*.txt`). Comparing each against `1ff6ea5^`, every row was identical once each table row's last two columns (NSE_mon, NSE_shr) were removed. That covers all annual columns, the gate and override lines, the test-gauge line and the zone coefficients. The other changes are the province key, the new SHARES lines, and the order of the "pooled zones in the shipped fit" list (`16 12 17` became `16 17 12`, the same set). That reorder comes from the zone columns arriving in fetch order (#76) and does not touch "all annual metrics unchanged".
- **`wb_aet_compare.txt`:** only the province-run line changed, so the claim that it reproduces #15 holds.
- **Upstream identity:** the report gives `worst relative difference: 6.6e-14 (200 tave_10)`, 24 basins and 3,245,453 watersheds, consistent with `wb_output_20260717.txt`.
- **Held-out annual:** the shipped fit is at 4.67e-15 (cfu only, the only variant a carried fit has). The 2025-10-14 fit is at 4.87e-15 over all 10 variants. That supports "every AET variant's held-out annual to 5e-15".
- **The #16 table:** every cell matches `wb_share_snow_20260717.txt` and `wb_share_snow.txt`: 0.856→0.874 (+0.018) and 0.866→0.880 (+0.014); 0.859 and 0.869; 0.708→0.727 and 0.725→0.743; 0.673→0.717 (41) and 0.620→0.714 (32); 0.622→0.511 (12) and 0.635→0.448 (10); 70.1→66.4 (241) and 71.8→68.7 (227); −14.8→−12.7 and −14.6→−13.0; −76→−16 (19) and −75→−11; 123→70 of 3,780 and 93→54 of 3,480.
- **The bullets after the table:**
  - Jan–Apr went from +8.2/+10.1/+8.5/+16.2 to +0.1/+4.6/+3.4/+10.7, which supports "+8 to +16 → 0 to +11".
  - The melt date alone adds +0.0035 on both fits.
  - "66 % still below" holds.
  - Zone 27 worsens by 0.111 and 0.187.
  - Zones 28 and 29 improve in share NSE on both fits.
- **"Every AET variant gives the same outcome":** all 11 2025-10-14 reports print the same `base 0.8659, snow 0.8803, gain +0.0144 over 290` (the 2026-07-17 fit has only cfu).
- **The rule's definition:** the 10 mm threshold is `wet_flow_validate(min_obs = 10)`. Commits 598d013 and 837ac0b exist and say what the prose says.
- **CLAUDE.md:** the `fits.rds$share_spec`, `cv_shares`, `zone` and `lake` names match `wb_validate.R:161-180`. The share predictors match `wb_cv_lib.R:101`. The 584 capped cells match `wb_inputs.txt`. #76 and #77 resolve to the right issues.
- **Publish report:** 6 of 67 parts are identical to the live build and no check fails, which supports "built and value-checked, not yet uploaded".
- **`irregular` attribute:** row subsetting `b[match(...), ]` keeps it (R 4.5.2), so the set check at line 60 compares real ids. A changed or dropped irregular id stops the run.
