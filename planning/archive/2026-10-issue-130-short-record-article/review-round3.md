## Checklist read

- /Users/airvine/Projects/repo/soul/conventions/writing.md, in full. The rule that governs this branch is "State each claim by the code's definition": name the set or relation the code defines, then confirm the sentence covers all of it and only it.
- code-check.md, the prose of all fourteen H3s under `## Mechanisms` (table rows skipped). The ones that bear on this round:
  - "A proxy is not the property": a sentence describing a figure is a claim about the criterion; end by enumerating every sentence that describes a result.
  - "A guard's scope, escape hatches, and remedies": restatements name their population six ways; terminate by enumeration.
  - "A guard that fails toward pass".
  - "Restore the bug and prove the guard fires": ask what would make the predicate true.
  - "One fact derived twice".

What I ran, read only:
- Rendered `vignettes/short-record-flow.Rmd` to the scratchpad after `pkgload::load_all()`. It builds and every `stopifnot()` holds. Extracted the published text from the HTML.
- Read both bundles, the pilot header (`scripts/departure_pilot.R:1-213`), both tracked reports, and the `wet_window_extend()`, `wet_departure_carry()` and `wet_snow_annual()` docs and code.
- Read cd's producer, `cd/scripts/backfill_edh_snow.py:27-31,262-271`, for the definitions of `snowmelt_doy_50` and `swe_max`.
- Read HYDAT 20260717 read-only (`SQLITE_RO`) for the record years at 08EE018 and 08EE003.
- Measured the bundled snow grid with terra: `inst/extdata/snow_pilot/*.tif` has a resolution of 0.1 x 0.1 degrees.

## Enumeration

Rmd line numbers are at HEAD (b6a7161). "Unguarded: a fixed fact" marks a literal no guard reads: a date, a place, or a setting fixed in the pilot header.

