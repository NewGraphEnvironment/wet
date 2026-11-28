# Code-check round 3: branch 237 (air temperature tree)

## Checklist read

- **code-check.md:** I read the prose of every H3 under `## Mechanisms`, skipping the table rows and the evidence blocks. The headings: "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree, and what generators leave in it", "A wrapper's exit is not the work", "Zero-length, empty, and unset are three different things", "The probe is broken before the world is", "Written data outlives the fix", "Serialization loses meaning silently" and "One fact derived twice". I read the two that matter most here in full: "Verification that reads its own output" and "One fact derived twice". I did not read the "Rules that stand alone", "Security" or "Spreadsheets and PDFs" headings (about 23), apart from "Documentation Staleness", whose rule I know from round 2.
- **code-check-r.md:** I judged it from its index lines. Round 1 and round 2 already read in full the sections this diff touches: data-raw loading, tests against the installed package, undeclared `pkg::` in tests, `match()` and NA, `ifelse()` on an all-NA test, `function(...)` mocks, DBI types, `identical()` on reader results, and arrow. I re-ran the checks those sections prescribe rather than re-reading them. About 150 headings were not re-read.
- **code-check-shell.md and code-check-spatial.md:** judged from their index lines only (about 130 and 120 headings). The branch's shell and spatial code is the same `system2("git"/"aws")`, terra and PostGIS code rounds 1 and 2 checked against the source.
- I also read cd's `R/cd_extract_daily.R` (the per-year loop, `daily_cells()`, the default `source`) and crate-air's two schemas, and grepped the planning files and `data/` for evidence of a build.
- I read the index, the diff and the changed files from file.

## The mechanism behind rounds 1 and 2

All six earlier findings come from one assumption: **a second copy of a fact tracks its source because the author wrote both, and nothing mechanical ties them together.**

- The test's packages against DESCRIPTION.
- A segment id as integer on one side and as double on the other.
- The frame handed to the writer against the part on disk.
- The roxygen against the Rd.
- The research sentence against the tests.
- The comment against cd's code.

In each case the author checked the copy they had in hand (the in-memory frame, the roxygen source, their reading of cd, an environment with arrow installed). The consumer reads the other copy. The prescription is code-check.md "One fact derived twice": partition every literal into a contract this repo chose (hardcode it) and a fact about another artifact (read it from that artifact, or stop when the two diverge).

## Every place the mechanism reaches on the branch, checked

| Copy | Source of truth | Verdict |
|---|---|---|
| DESCRIPTION Imports/Suggests | code, tests and examples | clean: `tools:::.check_packages_used`, `_in_tests` and `_in_examples` print nothing |
| `man/*.Rd` | roxygen | clean: `devtools::document()` in a scratch worktree at HEAD changes no file |
| integer keys | int32 parts | clean: reader (`vk`, `hit`), `air_check_complete`, `air_check_values` and the station check all paste integers; the remaining `paste(segs, collapse)` IN-lists are exact numeric literals |
| checks against the parts | parquet on disk | clean: `lookup` is replaced by its read-back before the cell checks; each year part is read back before completeness and values |
| `air_code_files` | what the build calls | clean: the test derives the list from the parse and passes |
| `wet_air_cell_id()` formula | crate schema text | clean: same formula; `air_cell_centre()` inverse tested |
| `air_id` / `air_url` | `wet_air_id` / `wet_air_catalog_url` | clean: `stopifnot(identical())` in the lib |
| `air_mask_day` | cube's last year, first band | clean: the build stops on either mismatch |
| comment on cd's "has data" band | cd 0.6.13 lines 150–153, 383 | clean after round 2 |
| research "each check shown able to fail" | test-air_publish_lib.R | clean: own, moved, no_data, outside, completeness and values each have a red mutation |
| publish header "skip a part whose live ETag is its md5" | `wet_catalog_verify()` | clean: a HEAD request with ETag compared |
| `scripts/discharge_publish_own.R` claim | table scripts | clean: none sources or calls the air files |
| bundled tarball paths ≤ 98 | `git ls-files inst/air` | clean: 95, 97, 97 with `wet/` |
| **research status line and "Produced by"** | build records | **finding 1** |
| **the cube's address** | one address for data and checks | **finding 2** |
| **`air_grid` "held for every file"** | the files checked | **finding 3** |

Tests at HEAD, in a scratch worktree under `NOT_CRAN=true` and `load_all()`:

| File | Pass | Fail | Error | Skip |
|---|---|---|---|---|
| test-wet_air_daily.R | 41 | 0 | 0 | 0 |
| test-air_publish_lib.R | 22 | 0 | 0 | 1 (crate schemas) |
| test-wet_catalog.R | 81 | 0 | 0 | 0 |
| test-wet_db_load.R | 58 | 0 | 0 | 0 |

