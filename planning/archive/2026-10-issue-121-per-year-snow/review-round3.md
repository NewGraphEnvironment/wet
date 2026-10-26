# Code-check round 3: branch 121-per-year-era5-land-snow-for-a-watershed

## Checklist read

- code-check.md: I read the prose of all 14 H3s under `## Mechanisms`, skipping the tables. That includes "A guard's scope, escape hatches, and remedies" in full. I did not read the other 23 H3s (Rules that stand alone, Security, Spreadsheets and PDFs). None of them applies to this diff.
- code-check-r.md: read in full: "`tolerance` in testthat is RELATIVE", "Rscript reads a script as it runs", "`sort()` and `order()` collate by `LC_COLLATE`", "A `data-raw/` script must load the source tree" and "`identical()` on two reader results". I checked other rules against their index line only: `$` partial matching, `stopifnot` and zero-length values, `system2(stdout = TRUE)`, "Postgres row order", "`pkg::` in a test", "`ifelse()` all-NA" and "`paste()` zero-length". About 104 not read.
- code-check-spatial.md: read in full: "terra: `extract()` returns no row for ground beyond the raster", "terra `metags<-` merges", "terra: `align()` defaults to `snap = \"near\"`" and "A label slice that ends exactly on a grid edge". About 89 not read.
- code-check-shell.md: none read, because the diff contains no shell. 67 not read.

## The mechanism

All four earlier findings share one assumption: **a property established for one member, form or name was written down for the whole set the sentence or check covers.**

- Round 1 stated the migration window's donor years for both windows, and stated an r range without saying which fits it covers.
- Round 2 had two instances. The weighting was described from the method's name (`method = "area"`) rather than from what the method computes. And `years` was checked before coercion, which is a check on a different form from the value then used.

This round's instances are a later transform the check did not see (`as.integer()` then `sort()`), a property of one cd file stated for all three, "identical" proven on an in-memory union and stated for any union, a "from its mean" that fits three of four series, and a stamp read from a different file at a different time than the run it describes.

## Claims enumerated (verdict against code or data)

Sources: `data/checks/departure_snow_20260717.txt` (S), `data/checks/departure_pilot_20260717.txt` (P), cd's cache copies of the three annual files (`~/Library/Caches/cd`, CD_RUN_TIME 2026-10-10T22:36:36Z, the same run as the report), and probes on a `git archive HEAD` copy.

