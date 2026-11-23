# Task: Backlog move 11: Small-basin error and the zone adjustment (#188)

**If we do it:** we know why the open balance runs about 14 % high at gauges under 100 km², how WALLY's flows compare at the gauges, and whether a trait regression or zone blending improves the adjustment, decided by a rule registered before the numbers. **If we never do:** small streams, where most fish habitat decisions are made, keep flow that is often 15 % or more too high with nothing saying why, and the zone steps stay on the annual map.

Batch 13 of `planning/backlog.md`: #176 (diagnose the small-basin error), #178 (WALLY: desk comparison, and its approach as a candidate), #44 (blend the adjustment across zone lines), #185 (consolidate `research/monthly_error.md`).

## What this pull request carries, and what it does not

The batch is more than one pull request's work, so by the rule in #188's body this move carries the first piece and files the rest as its own issue.

- **Carried here:** #185 (consolidation), #176 (the diagnosis, under a rule registered before its numbers), and #178's first two items (WALLY desk comparison and gauge filters), which the diagnosis needs anyway because its trait list comes from WALLY's open tables.
- **Filed as a new issue naming move 11 (Phase 5):** scoring the candidates that change the zone adjustment, a trait regression (#178's fourth item) and zone-line blending (#44), in one rescore under one registered rule, with the refit and republish chain. That work runs on the machine holding the full province run and changes published values; this pull request changes none.
- **This pull request edits no file `scripts/wb_score_md5.R` hashes** (`score_files_for()`), so the shipped fit stays current. The last phase asserts it.

## Decided at the gate

No gate ran in this pane: the park was dispatched by the coordinator (2026-11-23), whose plan gate reads this file and the review. The planning session decided these mechanisms, each with its reason:

- **The cut above**, by #188's body ("carries the first piece and files each other piece as its own issue naming move 11").
- **The hosted WALLY tool is not used in this move.** #188 allows it only where its written terms allow, it needs a sign-in, and nothing here depends on it. #178's third item (a handful of sites by hand) stays open in #178.
- **Script names:** `scripts/wb_small_basin.R` → `data/checks/wb_small_basin_20260717.txt`, its pure verdict functions in `scripts/wb_small_basin_rule.R`; `scripts/wally_compare.R` → `data/checks/wally_compare_20260717.txt`; WALLY findings in a new `research/wally.md`. They follow `wb_term_diagnose.R`, `wb_plateau_p.R` and `wb_gate_rule.R`.
- **#176's sampling candidate needs no number.** The province run already samples area-weighted (`scripts/wb_province.R:212`, `wet_ws_sample(st, ws, "area")`), so "centroid against area-weighted" does not apply to the shipped run. Phase 4 records that from the code.
- **Traits come from what the province run already holds at the gauges** (`upstream/<basin>.rds`: `p_yr`, `pet_yr`, `t_yr`, `elev`, `swe_max`, `snowmelt_doy_50`, zone shares) plus FWA-derived ones (area, lake, glacier cover). Slope and solar exposure need the DEM, which this machine does not hold: Phase 3 decides, from WALLY's own tables and before any of our error numbers, whether they are computed or listed as untested.
- **The data stays in the main checkout.** The worktree has no `data/wb`; the scripts read `data/` relative to the working directory through `scripts/wb_fit_lib.R`. Run them from the worktree with `data/wb`, `data/wb_term` and `data/hydz` symlinked to the main checkout's (all gitignored; confirm `git status --porcelain` stays empty), and write run logs straight into the main checkout's `data/logs/188/`.
- **Check B's thresholds (the owner, 2026-11-23): as drafted** — ±5 % median, ≥3.0-point MAE gain at small gauges, ≤1.0-point loss at the rest, bootstrap "undecided" band. Written into #188's body under "## Decisions".
- No comment on #188, #176, #178, #44 or #185 asks for anything (read 2026-11-23: only claim notices on #188).

## Open decisions

None open. Decision 1 (check B's thresholds) was answered by the owner on 2026-11-23, above.

Settled by the Plan review as mechanism, no longer asked: **which candidates the follow-up scores.** Zone-line blending (#44) enters whatever the diagnosis finds; the trait regression enters only if check B passes. The follow-up has its own gate, where its ship rule is settled.

## Phase 0: Data setup (added by the Plan review)

- [x] In the worktree, symlink `data/wb`, `data/wb_term`, `data/hydz` and `data/wally` to the main checkout's (create `data/wally/raw/` and `data/logs/188/` there first; neither exists). Confirm `git status --porcelain` is empty after.
- [x] Record `date -u` and the main checkout's fit key (`768876badf`) in `progress.md`.

## Phase 1: Consolidate `research/monthly_error.md` (#185)

Prose only; no number changes.

- [x] Record the file's prose word count and its numbers before the edit: `grep -oE '[+−-]?[0-9]+(\.[0-9]+)?' research/monthly_error.md | sort | uniq -c` to a temp file.
- [x] Fold the three issue-headed sections ("#6: ...", "#67: ...", "#162: ...") into statements by subject: by region and season; by basin size; routed PCIC's seasonal shape; the Fraser benchmark. One statement per finding, each pointing at `data/checks/gauge_monthly_compare_20260717.txt`. Keep "The answer" first. Keep the header line's provenance; add #185 to its issues. Issue numbers move from headings to the end of the statement they belong to.
- [x] Guard, body only (the header line is exempt: it gains "#185"): the multiset of numbers after the edit is a subset of the one before, each number dropped is listed in the commit message with why, and `grep -c '^## #[0-9]' research/monthly_error.md` is 0. The guard shows no number was typed, not that each still sits in its claim: read the diff for that. Report `wc -w` before and after (1,886 before; #185's 1,685 is soul's `research_check.sh` prose count).
- [x] Update the file's row in `research/README.md` if its description names the old sections.

## Phase 2: WALLY desk comparison (#178, items 1 and 2)

WALLY is a yardstick, never an input (CLAUDE.md, "Own estimates first"). Read `bcgov/WALLY`'s `modelling/` folder at one pinned commit (record the sha; Apache-2.0).

- [x] Fetch once into `data/wally/raw/` (gitignored), each file's md5 printed in the report: the per-station training tables (`data/3_merged/`, `data/4_training/`) and whatever the folder stores of its k-fold scores. Log each fetch to the main checkout's `data/logs/188/`.
- [x] From WALLY's tables alone, list its predictors and which mattered per zone (its coefficients or importances). This list is Phase 3's input. Write it to the report before any of our error numbers exist.
- [x] Station overlap: WALLY's training stations against our 315 calibration gauges, per hydrologic zone, so a WALLY score at a gauge it trained on is marked in-sample.
- [x] Gauge filters: WALLY's selection (licensed use under 200 % of mean annual flow; drainage area within 5–20 % of HYDAT's) against `wet_station_select()`'s natural-flow set (`R/wet_station_select.R`), as text, with the counts each keeps where its tables give them.
- [x] WALLY's held-out mean-annual-flow error by zone beside the held-out balance and routed PCIC by zone. Prefer a score table stored in the repo; where the scores exist only in `WALLY_Modeling_FSL_V0.5.pdf`, transcribe them into `scripts/wally_zone_scores.csv` with a page number per row, read from the PDF itself and checked a second time. Compute ours in WALLY's own metric from the stored held-out values (`cv_aet-cfu.rds`: `obs`, `cv_ann`, `zone`), and say plainly where the two metrics or gauge sets are not comparable.
- [x] `scripts/wally_compare.R` writes `data/checks/wally_compare_20260717.txt` through `wb_report()`; two runs give byte-identical reports.
- [x] `research/wally.md` (new, with the provenance header `planning.md` asks for, and a row in `research/README.md`): what WALLY is, the comparison, what is in-sample, and that the hosted tool was not used. Nothing about Fathom Scientific beyond what #178's body states from public pages.

## Phase 3: Register the diagnosis rule (#176), before any error-against-trait number

Commit the header of `scripts/wb_small_basin.R` holding the rule below, and `scripts/wb_small_basin_rule.R` with its verdict functions and tests, **in a commit of their own before the script computes any check**. Later commits never change that text; amendments made after numbers are listed apart in the header with the as-registered verdict beside (as `scripts/gauge_monthly_compare.R` does). Ask Open decision 1 first.

Definitions, all from `source("scripts/wb_cv_lib.R")` (`cal`, its `fold`, `zone`, `area_class`) and the fit's `cv_aet-cfu.rds` (`station_number`, `raw`, `cv_ann`, `obs`, `zone`, `lake`):

- gauges: the shipped fit's calibration gauges; **small** = accumulated area under 100 km² (84 expected; the script prints the count and stops if `cv_aet-cfu.rds` and `cal` disagree on station order or `obs`);
- error = 100 · (modelled − observed) / observed, annual; **raw** is P − AET, **adjusted** is the held-out balance as shipped (`cv_ann`);
- a class with fewer than 5 gauges is printed, marked, and not read.

The rule, four checks and one attribution:

**The Plan review changed A, B and C** (review-plan.md, findings 1 to 4). The header discloses what was known before registration, as `scripts/wb_gate_rule.R:17-20` does: at the 84 small gauges raw is +1.9 % and adjusted +14.3 %; at the 231 larger, raw −15.1 % and adjusted −6.7 % (`data/checks/wb_validation_20260717.txt:63,106`; the larger pair read by the review from `cv_aet-cfu.rds`, to be reprinted by the script).

- **A. Where the bias enters: known, so described, not judged.** The size-blind adjustment lifts both classes; raw is already about 17 points higher at small gauges than at larger ones, and adjusted about 21. A prints the small-minus-larger contrast, raw and adjusted, then both by dominant hydrologic zone, elevation tercile and aridity tercile (`pet_yr / p_yr`; terciles cut over all calibration gauges). Registered reading, the only part not yet seen: the contrast is **general** if adjusted small-minus-larger is +10 points or more in at least two thirds of the readable classes of each split, otherwise **concentrated**, naming the classes.
- **B. Do catchment traits explain it.** One model, no search: ordinary least squares of `log(cv_ann / obs)` on the traits, fitted on all calibration gauges (a registered deviation from #176, which says "at the small gauges": the candidate adjustment would be fitted on all) under the fit's blocked folds (`cal$fold`), each gauge predicted from the folds that exclude it, traits standardized inside each training fold. Traits, fixed here: log10 `area_km2`, `p_yr`, `pet_yr / p_yr`, `elev`, `t_yr`, `swe_max / p_yr`, glacier cover fraction, and slope and solar exposure under the task below. (`lake` is dropped: it is a lake-outlet label true at 1 of 84 small gauges.) Corrected value: `cv_ann / exp(predicted)`, then its percent error. Verdict **traits explain the small-basin error** only if all three hold: the small gauges' median corrected error is within ±5 %; their mean absolute percent error (`mae()`, `scripts/wb_cv_lib.R:149`, the statistic the gate's margin is on) falls by at least 3.0 points; the same at gauges of 100 km² and up worsens by no more than 1.0 point. A fold-blocked bootstrap (1,000 draws, seed in the header) gives a 90 % interval on the first; if it straddles ±5 %, the verdict is **undecided**. Beside the full model the report prints an **area-only** model under the same tests: if area alone passes, the verdict says so, because the class is defined by area. Registered caveat: the training gauges' `cv_ann` came from fits that saw the held-out gauge's `obs` (second-order leakage); it is stated, not removed. A per-trait table (Spearman at the small gauges, standardized coefficient) decides nothing.
- **C. Which term, against PCIC, where PCIC's grid reaches.** `basins` in `data/wb_term/diagnose_20260717.rds` is 192 PCIC-covered basins (Fraser, Peace, Columbia), 48 under 100 km², none in zones 01, 28 or 29; rows are basins, and one merges two gauges, so count basins and do not join on `station_number` alone. C first prints A's raw and adjusted medians on its own 48, and the attribution names that population. The rule is #45's (`planning/archive/2026-10-issue-45-dry-interior-term/findings.md`, steps 1 to 5; step 6, stability, is dropped and the header says so), which diagnoses overshoot only: copy `verdict()` verbatim from `scripts/wb_term_diagnose.R:226-269` (it cannot be sourced), assert the copy reproduces the stored `zones$verdict` on all 21 rows, then apply it to the small class with the ECCC corroboration over that class's dominant zones (the pooled stratum's zone vector, line 282), keeping #45's "4 distinct basins" minimum. Registered caveat: a PCIC cell is about 30 km², so a small basin spans a few cells; step 3 (reference usable) is the guard and its numbers are printed.
- **D. Sampling.** Recorded from the code, no number (see "Decided at the gate").
- **Attribution** (ours, theirs or unresolved): **ours, the adjustment's lift at small gauges**, already known, stated with A's reading (general or concentrated); for the raw small-minus-larger contrast, **ours, P** or **ours, AET** on C's population if C names that term with its corroboration, otherwise **unresolved** there. B's verdict is reported beside it and is the trait regression's entry to the follow-up issue. `sb_verdict_enter()` below becomes `sb_reading_contrast()`. Glacier cover, if built, is the area share of the gauge's upstream fundamental watersheds covered by FWA glacier polygons, the method stated in the header.

Tasks:

- [x] Check which traits can be built before registering: `p_yr`, `pet_yr`, `t_yr`, `elev`, `swe_max` are in `upstream/<basin>.rds` and reach `cal` through `with_predictors()` (confirm each column is in `cal`; add nothing to `scripts/wb_cv_lib.R`, which is hashed: join extra columns inside the new script). Glacier cover: confirm the FWA glacier polygons exist in the local fwapg (`whse_basemapping.fwa_glaciers_poly`), connecting with `connect_timeout = 10` and the `WET_PG*` variables; if absent, list glacier cover as untested with that reason.
- [x] Slope and solar exposure: if Phase 2's list ranks either among WALLY's three strongest predictors in most of its zones, they matter enough to compute, which needs the DEM on the machine with the full runs; if that is more than a side run of an hour, list them as untested in the header and carry them into the follow-up issue's body. Otherwise list them as untested because WALLY's tables do not rank them. Decide from WALLY's tables only.
- [x] Write the header (rule as above, with the trait list as it stands after the two tasks), `scripts/wb_small_basin_rule.R` (pure functions: `sb_verdict_enter()`, `sb_verdict_traits()`, `sb_attribution()`, numbers in, verdict string out) and `tests/testthat/test-wb_small_basin_rule.R`, following how `scripts/wb_gate_rule.R` is tested (find its test with `grep -rl wb_gate_rule tests/`; it must skip, not fail, where the script file is absent under `R CMD check`). Tests cover each verdict and each boundary value (exactly +10, ±5, 3.0, 1.0), and `NA` and too-few inputs.
- [ ] Commit this alone: "Register the small-basin diagnosis rule (#176)". Record the sha in `progress.md`; the header names it in the next commit.

## Phase 4: Run the diagnosis, report, and revise the research statement

- [ ] Write the body of `scripts/wb_small_basin.R`: checks A to D and the attribution, report through `wb_report("wb_small_basin", release)`. It stops unless it reproduces the tracked state first, to one decimal: raw +1.9 and adjusted +14.3 at 84 small gauges (`data/checks/wb_validation_20260717.txt:63,106`), and `cv$code_md5` equal to `score_code_md5`. If it does not, stop and find which file differs before reading any check.
- [ ] Prove check B is held out: a run with the folds replaced by one in-sample fit must print different predictions and a lower overall mean absolute log residual (not necessarily a better small-gauge median). Report both in the log, keep the held-out one. Then run twice from a clean tree: byte-identical reports. Logs to the main checkout's `data/logs/188/`.
- [ ] Commit the script before the run whose report is committed, and edit nothing it reads while it runs.
- [ ] Revise `research/monthly_error.md` in place: the basin-size statement gains the attribution and each check's verdict in one or two sentences; "The answer" gains one bullet; the header line gains #176, the script and its report, and today's verified date. No new issue-headed section.
- [ ] `research/water_balance_method.md`: where it lists small basins or blending as open (§0, §7 item 9), revise the sentence to the finding and point at `research/monthly_error.md`. Grep `research/` and `CLAUDE.md` for sentences the finding makes stale.

## Phase 5: Follow-up issue, issue bodies, documentation

- [ ] File the follow-up in NewGraphEnvironment/wet, body below, edited to the diagnosis's verdicts. Leave it out of `planning/backlog.md`.

  > **Title:** Zone adjustment candidates: score zone-line blending and a trait regression under one registered rule (from move 11)
  >
  > **If we do it:** the adjustment either improves at small basins and across zone lines or we know, by a rule set beforehand, that it does not. **If we never do:** the diagnosis from move 11 (#188) has no consequence for the published flows.
  >
  > From move 11 (#188), which carried the diagnosis (#176) and left the candidates here. Carries #44 and #178's fourth item.
  >
  > **What is known:** `<the attribution and check B's verdict, one line each, with the report path>`.
  >
  > **Candidates:** zone-line blending (#44: soft zone shares over a band of w km; `wet_wb_adjust()` already takes fractional shares); `<the trait regression, only if check B passed: the registered traits, per-zone or pooled>`; `<slope and solar exposure, if listed untested for want of the DEM>`.
  >
  > **Decided at this issue's gate:** the band widths and trait sets that enter, fixed before scoring; the ship rule, drafted as: a candidate ships if, under blocked CV on the shipped fit's folds, it does not worsen headwater MAE by more than 1.0 point, and it does what it is for (blending: the measured steps along zone lines shrink by a share set at the gate; trait regression: the small gauges' median error within ±5 % held out).
  >
  > **Phases:** measure the steps along each zone line and against the province's runoff isolines (#44, step 1); register the rule in the script's header; code the candidates behind arguments that default to the shipped behaviour; rescore every AET variant, `wb_aet_compare.R`, `wb_validate.R`, `wb_fit_accept.R`; if one ships, the output, segment, daily and publish chain and the three descriptions `discharge_publish.R` guards.
  >
  > **Touches:** `R/wet_wb_fit.R`, `R/wet_wb_adjust.R`, `scripts/wb_validate.R`, `scripts/wb_province.R` (zone shares), the refit and republish chain. Runs where the full province run is.

- [ ] Plan review, finding 9, applied when filing: the follow-up body carries every trait this move listed as untested, whatever the reason; its phases include re-rendering the runoff map (#44, step 4); and it says the trait candidate's ±5 % test is check B's first test, so that number is known before the follow-up's rule is registered. `research/wally.md`'s header is modelled on `research/monthly_error.md:3` (`planning.md` is not in this repo).
- [ ] Edit issue bodies (edit, never a correcting comment): #176 ticks its to-do items with the verdict and report path, naming the traits tested and those not; #178 ticks items 1 and 2, keeps item 3 open, and names the follow-up for item 4; #44 names the follow-up as where it is scored; #188 says what the move carried and names the follow-up. Resolve every issue number the branch introduces with `gh issue view` before the pull request.
- [ ] `CLAUDE.md`, Architecture: one entry each for `scripts/wb_small_basin.R` and `scripts/wally_compare.R`, in the style of the `wb_term_diagnose.R` entry (rule registered where, report path, what it needs). `research/README.md` rows current.
- [ ] Assert the fit is not staled: `git diff --stat origin/main...HEAD -- scripts/wb_score_md5.R scripts/wb_cv_lib.R scripts/wb_gate_rule.R scripts/wb_validate.R scripts/wb_aet_compare.R R/wet_wb_fit.R R/wet_wb_adjust.R R/wet_share_fit.R R/wet_share_predict.R R/wet_donor_mean.R R/wet_flow_validate.R R/wet_cv_folds.R R/wet_wb_raw.R R/wet_mm_to_m3s.R` prints nothing.
- [ ] Pull request body: `Fixes #176`, `Fixes #185`; `Relates to #178, #44, #188`.

## Owed at the end (reported, done after merge)

- [ ] Move the worktree's run logs, if any landed under its own `data/logs/`, into the main checkout's `data/logs/188/` before the worktree is removed.

## Validation

- [ ] Tests pass (`devtools::test()`; the new rule tests run with `NOT_CRAN=true`)
- [ ] `lintr::lint_package()` adds no lint
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion; the archive README carries `## Measurement` and `## Evidence` (log prefix `data/logs/188/`)

How each change is proved:

- Phase 1: the number multiset guard; word counts before and after.
- Phase 2: md5s of every fetched file in the report; byte-identical reruns; each transcribed PDF number carries its page.
- Phase 3: the rule's commit precedes every commit that computes a check (`git log --oneline -- scripts/wb_small_basin.R`); boundary tests on the verdict functions.
- Phase 4: the script reproduces the tracked medians before any check; the in-sample mutation moves check B; byte-identical reruns.
- Phase 5: the score-files diff is empty; every issue number resolves to the issue meant.
