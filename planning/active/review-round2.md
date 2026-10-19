# Code-check round 2 (#102): branch b8fe71c...5e08841, planning/ excluded

## Checklist read

- code-check.md (37 H3): read all 14 Mechanisms H3s in prose (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree; A wrapper's exit is not the work; Zero-length, empty, and unset; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). 23 not read (stand-alone, security, spreadsheet rules; none applies to this diff).
- code-check-r.md (111 H3): read `$` on a list partial-matches; `[[` on a named ATOMIC vector; `c(name = x)` keeps x's own name; `ifelse()` with an all-NA test; `match()` treats NA as a value; A `pkg::` call in a test; `expect_false(identical(x, y))`; Inside a dplyr verb, a column named like a local variable wins; `paste()` with a zero-length argument; Rscript reads a script as it runs. 101 not read.
- code-check-shell.md (67 H3): none read; the diff has no shell.
- code-check-spatial.md (92 H3): read A Freshwater Atlas main stem's downstream end (share_related() uses FWA codes). 91 not read.

## Method

Read the full current text of every file in the diff, plus every consumer of `fits.rds`, `cv_aet-*.rds`, `wet_share_fit()`/`wet_share_predict()` and `predict_cv()` (wb_output.R, wb_shape_daily.R, wb_share_snow.R, wb_aet_compare.R, wb_fit_accept.R, wb_pooled_test.R, pcic_routed_lib.R, segment_output.R, discharge_publish.R, data-raw/monthly_vignette_data.R, vignettes/monthly-flow.Rmd). Ran test-wet_share_fit.R and test-wet_shape.R (NOT_CRAN=true) and the new roxygen example from a copy under the scratchpad: 0 failed, 0 errors; the example prints the low watershed below the high one in May-July, as its comment says.

Checked and found sound:
- wet_donor_mean() reproduces the old shape donor exactly (test passes; NA rows could not reach it before because wet_shape_static() refuses NA).
- `identical(sm_cv$regression, cv$shares[[ship_share]])`: same training rows, same held-out rows, neither matrix carries dimnames, so it holds by construction and guards the right thing.
- ship_method is independent of the AET variant (shares use only shares, monthly ppt/tave/aet and static columns, never `cal$raw`), so the round-1 sentence in wb_aet_compare.R ("The monthly shares are the same for every variant ... differences here are annual only") is true. Round-1 fix is correct.
- The gate (`hw()`, mae_pct) reads annual errors only, so cv$share switching to the donor moves no gate or AET decision.
- `$` partial matching: every new key read with `$` (share_method vs share_method_rule, cv_share vs cv_shares/cv_share_methods*, r$n vs nse, fit$sd/shares/static) either has an exact match or, for pre-#102 files, an ambiguous or absent prefix, so it returns NULL as the guards expect.
- Old fits.rds/cv files are refused before any `fits$share_method` use (code_md5 includes R/wet_donor_mean.R and the edited hashed files), so the sprintf in wb_output.R and the switch in discharge_publish.R never see NULL.
- The registered rule text from a8ca570 is unchanged; the code matches it (>= gain in both pools, higher blocked-CV median, donor on a tie).

## Findings

- **[fragile]** vignettes/monthly-flow.Rmd:524-525. The guard `stopifnot(identical(prov$share_spec, "snow"))` stands in for "the shares are the snow regression", which lines 549-556 describe ("a share of the year modelled from monthly precipitation, temperature and evapotranspiration, elevation, location, and two snow terms ... (`wet_share_fit()`, #16). The snow terms reduced the bias..."). Under donor, share_spec stays "snow", so the guard still passes and those sentences become false. The branch adds `share_method` to the bundle's provenance (data-raw/monthly_vignette_data.R:278), but the Rmd never reads it. The accepted plan is to rewrite the bundle and the Rmd together after the republish. Nothing enforces that, though: a regeneration of the bundle on the donor fit alone (monthly_vignette_data.R now accepts a donor fit) would build green and publish the regression prose. One line closes it, and the Rmd is not in the scoring hash, so it stales nothing: `stopifnot(is.null(prov$share_method) || identical(prov$share_method, "regression"))` beside the existing guard. (The numeric stopifnots at 526-531 might also catch a donor bundle, but only by accident.)

- **[fragile]** scripts/wb_share_donor.R:163-165. The tracked report wb_share_donor_<release>.txt states as fact "(their observed shares rest on 1-9 years, so every method scores lower there)". No code computes or checks it. "every method scores lower" is a quantified claim about the test-gauge medians against the calibration medians, and the script has both numbers to hand (`tst_nse` vs `r$median`). If one method does not score lower, the report prints a false sentence beside the numbers that contradict it. Either assert it (`stopifnot(all(vapply(tst_nse, function(x) med(x[tst_ok]), 1) < r$median[share_methods]))`) or drop the clause. wb_share_donor.R is not in score_files_for(), so the fix stales nothing.

- **[minor, conditional on a blend outcome; not blocking]** scripts/wb_validate.R:253-255. The report's first line has no blend arm, so a blend ships with the label "(monthly shares use CGIAR monthly AET)", which leaves out the donor half. Under the forecast outcome (donor) the text is correct. wb_validate.R is hashed, so fix it only alongside another hashed edit, before the m4 run. The same applies to the comment at wb_validate.R:220-223 ("cv_share is the shipped specification's"). It is not false, but under donor, cv_share is no longer `cv_shares[[share_spec]]`. That is the assumption data-raw/monthly_vignette_data.R needed updating for, and a future consumer reading this comment would make it again.

No bugs found in the R code, wb_cv_lib.R, wb_validate.R's rule, wb_output.R, wb_shape_daily.R or discharge_publish.R.
