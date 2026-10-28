# Progress — Article: flow change at an ungauged stream, the Maxan Creek Chinook windows (#130)

## Session 2026-10-27

- Plan-mode exploration; phases approved by the user, with the donor decision (nearest Bulkley donors for the carried estimate)
- Created branch `130-article-flow-change-at-an-ungauged-strea` off main
- Scaffolded PWF baseline from issue #130 with approved phases
- Next: start Phase 1
- Phase 1: `departure_snow.R` saves `data/departure/departure_snow_20260717.rds` after its report (41fd43e). Rerun 01:2x UTC at 41fd43e (`data/logs/130/snow_run.log`): exit 0, report byte-identical to the tracked one, the saved snow rounds to the report's per-year table at every year and watershed.
- Phase 2: `data-raw/ungauged_vignette_data.R` (1207063) wrote `inst/vignette-data/ungauged_values.rds` (14 KB): 188 extended window-years, 16 one-predictor snow fits, 7 gauges. A rerun gave an `identical()` bundle.
- Mutations, each refused: a snow series file stamped with another md5 ("was made by another scripts/departure_snow.R"); an uncommitted line in `scripts/departure_snow.R` (`vd_commit()`); one printed number in a copy of the snow report moved by 0.2 ("snow change 08EE018: … is not the report's").
- Phase 3: `ungauged_map.rds` (119 KB): 7 gauges, 3 catchments within 1 % of HYDAT's areas, 70 streams, 49 lakes, Houston (Smithers falls outside the extent, so Houston alone, as the station map). `wet_station.csv` gains `ungauged_map`, `ungauged_series` and `snow_gauge`, the classes the article draws.
