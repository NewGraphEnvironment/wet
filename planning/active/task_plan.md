# Task: Backlog move 27: The runoff products no report covers yet (#243)

**If we do it:** every other group's runoff product wet could be checked against is compared with the balance and HYDAT at the same gauges, each material disagreement attributed as ours, theirs or unresolved. **If we never do:** those products are used unchecked, and their errors, or ours, stay invisible.

Batch 31 carries #225: GEOGLOWS v2, TerraClimate runoff, the 1961–1990 runoff isolines, and the BC Water Tool's modelled estimates (waiting on the Province's release).

## Decided at the gate

No plan gate in this pane: a coordinator-dispatched `park review`, parked for the coordinator's plan gate. The Plan review ran before the baseline (`planning/active/review-plan.md`), and its corrections are folded in below. Mechanism decisions made in the plan, each with its reason:

- **This PR carries TerraClimate runoff and the runoff isolines. GEOGLOWS v2 and the BC Water Tool are filed as their own issues naming move 27**, left out of `planning/backlog.md`, as the move's rule says for a batch bigger than one PR.
  - GEOGLOWS is its own PR's worth of work: a public-S3 zarr read of the retrospective, a TDX-Hydro geoparquet read over the processing units that cover BC, a gauge-to-reach crosswalk with its own acceptance rule and tests, and CC BY attribution.
  - TerraClimate and the isolines are both surfaces, so one path serves both, on the balance's own topology.
  - The BC Water Tool's estimates are not released.
  - The PR closes #243 and #225. #225's "Done when" is rewritten to name the two products this PR scores and the two new issues.
- **Names:**
  - rule: `scripts/runoff_products_rule.R`
  - script: `scripts/runoff_products_compare.R`
  - test: `tests/testthat/test-runoff_products_rule.R`
  - report: `data/checks/runoff_products_compare_<release>.txt`
  - findings and the disagreement log: one topic file, `research/runoff_products.md`, whose log section later products append to
  - caches: `<WET_DATA_ROOT>/runoff_products/`
  - logs: `<WET_DATA_ROOT>/logs/243/`
- **The rule follows `scripts/departure_donors_rule.R`'s pattern.**
  - The rule file holds the rule text in its header, the constants and `rp_verdict()`, and is committed alone, first.
  - The compare script, written after that commit, names `rule_commit` and refuses a rule file whose md5 differs from `git show <rule_commit>:<file>`.
  - The rule header states what was already public when it was registered:
    - TerraClimate P at the gauges, in `data/checks/wb_term_diagnose_20260717.txt` and `research/water_balance_method.md`;
    - the province run's `ppt_tc` and `aet_tc` in `cal`;
    - the isoline level counts read while planning.
- **Scores reuse the gauge reports' definitions** (`scripts/gauge_monthly_compare.R:111, 270–274`).
  - Error is modelled over observed, as %. "Within" means |error| ≤ 20 %.
  - Shape is the share NSE (twelve monthly shares, so volume does not enter), with monthly NSE beside it.
  - Observed, the held-out balance and routed PCIC come from `inst/vignette-data/monthly_values.rds`, held to `cv_aet-cfu.rds` as `scripts/wally_compare.R:102–112` holds them. Months 1–12 there are mm per month, as TerraClimate's monthly layers are.
  - At each product's scored gauges, the balance's median is taken over those gauges, and routed's over those gauges that are also among routed's 283 shared gauges.
- **The isolines become two surfaces through `sf::gdal_utils("grid", ...)`**, so the GDAL used is sf's, and the report prints its version.
  - The grid is fixed: BC Albers, 1 km cells, the origin and extent written in the script (`-txe/-tye/-tr`).
  - TIN: `-a linear:radius=0:nodata=-9999`. A radius of 0 leaves cells outside the triangulation empty. GDAL's default, −1, fills them from the nearest vertex.
  - Inverse distance: `-a invdistnn:power=2:radius=50000:max_points=12:nodata=-9999`. GDAL's default radius is 1 map unit, which in BC Albers is 1 m.
  - The lines are densified to 1 km before gridding.
  - Both surfaces are sampled in one `wet_ws_sample()` call. It counts a cell only where every layer has a value (`R/wet_ws_sample.R:13–18`), so both have one footprint.
  - The script refuses lines of different levels that cross each other.
  - For each gauge the report gives its share of basin area on flat triangles (all three vertices at one level), because the TIN and inverse distance share that bias and their spread cannot show it.
