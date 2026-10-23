## Outcome

The monthly-flow article's Chinook window table gives each source twice, from its published months (day-weighted) and from its published days (`segment_daily`, #99), each against the gauge's daily record, so a reader sees what the days add. In the fry-migration window, the one where a window from monthly means is poor, the gauge's own days run 21 % (Buck Creek, 08EE013) and 20 % (08EE003) below its monthly means. Routed PCIC's days fall further (33 %, 24 %), and its error against the daily record goes from +39 % to −7 % at Buck Creek and +60 % to +21 % at 08EE003. The balance's days fall 21 % at Buck Creek, as the gauge's do (its donor shape there is the gauge's own), leaving its annual error of −12 %; at 08EE003 they fall only 5 % and the error stays +356 %. In migration the days move no window by over 1 %; in spawning by up to 9 %. The data script (`data-raw/monthly_vignette_data.R`) reads the three segments' days from the live build (77585a8) and checks them as the publish does: routed PCIC routed again from the run's sub-basin days on only the sub-basins the three weights name (the publish's tie rule; 0 ties), the balance made again from its published months and the fit's daily shape where the fit copy holds the watershed's predictors (two of three on m1's reduced bundle), and every segment's day means held to the published months. The article also took #110's writing items for itself alone: software in code font and linked, no issue pointers, "What's next" cut, a computed "Software and citation" section. What we learned: the days do not "close the gap" by themselves; each source's days move a window by that source's own within-month shape, so where the balance's donor shape is not the gauge's (08EE003) the days barely move it. Closed by: PR (opened from branch `107-monthly-flow-article-chinook-windows-fro`).

## Measurement

Fry-migration window, two gauges: gauge's days vs its monthly means −21 % / −20 %; routed PCIC's days vs its months −33 % / −24 % (error +39 % → −7 %, +60 % → +21 %); balance's days vs its months −21 % / −5 % (error +12 % → −12 %, +379 % → +356 %). Migration: every move under 1 %; spawning: under 10 %. Bundle checks: 8 rows, 0 differing (routed days 1,095 compared at `tol = 0`, balance days 730 at the default tolerance, months-from-days 36 within 1e-9); 0 routed days at a rounding tie. Bundle 134 KB. Article text 2,413 → 2,992 words.

## Evidence

- `data/logs/107/monthly_vignette_data.log` (the passing run; the first run's refusal is in `findings.md`), `data/logs/107/devtools_test.log`
- `review-plan.md` (12 findings, 7 covered, 5 taken), `review-round1.md` to `review-round3.md`
- The rendered before/after text diff: scratch only; its hunks are listed in `findings.md`

## Owed

- #110's body: the monthly-flow bullets confirmed done under #107 at merge (its body already says they are taken here).
- m1's `pcic.subbasin_daily` now holds the 1981–2010 run only; the 1951–2012 run's days were never loaded there (nothing reads them).

## Code-check (branch, three rounds)

| Round | Findings | Fixed | Accepted | Inside previous fix? |
|-------|----------|-------|----------|----------------------|
| 1 | 1 | 1 | 0 | — |
| 2 | 1 (+1 wording note taken) | 1 | 0 | n |
| 3 | 1 | 1 | 0 | n |

Ended by enumeration: round 3 named the mechanism (prose stating a fact the data or layout holds, with no guard tying the sentence to it) and listed every changed sentence stating a count, direction, sign, position or set with what ties it; after the round-3 fix the only untied ones describe the file's layout or a declared contract, which another build of the bundle cannot move.
