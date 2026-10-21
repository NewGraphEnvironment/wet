## Outcome

Published `discharge/fwa/v1/segment_daily` (#99): every FWA segment's mean flow on each day of a 365-day year (29 February folded into 28), for both sources, beside the monthly datasets, in build 77585a8 on 2026-10-20. The balance's days are its published months laid on the fit's daily shape (#70), so each month's days average to it. Routed PCIC's days are routed in wet from fwapg#25's sub-basin climatology and segment weights (`wet:::wet_routed_days()`), clamped and rounded as fwapg makes its months, so they need not average to the published month. The work added a readers' path over `doy` (`wet_segment_daily()`, `wet_db_load(doys, groups)`, `wet_values_compare(time)`), `scripts/segment_daily_output.R`, the daily build, checks and skip-if-live upload in `scripts/discharge_publish.R`, the crate schema (crate#33, released in crate v0.8.0), and the daily read in the segment-discharge article. What we learned: routing the days reproduces fwapg's months exactly, but only once rounding matches Postgres's numeric rounding at 15-digit ties, which R's `round()` on a double does not. A reader's plain mean of a month's routed days differs from the published month for two reasons, the per-day clamp and February's fold weighting, and the fold accounts for most of it. The durable record is `research/discharge_publish.md` ("Routed days, against fwapg's months"). Follow-ups: #107 (the monthly-flow article's Chinook windows from the daily) and #108 (the manifest's routed description omits the fold).

## Measurement

- **Routed days reproduce fwapg.** The `n_days`-weighted mean of the raw days, clamped and rounded, equals `pcic.discharge_monthly` on all 40,524,444 segment-months, with 0 one-step tie flips. It also equals `pcic.discharge_weekly` on 8,467,940 rows in 5 groups (the probe). `wet_routed_round()` equals Postgres on 200,006 values; R's `round()` alone missed 4 of 6 constructed ties. The round-1 code review reproduced a real flow (12213.315444999958) that R rounds to .31544 and Postgres to .31545. That changed the rounding window and made the build's tie-aware guard necessary.
- **Per-day clamp.** 1.092 % of 1,232,618,505 routed segment-days are clamped, and 0.050 % mid-network (fwapg's monthly figures are 0.978 % and 0.049 %). The rule was set before measuring: it would be a stated weakness above 0.1 % mid-network. It is under that, so the daily step adds almost no mid-network clamping. The worst day is 16 May, with 874 segments.
- **Days against months.** 1,869,949 routed segment-months (4.614 %) have a plain day mean more than 1e-5 m³/s from the month, and 1,021,601 of them are in February. The largest gap above is 197.24528 m³/s and the largest below 0.12366 m³/s. The plan assumed the clamp was the cause. The round-4 review showed the fold accounts for most of it, and the article's sentence and #108 follow from that. The balance's days meet its months within 1.2e-15 relative over 38,680,224 watershed-months.
- **Size and time.** 2,886,046,240 rows in 445 daily parts, 31.35 GB, with the largest part at 373 MB. One part per drainage would have reached about 6 GB, over S3's 5 GB single-PUT limit, which decided per-group parts at the gate. The daily table takes 132 min on m4, and the BUILD with checks 3 h 29 min, comparing 15,040,448,264 values with 0 differing. PUBLISH skipped the 67 live-identical monthly parts. The BUILD after the upload found 512 of 512 parts byte-identical to live.
- **Wrong turns.** A first province daily run (code f35c673/86a5b78) passed both guards on the Fraser in 22 min and was stopped as superseded by the review fixes. Code review ran four rounds, and rounds 2 and 3 each found a defect inside the previous fix: the subset exemption, and then its reach, a misspelt group silently emptying a load. The rounds ended by enumeration. The article's 900-word prose cap refused the first daily text at 949 words.

## Evidence

- `data/checks/segment_daily_output_20260717.txt`, `data/checks/discharge_publish_20260717.txt` (the BUILD after the upload; the pre-upload report is at 608147e), `data/checks/segment_output_20260717.txt`
- `data/logs/99/*` on m4's worktree `~/Projects/repo/wet-99` (the probe, both daily runs and both BUILDs), not yet moved (Owed)
- `review-*.md` in this directory: the plan review, crate rounds 1–3 and code rounds 1–4

## Owed

- Remove the m4 worktree after moving its `data/logs/99/` into the main checkout

Closed by: PR (opened from branch `99-publish-segment-daily-the-balance-s-dail`)
