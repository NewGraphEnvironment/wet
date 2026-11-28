## Checklist read

code-check.md "A guard's scope, escape hatches, and remedies", "One fact derived twice", "Documentation Staleness"; index, diff and changed files read from file.

## Findings

- **[severity: fragile]** planning/archive/2026-11-issue-243-runoff-products/README.md:15 — the Evidence line calls `cfdc304b4cfc81a978ed00162010d0b9` (runs 15 and 16) the tracked report's **final** md5, and says the md5 for each code commit is in `progress.md`. Both are now wrong. The rebuild at 8f81c85b moved the tracked report to md5 `9c78e624c708d546ce77685564505093`, from code commit 01e52b2b; `git show 41ded8de:data/checks/runoff_products_compare_20260717.txt | md5` gives cfdc304b…, and the working copy at HEAD gives 9c78e624…. `progress.md`'s last entry (line 59) still ends at code commit a3918b6e, runs 15 and 16. The rebuild's runs exist as `runoff_products_compare_run17.log` (written 18:47:23, the second the report commit is stamped with) and `run18.log` (18:48:27) under the main checkout's `data/logs/243/`. The tree is clean after run 18, so the two runs gave the same bytes, but no planning file records them. Fix: add one progress.md line ("Merged origin/main at 01e52b2b, which moved the code commit; report from code commit 01e52b2b: runs 17 and 18 both md5 `9c78e624c708d546ce77685564505093`, changed only in the code-commit line") and change the README's "final" to that md5, runs 17 and 18.
  - **Rule:** code-check.md "Documentation Staleness"

## Checked and clean

1. **The report's last commit.** 8f81c85b changes one line of `data/checks/runoff_products_compare_20260717.txt`, line 4, from `Code commit a3918b6e` to `Code commit 01e52b2b`. Nothing else changed: no cache key, value or other line. `git log -1 --format=%H -- R scripts data-raw inst/vignette-data DESCRIPTION` at HEAD gives `01e52b2bdf5dd00a5d298653cb9aaa46ffbee006`, and its first 8 characters are 01e52b2b. That matches the script's `substr(..., 1, 8)` at scripts/runoff_products_compare.R:72. The merge commit is listed for that path set because it differs from both parents (it adds main's script to one side and this branch's scripts to the other). Nothing in tests/, R/, scripts/ or data-raw/ reads the report's code-commit line back, so the merge commit main will make on the PR does not stale anything that refuses.
2. **The merge.** `git show --cc 01e52b2b` shows no hunk that needed resolving.
   - CLAUDE.md against main gains only this branch's `runoff_products_compare.R` bullet. Against this branch it gains only main's paragraph on the Bayesian alignment check (#218). Both are whole.
   - research/README.md against main gains only the `runoff_products.md` row. Against this branch it gains only main's `temperature_bayesian_alignment.md` and `temperature_network_model.md` rows.
   - No `<<<<<<<`, `>>>>>>>` or bare `=======` line appears in any file the merge changed against either parent.
   - Main's added files touch nothing this branch reads or claims. The check script's `scope` (line 123) and its `choices` hold `R/wet_temp_fill.R`, `R/wet_temp_gsdd.R`, `R/wet_donor_mean.R`, `R/wet_cv_folds.R` and the temperature baseline scripts, none of which this branch touches (the branch changes nothing under R/). The words runoff, TerraClimate, isoline, #243 and #225 appear nowhere in main's script, its two research files or its report. The words temperature, Bayes, #217, #218 and #238 appear nowhere in this branch's script, rule, test or `research/runoff_products.md`.
3. **The archive README's Measurement section against the tracked report.**
   - TerraClimate, all matching:
     - error −33.0 [−45.5, −13.3], 23 % within; balance −3.6; routed −2.6 at n 283 (section 4)
     - theirs province-wide and in 14 zones (01, 03, 05, 07, 08, 13, 14, 20, 21, 22, 25, 26, 27, 29); unstable (theirs) in 10 and 19; unresolved in 04; ours in 24 with the balance at +36.4 (section 8)
     - terms P −202, AET +85, storage +3, zone adjustment −50 (section 9)
     - share NSE 0.55 against 0.94 (section 5)
     - plumbing 0.70 % at 314 gauges, bound 5 % (section 3)
   - Isolines, all matching:
     - TIN +1.8 [−14.0, +17.8], 61 % within, at n 292; balance −4.5
     - not material in 17 zones (01, 03, 08, 10, 13, 14, 15, 16, 18, 19, 20, 21, 22, 25, 26, 27, 28); ours in 24; unstable (ours) in 09; theirs (period untested) in 29
     - IDW against TIN a median +0.0; flat share median 0.20, 95 gauges above 0.5 (section 6)
   - Period: 121 gauges, province ratio 0.985, zone ratios from 0.951 to 1.033, which rounds to the README's 0.95–1.03 (section 7).
   - The terra figures (70–100 ms per polygon, 15–50 min per group, within 1.1e-7) match findings.md:41.
   - The run times (about 15–19 min cold, a minute from cache) match progress.md's runs 1–6 and 13, and runs 17 and 18 took 64 s and 53 s.
   - research/runoff_products.md's "Two runs gave byte-identical reports" still holds for runs 17 and 18. It names no md5 or code commit, so it is not stale.
