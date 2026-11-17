# Review round 3: #166 branch (at 41582dd; report and script at 4293f2b)

## Checklist read

- code-check.md: under `## Mechanisms` I read the prose (table rows skipped) of four sections in full: "A guard that fails toward pass" (opening part), "Verification that reads its own output", "A guard's scope, escape hatches, and remedies" and "One fact derived twice". The other ten Mechanisms H3s I read by index line only. "Rules that stand alone", Security and Spreadsheets: index lines only (about 25 headings).
- code-check-r.md (read by heading): index lines only this round. Rounds 1-2 already read the full sections that apply to this diff ("`stats::aggregate()`…", "Postgres row order…", "`ifelse()` with an all-NA test…", "`match()` treats NA…", "duckdb in R: … `LOAD icu`…", "`system2(stdout = TRUE)`…"), and round 2 changed none of that code. About 145 headings not read in full.
- code-check-shell.md and code-check-spatial.md: index lines only. There is no shell code in the diff, and its spatial use is attributes from a zipped shapefile. About 110 + 130 headings not read in full.

## Verified without a finding

These were checked, and none produced a finding:
- **The report.** `data/logs/166/report_run7.txt` and `report_run8.txt` (both at 4293f2b) are byte-identical to the tracked report. `gmc_frozen.R` equals `scripts/gauge_monthly_compare.R` at HEAD, and no script changed between 4293f2b and HEAD.
- **Round-2 fixes.**
  - `verdict_off()` now prints only "unresolved". The "supported (theirs: …)" arms match lines 55-62 of the header. The per-year parity has no floor, which matches the 520b9ca rule.
