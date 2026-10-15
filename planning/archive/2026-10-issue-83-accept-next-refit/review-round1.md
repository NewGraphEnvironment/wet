# Code-check round 1 — branch 83-wb-fit-accept-r-cannot-accept-the-next-r (#83)

Reviewer: subagent, 2026-10-15. Probes ran in a copy of the sandbox
(`scratchpad/sb2`, driver `scratchpad/probe.R`); the repo's `data/` and the
original `sb` were not touched.

## Findings

- **[bug] scripts/wb_fit_accept.R:45-69 (and research/water_balance_method.md:315)**: a new fit whose pooled-zone test has never run is accepted. The guard fails toward pass.
  The pre-registered rule says the new fit is compared only after its chain is complete, including the pooled-zone test. The research section adds "The script refuses either fit otherwise." The per-fit check covers only `fits$code_md5`, `x$code_md5` and `aet_winner.txt` against `score_code_md5`. `pooled_test.txt` is not hashed into `score_code_md5`, and `pooled_variant.txt` exists only when the test fixed a variant. So a fit stopped after its first `wb_validate.R <winner>` is fully "current":
  - It has a winner, a current `fits.rds` and no pooled test.
  - It is scored nested and reported as "chosen inside each fold".
  - It cannot be told apart from a fit whose test was uninformative.

  If the pending test would then have fixed a variant, the fit that ships differs from the one accepted.
  Reproduced: copy the sandbox's `fit_20990101`, delete only its `pooled_test.txt`, and run `wb_fit_accept.R 20260717 20990101`. It exits 0 with "fit 20990101 ships (+0.00 points)".
  Fix sketch: require `<fit>/pooled_test.txt` for the new fit, and check it agrees with the scores:
  - line 1 is a variant: `x$cv_variant` must equal it.
  - line 1 is `uninformative`: `x$cv_variant` must be `"nested"`.

  This needs no change to any hashed file. Otherwise, drop "The script refuses either fit otherwise" for the pooled test, from the research text and the script header.

- **[fragile] scripts/wb_fit_accept.R:33-34, 85 (research/water_balance_method.md:319; #83 body)**: #43's tracked report `data/checks/wb_fit_accept_20260717.txt` can still be overwritten. The docs say it "stays its record" and the issue body says it "is never rewritten". The guards are only `args[1] == wb_shipped_release` and `args[2] != args[1]`, and the report path is keyed on `args[2]`. Once `wb_shipped_release` moves to the next release N, the reverse run `wb_fit_accept.R N 20260717` passes both guards. `fit_20260717` stays current as long as the scoring code is unchanged, and `wb_fit_lib.R` is deliberately outside `score_files`, so the run overwrites the 20260717 report with a backwards comparison.
  Reproduced in `sb2`:
  1. Set `wb_shipped_release <- "20990101"` in `scripts/wb_fit_lib.R`.
  2. Run `wb_fit_accept.R 20990101 20260717`.

  It exits 0. The md5 of `wb_fit_accept_20260717.txt` changed from `92ec32e9…` to `e3300fdf…`, and the report's first line now reads "Does the fit on HYDAT 20260717 ship in place of 20990101?". The same hole lets any release older than the shipped one be "accepted" against it.
  Fix sketch: require the new release to be later than the shipped one: `grepl("^[0-9]{8}$", args[2]) && args[2] > args[1]` (YYYYMMDD strings order correctly). Or refuse when the report file already exists for a release that has been shipped.

- **[fragile, comment only] scripts/wb_score_md5.R:21-26**: the comments still say `aet_md5_for()` and `fits.rds$aet_md5` are what `scripts/wb_fit_accept.R` compares across releases. After this branch nothing reads `aet_md5` or calls `aet_md5_for()` except this file's own `aet_code_md5`. The text now describes a check the code no longer makes. Note that `wb_score_md5.R` is in `score_files_for()`, so editing even its comments stales every fit. Leaving it is defensible, but the stale sentence should be recorded, for example in #85 or the next scoring-code change, rather than forgotten.

## Checked and found sound

- `score_md5_for()` (`wb_fit_accept.R:39-44`) computes what `wb_validate.R` stamped:
  - `new.env()`'s parent is the function frame, then global. The env's own `release` shadows anything outside, and the script defines no global `release`, `fit_dir` or `key_dir` that the recipe reads.
  - The recipe uses only `wb_stations_path()`, `wb_fit_dir()`, `wb_key_dir()` (global, from `wb_fit_lib.R`) and `wet_md5_text()` (attached by `load_all()`).
  - `wb_cv_lib.R` sets `release <- wb_release()` and `fit_dir <- wb_fit_dir(wb_key_dir(), release)` before sourcing the same file, so the inputs are identical.
  - A missing stations file stops inside the recipe, which is a refusal.
- Edited decision files, a stale or missing winner, a winner naming another AET, and the wrong release in `fits.rds` or the cv file all refuse, before the report is written.
- `fit_20251014` as the new side is refused, because its `code_md5` predates the current scoring code, before `wb_report()` would pick the unsuffixed name.
- Nothing else in `scripts/` or `R/` relied on the removed `aet_md5` check or on the removed same-AET stop. `discharge_publish.R` keeps its own cfu stop, now pointing at #85, which exists, is open and has the right title.
- The claim that an AET switch exists only through `aet_decision.txt` holds: `wb_aet_compare.R:173-175`, plus `wb_cv_lib.R:130-133` for a fit missing the shipped fit's decision.
- The CLAUDE.md bullet is accurate: it describes the chain as a precondition, not a check.

planning/active/review-round1.md
