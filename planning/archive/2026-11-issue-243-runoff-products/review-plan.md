# Plan review for #243 (backlog move 27, #225): TerraClimate runoff and the runoff isolines

Blockers raised: 1
Owner forks: 2

The Plan agent read the plan against #225, #243 and the code it names, 2026-11-26, read-only. It ran `pg_isready` and one count on local fwapg. Each finding is listed with its verdict. The probes behind the verdicts are named where they were run. Everything folded is in `task_plan.md`.

## Blocker

- **B1. As specified, `gdal_grid`'s defaults give the wrong isoline coverage.** `linear`'s default radius of −1 fills cells outside the triangulation from the nearest vertex, so every gauge reads as fully covered. `invdistnn`'s default radius is 1 map unit, which is 1 m in BC Albers, so its surface is almost all empty.
  Verdict: **confirmed** (GDAL's `gdal_grid` documentation for both algorithms). Folded: both calls are spelled out (`radius=0`, `radius=50000:max_points=12`), with a fixed grid, through `sf::gdal_utils("grid")`, GDAL's version printed, and both surfaces sampled on one footprint.

## Gaps

- **G1. TIN artefacts that inverse distance shares.** The TIN is flat inside closed contours and between same-level lines, and the inverse-distance surface has the same bias. Folded: each gauge's flat-triangle share is reported, and crossing lines of different levels refuse the run.
- **G2. The P/AET split did not sum to the gap.** `cv_ann` is P − AET after the zone adjustment. Folded: four terms, their sum asserted at every gauge.
- **G3. `ppt_tc` and `aet_tc` are filled and resampled.** Verdict: confirmed (`scripts/wb_province.R:131–135` covers TerraClimate's empty cells with CGIAR AET and climr P). Folded: the plumbing check is split by native q coverage and given a bound. The native ppt and aet files are not on the machine, and none is fetched.
- **G4. TerraClimate's NetCDF declares no CRS.** Verdict: confirmed (`R/wet_terraclimate_aet.R:66–67`). Folded.
- **G5. Per-basin sampling repeats groups.** 313 group samples for 246 groups, measured by the reviewer on fwapg. Folded: sample each group once, as `scripts/wb_province.R` does.
- **G6. The rule's holes.** Two estimates both within ±20 % were labelled unresolved. The signed median hides scatter. Zones of 5 gauges are unstable. Boundaries and comparison sets were unstated. Folded into open decision 1: both-inside is not material, leave-one-out stability, `<=` at 20 %, the comparison sets stated. The signed-median alternative is offered as (b). **Owner fork (part of decision 1).**
- **G7. The isolines' period (1961–1990) against observed flow (1981–2010).** **Owner fork: open decision 3.** The reviewer also found `research/water_balance_method.md:730` calling the isolines independent. Verdict: confirmed by reading that line. It is corrected in Phase 3.
- **G8. TerraClimate is empty over large lakes.** Folded: dropped gauges are reported with their reasons, and the lake-outlet count is put in decision 1.
- **G9. The worktree has no data roots.** Verdict: confirmed (`ls data/` holds `basin/` and `checks/` only; an earlier worktree symlinks `data/wb` and `data/hydz`). Folded: symlinks and `WET_DATA_ROOT`.
- **G10. The rule-file pattern drifted from `scripts/departure_donors_rule.R`.** Verdict: confirmed (`scripts/departure_donors.R:40–50` reads `rule_commit` through `git show`). Folded: the rule text lives in the rule file, committed alone, and the script names `rule_commit`. The test is gated on the scripts directory.
- **G11. The report did not record its tree.** Folded: it refuses an uncommitted tree and records the commit.
- **G12. Pages that go stale.** `research/pcic_scenarios.md:38` (confirmed by reading it) and `scripts/pcic_coverage.R:259`. Folded: research is updated, and the script is left alone, since changing it stales its report.
- **G13. Small items.** The members check prints `FREE #N`. `wet_bcwt_read()` does not exist. GEOGLOWS needs an eligibility rule and the uncorrected series. The WFS template is in `scripts/wb_gauge_diversion.R`. All four folded.

## Ordering

- **O1. TerraClimate proxies are public before registration.** Folded: the rule header states what was public, and `ppt_tc − aet_tc` is not compared with observed before the rule commit.
- **O2. Registration can come before any value.** Agreed; no change.
- **O3. Installing wet first.** See A1.

## Assumptions

- **A1. Reinstalling wet is unnecessary, and harmful.** Verdict: confirmed (`scripts/wb_cv_lib.R:8` runs `devtools::load_all()`). Seven other worktrees share the library. Folded: the install step is dropped.
- **A2 and A3.** The reviewer verified the plan's claims about the code (`cal` carries `wscode`, `watershed_feature_id`, `ppt_tc`, `aet_tc`, `p_yr`, `aet_cfu`; `monthly_values.rds`'s columns and units; the score definitions), and that sampling the 24 first-level codes for all 315 gauges is feasible. No change.

## Scope

- **S1. The split's reason should be its size.** Folded: GEOGLOWS's cost is stated in PR terms.
- **S2. What decision 2's (c) means for the PR.** Folded into decision 2's text: under (c) the PR ships the isolines alone, files TerraClimate as its own issue, and #225 stays open.

## Acceptance

- **AC1. #225's "Done when".** Folded: its body edit rewrites "Done when", and the PR closes #243 and #225.
- **AC2.** Covered by S2.
- **AC3. Proofs without bounds.** Folded: the plumbing check has a 5 % bound, and the isoline spread is reported with its flat-triangle share.

## Files the plan names

planning/backlog.md
scripts/wb_cv_lib.R
scripts/wb_fit_lib.R
scripts/wb_province.R
scripts/wb_term_diagnose.R
scripts/wally_compare.R
scripts/gauge_monthly_compare.R
scripts/departure_donors.R
scripts/departure_donors_rule.R
scripts/wb_gauge_diversion.R
scripts/pcic_coverage.R
scripts/runoff_products_rule.R
scripts/runoff_products_compare.R
tests/testthat/test-departure_donors_rule.R
tests/testthat/test-runoff_products_rule.R
R/wet_terraclimate_aet.R
R/wet_ws_sample.R
R/wet_ws_fetch.R
R/wet_upstream_means.R
R/wet_bcwatertool.R
inst/vignette-data/monthly_values.rds
research/runoff_prior_art.md
research/runoff_products.md
research/README.md
research/pcic_scenarios.md
research/water_balance_method.md
CLAUDE.md
