# Code check round 4 (#169)

## Checklist read

- code-check.md: every H3 under `## Mechanisms` in full prose (14, table rows skipped); no other headings.
- code-check-r.md, by heading (7 read): "Regenerated binaries churn git even when nothing changed"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "`identical()` on two reader results tests the reader, not the file"; "Never name a durable artifact by a hash the library reserves the right to change"; "`tryCatch()` nests its handlers, so a `stop()` in one is caught by a later one"; "`on.exit()` at a script's top level never fires"; "A `function(...)` mock hides arguments the real callee no longer accepts". The rest not read.
- code-check-shell.md: none read (the diff has no shell).
- code-check-spatial.md: none read in full; index only (the round-3 fix touches no spatial call).

Index, diff and changed files read from file.

## The round-3 fixes, checked

| fix | check | verdict |
|---|---|---|
| "first fetch" from the log read at the end (scenario_basis.R:427) | the start guard (:131) still refuses before any request; the end call re-reads the same file the "requests logged" line reads, so the two lines now come from one read. It prints the first request in the whole log (every run sharing the data root), which is what the registration must precede; the comment's "names its own first request" holds only for the first run that fetched, a wording slip, not a defect | sound |
| map layers named `map_layers_<key>.rds` (pcic_coverage_map.R:45-48) | `wet:::wet_md5_text()` exists (R/wet_climr_normals.R:108); the key holds the constants and both scripts' md5s, so an edit to any constant or query redraws. It holds no input the layers are drawn **from**: the database `vd_connect()` reaches (scripts/vignette_data_lib.R, `WET_PG*`) and the GNS WFS that `vm_places()` reads | finding 2 |
| `run_files()` refuses a missing file (scenario_basis.R:338-341) | a missing name now stops instead of dropping NA out of `sort()`. `run_files()` is still a hand copy of `wet_pcic_fetch()`'s name format (R/wet_pcic_fetch.R:35 against scenario_basis.R:316), and `n_files = length(rf)` is the count of names built (always 60), not of files read | finding 3 |
| PNG without date chunks (pcic_coverage_map.R, end) | measured on magick 2.9.1 / ImageMagick 6.9.13: `image_set_defines()` returns NULL and sets the define in place, so the old assignment would have handed `image_write()` NULL; the new form, `image_append()` of two PNGs written 2 s apart, then strip and define, writes byte-identical files across renders | sound |

## Where else the mechanism reaches

| # | producer's set | second copy | verdict |
|---|---|---|---|
| R1 | the pilot's rule 3 verdict by domain (channel_scale_pilot_20260717.txt, Domains table, last column) | `product` in pcic_coverage.R:140, typed by hand | **finding 1** |
| R2 | the files `wet_pcic_monthly()` read | `run_files()` names | **finding 3** |
| R3 | what the stored map layers are drawn from | `layers_key` | **finding 2** |
| R4 | the CMIP5 files rule 5 scores | `score_set()`'s `md5` (scenario_basis.R:388) | **finding 4**: computed, never printed |
| R5 | the listings rule 4 read | `listing_md5` (scenario_basis.R, rule4()) | sound: same name as `listing()` writes, and every listing exists when rule 4 runs (it runs only when all are cached, or `listing()` creates each or stops), so `sort()` drops no NA |
| R6 | segment report's group table | `pcic_coverage.R` fields 3, 4 of `^[A-Z]{4} ` rows after the header | sound: 246 rows after line 92 of data/checks/segment_output_20260717.txt, no duplicates, no other line matches |
| R7 | pilot Domains columns | `pf[4,8,9,10]`, `pilot_with_outlet()` col 3, `gcm_by_dom` col 4 | sound against lines 20-24 of the pilot report |

## Findings

- **[severity: fragile]** scripts/pcic_coverage.R:140 — `product` (Fraser "CMIP5 gridded", the rest "CMIP6 routed") is rule 3's verdict by domain typed by hand, while the report calls it "rule 3's product" and the script already reads the same pilot report's Domains table for `gcm_by_dom` (:132). The verdict column is right there (`CMIP5 gridded`; `CMIP6 routed, through fwapg's crosswalk`) and is not read, so a pilot report whose rule 3 verdict differs (a rerun, or the Fraser passing rule 2) leaves the coverage table and map naming the old products with no stop. Only rule 5's override is read from a report. Remedy: take each domain's product from the Domains row's verdict (text before the first comma), or stop when the typed vector disagrees with it.
  - **Rule:** code-check.md "One fact derived twice"

- **[severity: fragile]** scripts/pcic_coverage_map.R:42-48 — the comment says the layers are "named for everything they are drawn from", but the key holds only the constants and the two scripts' md5s. The layers are drawn from the database `vd_connect()` reaches (whichever `WET_PG*` names, and its FWA content) and from BC Geographic Names over WFS (`vm_places()`); neither reaches the key, so a run against another database, or after GNS changes, reuses the stored layers silently and draws them into the tracked `research/pcic_coverage.png`. Impact is small for these layers (FWA groups and the BC boundary rarely move), but the claim the fix rests on is false. Remedy: say in the comment that the key covers the code, not the database or GNS (delete the file to redraw), or add the database's identity (e.g. `vm_postgis(conn)` plus `WET_PGDATABASE`/host) to the key.
  - **Rule:** code-check.md "Written data outlives the fix"

- **[severity: fragile]** scripts/scenario_basis.R:313-319, :338-341, :446 — the round-3 fix stops on a missing name but keeps `run_files()` as a second copy of `wet_pcic_fetch()`'s file name (R/wet_pcic_fetch.R:35). If the two ever differ while files under the copy's names also exist (an older naming left in `data/pcic/`), the months are read from one set of files and the md5 and the "60 one-year files" line describe another, with no stop. `n_files = length(rf)` is the number of names built, the same constant as before, not a count of files read. Remedy: take the paths from the producer: `wet_pcic_fetch()` returns a cached file's path without a request, so call it per variable and year (after `wet_pcic_monthly()`, or instead of `run_files()`) and md5 those paths.
  - **Rule:** code-check.md "One fact derived twice"

- **[severity: fragile]** scripts/scenario_basis.R:388 and the report (:692-710) — `score_set()` computes each CMIP5 run's `files_md5` (and `depths()` its `n_files`) and the report prints neither, so when rule 5 runs, the verdict that decides the Fraser's scenario basis names no CMIP5 input it was scored on, while the PNWNAmet side is named (:446). A rerun cannot be held to the files the tracked report scored. Remedy: print one line per CMIP5 run (and per RCP 8.5 run when scored) with its file count and md5 of md5s, as for PNWNAmet.
  - **Rule:** none

Not a finding: the end-of-run `fetch_guard()` comment ("so a run that fetched names its own first request") is literal only for the first fetching run; the value printed (first request in the log) is the right one for the registration claim.
