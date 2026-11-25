# Code check, round 2 (#211, `git diff origin/main...HEAD`, planning/ excluded)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms`, `|` table rows skipped. Read again closely: "Written data outlives the fix" (its cache-key sentence), "A guard's scope, escape hatches, and remedies", "A guard that fails toward pass" (its "A comment stating a property is an unexecuted claim" paragraph). Of the "Rules that stand alone", only "Documentation Staleness" read in full; the rest (about 20) not read beyond their index line.
- **code-check-r.md**, read in full: "`on.exit()` at a script's top level never fires"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "`tryCatch()` nests its handlers, so a `stop()` in one is caught by a later one". About 168 others not read beyond their index line.
- **code-check-spatial.md**: none read in full. Round 1 checked the FWA lookup rules against the stations' segments, and this round's fixes touch no spatial code. About 107 not read beyond their index line.
- **code-check-shell.md**: none read in full (no shell code in the diff). About 115 not read beyond their index line.

Probes, all read-only:
- `local({ on.exit(...) })` passed as a promise into a `cached()`-shaped function, run under Rscript: the exit handler fires before the caller continues. So fix 3 works.
- Recomputed the widened cache key from HEAD's files: it is `fe71f98c40`, the one directory under `data/departure_donors/`. Its rds files are dated 12:52:35 to 13:26:45, after the last commit to the script (12:52:32). So the tracked report was written by HEAD's code from a cache built under HEAD's code.
- Read the rule header's Scored years and `wet_departure_carry()`. Donors are chosen once (the k nearest with any rows), and a donor with no value in a year is dropped and the rest renormalised. So the report's new "fewer" count, the "none is" split, and the research's reading of both match what the code does.
- Checked research/chinook_sites.md's Result section against report sections 1 to 6. Every number checked agrees. The 25 stations by drainage prefix sum to 25. The 179 window-years "in 2010 or later" equal the 2010s plus 2020s rows. The −3.55 to 6.76 slope range equals the eligible-station table's extremes. Every other scored statistic has a positive median except migration cov_day.

Rule file: the round-1 fixes do not touch `scripts/departure_donors_rule.R`, and I found no defect in it. Nothing below changes a number the report prints.

## Findings

- **[severity: fragile]** scripts/departure_donors.R:59–66, and the header comment at :15–16.
  - The new comment says "the key covers every input the cache holds". The key still omits two inputs:
    - The script's own cached blocks: the HYDAT SQL in `hydat_stations`; the day-status logic and the `wet_window_stats()` arguments in `outside_window_stats`; the fwapg SQL; and the choice of which HYDAT gauges `fwapg` snaps (`pool_ids`).
    - The fwapg database itself.
  - So an edit to any cached block's code, or a reload of fwapg, makes a rerun silently reuse the old `.rds` and rewrite the old report byte for byte. CLAUDE.md offers that rewrite as the check ("byte-identical on a rerun from its cache").
  - This is round 1's finding 4, one axis over: the fix hashed wet's `R/` but not the script that holds the cached expressions.
  - The header at :15–16 still describes the old key ("the md5 of the release, the snapshot and the rule file"), so the two comments now disagree.
  - Nothing moves today: the probe above shows the cache was built under HEAD's script.
  - Fix: add `scripts/departure_donors.R` (or just the text of the cached blocks) to `key_files`, and correct the header line. For fwapg, either name it in the key (for example its fwapg commit, as other scripts record `WET_FWAPG_COMMIT`) or say plainly that the key does not cover it.
  - **Rule:** code-check.md "Written data outlives the fix" ; code-check.md "A guard that fails toward pass"

- **[severity: fragile]** research/chinook_sites.md, the rewritten Result bullet: "In the 2011–2025 years no station has a value, where the carry renormalises over the HYDAT donors left, the median difference is +0.001".
  - Read as written, the clause states that no station has a value in 2011–2025. That is false: the scored years are, by the rule, exactly the 2011–2025 years in which a station is among the donors, and the stations' records are almost all after 2010.
  - The report line it rests on ("0.0014 in the years none is") means "in those 2011–2025 years in which no chosen station has a value".
  - This is the sentence round 1 rewrote, and the new wording loses the restriction that the old one ("In the 2011–2025 years no station is among the donors") also only implied.
  - Suggested wording: "In the 2011–2025 years in which none of the chosen stations has a value, the carry renormalises over the HYDAT donors left and the median difference is +0.001".
  - **Rule:** none

Everything else in the round-1 fixes checks out:
- The NEWS and CLAUDE.md wording now names the median paired difference, and the values match report section 3.
- The `local()` wrappers fire their `on.exit()`.
- `rsort()` is no longer used before its definition, and the radix sort keeps the key locale-independent.
- The new "fewer" count is computed from the per-year donor strings of the same scored years as the "not among" count.

index, diff and changed files read from file
