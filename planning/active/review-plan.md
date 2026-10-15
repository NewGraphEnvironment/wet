# Review of the #46 plan (pinned HYDAT releases) against issue #46 and the code

The work moved while I reviewed. Phases 1–3 are already committed on `46-pinned-hydat-releases-one-resolver-a-per`: `6bb1479`, `8adccf3`, `0ec602a`. On m1 the cache already holds 20260717 (`~/Library/Caches/org.R-project.R/R/wet/hydat/20260717/Hydat.sqlite3`, 1,296,893,952 bytes), and `data/hydat/` is gone. So I reviewed the plan and the landed code together.

**Verdict:** no blockers. The design is sound and matches the issue's decisions. The main gaps:
- The resolver accepts a truncated file, because it only checks `VERSION` (G1).
- The shipped release 20260717 has no backup, and it is about to be superseded (G2).
- A fixed partial-directory name is unsafe when two processes fetch at once (G3).
- One HYDAT reader is missed: `scripts/mad_basin.R` (G4).
- The Phase 5 rerun of the departure report silently re-dates evidence that `research/` cites (A2).

## Blocker
None found. Every caller of `wb_hydat` is converted: `wb_stations.R:19`, `wb_output.R:21`, `wb_gauge_diversion.R:251`, `monthly_vignette_data.R:80`. No edited file is in any md5 guard:
- `score_files_for`: `scripts/wb_score_md5.R:14-17`
- the province `code_files`: `scripts/wb_province.R:52-56`
- `pcic_code`: `scripts/wb_term_diagnose.R:38`

## Gap

**G1. The download is checked only by `VERSION`, and a truncated file passes that check.** (`R/wet_hydat.R:48`, `:33`)
- tidyhydat's `download_hydat()` ends with `file.copy(...)` and `hy_check()`. `hy_check` only prints red messages for missing or empty tables and never errors (probe: `print(body(tidyhydat:::hy_check))`). `file.copy` returns FALSE on a short copy (disk full) and nothing stops the function.
- Probe on the m1 cache, read-only: `VERSION`'s root page is 40 of 1,266,498 pages (`SELECT name, rootpage FROM sqlite_master`). A copy cut off after about 160 KB would still return the right release, and the file would be renamed into the cache as valid.
- The same applies to the manual route the error message recommends ("copy Hydat.sqlite3 from the backup… to <f>"). An interrupted `cp` or `aws s3 cp` straight to the final path is not atomic.
- Fixes:
  - On every return: check `PRAGMA page_count * page_size == file.size(f)`. This costs milliseconds; on m1 both are 1,296,893,952.
  - Once in `wet_hydat_fetch()`, before the rename: run `PRAGMA quick_check`. Probe: 8.7 s on the 1.3 GB file on m1, against a download of up to 10 minutes.
  - Add a test with a VERSION-only file whose page count does not match its size.

**G2. Nothing backs up the shipped release, 20260717.** (Plan Phase 4, line 29)
- Only 20251014 is uploaded. `tidyhydat::hy_remote()` returned `"20260717"` today, so it is still current. ECCC publishes roughly quarterly, and 20260717 is three months old, so it is likely to be superseded soon.
- Once it is, the shipped fit's release, the station-flow pin and both live tests' pin would exist only in the m1 and m4 caches. The resolver's message would point at `s3://fresh-bc/hydat/20260717/`, which does not exist.
- This is the issue's own "If we never do" failure ("exists only where someone happened to copy it"), and the plan has no step that would catch it later.
- Fix: upload 20260717 with its md5 now, in the same step as 20251014. Or write a standing rule in CLAUDE.md: "the release `wb_shipped_release` names is backed up when pinned".

**G3. Two processes fetching at once can corrupt the cache.** (`R/wet_hydat.R:43-55`)
- The partial path is a fixed `.<release>.partial` that is `unlink`ed on entry.
  - Process B starting while A downloads deletes and recreates A's partial directory. Both then `file.copy` into the same path.
  - When A renames the directory, B's still-open copy keeps writing into the file A has just returned.
  - B's own rename then fails on the non-empty target (macOS `rename(2)` gives ENOTEMPTY). B stops with "could not move the download", even though a valid release now sits in the cache.
- Realistic case: two scripts started on a fresh machine (m4 runs things in parallel), or after a release bump.
- Fixes:
  - Name the partial with `tempfile(paste0(".", release, ".partial-"), tmpdir = root)`.
  - On a failed rename, return the target if it exists and passes the checks, then unlink your own partial.
  - Unique names lose the "clean a stale partial" behaviour, so sweep `.<release>.partial-*` older than about a day.

