# Code review, round 2: #27 vignette diff (`git diff origin/main...HEAD`), with HEAD b448962's round-1 fixes read closely

Reviewer: subagent, 2026-10-01. All probes ran on a copy (`$TMPDIR/wet_review2`). I rendered the vignette there with `load_all()` and CLAUDE.md removed, then re-derived the inline numbers from the saved environment. Nothing in the repo was modified apart from this file.

Verified sound:
- **The rds churn in HEAD is metadata only.** `station_daily.rds` without its provenance attribute is `identical()` to HEAD~1's. Only `provenance$hydat` changed, from "20260717" to "2026-07-17", which is the VERSION table's date and agrees with the directory name.
- **The spawning claim and its guard hold.** The guard (`stopifnot`) passes: 8 rows, all negative, so the claim reads 58%–81% for 2023–2026.
- **The drop sentence now matches Figure 3's "dropped" cells exactly.** That is 5 windows at 08EE013 and 2 at 08EE003.
- **The trend counts check out.** 76 slopes minus the 8 CH/SK spawning duplicates leaves 68 distinct. No slope or p-value is NA. 5 are significant and all 5 are negative. 0.05 × 68 rounds to 3.
- **Body prose is 519 words**, under the 600 cap.
- **The `years_text()` " and " join works**, including inside the per-window drop text.

## Findings

- **[severity: bug]** vignettes/station-flow.Rmd:164, :168 (Figure 1 caption) and :405-406 (limits bullet). This is the round-1 fix reproducing the defect it was meant to remove. `full` keeps only years with ≥ 360 days, so the vignette says 08EE003 "has a year-round record only in 1971 and 2011–2024" and "was a seasonal gauge for most of its record". The bundled data contradicts that for the last two years:
  - **2025 has 348 days**: 63 HYDAT ice days, then 285 provisional days, with the winter covered. The 17 missing days all fall between 1 July and 11 August 2025. That is a summer gap in the provisional archive, not seasonal operation.
  - **2026 is complete to date**: 273 of 273 days through 30 September.

  Figure 1, directly above the caption, shows near-full bars for both years. A reader is told the gauge went seasonal again after 2024, which is false. The ≥ 360-day test is a proxy for "operated year-round", and it fails on a gappy year and on the year in progress. Fix it by testing winter coverage (for example, any Dec–Feb days in the year) or by treating the current partial year separately. Alternatively, phrase the claim as "year-round since 2011, and in 1971".

- **[severity: bug]** vignettes/station-flow.Rmd:366, :377-379. "At Bulkley River near Houston, 'from 2000' starts in 2010, its first window-year since then" is wrong for most of what the trend figure shows:
  - `since_2000_003` is the minimum over `kept`, across every window. That includes CH and BT incubation, which have no departure and no trend.
  - Only BT spawning and CO spawning have a 2010 window-year, because 2010 holds only 127 late-season days.
  - The other 6 trended windows start in 2011. That includes both significant 08EE003 results: CH emergence (n_years 14) and CH migration (n_years 16).

  The start year is derived a second time from a different table than the one the trends were fitted on. Derive it from the trend inputs instead, for example `aggregate(year ~ period, anom[anom$station_number == "08EE003" & anom$year >= 2000, ], min)`, and state the range ("2010 or 2011"). Or say 2011 and name the two exceptions.

- **[severity: fragile]** vignettes/station-flow.Rmd:359-360, :374-375, and :365. These sentences are built from computed values, but unlike the other data-driven claims in this file they have no guard:
  - If no two windows share dates after a knowledge refresh, `paste(same, collapse = " and ")` is `""` and the prose reads " share their dates, so they count once."
  - If two pairs share dates, "A and B and C and D share their dates" misstates which ones coincide.
  - If `n_sig` is 0, the text reads "0 are significant ..., all of them negative".

  None of this fires today. The other data-driven claims each carry a `stopifnot`, and these should too.