- **TerraClimate is read at its own 1/24° lattice**, with no resampling: the 12 monthly layers of the 1981–2010 climatology.
  - Set `crs(r) <- "EPSG:4326"`, because the file declares none (`R/wet_terraclimate_aet.R:66–67`).
  - Crop to BC plus a margin.
  - Refuse a file whose variable is not `q` or that does not hold 12 layers.
  - Its coverage at a gauge, measured on this native sample, is how much of the basin has a TerraClimate cell. Sea, some large lakes and coastal ground are empty.
- **The sampling follows `scripts/wb_province.R`, not per basin.**
  - Each watershed group is sampled once and cached per group, keyed on the inputs' md5s and the code files read: q's 13 layers as one multi-layer sample, the two isoline surfaces as another.
  - Upstream means are then accumulated per first-level code that `subltree(cal$wscode, 0, 1)` names, with `wet_ws_fetch()`, `wet_upstream_irregular()` and `wet_upstream_means()`.
  - Done per basin, as in `scripts/wb_term_diagnose.R`, 54 groups that span more than one code would be sampled again (313 group samples for 246 groups, measured by the review).
- **q's annual sum against `ppt_tc − aet_tc` is a plumbing check with a bound.**
  - Those columns are bilinear on the 30″ grid, filled from CGIAR and climr where TerraClimate is empty (`scripts/wb_province.R:131–135`).
  - So the check is reported separately on gauges whose native q coverage is 1 and on the rest.
  - On coverage-1 gauges, a median absolute difference above 5 % refuses the run. That is a sampling fault, not a finding.
- **The evidence for a TerraClimate disagreement adds up exactly.** At each gauge, `q − cv_ann` is split into four terms:
  - precipitation, `ppt_tc − p_yr`
  - AET, `−(aet_tc − aet_cfu)`
  - TerraClimate's storage and fill, `q − (ppt_tc − aet_tc)`
  - the zone adjustment, `−(cv_ann − (p_yr − aet_cfu))`
  The script asserts that the four sum to the gap at every gauge. `aet_tc` is read from `cal` directly: it is not in `scripts/wb_term_diagnose.R`'s `cols_g`.
- **wet is not reinstalled.**
  - The installed copy is 0.4.44 against the source's 0.6.0, but `scripts/wb_cv_lib.R:8` runs `devtools::load_all()`, so `wet:::` resolves to the source tree. The script sources it first.
  - `R CMD INSTALL` would swap the shared library under the seven other open worktrees.
  - Do not copy `scripts/wally_compare.R:122`'s `wet:::` call made before any `load_all()`.
- **Runs on m1 from this worktree.**
  - `data/wb` and `data/hydz` are symlinked to the main checkout, as `wet-188` does.
  - `WET_DATA_ROOT` names the main checkout's `data/` for the caches and logs, as `scripts/departure_donors.R:74` reads it, so `git worktree remove` loses nothing.
  - fwapg answers on 127.0.0.1.
  - The script refuses an uncommitted `R/`, `scripts/` or `data/checks/`, and records the commit, as `scripts/gauge_monthly_compare.R:105–108` does.
- **Pages that say no report scores these yet are updated in research only.** `research/pcic_scenarios.md:38` is updated, and `research/water_balance_method.md:730`'s "independent" for the isolines is corrected (they were drawn from WSC gauges). `scripts/pcic_coverage.R:259` says the same, but it is left alone, because changing it stales its tracked report; the findings note it.

## Owner's decisions (2026-11-27, at the resume)

