# Code-check round 3 (#243)

## Checklist read

- **code-check.md**: all 14 H3s under `## Mechanisms`, prose only, `|` rows skipped (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice), plus Documentation Staleness. 15 read, 23 not read.
- **code-check-r.md**: `system2(stdout = TRUE)` warns on a non-zero exit; `clusterApply()` returns `NULL` for no tasks; `on.exit()` at a script's top level never fires; `sort()` and `order()` collate by `LC_COLLATE`; Postgres row order is never fixed unless the query fixes it; Rscript reads a script as it runs; A `skip_if_not()` skips only its own `test_that()` block; Under `R CMD check`, tests run from a temp dir against the INSTALLED package. 8 read, 124 not read.
- **code-check-shell.md**: Git plumbing calls whose default answers a different question. 1 read, 74 not read.
- **code-check-spatial.md**: sf and terra can link different GDALs; `sf::gdal_utils()` does not raise when GDAL cannot open the source; terra: `extract()` returns no row for ground beyond the raster; The BC WFS caps an un-paged `GetFeature` at 10,000 features; A GDAL failure partway through `sf::st_read()` returns the rows read so far; GeoJSON in a projected CRS is silently non-portable; terra keeps a result in memory whenever it fits. 7 read, 91 not read.

Index, diff and changed files read from file.

## Findings

- **[fragile]** research/pcic_scenarios.md:38: "The coverage report's line saying no report scores TerraClimate runoff predates that report and is left as it ran." The coverage report holds two lines this branch has made false, not one: data/checks/pcic_coverage_20260717.txt:34 (TerraClimate runoff) and :35 ("the 1961-1990 runoff isolines: no report scores them yet"). The sentence names one member of a two-member set. "Left as it ran" also covers only the report: scripts/pcic_coverage.R:258-259 still prints both literals, so any rerun of `pcic_coverage.R` publishes both false lines again. Name both lines, and either change the two literals in `pcic_coverage.R` (the next rerun then prints them) or say the script still prints them.
  - **Rule:** code-check.md "One fact derived twice" (a literal inside a printed string, which nothing consumes)
- **[fragile]** research/runoff_products.md:42 and :53: the disagreement log's evidence for zone 03 (Northern Rocky Mountains) is "precipitation −138 mm" and for zone 22 (Lower Columbia Basin) "precipitation −171 mm". Report section 9 has the zone adjustment as the larger term in both zones (−142 and −203 mm), and the research file's own bullet at :17 says so ("but two, the Northern Rocky Mountains and the Lower Columbia Basin, where the zone adjustment is as large or larger"). Rows 25–27 and 29 name the zone adjustment beside precipitation. Rows 03 and 22, the only two zones where the adjustment outweighs precipitation, name precipitation alone. Shortening section 9 into the log dropped the term that dominates those two zones.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ("Compression runs both ways": check the compression against each source)
- **[fragile]** research/runoff_products.md:7 ("at the median gauge its precipitation is 202 mm below climr's, its AET 85 mm below ours") and :40 ("precipitation −202 mm at the median gauge"): section 9's BC row gives each term's median taken separately across gauges. The report's caption says plainly that these "medians need not sum to the gap's median". No single "median gauge" carries both −202 and +85, and the code computes none. Say "the median precipitation difference is −202 mm, the median AET difference +85 mm".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (a compression that adds a claim)
- **[fragile]** scripts/runoff_products_compare.R:18-20: the header says "Stages, each cached under <WET_DATA_ROOT>/runoff_products/ and keyed on its inputs and the code that builds it". The code does not support either half:
  - Stages 4 (the period ratio) and 5 (scores) are not cached at all.
  - Stage 1's keys leave out the code that builds the rasters. `tc_key` (line 156) is the file's md5 and the crop extent; `iso_key` (line 214) holds the gridding parameters and GDAL's version. Neither covers the crop and write code (lines 159–168), the −9999 reclassify (line 238) or the flat-layer construction (lines 247–248).
  - Stage 2's dependence on `sample_group()` rests on a hand-bumped `sample_version`.

  So an edit to stage 1's construction reuses the old `.tif`, and the rerun stays "byte-identical" to the stale result. Either hash the script's stage code into the keys, or narrow the comment to what is keyed (as the `sample_version` comment already does for stage 2).
  - **Rule:** code-check.md "Written data outlives the fix" ("A cache keyed by fewer inputs than the write depends on returns plausible wrong data")
