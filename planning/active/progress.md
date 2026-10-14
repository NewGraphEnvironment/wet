# Progress — Per-segment flow: wet_segment_monthly(), and wet_flow_window() for date windows (#59)

## Session 2026-10-14

- Plan-mode exploration — phases approved by user
- Created branch `59-per-segment-flow-wet-segment-monthly-and` off main
- Scaffolded PWF baseline from issue #59 with approved phases
- Next: start Phase 1
- Phase 1: tests written, all 18 blocks fail before implementation (8 window, 10 reader)
- Plan correction: the fixture's parquet parts cannot ship (`data-raw/discharge_fixture.R`: their paths exceed the 100 bytes a portable tarball holds), so the reader's example is a `\dontrun{}` live read, as `wet_db_load()`'s is. `_pkgdown.yml` has no reference index, so it needs no entry.
