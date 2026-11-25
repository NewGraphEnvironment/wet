# Code check, round 1 (#211, `git diff origin/main...HEAD`, planning/ excluded)

## Checklist read

- **code-check-r.md**, read in full: "`on.exit()` at a script's top level never fires"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "`tryCatch()` nests its handlers, so a `stop()` in one is caught by a later one"; "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"; "A `skip_if_not()` skips only its own `test_that()` block"; "Under `R CMD check`, tests run from a temp dir against the INSTALLED package". About 165 other headings not read beyond their index line.
- **code-check-spatial.md**, read in full: "FWA lookup area follows watershed codes, so side channels get the river's"; "A relation between FWA watershed codes is not a place". About 105 not read beyond their index line.
- **code-check-shell.md**: none read in full (the diff has no shell code). About 115 not read beyond their index line.
- **code-check.md**: the prose of all 14 H3s under `## Mechanisms`, with their `|` table rows skipped. "Written data outlives the fix" and "A guard's scope, escape hatches, and remedies" were then read again closely. None of the "Rules that stand alone" were read beyond their index line.

Probes, all read-only (the repo was not modified):
- Every natural station's placed segment, checked in local fwapg for side-channel edge types and for a polygon whose code differs from the segment's. Only one segment is not a main-flow type: Sam Hill Creek, edge type 2000, same code, 0.2 km². No station sits on edge type 1100, 1150, 1300 or 1350, so the side-channel area rule does not bite here.
- The script's cache under `data/departure_donors/68abdc9c06/`. Across every statistic and window, the most 1981–2010 window-years any station holds is 5 (1AHA040), so "none holds 10 years of 1981–2010 record" holds beyond the migration mean. HYDAT donor displacement in the scored years (finding 1).
- `git diff a7455e45 HEAD -- scripts/departure_donors_rule.R` is empty, and the rule file's md5 is 39cf1cd3…, as the report prints.
- A minimal Rscript showing that `on.exit()` inside an expression forced through `cached()` never fires (finding 3).

Rule file: no defect found in `scripts/departure_donors_rule.R`. I traced its functions (dd_gauge, dd_pools, dd_candidate, dd_baseline_rows, dd_scored_years, dd_ship) against the rule header and against `wet_window_extend()` and `wet_departure_carry()`. Nothing below changes a number the report prints.

## Findings

- **[severity: fragile]** research/chinook_sites.md, the "Result" bullet "**The stations do not displace HYDAT donors in a way that matters.** … in no scored gauge-year are the HYDAT donors with the stations other than those without."
  - The report line behind this ("Scored gauge-years whose HYDAT donors with the stations are not among those without: 0 of 263") tests only that the HYDAT donors with the stations are a *subset* of those without. It does not test that they are the same set.
  - `wet_departure_carry()` takes the k = 5 nearest of every donor with rows (`wet_donor_mean()`'s `order(dist)[seq_len(k)]`). So a station among the donors takes a HYDAT gauge's slot by construction.
  - Measured from `results.rds`: in 210 of the 263 leave-one-out scored gauge-years, and 217 of 282 leak-free, the carry with the stations used fewer HYDAT donors than the carry without. So the bolded "do not displace" is false as written, and "other than those without" reads as "the same as".
  - The "+0.001 in the years none is" line supports something narrower: losing the displaced HYDAT donor costs little in the years the station has no value.
  - Suggested wording: every HYDAT donor with the stations is one of those without; in about 80 % of scored years a station takes one HYDAT gauge's place, and in the years no station has a value, that loss is worth +0.001.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (its compression paragraph: a restatement that gained a claim its evidence never measured)

- **[severity: fragile]** NEWS.md:5 and CLAUDE.md (the "Chinook pilots beyond Maxan" paragraph), "median RMSE +0.032 leave-one-gauge-out, +0.015 leak-free".
  - Both numbers are the *median paired difference* (with minus without, per gauge), not a change in the median RMSE.
  - The report's own quartiles put the median RMSE at 0.275 → 0.300 (+0.025) leave-one-out and 0.274 → 0.303 (+0.029) leak-free. Read literally, the leak-free figure is off by about a factor of 2.
  - research/chinook_sites.md words it correctly ("the median paired difference in RMSE is +0.032").
  - NEWS is public text.
  - **Rule:** none

- **[severity: fragile]** scripts/departure_donors.R:83–92 (`cached("hydat_stations", { con <- …; on.exit(DBI::dbDisconnect(con)); … })`) and :146–166 (`cached("fwapg", { conn <- connect(); on.exit(DBI::dbDisconnect(conn)); … })`).
  - `expr` is a promise forced inside `cached()`, but it is evaluated in the global environment. So `on.exit()` finds no closure frame to attach to and registers nothing.
  - Reproduced: `cached <- function(n, expr) { v <- expr; v }; cached("a", { on.exit(message("EXIT")); 1 })` under Rscript never prints EXIT.
  - The HYDAT SQLite and fwapg connections stay open for the whole run (main run plus five sensitivities, about 40 minutes by the cache mtimes). No number moves.
  - Fix: disconnect explicitly before the block's value, or wrap the block in `local()`, which gives `on.exit()` a frame.
  - **Rule:** code-check-r.md "`on.exit()` at a script's top level never fires"

- **[severity: fragile]** scripts/departure_donors.R:59–60, the cache key `digest(paste(release, dd_snapshot, rule_md5))`.
  - The cached inputs depend on more than the key covers:
    - the windows read from `inst/vignette-data/life_history_bulk.csv`;
    - the `stats` vector;
    - the station list (`wet_station_list()` and `regulation_20261028.csv`), which picks the stations whose days are read and the segment ids sent to fwapg;
    - wet's own `wet_station_daily()` and `wet_window_stats()`.
  - After any of those changes, a rerun silently reuses the old inputs and rewrites the old report. CLAUDE.md cites that as "byte-identical on a rerun from its cache", so the check cannot fail.
  - A sharper case: `st_o` is rebuilt outside the cache on every run, but `fw$lookup` holds only the segment ids from the first run. A station added or re-placed later gets `NA` area and code, and drops out of candidacy with no error.
  - Nothing moves today. The fix: fold the md5s of `life_history_bulk.csv` and the regulation CSV, the `stats` vector, and wet's version into the key. Or refuse a lookup missing any `st_o` segment id.
  - **Rule:** code-check.md "Written data outlives the fix"

index, diff and changed files read from file