| where | claim | verdict |
|---|---|---|
| roxygen L3 | ERA5-Land at 0.1°, one band per year | true (76 bands 1950-2025, res 0.1) |
| roxygen L10-12 | "fundamental watersheds and their union give identical results" | **partly**: identical for `terra::aggregate()` and `sf::st_union()` unions (probe). Not identical for a serialised union, such as the bundled WKT outline at 15 digits: on the test's three polygons the probe gave a max absolute difference of 2.2e-4. data-raw asserts only 1e-9 for Maxan. Finding 3 |
| roxygen L12 | nested or overlapping polygons count their ground once | true (dissolve; test L124) |
| roxygen L16-21 | weight is the covered share of each 0.1° cell; area falls about 2.4 %/degree at 54 N; about 1 % over half a degree; southern cells underweighted | true: tan(54°)·π/180 = 2.40 %/degree; 1.2 % over half a degree; direction correct |
| roxygen L23-28 | a cell counts only where every layer has a value; `cover` is one number; a year's value depends on `years`/`vars` | true (`wet_ws_sample()` `complete.cases`; test L127-138) |
| roxygen L28-30 | "a watershed reaching the coast reports `cover` below 1" | **overclaim**: true only where part of the watershed lies in a sea-masked cell. Finding 4 |
| roxygen L33-35 | glacier points have `swe_max` of 5,000 to 10,000 mm (per-year context) | approximately true. Per-year cell values over 3,000 mm run 3,000 to 10,124 (median 9,039; 5 % below 3,487). No finding |
| roxygen L43-45 | `years`: every one must be a band; `NULL` = the first variable's bands | true (`wet_snow_bands_check()`; test L60-64) |
| roxygen L47-49 | a remote href goes through `cd_cache_fetch()`; any other must be local | true (`^https?://`; `file.exists`) |
| roxygen L52-53 | the default cap applies only when `swe_max` is in `vars`; an explicit cap must name only `vars` | true (L91-92; test L90) |
| roxygen L54-56 | ascending years; `cover` the same in every row; NA where it is 0 | true (L104, L128; `val[!(cov > 0), ] <- NA`) |
| test L33 title | "the exact area-weighted value" | stale wording from round 2's fix. The fixtures are row-symmetric or single-row, so they cannot tell the two weightings apart. A test title, so no finding |
| test L121 | coverage fractions carry about 1e-6 on a diagonal edge | consistent with the probe (about 1e-6 relative) |
| data-raw L10-13 | union of the 788 polygons, own polygon included, EPSG:3005, unsimplified, WKT at 15 digits | true per code and provenance.txt (788, 2,690 vertices) |
| data-raw L14-17 | "FLT8S as cd writes it" | **false for 2 of 3**: cd writes `swe_max` and `snowmelt_rate_peak` as Float32 (gdalinfo `Type=Float32`) and `snowmelt_doy_50` as FLT8S. Finding 2 |
| data-raw L23-30 | "Refuses unless ..." | the checks exist, but every one runs after `unlink()` and the write. Finding 6 |
| data-raw L28 | outline equals the fundamental watersheds to 1e-9 | true (L99, `all.equal` tolerance 1e-9) |
| provenance.txt | snaps all accepted; 788 polygons; 2,690 vertices; FLT8S; equal to the remote at every cell | true (`ds_snap()` refuses otherwise; L83-84 compare against a separate `/vsicurl` crop) |
| departure_snow.R header L14-19 | rds `ws` is before the value > 0 filter | true (pilot L264 then L820; `wsel()` filters later) |
| L23-26 | WET_PG* with localhost:5432 fwapg postgres defaults; "the pilot alone reads bare PG*" | true (`vd_connect()`; a grep of `dbConnect` over scripts/, data-raw/ and R/ finds only the pilot connecting to Postgres without WET_PG*) |
| L33-34 | no timestamp; a rerun is byte-identical | consistent (no `Sys.time`; progress records two identical runs) |
| L40 | snaps 7653689, 7619666, 9939958 | true (S §1; `ds_snap()` stops otherwise) |
| L56-58 | refuses cover below 1; "none at the plan: no band has an NA cell over the pilot box" | the refusal holds (L210). "pilot box" is not defined in the header. It holds for the plan's box (-127.6…-125.6 × 53.9…54.9, 200 cells, no NA) and not for `scripts/departure_pilot.R`'s `box` (-128.8…-125.0 × 53.6…55.8, 3 NA cells in every band). This is a registered header and the report measures cover directly, so no finding |
| L68-69 | 08EE003 has 18 migration baseline years (1981-1998), 08EE013 has 30 | true (S L29, 31) |
| L75-77 | every baseline year of Maxan is extended; observed 1975-1979 | true (S per-year donors) |
| L83-92 | three fits over the same years; pre-1950 years counted; 08EE003 has no window 1999-2010 | true (one `d` per series; S) |
| L85-86 | no series reaches 2025; the extension ends in 2024 | true (S 2025 row all "-") |
| L108-112 | per-cell mean commutes; "area-weighted"; cap never binds (largest 1,783 mm in the pilot box); the difference is bilinear resampling alone | commutation holds for any fixed weights, so "area-weighted" is harmless here. 1,783.4 mm is confirmed for the plan's 200-cell box (2,853 mm in the pilot script's box; both are under 3,000). The report measures `cap_binds` directly. The normals file is FLT4S, which adds about 1e-5 mm. No finding |
| L127-132 | n = 75; 44/44 and 51/50 pool counts | true (P L15-31; S L29-36) |
| report L5 | the rds window statistics equal those recomputed from HYDAT | enforced (L184 stops otherwise) |
| report L6 | swe_max capped per cell and year at 3,000 mm | true (default `cap`) |
| report L18 | Houston contains Buck and Maxan | consistent with the areas (2,315 vs 567 and 364 km²); not measured here |
| report L79 | "(its series from 1931)" | true for both columns (P L250: extended and carried both have 1931) |
| report L87 | the cache key reproduces, so the normals were built from these bands | true by key construction (grid, vars, years, cap, method, band values) |
| report L95 | the cap binds in none of the watersheds in any year | measured (`identical()` capped vs uncapped) |
| research L118 | "all 24 fits are reported" | true (S L43-66) |
| research L121 | "at every gauge and both Maxan series" | true (the 4 "both" fits, all slope intervals > 0) |
| research L121 | "as a log departure from its 1981–2010 mean" | **false for 1 of 4 series**: the carried series is the donors' departures from their own means (the #120 section: "needs no Maxan baseline"). Finding 5 |
| research table | n, % slopes, intervals, R², SE | all 32 numbers recomputed from S with exp(b) − 1: true |
| research L130 | all eight intervals exclude zero; r = 0.50 to 0.57; alone +30 to +39 % and +18 to +28 %; spawning R² ≤ 0.07, every interval spans zero; lag-1 −0.07 to 0.19 | true (S; the lag-1 range is over all 24 fits) |
| research L132 | about 10 mm, 3 to 4 %; 9/11/10 days; −17 % and −11 %; −14 % and −3 %; back to 1931 | true (S §3: −9.3/−10.6/−9.9 mm, −3.2/−3.2/−3.8 %; e.g. exp(−0.099·0.191 − 0.98·0.169) − 1 = −16.8 %; P L211) |
| research L134 | within 0.9 mm and 0.5 days; the 3,000 mm cap never binds | true (S §4) |
| research L138 | donors per window and years | true. Not exhaustive: Goathorn also supplies 2016 (migration) and 1984 and 2016 (spawning), and "most years since 1973" leaves room for that. No finding |
| research L139 | 1950-51 carried = Houston's, in both windows | true (S per-year: −0.079/−0.002 and 0.346/0.689) |
| research L141 | 36 fitted years; 8 of 44 before 1950; none 1999-2010 | true |
| research L142 | about 70 km² per cell; 364 km² is about five cells | true (11.1 × 6.5 km at 54.4 N = 72 km²) |
| research L143 | spawning intercepts −0.31 to −0.46, carried about −0.12 | true to 2 dp (−0.315…−0.459; −0.110…−0.127). −0.315 printed at 3 dp could round either way |
| research #120 Produced-by | report regenerated byte-identical | consistent (no diff on the tracked report) |
| README row, CLAUDE.md lines | rds gitignored and md5-stamped; regression on swe/doy; bundle path; only the pilot uses bare PG* | true |
| departure_pilot.R header | rds contents listed | true (L820-822) |