1. **The registered rule: the signed median at 20 points.**
   - The gauge set is the shipped fit's 315 calibration gauges. A product is scored where it covers at least 95 % of the gauge's basin. The report lists the gauges dropped by coverage, by zone and with the reason: sea, large lake (18 calibration gauges sit at lake outlets), outside the isoline hull, outside BC.
   - A hydrologic zone with at least 5 scored gauges is a material disagreement when the product's median annual error and the held-out balance's differ by more than 20 percentage points (exactly 20 is not material).
   - The verdict is **theirs** when the product's median error is outside ±20 % and the balance's inside, **ours** when the reverse, and **unresolved** when both are outside. When both are inside ±20 %, the zone is not material, however far apart the two are.
   - Each verdict is printed with its leave-one-gauge-out stability, as #45 did (`scripts/wb_term_diagnose.R:271–278`). A verdict that flips when one gauge is dropped is marked unstable.
   - The province-wide medians get the same test.
2. **TerraClimate: one logged fetch** of `TerraClimate_19812010_q.nc` from `/thredds/fileServer/`, its md5 in the report, as the AET and precipitation climatologies were fetched. The robots fact is recorded in `research/runoff_products.md`.
3. **The isolines' period: the period ratio test.** At the long-record natural HYDAT gauges with complete years in both 1961–1990 and 1981–2010, each zone's ratio of 1981–2010 runoff to 1961–1990 runoff is measured (`wb_hydat()`). Where that ratio alone moves the isoline's median error back inside ±20 %, an isoline "theirs" becomes "unresolved (period)".

## Phase 1: Split, then register before any number

