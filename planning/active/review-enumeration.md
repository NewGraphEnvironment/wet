# Code-check enumeration after round 4 (#237)

Rounds 1-4 found eleven instances of one mechanism, named in round 3: a fact held in two places,
assumed equal because one author wrote both, with nothing mechanical holding them. Round 4 found
one inside round 3's fix (the cube address was made one, the cube build it named was not), so
by the stopping rule only an enumeration ends the loop. The candidate set is every fact the
branch's code, data and prose hold in more than one place. Each row names its source of truth
and what holds the copy to it; nothing sits above its source.

| # | fact | copies | held by |
|---|---|---|---|
| 1 | the tree's ID and manifest URL | `wet_air_id`, `wet_air_catalog_url` (R/); `air_id`, `air_url` (lib) | `stopifnot(identical(...))` at the lib's top |
| 2 | the mask day | `wet_air_mask_day` (R/); `air_mask_day` (lib) | the lib assigns it from R/; one value |
| 3 | the cube's address | cd's option default; `air_cube_url` | every cd call in the build and station check passes `source = air_cube_url` (round 3) |
| 4 | the cube's grid | `air_grid`; each cube file | `compareGeom()` of the mask file and of every year's three files against `air_template()` (round 3) |
| 5 | the cube build named in provenance | `cube_md5`, `mask_entry` read at the start; what cd read during the build | md5 of the cached manifest re-checked after the year loop; the mask file's checksum as cd read it held to `mask_entry`; unexpected cd warnings during the lookup stop the build (round 4) |
| 6 | which cells hold data | the lookup's mask-day band; the station check's first-year band | the station check stops unless the two bands' empty cells are identical (round 4) |
| 7 | the `cell_id` formula | `wet_air_cell_id()`; `air_cell_centre()` (inverse); crate's schema note; test values | round-trip test over five cells including both hemispheres' edges; test values computed from the formula; crate's text checked against the code in crate's own review (its round 3 enumeration) |
| 8 | the frames written | in-memory frames; parts on disk | every check reads the parts back (round 1); segment_cell parts `all.equal` to the frames |
| 9 | the files the build reads | `air_code_files`; the scripts' actual calls | `test-air_publish_lib.R` derives the list from the parse and the call closure and holds `setequal` (it caught `R/wet_db_load.R`'s `%||%`) |
| 10 | which files no discharge table reads | `scripts/discharge_publish_own.R`; the air files | the entries are a claim, checked by reading what the three table scripts source; `test-publish_own.R` holds that each listed file exists |
| 11 | column order and types | crate schemas; `air_arrow_types` | `air_conform()` refuses a frame whose names differ and one whose NA count conform changes; the float32 cast refuses a value that does not survive |
| 12 | row and byte counts in the report | parts; manifest | the manifest is written from the files, and the report reads the manifest |
| 13 | the receipt's summary names | declaration; writer | `wet_receipt_write()` reads them from the declaration (discharge receipt byte-identical before and after) |
| 14 | station and segment ids as keys | double ids from SQL; integer ids from duckdb | `as.integer()` on both sides of every paste (round 1) |
| 15 | the roxygen and the Rd | R/; man/ | `devtools::document()` leaves no diff (round 2, checked again in round 3) |
| 16 | DESCRIPTION's packages | the tests' `::` calls | `tools:::.check_packages_used_in_tests` prints nothing (round 1) |
| 17 | which band cd reads "has data" from | cd's code; the comment and research sentence | reworded to cd's code (round 2); the build's one-day call makes the two the same file |
| 18 | research claims | `research/air_temperature_segments.md`; recorded runs and tests | narrowed to the method, fixture, sizing and a trial recorded in findings (round 3); the build's counts are written after the build |
| 19 | the bundled example | `data-raw/air_example_data.R`; `inst/air/` | a rebuild is byte-identical; its manifest's crate version follows the release, and is rebuilt when crate 0.22.0 is installed |
| 20 | crate's release | DESCRIPTION's floor; the build's schema check | the build fetches each schema at the installed release's tag and holds the installed file to it |

Loop ended by this enumeration: 20 facts, each held. Commits after this one (the crate floor,
the rebuilt example manifest, the build's report and Phase 5's prose) get a review round of
their own before the verdict.
