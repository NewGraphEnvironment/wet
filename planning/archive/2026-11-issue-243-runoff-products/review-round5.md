# Code-check round 5 (#243)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (`|` rows skipped), with "A guard's scope, escape hatches, and remedies" ("run the remedy yourself, for every input the clause can receive"), "Written data outlives the fix" and "One fact derived twice" read for the findings; plus Documentation Staleness. 15 read, 23 not read.
- **code-check-r.md**: none newly; the fix diff changes only comments in R code and prose. 0 read, 132 not read.
- **code-check-shell.md**: Git plumbing calls whose default answers a different question (the report's code-commit line from `git log -1 --format=%H -- <paths>`). 1 read, 74 not read.
- **code-check-spatial.md**: none; the fix changes no spatial code, only a sentence about terra's timings. 0 read, 98 not read.

Index, diff and changed files read from file.

## Scope check

- `git diff f19b65aa HEAD` (round 4's HEAD to now): research/runoff_products.md:32, scripts/runoff_products_compare.R:18-24 (comment only), planning/ and the report. Every +/− line of that diff, outside the report and planning/active/progress.md and review-round4.md, is a line of round4_fix.diff.
- The report: `git diff f19b65aa 8db53405` changes line 4 alone, code commit `a61e7ddc` → `f32e6804`; `git log -1 --format=%H -- R scripts data-raw inst/vignette-data DESCRIPTION` is `f32e68043bb3…`, so line 4 is right. The tracked report's md5 is `e33ca278966f03469c59ef228931d828`, the md5 progress.md (uncommitted edit) gives for runs 11 and 12.
- CLAUDE.md, research/README.md, runoff_prior_art.md, water_balance_method.md, pcic_scenarios.md, the rule file and the test are unchanged since round 4, and the report's values are unchanged, so every round-3 "holds" row (re-checked in round 4) still holds.

## Findings

- **[fragile]** scripts/runoff_products_compare.R:21-23 — the stage-1 remedy, "After changing stage 1 here, remove its .tif files (sample_version is not in their keys)", does not finish the job, so a rerun after following it reproduces the stale result. Removing `tc_q_bc_<tc_key>.tif` or `isolines_<iso_key>.tif` rebuilds the `.tif` under the same name, because its key (lines 160, 218) holds inputs and parameters, not the edited code. Stage 2's directory is keyed on that same `tc_key`/`iso_key` (lines 266-267), not on the `.tif`'s content, so the old `sample_<s>/<key>/<WSG>.rds` files are still there. `sample_group()` skips each one (line 295), `todo` (line 323) is empty, and stage 3's directory (line 344, keyed on stage 2's key) is reused too. The rebuilt `.tif` is never read, and the report comes out byte-identical to the stale one. This is round 4's finding 1 again, with round 4's suggested wording (mine) as the cause. Say: after changing stage 1, remove its `.tif` files *and* bump `sample_version` (or remove the `sample_<s>/` and `upstream_<s>/` caches). Keying stage 2 on `md5(sets[[s]]$file)` in place of the stage-1 key would make it automatic, though it depends on terra writing the same bytes each time.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ("run the remedy yourself, for every input the clause can receive, and check it finished the job"); code-check.md "Written data outlives the fix"
- **[fragile]** scripts/runoff_products_compare.R:264 — `sample_version <- "2"  # bump whenever sample_group() changes what it stores` is a second copy of when to bump, and it disagrees with the header's new rule (lines 22-23: bump after changing stage 2 *or 3*). Someone editing `upstream()` (lines 342-360) who checks the variable's own comment concludes that no bump is needed, and stage 3's cache (keyed on R/ code and stage 2's key only) serves the old upstream means. The finding above also needs a bump after a stage-1 change. Make the line comment match the header, or have it point to the header.
  - **Rule:** code-check.md "One fact derived twice"; code-check.md "A guard's scope, escape hatches, and remedies" (a remedy repeated across sibling messages)
- **[fragile]** research/runoff_products.md:32 — the new citation `planning/archive/2026-11-issue-243-runoff-products/findings.md` points to a path that does not exist at HEAD (the record is `planning/active/findings.md`). Its name is chosen later by hand: `/planning-archive` asks for "a brief slug" and dates the directory by the month it is archived. The issue's title ("Backlog move 27: The runoff products no report covers yet") and the branch name (`243-backlog-move-27-the-runoff-products-no-r`) both suggest a slug other than `runoff-products`, and nothing checks research paths (`research_check.sh` reads dates and headings only). The repo's form for a citation into an archive is a glob, `planning/archive/2026-11-issue-213-*/` (research/station_temperature_fill.md:3). Use `planning/archive/2026-11-issue-243-*/findings.md`, or put checking the path on the archive step's checklist.
  - **Rule:** code-check.md "Documentation Staleness" (paths in docs follow the file); none more specific

## Enumeration

Sources: C = scripts/runoff_products_compare.R at HEAD; F = planning/active/findings.md:41 and :48 at HEAD; R = data/checks/runoff_products_compare_20260717.txt; M = mtimes in the main checkout's data/runoff_products/sample_tc/a77a366b4e/ and sample_iso/a0223528f2/ (the first, ellipsoidal run, 4 workers; tc is written before iso for each group, so iso time = iso mtime − tc mtime).

### The cache comment, stage by stage