**G4. `scripts/mad_basin.R` still reads whichever HYDAT the machine last downloaded, unpinned.** (`scripts/mad_basin.R:287-288`)
- It calls `tidyhydat::hy_stations("08MF005")` and `hy_daily_flows(...)` with no `hydat_path`. The result goes into the tracked `data/basin/100_report.txt:63` ("HYDAT 1981-2010 mean 2664 m3/s") with no release named.
- It is a sanity check that never stops the run, and `wb_output.R:116` parses only the PCIC "area/covered" line. So nothing breaks, but it contradicts "every script names the HYDAT release it reads".
- Fix: pass `hydat_path = wb_hydat(wb_release())` and print the release. Or list it as an explicit exemption in the plan.
- `R/wet_temp_daily.R:169` and `scripts/temp_fill_validate.R:66` use `tidyhydat::allstations`, which is package data rather than the HYDAT file. They are out of scope.

**G5. Test gaps in `tests/testthat/test-wet_hydat.R`.**
- No test for a stale `.20260717.partial/` left by a killed run. The code handles it at line 44, but nothing pins that.
- The download mock doesn't assert `dir.exists(dir)`. tidyhydat creates the directory non-recursively, and wet creating it (`R/wet_hydat.R:45`) is the contract a mock should enforce.
- No test covers a failed rename when the target already exists (see G3).
- A garbage `hy_remote()` result (if ECCC changes its page) becomes a classed "unavailable" error, so the live tests skip silently. Checking `^[0-9]{8}$` on the remote value would turn that into a real error.
- Nothing tests `wb_hydat`'s `WET_HYDAT` guard. Only a manual Phase 5 check covers it.

## Ordering

**O1. Phase 4 on m4 must happen before anything on m4 runs the new tests or scripts.**
- 20260717 is still current, so on m4 `local_hydat_pinned()` (`helper-hydat.R:6-8`) or any `wb_hydat()` call would download about 1.3 GB into the cache first.
- A later `mv data/hydat/20260717 <cache>/hydat/20260717` would then nest it as `<cache>/hydat/20260717/20260717/`.
- Fix: do the move first, using `mkdir -p <cache>/hydat` and `mv -n` after checking that the target is absent.

**O2. m4 needs the branch's code before its Phase 4 checks.**
- Phase 4's `wet:::wet_hydat(...)` checks need this branch checked out and `load_all`ed on m4. Earlier notes have m4's installed wet at 0.0.0.9000, so a plain installed wet won't have `wet_hydat`.
- Add "fetch and check out the branch on m4".

**O3. The m1 half of Phase 4 has already happened, but its checkbox is unchecked** (`task_plan.md:30`). Tick it with what was actually done.

## Assumption

**S1. Station-flow outputs follow the water balance's shipped release.** Station scripts now pin `wb_shipped_release` through `wb_release()` (`station_departure.R`, `station_vignette_*.R`).
- A future water-balance refit bump re-pins station flow too, and a shell with `WET_HYDAT_RELEASE=20251014` exported for water-balance work changes station outputs.
- The issue decided this, and the release is now recorded, so it is visible. The live tests, though, hard-code `"20260717"` (`helper-hydat.R:6`, `test-wet_station_daily.R:289`): one bump now needs two edits. Write that down in CLAUDE.md.

**S2. Sourcing `scripts/wb_fit_lib.R` from the station and data-raw scripts is safe.**
- It only defines `wb_*` functions and `wb_shipped_release`, with nothing run at source time (`wb_fit_lib.R:18-53`). Its names don't collide with the station scripts'.
- Every caller already assumes the working directory is the repo root (`devtools::load_all()`, `data/checks/...` paths).
- `wet:::wet_hydat` resolves to the `load_all` namespace.
- Small fix: its header still says "Sourced by the wb_* scripts" (`wb_fit_lib.R:1-2`).

**S3. Leftover temp files and disk use from tidyhydat are acceptable.**
- `download_hydat()` never deletes its temporary zip, and it extracts to `tempdir()/extracted` with an `on.exit` registered only after the unzip. Peak use is roughly the zip plus 2 × 1.3 GB.
- On m1, `tempdir()` (`/tmp/Rtmp…`) and the cache are on one APFS volume with 767 GB free (probe: `df`).
- The rename is between sibling directories, so it never crosses volumes.
- A process killed outright leaves an orphaned `/tmp/Rtmp*` of about 1.7 GB.

**S4. No discharge build is waiting to be published.** Any change under `R/` or `scripts/` trips `discharge_publish.R:69` (PUBLISH: `built_at`..HEAD) and `:178` (BUILD: `seg_commit`..HEAD). The findings file covers the BUILD side; it should also confirm no local tree is awaiting PUBLISH.

**S5. Nothing purges the macOS cache directory.** `~/Library/Caches` is purgeable by OS or cleaner tools. That's fine for the current release (it re-downloads), but for a superseded one it forces a fetch from S3. Note it in CLAUDE.md beside the backup.

**S6. Tests may download about 1 GB.** With the cache empty and 20260717 still current, `devtools::test()` on a developer machine with fwapg downloads about 1 GB inside the snap test, with no prompt. CI is spared, because `local_fwapg()` and the Buck Creek test call `skip_on_ci()` first, and only `pkgdown.yaml` runs on CI anyway. Either accept this explicitly, as the helper comment does, or make the download opt-in (an env var) in `local_hydat_pinned`.

