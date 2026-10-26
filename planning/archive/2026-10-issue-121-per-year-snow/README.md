## Outcome

Added `wet_snow_annual()`, each year's ERA5-Land snow from cd's annual layers over one watershed. It dissolves the watershed's polygons and samples the union once with `wet_ws_sample(method = "area")`, so fundamental watersheds and their union give identical values and one `cover`. Its example reads a 164 KB Maxan Creek bundle in `inst/extdata/snow_pilot/`, built and checked by `data-raw/snow_pilot_data.R`. `scripts/departure_pilot.R` now saves its series to a gitignored rds after its report, stamped with the md5 of the script it ran. `scripts/departure_snow.R` regresses the pilot's Chinook window flows on each year's peak snow water equivalent and 50 % melt date, under a specification registered in its header at 81580b5 before any body code. Result: more peak snow and a later melt mean more migration-window flow at every gauge and both Maxan series; snow explains almost nothing in the spawning window. The durable result is in `research/station_flow_departure.md`, "Snow and the window flows at the pilot (#121)". What was learned along the way: `wet_ws_sample()` weights by the covered share of each lon/lat cell, not ground area (now stated in the roxygen). Most review findings were claims written for a whole set that held for one member.

## Measurement

- Migration-window mean, both-predictor fits, 1950-2024: per 100 mm more peak snow +17 % to +27 %, per 10 days later melt +10 % to +21 %, all eight 90 % intervals excluding zero; R² 0.40-0.50, residual SE 0.20-0.28 log. Spawning window: R² at most 0.07, every interval spans zero.
- Snow 1950-1980 to 2011-2025: peak SWE 9-11 mm lower (3-4 %), melt date 9-11 days earlier, in all three watersheds.
- Parity with the shipped snow normals (#16): within 0.86 mm and 0.49 days over 1981-2010; the normals' cache key reproduces from the bands read. The 3,000 mm cap binds in no watershed in any year (measured, not assumed).
- Watershed polygons on fwapg: 08EE003 5,448, 08EE013 1,005, 08EE018 788 (the plan had approximate counts from `integer64` printed as doubles).
- Run times: pilot 2 min 35 s; regression 9 s; bundle 9 s. The pilot was rerun four times as its script changed; its tracked report stayed byte-identical every time, and so did the regression report.
- Code-check: five rounds, 14 findings, all fixed. Rounds 3, 4 and 5 each found a defect inside the previous fix (years coerced to NA after the check; a space in the pilot's path made its md5 NA; a sourcing wrapper recorded its own md5). Ended on round 5's enumeration of 25 invocation routes. Five reviewers is the per-task bound.

## Evidence

`data/logs/121/20261026_*` (in the main checkout): pilot runs, regression runs, test and check logs. Reviews: `review-round*.md` in this directory.

## Owed

- Tick #121 in #118's component task list

Closed by: PR (this branch, `121-per-year-era5-land-snow-for-a-watershed`)