| place | claim | source | verdict |
|---|---|---|---|
| C:18-19 | stage 1 keyed on its inputs' md5s and its parameters, not on the script's code | C:160 `tc_key = key_of(tc_md5, tc_ext)`; C:218 `iso_key = key_of(lines_md5, densify_m, grid_txe, grid_tye, grid_tr, alg_tin, alg_idw, flat_tol, gdal_sf)` | holds |
| stage 1a | edits caught | a new TerraClimate file, `tc_ext` | — |
| stage 1a | edits not caught | the crop and CRS assignment, layer names, `datatype` (C:163-172); terra/GDAL versions | — |
| stage 1b | edits caught | the isolines file, densify step, grid extent and cell size, both algorithm strings, `flat_tol`, sf's GDAL version | — |
| stage 1b | edits not caught | point construction (C:222-228), `grid_one()`'s −9999 reclassify, the flat-layer formula, layer names, `datatype` (C:229-256); terra's version | — |
| C:19-21 | stage 2 on stage 1's key, wet_ws_sample.R, wet_ws_fetch.R, sample_version | C:264-267 | holds |
| stage 2 | edits caught | a stage-1 key change; R/wet_ws_sample.R (holds `wet_ws_frame`); R/wet_ws_fetch.R (holds `wet_ws_geom`, `wet_upstream_irregular`); a `sample_version` bump | — |
| stage 2 | edits not caught | `sample_group()`, its crop margins, the `"local"` relabel, the `ext_g` query (unless `sample_version` is bumped); a stage-1 `.tif` rebuilt under an unchanged key; fwapg; terra | — |
| C:21 | stage 3 on stage 2's key and the upstream code in R/ | C:341-344: wet_upstream_means.R, wet_upstream_sums.R (holds `wet_seg_*`, `wet_count_lt`), wet_ws_fetch.R; `wet_upstream_mean` is only linked from roxygen, not called | holds |
| stage 3 | edits caught | a stage-2 key change (so a `sample_version` bump); those three R files | — |
| stage 3 | edits not caught | `upstream()` in C (C:342-360) unless `sample_version` is bumped; fwapg | — |
| C:21-23 | after changing stage 1, remove its .tif files | C:266-267, 295, 323, 344 | **fails: the rebuilt .tif is never resampled** (finding 1) |
| C:22 | sample_version is not in stage 1's keys | C:160, 218 | holds |
| C:22-23 | after changing stage 2 or 3, bump sample_version | C:266-267 → C:344 | holds (a bump renames both stage 2's and stage 3's directories) |
| C:264 | bump whenever sample_group() changes what it stores | header C:22-23 | **disagrees with the header on stage 3** (finding 2) |
| C:23-24 | fwapg and installed packages are in no key; stages 4 and 5 recomputed | C after line 360 | holds (sf's GDAL version is in `iso_key`; over-keying, accepted in round 4) |

### The timings

| place | claim | source | verdict |
|---|---|---|---|
| F:41 | 200 polygons 14.9, 16.3, 16.6 s; 50 polygons 4.5, 4.8, 4.3, 4.0 s; 3.65, 3.56 s; 0.6–0.9 ms on lon/lat; local 0.025, 0.028 s | the recorded measurement (probes not saved; the scratchpad's prof*.R last modified 00:11–00:15 UTC 2026-11-28, so "probes run 2026-11-28" is consistent in UTC) | accepted as producer |
| research:32 | about 70–100 ms per FWA polygon | F: 74.5, 81.5, 83 / 90, 96, 86, 80 / 73, 71.2 ms (71–96) | holds |
| research:32, F:41, F:48 | 15–50 minutes per watershed group (MORK 46 min) | M: BABL 16.5, TATR 28.3, KOTL 32.5, PINE 34.8, MORK 46.6 min (MORK 46.8 from the run's 16:11:58 start) | holds (MORK is 46.6, written as 46) |
| research:32 | under 1 ms per polygon on lon/lat | F 0.6–0.9 ms | holds |
| research:32 | neither extent nor cell size moved it | F 4.0–4.8 s over four extents and cell sizes | holds |
| research:32 | more than 100 times faster, 0.025 s against 3.6 s for 50 SALR polygons | F: 0.025/0.028 against 3.65/3.56 s (127–146×) | holds |
| research:32 | the record's path | planning/archive/2026-11-issue-243-runoff-products/findings.md: missing at HEAD, slug chosen at archive | **fragile** (finding 3) |
| research:32 | fractions within 1.1 × 10⁻⁷ | F:41 1.1e-7 | holds |
| C:305-306 | about 100 times slower than on lon/lat | F: 71–96 ms against 0.6–0.9 ms (79–160×) | holds, as a round figure |
| C:309-310 | measured on SALR, within 1.1e-7 | F:41 | holds |

### Other copies (branch diff, planning/ excluded, plus CLAUDE.md and research/)

| place | claim | source | verdict |
|---|---|---|---|
| everywhere | the old "75–90", "15–45", "about 1 ms" | grep over the diff, research/, CLAUDE.md, scripts/, R/ | none left |
| CLAUDE.md:44 | isolines sampled under "local", ellipsoidal on a projected CRS, BC Albers equal-area | F:41, C:300-312 | holds; no timing or remedy copy |
| everywhere | a third statement of when to bump `sample_version` or remove caches | grep `sample_version`, `bump`, `remove` | only C:21-23 and C:264 (finding 2) |

### The report and round 3's rows

| place | claim | source | verdict |
|---|---|---|---|
| R line 4 | code commit f32e6804, the last commit to code_paths | `git log -1 --format=%H -- R scripts data-raw inst/vignette-data DESCRIPTION` | holds |
| R | changed only in line 4 since round 4 | `git diff f19b65aa 8db53405` | holds |
| progress.md (uncommitted) | runs 11 and 12 md5 e33ca278… | `md5` of the tracked report | holds |
| research:3 | two runs gave byte-identical reports | runs 11/12, one md5 | holds |
| round 3 "holds" rows | every value | R values, CLAUDE.md, the other research files, rule, test unchanged since round 4 | still hold |
