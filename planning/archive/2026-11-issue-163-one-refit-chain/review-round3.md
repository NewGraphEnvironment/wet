# Code-check round 3 (wet#163, branch 163-backlog-move-1-one-refit-chain-input-key at 44cc51a)

## Checklist read

- code-check.md: all 14 H3s under `## Mechanisms`, prose only (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Not read: the 22 headings under Rules that stand alone / Security / Spreadsheets and PDFs (index lines only).
- code-check-r.md: read `$` on a list partial-matches; `identical()` on two reader results tests the reader, not the file; `climr::downscale()` returns its reference-period row; A `function(...)` mock hides arguments; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; `sort()` and `order()` collate by `LC_COLLATE`; `tolerance` in testthat is RELATIVE (7). Not read: the remaining ~150 (index lines only).
- code-check-shell.md: read A `curl` in a parallel fan-out needs `--max-time`; An S3 multipart ETag depends on the uploader's part size (2). Not read: the remaining ~95.
- code-check-spatial.md: read 0 sections (the diff's raster read path is unchanged; index lines only for the ~100 headings).

## Round 1's mechanism

A sentence, report line or comment states a property, and the guard beside it (or the number in it) tests or restates a nearby proxy: there, the vignette's "kept within the margin" bullet was held by `keep_adjust`/`gate_pass`, which an override or the nested arm also satisfy. Its siblings in this diff are every line whose wording names the gate, the override, a tolerance or an exact zero, and every new report line.

## Findings

- **[severity: bug]** scripts/wb_gate_score.R:59-60 — the report says fit_20260717 was made under "the 0.5-point override". The recorded tolerance was 0.10 point (`data/wb/92b893c4da/fit_20260717/adjust_override.txt` line 1 reads `0.1`; `data/checks/wb_validation_20260717.txt:17` and `wb_aet_compare_20260717.txt:4` say "0.10 point"); 0.5 was only the cap `wb_cv_lib.R` allowed. The "made" column is read correctly from `x$keep_adjust`, but the line explaining it states the wrong rule. For any other variant of fit_20260717 whose headwater loss fell between 0.10 and 0.5, a reader of the label would expect "keep" where the column says "drop". The report has not been written yet (`data/checks/wb_gate_main_stems.txt` does not exist), so it is cheap to fix: read the number from the file, or say 0.10.
  - **Rule:** code-check.md "One fact derived twice"

- **[severity: fragile]** scripts/wb_gate_score.R:31-46 — nothing checks that the `cv_aet-*.rds` it reads were made before #47. The header and the "made:" line say the `made_*` columns are the headwater gate (plus override). But the chain this branch sets up (task_plan Phase 3, line 71: rescore all ten variants under the new code) rewrites fit_20260717's `cv_aet-*.rds` through `wb_validate.R`, whose `keep_adjust` is now `wb_gate()`. Run after that (it reads `wb_key_dir()`, which then names the rescored run), the script labels the #47 rule's keep as "made under the headwater gate and override", and "variants whose keep or drop changes" reads 0 by construction. The two sides then come from one source and cannot disagree. The discriminating fact already exists: `wb_validate.R` now stores `gate_arm` in every cv file, and files made before #47 carry none. So `stopifnot(is.null(x$gate_arm))` (or `[["gate_arm"]]`) per file makes the label true or stops the script.
  - **Rule:** code-check.md "Verification that reads its own output"

- **[severity: fragile]** scripts/wb_run_compare.R:25-33 — `files_of()` returns nothing for a declared part missing from a run, and a part missing from **both** runs adds no file to either set, so nothing reports it. Two directories that each hold only `upstream/` (the shape of the reduced bundles, e.g. `data/wb/_pre76_m1/e675918817` on m1: `fit_20260717` and `upstream` only) compare `upstream/` alone, print `IDENTICAL` and exit 0. The header promises `sample/`, `layers.tif`, `in_bc.tif`, `lc_ratios.csv` and `ex_filled_cells.txt` too, and it says "exits ... 0 when the runs hold the same values", which CLAUDE.md now repeats and the plan leans on ("`wb_run_compare.R` must report identical", task_plan lines 54 and 72). When every part is missing from both (two `fit_*` directories, say), `sort(NULL, method = "radix")` aborts with "argument 1 is not a vector" (checked in R), not with a message naming the problem. Refusing when any declared part is absent from both runs (or from either) closes both cases.
  - **Rule:** code-check.md "A guard that fails toward pass"

## Every place the mechanism reaches, and whether it holds

| place | claim | verdict |
|---|---|---|
| vignettes/segment-discharge.Rmd:936-948 | kept "within a margin"; loses "by less than the margin the gate allows" | holds: the guard requires arm `margin`, or no `gate_arm` (a pre-#47 bundle, where keep∧¬pass means an override whose tolerance was capped at 0.5 < 1.0). Only at a loss of exactly 1.00 does "less than" disagree with `<=`; immaterial |
| data-raw/segment_vignette_data.R:230-236 | gate_arm absent before #47 | holds: `list(gate_arm = NULL)` keeps a NULL element; no sibling key shares the `gate_arm` prefix, so `$` cannot partial-match |
| wb_validate.R:292-297 GATE line | arm named from `gate$arm` | holds; it prints nested MAE for the margin arm too, which is informative, not false |
| wb_validate.R:298-300 rule line | the three arms and `gate_margin_pts` | holds against `wb_gate()`'s branches |
| wb_validate.R:203-207 fixed-variant stop | "fails the gate" | holds: fires only on the `dropped` arm |
| wb_validate.R:302 | "Under the pre-set specification ... the gate FAILS" | unconditional and headwater-only, but older than this branch and printed only without a fixed variant (not the shipped fit); not raised |
| wb_validate.R:48 (#102's registered rule) | "a gauge at distance 0 taking the whole weight" | narrower than the code since #158, but it is registered text; not raised |
| wb_aet_compare.R:243-246 header line | "#47's rule (headwater, within %.1f point, or nested)" | holds; three placeholders, three arguments |
| wb_aet_compare.R:269-273 adjusted* footnote | headwater failed, kept within margin or nested | holds: shown only when `gate & !gate_pass`, which is the margin or nested arm. The sentence about "the fixed pooled variant" would print without one, but that was already so before this branch |
| wb_aet_compare.R:265 heading | "adjusted if it passes the headwater gate, raw otherwise" | literally false since #43 (override) and still false for the margin and nested arms; the adjusted* footnote under the table corrects it. Not raised |
| wb_aet_compare.R:110-118 as_shipped_cv | the gate on nested MAE | holds: `metrics()` returns `nes_mae` (mean abs error over obs >= 10, nesting != "headwater"). `wet_cv_folds()` has only "headwater"/"nested", so it is the same population as wb_validate.R's `nes()` |
| wb_fit_accept.R:107-111, 127-136 | kept "by override" or "by the <arm> arm" | holds. The "override" fallback is unreachable for any fit that passes the score-md5 check (wb_gate_rule.R is now hashed, so a current fit was written with `gate_arm`). "its gate FAILS" means the headwater gate, as the header says |
| wb_fit_lib.R:16-20 | cfu kept by the gate's own margin | holds on the stored numbers (30.72 vs 30.69, the margin arm, pinned in test-wb_gate_rule.R), pending the rescore |
| wb_cv_lib.R:96-103 refusal | "the 1.0-point margin covers the tie it kept" | holds (tolerance 0.1, tie 0.03) |
| wb_score_md5.R:26-35 | the override no longer among the decision files | holds. Scripts that source it without wb_cv_lib.R (wb_output, segment_*) do not refuse the file, but every pre-#47 fit is stale through wb_gate_rule.R anyway |
| wb_gate_rule.R:15 | "a 0.03-point tie within a 0.5-point cap" | holds literally (the cap), though the recorded tolerance was 0.10 |
| wb_gate_score.R:59-60 | "the 0.5-point override" | **does not hold** (finding 1) |
| wb_gate_score.R header / made columns | made under the headwater gate (and override) | holds only before the rescore (finding 2) |
| wb_inputs.R:219-246 | "averaged over the 30 observed years"; pre-#51 line "same read" | holds: the `stopifnot` gives each id 0 or 30 rows, and `cl_ref` comes from the same `cl` |
| wb_term_diagnose.R:202-209, 332-333 | pre-#51 median, "same read" | holds: the ECCC cache is keyed on the script's own md5 (`eccc_key`), so no pre-#51 rds without `ref_map` is read |
| R/wet_donor_mean.R:1-8 | within 1e-9 × median(d), shared equally | holds: the median is over all donors' distances, and `as.numeric(zero)` gives equal weights |
| segment_group.R:24-26, 382-389 | "within 1e-9 of the median distance" | wording reads as abs(d − median) <= 1e-9 where the code means 1e-9 × median; comment only. The report line (405, "within 1e-9 (scaled)") matches its absolute `dmin < 1e-9`, and the comment says so. Holds |
| R/wet_shape_fit.R:12, R/wet_share_fit.R:15 (roxygen) | "at distance 0 takes the whole weight" | true but narrower than the code since #158; not raised |
| departure_pcic.R:112-116 (registered) | "at distance 0" | registered text; moves only for gauges co-located within 1e-9 × median distance; not raised |
| R/wet_cgiar_aet.R roxygen | "a revised archive gives a new crop" | holds for a revised local archive; a figshare revision is noticed only on a rebuild (accepted design) |
| R/wet_dem_glo90.R roxygen | ETags read on every call | holds (HEADs with a 120 s per-handle timeout; any tile without a 200 and an ETag stops the call) |
| wb_run_compare.R header | "exits 1 on any, 0 when the runs hold the same values" | **does not hold** for parts absent from both runs (finding 3) |

Also checked: the test mocks' signatures against the real callees' formals (`wet_download`, `wet_unrar`, `wet_figshare_files`, `wet_cgiar_stack`, `wet_gdal_config_set`, `wet_glo90_tiles`, `wet_glo90_etags`); test-wb_gate_rule.R skips under R CMD check (`../../scripts` absent); the GLO-90 key sorts with `method = "radix"`; `<<-` in the curl callbacks reaches the function frame.

/Users/airvine/Projects/repo/wet/planning/active/review-round3.md
