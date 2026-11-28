# Code-check round 4 (#243)

## Checklist read

- **code-check.md**: all 14 H3s under `## Mechanisms`, prose only, `|` rows skipped (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice), plus Documentation Staleness. 15 read, 23 not read.
- **code-check-r.md**: `system2(stdout = TRUE)` warns on a non-zero exit (the `git()` helper the fixed `code_commit` line calls). 1 read, 131 not read.
- **code-check-shell.md**: Git plumbing calls whose default answers a different question (`git log --format=%H`). 1 read, 74 not read.
- **code-check-spatial.md**: none; the fix diff touches no spatial code. 0 read, 98 not read.

Index, diff and changed files read from file.

## Scope check

`git diff 8c2d28ae HEAD` (round 3's HEAD to now), planning/ and data/checks/ excluded, is line for line the fix diff given (ck4/round3_fix.diff). The report's only change since round 3 is line 4, the code commit (`61972008` to `a61e7ddc`), and `a61e7ddc` is `git log -1 --format=%H -- R scripts data-raw inst/vignette-data DESCRIPTION` truncated to 8. So every round-3 "holds" row read from the report still holds.

## Findings

- **[fragile]** scripts/runoff_products_compare.R:21-23 — the new remedy, "After changing stage 1 or 2 here, remove the caches or bump `sample_version`", offers a remedy that does not work for stage 1. Stage 1's outputs are `tc_q_bc_<tc_key>.tif` and `isolines_<iso_key>.tif` (lines 159-161, 217-218, 228). `tc_key` and `iso_key` do not hold `sample_version`, so after an edit to stage 1's construction (the crop and write, the −9999 reclassify, the flat layer), bumping `sample_version` gives stage 2 a new directory that re-samples the old `.tif`. The rerun is then byte-identical to the stale result, which is round 3's finding 4 again, reached through the remedy. Stage 3's own code in this script (`upstream()`, lines 342-360) is also in no key, and the remedy names only stages 1 and 2. Bumping `sample_version` does cover stage 3, because stage 2's key is part of stage 3's. Say instead: after changing stage 1, remove its `.tif` files; after changing stage 2 or 3, bump `sample_version`.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ("A **remedy** in the error message is code the caller will run, and nothing checks it"); code-check.md "Written data outlives the fix" (a cache keyed by fewer inputs than the write depends on)
- **[fragile]** research/runoff_products.md:32 — the fix added "(0.025 s against 3.6 s for 50 SALR polygons)", and 3.6 s has no recorded producer:
  - planning/active/findings.md:41, the record round 3 checked this paragraph against, gives 0.025 s for 50 polygons "local" and 16 s for 200 polygons ellipsoidal. That is about 4 s per 50, at 75–90 ms per polygon.
  - No run log under data/logs/243/ holds 3.6. `scratchpad/prof5.R` prints its timings to the console and saves nothing.
  - 3.6 s over 50 polygons is 72 ms each, below the same paragraph's "about 75–90 ms per FWA polygon".

  "More than 100 times faster" holds on either number (144× or about 160×). The fix is either to write the 3.6 s measurement into findings.md:41 beside the 0.025 s, or to quote findings' own figures.
  - **Rule:** code-check.md "One fact derived twice" (take each number from its producer)

## Enumeration

Sources: R = data/checks/runoff_products_compare_20260717.txt at HEAD; C = scripts/runoff_products_compare.R at HEAD; F = planning/active/findings.md; PC = scripts/pcic_coverage.R; PCR = data/checks/pcic_coverage_20260717.txt.

### The six fixes

| place | claim | source | verdict |
|---|---|---|---|
| research/pcic_scenarios.md:38 | the coverage report's two lines (TerraClimate runoff, the isolines) say no report scores them, and predate this report | PCR:34-35 (GEOGLOWS on :33 is still true) | holds |
| research/pcic_scenarios.md:38 | `pcic_coverage.R` still prints them | PC:258-259 | holds |
| research/pcic_scenarios.md:38 | left unchanged so its tracked report stays current | PCR equals PC's literals; editing PC would leave PCR behind HEAD's code | holds |
| research/pcic_scenarios.md (rest of repo) | a seventh copy of "no report scores TerraClimate or the isolines" | grep over research/, CLAUDE.md, scripts/, R/, tests/, data/checks/: only PC and PCR (planning/backlog.md:133 excluded) | none outside the two named |
| research/runoff_products.md:42 | 03: the zone adjustment adds 142 mm to the balance, the larger term | R §9 03: zone adj −142 (term −(cv_ann − raw), so the median of cv_ann − raw is +142), P −138 | holds |
| research/runoff_products.md:53 | 22: the zone adjustment adds 203 mm, the larger term | R §9 22: −203 against P −171 | holds |
| research/runoff_products.md:17 | P largest in every theirs zone but 03 and 22, where the adjustment is as large or larger | R §9: 14 (−151 against −142) and every other row, P largest | holds, consistent with :42/:53 |
| research/runoff_products.md:7 | over the 315 gauges, the median P difference from climr's is −202 mm | R §9 BC P −202; C:436 `t_p = ppt_tc − p_yr`; C:618 BC row is `g[g$tc_ok, ]`, 315 (R §2); `p_yr` from `cal` (C:139) | holds |
| research/runoff_products.md:7 | median AET difference from ours −85 mm | R §9 BC AET +85 is `−(aet_tc − aet_cfu)` (C:437); negation commutes with the median, so the median of aet_tc − aet_cfu is −85 | holds |
| research/runoff_products.md:40 | BC: precipitation term's median −202 mm | R §9 BC | holds |
| research (all) | a seventh "median gauge" copy | grep `median gauge` over research/, CLAUDE.md, scripts/: only monthly_error.md and gauge_monthly_compare.R, about another statistic | none |
| C:18-19 | stages 1-3 cached under runoff_products/ | C:160, 219, 267, 343 | holds |
| C:19 | stage 1 keyed on its inputs' md5s and its parameters, not on the script's code | C:159 (md5, extent), C:217 (lines md5, gridding parameters, flat_tol and GDAL's version) | holds (GDAL's version is also in `iso_key`, which only over-keys) |
| C:20-21 | stage 2 on stage 1's key, wet_ws_sample.R, wet_ws_fetch.R and sample_version | C:264-266; wet_ws_geom and wet_upstream_irregular are in R/wet_ws_fetch.R | holds |
| C:21 | stage 3 on stage 2's key and the upstream code | C:342-343: wet_upstream_means.R, wet_upstream_sums.R, wet_ws_fetch.R | holds |
| C:21-22 | remedy: remove the caches or bump sample_version after changing stage 1 or 2 | C:159-161, 217-228 | **fails for stage 1** (finding 1) |
| C:22-23 | fwapg and installed packages are in no key; stages 4 and 5 recomputed every run | C has no `file.exists`/`saveRDS` after line 360 except the hz_zip input check | holds |
| CLAUDE.md:44 | fetched files in runoff_products/raw/; fetch log and run logs under logs/243/ | C:72-73, 153, 182-185, 98; main checkout data/logs/243 (run1–10 logs, fetch tsv) | holds |
| CLAUDE.md:44 | report byte-identical on a rerun | C:69 now fixed at 8 characters | holds |
| C:69 / R line 4 | code commit, fixed length as rule_commit | C:69 `substr(%H, 1, 8)`; C:481 `substr(rule_commit, 1, 8)`; R line 4 `a61e7ddc` is the last commit to code_paths | holds |
| research/runoff_products.md:32 | more than 100 times faster | F:41 0.025 s per 50 against 75–90 ms per polygon (144–180×) | holds |
| research/runoff_products.md:32 | 3.6 s for 50 SALR polygons | F:41 (16 s per 200), data/logs/243 | **no producer; under the paragraph's own 75 ms floor** (finding 2) |

### Round 3 rows the fix touched, and the "holds" rows

| place | claim | source | verdict |
|---|---|---|---|
| research/runoff_products.md:3 | two runs gave byte-identical reports | R changed only line 4, which the code commit moves by design | holds as before |
| research/runoff_products.md:7 (rest), :9, :11, :15-28, :36-61 | every value round 3 checked | R at HEAD differs from round 3's copy only in line 4 | still holds |
| CLAUDE.md:44 (rest) | every clause round 3 marked holds | CLAUDE.md diff touches only the parenthetical | still holds |
| C comment and caption rows | round 3 C rows | C diff touches only lines 18-23 and 69; captions (C:478 on) unchanged | still hold (line numbers after 20 are +3) |
| RU rows, test rows | frozen rule, test file | unchanged since round 3 | still hold |
| research/README.md:23, runoff_prior_art.md:57-58, water_balance_method.md:730 | summaries | unchanged; R unchanged in values | still hold |
