# Plan review of #169, backlog move 7: scenarios and coverage (2026-11-25)

Blockers raised: 2
Owner forks: 3

A Plan-type reviewer read `task_plan.md` and `findings.md` against #169, #4, #5, #205 and #9 and the code the plan names. It ran no R and contacted no PCIC host. Each finding was checked against the file it cites before it was folded in or declined; "probed" names what was read.

## Blockers

1. **Rule 4's verdict was known for one run before any listing, and its typing hid the case that matters.** fwapg's notes say CNRM-ESM2-1 has series where PNWNAmet has none, so the job would refuse that run whatever the listings say. Probed: the notes, read at the commit `findings.md` names. **Folded:** rule 4 now says so in its own text and types what each run lacks (nothing; only extra series; series the crosswalk places; series at unplaced outlets only).
2. **Rule 5 did not fix how flow, shares and observed flow are formed.** The year's length (365 against 365.25 would break parity at Hope), which shares, and observed flow were all unstated. Probed: `R/wet_mm_to_m3s.R` (default 365), the pilot's `ann()`, `shares()` and `q_obs`. **Folded:** rule 5 names each.

## Gaps

3. **`wet_upstream_means()` would not reproduce the pilot's accumulation** (covered denominator against total). Probed: `R/wet_upstream_means.R`. **Folded:** rule 5 names twelve calls of `wet_upstream_mean(..., "total", irregular_pairs = )`.
4. **Parity at 08MF005 needs the site table.** Probed: `scripts/channel_scale_sites.csv` and the report's sites table. **Folded:** rule 5 names the csv and the sites by id.
5. **A listed but short or gapped series, two rows for one run, and "days from start to end" were undefined in rule 4.** **Folded:** counted apart, two rows stop the script, both ends counted.
6. **The pilot's bulk markers do not name their outlet.** Probed: the pilot's `batch_name()`. **Folded:** the lib copies `batch_name()`; rule 4 says how a marker names its outlet, and also holds fetched outlets to their listings.
7. **The CMIP5 fetch was never logged.** Probed: `R/wet_pcic_fetch.R` writes no log. **Folded:** the script fetches a year at a time and logs each download; "first fetch: none" when no log exists.
8. **"Run from the cache" had no guard against a cache miss asking PCIC.** Probed: `tests/testthat/test-wet_pcic_fetch.R` uses `options(wet.pcic_base = "http://127.0.0.1:9")`. **Folded:** offline runs go under that option, and the bbox recipe is named.
9. **New and edited files were not added to the publish guards' list.** Probed: `scripts/discharge_publish_own.R`. **Folded** into Phase 2.
10. **Editing `R/wet_pcic_fetch.R` renames `scripts/wb_term_diagnose.R`'s cache key.** Probed: its `pcic_code` hash. **Folded** as a stated consequence; the script is not rerun.
11. **The map could not be drawn from the sources named** (no group polygons or river names in any bundle; `vm_places()` is a live query; the towns unnamed). Probed: `scripts/vignette_map_lib.R`; the bundle's columns taken from the reviewer's read of `data-raw/segment_vignette_map.R`. **Folded:** Phase 4 names each layer's source and stores the drawn layers.
12. **The coverage classes named no denominator and no class for a mixed group.** **Folded:** each share defined; the right panel gains "part or mixed".
13. **"Median absolute error as the article scores" contradicted the article**, which takes a mean. Probed: `vignettes/segment-discharge.Rmd`. **Folded.**
14. **Asks neither carried nor handed on:** #4's domain-boundary check, #5's disagreement log and "published", and a scenario key for RCP runs. **Folded** into Phase 6's bodies and open decision 2.
15. **No user agent on `wet_pcic_fetch()`.** **Folded** (`wet`).
16. **Which gridded run supplies the mask was unsaid.** **Folded:** named for each answer to decision 1.

## Ordering

17. **Under the recommended answer to decision 1 the fetches could never run in this pull request.** **Folded:** the plan says so plainly, the note is drafted first, and a table sets out what runs under each answer.
18. **Phase 4 read Phase 3's results with nothing saying which runs first.** **Folded.**
19. **Phase 1's grep could not pass before later phases.** **Folded:** copies are corrected where found, in the same commit.
20. **`vd_commit()` refuses uncommitted `data/checks`.** Probed: `scripts/vignette_data_lib.R`. **Folded:** the report is committed between runs.

## Assumptions

