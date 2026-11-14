# Code-check round 4 (wet#163, branch 163-backlog-move-1-one-refit-chain-input-key at 9c0f762)

## Checklist read

- code-check.md: I read the prose of all 14 H3s under `## Mechanisms`, skipping the table rows. I did not read 24 headings: 14 under Rules that stand alone, 6 under Security and 4 under Spreadsheets and PDFs.
- code-check-r.md: I read 8 of 121 headings: "`$` on a list partial-matches…", "`[[` on a named ATOMIC vector…", "`c(name = x)` keeps `x`'s own name…", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "`climr::downscale()` returns its reference-period row…", "`identical()` on two reader results tests the reader, not the file", "`on.exit()` at a script's top level never fires" and "A `function(...)` mock hides arguments…". I did not read the other 113.
- code-check-shell.md: I read 1 of 71 headings: "An S3 multipart ETag depends on the uploader's part size…". I did not read the other 70.
- code-check-spatial.md: I read none of its 94 headings. The diff's spatial code is unchanged terra and GDAL plumbing, except an ETag key read over HTTP.

## Round 3's fixes, reviewed first

- **wb_gate_score.R refuses a cv file that records `gate_arm`.** This holds. Commit 69e5fc6 added both the rule (`wb_gate()` in wb_validate.R) and the `gate_arm` field in both saveRDS calls, so no commit ever wrote a cv file scored under the rule without `gate_arm`. The read uses `[[`, so no sibling key can partial-match it.
- **The label now reads 0.10.** This holds. Line 1 of `data/wb/92b893c4da/fit_20260717/adjust_override.txt` is `0.1`.
- **wb_run_compare.R stops when a declared part is absent from both runs.** This does not fully hold: see finding 1. The check tests that the path exists, which only stands in for the run holding the part.

## Findings

- **[severity: bug]** scripts/wb_run_compare.R:676-677. The round-3 guard tests `file.exists(file.path(run, part))`. But scripts/wb_province.R:63-64 creates `sample/` and `upstream/` before it writes anything. So two runs that never accumulated pass the guard: both stopped by `WET_WB_GROUPS` ("stopping before accumulation"), or both killed during sampling. Each holds an empty `upstream/` with no `_complete`, the compare covers only `sample/` and the four top-level files, and it prints `IDENTICAL` and exits 0. I reproduced this on synthetic directories in the scratchpad: two runs, each with one sample rds, an empty `upstream/` and the four files. The output was `files compared: 5 of 5 and 5`, `upstream watersheds in the first run: 0`, `IDENTICAL`, exit 0. This is the same defect round 3 fixed, one level down: a directory that exists is not a part that is held. Every later script refuses a run without `upstream/_complete`; requiring it in both runs (or requiring each directory part to hold a file) would close the gap.
  - **Rule:** code-check.md "A proxy is not the property"
- **[severity: fragile]** scripts/wb_aet_compare.R:269-272. Whenever any variant is `adjusted*`, the footnote states that "the fixed pooled variant, applied to every variant and fold, leans toward the AET it was fixed under". It does not check `fixed_variant`. When `fixed_variant` is NA, the same report's header says the pooled zones are "chosen inside each fold", so the report contradicts itself. Before this branch, `adjusted*` arose only through an override, which came with a refit's decision files. Under #47 it arises from the margin or nested arm on any fit, including one with no decision files, for example a new release compared before its pooled test runs, which is the documented order. So the false sentence is now reachable in the tracked report `wb_aet_compare_<release>.txt`. The wording was rewritten in this diff, which carried the unconditional clause forward.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

## The mechanism

All of round 3's findings, and both findings above, share one shape. A report line or verdict is true only under an assumption about its inputs, and nothing checks that assumption:

- the label assumed the override's value;
- the gate score assumed its cv files were made before the rule;
- the run compare assumed both directories were complete province runs;
- the footnote assumes a fixed pooled variant exists.

