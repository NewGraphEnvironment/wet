# Progress — Per-segment flow: wet_segment_monthly(), and wet_flow_window() for date windows (#59)

## Session 2026-10-14

- Plan-mode exploration — phases approved by user
- Created branch `59-per-segment-flow-wet-segment-monthly-and` off main
- Scaffolded PWF baseline from issue #59 with approved phases
- Next: start Phase 1
- Phase 1: tests written, all 18 blocks fail before implementation (8 window, 10 reader)
- Plan correction: the fixture's parquet parts cannot ship (`data-raw/discharge_fixture.R`: their paths exceed the 100 bytes a portable tarball holds), so the reader's example is a `\dontrun{}` live read, as `wet_db_load()`'s is. `_pkgdown.yml` has no reference index, so it needs no entry.
- Phase 2: `R/wet_segment_monthly.R` (reader, `wet_segment_sources()`, `wet_segment_read()`, per-store helpers, `wet_segment_annual()`); reader tests 43 pass with fwapg up, 0 skip. Example is `\dontrun{}` (plan correction above). Live read of 17094080 with `groups = "BULK"`: 4.5 s, 26 rows, no NA.
- Phase 3: `R/wet_flow_window.R`; window tests 29 pass; example runs. Group filter factored into `wet_sql_groups()`; no lints in either new R file.
- Plan review (review-1.md) folded in: 12 findings; two changed the work (per-window observed months in the article; Postgres unloaded scenario/source now stops). Guard proven by disabling it (1 failure), restored (45 pass).
- Phase 4: `routed_annual()` through `wet_segment_monthly(from = "fwapg")`, equal to the old SQL within 6.8e-13 m3/s on 20,000 segments, with an assertion that the lib and package name the same table. `pcic_routed_compare.R` rerun twice (835b12e, 2a3a756): tracked report reproduces except its wet-commit line; tracked copy kept. `monthly_vignette_data.R` recipe check through the reader; bundle regenerated on m1: segments, gauges and period identical, provenance differs only in built and wet_commit (2a3a756). Article rendered before (from HEAD) and after: window table and every inline number identical; only the intended prose moved.
