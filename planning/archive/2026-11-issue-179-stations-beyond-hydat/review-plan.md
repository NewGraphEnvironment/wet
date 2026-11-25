# Plan review: #179, backlog move 8 (stations beyond HYDAT), 2026-11-22

Blockers raised: 2
Owner forks: 3

A Plan agent read the draft plan against #179, #142, #144 and the code they name (tree eaa12d9). Each finding was probed before it was folded in or declined.

## Blockers

1. **Choosing a source by the shape of the id fails.** Confirmed: the survey's Tool `nid`s include `HRB3142`, `ALU-water`, `ogc_1002`, `UC 5`, `manson`, and provincial-shaped `07FA0003`/`07FC0003` that are not in the provincial files (report "Every station read"); Tool CSVs are named by API id (Sharp Creek `nid` 2601 is `13915.csv`). Folded: the source is looked up in a per-snapshot registry; only HYDAT's own pattern stays a shortcut.
2. **Decision 4(a) contradicts the chain.** Confirmed: `wet_daily_after()` (R/wet_station_daily.R:98–103) keeps only a later source's days after the earlier one's last day. Folded: decision 4 rewritten, recommending provincial only, with a before-first-day rule as option (b); an owner fork, moved to #144's plan under the recommended scope.

## Gaps

3. Provisional and real-time run for every station (R/wet_station_daily.R:68–86). Confirmed; folded: limited to HYDAT-form ids.
4. No snapshot pinned; the manifest must be tracked; `wet_station_daily()` needs `snapshot =`; hard-coded archive names. Folded: pinned 20261028, seeded from the raw copy, tracked manifest, `snapshot =`, a new snapshot lists the directory.
5. Derived parquet would bake in decisions 2 and 3. Folded: values stored before status and bound, keyed by snapshot and reader version, landed by partial file and rename.
6. `"unchecked"` invisible to `frac_provisional`. Confirmed (R/wet_window_stats.R:168; `wet_temp_gsdd()` line 100). Folded: counts every non-approved status.
7. `hydat_site` needs HYDAT or a tracked crosswalk; an example cannot read `tests/testthat/fixtures/`. Folded: tracked crosswalk from the data script; example fixture under `inst/extdata/`.
8. Tool `Units` unchecked; negative values; duckdb version; probe's fate. Folded: negatives dropped, duckdb floor, probe kept; `Units` moved to #144 (Tool CSVs have a `Units` column, confirmed).

## Assumptions

9. Provincial days are UTC (`Date/Time(UTC)`, confirmed), HYDAT's local. Folded as a builder decision: fixed-offset local standard time; the count change handled by Phase 4's tier (ii).
10. Plausibility rule details (zero medians, single extreme station, register expected catches before measuring, all stations with natural beside, name the script). Folded into decision 3 and Phase 2.

## Open decisions

11. Unknown regulation cannot be a donor under `wet_station_select()`. Confirmed (R/wet_station_select.R:27–28). New owner fork: decision 7.
12. The Tool's "BC ENV" listings with discharge (08MH0061, H08KC1015). Moved to #144 under decision 1(a).
13. Decisions 7 (credit) and 8 (name) and the cache layout are mechanism. Agreed: moved to "Decided by the builder".

## Scope

14. Split: #142 first, #144 after. Agreed; owner fork, now decision 1's recommendation.

## Acceptance

15. Count check against 110/35 cannot fail. Agreed: two tiers, exact reproduction under the survey's rules, then a station-by-rule table under the shipped ones.
16. A host name in committed planning. Confirmed; removed.

## Files the plan names

```
planning/active/task_plan.md
planning/active/findings.md
planning/active/progress.md
planning/backlog.md
R/wet_station_daily.R
R/wet_temp_daily.R
R/wet_temp_gsdd.R
R/wet_window_stats.R
R/wet_hydat.R
R/wet_pcic_years.R
R/wet_station_select.R
R/wet_bcenv.R
R/wet_bcenv_daily.R
R/wet_station_list.R
scripts/station_sources_probe.R
scripts/station_sources_bound.R
scripts/station_sources_harvest.R
scripts/wb_gauge_diversion.R
scripts/station_departure.R
scripts/wb_shape_daily.R
scripts/departure_pcic.R
scripts/departure_site.R
data-raw/station_vignette_data.R
data-raw/station_sources_snapshot.R
research/station_sources.md
data/checks/station_sources_20260717.txt
data/checks/station_sources_bound_20260717.txt
data/checks/station_sources_harvest_20261028.txt
inst/extdata/station_sources/bcenv_20261028.csv
inst/extdata/station_sources/bcenv_20261028_hydat.csv
tests/testthat/test-wet_station_daily.R
tests/testthat/test-wet_station_list.R
tests/testthat/fixtures/
DESCRIPTION
_pkgdown.yml
CLAUDE.md
NEWS.md
```