## Input validations enumerated

| file:line | input | check | transformed after the check? |
|---|---|---|---|
| wet_snow_annual.R:74 | `ws` | SpatVector, polygons, ≥ 1 row | `[, 0]`/`aggregate()`, then `project()`. The check holds for the result |
| :77 | `ws` CRS | non-empty | no |
| :78 | `catalog` | none here; columns are used in `wet_snow_files()` | a factor `href` fails `vapply(, "")`, so a bad catalog aborts |
| :79 | `vars` | length, NA, duplicates, "\|" | no (used as given in names) |
| :82-88 | `years` | coerced to numeric, then NA, whole and duplicate checks | **yes**: `as.integer(y)` (L87) and `sort()` (L104). Inf, −Inf and \|y\| > 2^31−1 pass the check, become NA with only a warning, and `sort()` drops them. Finding 1 |
| :91-92 | `cap` | names in `vars`, non-NA (`wet_snow_cap_check()`) | filtered when missing. Not checked: numeric type (a character cap aborts inside terra) and duplicate names (`cap[[v]]` silently takes the first; this code moved from `wet_snow_normals()`) |
| :96 | band names | `^[0-9]{4}$` | `as.integer()` at L103 is safe for 4 digits |
| :99 | grids | `compareGeom(lyrs = FALSE)` | no |
| :105 | years in bands | `wet_snow_bands_check()` | no |
| departure_snow.R:141 | release | == 20260717 | no |
| :159-165 | pilot rds | exists; release; code_md5; baseline, k, level | `stopifnot(pr$k_main == 5)` passes on a missing field (zero-length). This is unreachable while `code_md5` matches, because the script always writes the field |
| :170-171 | windows | identical to the pilot's | no |
| :183-184 | rds `ws` vs HYDAT | `all.equal()` after key_order | no |
| :189, :191 | snap, polygons | `ds_snap()`, `ds_watershed()` counts | no |
| :197 | cd catalog | variables, href non-NA | then `cd_cache_fetch()` |
| :210 | cover | ≥ 1 | no |
| :221 | baseline years | ≥ 10 | no |
| :229 | pool counts | == the pilot report | no |
| :295 | n per series | == registered counts | no |
| :300 | normals files | ≤ 1 | no |
| data-raw:38 | release | == 20260717 | no |
| :47-48 | snap, polygons | as above | no |
| :67 | cd catalog | as above | no |
| :75 | CD_* tags | present | then merged by `metags<-` into the crop's own tags, and compared back at L86 |
| :83-86 | crop | names, geometry, values, tags vs a separate remote crop | no |
| :89 | sidecars | none | no |
| :99 | bundle | identical to whole files; the outline vs polygons to 1e-9; 1950-2025; cover 1; no NA | no, but it runs after the write. Finding 6 |
| :128 | size | ≤ 500 KB | after the write. Finding 6 |

