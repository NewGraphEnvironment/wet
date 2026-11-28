# Code-check round 2 (#238)

## Checklist read

- code-check.md: I read the prose of all 14 H3 sections under `## Mechanisms`, skipping their table rows. Most closely: "A guard that fails toward pass", "A proxy is not the property", "A guard's scope, escape hatches, and remedies" and "Restore the bug and prove the guard fires". I read no heading under "Rules that stand alone", Security or Spreadsheets (none applies); about 30 headings not read.
- code-check-r.md: I read "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising…", "`\<` and `\>` are word boundaries…", "`nzchar(NA)` is TRUE…", "`$` on a list partial-matches…", "`paste()` with a zero-length argument…", "Rscript reads a script as it runs…" and "`sort()` and `order()` collate by `LC_COLLATE`…" from the index, with their full text where the diff touches the pattern. The rest (about 140 headings) were not read, because the diff does not use their tools.
- code-check-shell.md: none read. The diff has no shell code.
- code-check-spatial.md: none read. The diff has no spatial code.

Verified against the code and the tracked reports:
- The Choices table: the check passes, and its 64 rows match `file:line` (rerun in a scratch worktree; the output matches the committed log line for line).
- The claims in both research files: the leak-free pool and its folds, the caps, the air gap, the 180-day threshold, the regression and mean intervals (t with n−p and n−1 degrees of freedom), the statistic, the tie rule, the recovery's coverage (0.896–0.902), 298.0 and 97.5, 4.1 and 11.5, 130.43 and 128.74, −0.49, `scores_edfbc29809.rds`, gsdd 0.3.0.9007, and the documented columns of `wet_station_snap()` and `wet_temp_daily()`. I found nothing false.
- Round-1 fixes: fix 2 (exit 2 without the books) and fix 3 (the leak-free wording) are correct. Fix 1 is only half applied: see the first finding.

## Findings

- **[severity: bug]** scripts/temperature_bayesian_alignment_check.R:166 — the sign of a figure is never checked. Round 1 put `−` and `-` into `has_whole()`'s lookbehind (line 170). The extractor `unit_rx` still has only `(?<![0-9.,])`, so it pulls `4 °C` out of `−4 °C` (and `5 °C` out of `-5 °C`). The bare figure then matches the listed `4 °C` / `5 °C` entries and passes. Probe: I appended "The water fell to −4 °C and to -5 °C." to a copy of `research/temperature_network_model.md` and ran with `MD=<copy>`. Result: `figures: 2 numbers with a unit … PASS`, exit 0. A figure written with the wrong sign, or with a sign its source does not have, passes. This is the round-1 defect one axis over: the fix landed in the matcher but not in the extractor that feeds it. A related gap: a number preceded by `.` or `,` (`1,600 %`, `.5 °C`) is not extracted at all, so it is skipped rather than failed.
  - **Rule:** code-check.md "A guard that fails toward pass" ; code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** scripts/temperature_bayesian_alignment_check.R:330-333 — the unlisted-figure check asks only whether the bare number-with-unit string appears inside some listed entry that is somewhere in the file. It never asks whether this occurrence is the one the entry describes. So entries written with context (`nominal 95 %`, `95 % of the basin`, `traits 50 %, network 25 %, noise 25 %`, `90 % interval`, `0.1 °C`, `4 °C`) let the same number pass anywhere, with any meaning. Probe: I appended "The fill covers 95 % of stations, and obs noise is 0.1 °C where 50 % of days are 4 °C." to a copy of the research file and ran with `MD=<copy>`. Result: `figures: 21 numbers … PASS`, exit 0, all four new claims unsourced. The literal check on each entry's source does not help, because it runs once per entry, not once per occurrence. In practice "held to its source" holds only for the first sentence that uses a number; later restatements, including a wrong value that collides with a listed one (say `0.1 °C` written where `0.01 °C` was meant), pass. Every current occurrence does sit inside an entry's text (checked: the only ones outside are inside a checked quote), so nothing in the files is wrong today. The fix: require each occurrence's span to fall inside a whole-match of some listed entry's text in the file, not just inside the entry string.
  - **Rule:** code-check.md "A proxy is not the property" ; code-check.md "A guard that fails toward pass"

index, diff and changed files read from file
