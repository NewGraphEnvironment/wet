# Code-check round 6 (#243)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (`|` rows skipped); "Written data outlives the fix" (cache keyed by fewer inputs; over-key, never under-key), "A guard's scope, escape hatches, and remedies" (run the remedy for every input the clause can receive), "One fact derived twice" and "A guard that fails toward pass" ("a comment worded more narrowly than the code reaches is true of the case it names") read for the findings; plus Documentation Staleness. 15 read, 23 not read.
- **code-check-r.md**: "Never name a durable artifact by a hash the library reserves the right to change" (the stage-2 key is `tools::md5sum()` of file bytes, base R: holds). 1 read, 131 not read.
- **code-check-shell.md**: "Git plumbing calls whose default answers a different question" (the report's code-commit line). 1 read, 74 not read.
- **code-check-spatial.md**: "terra: `wrap()` carries the tempfile basename in `varnames`" (whether the `.tif` bytes, now the stage-2 key, can change on a rebuild with unchanged values: at worst a resample, never a stale reuse). 1 read, 97 not read.

Index, diff and changed files read from file.

## Findings

- **[fragile]** scripts/runoff_products_compare.R:23-24 (and the line comment at :265) — the bump rule now names two functions, "After changing sample_group() or upstream() here, bump `sample_version`", but two pieces of the script's stage-2 code sit outside both and change what stage 2 stores with no key moving: the `crs` entries of `sets` (:268-269), which pick `sample_group()`'s branch (the crop window from the lon/lat or the Albers extent, and whether raster and polygons are relabelled `"local"`), and the `ext_g` extent query (:278-284), which sets every crop window (a window narrower than a group's polygons changes its sample). An edit to either, followed by the comment's remedy (none applies, since neither is in `sample_group()` or `upstream()`), reuses every `sample_<s>/<key>/<WSG>.rds` and every `upstream_<s>/` file. Round 4's wording ("after changing stage 2 or 3 here") covered them; round 5 narrowed it to agree with the line comment. Say "after changing stage 2 or 3 here (`sets`, the extent query, `sample_group()`, `upstream()`)", and have the line comment point to the header rather than restate it.
  - **Rule:** code-check.md "A guard that fails toward pass" ("a comment stating a property ... worded more narrowly than the code reaches is true of the case it names"); code-check.md "Written data outlives the fix" ("A cache keyed by fewer inputs than the write depends on")
- **[fragile]** research/runoff_products.md:32 — the glob `planning/archive/2026-11-issue-243-*/findings.md` fixes the month. `/planning-archive` names the directory `YYYY-MM-issue-N-slug` by the month it runs, and every archive directory in the repo carries the month of the commit that added it (checked over all of `planning/archive/`). The branch is not archived yet (the glob matches nothing at HEAD) and it is 2026-11-27 in Vancouver: an archive on or after 1 December names `2026-12-issue-243-…`, and the citation points nowhere, with nothing to catch it (`research_check.sh` reads dates and headings). The other month-fixed globs (`station_temperature_fill.md`, `discharge_publish.md`, `station_water_temperature.md`) were written and archived in one month. Use `planning/archive/*-issue-243-*/findings.md`, or check the month at the archive step.
  - **Rule:** code-check.md "Documentation Staleness" (paths in docs follow the file); none more specific

## Enumeration

Sources: C = scripts/runoff_products_compare.R at HEAD (0374537f); R = data/checks/runoff_products_compare_20260717.txt; D = the main checkout's `data/runoff_products/` (read only); L = the main checkout's `data/logs/243/`.

### The cache chain, stage by stage

| place | claim | source | verdict |
|---|---|---|---|
| stage 1a | new result on: a new raw `TerraClimate_19812010_q.nc` (only if removed and refetched), `tc_ext` | C:159-162 `tc_key = key_of(md5(f_tc), tc_ext)` names the `.tif` | — |
| stage 1a | reused silently on: the crop, CRS assignment, layer names, `datatype` (C:163-173); terra/GDAL versions | C:163 `if (!file.exists(f_tc_bc))` | — |
| stage 1b | new result on: the isolines file, densify step, grid extent and cell, both algorithm strings, `flat_tol`, sf's GDAL version | C:219 `iso_key` | — |
| stage 1b | reused silently on: point construction (C:222-229, recomputed every run but used only on a rebuild), `grid_one()`, the flat formula, names, `datatype` (C:230-258); terra's version | C:230 | — |
| C:18-20 | stage 1's `.tif` files named for inputs' md5s and parameters, not the script's code; after changing stage 1, remove them | C:162, 220 | holds; following it now finishes the job: the rebuilt `.tif`'s md5 is stage 2's key (C:268-269), so a changed `.tif` renames stage 2's and stage 3's directories (C:271, 346). `isoline_points_<key>.gpkg` is not a `.tif` but is rewritten by `file.rename()` on the rebuild (C:233-235) |
| C:20-21 | stage 2 keyed on the md5 of the `.tif` it samples, "so a rebuilt .tif is sampled again" | C:268-269 `key_of(md5(f_tc_bc), ...)` | holds in effect: a rebuild with identical bytes reuses samples of identical content; one whose bytes differ (values, or metadata such as a tempfile-derived varname) is resampled. Never stale |
| C:21-22 | stage 2 also on wet_ws_sample.R, wet_ws_fetch.R, `sample_version` | C:266, 268-269 | holds; `sample_group()` calls `wet_ws_geom()` (R/wet_ws_fetch.R:88) and `wet_ws_sample()` → `wet_ws_frame()` (R/wet_ws_sample.R:30, 82), no other wet function outside those files (grep of non-roxygen calls) |
| stage 2 | reused silently on: `sample_group()` (crop margins, the `"local"` relabel) unless bumped; `sets`' `crs`, the `ext_g` query (finding 1); fwapg; terra | C:265-327 | — |
| C:22-23 | stage 3 on stage 2's key and the upstream code in R/ | C:343, 346 `key_of(sets[[s]]$key, up_code)`; up_code = wet_upstream_means.R, wet_upstream_sums.R (holds `wet_count_lt`, `wet_seg_*`), wet_ws_fetch.R (`wet_ws_fetch`, `wet_upstream_irregular`) | holds; `wet_upstream_mean()` appears only in roxygen |
| stage 3 | reused silently on: `upstream()` unless bumped; fwapg | C:345-362 | — |
| C:23-24 | after changing sample_group() or upstream() here, bump `sample_version` | C:268-269 → 346 | holds for those two; **narrower than stage 2's code** (finding 1) |
| C:265 | bump whenever sample_group() or upstream() changes what it stores | header C:23-24 | agrees with the header (same gap, finding 1) |
| C:24 | fwapg and installed packages are in no key | C:219 holds `gdal_sf` | over-keying only, as accepted in rounds 4 and 5; no remedy is stated for them, and bumping (stages 2-3) or removing the `.tif` (stage 1) covers them |
| C:24-25 | stages 4 and 5 recomputed every run | C after :364 | holds |
| stage 1 remedy | an edit for which it leaves a stale result | the cascade above | none: every stage-1 edit that changes the `.tif` changes its md5 |

### The keys, re-derived

| place | claim | source | verdict |
|---|---|---|---|
| R:17 | Samples: TerraClimate 666ff278b6, isolines 5176108a9b | md5 of D/tc_q_bc_3483ea5ca8.tif and D/isolines_2197094c35.tif with the md5s of R/wet_ws_sample.R, R/wet_ws_fetch.R and "2", joined by `|` and md5'd as `wet_md5_text()` does (writeLines adds `\n`), first 10 | holds: 666ff278b6, 5176108a9b; D/sample_tc/666ff278b6 and D/sample_iso/5176108a9b hold 236 files each |
| stage 3 dirs | key_of(stage 2 key, up_code) | same recipe | 32e16e59c7 and 0b7f0ee772, both present under D/upstream_tc and D/upstream_iso |

### Round-5 diff, other claims

| place | claim | source | verdict |
|---|---|---|---|
| research:32 | the archive cited by glob, `planning/archive/2026-11-issue-243-*/findings.md` | archive names `YYYY-MM-issue-N-slug`; soul's planning-archive SKILL.md:46; all archive dirs dated by the month they were added | form holds; the month is a guess (finding 2) |
| research/station_temperature_fill.md:3 | the convention | `planning/archive/2026-10-issue-40-*/findings.md`, `planning/archive/2026-11-issue-213-*/` | holds (213's written 2026-11-25, archived the same day) |
| C:267 | "keyed on what each .tif holds, not on the key that named it" | C:268-269 | holds |

### Other copies of the cache description

| place | claim | source | verdict |
|---|---|---|---|
| CLAUDE.md:44 | "Each watershed group is sampled once and accumulated per first-level code, cached under `<WET_DATA_ROOT>/runoff_products/`"; "byte-identical on a rerun" | C | holds; names no key or remedy |
| research/runoff_products.md, research/README.md | any key or remedy wording | grep `sample_version`, `keyed`, `cache` | none |
| branch diff | a third statement of when to bump or remove | grep `sample_version`, `bump`, `remove`, `keyed`, `named for` over the diff (outside review files) | only C:18-25 and C:265 |
| planning/active/task_plan.md:50 | "cached per group, keyed on the inputs' md5s and the code files read" | the plan's wording | holds loosely (the `.tif` md5 derives from the inputs; the R files read are keyed); a plan, not a description of HEAD |

### The report

| place | claim | source | verdict |
|---|---|---|---|
| R, 0374537f | changed only the code-commit and Samples lines | `git diff 8db53405 0374537f`: line 4 (f32e6804 → b6692079) and line 17 (571f1ec516/c6d7c91381 → 666ff278b6/5176108a9b) | holds |
| R, 8db53405 | changed only the code-commit line | `git diff f19b65aa 8db53405`: 1 line | holds |
| R:4 | code commit b6692079 | `git log -1 --format=%H -- R scripts data-raw inst/vignette-data DESCRIPTION` = b6692079… | holds |
| progress.md (uncommitted) | run 13 resampled from scratch, about 19 minutes; run 14 from cache | L run13: "236 groups to sample" 18:16:55, 18:16:29 → 18:35:31; run14: no sampling line, 18:35:52 → 18:36:49 | holds |
| progress.md (uncommitted) | runs 13 and 14 md5 31216a4a… | tracked R md5 = 31216a4a832e0fa0bffc931244695153 (run 14's output); the logs record no md5, so run 13's is not re-derivable | holds for run 14 |