- **[fragile]** CLAUDE.md:44: "cached under `<WET_DATA_ROOT>/runoff_products/` (fetches and run logs under `<WET_DATA_ROOT>/logs/243/`)". The fetched files go to `<WET_DATA_ROOT>/runoff_products/raw/` (script lines 72, 149, 177–178). Only the fetch log, `runoff_products_fetch.tsv` (line 95), sits under `logs/243/`. This is a fourth spelling of the script's path list, and it disagrees with the script header (lines 9–10), which is correct.
  - **Rule:** code-check.md "One fact derived twice"
- **[fragile]** scripts/runoff_products_compare.R:66: `code_commit` is written with `git log --format=%h`, whose length is git's automatic abbreviation and scales with the object count of each clone. The rule commit, by contrast, is a fixed `substr(, 1, 8)` (line 478). On another clone, or after the repository grows past a threshold, a rerun with no code change prints a 9-character hash in report line 4, so the report is no longer byte-identical as the header and CLAUDE.md promise. `--format=%H` with `substr(, 1, 8)`, as for the rule commit, removes this.
  - **Rule:** none

## Mechanism

Every earlier finding, and every finding above, has one shape: **a fact has one producer, and copies of it were typed by hand into other places with nothing tying each copy back to that producer.** The producer is the tracked report, a constant in the rule or the script, or the `code_paths` vector. The copies are research prose, CLAUDE.md, the script's header and comments, captions printed by the script, and other repos' and reports' lines that name the products. Each copy is edited on its own, so fixing one leaves its siblings as they were. That is "One fact derived twice" applied to prose, and it reaches every way a claim names a population:

- **a count**: zone counts with and without unstable verdicts (r2);
- **a member list**: `code_paths` written three or four ways (r1, r2); the coverage report's stale lines, one of two named (r3); the CLAUDE.md path list (r3);
- **a place-grouping**: "upper Skeena" (r1), "plains tributaries" (r2);
- **a threshold restated as a literal**: the star at `< 5` against `rp_min_gauges` (r1); "lake outlets" as a reason no code tested (r1);
- **a compression of a table**: the log's evidence column (r3); "at the median gauge" (r3);
- **a quantifier**: "Stages, each cached ... keyed on ... the code" (r3).

The tables a guard reads (sections 4, 8 and 9) have been right throughout. Only the restatements drifted, and rounds stopped finding them only when a reviewer re-derived every claim from the report or the code. The enumeration below does that for every claim in the branch.

## Enumeration

Sources: R = data/checks/runoff_products_compare_20260717.txt (HEAD copy, identical to the working file); C = scripts/runoff_products_compare.R; RU = scripts/runoff_products_rule.R. Zone names were checked against other tracked reports and research (wally, monthly_error, small_basin), which give the same number-to-name pairs.

### research/runoff_products.md