- **Bin parity, recomputed read-only.**
  - I approximated the 87 shared Fraser segments from the bundle (my derivation of the subtree gave 257 sub-basins and 94,062 bins, against the report's 261 and 95,526).
  - Worst ratio with the +1e-9 floor: 0.342. Under the bare 2^-23 rule registered at 520b9ca: 0.376. So the floor changes no verdict, and "within float32 precision" (research line 75) holds in fact.
  - The floor does act on far more than "a bin of all-zero flow": 9,307 q_local bins and 326 q_acc bins have a mean |q| under 8.4e-3 m3/s, where 1e-9 exceeds 2^-23 of the mean.
- **Numbers in research/monthly_error.md lines 9-13, 21, 27-29, 34-38, 50-63, 71-97.** Each one equals its report line.

## Findings

- **[severity: bug, doc]** data/checks/gauge_monthly_compare_20260717.txt (the parity line, "(registered bound 1e-9)"); scripts/gauge_monthly_compare.R:32, 39, 64-69 and 712. Two bounds are called registered although they were written after the numbers they judge.
  - The HYDAT-years bound of 1e-9 relative was written into the header in round 2. That was after the round-1 and earlier reports had already printed the measured 5.9e-16 (`report_run1.txt`, `report_run3.txt` line 182).
  - The bin floor "plus 1e-9 m3/s" was also first written into the header in round 2. The code used it from ba29835 on, and `report_run1.txt` line 179 already showed "worst 0.34".
  - Both sit under the heading "rules (registered before the numbers they judge)". Line 39 says the rules come "before any number they judge is computed". The parity paragraph (lines 73-76) admits a later amendment only for the per-year days floor.
  - The report prints "registered bound 1e-9" for the HYDAT check. This is round 2 finding 2's defect again: round 2 removed "registered" from the floor it had loosened, and in the same commit applied the word to a new bound.
  - The direction is strict (0.02 tightened to 1e-9), so no guard fails toward pass and no number moves. Only the provenance claim is false.
  - Fix: name both as added after the numbers, in the parity paragraph and in the report line.
  - **Rule:** none
  - **Inside a round-2 fix?** yes

- **[severity: bug, doc]** research/monthly_error.md:12 (the bold lead "Neither PCIC's sub-basin resolution nor a late melt explains the shape loss that remains"); research/README.md:19 ("with neither PCIC's resolution nor a late melt explaining the rest"). Both state the "not supported" outcome that round 2 removed from the code.
  - The registered rules for checks 2 and 3 have two outcomes: "supported" or "otherwise unresolved". "Unresolved" means the check could not show the reading, not that the reading fails to explain the loss.
  - Round 2 changed the code label, the report line, the check-2 heading and line 12's parenthetical. The bold lead of the same bullet, and the README row, still assert that neither cause explains the loss.
  - The verdict vocabulary is written by hand in four places (code, report, research, README index), and the fix reached the places the round-2 finding named.
  - Fix: something like "Checks 2 and 3 are unresolved: the data show neither PCIC's sub-basin resolution nor a late melt behind the shape loss that remains", or simply "unresolved".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
  - **Inside a round-2 fix?** yes (line 12 was edited in round 2, and its lead was left as it was); README: no

- **[severity: bug, doc]** research/monthly_error.md:22. "The balance's regional errors are zonal levels, not a seasonal shape" is contradicted by two of the four zones listed under it, and by others in the report.
  - Zone 28 (the shared table, balance side): DJF +1.0, MAM −0.5, JJA +44.7, Jul-Aug +69.1. That is an error in summer alone, which is a seasonal shape. Line 26 itself quotes "+45 % in summer and +69 % in July–August".
  - Zone 25: +49.5 in winter against +8.0 in autumn and +8.9 in summer.
  - Zone 01: +23.0 DJF, −21.9 JJA, −31.0 Jul-Aug. Zone 07: +108.6 DJF, −20.3 JJA. Both are opposite-signed seasonal swings.
  - Only zone 24 (+47 to +62 %) and roughly zone 08 are level. The report computes no level-versus-shape statistic, so this sentence characterises the table beyond what it shows.
  - **Rule:** none
  - **Inside a round-2 fix?** no

- **[severity: doc]** research/README.md:19. "(not in every zone: Southern Thompson Plateau and Western Vancouver Island run the other way in July–August)" names 2 of the 5 unmarked zones where routed's July–August median is negative.
  - The other three: 16 Southern Quesnel Highland (−7.1, n 6), 13 Upper Fraser Basin (−2.8) and 05 Northern Central Uplands (−1.1). 16 is beyond the ±5 % the checks use.
  - The parenthetical exists to qualify a province-wide claim. A list that reads as exhaustive misstates which zones are exceptions.
  - This text came from round 1's fix, and round 2 checked its two values but not whether the list was complete.
  - **Rule:** none
  - **Inside a round-2 fix?** no

- **[severity: doc]** scripts/gauge_monthly_compare.R:73-76. The history paragraph misstates the first implementation.
  - At ba29835 the code divided by `pmax(q_m3s_pub, 1e-3)`. It floored the *denominator* at 1e-3 m3/s, an absolute bound of 1e-6 m3/s, not "the bound at 1e-3 m3/s", which would be 1,000 times looser.
  - It also leaves out round 1's intermediate floor (max(1e-3·pub, 1e-5 m3/s)), which was the floor round 2 actually found looser.
  - No number depends on this. It is the one paragraph the header uses to admit amendments, and it records the wrong one.
  - **Rule:** none
  - **Inside a round-2 fix?** yes

## Mechanism and enumeration

**Mechanism.** Every instance in rounds 1-3 shares one assumption: that the header at HEAD is the registered record, so header-agrees-with-code proves registration.

But each fix edits the header, the code and the report in the same commit. Round 2 added the 0.999 cut, the bin floor, the HYDAT bound and the "admits no difference" clause to the header beside their code. The two lists agree because one author writes both at once, so comparing them cannot disagree (code-check.md "Verification that reads its own output").

The independent reference is the header as committed at 520b9ca, set against the earliest report run that printed each number. The enumeration never consults it, and labels three rows "registered round 2". That phrase contradicts the header's own heading.

A second strand follows from the first: a verdict or bound is restated by hand in up to five places (code label, report line, research heading, research answer bullet, README index row, CLAUDE.md line 25). A fix reaches the instances the review named, not the claim.

**Verdict on the author's enumeration: not complete.** It compared header@HEAD with code@HEAD. Its candidate set left out prose and provenance. What it missed:

1. **Provenance of each amended rule.** I diffed header@520b9ca against header@HEAD. The rules added later are the check-2 "taken as above 0.999" text (its code predates the registration, so that one is honest), the bin "+1e-9" floor, the HYDAT 1e-9 bound, and "a published month of zero admits no difference". The parity paragraph names only the per-year days floor. The report still says "registered bound 1e-9" (Finding 1).
2. **Prose verdicts.** "Neither … explains" (research line 12, README) carries the removed third outcome (Finding 2).
3. **Characterisations beyond the numbers.** "Zonal levels, not a seasonal shape" (Finding 3). The README's exceptions list (Finding 4). The header's history paragraph (Finding 5).
4. **Refusal thresholds in code.** These are not listed although the stated candidate set covers refusals:
   - l.125, `all.equal`'s default 1.5e-8 tolerance for "the stored months give the stored scores";
   - l.468, the exact `share == 1`;
   - l.581, ≥ 20 days per HYDAT month;
   - l.570, the complete-years count;
   - lib l.290, the 366 bins per sub-basin.
   None of these sits above its source of truth, and none produced a finding.
5. **Candidates I checked that are not findings.**
   - CLAUDE.md line 25 says the gauge table "must equal the … bundle value by value". The code admits 1e-12 relative on routed month 0, and this run measured 0.
   - Research line 47 calls the 0.91 − 0.80 and 0.64 − 0.44 differences of medians "the shape gap". The header defines the gap as the median of per-gauge differences, and by that definition the under-100 km² value is about 0.09-0.10 (check 3's halves). "About 0.11" is close, but it is not the code's quantity.
   - Line 13's "37 % of the Fraser gauges" is 31 of the 84 gauges with flow in their lowest August. Line 97 discloses the exclusion.
   - The bin floor's stated purpose ("so a bin of all-zero flow compares") understates its scope: it governs about 10 % of the bins (see Verified). It moves no verdict.

To close the class mechanically, take the registered set from `git show 520b9ca:scripts/gauge_monthly_compare.R`, not from HEAD. Grep the report, research/, README and CLAUDE.md for "registered", "supported", "neither", "not", "every" and "across". Check each hit against that set, and check each amended rule against the earliest `data/logs/166/report_run*.txt` that printed its number.
