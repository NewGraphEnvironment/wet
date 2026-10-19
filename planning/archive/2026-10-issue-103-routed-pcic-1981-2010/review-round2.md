# Review round 2 (#103), branch diff against 2675636

## Findings

- **[severity: fragile (doc)]** research/discharge_publish.md:5 (Status paragraph, round 1's rewrite). The paragraph now ends "The upload took about 4 min and deleted no stale keys." In the rewritten order, that sentence follows "It is not yet uploaded" (the #103 build) and "The reports before it were #101's rebuild ... and #91's ...". "The upload" no longer has a clear subject. A reader can take it as the #103 upload, which contradicts the sentence two lines earlier. It refers to the 2026-10-15 acb820f upload. Fix: move it up beside "replaced on 2026-10-15 ...", or name it ("The 2026-10-15 upload took ..."). This is the only problem I found in the round 1 fixes.

No code bugs found.

## Checked and found correct

- **R/wet_segment_monthly.R, man/.** Only the pinned period and its roxygen changed, and the .Rd is regenerated. `scripts/pcic_routed_lib.R` (`routed_run`, `routed_where`, `routed_report_line`), `segment_output.R` (`period_routed`) and `discharge_publish.R:297` all take the period from that pin. No `1951` is left in R/, scripts/, data-raw/, vignettes/ or tests/, apart from helper-discharge.R (accepted).
- **data-raw/monthly_vignette_data.R.** The removed block leaves no dangling reference: `long_sel`, `mon_long`, `mon_8110`, `yrs_long` and `period` appear nowhere else. `hydat` is still used by `wet_hydat_connect()`.
- **data-raw/segment_vignette_data.R.**
  - `period` is a file column, not a Hive key, so the added SELECT column exists in the parts.
  - `stopifnot(identical(unique(pub_r$period), routed_run$period))` compares character to character (a data.frame column via `as.list`), and an NA or a second period fails it.
  - `routed_period` is recorded only after that assert.
- **vignettes/segment-discharge.Rmd.** `grepl(prov$routed_period, prov$routed, fixed = TRUE)`: `prov$routed` is `routed_report_line()` minus its prefix, which contains the run's period. NA gives NA, so `stopifnot` fails. An empty string cannot reach here because of the data script's assert. Nothing else in the article mentions periods.
- **vignettes/monthly-flow.Rmd.**
  - `routed_text`, `v$period`, `lp`, `n_long`, `n_long_far`, `per_med`, `long_med` and `explained` have no remaining uses.
  - The new `by_g` uses `both$ratio_r`, which is routed_mm/obs_mm and so the same ratio as flow over flow per month; it is asserted non-NA. Its `length(g_low) == n_both_gauges` holds by construction.
  - The probe's numbers give the guards margin, but only just: 1981-2010 run at the 279 gauges, months 3/4 at -11.1/-12.2, months 7/8 at +19.9/+13.0, season medians -11.5 and +15.8, per gauge 61 % low and 68 % high, against thresholds of -10, +10 and 50 %. The tightest is April's -11.1 against -10. The vignette's far-low set is the new run's 11, which the routed report shows are the same 11 as before.
- **tests.** The changed expectations match the new rds shape, and the SQL in test-wet_segment_monthly.R matches the pin.
- **research/water_balance_method.md numbers**, against the tracked reports, git's 2675636 copy of the routed report, and planning/active/evidence/:
  - Routed scores: 24.2/27.6, median 13.1, ±20 % at 63/54, bias +1.4, closer at 58 %.
  - By group: headwater 28.3/31.0, nested 11.7/17.2, 1,000-10,000 km² 11.9/22.3.
  - By basin: Peace 19.0/19.2, Fraser 30.7, Columbia 24.6, Coast 19.2. Bias moved +3.8 in the Columbia (7.8 → 11.6) and -3.9 in the Peace (9.4 → 5.5). The table total is 0.5 % higher.
  - Without the far-low gauges: 21.5 / 27.2. At the 112 gauges the older table never scored: 18.1. At the 178 and the 171: 28.0 and 25.3.
  - Pick at the gauges: 23.0 / 24.2 / 27.6, and 23.3 / 27.5 at all 315.
  - Picks in the province: 3,154,131 routed and 1,378,712 balance, 222,906 of them flipped (6.6 %), Fraser 113,604, Nechako groups 26.8 %, GUIC 72.7 %, edge types 1410 11.8 %, 1400 10.9 %, 1450 5.3 %, order 1 5.4 %.
  - Pick moves 3,013 + 1,720 = 4,733, which is 0.10 % of 4,532,843; the net change of 1,293 agrees with the segment report.
  - Spring -19.5 → -11.5 is about 41 %, and summer 18.7 → 15.8 about 16 %.
- **research/discharge_publish.md numbers**, against data/checks/discharge_publish_20260717.txt:
  - wet 94deeb5, segment table 5215906, every check passing.
  - 555,857,796 values compared: the sum of the eight checks.
  - 35 of 67 parts byte-identical. That is 24 watershed parts plus 11 balance segment parts. The 32 changed parts are all 20 routed parts (800, 945 and 990 have none) plus the balance parts of the 12 basins pickmove.txt shows moving.
  - Month 0's largest difference is 9.1e-13.
- **The round 1 evidence fix.** planning/active/evidence/{period_probe,pickmove}.{R,txt} are tracked, and findings.md cites them by the `evidence/` path. R/, scripts/ and data-raw/ have not changed between the build commit 94deeb5 and HEAD, so the built tree matches the code.

## Note (known state, not a finding)

The committed inst/vignette-data rds files are still in the old shape. Until they are rebuilt:

- test-vignette_data.R fails three expectations: `expect_named` (monthly), `routed_period` (segment), and the routed `period` setequal.
- Both vignettes stop at their period asserts, so a pkgdown build of this branch fails too.

Rebuilding them is the merge gate. It also needs the publish BUILD rerun after the upload, so that its report reads "identical to the published build 94deeb5 (or the upload's commit): 67 of 67", because `vd_published()` refuses anything else.