- [x] Before building, run `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 243 243-backlog-move-27-the-runoff-products-no-r --batch 31` (T from `soul_published_tree`). If it exits non-zero, or prints any line not of the form `FREE #N`, build nothing of this batch: write the line under `## Open decisions` and stop.
- [x] Before any phase that needs it, ask the owner what `## Open decisions` lists that is still unanswered. This phase's rule needs decision 1, and its TerraClimate step needs decision 2.
- [x] File GEOGLOWS v2 as its own issue naming move 27 (#244). Leave it out of `planning/backlog.md`. The issue carries:
  - the TDX-Hydro reach crosswalk to the FWA, with its eligibility rule (the reach's drainage area within 10 % of the gauge's FWA area), the counterpart of this PR's 95 % coverage;
  - the uncorrected retrospective's 1981–2010 flow at the calibration gauges, so no gauge-corrected series is scored as independent;
  - scoring under this PR's rule, with the results appended to its disagreement log.
- [x] File the BC Water Tool's modelled estimates as their own issue naming move 27 (#245). Leave it out of `planning/backlog.md`. The issue carries #225's text:
  - a reader still to be written (`wet_bcwt_read()` does not exist; `R/wet_bcwatertool.R` reads the Tool's gauge records), on `fund_rollup_report`;
  - the release schema in `crate`, and the snapshot pinned;
  - its accuracy numbers, which are in-sample;
  - whether its ids are FWA or Foundry `watershed_feature_id`;
  - the questions for the Province, which go through the owner;
  - the metadata inconsistencies already found.
- [x] Edit #225's body to say:
  - what this PR carries;
  - the two issues the rest moved to;
  - a "Done when" rewritten to name TerraClimate runoff and the isolines.
- [x] Symlink `data/wb` and `data/hydz` to the main checkout. Export `WET_DATA_ROOT=/Users/airvine/Projects/repo/wet/data`.
- [x] Write `scripts/runoff_products_rule.R` from the owner's answers to decisions 1 and 3. It holds:
  - the rule text, including what was public at registration;
  - the constants: coverage 0.95, zone minimum 5, within ±20 % (`<=`), the material cut;
  - `rp_verdict()`, with its leave-one-out stability.
  Commit it alone, before any product value is read. Do not compute `ppt_tc − aet_tc` against observed before this commit.
- [x] Write `tests/testthat/test-runoff_products_rule.R`. Gate it with `skip_if_not(dir.exists(scripts))`, as `tests/testthat/test-departure_donors_rule.R:4–9` does.
  - Run `rp_verdict()` on made-up zones that reach each branch: theirs, ours, unresolved, not material (both inside ±20 %), too few gauges, unstable, and the boundaries exactly at 20 % and exactly at the cut.
  - Plant a wrong sign in the verdict, and watch the test fail.

## Phase 2: The two products at the gauges

- [x] Write `scripts/runoff_products_compare.R`'s inputs. Source `scripts/wb_cv_lib.R` first, then:
  - Hold the rule file to `rule_commit`.
  - Refuse an uncommitted tree.
  - Hold `monthly_values.rds`'s gauge table to `cv_aet-cfu.rds`. Shared = 283.
- [x] TerraClimate: fetch `TerraClimate_19812010_q.nc` once, as decision 2 says, into `<WET_DATA_ROOT>/runoff_products/raw/`.
  - Log each request to `<WET_DATA_ROOT>/logs/243/runoff_products_fetch.tsv`. Put the file's md5 in the report.
  - Read it as the Decided-at-the-gate note on TerraClimate says.
- [x] Isolines: read `WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE` (OGL-BC) from the BC WFS once.
  - Use `resultType=hits`, then hold the read to the server's `numberMatched` (66 lines, levels 50 to 4,000 mm, when probed), as in `scripts/wb_gauge_diversion.R:41–76`.
  - Save the raw read with its md5.
  - Refuse lines of different levels that cross.
  - Build the TIN and inverse-distance surfaces exactly as specified under Decided at the gate.
- [x] Sample each watershed group once, cached. Accumulate per first-level code holding a calibration gauge. Keep each layer set's coverage and each gauge's flat-triangle share.
- [x] Run the plumbing check: q's annual sum against `ppt_tc − aet_tc`, on coverage-1 gauges and on the rest, under the 5 % bound.

## Phase 3: Score, attribute, write up

- [x] Write the report `data/checks/runoff_products_compare_20260717.txt`. It holds:
  - inputs, md5s, the commit, sf's GDAL version, and the gauges dropped by coverage with their reasons;
  - for each product, its annual error % (median, middle half) and its share within ±20 %, province-wide and by hydrologic zone, beside the held-out balance and routed PCIC at the same gauges. Zones with fewer than 5 gauges are printed and marked, not read;
  - TerraClimate's monthly NSE and share NSE, beside the balance's and routed PCIC's;
  - the isoline spread (TIN against inverse distance) and the flat-triangle share;
  - each zone's verdict, with its stability.
- [x] For each material disagreement, add the evidence:
  - TerraClimate: the four-term split of `q − cv_ann`, its sum asserted;
  - the isolines: the period ratio under decision 3, and that they were drawn from WSC gauges;
  - independence: TerraClimate is gauge-free.
- [x] Run twice; the two reports must be byte-identical.
- [x] Write up:
  - `research/runoff_products.md`: the answer first, then each product, the TerraClimate robots fact, and the disagreement log (one row per material disagreement: product, where, size, ours/theirs/unresolved, evidence, report section);
  - a row in `research/README.md`;
  - `research/runoff_prior_art.md`'s rows 5 and 6 point to it;
  - `research/pcic_scenarios.md:38` and `research/water_balance_method.md:730` corrected;
  - a script bullet in `CLAUDE.md`.
- [x] Before `git worktree remove`, move `data/logs/243/` into the main checkout if any log landed in the worktree.

## Validation

- [x] Tests pass (4,038 passed, 0 failed, 5 skipped, 2026-11-28)
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- The rule commit precedes the first value. The script refuses a rule file that differs from `rule_commit`.
- The verdict test fails against a planted wrong sign.
- TerraClimate's sampling is held to `ppt_tc − aet_tc` within 5 % on fully covered gauges.
- The four-term split sums to the gap at every gauge.
- The isoline surfaces carry their spread and their flat-triangle share. Crossing lines refuse the run.
- The gauge table equals `monthly_values.rds`'s.
- The report names its commit, and two runs give byte-identical reports.
