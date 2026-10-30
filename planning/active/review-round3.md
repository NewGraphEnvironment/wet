# Code check, round 3 (#145): branch 38a9672...HEAD (49e8387)

## Checklist read

- Index (`checklist.txt`): read in full, all four files.
- code-check-r.md, full sections read (12): "Moving prose into a code chunk hides it…", "A `data-raw/` script must load the source tree…", "Regenerated binaries churn git…", "A duplicate knitr chunk label fails the build…", "`sort()` and `order()` collate by `LC_COLLATE`…", "Postgres row order is never fixed…", "`sprintf("%g", x)` writes `Inf` and `NA` into SQL…", "`paste()` with a zero-length argument…", "`ifelse()` with an all-NA test…", "`sub()` takes one replacement…", "`c(name = x)` keeps `x`'s own name…", "ggplot2 legends and labels…". The rest were judged from the index.
- code-check-spatial.md, full sections read (7): "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline…", "A name is not a key…", "`atan2(0, 0)` is 0…", "FWA main flow is not edge type 1000 alone", "The BC WFS caps an un-paged `GetFeature`…", "A raster's drawn footprint is its valid data, not its extent", "`geom_sf(data = NULL)` draws nothing…". The rest were judged from the index.
- code-check-shell.md: index only. The diff has no shell code.
- code-check.md: the prose of all 14 H3s under `## Mechanisms`, with `|` rows and evidence blocks skipped. Rules that stand alone, Security, and Spreadsheets were judged from the index.
- writing.md (soul `conventions/writing.md`, 497 lines): read in full, every rule.

## Findings

- **[severity: bug]** vignettes/flow-departure-normal.Rmd:452–459 (caption), with its guard at :406–407. The map caption says "other streams of order 5 and up thin, and lakes of 100 ha and up in blue". This branch added that sentence (the old caption named no streams or lakes). Read as a description of the map, it says every such stream and lake in the frame is drawn, and that is false.
  - **Why.** `data-raw/station_vignette_map.R` queries streams and lakes only inside `vm_extent(catch, 8000)`, the catchments' bbox plus 8 km. The article then frames the map with a different box: the catchments plus 3 km, extended 22 % downward for the legend, then widened to a 7 : 6.5 aspect (Rmd:411–414).
  - **Measured** from the purled article against the installed bundle:
    - 36.5 % of the drawn frame lies outside the query extent (frame x 930,790–1,026,453, ext x 943,459–1,013,784; frame y from 990,876, ext from 1,002,986).
    - No stream of order 5 or more and no lake is drawn there, except where a feature also crosses into the extent.
    - 8 of the 27 thin streams stop at the extent's edge inside the frame: Parrott Creek, the Endako River, Houston Tommy Creek, Dockrill Creek, the Morice River (order 8) and three unnamed streams of order 5–7.
    - In docs/articles/flow-departure-normal_files/figure-html/map-1.png, the lines end abruptly along the left edge (x ≈ 265 px) and the bottom edge, and the bottom-right and left strips are empty.
  - **Why the guard misses it.** `all(map$streams$stream_order >= 5 | map$streams$main)` and `all(map$lakes$area_ha >= 100)` prove that what is drawn falls inside the class. They do not prove that the class, inside the frame, is drawn.
  - **Fix.** Make the query extent cover the frame, and guard it. For example, store the query extent in the bundle (an attribute) and `stopifnot(sf::st_covers(ext, sf::st_as_sfc(bb)))` in the map chunk, or compute the frame in the data script. Alternatively, reword the caption to the set the code draws ("within 8 km of the catchments"). The cut lines would still show, though.
  - **Rule:** writing.md "Check that each guard covers the set its sentence names"; writing.md "A caption names every mark the figure draws"; code-check-spatial.md "A raster's drawn footprint is its valid data, not its extent" (the same shape for vectors: the drawn frame is not the queried extent).

