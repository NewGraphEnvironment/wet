# Code-check round 1 (#103, branch diff against main)

## Findings

- **[fragile] research/discharge_publish.md:5, with :3 and :62.** The doc describes the publish state two ways that contradict each other. One of those descriptions also contradicts the committed BUILD report.
  - **Line 5 (Status) is stale.** It still describes the #101 rebuild: "the value-checked rebuild at wet 1d0faf8 (segment table 433d036 …) … 58 of its 67 parts byte-identical to the acb820f upload … until #103 republishes, the vignette data scripts … refuse". It also still says "Row counts and picks are those of 7c62b9e".
  - **What the report says.** The committed `data/checks/discharge_publish_20260717.txt` is now the #103 BUILD: wet 94deeb5, segment table 5215906, run 1981-2010, fingerprint 178918222.786650, and "parts identical to the published build acb820f: 35 of 67". The picks have also moved: 4,733 changed (routed picked on 3,154,131, against 3,152,838 before).
  - **Lines 3 and 62 claim an upload that has not happened.** Line 3 says "the routed run moved to 1981–2010 and republished, #103" and lists "#103 (routed PCIC over 1981–2010 published)". Line 62 says "Since #103 the live manifest names `pcic.discharge_monthly`, run PNWNAmet historical 1981–2010". But `planning/active/progress.md` (ab273f3) records "Upload refused … routes offered to the user". The live manifest is still the acb820f build, which names the frozen table and the 1951–2012 run. So both claims are false today.
  - **Uploading does not fix line 5.** Even after the upload, the Status paragraph would still be wrong (1d0faf8, 58/67, "picks are those of 7c62b9e", "until #103 republishes").
  - **Why it matters.** This research file is where the publish state is recorded, and a reader of it today is told the 1981–2010 build is live.
  - **Fix.** Rewrite the Status paragraph from the #103 report once the upload is done (wet commit, segment table, 35/67 identical, picks moved). Until then, keep "republished" and "Since #103 the live manifest names …" out of lines 3 and 62.

- **[fragile] research/water_balance_method.md:80 and :103. Provenance points at files that will not survive.**
  - **Line 80** says "the per-month table and the probe that made it are in the #103 archive". The probe is `data/logs/103/period_probe.R` (output `period_probe.txt`), and `.gitignore:8` (`data/*`) ignores both. `planning/active/findings.md` carries the table but cites the probe only by that untracked path. Once the PWF is archived, the table survives and the probe does not, unless it is copied into the archive.
  - **Line 103.** The "moved 4,733 picks: 3,013 to routed and 1,720 to the balance" figure cites no producer. It comes from `data/logs/103/pickmove.R`, which is also untracked. The net change agrees with the committed segment report (3,154,131 − 3,152,838 = 1,293 = 3,013 − 1,720). The split itself can only be re-derived from the untracked script.
  - **Fix.** Copy both probe scripts and their outputs into the archive directory, or cite them as m1/m4-local.

## Checked and found correct (no action)

- **R code and tests.**
  - `wet_segment_sources()` pin, roxygen and `man/`: consistent.
  - `scripts/pcic_routed_lib.R` takes `routed_run` from the pin.
  - `segment_output.R` and `discharge_publish.R` take the period from `routed_run`. No literal 1951 is left in `R/`, `scripts/`, `data-raw/`, `vignettes/` or `tests/` (`helper-discharge.R` aside, an accepted tradeoff).
- **`data-raw/monthly_vignette_data.R`.**
  - Removing the period block leaves no dangling reference: `hydat` is still defined and used by `wet_hydat_connect()`, and `s` (used for `years`) comes from `wb_cv_lib.R`.
  - The saved list is `segments, gauges, provenance`, which matches `expect_named()` in the test.
- **`data-raw/segment_vignette_data.R`.**
  - Sources `pcic_routed_lib.R`, so `routed_run` exists.
  - `period` is a parquet column, not a hive key, so the added `SELECT … period` is valid.
  - `routed_period = unique(pub_r$period)` is held to `routed_run$period` before it is written.
  - The vignette's `grepl(prov$routed_period, prov$routed, fixed = TRUE)` holds against `routed_report_line()`'s format.
- **`vignettes/monthly-flow.Rmd`.**
  - No inline r value or `stopifnot()` refers to a removed object (`p`, `lp`, `n_long`, `n_long_far`, `long_med`, `per_med`, `explained`, `routed_text`, the period-check chunk); checked by grep.
  - `by_g()` now uses `both$ratio_r`, and `length(g_low) == n_both_gauges` holds by construction.
  - `far_low`, `days` and `base` are still defined and used.
- **Numbers in `research/water_balance_method.md`, checked against `data/checks/pcic_routed_compare_20260717.txt`** (current, and old at 2675636), all match:
  - At the 290 gauges: 24.2/27.6, median 13.1/18.0, within ±20 % 63/54, bias +1.4/+9.0, routed closer at 58.
  - Headwater 28.3/31.0, nested 11.7/17.2, 1–10k km² 11.9/22.3.
  - Fraser 30.7/28.4, Peace 19.0/19.2, Columbia 24.6/32.7, Coast 19.2/25.1. Routed's median is better and it is closer at more than half the gauges in all four basins.
  - Old values: 24.1, 13.0, +0.2, 59. Bias +1.2 overall, Columbia +3.8, Peace −3.9. Table total +0.50 %.
  - Without the far-low gauges: 21.5/27.2. The 112 gauges the older table never scored: 18.1/23.3. The 178 and 171 sets unchanged.
  - Pick 23.0/24.2/27.6 and 23.3/27.5; old 22.9/24.1/27.6 and 23.2/27.5.
  - Monthly −19.5→−11.5 and +18.7→+15.8 match `data/logs/103/period_probe.txt`, so about 41 % and 16 % of the spring and summer errors.
- **Numbers checked against `data/checks/segment_output_20260717.txt`**, all match:
  - Picks 3,154,131 / 1,378,712 / 222,906, Fraser 113,604, 6.6 %.
  - Nechako groups 26.8 %, GUIC 72.7 % (written as 73 %).
  - Edge types 1410 11.8 % and 1400 10.9 %, order 1 5.4 %.
  - 4,733 picks moved = 0.104 % of 4,532,843.
- **The routed month-sum ratio "0.97–1.02, median 1.003; 0.93–1.02 on 1951–2012"** was re-queried on m1's `pcic.discharge_monthly`:
  - 1981-2010: 0.973–1.018, median 1.0027, over 3,308,090 segments.
  - 1951-2012: 0.928–1.018, median 1.0030, over 3,309,111 segments.
- **Monthly article's thresholds against the measured new values.**
  - March −11.1 and April −12.2 are each under −10, and the season median of −11.5 is under −10: true, though narrowly.
  - July +19.9, August +13.0 and the season median +15.8 are all over +10.
  - Per gauge, 61 % low and 68 % high, both over 50.

## Note (not a finding)

`stopifnot(all(5:9 %in% r_closer))` in `vignettes/monthly-flow.Rmd` (the "May to September among them" prose) was not measured on the 1981–2010 run. Routed's May median moved from −15.5 to −17.2 %, so May is the month at risk. If it fails, the render stops when the rds is regenerated rather than shipping wrong prose, so this is a heads-up only.
