# Progress — Pinned HYDAT releases (#46)

## Session 2026-10-15

- Plan-mode exploration — phases approved by user ("go all phases to pr")
- Created branch `46-pinned-hydat-releases-one-resolver-a-per` off main
- Scaffolded PWF baseline from issue #46 with approved phases
- Next: start Phase 1
- Phase 1: `wet:::wet_hydat()` in `R/wet_hydat.R` (partial dir + rename, VERSION on every return), 23 expectations green. Four restored defects (no return VERSION check, no superseded refusal, no download VERSION check, download straight into place) each turn a test red, run in a tree copy
- Phase 2: `wb_hydat()` resolves through `wet:::wet_hydat()` and refuses a set `WET_HYDAT`; run lines stripped; the three station scripts source `wb_fit_lib.R` and record the release (departure report, `station_daily.rds` via `wet_hydat_release()`, new `station_map.rds` provenance). The grep box waits for Phase 3 (the live test still names `data/hydat/`)
- Phase 3: `local_hydat_pinned()` replaces the repo path and `local_hydat_real()`; it skips only on the classed `wet_hydat_unavailable` error, so a cache holding the wrong release fails the test instead of skipping it. The grep for `WET_HYDAT` now finds only the guard
- Phase 4 (2026-10-15 16:52–16:58 UTC):
  - `s3://fresh-bc/hydat/20251014/Hydat.sqlite3` (1,274,108,928 bytes, object metadata `md5`) and `Hydat.sqlite3.md5`, uploaded from m4's wet cache. Read back on m4: md5 da00052022aa1533b80f9fab7cb8b4d0. Anonymous GET of the md5 file gives 403, and the published manifest gives 200 from the same endpoint.
  - m1: `data/hydat/20260717/` moved (a rename) to `~/Library/Caches/org.R-project.R/R/wet/hydat/20260717/`, and `wet:::wet_hydat("20260717")` resolves.
  - m4: the main checkout's `data/hydat/20260717/` moved into the cache; `wet-16`'s `data/hydat` symlink (to it) removed. With this branch's `R/wet_hydat.R`, both 20260717 and 20251014 resolve there.
- Full suite on m1 at d077db0: 1105 pass, 0 fail, 0 skip (`data/logs/46/test.rds`). Buck Creek and snap tests passed, not skipped
- Plan review folded in (findings table): whole-file check, unique partials, ECCC answer validated, `mad_basin.R` pinned, 20260717 backed up. Mutations M5-M9 each turn their own test red
- Phase 5 on m1:
  - `wb_hydat(wb_release())` gives the cache path. `WET_HYDAT=x` is refused, and `WET_HYDAT_RELEASE=20251014` stops naming the S3 backup and the cache path.
  - `station_departure.R` ran (exit 0), and its report reads "HYDAT 2026-07-17". It was kept as `data/logs/46/station_departure_report.txt`, and the tracked report restored, because research cites its figures (review A2).
  - `station_vignette_map.R` regenerated `station_map.rds`. Five layers are `all.equal` to the committed file. Lakes hold the same 19 rows in another order (the query has no ORDER BY) and are equal once sorted. The new file carries `provenance$hydat = "2026-07-17"`, and `test-vignette_data.R` passes 104.