- **[severity: bug, minor]** vignettes/flow-departure-normal.Rmd:703–705: "[`cd`] takes the normal, the departures and the trends, with `Kendall` and `zyp` for the trend tests."
  - **What the code does.** `cd::cd_trend()` calls `Kendall::MannKendall(y)` for the test and `zyp::zyp.sen(y ~ yr)` for the Theil–Sen slope. `zyp` runs no test here.
  - **Why it matters.** The article's own trend paragraph (:621–627) keeps the slope (Theil–Sen) and the test (Mann–Kendall) apart, so this line misstates the role of `zyp`.
  - **Fix.** "with `Kendall` for the trend test and `zyp` for the slope".
  - **Rule:** writing.md "State each claim by the code's definition"; writing.md "Name, link and cite the software" ("a tool as a tool").

## Mechanism

**The shared assumption: a claim was checked against the instance in front of the author, and that instance stood in for the set the claim names.** It came in three variants:

- The data as it is today. Round 1's "From 2023, every bar…": the guard covered the low years' bars, not an unbroken run to the last year.
- The session as it is today. Round 1's `sort()`, which used the session's collation.
- The source the author remembered. Round 1's Stream Network credited for catchments; round 2's "partly provisional", which was never measured.

In each case the guard, or the author's check, tested membership in one direction. Something drawn, sorted or counted was confirmed to be consistent with the sentence. Nothing confirmed that the sentence's whole set was what the code produced. This round's map caption is the same shape:

- **The direction checked:** what is drawn is order ≥ 5.
- **The direction claimed:** order ≥ 5 within the frame is drawn.

This round's `zyp` line has the same root as round 1's Stream Network credit: the role was attributed from a package's general reputation, not from the call the code makes.

**Where the mechanism reaches** (each was walked in the enumeration below):

1. Every inline number and quantifier in the prose and the limits ("every", "both", "all of them", "from <year>", "some", "no window").
2. Every caption's description of its marks and of the set they cover: the map, the bars, the hydrograph, the heat strip and the trend figure.
3. Every attribution in "Software and citation" and the Data list, each checked against the call or query that produces it.
4. Every artifact a script writes:
   - the `.bib`: its order and the shape of its entries, where `vignette_bib.R`'s regexes are keyed to today's Better BibTeX output;
   - `station_map.rds`: its layers, its query extent and the town filter.
5. Thresholds and folds taken over a set: `hydat_end` is the maximum over both stations, `med_range` covers all six panels, and `q10` uses type-7 quantiles over 18 baseline years at 08EE003.

## Enumeration

Every factual claim in the rendered article (docs/articles/flow-departure-normal.html, current with HEAD) and the Rmd. The numbers were re-derived by purling the Rmd into the scratchpad and running it against the installed wet 0.4.30, whose bundle md5s equal `inst/vignette-data/`.