| place | claim | source checked | verdict |
|---|---|---|---|
| :3 header | rule registered at a5e867c before script or value | git log; C:41 | holds |
| :3 | province run 768876badf | main checkout data/wb/768876badf, the only run key | holds |
| :3 | run logs and fetch log in data/logs/243/ | main checkout data/logs/243 (8 run logs, fetch tsv) | holds |
| :3 | two runs gave byte-identical reports | runs 7 and 8 both wrote the report; no md5 logged | cannot be checked from the artifacts; consistent |
| :7 | 315 gauges; TC median −33 %, middle half −46 to −13, 23 % within | R §4 BC: −33.0 [−45.5, −13.3] 23 % | holds |
| :7 | balance −4 %, routed −3 % | R §4: −3.6; routed n283 −2.6 | holds |
| :7 | theirs province-wide and in 14 zones, two more unstable | R §8 TC column: theirs 01 03 05 07 08 13 14 20 21 22 25 26 27 29 (14); unstable(theirs) 10, 19 | holds |
| :7 | unresolved in Northern Interior Plains (04) | R §8 04 unresolved | holds |
| :7 | ours in Southern Thompson Plateau (24); balance +36, TC −13 | R §8 24: −12.5, +36.4, ours | holds (−12.5 sits at the rounding edge) |
| :7 | precipitation 202 mm below climr's, AET 85 mm below ours "at the median gauge" | R §9 BC: P −202, AET +85, each a separate median | **fails: separate medians, not one gauge** (finding 3) |
| :9 | isolines +2 % at 292, middle half −14 to +18, 61 % within | R §4: +1.8 [−14.0, +17.8] 61 % | holds |
| :9 | balance −5 % at same gauges | R §4: −4.5 | holds (rounding) |
| :9 | not material BC + 17 zones, 2 more unstable, 7 too few | R §8 TIN: nm 01 03 08 10 13 14 15 16 18 19 20 21 22 25 26 27 28 (17); unstable 07, 23; too few 02 04 05 06 11 12 17 (7) | holds |
| :9 | ours STP; ours-unstable zone 9; theirs zone 29 −22 vs +9 | R §8 24, 09, 29: −21.9 vs +8.8 | holds |
| :9 | too few long-record gauges in 29 | R §7 zone 29: 2 gauges, no ratio | holds |
| :11 | isolines match gauges better than the balance | R §4: +1.8 / 61 % against −4.5 / 52 % | holds |
| :11 | share NSE 0.55 vs 0.94 vs 0.89 at 283 | R §5 line 2 | holds |
| :15 | 12 layers, 1/24°, no resampling, sum of months | C:159-171, :367; R §1 0.041667 | holds |
| :15 | covers every basin, none dropped at 95 %, lake outlets included | R §2 TC scores 315; 19 lake outlets, all tc_cov ≥ 0.978 | holds |
| :16 | 314 wholly covered, median 0.7 %, bound 5 % | R §3 0.70 % at 314 | holds |
| :16 | ppt_tc/aet_tc resampled to 30″ grid | R/wet_terraclimate_aet.R:5-8, 70 (bilinear) | holds |
| :17 | gap splits exactly into four terms | C:433-438 stopifnot | holds |
| :17 | P largest in every theirs zone but 03 and 22 | R §9: 03 zadj −142 > P −138; 22 −203 > −171; all others P largest (14: 151 > 142) | holds |
| :17 | P median −126 to −1,404 | R §9 theirs rows: min 08 −126, max 27 −1404 | holds |
| :17 | AET offsets +29 to +147 | R §9 theirs rows: 07 +29 … 25 +147 | holds |
| :17 | storage under 10 mm | R §9 max +9 (01) | holds |
| :17 | zones 25–27, 29 adjustment 119 to 491 mm | R §9: 299, 491, 119, 408 | holds |
| :18 | TC uses no gauge; no glacier or groundwater terms | runoff_prior_art.md rank 5 | holds (cited) |
| :19 | robots.txt disallows fileServer, ncss, dodsC, wcs, wms, cdmremote, catalogs | live robots.txt, read 2026-11-27 | holds |
| :19 | 86,671,480 bytes, md5 691e6bfe…, logged; no other TC request | fetch tsv: one TC row with those values | holds |
| :23 | 66 lines, nine levels 50–4,000, held to server count; none of different levels touch | R §1 lines 11–13; C:189, 197-205 | holds |
| :23 | no robots.txt on the WFS host | openmaps.gov.bc.ca/robots.txt answers 404 | holds |
| :24 | densified 1 km, 31,474 points, GDAL 3.8.5, TIN/IDW parameters | R §1; C:210-211 | holds |
| :24 | IDW median 0.0 %, middle half −2.0 to +1.7 | R §6 | holds |
| :24 | same verdict in every zone but 07 and 23 (TIN unstable), "surface-dependent" | R §8: 07 TIN unstable(nm) / IDW nm; 23 TIN unstable(nm) / IDW unstable(theirs); all others equal | holds |
| :25 | flat median 20 %, 95 gauges above half | R §6: 0.20, 95 | holds |
| :25 | nearly all flat in zones 19–21 | R §6 zone medians 0.99, 1.00, 1.00 | holds |
| :26 | 23 gauges below 95 % | R §2 table: 23 rows; 315 − 292 | holds |
| :26 | 6 Stikine, 5 Skeena + Nass, 8 Liard, Finlay + Alces in Peace, 2 Flathead | R §2 rows by station: 08CD001, 08CA001/2, 08CB001, 08CE001, 08CF001; 08DB001, 08EB004/5, 08EC013, 08EF001; 10AC004/6, 10BA001, 10BB002, 10BE008/12, 10CB001, 10CC002; 07EA005, 07FD004; 08NP003/4 | holds |
| :27 | water_balance_method called them "independent" until now | diff of research/water_balance_method.md:730 | holds |
| :28 | 121 natural BC gauges, ≥ 20 years each period, median 0.985 | R §7; R/wet_station_select.R (REGULATED = 0, prov BC, 20 days) | holds |
| :28 | each zone with ≥ 3 gauges within 0.95 to 1.03 | R §7: min 0.951, max 1.033 (zone 15) | holds at the 2 decimals written; 1.033 strictly exceeds 1.03 |
| :28 | scaled, no zone's verdict changes | R §8 period column re-judged by hand: every zone keeps its verdict (23: 20.1 points apart, both inside → still not material) | holds (medians; stability under scaling not computed) |
| :28 | zone 29 has two such gauges | R §7 | holds |
| :32 | terra 1.9.50; 75–90 ms per polygon; 15–45 min per group; ~1 ms on lon/lat; extent and cell size no effect | planning/active/findings.md:41 | holds |
| :32 | "local" about 100× faster; fractions within 1.1e-7 | findings.md:41: 0.025 s / 50 polygons = 0.5 ms, i.e. 150–180× | loose (order of magnitude holds) |
| :32 | province run samples on lon/lat | scripts/wb_province.R 30″ lon/lat grid; CLAUDE.md | holds |
| :36 | log definition (≥ 5 gauges or province, > 20 points, one outside ±20) | RU:46-57; C:604 `material()` | holds |
| :36 | verdicts in §8, evidence in §9 | R headings | holds |
| :40–58 | 19 TC rows: zone set and every product, balance, verdict value | R §8/§9: zone set BC 01 03 04 05 07 08 10 13 14 19 20 21 22 24 25 26 27 29 = §9 list; each value checked | holds |
| :40–58 | evidence P values per row; zone adjustment 299/491/119/408 | R §9 | holds as numbers; **rows 03 and 22 omit the larger zone-adjustment term** (finding 2); BC row "at the median gauge" (finding 3) |
| :43 | 04: both low; 5 gauges | R §8 n 5, −64.7 / −32.9 | holds |
| :54 | 24: dry-interior overshoot (monthly_error.md) | citation | holds (cited) |
| :59–61 | isoline rows 09, 24, 29; ratio 0.968; two long-record gauges | R §9 isolines; §7 | holds |