A check that stands in for the assumption, such as a path existing, is the same defect in a guard's clothing. The remedy is to state each such assumption next to the line that depends on it, and to test it against the input itself: the file's value, the marker only a finished run writes, the variable the sentence names.

### Every place in this diff the mechanism reaches

| place | assumption | checked? | verdict |
|---|---|---|---|
| wb_run_compare.R IDENTICAL | both are complete province runs | path exists only | **does not hold** (finding 1) |
| wb_run_compare.R scope ("what wb_province.R writes, and nothing else") | `parts` is everything wb_province.R writes | read wb_province.R: sample/, upstream/ (+`_complete`), in_bc.tif, layers.tif, lc_ratios.csv, ex_filled_cells.txt, and sample_times.txt (excluded) | holds |
| wb_run_compare.R text compare | non-rds, non-tif files are text | sample/ and upstream/ hold only rds and `_complete` | holds |
| wb_aet_compare.R `adjusted*` footnote | a fixed pooled variant exists | no | **does not hold** when `fixed_variant` is NA (finding 2) |
| wb_aet_compare.R in-fold gate | `metrics()[["nes_mae"]]` is the same number as wb_validate.R's `nes()` (summary, nested) | only headwater is cross-checked (lines 91-97) | holds by definition today: both use min_obs 10 and the mean of abs(err_pct), and nesting is binary (wet_cv_folds.R:52). Nothing asserts the nested number. |
| wb_gate_score.R "made" column | scores were made before the rule | yes, `gate_arm` refused | holds |
| wb_gate_score.R "made" column | each fit's cv files were scored under one code, for fit_20260717 the one carrying the 0.10 override | no; the md5s are printed, not compared | holds only if nobody rescored a subset. A mix would show as two md5s on one line of the report but would not stop the script. |
| wb_gate_score.R fit_20251014 path | `_pre76/e675918817` is #15's record copy | `x$release` checked, path hard-coded | holds as documented |
| wb_gate_score.R 0.10 label | the override's tolerance | read from the file by me, not by the script | holds (`0.1`) |
| wb_fit_accept.R `gate_arm` NULL is read as "override" | a fit before #47 keeping the adjustment with its gate failing did so by override | implicitly: such a fit cannot pass the `code_md5` currency check now that wb_gate_rule.R is hashed | holds (that branch is unreachable) |
| vignette guard `is.null(gate_arm) \|\| gate_arm == "margin"` against "loses by less than the margin" | a NULL arm (an override-era bundle) lost by no more than 1.0 | the override was capped at 0.5 by wb_cv_lib.R at the time, and segment_vignette_data.R refuses a fit under other scoring code, so new bundles always carry `gate_arm` | holds |
| wb_score_md5.R dropping adjust_override.txt | nothing reads the file any more | wb_cv_lib.R refuses its presence; scripts that source wb_score_md5.R alone refuse a stale `code_md5` | holds |
| wet_cgiar_aet() cache hit | a crop named for these archives' md5s was built from them | by construction: the name is computed after the md5 check | holds |
| wet_cgiar_aet() extraction marker | the extracted grids are from the current archives | marker names each md5 | holds |
| wet_dem_glo90() key | ETags identify tile content | stops on any tile without a 200 and an ETag | holds (over-keys on a re-upload, which is safe) |
| segment_group.R attribution count | the count matches wet_donor_mean()'s zero test | no, and disclosed: absolute 1e-9 against relative 1e-9 · median | holds as disclosed (the count is a subset of the whole-weight rows) |
| climr filters (wb_inputs.R, wb_term_diagnose.R) | 30 observed rows per point | `stopifnot(table %in% c(0, 30))` | holds; the ECCC cache in wb_term_diagnose.R is keyed on the script's md5, so no row cached before #51 is read back |
| wb_inputs.R / wb_term_diagnose.R "before #51" line | exactly one reference row per point | no | holds for climr 0.2.2 (one `1961_1990` row) |
