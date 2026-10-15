# Code-check round 4 (#83): ceb28bb, each fit scored on what it ships

Scope: ceb28bb's change to `scripts/wb_fit_accept.R`, and its docs (script header,
`research/water_balance_method.md` "Accepting the next refit (#83)", the `CLAUDE.md` bullet).
Probes ran in a fresh sandbox copy (`scratchpad/sb5`, the repo's `scripts/wb_fit_accept.R`
copied in), with the 18-case driver copied unedited to `scratchpad/sb5_cases.R`.

## Findings

- **[fragile, docs] #83 issue body, "Outcome (2026-10-15)" (also `planning/active/task_plan.md:21-22`)**:
  the spec still describes the rule as it was before rounds 1 to 3. It says the script "compares
  the headline blocked CV each fit stores", and the plan says "mean |err_pct| of `cv_v`" and "the
  headline CV of its shipped AET". Since ceb28bb, a fit whose gate dropped the adjustment is scored
  on `raw_v`, not on its headline CV. The body also says "The old side must be `wb_shipped_release`,
  so #43's report is never rewritten". Round 1 showed that guard alone did not protect the report;
  what protects it is the later-release requirement (`wb_fit_accept.R:39`), which the body does not
  mention. It also does not mention the pooled-test requirement or its tie to the tracked report.
  The in-repo docs (script header, research section, `CLAUDE.md`) are now true of the code, so this
  is only the issue body and the plan. The body is the record of a pre-registered rule, though, and
  a reader taking it as the rule would score a raw-shipping fit on the wrong estimate. Edit the body
  before merge (`/gh-pr-merge` step 3b would catch it).

No defect in the code change itself. What was checked:

## Verified

1. **`raw_v` and `cv_v` station frames are comparable.** `wb_validate.R` builds both from the same
   `cal` through the same `long()` (`wb_cv_lib.R:200`): `raw_v` from
   `long(cal, pmax(cal$raw, 0), NA shares)` with `groups`, and `cv_v` from
   `long(cal, cv$ann, cv$share)` with `groups_cv`. `groups` only shapes `summary`, not `stations`.
   `wet_flow_validate()` (`R/wet_flow_validate.R`) gives the same rows (`sort(unique(station_number))`),
   the same `obs`, and the same `err_pct = 100 * (mod - obs) / obs`, NA where `obs < 10` or `mod` is NA.
   The NA shares in `raw_v` touch only `nse_*`, not `err_pct`. `wb_fit_accept.R:91` aligns the frame
   to `x$station_number` by `match()`, so row order does not matter. A gauge NA in either fit's
   shipped estimate leaves `common` for both fits, so the comparison stays paired.
2. **`raw_v` exists in every `cv_aet` file current under this code.** `wb_validate.R:139` has saved
   it since the first scoring commit (fdaeb82), and `wb_validate.R` is in `score_files_for()`
   (`wb_score_md5.R:14`). A file that passes the `x$code_md5` check at `wb_fit_accept.R:58` was
   therefore written by code that saves `raw_v`. In the sandbox the reduced bundle's
   `cv_aet-cfu.rds` gives raw headwater MAE 30.69, matching #43's documented raw value of 30.688.
3. **`raw_v` is what ships when the adjustment is dropped.** `wb_output.R:62` ships
   `pmax(up$raw, 0)` with `up$raw <- wet_wb_raw(up, aet)`, and `raw_v` uses `pmax(cal$raw, 0)` with
   `cal$raw <- wet_wb_raw(cal, aet_v)`, the same function on the same upstream means. Raw has no
   fitting, so the held-out and shipped values are the same.
4. **`keep_adjust` is the one switch (grep).** Every read in `scripts/`, `R/`, `data-raw/` and
   `vignettes/`: `wb_output.R:62, 122, 138` choose adjusted or raw on it. `pcic_routed_lib.R:69` and
   `wb_aet_compare.R:77, 88` score on it the same way `wb_fit_accept.R:89` now does.
   `pcic_routed_compare.R:105` and `data-raw/segment_vignette_data.R:66, 199` label on it.
   `monthly_vignette_data.R:61` and `segment-discharge.Rmd:336` require it TRUE. `wb_validate.R`
   and `wb_cv_lib.R:139` produce it. Nothing else selects the shipped annual estimate.
   `fits$keep_adjust` and `x$keep_adjust` come from the same `wb_validate.R` run, because both
   files carry the same `score_code_md5` and AET and `fits.rds` is written only in a run that also
   writes `cv_aet-<ship AET>.rds`.
5. **Gate and `keep_adjust` combinations.**

   | old | new | scored | routing |
   |---|---|---|---|
   | any | gate PASS, keep TRUE | new adjusted | none |
   | any | gate FAIL, keep TRUE (override) | new adjusted | to the user if SHIPS |
   | any | gate FAIL, keep FALSE | new raw | to the user if SHIPS |
   | keep FALSE | any | old raw | old's gate does not route (rule: new side only) |

   Amendment 9 ("a new fit that passes with its headwater gate failing goes to the user") holds in
   every row: `gate_ok` reads `gate_pass`, not `keep_adjust`. `gate_pass` NULL with `keep_adjust`
   TRUE would hide a failed gate, but current `fits.rds` always carries `gate_pass`
   (`wb_validate.R:127`). Fixed variant with keep FALSE cannot produce a current `fits.rds`, because
   `wb_validate.R:116` stops first. So a raw-shipping fit is only reachable after an uninformative
   pooled test (nested), and that path is exercised.
6. **Sandbox, 18 cases (`scratchpad/sb5_out.txt`).** 5 exit 0 and 13 refuse, as in round 3.
   "Shipped fit ships raw" reports "scored as each ships: 20260717 raw P - AET" and +0.03.
   "New fit ships raw" reports 20990101 raw, −0.03, gate FAIL, and "SHIPS ...; its gate FAILS, so
   the decision goes to the user", on both the report's VERDICT line and the console line.
   The switch moves the MAE (30.72 to 30.69), so line 89 is not inert.
7. **Docs.** The script header (lines 6-18), the research bullets and the `CLAUDE.md` bullet each
   describe `cv_v`, or `raw_v` when the gate dropped the adjustment, and the user route for a new
   fit only. The removed sentences ("Both MAEs are of the adjusted balance ...") are gone from all
   three. `pcic_routed_lib.R` does make the same choice, as the research text says.