The worktree is removed. The repository is unchanged.

## Findings

- **[severity: fragile]** research/air_temperature_segments.md:3 and :5. The research file claims a build that nothing records.
  - **What the file says.** The header says it was verified on "a build of two watershed groups and two years". The Status line says "built and checked on two watershed groups (VICT and CLAY) for 2024–2025". "Produced by" names `data/checks/air_publish_2025.txt` and `data/checks/air_station_check_2025.txt`.
  - **What I found.** Neither report exists in the branch or in the main checkout's `data/checks/`. There is no `data/logs/237/` in either checkout. `findings.md` mentions VICT and CLAY only in the Phase 1 timing table of one-day `cd_extract_daily()` calls. Neither `progress.md` nor any commit message records a build. The task plan's `scripts/air_publish.R` and Phase 4 boxes are unticked.
  - **The script cannot produce such a build as written.** It stops unless the lookup holds every row of `fwa_stream_networks_sp` (`nrow(lookup) != n_table`). It also stops unless the cube's years run unbroken from the first year to 2025, read from the hard-coded `air_cube_url` manifest. So a build of 2 groups and 2024–2025 alone is refused.
  - **Why it matters.** This is the round-2 (5) shape again, larger: a verification claim with no evidence behind it. Its producer files do not exist. It would survive into the merged research file.
  - **Fix.** Either point to where that trial build and its report are recorded and commit them, or narrow the header and Status line to what was done (the method, the fixture and the sizing). Then name the two reports as "written by the province build (pending)".
  - **Rule:** code-check.md "One fact derived twice" (a claim that names its producer must be derived from it), and "Restore the bug and prove the guard fires" (execute each claim the diff makes)

- **[severity: fragile]** scripts/air_publish.R:215 and :251 (also scripts/air_station_check.R:95) against scripts/air_publish.R:161, :175 and :296. The build reads the cube through two addresses.
  - **Hard-coded address.** The manifest md5, the year list, the mask file for the cell checks, the files the values check reads, and the manifest's `cube_url` all come from `air_cube_url`.
  - **cd's option.** The data come from cd's default `source`: `wet:::wet_air_cells(p[...])` for the lookup and `cd::cd_extract_daily(pts, ..., air_vars)` for every year. That default is `getOption("cd.daily_url", <same URL>)`, and cd documents overriding it.
  - **Effect.** With the option set (a local mirror, a staging cube, a test), the tree is made from one cube while its manifest, receipt and report name and check another. Where the two cubes differ, the values and cell checks FAIL, which is a refusal that is hard to explain. Where they hold the same values, the published provenance names a cube the tree was not read from: `cube_manifest_md5` comes from one manifest, while the per-year `checksum`/`cd_sha` come from the other.
  - **Fix.** Pass `source = air_cube_url` to `wet_air_cells()` and to both `cd_extract_daily()` calls, including the station check's `quiet_cd()`. Or stop when `getOption("cd.daily_url")` is set to anything else.
  - **Rule:** code-check.md "One fact derived twice" (a fact about another artifact is read from one place, or the code stops on divergence)

- **[severity: fragile]** scripts/air_publish_lib.R:19–20, with the build's grid check at scripts/air_publish.R:179 and the manifest's `grid = air_grid` at :296.
  - **What the comment says.** `air_grid` is "the published grid, which the build holds every file to (cd's own compareGeom() within a call; this across calls)".
  - **What the build does.** It compares only the mask file (`tmean_daily_2025.tif`) with `air_template()`. cd's `compareGeom()` inside each yearly call holds that year's three files to that year's `tmean` file, not to `air_grid` (cd `R/cd_extract_daily.R:168`). Nothing holds the other 75 years' files to `air_grid`.
  - **What is published anyway.** The manifest still publishes `grid = air_grid` as the cube's grid, and the report prints it as "cube grid …".
  - **No data goes wrong today.** A shifted year fails `air_daily_frame()`'s `back_id` check. A year on a smaller box (cd's old 59.95° N edge) warns "Outside…" for the 60.0° N centres, and the year loop's handler stops the build.
  - **The risk is the comment.** It is the round-2 (6) shape: it states a guard the code does not run. Anyone relying on it (for example, dropping `back_id` as redundant) loses the only check that catches a regridded year.
  - **Fix.** Either compare each year's `tmean` file with `air_template()` inside the year loop (one `compareGeom()` per year), or reword the comment to say only the mask file is held to `air_grid` and other years are caught through `back_id`.
  - **Rule:** code-check.md "One fact derived twice" (partition every literal: `air_grid` is a fact about another artifact, so read it from that artifact or stop on divergence)

index, diff and changed files read from file
