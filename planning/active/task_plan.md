# Task: Score PCIC routed flow at the gauges; replace the vignette's fwapg comparison (#58)


On 2026-10-08, routed PCIC monthly flow (`whse_basemapping.fwa_stream_networks_discharge_monthly`, from NewGraphEnvironment/fwapg#6) was scored once, by an ad hoc query, at the shipped fit's 315 calibration gauges. At the 290 it covers:
- mean absolute error 24.4 % against the balance's 27.6 %;
- bias −0.1 % against +9.0 %;
- closer at 58 % of gauges.

The full table is in #57. No script or report produced it. The vignette's "Two estimates" table and `research/water_balance_method.md` §0 still score fwapg's annual table: 183 gauges, no rivers of order 8 and up.

## Context (plan gate, 2026-10-09)

fwapg#6 merged on 2026-10-08 (b41eb0b on fwapg's `newgraph` branch), so the issue is no longer blocked. It places PCIC's Raven-routed outlets on the FWA and writes `whse_basemapping.fwa_stream_networks_discharge_monthly`. #57's scores for it (24.4 % MAE against the balance's 27.6 % at 290 of 315 gauges) came from an ad hoc query. The local table's build commit is not recorded anywhere. It was last analysed 2026-10-08 11:47 PDT, before the side-channel vote change (5e3cd07) landed, so it probably predates the merged placement.

The vignette `vignettes/segment-discharge.Rmd`, its data in `data-raw/segment_vignette_data.R` and `data-raw/segment_vignette_map.R`, and `research/water_balance_method.md` §0 all still score fwapg's annual table: 183 gauges, no rivers of order 8 and up. Routed flow covers SALR (2,180 of 2,181 order ≥3 segments) and BULK (7,748 of 7,755).

Decided at the gate:
- **Rebuild the routed table at a pinned fwapg sha.** Use a clean worktree, not the checkout a parallel session is using.
- **Routed replaces fwapg in every comparison** in the vignette. "How it is built" keeps wet's rebuild of fwapg's annual table, because that section is about wet's own code.

## Phase 1: Comparison script, checked against #57
- [x] `scripts/pcic_routed_lib.R`, sourced by both the script and data-raw:
  - routed mean annual flow at given `linear_feature_id`s, as the mean of the 12 monthly means;
  - flow → mm over wet's accumulated upstream area;
  - a table fingerprint: rows, segments, sum of `q_m3s`.
- [x] `scripts/pcic_routed_compare.R`:
  - Sources `scripts/wb_cv_lib.R`. Takes held-out balance error from the shipped fit, with the same guards as data-raw: shipped release, `score_code_md5`, and `keep_adjust` → `cv_v`, else `raw_v`.
  - Requires `WET_FWAPG_COMMIT`. Refuses uncommitted `R/` and `scripts/`.
  - Header: date, wet commit, fwapg commit, table fingerprint, fit release, HYDAT release.
  - At covered gauges, routed against the balance: mean, median, within ±20 %, bias, headwater / nested, share where routed is closer, and by basin.
  - Uncovered gauges listed by sub-drainage (first 3 characters).
  - Caveats: PCIC is partly in-sample; 1951–2012 against 1981–2010; an unweighted mean of monthly means.
- [x] Run it against the current table, without committing the report. It should reproduce #57's numbers, which validates the definitions. Record the result in findings.md.

## Phase 2: Routed table at a pinned sha, and the report
- [ ] Before writing to fresh-db, check `pg_stat_activity` and the fwapg session's state. Nothing else may be writing `fwapg.pcic_*`, `blk_paths` or the routed table.
- [ ] `git worktree add` fwapg at the current `origin/newgraph` sha, in the scratchpad. Copy (not symlink) the cached `extras/pcic_crosswalk/data/{rivers,lakes,series,monthly}`.
- [ ] Run `./pcic_crosswalk.sh` there against fresh-db (127.0.0.1), backgrounded with a log. Confirm `qa.sql` passes and the staging tables are dropped. Record the sha, fingerprint and QA summary in findings.md.
- [ ] `WET_FWAPG_COMMIT=<sha> Rscript scripts/pcic_routed_compare.R` → commit `data/checks/pcic_routed_compare_20260717.txt` (through `wb_report()`, so it carries the release). Note in findings.md how the numbers moved from #57's.

## Phase 3: research §0
- [ ] Revise `research/water_balance_method.md` §0 in place:
  - Replace the "Across PCIC's coverage, fwapg is closer…" bullet with the routed result, its caveats and the coverage edge (10A–10C, no Liard; 08N/08M/09A).
  - Keep the #39 fwapg history only as one sentence of provenance.
  - Update the Prince George (SALR) bullet with routed numbers, after the Phase 4 rebuild (review item 13).
  - Update the Verified / Issues / Produced-by header.

## Phase 4: Tests first, then the vignette data
- [ ] `tests/testthat/test-vignette_data.R`: change the expectations to the new shape. They fail until the data is rebuilt.
  - `skill$routed_mm` and `in_routed`.
  - `segments$mad_routed_m3s` for SALR and BULK.
  - `gauges_salr$routed_mm`.
  - Provenance: `fwapg_commit` and the routed fingerprint, with the routed coverage counts in place of `fwapg_*`.
  - The map coverage outline, using the same `cov_share` rule on the routed table.
- [ ] `data-raw/segment_vignette_data.R`:
  - Reads the routed table through `pcic_routed_lib.R` and needs `WET_FWAPG_COMMIT`.
  - Asserts that its gauge summary equals the tracked report's lines, as it already does for `wb_validation`.
  - Keeps the parity/sampling path from `mad_parity.R`.
  - Fixes the stale "290 calibration stations" header.
- [ ] `data-raw/segment_vignette_map.R`: the coverage outline becomes the groups where at least half the segments are routed.
- [ ] Rebuild `inst/vignette-data/*.rds` (budget 500 KB). Tests pass.

## Phase 5: Vignette
- [ ] "Two estimates":
  - The column becomes routed PCIC (fwapg#6), with values on segments.
  - The table rows are rewritten. "Largest rivers" is now covered, "Time" is monthly 1951–2012, and "Where it has values" is the routed domain (no Liard).
  - Scatter, captions, assertions and the "which to use" guidance are recomputed.
- [ ] Province map: the coverage outline and caption.
- [ ] SALR: a routed | balance map, and a gauge table with a routed column. The prose and every `stopifnot` are re-derived from the new numbers, not adapted.
- [ ] BULK: drop "outside PCIC's coverage". It stays the balance's worked example, with a routed column in its gauge table.
- [ ] Glossary: "fwapg" now names the routed table's source (fwapg#6). "How it is built" keeps the annual-table parity, labelled as such.
- [ ] Render the vignette. Self-review the maps and figures at their published width (CLAUDE.md cartography checks 1–12).

## Phase 6: Docs and issues
- [x] CLAUDE.md Architecture: add `scripts/pcic_routed_compare.R` and its report. Update the vignette paragraph, which still says it compares "the open water balance and fwapg (PCIC)".
- [ ] Edit #57's body: point it at the research section in place of its numbers table.
- [ ] Remove the fwapg worktree.

## Review (planning/active/review-plan.md) folded in
- [x] Exact fingerprint (numeric sum of values rounded to 1e-6), checked before the parity run in data-raw, and recorded with the map outline
- [x] Report lists gauges whose segment carries < 20 % of observed flow (side channels, reservoir lakes), with a line scored without them
- [x] CLAUDE.md Data Sources: the historical routed run's coverage and table
- [ ] Keep the job's `fwa_stream_networks_discharge_monthly.csv.gz` and its sha256 from the pinned run; set `WET_FWAPG_COMMIT` from the worktree's `git rev-parse`
- [ ] Do not commit the 4929c8c report (it named a guess); it is overwritten by the pinned run

## Validation
- [ ] Vignette body prose under its 1,600-word cap
- [ ] Tests pass; `lintr::lint_package()` clean; vignette renders
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