## Findings

- **[severity: fragile]** R/wet_snow_annual.R:83-87, 104. Round 2's fix leaves a gap in the same class. A year that is not finite, or outside the integer range (`Inf`, `-Inf`, `3e9`, `"Inf"`), passes the check: `anyNA` is FALSE and `Inf == round(Inf)`. `as.integer(y)` then turns it into NA with only a coercion warning, and line 104's `sort()` drops NA by default (`na.last = NA`). Measured on the copy: `years = c(2003, Inf)`, `c(2003, 3e9)`, `c("2003", "Inf")` and `c(2003, -Inf)` each return one row, year 2003, with a warning. So a requested year still goes missing from the result without an error. Fix: also require `all(is.finite(y))` and `all(abs(y) <= .Machine$integer.max)`, or check `anyNA()` on the integer form itself, which is the form actually used.
- **[severity: claim]** data-raw/snow_pilot_data.R:16. "FLT8S as cd writes it" is wrong for two of the three files. cd writes `swe_max_annual.tif` and `snowmelt_rate_peak_annual.tif` as Float32 (`gdalinfo` `Type=Float32`; `terra::datatype` FLT4S on cd's cached copies of the 2026-10-10 run) and only `snowmelt_doy_50` as FLT8S. The values are unaffected, since float32 widens exactly and the L84 comparison holds. But the comment states one file's property for all three, and the bundle stores two layers at twice cd's width. provenance.txt says only "FLT8S", which is true of the bundle.
- **[severity: claim]** R/wet_snow_annual.R:10-11 (and man/wet_snow_annual.Rd). "so the fundamental watersheds and their union give identical results" holds for a union computed in memory by `terra::aggregate()` (or `sf::st_union()`; probe: `identical()` TRUE for both). It does not hold for a union that has been serialised, which is what the documented example passes: the bundled outline is WKT at 15 significant digits. On the test's three polygons, a 15-digit WKT round trip of the union in EPSG:3005 gave `identical()` FALSE, with a max absolute difference of 2.2e-4, about 1e-6 relative. `data-raw/snow_pilot_data.R:99` asserts only `all.equal(..., tolerance = 1e-9)` for Maxan's outline against its 788 polygons. Say "the same, to the rounding of the outline's coordinates", or limit "identical" to a union terra computes.
- **[severity: claim]** R/wet_snow_annual.R:28-30. "a watershed reaching the coast reports `cover` below 1" is stated as always true. ERA5-Land drops only cells it masks as sea, so a coastal watershed whose ground lies within land-classified cells reports `cover` 1. The sibling sentence in `wet_snow_normals()` is scoped correctly ("cells ... whose own ERA5-Land cell is empty"). Use "can report".
- **[severity: claim]** research/station_flow_departure.md:121. "The window's mean flow, as a log departure from its 1981–2010 mean, was regressed on both" covers all four series in the table below it. It is false for the donor-carried row: that series is the donors' log departures from their own 1981–2010 means, and the #120 section above says "The donor-carried route needs no Maxan baseline". The report's line 22 states this correctly. This is the round-1 shape again: true of three members, written for the set.
- **[severity: fragile]** scripts/departure_pilot.R:822. `code_md5 = tools::md5sum("scripts/departure_pilot.R")` is read when the rds is written, at the end of the run, from the repo path. It is not read from the script that ran. The pilot was rerun from a frozen copy (progress.md, Phase 4), as the "Rscript reads a script as it runs" rule prescribes, and that copy exists so the repo file may be edited while it runs. An edit saved during the run gets stamped into an rds made by the old code, and `scripts/departure_snow.R:162` then accepts it. Capture the md5 at start, of the file actually executing, or have the run record the frozen path's md5. Also, the stamp covers the script only, so a change to `R/wet_window_extend.R` or `R/wet_departure_carry.R` that moves `mx` does not stale the rds. departure_snow.R recomputes `ws` from HYDAT but not `mx`.
- **[severity: fragile]** data-raw/snow_pilot_data.R:57-59, 99, 128. The header says the script "Refuses unless" each check passes. But line 57 deletes `inst/extdata/snow_pilot/` and the new outline and layers are written before the identity, cover and size checks run. A refusal therefore leaves a bundle that failed its own checks where the example, the test and pkgdown read it. It is recoverable from git, but it is not a refusal to write. Build in `tempfile()` and move into place only after line 99 and the size check pass.

Nothing found in the wet_snow_normals() refactor (it moves code with order and messages unchanged), the fit and count logic of departure_snow.R, or the report's numbers.