| claim (short) | set and precision it names | guard or source (Rmd line) | covers? |
|---|---|---|---|
| Title: "Departed from Its 1981–2010 Normal: A Case Study" | baseline is 1981–2010 | :99 `identical(baseline, 1981:2010)` | yes (08EE003's 1981–1998 is an accepted tradeoff) |
| `wet` measures stream flow and water temperature on BC's Freshwater Atlas | the package's scope | package DESCRIPTION title | yes |
| two gauges near Houston | both gauges < 10 km from Houston's GNS point | :389–390 (280 m, 4.6 km) | yes |
| "summer flow, in the weeks when chinook salmon migrate, spawn and move downstream as fry" | the three windows, May 1 – Sep 15 | :60, :89–90 | loosely: the migration window opens on May 1, which is spring. Colloquial, not flagged |
| 1981–2010 is one of the 30-year periods WMO sets for climate normals | Arguez and Vose 2011, p. 699 | citation; checked against the PDF (accepted tradeoff) | yes |
| below normal in every timing window at both gauges in 2023–2026 | all 6 bars in each low year < 100 % | :227, :230, :233 | yes |
| 21 of those 24 window means drier than nine 1981–2010 years in ten | low-year bars with value < q10 (type 7) | :238–240 (n_dec = 21, n_low = 24) | yes (round 2: the empirical definition also gives 21) |
| 2022 was above normal in some windows | the one up year with ≥ 1 bar ≥ 100 % | :245–248 (4 of 6 bars above) | yes |
| Of 24 trends since 1981 and since 2000, 2 pass the test | `nrow(tr)`, mk_pvalue < 0.05 | :279–281 | yes |
| all of them downward | the significant slopes are all < 0 | :281–288 (n_neg = 2 of 2) | yes |
| about as many as chance alone would | \|n_sig − 0.05·24\| ≤ 1 | :294 | yes |
| At 08EE003 the normal rests on 1981–1998, the years with enough record | 08EE003's baseline years, the same in every window | :166–171 | yes |
| timing window = the part of the year a life stage is in the stream | definition | none needed | n/a |
| adults migrate upstream May 1 – Aug 1; spawn Aug 1 – Sep 15; fry move downstream Jul 15 – Sep 7 | the CH rows of the table | :60, :89–90; the life stages migration, spawning, fry_migration | yes |
| the dates come from New Graph's table for the Bulkley, which cites Gottesfeld and Rabnett (2007) | all 3 rows' `source` | :93 | yes |
| the table's other 2 chinook windows, incubation and emergence, reach into Nov–Apr, so they are left out | CH rows that touch Nov–Apr | :50–62 (`out` = incubation, emergence) | yes |
| a window's flow is its mean daily flow, counted when 80 % of its days have a record | `wet_window_stats(min_frac = 0.8)`, `nd/len < min_frac` drops | :86; R/wet_window_stats.R:183 | yes |
| 100 % is normal and lower is drier; the dashed line marks the median year | the plot's definition | :209, :347 | yes |
| a typical year sits under the mean | every median < 100 % as printed | :252–254 (64–96 %) | yes |
| From 2023, every bar falls below the median year as well as the mean | low years unbroken to the last year; every low bar < its median | :230, :244 | yes |
| 6 were drier than any 1981–2010 year | low bars with value < the baseline minimum | :241–242 | yes |
| the two gauges fall on the same side of normal in every window and year | kr (recent years), per window and year | :249–251 | yes |
| partly because one catchment holds the other | Buck's catchment ≥ 99 % inside 08EE003's | :385–387 | yes |
| Bar caption: % of the 1981–2010 mean (solid line, m³/s top right) | `ref$label`, the hline at 100 | :223, :346–355 | yes |
| bars labelled with %, coloured below/above, paler where any day is provisional | `pct()`, `side`, `status` = frac_provisional > 0 | :209–211 | yes |
| At 08EE003 the normal rests on 1981–1998: no window in 1999–2010 has 80 % of its days | `miss_003`, the same years in every window | :166–171 | yes |
| Both gauges are near Houston | as above | :389–390 | yes |
| Buck Creek joins the Bulkley River in the town | `into1` from the watershed code; mouth < 2 km from Houston | :397–398 (0.89 km) | yes |
| the Bulkley gauge sits downstream of its mouth, so it measures Buck Creek's flow | containment | :385–387 | yes |
| Buck Creek drains 24 % of the area above it | ratio of the FWA catchment areas | :382–383 (567 / 2,315) | yes |
| The Bulkley joins the Skeena River at Hazelton | `into1` = Skeena River; mouth < 2 km from Hazelton | :397–399 (1.15 km) | yes |
| about 120 km north-west of Houston | town-to-town distance rounded to 10 km; 45° bins | :401–405 (116 km, 326°) | yes |
| Map caption: two gauges (points), the land each drains (shaded) | layers drawn | :468–481 | yes |
| Buck's catchment (567 km²) lies inside the Bulkley gauge's (2,315 km²), so the records are not independent | containment, areas | :385–387, :458–459 | yes |
| the Bulkley River and Buck Creek drawn heavy | `streams$main` = the two blue lines | vm_streams `sum(main) == length(blk)` | yes |
| **other streams of order 5 and up thin, lakes of 100 ha and up in blue** | every such feature in the frame | :407 checks drawn ⊆ class only; the query extent covers 63.5 % of the frame | **no**: Finding 1 |
| Houston is labelled; the bar is 30 km; the inset places the map in BC | `pl_lab`, `sb_km`, keymap | :430, :438, :443–448 | yes |
| Hydrograph text: the same five years against the middle half of 1981–2010 flows each day | band quartiles over the baseline years | :525–531 | yes (08EE003's band is 1981–1998: accepted) |
| Hydrograph caption: May–Oct, 2022–2026, one line per year, broken where a day has no record | full day grid merged with NA | :514, :532–537 | yes |
| median day (grey line) and middle half (band), drawn only on days with ≥ 10 years | `band$n >= min_baseline` | :531 | yes ("grey" is the registry's #636363, round 2) |
| the timing windows run beneath as bars; log scale | strip segments; `scale_y_log10` | :544–573 | yes |
| (implicit) no zero flows in May–Oct | | :516–517 | yes |
| Every year since 1981; 08EE003 has no window with 80 % of its days in 1999–2010 | `gap` = years with no stats row at 08EE003 | :597; non-empty because `miss_003` ⊆ `gap` (:171) | yes |
| Heat caption: one cell per window and year, coloured by class; blank cells have under 80 % of their days, or none | stats keep only window-years ≥ min_frac; no NA anomaly rows | :591–596 (measured: 0 NA rows) | yes |
| trend = yearly change in departure, in percentage points of the mean | `cd_trend()` on the anomaly (pct_normal) | :198; round 2 | yes |
| negative is drying | sign of the slope on flow departure | definition | yes |
| Theil–Sen slope = median of the slopes between every pair of years | `zyp::zyp.sen` | cd source | yes |
| Mann–Kendall p = the chance of a trend at least that consistent if flow had none | `Kendall::MannKendall` | cd source | yes |
| Of 24 slopes, 2 have p < 0.05, all downward, about what chance gives (1) | as above; round(1.2) = 1 | :279–294 | yes |
| tests not independent: the windows overlap, and one gauge drains into the other | fry migration ∩ spawning days > 0; containment | :290–292, :387 | yes |
| At 08EE003, "from 2000" starts in 2011 | first year of each fitted series ≥ 2000 | :296–299 | yes |
| Trend caption: filled where p < 0.05, hollow otherwise; one colour per start; vertical line = no trend | `scale_shape_manual`, `pal_trend` | :633–640 | yes |
| These calls produced the window statistics; normal, departure and trend from `cd` | recipe = the article's calls with literal windows | :89–90 pin the dates; window names from the life stages | yes (the recipe's default HYDAT is the user's latest, not the pinned release; pre-existing) |
| They read HYDAT, the water-temp-bc archive and ECCC's real-time feed (through `tidyhydat`) | `wet_station_daily()`'s sources | R/wet_station_daily.R:192 `tidyhydat::realtime_ws` | yes |
| Limits: approved HYDAT flows end in March 2025 | max hydat date over both stations | :673 (2025-03-04 and 2025-03-02) | yes today; the guard takes the maximum over both stations, not each station's end |
| so 2 of the five years rest on provisional flows | years with provisional bars; every bar in them provisional | :674–678 (frac = 1 in 2025 and 2026) | yes |
| 3 of the 30 bars rest on 80 %–91 % of their days: 08EE003 in 2025 (all three windows) | `part` | :256–262 | yes |
| a year is left out of a normal when the window has under 80 %; Buck lacks 1984 in spawning and fry migration; 08EE003 lacks 1999–2010 in every window | `miss_text` from `qb` | :173–186 | yes |
| windows from the literature; the table cites G&R for all three; fry migration's citation carried over from a neighbouring watershed's row | `source`; note "citation listed under the other area" | :93–95; knowledge holds only BULK and MORR, and the Morice neighbours the Bulkley | yes ("neighbouring" is pre-existing; the other area is MORR) |
| flows cached from HYDAT release 2026-07-17; provisional/real-time retrieved 1 Oct 2026; windows at knowledge c97c4d0 | bundle provenance | `prov` | yes |
| catchments, stream mouths and the rivers they join are the Freshwater Atlas's | vm_catchments (`fwa_watershedatmeasure`), vm_into (fwa_stream_networks_sp) | scripts/vignette_map_lib.R | yes |
| `wet` reads the gauge records and makes the timing-window statistics | `wet_station_daily`, `wet_window_stats` | :155 | yes |
| `cd` takes the normal, departures and trends | `cd_baseline`, `cd_anomaly`, `cd_trend` | :194–198 | yes |
| **with `Kendall` and `zyp` for the trend tests** | `zyp` gives the slope, not a test | cd source | **no**: Finding 2 |
| `tidyhydat` reads the ECCC real-time feed | `realtime_ws` | R/wet_station_daily.R:192 | yes |
| `fwapg` holds the FWA in PostgreSQL, from which the catchments and stream mouths were drawn | `fwa_indexpoint`, `fwa_watershedatmeasure` (both upstream smnorris/fwapg) | vignette_map_lib.R | yes (streams, lakes and the outline also came from it; incomplete, not false) |
| `ggplot2`, `gq`, `sf` make the figures and map; `knitr`, `bookdown` render; all in R | calls in the article | :26–28, :112, output format | yes |
| This build ran on wet 0.4.30, cd 0.6.11, gq 0.16.0 (commit when recorded) | `packageVersion`, a 40-hex RemoteSha | :717–721 | yes (accepted) |
| `citation("wet")` with concept DOI 10.5281/zenodo.23305781 | printed from inst/CITATION | :723 | yes |
| Data: daily flow from WSC's HYDAT [ECCC 2021], release 2026-07-17 | bundle | `prov$hydat` | yes |
| Data: provisional and real-time flow, ECCC records archived by water-temp-bc, and its real-time feed | `wet_station_daily` sources | as above | yes |
| Data: timing windows, New Graph's table [G&R 2007] | as above | :93 | yes |
| Data: streams and stream mouths, FWA Stream Network through DataBC [FLNRORD 2021] | `fwa_stream_networks_sp` | vm_streams, vm_into | yes |
| Data: catchments, lakes, province outline from the FWA's watersheds, lakes and boundary, same publisher | `fwa_watershedatmeasure`, `fwa_lakes_poly`, `fwa_bcboundary` | vm_catchments, vm_lakes, vm_bc | yes |
| Data: place names, BC Geographic Names through DataBC | `bcdata` GNS_GEOGRAPHICAL_NAMES_SP | vm_places | yes |
| Data: gauge locations from HYDAT's station table | `vm_stations(hydat, …)` → `vm_points` | data-raw/station_vignette_map.R:9 | yes |
| References: Theil 1950, Sen 1968, Mann 1945, Kendall 1975 for the slope and test | cited for definitions | no page given (writing.md "Cite the page that says it"); not false | yes (no pin cite) |
| word cap 700 | body prose to "Software and citation" | :746–762 (699, per the author) | yes |

The other code checked and found clean:

- vignette_bib.R: radix sort; the package/literature split; the missing-key stop; the local-path refusal.
- vm_into(): the SQL is moved verbatim, and the rows come back in the given order.
- The town lookup: within 15 km of the mouths, by feature type, with `setequal` and `nrow == 2`.
- The mouths lie on the receiving river's centreline (code-check-spatial.md), and the 2 km tolerance absorbs that.
- No duplicate chunk labels.
- The _pkgdown.yml redirect and the README link.
