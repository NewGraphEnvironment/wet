# Code-check round 4: branch 121-per-year-era5-land-snow-for-a-watershed

Reviewed at HEAD 205b471. Probes ran on a `git archive HEAD` copy in the session scratchpad, with nothing written to the repo except this file.

## Checklist read

- code-check.md: I read the prose of all 14 H3s under `## Mechanisms`, skipping the tables. That includes, in full, "A guard that fails toward pass" (its provenance paragraph: "capture a provenance stamp at the start ... write the captured value"), "A guard's scope, escape hatches, and remedies" and "Restore the bug and prove the guard fires". I did not read the other 23 H3s, because none applies to this diff.
- code-check-r.md: I read 7 sections in full: "Rscript reads a script as it runs", "`Rscript -e` supplies `--args` itself", "`tempfile()` lives in the session tempdir", "`fs::file_move()` onto an existing directory", "`as.integer(\"NaN\")` is `0`", "A `data-raw/` script must load the source tree" and "`on.exit()` at a script's top level never fires". The other 104 were checked against their index line only.
- code-check-spatial.md: none read this round. Round 3's fix touches no spatial code. 93 not read; round 3 read four (extract, `metags<-`, align, label slice).
- code-check-shell.md: none read in full; 67 not read. I applied the index line "A verification command can be shadowed by a shell function": in this shell `diff` resolves to a `git diff` wrapper, so the man-page comparison used `/usr/bin/diff`.

## Round 3's fix, probed

### `years` check (R/wet_snow_annual.R:84-91)

I called `wet_snow_annual(<bundled Maxan outline>, "swe_max", years = X, catalog = <bundle>)` for each X below.

