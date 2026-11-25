# Code review, round 1 (#187): branch diff cbeb3489...HEAD (2291851e)

## Checklist read

- **code-check.md:** I read the prose of all 14 H3s under `## Mechanisms`, skipping the `|` rows. The ones that bear on this diff are "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree, and what generators leave in it", "A wrapper's exit is not the work", "Zero-length, empty, and unset are three different things", "The probe is broken before the world is", "Written data outlives the fix", "Serialization loses meaning silently" and "One fact derived twice". I did not read the other 24 headings (the standalone rules, Security, Spreadsheets and PDFs) beyond the index.
- **code-check-r.md:** read "A `skip_if_not()` skips only its own `test_that()` block", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires", "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests", "`paste()` with a zero-length argument returns length ONE, not zero" and "A `data-raw/` script must load the source tree, not the installed package". Not read: 126.
- **code-check-shell.md:** none read. The diff has no shell code; `gh api` runs only through `system2()`, covered above. Not read: 75.
- **code-check-spatial.md:** none read. The diff changes no spatial code; `chinook_sites_map.R` is unchanged and only rerun. Not read: 98.

## What I checked, and how it came out

These hold:
- `lh_pin_guard()`. A default `cols = names(x)` is evaluated before `x` is reassigned. Row names are reset on both sides. `ch()` compares the same six columns. The MORR check takes every column and the BULK check every column but `note`. None of its checks fails toward pass.
- `test-life_history_pin.R`. Every block calls `lh_lib()`, so each skips on its own when `data-raw/` is absent under R CMD check. The `sys.nframe()` gate keeps `gh` from running under `sys.source()`. The CO-spawning test asserts there is exactly one such row.
- The `own-windows` chunk. Each sentence has a guard over the set it names:
  - "from April": both own migration windows start 04-01, and the Bulkley's starts 05-01.
  - "about August 10 to early September, shorter": the windows open 9–10 days after 08-01 and close 9–10 days before 09-15, inside the guard's 8–12.
  - "barely moves" and "neither range clear": the `carried` rows in `change` are the shipped weighting under each group, per `chinook_sites_data.R` lines 164–198.
- The bundle values agree with the reports: Swift UFRA −15.5 % (−33.1..5.5) against BULK −15.3 %, and Naver COTR covariance_pick −34.8 % (−59.4..8.9) against BULK −35.2 %.
- Assertions that already spanned every window set still hold with UFRA and COTR rows in the bundle:
  - coverage ≥ 0.87: the lowest new value is 0.931.
  - migration carried ≥ 0.5: UFRA 0.55, COTR 0.74.
  - "migration fell clearly only at Maxan": the Naver COTR migration mean runs −27.4..9.8 %.
  - `n_pre` 10–30 and `n_post` 9–10.
  - snow `lo > 0` over every group: true in both new snow reports.
  - the `cy$ship` checks: distance at Swift under both groups, and covariance_pick at Naver under COTR.
- research/chinook_sites.md, "Swift and Naver under their own windows", checked against the reports:
  - The table's numbers match sections 3, 5 and 6: Swift UFRA gain −0.021, NSE 0.55 / 0.42, migration −6 %; Swift BULK 0.51 / 0.43, −5 %; Naver COTR gains 0.139 / 0.159, cov_pk 0.74 / 0.56, migration −11 %; Naver BULK 0.75 / 0.60, −13 %.
  - Swift's extended spawning change: −31.7 % (−49.4..−6.1) under UFRA, −27.5 % under BULK.
  - Snow gauges: 08LB038 and 08KA007 under UFRA, 08LB038 and 08KA001 under BULK.
  - Coverage under the new sets is ≥ 0.931.
  - CLAUDE.md's "under every window set; distance at Swift, under both" and its cap of 1,245 also match.

## Findings

- **[severity: fragile]** vignettes/articles/flow-change-sparse-gauges.Rmd:663 (the limits bullet "The windows are the Bulkley's at all four streams, and the figures show only those").
  - The Fraser map is a figure, and it now draws two gauges that only the Cottonwood (COTR) run uses: 08JE001 (extension donor) and 08KF001 (carried donor). The pre-branch `chinook_sites_map.rds` has neither. `data-raw/chinook_sites_map.R:53` takes every extension and carried donor from `values$gauges`, which has no `group` column, so donors from every window set get drawn. research/chinook_sites.md says this outright: "two donor gauges used only under COTR … which widen the article's Fraser map".
  - So the sentence is false for that map. Its caption, "with the gauges each borrows from", also claims more than it holds: under the Bulkley windows the article reports, Naver borrows from neither gauge.
  - No guard holds "the figures show only those". The `stopifnot` at line 159 checks only `sites$windows`.
  - Two ways to fix it: (a) qualify the sentence and caption, e.g. the map also draws the gauges the Cottonwood windows borrow from; or (b) build the map from the BULK runs' donors only. Option (b) means `gauges` needs a group column, and the map must be rebuilt.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ; code-check.md "A proxy is not the property"

Nothing else is a defect.