### Other prose in the branch

| place | claim | source checked | verdict |
|---|---|---|---|
| research/README.md:23 | TC median 33 % low, theirs in most zones, mostly precipitation, ours in STP; isolines +2 %, not material BC, drawn from gauges | R §4/§8 (14 + 2 of 25 zones with a verdict) | holds |
| research/runoff_prior_art.md:57 | TC median 33 % low, mostly precipitation | R §4/§9 | holds |
| research/runoff_prior_art.md:58 | isolines median +2 % at gauges covered | R §4 | holds |
| research/water_balance_method.md:730 | not independent, drawn from WSC gauges | source description | holds |
| research/pcic_scenarios.md:38 | GEOGLOWS v2 and Water Tool unscored; TC and isolines scored by runoff_products_compare | R; #244/#245 titles resolved through gh | holds |
| research/pcic_scenarios.md:38 | "the coverage report's line ... TerraClimate ... left as it ran" | data/checks/pcic_coverage_20260717.txt:34-35; scripts/pcic_coverage.R:258-259 | **fails: two stale lines, and the script still prints both** (finding 1) |
| CLAUDE.md:44 | one logged fetch from a disallowed path, as wet_terraclimate_aet() fetched | fetch tsv; R/wet_terraclimate_aet.R:37 (same fileServer path); robots.txt | holds |
| CLAUDE.md:44 | WFS, sf's GDAL, TIN + IDW, fixed 1 km BC Albers | C:206-245 | holds |
| CLAUDE.md:44 | 315 gauges; rule at a5e867c; script refuses another version; test tests verdicts | C:41-58; test file | holds |
| CLAUDE.md:44 | signed median errors, LOO stability, period ratio at long-record natural gauges | RU; C:377-403 | holds |
| CLAUDE.md:44 | each group sampled once, accumulated per first-level code | C:259-360 | holds |
| CLAUDE.md:44 | "fetches and run logs under logs/243/" | C:72, 95, 149, 177-178 | **fails: fetched files are under runoff_products/raw/** (finding 5) |
| CLAUDE.md:44 | "local" label, reason | C:300-311 | holds |
| CLAUDE.md:44 | report byte-identical on a rerun | C:66 `%h` | holds today; fragile across clones (finding 6) |
| CLAUDE.md:44 | #244, #245 append to the log | gh titles | holds |

### Script comments and printed captions (C)

| place | claim | source checked | verdict |
|---|---|---|---|
| C:7-17 | inputs fetched once into runoff_products/raw, every request logged to logs/243 | C:72, 95-110, 150-185; fetch tsv (3 rows) | holds |
| C:18-20 | stages each cached, keyed on inputs and the code that builds them | C:156, 214, 260-263, 337; stages 4–5 uncached | **fails** (finding 4) |
| C:21-30 | stage descriptions | code | holds |
| C:31-34 | refuses uncommitted `code_paths` or data/checks; records last commit to `code_paths` | C:62-66 | holds (one vector) |
| C:36 | wb_cv_lib supplies load_all, cal, release, fit_dir, wb_hydat, stamp, score_code_md5 | scripts/wb_cv_lib.R:8-19, 238 | holds |
| C:61 | one set of paths for guard, commit and label | C:62-66, 478-479 | holds |
| C:141-144 | shared set ≥ a fifth of observed, 283 | stopifnot | holds |
| C:155 | BC with a margin | fwapg: groups' lon/lat extent −139.06…−114.05, 48.30…60.00, inside −140…−113, 47…61 | holds |
| C:163 | netCDF declares no CRS, as wet_terraclimate_grid | R/wet_terraclimate_aet.R:65 | holds |
| C:207 | grid = groups' extent rounded out to 10 km | fwapg: 273314–1870651, 367780–1735770 → 270000–1880000, 360000–1740000 | holds |
| C:301-306 | ~100× slower than lon/lat; 1.1e-7 on SALR | findings.md:41 (75–90 ms against ~1 ms) | holds |
| C:419-420 | ppt_tc bilinear, filled | scripts/wb_province.R:127-135 | holds |
| R line 4 / C:478 | code commit is the last commit to `code_paths` | git log: 61972008 last code commit before 8c2d28ae (report only) | holds |
| R line 6 / C:482 | within is ≤ 20 % (literal) | RU:131 rp_within 20 | holds (literal matches) |
| R §2 / C:503 | 315 gauges, 19 lake outlets, 283 shared, 95 % | stopifnot C:118, 144; §10 count 19 | holds |
| R §2 / C:507-508 | no value only from an empty TC cell, or beyond triangulation / > 50 km from a vertex | C:164 (crop encloses every group), 210-211 (radius=0, radius 50000), wet_ws_sample extend; coverage = all layers non-NA, flat NA iff TIN NA | holds |
| R §4 / C:542 | star below 5, routed over its 283 | C:547; RU:130 | holds |
| R §3 / C:526 | bilinear 30″, filled from climr and CGIAR | wb_province.R:134-135 (aet_yr, p_yr) | holds |
| R §6 / C:572 | drawn from WSC gauges | source | holds |
| R §7 / C:583 | natural BC, ≥ 20 years each, zone needs 3 | RU:133-134; wet_station_select | holds |
| R §8 / C:601 | period: TIN values × zone ratio | C:444, 455 | holds |
| R §9 / C:609-612 | four terms sum at every gauge; medians need not | C:438 | holds |

### Rule (frozen) against the code applying it

| place | claim | source checked | verdict |
|---|---|---|---|
| RU:16-28 | TC 12 layers, its own lattice; isolines TIN/IDW parameters; coverage where both surfaces have a value | C; wet_ws_sample (every layer) | holds |
| RU:32-44 | 315 gauges from monthly_values held to cv; error formula; zone = cal$zone | C:113-123, 406-412 | holds |
| RU:48-64 | verdict ladder; period applies only to theirs; province ratio over every period gauge | RU:150-164; C:403, 442-456 | holds |
| RU:66-73 | period gauges: natural BC, 12 months ≥ 20 days, zone from HYDAT location | wet_station_select; C:393-401 | holds |
| RU:75-79 | LOO stability, no minimum on subsets; surface-dependent where IDW differs | RU:168-178; C:451 | holds |
| RU:83-97 | reported items, plumbing stop at 5 % | C:427-430 and report sections | holds |

### Test comments (tests/testthat/test-runoff_products_rule.R)

| place | claim | source checked | verdict |
|---|---|---|---|
| :20-22 | bal_in median 0, bal_out median 50 | arithmetic | holds |
| :29-30 | 36 points apart, both inside | −18 against +18 | holds |
| :36-48 | boundary comments (exact 20 within, 20 points not material, 30 apart) | RU:144, 156 | holds |
| :64-66 | median 22; leaving out 25 gives 20, the cut | (18 + 22) / 2 = 20 | holds |