## Scope

**Sc1. Cache pruning is decided but neither planned nor built.** The issue says "A release gets a directory only while something depends on it. Otherwise it is overwritten, not accumulated." Nothing removes old releases. Either state that this is a manual rule (CLAUDE.md, Phase 6) or edit the issue body.

**Sc2. The plan downloads into a partial directory and renames it; the issue says `dl_hydat_here = <cache>/<release>`.** Phase 6 already covers editing the issue body "if anything landed differently". List this difference.

**Sc3. No NEWS.md entry.** The plan's Validation has none for the new cache and `WET_HYDAT` retirement. `/gh-pr-merge` can infer one, but the retirement breaks run lines (CLAUDE.md:26, 34, 68), so it deserves an explicit NEWS line.

## Acceptance

**A1. The Phase 2 grep check passes no matter what** (`task_plan.md:22`).
- Unquoted, the shell strips the backslash: `echo WET_HYDAT\b` prints `WET_HYDATb`, and `grep -rn WET_HYDAT\b R scripts data-raw tests | wc -l` gives `0`, a pass that checks nothing.
- The quoted `grep -rnE 'WET_HYDAT\b' R scripts data-raw tests` finds only `scripts/wb_fit_lib.R:29,33,34`. That is the intended state, so it passes for real today.
- Write the check quoted.

**A2. "Tracked report gains its release" understates the Phase 5 rerun of `station_departure.R`** (`task_plan.md:35`).
- The report holds provisional and real-time data up to yesterday (`station_departure.R:50`). The rerun rewrites the 2025 and 2026 rows and the trends, not only line 3.
- `research/station_flow_departure.md:3` says "Verified: 2026-09-28" and cites figures from that report (lines 24-32: "54–87% below", the trend p-values).
- Choose one of:
  - rerun and re-verify those research figures, updating the Verified date;
  - don't commit the refreshed report; restore it and leave a smoke run as proof.

**A3. "Only the provenance attribute should differ" needs a stated comparison method for the `station_map.rds` rerun.**
- The script also pulls Houston live from BC Geographic Names (`bcdata`, `station_vignette_map.R:97-99`) and reads the current fwapg, and the xz bytes always change.
- Say how it is compared: `all.equal` per layer on `sf` objects, attributes stripped. Say what happens if a layer differs: keep the committed file.

**A4. Phase 5 "passing, not skipped" needs a way to see the skips.** Plain `devtools::test()` output makes them easy to miss. Name the two tests and check their status, for example in the skip list printed at the end of the run.

**A5. Two date formats now record the release.**
- The departure report prints `20260717`, from `wet_hydat_release()`.
- `station_daily.rds` and `station_map.rds` store `2026-07-17` (`station_vignette_data.R:46`, `station_vignette_map.R:119`), which the vignette shows at `station-flow.Rmd:639`.

  Both are fine, but pick one on purpose. The `.rds` format matches the committed `station_daily.rds`, so the vignette doesn't change.

## What I checked that holds
- **Issue items 1–4 are met in code.** The classed `wet_hydat_unavailable` error means a cache holding the wrong release fails the live test rather than skipping it (`helper-hydat.R:8`, `test-wet_hydat.R:30-32`).
- **wet never writes to tidyhydat's directory.** `download_hydat` touches `hy_dir()` only when `dl_hydat_here` is NULL. It calls `hy_remote()` a second time internally, and the post-download `VERSION` check catches a release that changed in between (that case is tested).
- **The `vd_commit()` clean-tree guard** (`vignette_data_lib.R:17`) only matters if `monthly_vignette_data.R` or `segment_vignette_data.R` is rerun, and the plan reruns neither.
- **The `wet_db_load` cache** shares the same `R_user_dir("wet","cache")` but uses dataset subdirectories, and nothing in `R/` deletes from the cache root.
- **`R_USER_CACHE_DIR`, `XDG_CACHE_HOME` and `TMPDIR`** are all unset in m1's shell, so Rscript and the GUI resolve the same cache.

## Critical files for implementation
- `/Users/airvine/Projects/repo/wet/R/wet_hydat.R`
- `/Users/airvine/Projects/repo/wet/tests/testthat/test-wet_hydat.R`
- `/Users/airvine/Projects/repo/wet/tests/testthat/helper-hydat.R`
- `/Users/airvine/Projects/repo/wet/scripts/wb_fit_lib.R`
- `/Users/airvine/Projects/repo/wet/planning/active/task_plan.md`
- Also relevant:
  - `/Users/airvine/Projects/repo/wet/scripts/mad_basin.R` (G4)
  - `/Users/airvine/Projects/repo/wet/research/station_flow_departure.md` (A2)
  - `/Users/airvine/Projects/repo/wet/CLAUDE.md` (lines 26, 34, 68)