| # | Unit (published text) | Verdict | Source of truth / guard |
|---|---|---|---|
| 1 | Maxan Creek runs into Bulkley Lake, at the head of the Bulkley River, which Chinook salmon use in summer. | HOLDS | Station name "above Bulkley Lake". Geography. Unguarded: a fixed fact. |
| 2 | Its flow was measured for only five summers, 1975–1979. | HOLDS | HYDAT runs from June 1974 (partial) to December 1979. The complete window-years are 1975–1979 (pilot report §1, "08EE018 5"). Guard: `identical(obs_years, 1975:1979)`. |
| 3 | …uses the R package `wet` to fill in the rest of its record from gauges nearby… | MISLEADING (minor) | The code fills no record. It fills each year's window statistics, in two windows, 1931–2024 (`wet_window_extend()`), which includes 44 years before the gauge existed. Unguarded. |
| 4 | …two Chinook windows: adult migration (May 1 – August 1) and spawning (August 1 – September 15). | HOLDS | Pilot header:29-30. Unguarded: a fixed fact. |
| 5 | In the spawning window, Maxan Creek's flow in a typical year of 2011–2024 was 56% lower than in 1931–1980 | HOLDS | `change`: the difference of mean log departures, a ratio of geometric means. pct −55.9, n_pre 50, n_post 14. Guards: `row_of()` checks n, and the drawn-means `all.equal`. |
| 6 | …with a 90% range of 28%–73% lower | HOLDS | Bootstrap interval −73.0..−27.9 (pilot §4). Guard: `sp$pct_hi < 0`. |
| 7 | …and its lowest seven-day flow fell by about two thirds. | HOLDS | min7 spawning −64.7. Guard: `abs(sp7$pct + 66.7) < 3`. |
| 8 | In the migration window the change is small and uncertain: 14% lower, with a range from 33% lower to 9% higher. | HOLDS | −14.1, −32.7..9.1. Guard: `mg$pct_lo < 0, mg$pct_hi > 0`. |
| 9 | Maxan Creek drains 362 km² of plateau east of Houston. | HOLDS | The FWA catchment area, 361.7 km², in the map bundle. Place is unguarded: a fixed fact. |
| 10 | The gauges whose records fill its years are within about 70 km | HOLDS | Fill = `extension_donor` (08EE004, 08EE008, 08EE013). Farthest is 69.7 km. Guard: within 2 km. |
| 11 | …and those that lend only their departures within about 90 km. | HOLDS | Lend = 08EE003, 08EE020, 08JA016. Farthest is 90.2 km. Guard: within 2 km. |
| 12 | Fig 1 caption: Maxan Creek's gauge and catchment (362 km²), and the neighbouring gauges it borrows from. | HOLDS | Every non-Maxan gauge is `extension_donor` or `carried_donor`. Guard at :146. |
| 13 | Fig 1 caption: Maxan's and Buck Creek's catchments lie inside the Bulkley gauge's near Houston. | HOLDS | Guard: `share_inside() > 0.99` for both. |
| 14 | Legend (short_record_map): Drains to the Bulkley gauge near Houston / to the Buck Creek gauge / to Maxan Creek's gauge | HOLDS | `catch$part` keyed by station_number. |
| 15 | Legend: Bulkley River, Buck Creek and Maxan Creek | HOLDS | `map$streams$main` holds exactly those three GNIS names. |
| 16 | Legend: Maxan Creek gauge (five years) | HOLDS | As #2. |
| 17 | Legend: Gauge whose record fills Maxan's years | HOLDS | `role == "fill"` from `v$gauges$extension_donor` (:145). |
| 18 | Legend: Gauge that lends only its departures | HOLDS | `role == "lend"`. Guard: `all(g$carried_donor[st$role == "lend"])`. |
| 19 | The black lines are the two periods the changes compare. | HOLDS | `means` segments over `pre` and `post`. |
| 20 | Fig 2 caption: Average flow in each window, 1931–2024 (log scale). | HOLDS | `ext$value` is the window mean (m³/s). first_year and last_year are computed. |
| 21 | Fig 2 caption: Points are the five measured summers; the line fills the other years from one nearby gauge each, shaded by its 90% range. | HOLDS | `source == "observed"`. One donor per year (`ext$donor`). The ribbon is OLS's prediction interval, which is zero-width in the observed years. |
| 22 | Fig 2 caption: Black lines are each period's typical flow (the geometric mean), 1931–1980 and 2011–2024: their ratio is the change. | HOLDS | Guard at :254-257 (`all.equal` to `pct`). |
| 23 | Facet labels Migration (May 1 – August 1), Spawning (August 1 – September 15); y axis Average flow (m³/s) | HOLDS | As #4 and #20. |
| 24 | Legend (short_record_series): 90% range / Filled from a neighbouring gauge / Measured at Maxan Creek / Typical flow over the period | HOLDS | As #21 and #22. |
| 25 | Table header: Window, Flow, Typical year, 2011–2024 against 1931–1980, 90% range | HOLDS | `post_text` and `pre_text` are computed. Guard: n in `row_of()`. |
| 26 | Table row: Migration, Window average, −14%, −33% to +9% | HOLDS | `change` mean/migration. |
| 27 | Table row: Spawning, Window average, −56%, −73% to −28% | HOLDS | `change` mean/spawning. |
| 28 | Table row: Spawning, Lowest seven days, −65%, −78% to −43% | HOLDS | `change` min7/spawning. |
| 29 | Two routes fill the years Maxan Creek was not measured, and each was scored at gauges with fuller records. | HOLDS | Extension: 21 pool gauges with 30 or more years. Carried: 31 pool gauges with 10 or more baseline years. Every one has more than 5 years. |
| 30 | A score of 1 is a perfect match, and 0 is no better than calling every year typical. | HOLDS | Log NSE. 0 is the observed years' log mean for the extension (header:143), and "no departure" for centred series in the carried route (header:165). Unguarded: a fixed fact. |
| 31 | Each missing year comes from the gauge nearest in place and size with a record that year, | **WRONG** | `wet_window_extend.R:113-119`, pilot header:75-80. The chain is the 5 nearest extension-pool gauges with a value in every one of Maxan's observed years, so it excludes 08EE003. In 11 filled years per window (1931, 1933, 1944–1951, 1971), 08EE003 is nearer and has a record, yet the year comes from 08EE004 or 08EE008. Unguarded. See Findings. |
| 32 | …through a fit between the logs of its flow and Maxan's over the five measured summers. | HOLDS | Candidate (a): OLS of log y on log x over the observed years (header:99-103). |
| 33 | At 21 gauges, each record was cut to five years at a time, filled back out and scored on the years it had lost: | HOLDS | Header:128-139. Report §2: 21 gauges, 218 blocks. `scm$extension_gauges`. |
| 34 | …a median of 0.50 in the migration window and 0.42 in the spawning window, | HOLDS | Report §2: ols 0.50 and 0.42 (median over gauges of the per-gauge median). |
| 35 | …with the 90% range holding the measured flow in 85–88% of those years. | HOLDS | ols coverage: 85 migration, 88 spawning. |
| 36 | Each year takes the departure from normal (its 1981–2010 average) at the five gauges nearest in place and size with at least ten years of record then, | **MISLEADING** | The donor set (5 nearest departure-pool gauges with 10 or more baseline years) holds, and so does the departure as log(value / arithmetic 1981–2010 mean). But each year is the inverse-distance mean of only those of the five with a value that year (`wet_departure_carry()`, header:80-85). Only 26 of 147 years have all five. Before 1981, 20 of 29 migration years and 21 of 30 spawning years are one gauge's departure at weight 1. See Findings. |
| 37 | …so needs no record at Maxan. | HOLDS | Header:154-157. |
| 38 | Leaving out each of 31 gauges in turn, it scored a median of 0.63 in the migration window and 0.49 in the spawning window, | HOLDS | Report §3: n 31, medians 0.63 and 0.49. Guard: the two windows' gauge counts are equal. |
| 39 | …and 0.92 and 0.59 on Maxan's own five summers. | HOLDS | Report §4, "two routes" obs NSE. Centred, this is the carried route against Maxan's observed values, and equals the short-record row's 0.92. Guard: `maxan_years == 5`. |
| 40 | The borrowed departures reach only 29–30 of the 50 years before 1981. | HOLDS | `n_pre_carried` 29 and 30. Guard: `< length(pre)`. |
| 41 | They give smaller drops, 3% lower in the migration window and 46% lower in the spawning window, but the same picture: a much drier spawning window, and little change in migration. | HOLDS (numbers) | `carried_pct` −2.6 and −46.3. Guard: signs and `abs()` order. The years they rest on are #36's finding. |
| 42 | On all three watersheds, snow melted about ten days earlier in 2011–2025 than in 1950–1980, | MISLEADING (wording; number holds) | `snow_change`: doy shifts −9.2, −11.0, −9.8. Guard: `nrow == 3`, in (−11.5, −8.5). What "snow melted" measures is #46's finding. |
| 43 | …and peak snow was 3–4% lower. | HOLDS | Area-weighted mean of each cell's annual maximum SWE: −3.2, −3.2, −3.8%. Guard: in (−4.5, −2.5). |
| 44 | Migration-window flow follows the snow: at all three gauges, a year whose snow melted ten days later carried about a quarter more flow, | HOLDS (number) | One-predictor doy fits: +27.9, +24.9, +26.5% per 10 days. Guard: within 5 of 25, `slope_lo > 0`, n == 3. |
| 45 | …and one with 100 mm more snow about a third more. | **MISLEADING** | The predictor is `swe_max` per 100 mm of snow water equivalent, not of snow (`departure_snow.R:55-58,273`). The gains, +32.8, +36.7 and +38.7%, hold under the guard (within 7 of 33.3). See Findings. |
| 46 | Spawning-window flow does not: each of these two measures of snow explains at most 6% of how its flow varies between years, at any gauge. | HOLDS | Max R² over the 6 non-carried spawning fits is 0.063 (08EE003 swe). Guard: `< 0.1`. |
| 47 | Fig 3 caption: Each year's window flow, as a percentage of its 1981–2010 average, | HOLDS | 100·exp(dep), with dep = log(value / arithmetic 1981–2010 mean) (header:36-38; snow header (i)/(ii)). |
| 48 | Fig 3 caption: …against the date half of the watershed's snow had melted, 1950–2024. | **MISLEADING** | `snowmelt_doy_50` is, per 0.1° cell, the first day on which cumulative calendar-year melt reaches half that year's total melt (cd `backfill_edh_snow.py:30,262-269`). It is then averaged over the watershed by cell share (`wet_snow_annual.R:18-19,127`). That is not the day half the watershed's snow had melted. The years are computed. See Findings. |
| 49 | Fig 3 caption: Maxan Creek's values are its filled record. Lines are straight-line fits (log scale). | HOLDS | `series != "carried"`, so 08EE018 is "extended". `geom_smooth(lm)` on log10. Guard at :365-370: the bundled slope is refitted. |
| 50 | Fig 3 axes: Date half the snow had melted; Window flow (% of 1981–2010 average) | x: **MISLEADING** (as #48); y: HOLDS | |
| 51 | Legend (snow_gauge): Bulkley River near Houston / Buck Creek / Maxan Creek (filled record) | HOLDS | `pal_gauge` keyed by station_number. |
| 52 | Each filled year rests on one nearby gauge, through a fit on five summers. | HOLDS | One donor per year. OLS on n = 5. |
| 53 | Most of the years before 1981 come from the Bulkley at Quick, whose catchment holds Maxan's, so they carry the Bulkley's own history: 31 of the 50 in the migration window. | HOLDS | `n_quick` = 31 (spawning 30). Guard: `> 25`. Containment is geography (Maxan → Bulkley Lake → Bulkley → Quick). Unguarded: a fixed fact. |
| 54 | Spawning-window flows are small, under 0.5 m³/s in 80 of the 94 years, so a small change in flow is a large one in percent. | HOLDS | Count over `ext` spawning. Guard: `small > n_spawn / 2`. |
| 55 | The snow is modelled on cells a tenth of a degree across, about 11 by 7 km here, coarse for a 362 km² watershed. | WRONG (minor) | The layer is 0.1° (bundled tif), but at Maxan (54.36° N) 0.1° of longitude is 6.5 km, not 7. "Modelled on": ERA5-Land runs on a ~9 km native grid (cd README:7), and 0.1° is the regridded layer. Unguarded. |
| 56 | The windows come from the literature for the Bulkley, not from observation at Maxan Creek. | HOLDS | `life_history_bulk.csv` CH rows; Gottesfeld and Rabnett (2007). Unguarded: a fixed fact. |
| 57 | The flows in this article are from HYDAT release 2026-07-17; | HOLDS | `prov$hydat`. |
| 58 | …the snow is ERA5-Land, summarised per year by the R package `cd` (its layers at commit 349f9d7); | HOLDS | `prov$cd_sha` (the layers' CD_SHA). The installed cd commit printed below is bd8137f, and the sentence names the layers' commit, not that one. |
| 59 | …the catchments and streams are the Freshwater Atlas's, through `fwapg`. | HOLDS | `data-raw/short_record_vignette_map.R` reads fwapg. |
| 60 | The data were bundled at `wet` commit be14851. | HOLDS | `prov$wet_commit`. It is an ancestor of HEAD, and only `scripts/vignette_*_lib.R` guard lines changed since. |
| 61 | How the record is filled and scored is set out in `wet`'s research notes. | HOLDS | Links `research/station_flow_departure.md` on main. |
| 62 | Generated citation lines; "Cite `wet` by the DOI above, which resolves to its latest release." | HOLDS | `wet_software_cite()`; concept DOI. |
| 63 | Data paragraph (HYDAT, ERA5-Land reference, Gottesfeld and Rabnett, fwapg, BC Geographic Names) | HOLDS | Unguarded: fixed citations. |
| 64 | README: "…how flow in two Chinook windows has changed at Maxan Creek, measured for only five summers, with the rest of its record filled from nearby gauges." | MISLEADING (minor) | As #3. |
| 65 | research/station_flow_departure.md: "The article … puts the Maxan answer and the snow fits below in front of an outside reader (#130)." | HOLDS | The article carries §4's change and the §5 snow fits. |

## Findings

- **[severity: bug]** vignettes/short-record-flow.Rmd:320-322. "Each missing year comes from the gauge nearest in place and size with a record that year" is false for 11 filled years in each window. The code's set is narrower: the k = 5 nearest extension-pool gauges with a value in every one of Maxan's measured summers (`R/wet_window_extend.R:113-119`; pilot header:75-80). Within that chain, each year comes from the nearest gauge with a value that year. The Bulkley near Houston (08EE003) is not in the chain because it has no record in 1975–1979 (HYDAT: 1971, then 1980). Yet it is nearer in place and size than both Quick (08EE004) and Goathorn (08EE008), by the pilot's own distances: it is in the five nearest of the departure pool and Quick is not, and its 1971 inverse-distance weight is 0.56 to Goathorn's 0.44. It has a complete window-year in 1931, 1933, 1944–1951 and 1971 (the carried route uses it alone in those years). Those years are filled from Quick (1931–1951) and Goathorn (1971). The trailing "through a fit … over the five measured summers" implies the five-summer requirement but does not state it as the selection rule. No guard reads the sentence. Suggested wording: "Each missing year comes from the nearest gauge, in place and size, that was also measured in Maxan's five summers and has a record that year".

- **[severity: bug]** vignettes/short-record-flow.Rmd:328-330. "Each year takes the departure from normal … at the five gauges nearest in place and size" describes the donor set, not what a year takes. Each year is the inverse-distance-weighted mean of those of the five that have a value that year, with the weights renormalised (`wet_departure_carry()`; pilot header:80-85). All five are present in 26 of the 147 carried years. Before 1981, 20 of the 29 migration years and 21 of the 30 spawning years are one gauge's departure at weight 1: 08EE003 alone in 1931, 1933 and 1944–1951, and 08EE008 alone in 1960/61–1970. Those are the years the paragraph at :336-339 compares ("smaller drops … but the same picture"), so a reader takes them for a five-gauge mean. Suggested wording: "the weighted mean of the departures from normal at those of the five nearest gauges … with a record that year". Alternatively, add a limit bullet beside "Each filled year rests on one nearby gauge" saying that most borrowed years before 1981 rest on one gauge.

- **[severity: bug]** vignettes/short-record-flow.Rmd:385-386. "one with 100 mm more snow about a third more": the predictor is `swe_max` per 100 mm of snow water equivalent (scripts/departure_snow.R:55-58, 273). That is the watershed's area-weighted mean of each cell's annual peak SWE. Read as snow, 100 mm is roughly a third to a fifth of the snowpack depth it stands for, so the sentence overstates by that factor how sensitive the flow is. The guard pins the gain (`abs(swe_gain - 100/3) < 7`), not the unit. Say "100 mm more snow water equivalent at the peak", or "100 mm more water in the peak snowpack".

- **[severity: fragile]** vignettes/short-record-flow.Rmd:377-378 (caption), :403 (x axis), and the "snow melted … ten days earlier" and "melted ten days later" sentences at :382 and :385. "The date half of the watershed's snow had melted" is not what the code computes. Per 0.1° cell, `snowmelt_doy_50` is the first day on which cumulative calendar-year snowmelt reaches half that year's total melt (cd `scripts/backfill_edh_snow.py:30, 262-269`; `R/wet_snow_annual.R:41-42`). `wet_snow_annual()` then averages it over the watershed by cell share (:18-19, :127). An average of cells' half-melt dates is not the day half the watershed's snow had gone: deep, late-melting cells weigh more in the watershed total than in the area mean. The year's melt total also counts autumn melt. No guard can see this. Suggested wording: "the day by which half the year's snowmelt had happened, averaged over the watershed" (the function's own words), with "Half-melt date" on the axis.

- **[severity: fragile]** vignettes/short-record-flow.Rmd:423-424. "The snow is modelled on cells a tenth of a degree across, about 11 by 7 km here": at Maxan's gauge (54.36° N), 0.1° of longitude is 6.5 km, so the cells are about 11 by 6.5 km. ERA5-Land is modelled on its ~9 km native grid (cd README:7), and 0.1° is the regridded layer cd serves (bundled tif, resolution 0.1). Suggested wording: "The snow comes on cells a tenth of a degree across, about 11 by 6.5 km here". The bullet's point, that the cells are coarse for a 362 km² watershed, stands.

- **[severity: fragile]** vignettes/short-record-flow.Rmd:112-113 and README.md:45. The article says it will "fill in the rest of its record", and the README "with the rest of its record filled". The code fills no record: it fills each year's window statistics in two windows, 1931–2024, including 44 years before the gauge existed. The article's own later phrasing, "fill the years Maxan Creek was not measured" (:318), is the accurate one. Suggested wording: "to fill in its flow in the two windows for the years it was not measured".

- **Guards that cannot fail when their sentence is false:** #31, #36, #45 (its unit), #48 and #55 have no guard, or only a guard on the number beside the word. This is the same mechanism as rounds 1 and 2. Every other unit in the table either has a guard that would fire, or is a fixed fact or contract as marked.

## Triage (main session)

All six fixed in the next commit, each rewritten to the definition the finding cites from the code, then re-read in the rendered article: the fill donors are the nearest in place and size measured in Maxan's five summers (`wet_window_extend()`'s covering chain); each borrowed year is the weighted mean over those of the five donors with that year, and most borrowed years before 1981 rest on one gauge (guarded: 20 of 29 and 21 of 30); "100 mm more water in the peak snowpack" (swe_max); the half-melt date is the day half the year's snowmelt had happened, averaged over the watershed (caption and axis); cells about 11 by 6.5 km; the article and README fill years, not a record. To keep the 600-word cap, the distance sentence names the farthest gauge only (the map shows the two routes) and the line above the flow figure, which repeated its caption, is gone; body prose 599 words.

This enumeration of all 65 published units is what ends the review: rounds 1 and 2 each found defects inside the previous fixes, so a quiet round could not, and after it every unit either holds with a guard that would fire or is one of the six rewritten here.
