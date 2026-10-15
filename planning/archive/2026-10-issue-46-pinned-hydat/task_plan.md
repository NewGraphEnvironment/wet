# Task: Pinned HYDAT releases: one resolver, a per-user cache, recorded in every output (#46)

**If we do it:** every script, data script and live test names the HYDAT release it reads and gets it from one resolver that checks the file. Station-flow outputs record their release, as the water balance's do. Package users keep tidyhydat's usual workflow untouched. **If we never do:** what the station scripts read depends on which release a machine last downloaded. On 2026-10-15 m1's tidyhydat copy was 2026-07-17 and m4's was 2025-10-14, so the same script gave different numbers on the two machines without saying so. A pinned release also exists only where someone happened to copy it.

## Phase 1: The resolver `wet:::wet_hydat()`
- [x] Tests first, `tests/testthat/test-wet_hydat.R`, against a temp `cache_dir` and tiny VERSION-only sqlite files. The network wrappers are mocked to `stop()` by default. Cases:
  - a cached match returns the path with no network call;
  - a cached file holding another release is refused;
  - an absent current release is downloaded into the cache, with no partial directory left;
  - an absent superseded release stops, naming `s3://fresh-bc/hydat/<release>/` and the cache path, and does not download;
  - a download that yields another release (ECCC moved on) stops and leaves nothing in the cache;
  - ECCC unreachable stops, naming the backup;
  - a malformed release is refused.
- [x] `R/wet_hydat.R`: `wet_hydat(release, cache_dir = tools::R_user_dir("wet", "cache"))`, internal (`@noRd`), plus thin wrappers `wet_hydat_remote()` (`tidyhydat::hy_remote()`) and `wet_hydat_download(dir)` (`tidyhydat::download_hydat(dl_hydat_here = dir, ask = FALSE)`), so tests mock them inside wet. It downloads into `<cache>/hydat/.<release>.partial/`, checks `wet_hydat_release()`, then `file.rename()`s into place, and checks `VERSION` on every return.
- [x] Restore-the-bug: drop the VERSION check, and drop the superseded-release refusal, and watch the tests go red.

## Phase 2: Scripts resolve through it; `WET_HYDAT` retired
- [x] `scripts/wb_fit_lib.R`: `wb_hydat(release)` becomes `wet:::wet_hydat(release)`, and it stops if `WET_HYDAT` is set ("retired by #46; name the release with WET_HYDAT_RELEASE; a file goes in <cache>/hydat/<release>/"), so an old run line cannot be silently ignored.
- [x] Strip `WET_HYDAT` from the run lines and comments of `scripts/wb_stations.R`, `wb_output.R`, `wb_gauge_diversion.R` and `data-raw/monthly_vignette_data.R`.
- [x] `scripts/station_departure.R`, `data-raw/station_vignette_data.R` and `data-raw/station_vignette_map.R` source `scripts/wb_fit_lib.R` and take `hydat <- wb_hydat(wb_release())`. The hard-coded `data/hydat/20260717/` default and its stale comment go.
- [x] Provenance: the departure report prints `HYDAT <release>` (from `wet_hydat_release()`); `station_vignette_data.R` takes its release from `wet_hydat_release()`; `station_map.rds` gains `attr(, "provenance") <- list(hydat = <release>)`.
- [x] `grep -rn WET_HYDAT\b` over `R/ scripts/ data-raw/ tests/` finds only the guard.

## Phase 3: Live tests name their release
- [x] A helper in `tests/testthat/helper-hydat.R`, `local_hydat_pinned(release = "20260717")`: `wet:::wet_hydat(release)`, or `skip()` with the resolver's message.
- [x] The Buck Creek test (`test-wet_station_daily.R:280`) and the snap test (`test-wet_station_snap.R:36`) use it, and `local_hydat_real()` is removed. The fixture tests keep `local_hydat()`.

## Phase 4: Copies and backup (m1, m4, S3)
- [x] m4: upload `~/Library/Caches/org.R-project.R/R/wet/hydat/20251014/Hydat.sqlite3` to `s3://fresh-bc/hydat/20251014/Hydat.sqlite3` with a `Hydat.sqlite3.md5` sidecar (`AWS_PROFILE=airvine`), private. Verify by downloading it back and checking md5 `da00052022aa1533b80f9fab7cb8b4d0` and 1,274,108,928 bytes.
- [x] m1 and m4: move `data/hydat/20260717/` into `<cache>/hydat/20260717/`. Check each by `wet:::wet_hydat("20260717")` and `wet:::wet_hydat("20251014")` (m4), and remove the empty `data/hydat/`.

## Phase 5: Verify on the real files
- [x] m1: full `devtools::test()` with the Buck Creek and snap tests passing, not skipped.
- [x] m1: `wb_hydat(wb_release())` resolves; `WET_HYDAT=x` is refused; `WET_HYDAT_RELEASE=20251014` stops naming the backup.
- [x] m1: rerun `scripts/station_departure.R` (tracked report gains its release) and `data-raw/station_vignette_map.R` (layers compared with the committed `station_map.rds`; only the provenance attribute should differ). `station_vignette_data.R` is not rerun: it already records its release, and a rerun would refresh the vignette's daily series.

## Phase 6: Docs
- [x] CLAUDE.md: remove `WET_HYDAT` (lines 26, 34, 68), and describe the cache, `WET_HYDAT_RELEASE` and the S3 backup.
- [x] `research/water_balance_method.md:124`: the same correction.
- [x] Memory `hydat_location_m1.md` rewritten to the new state; the issue body is edited if anything landed differently.

## Validation

- [x] Tests pass; `lintr::lint_package()` clean
- [x] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion
