# Review round 4: docs and prose (git diff dabbfa1 HEAD -- CLAUDE.md vignettes research)

Checked every added factual or quantified claim against data/checks/segment_daily_output_20260717.txt,
data/checks/discharge_publish_20260717.txt (HEAD and 608147e), the live manifest (fetched 2026-10-20,
`built` 2026-10-20T18:40:10Z, wet_commit 77585a8), planning/active/findings.md and progress.md, and
R/wet_routed_days.R, R/wet_shape_predict.R, scripts/segment_daily_output.R, scripts/discharge_publish.R.

## Findings

1. **research/discharge_publish.md:5 (Status): the largest daily part has the wrong source.**
   The text says "the largest, `pcic_routed` SETN, 373 MB". In the live manifest the largest daily part is
   `segment_daily/.../source=wet_balance/part-SETN.parquet`, 372,609,026 bytes (23,832,675 rows). The
   `pcic_routed` SETN part is 196,739,492 bytes (197 MB). The next largest are all wet_balance (TOAD 312 MB,
   LIAR 273 MB, OWIK 257 MB, MORK 219 MB). Fix: "`wet_balance` SETN, 373 MB".

2. **vignettes/segment-discharge.Rmd, the `segment_daily` bullet: "Routed PCIC's days, each clamped at zero,
   need not average to their month."** The sentence is true. With "`segment_monthly` per day" just before it,
   "their month" reads as the published `segment_monthly` month, and that reading is correct. But the
   appositive gives the clamp as the reason, and the clamp is not the main one. The daily report gives
   1,869,949 segment-months whose plain day mean is more than 1e-5 m³/s from the published month, and
   1,021,601 of them (55 %) are February. Those come from the fold: a plain mean counts the folded 28 February
   as 1 day in 28, while the month weights it 37/847 (research/discharge_publish.md, "Routed days" bullet 3).
   Two numbers show the clamp cannot account for February:
   - Clamped segment-days are 1.092 % of all days. Outside February, 848,348 of 37.1 M segment-months (2.3 %)
     differ, while in February 1,021,601 of 3.38 M (30 %) do.
   - The largest difference below the month, −0.12366 m³/s, cannot come from the clamp, which only raises a
     day mean. Outside February a mean can fall below the month by rounding only (≤ 1e-5), so this value must
     come from the fold.

   So a reader who averages February's days on a segment where nothing was clamped will find a gap the
   sentence does not explain. The live manifest's `pcic_routed` description has the same gap; it is not in
   this diff. A wording that stays within the cap would be something like "Routed PCIC's days, clamped at
   zero one by one, with 28 February counted as one day, need not average to their month." The cap leaves
   1 word of room (see the Clean note below), so a fix must cut words elsewhere.

3. **research/discharge_publish.md:80 (new value-check table row): "daily balance, n-weighted mean of each
   month's days = the `segment_monthly` parts".** The code takes a plain mean. scripts/discharge_publish.R
   (the "daily balance months = segment parts" check, about line 609) uses
   `stats::aggregate(q_m3s ~ linear_feature_id + month, ..., mean)`, an unweighted mean of each month's days.
   In this file "n_days-weighted" means the routed weighting that counts the folded 28 February 37/847, so
   "n-weighted" here suggests the check weights the days, which it does not. The balance's plain mean equals
   its month by construction: `wet_shape_daily()` sets q = Q·n·w with n = 28 in February and Σw = 1. Fix:
   "plain mean of each month's days".

4. **research/discharge_publish.md, "Routed days" bullet 1: "with no difference even at a rounding tie (the
   script refuses otherwise ...)".** The result is right: the report gives 0 differing and 0 one-step tie
   flips. The parenthesis overstates the guard, though. scripts/segment_daily_output.R stops only on
   `vs_month[["differing"]] > 0`, and a one-step difference at a tie is counted separately as `tie_steps` and
   excused (about lines 226–231 and 261–262). It would not refuse a tie flip. Suggested wording: "the script
   refuses any other difference" or "refuses a difference beyond a one-step tie".

5. **research/discharge_publish.md:5 (Status): "about an hour" for the 2026-10-20 upload has no record.**
   No committed report, log or planning file records how long the PUBLISH took. progress.md gives only
   bounds: the BUILD ended 20:36 UTC, and "the live manifest named 77585a8 by 21:46 UTC". That is at most
   about 70 min, and it includes the user starting the run and the anonymous verification. The figure is
   plausible but unsourced. Either cite where it comes from (the user's PUBLISH output) or say "within about
   70 min". This is minor.

## Verified (no finding)

- **Part counts and sizes:** 512 parts and 33.23 GB. By dataset:
  - segment_monthly: 43 parts, 102,790,688 rows, 1.15 GB
  - watershed_monthly: 24 parts, 41,904,356 rows, 0.73 GB
  - segment_daily: 445 parts (246 wet_balance and 199 pcic_routed, one per group and source),
    2,886,046,240 rows, 31.35 GB

  All are decimal GB, matching the manifest and the report's "Totals". The provenance (77585a8, d20a624,
  6bb261e, crate 0.8.0) matches the manifest.
- **Pre-upload build (608147e:...):** 67 of 512 parts identical to live 8ca2dee. That supports both "the
  monthly parts are byte-identical to 8ca2dee" and "already live with the same bytes". The post-upload
  BUILD at 608147e gives 512 of 512 identical and every check ok.
- **Values compared:** 15,040,448,264 equals the sum of the report's compared column. The four new table
  rows' counts and 0 differing match. The 3.6e-12 m³/s is `max_abs_diff`, an absolute difference
  (R/wet_values_compare.R). The 0 tie-step count matches.
- **"one sum per distinct upstream set, not the build's path":** matches `route_by_set()` against
  `wet_routed_raw()`.
- **Build timing:** "3 h 29 min" matches progress.md (17:06–20:36 UTC).
- **Routed days section:**
  - The input counts check out: 13,786,122 = 37,667 × 366, and the weights table has 3,377,037 rows.
  - Both inputs are held to `pcic.runs` (`routed_daily_fingerprint()` in scripts/pcic_routed_lib.R).
  - The formula `max(Σ q_acc + q_local·share, 0)` and the half-away-from-zero rounding match
    R/wet_routed_days.R. The 4-of-6 ties and the 200,006 values match findings.md.
  - The month and week reproductions match: 40,524,444 segment-months, and 8,467,940 weekly rows in five
    groups.
  - The clamp figures match: 1.092 %, 0.050 %, 0.978/0.977 % and 0.049/0.048 %, worst day 16 May (874).
  - The fold arithmetic holds: 30 × 28 + 7 leap days = 847, and the folded bin is 30 + 7 = 37.
  - The plain-mean counts match: 1,869,949 (4.614 %), 1,021,601 in February, +197.24528 and −0.12366.
  - "Outside February ... only by rounding (at most 1e-5)" holds, because each day is held 30 times there.
  - The balance figures are 1.17e-15 and 1.25e-15 relative, so "1.2e-15" and "1.3e-15" round correctly.
- **CLAUDE.md and research/water_balance_method.md edits:** consistent with the above.

## Clean (word cap)

The vignette's 900-word prose cap still passes. Running the `wordcount` chunk's logic on
vignettes/segment-discharge.Rmd gives **899 words** (cap 900), so a fix to finding 2 must be
word-neutral.
