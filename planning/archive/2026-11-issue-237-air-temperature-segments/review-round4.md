# Code-check round 4: branch 237 (air temperature tree), reviewing round 3's fixes (e1d84e02)

## Checklist read

- **code-check.md:** I read the prose of every H3 under `## Mechanisms`, skipping the table rows and evidence blocks: "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree, and what generators leave in it", "A wrapper's exit is not the work", "Zero-length, empty, and unset are three different things", "The probe is broken before the world is", "Written data outlives the fix", "Serialization loses meaning silently" and "One fact derived twice". I read "One fact derived twice" and "Verification that reads its own output" in full. I did not read the 23 or so headings under "Rules that stand alone", "Security" and "Spreadsheets and PDFs".
- **code-check-r.md:** I read three sections: "`identical()` on two reader results tests the reader, not the file", "`Rscript -e` supplies `--args` itself…" and "`paste()` with a zero-length argument returns length ONE, not zero". The rest (about 150 headings) I judged from their index lines, since rounds 1 to 3 read the sections this diff touches.
- **code-check-spatial.md:** I read three sections: "`terra::rast()` on a SpatRaster returns an empty template, not a copy", "terra: `extract()` returns no row for ground beyond the raster, and counts cells by centre" and "`terra::project()` given only a CRS…". The rest (about 120) I judged from their index lines.
- **code-check-shell.md:** judged from its index lines only (about 130 headings). Round 3 changed no shell code.
- **Other sources read:**
  - cd's `R/cd_extract_daily.R` (template, `daily_cells()`, `daily_manifest()`, the stale-build warning) and `R/cd_cache_fetch.R` (cache key `rlang::hash(href)`, `cd.cache_revalidate` default TRUE).
  - The research file, the receipt declaration, the code-files derivation test and the trial record in `findings.md`.
- **Measured:** the cube's no-data mask on band 1 of `tmean_daily_1950.tif`, `_2002.tif` and `_2025.tif`, over `/vsicurl/` into a scratch session (script in the scratchpad, nothing written to the repository):
  - all three files have the same extent and are 121 × 261 cells;
  - 0 cells differ between them;
  - 10,835 cells are NA.
- **The trial's numbers in `findings.md` add up:**
  - 18,378 + 756 + 125 = 19,259 segments;
  - 73 cells × 731 days = 53,363 cell-days;
  - 53,363 × 3 = 160,089 values.

index, diff and changed files read from file

## Round 3's fixes

- **`source = air_cube_url`:** now passed at every cd call the build and the station check make (`wet_air_cells()`, both `cd_extract_daily()` calls and `quiet_cd()`). The manifest, mask and value-check files come from the same URL through `cd_cache_fetch()`. cd's own manifest read uses the same string, so it uses the same cache file. Clean.
- **Every year's three files are now `compareGeom()`'d to `air_template()`:** clean. The lib comment now matches what the code does.
- **The research Verified, Status and Produced-by lines:** they now name only what is recorded. The trial's pointer, `planning/archive/2026-11-issue-237-*`, matches the active PWF's issue (#237). Clean.

## Findings

- **[severity: fragile]** scripts/air_publish.R:161–162 and :281, :291, :303–305, against :215 and :251. The cube's manifest md5 and the mask file's checksum are each recorded once, at the start of the build, and never held to what cd actually read.
  - **What is recorded.** `cube_md5` is the md5 of the manifest fetched with `refresh = TRUE` before the lookup. `mask_entry`'s checksum comes from that same manifest. Both go into the manifest, the receipt and the report.
  - **What cd reads.** Every later cd call re-reads the manifest and the files through `cd_cache_fetch()`, which revalidates by default (cd `R/cd_cache_fetch.R:52`, `cd.cache_revalidate` defaults to TRUE). That happens 246 lookup calls and 76 year calls into a build that runs for hours. If the cube is republished mid-build, cd fetches the new manifest into the same cache path, and the per-year `checksum` values written to `years[]` come from a manifest whose md5 is not the published `cube_manifest_md5`.
  - **The lookup is the weaker side.** `wet_air_cells()` drops cd's `checksum` (R/wet_air_daily.R:190–200), so the build never compares the build of the mask file the lookup read with `mask_entry`. And unlike the year loop, the lookup call is not wrapped in a warning-to-stop handler. cd's stale-build warning ("the cube's manifest…") is not one of `wet_air_cells()`'s two muffled warnings, so during the lookup it only prints, and the build goes on.
  - **When it bites.** Only when the cube changes during a build, so it is rare. When it does, the provenance names a build that is not the one the tree was read from, and nothing fails.
  - **Fix.**
    - After the year loop, stop unless `tools::md5sum(man_path) == cube_md5`. This is the same file cd revalidates, because both build the same href and cd keys its cache on the href.
    - Stop unless the last year's `tmean` checksum in `year_files` equals `mask_entry[["file:checksum"]]`.
    - Or give the lookup call the same `withCallingHandlers(warning = stop)` the year loop uses.
  - **Rule:** code-check.md "One fact derived twice" (a fact about another artifact is read from that artifact, or the code stops on divergence)

- **[severity: fragile]** scripts/air_station_check.R:29, :95, :98 and :106. The station check reads "has data" from a different day than the lookup it is checking.
  - **Which day each side uses.**
    - The lookup took its cells from a one-day call on `air_mask_day` (2025-01-01).
    - The station check calls `cd_extract_daily(p, from, to, …)` with `from` set to the first year's 1 January. cd decides "has data" from band 1 of the first variable's file for `from`'s year (cd `R/cd_extract_daily.R:151` and `:383`, as the comment at R/wet_air_daily.R:148–151 says). So the station check places points on the 1950-01-01 mask.
  - **What rests on the two days agreeing.** The headline check: the tree equals cd at the segment's stored point. Also the station-versus-segment `same` split and the list of stations in another cell. Both hold only while the two masks are identical.
  - **Today they are.** I measured 0 differing cells between band 1 of 1950, 2002 and 2025, so a report written now is right.
  - **What nothing holds.** Nothing keeps the two masks equal. A cube rebuild that changes one year's no-data cells would make the station check FAIL on correct lookup rows, or list stations wrongly, and the report would blame the lookup. The script header and research line 39 both describe the comparison as against cd at the same point, which hides the difference in day.
  - **Fix.**
    - Place both the segment points and the station points with a one-day cd call on `air_mask_day`, as `wet_air_cells()` does, and compare the series by cell.
    - Or stop when band 1 of the first year's `tmean` file has a different NA set from the mask day's.
  - **Rule:** code-check.md "One fact derived twice" (the expected side must come from the same producer and settings as the subject, or the check fires on good input)
