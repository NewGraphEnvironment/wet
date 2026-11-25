# Plan review for #211 (backlog move 18: natural non-HYDAT stations as donors)

Blockers raised: 1
Owner forks: 2

Reviewed 2026-11-25 by a Plan subagent reading the first draft of `task_plan.md` against #211, #202 and the code, before the baseline commit. Each finding was probed before it was folded or declined; the probes' numbers are in `findings.md`. The reviewer's overall verdict on the first draft: not buildable as written, the scope reasoning sound.

## Blocker

- **B1. The extension call fails for every station whose record runs past HYDAT's approved years.** `wet_window_extend()` keeps a donor only if it holds every year the target has (`R/wet_window_extend.R`, the `covers` test), and the draft gave it all of a station's observed years. **Confirmed:** 14 natural stations hold a 2026 migration window-year and 22 hold one in 2025 or 2026; of natural BC HYDAT gauges, 272 hold May–July 2024, 120 hold 2025, none 2026. **Folded:** the rule defines fit years (usable values through 2024); later years enter the carry as observed; `dd_fit_years()` and its test are in Step 1. Through 2024, 33 stations keep at least 3 years.

## Gaps

- **G1, G2. The `stations` table of each extension and of the carry with the stations was not stated.** Confirmed (`wet_station_space()` takes its SDs over every row given). Folded: one table per held-out gauge, the box pool plus every candidate, for every extension, statistic and pool.
- **G3. "At least 3 window-years" did not say of what.** Confirmed against the site script's pools. Folded: a candidate needs 3 migration-mean window-years; eligibility needs 3 usable fit values of the statistic itself.
- **G4. The held-out set for the other statistics was undefined.** Folded: each statistic's own province-wide departure pool.
- **G5. No instruction for a gauge with no HYDAT donor left.** Confirmed (`wet_departure_carry()` stops with "`x` has no donor rows"). Folded: not scored, counted, and a test case.
- **G6. "Can be extended" invited a blanket `tryCatch`.** Folded: each reason is checked before the call and counted; any other error stops the run.
- **G7. Stations at another HYDAT gauge's site.** Confirmed: 16 natural stations sit at a HYDAT site, 4 where HYDAT flags the gauge regulated. Decided in the plan, not put to the owner: the population stays #196's registered `"natural"`, with a registered sensitivity that leaves both kinds out and a report line listing them.
- **G8. The leak-free relation for stations named no codes.** Confirmed in `scripts/station_regulation_lib.R` (`rg_sql_snap`). Folded: the watershed polygon's codes through the lookup, named in the rule.
- **G9. Station areas had no reachable source.** Confirmed: the shipped file carries no area; 37 natural stations were placed by name alone. Folded, simplified: fwapg's upstream area at the placed segment for every station, one source; none means not a candidate.
- **G10. The unchecked-day sensitivity cannot come from `wet_window_stats()`.** Confirmed (`frac_provisional` counts every status but approved). Folded: read from the daily rows, stated in the rule.
- **G11. "k = 3 and 8" and "at least 5 window-years" were ambiguous.** Folded: the carry's k, the extension's staying 5; 5 fit years of the statistic.
- **G12. No amendment protocol.** Folded into the rule's header, as #196 stated its own.
- **G13. What the PR closes was not stated.** Decided in the plan: `Fixes #202` and `Fixes #211` on either verdict.
- **G14. Smaller items.** Folded: the box centre rounded to 2 decimals (confirmed to reproduce Swift's and Naver's rows exactly); `dd_ship()`'s check order follows `site_carry_ship()`; a test for the held-out gauge's own site; the superseded sentences in `research/station_sources.md` listed by line.

## Assumptions

- **A1. Scored years are chosen by one carry's donor list, and a station among the 5 nearest pushes out a HYDAT donor in the years it has no value too.** Holds (the carry picks its k once and renormalises per year). Folded as a reported line, split by years with and without a station; whether it joins the verdict is Open decision 2.
- **A2. The draft's third invariant was false:** the two tables' SDs differ, so the fifth and sixth nearest HYDAT donors can swap. Holds. Folded: now a reported count, and the asserted invariant is that neither the held-out gauge nor a related one reaches an extension chain or a donor string.
- **A3. The margin has no noise guard.** Folded as reported lines (gauges better and worse, a bootstrap interval); joining the verdict is Open decision 2.
- **A4. Gauges are not independent of each other.** Folded as reported lines (distinct stations, the median by station); a floor is Open decision 2.
- **A5. A station's level over its fit years is its extension gauge's.** Holds (OLS residuals sum to zero). Folded: the plan and `findings.md` now say that only the year-to-year part is the station's, that no gain is the likely result today, and Open decision 1 says so to the owner; each station's fit years, slope and chain are reported.
- **A6. Three phases against #211's "one phase".** Folded: one phase in three steps.

## Ordering

- **O1. An end-to-end test before the registering commit.** Folded: `dd_gauge()` lives in the rule file and is tested through both real functions in Step 1.
- **O2. The rule header pointed at a section of the plan.** Folded: the counts are embedded in the header, dated, as seen.
- **O3. Step 1 publishes counts with no tracked producer until Step 2.** Folded: marked as seen; Step 3 reconciles the research section to the report, and the header's copy is not corrected.

## Scope

- **S1. #211's four gate questions answered by the plan rather than asked.** Declined as owner forks: each is mechanism, decided under "Decided at the gate" with its reason, and the owner can overturn any of them at Open decisions, where the plan goes anyway.
- **S2. `tests/testthat/test-wet_station_select.R` dropped silently from the Touches list.** Folded: named as read, not edited.
- **S3. The continuation piece was filed nowhere.** Folded: Step 3 files it as its own issue naming move 18; the selector follow-up stays conditional on a pass.

## Acceptance

- **V1. Nothing proved the carry without the stations is #120's.** Folded: the script asserts its pools at 08KA012 and 08KE014 against the Swift and Naver site reports' counts lines (30, 11, 13 and 58, 17, 24).
- **V2. Invariants.** See A2.
- **V3. "No change to R/" had no proof.** Folded into Validation.
- **V4. The byte-identical rerun proved determinism after the cache, not the cache.** Folded: the reported run starts from an empty cache.

## Owner forks

- **Scope (a), (b) or (c):** already Open decision 1; the review's A5 is now in its text.
- **The bar:** Open decision 2, raised by A1, A3 and A4.
- Three more the reviewer labelled owner forks are decided in the plan as mechanism, each named above: the four gate questions (S1), the stations at HYDAT sites (G7), and what the PR closes (G13).

## Files the plan names

tests/testthat/test-departure_donors_rule.R
tests/testthat/test-departure_site_rule.R
scripts/departure_donors_rule.R
scripts/departure_donors.R
scripts/departure_site.R
scripts/departure_site_lib.R
scripts/departure_sites.csv
scripts/station_regulation.R
scripts/station_regulation_lib.R
R/wet_window_extend.R
R/wet_departure_carry.R
R/wet_station_select.R
R/wet_station_list.R
R/wet_station_daily.R
R/wet_window_stats.R
R/wet_station_snap.R
inst/vignette-data/life_history_bulk.csv
inst/extdata/station_sources/regulation_20261028.csv
data/checks/departure_donors_20260717_20261028.txt
data/checks/departure_site_swift_bulk_20260717.txt
data/checks/departure_site_naver_bulk_20260717.txt
research/chinook_sites.md
research/station_sources.md
research/README.md
NEWS.md
CLAUDE.md
