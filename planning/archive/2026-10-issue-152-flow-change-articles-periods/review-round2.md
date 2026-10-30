## Checklist read

- **code-check.md**: I read the prose of all 14 `## Mechanisms` H3s. I did not read the other 23 headings (the stand-alone rules, Security, and Spreadsheets and PDFs), because this diff touches none of their tools.
- **code-check-r.md**: I read 7 sections:
  - "Moving prose into a code chunk hides it from tools that scan the document"
  - "A `data-raw/` script must load the source tree, not the installed package"
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "Regenerated binaries churn git even when nothing changed"
  - "`nzchar(NA)` is TRUE — non-empty checks silently pass NA"
  - "`sub()` takes one replacement, not one per element"
  - "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"

  I did not read the other 108.
- **code-check-shell.md**: I read the index only and none of the 70 sections. The diff contains no shell.
- **code-check-spatial.md**: I read the index only and none of the 93 sections. The diff adds no spatial code; the compass and atan2 helpers are unchanged.

Method: I read the full diff and the current text of every changed file. I loaded `chinook_sites_values.rds` and `station_daily.rds` and checked every quantified sentence in both articles against the data. I rendered all three articles (flow-change-sparse-gauges, flow-departure-normal and segment-discharge) in a temp copy of the repo. All three rendered, every guard passed, both word caps held, and every citation key has a .bib entry.

### Round 1's fixes

- **Fix 1** holds: the BULK-only guards now match "the Bulkley's windows".
- **Fix 2** holds: "7 of 8" is the BULK 4×2 set, which the sentence names as "windows and boxes".
- **Fix 3** holds: the bundle's md5 equals the report's (2ab0f583…).
- **Fix 4** holds: in 2016–2025 every series lacks only 2025, except all four Swift series and Naver's migration filled-in series, which have it.

## Findings

- **[severity: bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:515–516 (guards at 128–137 and 500–502): "Filling in a record scores poorly only in the upper Fraser" is not true against the bar set two sentences earlier ("A score of 0.5 was set as the method's bar").
  - The filled-in (ols) scores are in `v$score_settings`, BULK:
    - Migration: Gosnell's box scores 0.48, below the bar. The table directly above prints it as 0.48, and Maxan's sits at 0.50.
    - Spawning: Maxan 0.42, Naver 0.44 and Gosnell 0.44 are all below the bar. Gosnell scores 0.49 under the Morice windows.
  - The guards only check that Naver and Gosnell are within 0.15 of Maxan, and that Swift is at least 0.2 below Maxan and under 0.2. No guard tests a box other than Swift against 0.5, so "only" is unguarded.
  - The same paragraph calls the borrowed route's spawning scores (0.42–0.49) "below the bar" and says their ranges "carry that weaker score". The filled-in spawning scores are just as low (0.42–0.44), and the filled-in spawning drops the article quotes (Maxan −57 %, Naver −40 %, "27%–57%") rest on them, without that caveat.
  - **Rule:** code-check.md "A proxy is not the property" ; code-check.md "A guard's scope, escape hatches, and remedies"
  - **Inside round 1's fix?** no. The sentence appears as unchanged context in 2d9309a; this branch rewrote it from "about the same in the Bulkley, Cottonwood and Morice boxes, and poorly in the upper Fraser".

- **[severity: bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:155–156 and 462–464 (guard at 105–108): the lowest seven-day flow "fell at Maxan, Naver and Gosnell creeks and held at Swift Creek", and later "At three of them … fell by 26% to 40%". The data do not support these as stated. All values are BULK, spawning, borrowed unless noted.
  - **(a) "Fell" despite ranges that reach no change.** Naver's change is −33 % (90 % range −56..+5) and Gosnell's is −26 % (−49..+13). Both ranges reach no change; only Maxan's (−40 %, −63..−2) stays below it. The same opening paragraph calls a range that crosses zero "no clear change" (the migration window), and for the mean it names only the streams whose range "stays below no change". A reader takes "fell" as clear. The guard `pct < -10` stands in for "fell" and never looks at the range. The min7 held-out score is also below the bar in 7 of 8 window-box pairs (0.23–0.59).
  - **(b) Neither sentence names the route.** "Held at Swift Creek" is true only for the borrowed route (+1 %). The filled-in route, drawn in the same change figure's bottom panels, has Swift falling −18 % (−42..+16).
  - **(c) "At three of them" points at the wrong set.** It directly follows "filling in each gauged stream's own record gives drops…", which reads as the three gauged streams (Maxan, Swift and Naver, filled in). Its set and numbers are the borrowed route's {Maxan, Naver, Gosnell}, 26–40 %. The filled-in min7 drops at the three gauged streams are 18–58 %.
  - research/chinook_sites.md's bullet "falls at Maxan, Naver and Gosnell and holds at Swift" repeats (a) and (b), although its own table prints the ranges.
  - **Rule:** code-check.md "A proxy is not the property" ; code-check.md "A guard's scope, escape hatches, and remedies"
  - **Inside round 1's fix?** no. Round 1 removed the adjacent min7 score sentence but left these two.

- **[severity: fragile]** vignettes/articles/flow-change-sparse-gauges.Rmd:553–555 (guard at 538–542): "measured flow at all 8 snow gauges … 25–62%" comes from a BULK-only guard (`og`), and the sentence does not say "under the Bulkley's windows". Under Gosnell's Morice windows, 08ED001's migration fit explains 63 % (`v$snow`, MORR, observed, swe, r2 0.631), outside the printed range. This is round 1 fix 1's shape again, one section over. The other snow sentences ("at all four … 41–51%", "at most 16% / 31% / 23%") also hold under the Morice windows, so this range is the only one affected.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
  - **Inside round 1's fix?** no (same mechanism as fix 1, but a sentence it did not touch).

- **[severity: fragile]** vignettes/articles/flow-change-sparse-gauges.Rmd:100–102: this guard quotes a sentence that is not in the article ("the filled-in record at Maxan Creek falls in the migration window too": `mx_mig$pct_hi < 0`). No prose reads `mx_mig`, so after a rebundle it can stop the build over a claim the article does not make. The finding it encodes also goes unsaid. Maxan's filled-in migration mean fell −28 % (−46..−5), as research/chinook_sites.md records. The article says only that the borrowed departures show no clear change in that window, while its change figure draws the filled-in fall. Either restore the sentence or drop the guard.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
  - **Inside round 1's fix?** no

- **[severity: fragile]** research/chinook_sites.md (#152 table, Swift row, spawning mean): the extended change is given as "−28 %", but the value is −27.46 % (`exp(-0.320984571) - 1`). It was rounded twice, from the report's printed "−27.5". This is a wrong number in the durable record, though not in an article.
  - **Rule:** none
  - **Inside round 1's fix?** no (the fix touched the paragraph above this table)
