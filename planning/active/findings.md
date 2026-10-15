# Findings — Pinned HYDAT releases (#46)

## Plan-mode exploration (2026-10-15)

Findings that shaped the phases:
- `tidyhydat::download_hydat(dl_hydat_here, ask)` writes `<dir>/Hydat.sqlite3`, and `hy_remote()` returns ECCC's current release as YYYYMMDD (tidyhydat 1.0.1). `download_hydat` creates its directory non-recursively, so wet creates it.
- No edited file is among `score_files_for()` (`scripts/wb_score_md5.R:13`), so no fit goes stale. Any change under `R/` or `scripts/` does make the next `discharge_publish.R` build demand a rerun of `wb_output.R` and `segment_output.R` (`discharge_publish.R:178`). That is the usual cost, and no republish is part of this issue.
- `tests/testthat/test-wet_station_snap.R:36` reads real HYDAT through `local_hydat_real()` (tidyhydat's dir, `helper-fwapg.R:21`), as well as the Buck Creek live test.
- `station_vignette_data.R` already records the release from `VERSION`. `station_vignette_map.R` records none. `station_departure.R`'s report prints the path, not the release.
- Existing cache pattern: `wet_db_load(cache_dir = tools::R_user_dir("wet", "cache"))`.


## Issue context

**If we do it:** every script, data script and live test names the HYDAT release it reads and gets it from one resolver that checks the file. Station-flow outputs record their release, as the water balance's do. Package users keep tidyhydat's usual workflow untouched. **If we never do:** what the station scripts read depends on which release a machine last downloaded. On 2026-10-15 m1's tidyhydat copy was 2026-07-17 and m4's was 2025-10-14, so the same script gave different numbers on the two machines without saying so. A pinned release also exists only where someone happened to copy it.

## Decided (2026-10-15)

- **Pin and record.** The station-flow work pins a release (by default the shipped one) and records it in its outputs. A new HYDAT is a deliberate bump.
- **tidyhydat's directory stays the user's.** `tidyhydat::hy_dir()` holds whatever `download_hydat()` last fetched, the user's "latest HYDAT". wet never writes there. `wet_station_*(hydat = )` keep defaulting to it for interactive use, so users' workflows don't change.
- **Pinned releases live in a per-user cache:** `tools::R_user_dir("wet", "cache")/hydat/<release>/Hydat.sqlite3`. That's one copy per machine, shared by every checkout and worktree. A release gets a directory only while something depends on it. Otherwise it is overwritten, not accumulated.
- **No archive service.** ECCC serves only the current release: on 2026-10-15 the download page listed only `Hydat_sqlite3_20260717.zip`, and the 2025-10-14 file returned 404. So a superseded release we still need gets one private backup at `s3://fresh-bc/hydat/<release>/` with its md5. The anonymous read policy covers only `discharge/*`. #81 retires the one standing dependency on a superseded release (`fit_20251014` as a gate), so after it this backup is a record, not a working input.

- **`wet_hydat()` is internal** (`wet:::wet_hydat`), like `wet_hydat_release()`. Its fallback for a superseded release is a private backup that outside users cannot reach, so it is not a public contract. Export later if a user needs it.
- **`WET_HYDAT` is dropped.** Scripts name the release with `WET_HYDAT_RELEASE` alone (default: the shipped release, `wb_release()`), and the resolver is the only route to the file. A file the resolver does not know about goes into the cache directory for its release, and the `VERSION` check still applies.

## Proposed

1. **`wet_hydat(release)`, a path to a pinned release.**
   - It returns the cached copy if present.
   - Otherwise, if `release` is ECCC's current one, it fetches it with `tidyhydat::download_hydat(dl_hydat_here = <cache>/<release>, ask = FALSE)`.
   - Otherwise it stops and names where the file must come from (the backup).
   - It refuses unless `wet_hydat_release()` (the file's `VERSION`) equals `release`.
2. **Water balance.** `wb_hydat()` (`scripts/wb_fit_lib.R`) resolves through `wet_hydat(wb_release())`, and `WET_HYDAT` is removed from it and from every script's run line (`wb_stations.R`, `wb_output.R`, `wb_gauge_diversion.R`, `data-raw/monthly_vignette_data.R` and the rest that name it).
3. **Station flow.**
   - `scripts/station_departure.R`, `data-raw/station_vignette_data.R` and `data-raw/station_vignette_map.R` drop their hard-coded `data/hydat/20260717/` default.
   - They take the release from `WET_HYDAT_RELEASE` (default `wb_shipped_release`), resolve it with `wet_hydat()`, and record `wet_hydat_release()` in their outputs' provenance.
4. **Live test.** `tests/testthat/test-wet_station_daily.R:280-294` (Buck Creek, HYDAT → provisional → real-time) uses `wet_hydat("20260717")`. It skips when the release cannot be had, not on a missing repo path. The other tests keep the fixture `local_hydat()`.
5. **Backup.** Upload 2025-10-14 to `s3://fresh-bc/hydat/20251014/`, with md5 `da00052022aa1533b80f9fab7cb8b4d0` (1,274,108,928 bytes). The copy now sits in m4's wet cache (`~/Library/Caches/org.R-project.R/R/wet/hydat/20251014/`), taken 2026-10-15 from m4's tidyhydat path, the only copy found. Check the md5 after the upload.
6. **Move existing copies.** `data/hydat/20260717/` on m1 and m4 moves into the cache. Update CLAUDE.md: remove `WET_HYDAT`, and describe the cache and `WET_HYDAT_RELEASE`. Update the machine notes.

## State before the work (2026-10-15)

| machine | release | where |
|---|---|---|
| m1 | 2026-07-17 | tidyhydat default, and `data/hydat/20260717/` (a copy, made for the live test) |
| m4 | 2026-07-17 | `data/hydat/20260717/` |
| m4 | 2025-10-14 | tidyhydat default, and the wet cache (copy) |

Relates to #43, #81, #25, #27.



## Errors Encountered

| Error | Resolution |
|-------|------------|

## Plan review (`review-plan.md`, Plan agent, landed after Phases 1–3)

| finding | disposition |
|---|---|
| G1 truncated file passes the VERSION check | **Not reproduced as stated.** A VERSION+BIG sqlite cut to 20 pages already fails in `wet_hydat_release()` with "database disk image is malformed". Added anyway: `wet_hydat_check()` turns any open/read failure into "is not a whole HYDAT", compares `page_count * page_size` with the file size on every return, and runs `PRAGMA quick_check` once after a download. The size check alone is not separately pinned: no cheap fixture gets past SQLite's own check |
| G2 the shipped release has no backup | Fixed. `s3://fresh-bc/hydat/20260717/` uploaded from m4, md5 0a1c40705f31ca89606560b569ea0af5 (the same on m1 and m4), read back. CLAUDE.md: back a release up when it is first pinned |
| G3 fixed partial name races | Fixed. `tempfile()` partial per call; a failed rename onto a filled target uses that copy; partials over a day old are swept |
| G4 `mad_basin.R` reads tidyhydat's directory | Fixed: `hydat_path = wb_hydat(wb_release())` and the release printed. The pinned calls give 2664 m3/s over 10957 days, the tracked `data/basin/100_report.txt:63` exactly, so no rerun |
| G5 test gaps | Added: stale vs live partial, mock asserts its dir exists, another run landing first, non-release answer from ECCC is a plain error. `WET_HYDAT` guard checked by hand (Phase 5); scripts are not under test |
| O1/O2/O3 | Moot: the m4 move was done before anything ran there, with the branch's files copied over |
| S1 pin bump needs several edits | CLAUDE.md lists them |
| S2 lib header | Updated |
| S5 cache purgeable, Sc1 pruning | CLAUDE.md: backup survives a purge; unpinned releases deleted by hand |
| S6 tests may download 1 GB | Accepted; the helper says so |
| Sc2 partial dir vs issue's `dl_hydat_here = <cache>/<release>` | Issue body edited at the end |
| A1 unquoted grep | The check was run quoted |
| A2 departure rerun re-dates cited figures | Run as a smoke test into `data/logs/46/`; the tracked report is not refreshed |
| A3 map comparison | `all.equal` per layer; the committed file kept if any layer differs |
| A4 skips | Checked from the result table: both pinned tests passed, 0 skipped |
| A5 two date formats | The departure report now prints 2026-07-17 as the .rds files do |