| X | result |
|---|---|
| `TRUE` | error: no band for 1 |
| `NA`, `NaN`, `-Inf`, `"Inf"`, `c(1990, NA)` | error: distinct whole years |
| `character(0)`, `integer(0)` | error: distinct whole years |
| `-1` | error: no band for -1 |
| `factor(c("1990","1991"))` | error: no band for 1, 2. The factor's codes are used, and it is refused loudly |
| `as.Date("1990-01-01")` | error: no band for 7305 |
| `list(1990, 1991)`, `matrix(1990:1991)`, `1990L`, `c(2003, 1990)` | OK, years 1990,1991 / 1990 / 1990,2003 |
| `list(1990, "a")` | error: distinct whole years |
| `2147483647` | error: no band (the boundary passes the check, as intended) |
| `-2147483648` (`NA_integer_`'s bit pattern) | error: distinct whole years |
| `"0x7C6"` | OK, 1990 (hex parses; harmless) |
| `1990+1i` | OK, 1990. `as.numeric()` drops the imaginary part under `suppressWarnings()`. Not a realistic input, so no finding |

Nothing the check passes is dropped or changed afterwards: `as.integer(y)` is exact on everything that passes, and `sort()` cannot meet an NA.

Mutation table (test file run with `testthat::test_file()` on the copy; control: 50 passed, 0 failed, 0 errors):

| guard deleted | result |
|---|---|
| `!all(is.finite(y))` | red: 1 error in "`years` subsets and orders" (the `c("1990","x")` case reaches `if (NA)`) |
| `any(abs(y) > .Machine$integer.max)` | red: 1 error in the same block (the 3e9 case) |

Note: the `c(1990, Inf)` test is caught by both arms, because `abs(Inf)` is greater than `integer.max`. The finite arm is pinned by the `"x"` → NA case instead. Both arms have a red test, so no finding.

### data-raw/snow_pilot_data.R replace step (L133-138)

I ran the step as written against each state of the destination:

| dest state | result |
|---|---|
| absent | written |
| existing, with an old file of the same name plus an extra file | written; extra removed |
| existing, with a read-only (0444) file | written (unlink removes it) |
| a read-only (0555) directory | `unlink` fails silently and `dir.create` warns "already exists". `file.copy(overwrite = FALSE)` then returns FALSE, so the script stops "could not copy". It fails toward abort |
| a read-only parent | `dir.create` fails, then `file.copy` returns FALSE, so it stops. It fails toward abort |

Every check (L86-89, L92, L102-103, L131) now runs on the temporary copy before `unlink(dest)`. One residual: when the copy itself fails after `unlink(dest)`, the old bundle is already gone and the checked one sits in the session tempdir, which R deletes on exit. The bundle is tracked, so `git restore` recovers it, and the error message names no temporary path. So no finding.

### departure_pilot.R self md5 (L216-220)

I ran a two-line copy of the self-md5 code under each invocation:

| invocation | `self` | md5 |
|---|---|---|
| `Rscript self.R` | `self.R` | correct |
| `Rscript ../self.R` from another cwd | `../self.R` | correct (resolved against the unchanged cwd; the pilot never calls `setwd`) |
| `Rscript ~/../../<abs>/self.R` | the expanded path | correct |
| `R --no-echo --file=self.R` | `self.R` | correct |
| `R --no-echo -f self.R` | none | refused ("run with Rscript"), correct direction |
| `Rscript -e 'source("self.R")'` | none | refused, correct direction |
| `Rscript wrap.R`, where wrap.R sources self.R | `wrap.R` | **the wrapper's md5**: departure_snow.R:162 then refuses. That is the correct direction, though the message blames the pilot |
| `Rscript "sp ace/self.R"` | `sp~+~ace/self.R` | **NA**. Rscript encodes spaces in `--file=` as `~+~`, so `md5sum()` gets a path that does not exist and returns NA. The script does not refuse it (Finding 1) |

The current rds's `code_md5` (599d4b8d…) equals `md5sum("scripts/departure_pilot.R")` at HEAD. Rds mtime is 14:43:58; the snow report was regenerated at 14:44:25; both tracked reports are clean against HEAD.

## Enumeration 1: claims (round 3's table re-walked)

Files changed since round 3's base (0372584, planning excluded): R/wet_snow_annual.R, man/wet_snow_annual.Rd, data-raw/snow_pilot_data.R, inst/extdata/snow_pilot/provenance.txt, research/station_flow_departure.md (L121 only), scripts/departure_pilot.R, tests/testthat/test-wet_snow_annual.R. Unchanged: scripts/departure_snow.R, scripts/departure_snow_lib.R, CLAUDE.md, research/README.md, both data/checks reports (regenerated, clean against HEAD). For rows in unchanged text, round 3's verdict carries over. Line numbers below are at HEAD.

| where (HEAD) | claim | file changed? | verdict |
|---|---|---|---|
| roxygen L3 | ERA5-Land at 0.1°, one band per year | yes, line moved only | true (carried) |
| roxygen L8-12 | polygons dissolved with `terra::aggregate()`; the fundamental watersheds and their union "as `terra::aggregate()` returns it" give identical results | **yes (round-3 fix)** | true. By construction: a multi-row `ws` is aggregated at L111 and a one-row union is used as given, so the two inputs reach `wet_ws_sample()` as the same geometry. Test L111-123 checks it with `expect_identical`. The one-row input is not aggregated; a one-row multipolygon with overlapping parts is invalid and errors loudly (TopologyException, probed), so it never returns a silent double count |
| roxygen L12-13 | nested or overlapping polygons count their ground once | yes (rewrapped) | true for rows (test L125; probe: an outer square plus a nested column as two rows gives `identical()` to the outer alone); an invalid one-row overlap errors |
| roxygen L13-14 | "A union stored and read back (as WKT, say) agrees to the rounding of its coordinates" | **new (round-3 fix)** | true as scoped. Round 3 measured a 15-digit WKT gives about 1e-6 relative on the test fixture; data-raw L102 asserts 1e-9 for Maxan |
| roxygen L14-16 | several watersheds → mean over their union | unchanged text | true (carried) |
| roxygen L18-23 | cover-share weighting; 2.4 %/degree at 54 N; about 1 % over half a degree | unchanged text | true (carried) |
| roxygen L25-30 | every layer must have a value; one `cover`; depends on `years`/`vars` | unchanged text | true (carried) |
| roxygen L30-32 | the coast "can report" `cover` below 1 | **yes (round-3 fix)** | true (now scoped) |
| roxygen L34-37 | glacier `swe_max` 5,000-10,000 mm | unchanged | approximately true (carried) |
| roxygen L45-47 | `years` must be bands; `NULL` = the first variable's bands | unchanged text | true (carried); the new check runs before it |
| roxygen L48-51, L52-55, L56-58 | catalog href handling; cap scope; return shape | unchanged | true (carried) |
| man/wet_snow_annual.Rd | matches roxygen | yes | true: `roxygen2::roxygenise(roclets = "rd")` on the copy gives no difference from `man/` (`/usr/bin/diff -r`) |
| test L111 title | "fundamental watersheds and their union give identical results" | unchanged | true for the in-memory `aggregate()` union the test builds. A test title, as before |
| test L33 title | "the exact area-weighted value" | unchanged | stale wording, carried from round 3 (test title, no finding) |
| test L67 comment | "years are checked after coercion, so nothing is dropped or truncated silently" | context of the new tests | true now (probe table above) |
| data-raw L9-13 | outline: union of 788, own polygon included, EPSG:3005, unsimplified, WKT 15 digits | no | true (carried) |
| data-raw L14-18 | written as FLT8S; cd writes snowmelt_doy_50 as Float64 and the other two as Float32; both held exactly | **yes (round-3 fix)** | true. `gdalinfo` over `/vsicurl` of the live S3 files: swe_max Float32, snowmelt_doy_50 Float64, snowmelt_rate_peak Float32 (CD_RUN_TIME 2026-10-10T22:36:36Z on all three). The bundle is Float64 for all three. "Held exactly" holds because float32 widens exactly, and L87 checks `identical()` values against a separate remote crop |
| data-raw L24-30 | Refuses unless (HYDAT; snaps; crops equal remote; bundle = whole files; outline = fundamental watersheds to 1e-9; 1950-2025 cover 1; ≤ 500 KB) | yes | true: L41, `ds_snap()`/`ds_watershed()`, L86-89, L102-103, L131. Every check now precedes the replace |
| data-raw L30-31 | built and checked in a temporary directory; replaces the bundle only once every check has passed | **new** | true (L44, L133-137; probes above) |
| data-raw L31-33 | HYDAT from wb_hydat(); fwapg from WET_PG* | no | true (carried) |
| provenance.txt | wet commit 7e8b9fa; snaps; 788; 2,690 vertices; FLT8S; equal to the remote | yes (commit line only) | true: 205b471 rebuilt from 7e8b9fa's tree (the only change since is provenance.txt itself); bundle tifs are Float64 |
| departure_pilot.R header L14-21 | rds contents; `code_md5` is "the md5 of the script file this run executes, taken at its start; it covers the script, not the package functions it calls" | **yes (round-3 fix)** | **partly**: true for `Rscript <path>` and `R --file=` with no space in the path. Under a path with a space it is NA (Finding 1). Under a wrapper it is the wrapper's md5 (refused downstream). "At its start" means L220, after `load_all()` and one `source()`, before any HYDAT read: true in substance |
| departure_pilot.R L217 comment | "hashed before anything else can change it" | new | true in substance (before the long work). Rscript still reads later lines as it reaches them, so an edit after L220 runs a mixture under the old stamp. That is the convention's frozen-copy remedy, named in the same comment, so no finding |
| departure_snow.R header L14-19 | rds written after the pilot report; `code_md5` = md5sum of scripts/departure_pilot.R | no (registered, frozen) | true wherever L162 accepts the rds, because acceptance requires the executing copy's md5 to equal the repo file's |
| departure_snow.R header L23-26, L33-34, L40, L56-58, L68-69, L75-77, L83-92, L85-86, L108-112, L127-132 | (round 3 rows) | no | carried: all true / no finding as round 3 recorded |
| report L5, L6, L18, L79, L87, L95 | (round 3 rows) | regenerated, clean against HEAD | carried |
| research L118 | all 24 fits reported | no | true (carried) |
| research L121 | migration: every gauge and both Maxan series | no | true (carried) |
| research L121 | "For the observed and extended series the departure is from the series' own 1981–2010 mean; the donor-carried series is the donors' departures from theirs" | **yes (round-3 fix)** | true: observed `log(x / mean(b))`, b = the series' years in 1981-2010 (departure_snow.R `obs_series()`); extended `tr(e$value) - tr(mean(e$value[e$year %in% baseline]))` (pilot L708); carried `m$a$anomaly` from `wet_departure_carry(baseline = 1981:2010)`. For Houston, "its own 1981–2010 mean" is over 1981-1998, which the Limits list states ("none between 1999 and 2010") |
| research table, L130, L132, L134, L138-143 | (round 3 rows) | no | carried (all true; the L138 Goathorn and L143 −0.315 notes stand as no-finding) |
| research #120 Produced-by (L72) | the script also saves the rds; the report regenerated byte-identical | no | true: the rerun after 7e8b9fa left the tracked report clean |
| CLAUDE.md L42, L85; research/README.md | (round 3 rows) | no | true (carried) |

## Enumeration 2: input checks (round 3's table re-walked)

| file:line (HEAD) | input | check | transformed after? | verdict |
|---|---|---|---|---|
| wet_snow_annual.R:76 | `ws` | SpatVector, polygons, ≥ 1 row | `[, 0]`/`aggregate()`, `project()` | holds (carried) |
| :79 | `ws` CRS | non-empty | no | holds |
| :80 | `catalog` | in `wet_snow_files()` | factor `href` aborts | holds (carried) |
| :81 | `vars` | length, NA, duplicate, "\|" | no | holds |
| :84-91 | `years` | **now** coerced, then length, finite, ≤ integer.max, whole, distinct | `as.integer()` L90 (exact on every value that passes), `sort()` L107 (no NA can reach it) | **holds**. Probe table above; both new arms red under mutation |
| :94-95 | `cap` | names in `vars`, non-NA | filtered when missing | as round 3 (type and duplicate names unchecked; pre-existing, moved code; no finding) |
| :99 | band names | `^[0-9]{4}$` | `as.integer()` L106 safe | holds |
| :102 | grids | `compareGeom(lyrs = FALSE)` | no | holds |
| :108 | years in bands | `wet_snow_bands_check()` | no | holds |
| departure_pilot.R:213 | release | == 20260717 | no | holds |
| departure_pilot.R:218-220 | the executing script | **new**: exactly one `--file=` | `md5sum()` of it, **NA unchecked** | **gap**: Finding 1 |
| departure_snow.R:141, :159-165, :170-171, :183-184, :189-191, :197, :210, :221, :229, :295, :300 | (round 3 rows) | as round 3 | as round 3 | unchanged file: carried. :162 now compares against the executing copy's md5, which equals the repo file's only when the two match: correct |
| data-raw:41 | release | == 20260717 | no | holds |
| data-raw:47-54 | snap, polygons | `ds_snap()`, `ds_watershed()` | no | holds |
| data-raw:61 | temp `out` | `dir.create(recursive = TRUE)` on a fresh `tempfile()` path | no | holds (a fresh name; a failure would make the later writes error) |
| data-raw:70 | cd catalog | variables, href non-NA | no | holds |
| data-raw:78 | CD_* tags | present | merged by `metags<-`, compared back at L89 | holds |
| data-raw:86-89 | crop | names, geometry, values, tags vs a separate remote crop | no | holds |
| data-raw:91-92 | sidecars | none beside the layers | no | holds |
| data-raw:102-103 | bundle | identical to whole files; outline vs polygons 1e-9; 1950-2025; cover 1; no NA | no | holds, **now before the replace** |
| data-raw:131 | size | ≤ 500 KB | no | holds, now before the replace |
| data-raw:134-137 | the replace | `file.copy` all TRUE and the same file names | no | holds; fails toward abort in every state probed. It checks names, not bytes, after a `file.copy` that returned TRUE |

## Findings

- **[severity: fragile]** scripts/departure_pilot.R:218-220. The new self-md5 trusts that the `--file=` value is a path it can read. Rscript encodes each space in the script path as `~+~` in `commandArgs()`. So `Rscript "<dir with a space>/departure_pilot.R"`, for example a frozen copy under a folder such as "Application Support", gives `self = ".../x~+~y/departure_pilot.R"`, and `tools::md5sum()` returns NA. Measured: `Rscript "sp ace/self.R"` printed `self=[ sp~+~ace/self.R ] md5= NA`. Nothing refuses the NA. The pilot runs to the end, writes its tracked report and saves `code_md5 = NA` in the rds. scripts/departure_snow.R:162 then refuses with "was written by another scripts/departure_pilot.R: rerun the pilot", and a rerun from the same path repeats it. This is the round-3 mechanism again: the property was shown for one form of the invocation (a path without spaces) and the header L17-18 states it for "the script file this run executes". It fails toward abort, so no wrong number can ship, but only after the whole run, and with a message pointing at the wrong cause. Fix: refuse at L220 when `is.na(code_md5)` (or `!file.exists(self)`), or decode `gsub("~+~", " ", self, fixed = TRUE)` before hashing.

Nothing else. The `years` check closes round 3's gap for every input probed. Both of its new arms are pinned by a red test. Every claim round 3's fix rewrote checks out against code, the live S3 files or the rerun artifacts: the union wording, "can report", the data types, the build-in-temp sentence and research L121. The data-raw replace step fails toward abort in every destination state probed. Apart from Finding 1, the two enumerations show nothing above its source of truth.