21. **Rule 5 is not rule 2 verbatim** (the year, an unrouted PNWNAmet side, two model structures). **Folded:** the report states the three differences beside the pilot's numbers and lists each gauge's area ratio.
22. **The RCP 8.5 check saw no scenario year, and "the packing step" was undefined.** **Folded:** 2008 added as reported; the step is the larger `scale_factor`, on daily values per variable.
23. **Rule 4's precondition was all-or-nothing.** **Folded another way:** the reference is the stored crosswalk's own set, and the listing's disagreement with it is reported, deciding nothing.
24. **"A kept file whose days" could be read as a cached file.** **Folded:** a download only, before it is renamed into the cache; the tests that need a real NetCDF skip without ncdf4.
25. **The bundled BC outline is cut for a keymap.** **Folded:** the outline comes from fwapg as `scripts/wb_map.R` takes it.
26. **`NEWS.md` has no development heading.** Probed: only release commits touch it. **Folded:** no edit on the branch; the pull request body carries the bump.

## Scope

27. **"By domain, both generations" was filed as settled, and #169's body lists it as this move's gate decision.** **Owner fork:** open decision 3.
28. **The map as a research figure, against #5's "published".** **Owner fork:** stated in open decision 2.
29. **Phase 4 is a second pull request in size.** **Owner fork:** offered in open decision 2; the draft keeps it, because under the recommended answer to decision 1 it is the main thing delivered.
30. **The map's class breaks as an owner's decision.** **Declined:** they draw a figure and decide no verdict; the plan fixes them before the table is read and says so.
31. **The "other way" in decision 2 broke the backlog's header rule.** **Folded:** the alternatives are restated, and Phase 6 says what the next sweep reads.
32. **With decision 2 "no" and no fetch, the unrun checks had no home.** **Folded:** they stay with #4 under every answer where they did not run.

## Acceptance

33. **Phase 2's cached-year check had no recorded "before".** **Folded.**
34. **Phase 3's guard tests could not all run where the fetches do not.** **Folded:** which run under each answer.
35. **Phase 4's totals check should also hold rows.** Probed: the reviewer's read of the publish report's rows. **Folded.**
36. **Phases 5 and 6 did not say what they hold when nothing ran.** **Folded.**

## Confirmed by the review

The parity lines exist at two decimals; the cached-file path is unchanged when the days check applies to downloads only; `curl` is an Import and `ncdf4` a Suggest, neither relied on wrongly; the published parts carry `watershed_group_code`, `month`, `q_m3s` and `pick`; fwapg's job stops past 100 outlets with no series and refuses a differing crosswalk; no host name or other repository's issue reference is in the planning files.

## Files the plan names

```
research/pcic_hydrology.md
research/station_sources.md
research/README.md
research/pcic_channel_scale.md
research/pcic_scenarios.md
research/pcic_coverage.png
research/discharge_publish.md
CLAUDE.md
NAMESPACE
_pkgdown.yml
R/wet_pcic_fetch.R
R/wet_pcic_annual.R
R/wet_runoff_annual.R
R/wet_pcic_index.R
R/wet_runoff_monthly.R
R/wet_pcic_monthly.R
R/wet_upstream_mean.R
R/wet_mm_to_m3s.R
R/wet_ws_fetch.R
R/wet_ws_sample.R
man/wet_pcic_fetch.Rd
man/wet_runoff_monthly.Rd
man/wet_pcic_monthly.Rd
tests/testthat/test-wet_pcic_fetch.R
tests/testthat/test-wet_pcic_annual.R
tests/testthat/test-wet_runoff_monthly.R
tests/testthat/test-wet_pcic_monthly.R
scripts/channel_scale_pilot.R
scripts/channel_scale_sites.csv
scripts/scenario_basis.R
scripts/scenario_basis_lib.R
scripts/pcic_coverage.R
scripts/pcic_coverage_map.R
scripts/discharge_publish_own.R
scripts/wb_term_diagnose.R
scripts/vignette_data_lib.R
scripts/vignette_map_lib.R
scripts/wb_map.R
inst/cartography/wet_coverage.csv
inst/vignette-data/monthly_values.rds
inst/vignette-data/segment_map.rds
vignettes/segment-discharge.Rmd
data/checks/channel_scale_pilot_20260717.txt
data/checks/scenario_basis_20260717.txt
data/checks/pcic_coverage_20260717.txt
data/checks/segment_output_20260717.txt
data/checks/discharge_publish_20260717.txt
data/checks/pcic_routed_compare_20260717.txt
```
