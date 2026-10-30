# Code check, round 5 (#145): terminal enumeration of every figure mark (HEAD 3a211e4)

## Checklist read

- Index (`checklist.txt`): headings read for all four files. Full sections bearing on drawing were judged from their index lines: code-check-spatial "`geom_sf(data = NULL)` draws nothing, silently", "sf: `st_intersection()` / `st_difference()` return a GEOMETRYCOLLECTION…", "A raster's drawn footprint is its valid data, not its extent"; code-check-r "ggplot2 legends and labels…"; code-check.md "A proxy is not the property", "A guard's scope, escape hatches, and remedies", "One fact derived twice".
- writing.md: the three rules the brief names, applied mark by mark below.
- Method: the article was purled into a temp dir (scratchpad `r5/`) and run against the installed `wet`, whose `station_map.rds`, `station_daily.rds`, `life_history_bulk.csv` and `wet_station.csv` are byte-identical (md5) to the source tree at HEAD. The five PNGs in `docs/articles/flow-departure-normal_files/figure-html/` were viewed; `map-1.png` (mtime 10:30:04 PDT, commit 10:30:17) was also composited onto white, because 59% of its pixels are transparent.

## Findings

No caption or prose sentence beside a figure is false on today's data, and round 4's fix holds (section "Round 4's fix" below). Two low-severity guard gaps remain, both in the direction the rounds converged on: a sentence that names a set, with a guard narrower than the claim.

- **[severity: low]** vignettes/flow-departure-normal.Rmd:411–417 (the cut), caption :465–466. The caption names two marks, thin streams and lakes. Nothing guards that the cut leaves them drawable and present.
  - `cut_near()` drops empty results. Data-raw selects by `ST_Intersects` with the same box, so a line or lake that only touches the box edge would be cut to a POINT or a LINESTRING, or to a GEOMETRYCOLLECTION. `geom_sf()` would draw a POINT as a dot in the stream colour, which is a mark the caption does not name. And if a layer came back with zero rows, `geom_sf()` draws nothing, silently, while the caption still names it.
  - Today both layers are clean: 27 of 27 thin streams survive, all LINESTRING; 19 of 19 lakes survive, all POLYGON; no row was dropped.
  - Suggested guard, after :417:
    `stopifnot(nrow(thin_streams) > 0, nrow(lakes_near) > 0, all(sf::st_geometry_type(thin_streams) %in% c("LINESTRING", "MULTILINESTRING")), all(sf::st_geometry_type(lakes_near) %in% c("POLYGON", "MULTIPOLYGON")))`
  - Rules: writing.md "Check that each guard covers the set its sentence names"; code-check-spatial "`geom_sf(data = NULL)` draws nothing, silently" (the zero-row form); code-check-spatial "sf: `st_intersection()` … return a GEOMETRYCOLLECTION…".

- **[severity: low]** vignettes/flow-departure-normal.Rmd:238–240 (guard), opening :316–317. The opening says "21 of those 24 window means were drier than nine 1981–2010 years in ten". The count is `value < q10`, a type-7 quantile, and the only guard is `n_dec > 0`. At 08EE003 there are 18 baseline years, so q10 is interpolated between the 2nd and 3rd driest years. A bar can therefore be counted while it is drier than only 16 of 18 years (88.9%).
  - Today the definitions agree. I measured every one of the 24 low bars: every bar counted is drier than at least 93.1% of its baseline years, and no bar left out is drier than 90% or more. Round 3 recorded the same equality.
  - It is still a measured equality, not a guard. A rebuild of `station_daily.rds` (provisional flows are revised) can separate the two definitions with nothing failing.
  - Suggested guard: compute each bar's share of baseline years wetter than it, and assert `n_dec == sum(share >= 0.9)`, or count with that share directly.
  - Rules: code-check.md "A proxy is not the property"; writing.md "State each claim by the code's definition".

Not findings (checked, noted for the record):

- The heat strip's legend labels come from the registry (`wet_station.csv` d1–d8, unchanged on this branch). Its breaks are typed at :605 (`c(-Inf, -75, -50, -25, 0, 25, 50, 100, Inf)`). They agree, including the right-closed edges: "75% or more below" is (−∞, −75], and "More than 100% above" is (100, ∞).
  - This is one fact derived twice with no guard. It predates this branch and is not in its diff, so it is not raised as a finding.
- The map PNG has a transparent ground. The scale bar and "30 km" are black on transparent. They show on pkgdown's white page (bootstrap 5, no light-switch), but would vanish on a dark viewer. Composited onto white, they sit in the lower right, clear of every lake and stream: the bar is at y = 995,318, below the box edge at y = 1,002,986.

## Round 4's fix

(a) **The drawn layers lie within the box.** Checked from the article's own objects in the temp-dir run:

- `sf::st_difference(st_union(thin_streams), near)` has length 0 m, and `st_difference(st_union(lakes_near), near)` has area 0 m².
- `st_covered_by(·, st_buffer(near, 1))` is TRUE for every thin stream and every lake.
- `near` equals data-raw's `vm_extent(catch, 8000)` recomputed from the bundle's catchments (`all.equal` on the bboxes), so the selection box and the cut box are one box. No feature can be selected in one and missed by the other.
- In the white-composited map, François Lake (bottom right) and the thin streams now stop at a straight edge, and Babine Lake no longer reaches the top-right corner past the box. The frame is 3,102 km² larger than the box. On the left, right and bottom, the strips beyond the box hold only the heavy Bulkley and nothing thin or blue, which is what the caption says.

(b) **The cut leaves drawable geometry.** It yields LINESTRING ×27 and POLYGON ×19, drops no row, and leaves no GEOMETRYCOLLECTION or POINT. It is not guarded against either case on a refresh (Finding 1).

(c) **The map caption's other claims:**

| claim | source / guard | verdict |
|---|---|---|
| Buck Creek's catchment lies inside the Bulkley gauge's | `inside / area > 0.99` at :385–387; measured 0.99993 | guarded |
| 567 km² and 2,315 km² | `catch$area_km2`, the bundle attribute; `st_area` gives 566.69 and 2,314.90, within 0.04% | from the data |
| Houston is labelled | `pl_lab` from `map$places$name`; the bundle holds one place, "Houston"; data-raw selects by that name and asserts `nrow(places) == 1` (data-raw/station_vignette_map.R:54–55) | from the data, guarded at build |
| the bar is 30 km | `sb_km = max(gq_scale_breaks(bb))`, which also sets the drawn length (`sb_km * 1000` in EPSG:3005, which is metres; every layer is EPSG:3005) and the label | from the data, one variable for bar, label and caption |
| the inset places the map in British Columbia | the keymap draws `map$bc` and the rectangle `st_as_sfc(bb)`, which is the frame itself; `bb` lies within `map$bc` (measured TRUE) | from the data |
| the Bulkley River and Buck Creek are drawn heavy | `main_streams` = `map$streams$main`, exactly two rows: blue_line_key 360873822 "Bulkley River" and 360886221 "Buck Creek"; data-raw asserts `sum(main) == 2` | from the data (the two heavy branches meeting at the catchment's east edge are both the Bulkley's blue line) |
| other streams of order 5 and up (thin) | guard :407 (drawn ⊆ order ≥ 5); the converse (every order-5+ stream in the box is drawn) holds because selection and cut use one box | covered |
| lakes of 100 ha and up (blue) | guard :407 (drawn ⊆ ≥ 100 ha); the converse holds by the same one box; the lake fill is #dcecf4 with stroke #1f78b4 | covered |

## Enumeration

### Figure 1: recent bars (`recent`, :342–374; caption `cap_recent`, :264–271)

| mark | what it draws (set, cut, filter) | caption phrase | exact? |
|---|---|---|---|
| `geom_col` | `kf`: q_mean window means, the five recent years × 3 windows × 2 stations (30 bars, `stopifnot` at :208), as % of the baseline mean | "Mean flow in each chinook timing window, 2022–2026, as a percentage of its 1981–2010 mean" | yes |
| fill = `side` | `pct < 100` is below, otherwise above | "coloured by whether it falls below or above the mean" | yes (no bar equals 100) |
| alpha = `status` | `frac_provisional > 0` is provisional (0.45) | "paler where any of its days are provisional" | yes; "any" = `> 0` |
| `geom_hline` solid | y = 100 per panel | "its 1981–2010 mean (solid line…)" | yes |
| `geom_hline` dashed ("22") | `100 * median(v) / mean(v)`, v = the baseline window means | "The dashed line is the median 1981–2010 year" | yes |
| `geom_text` above bars | `pct(pct)`, rounded absolute % | "Each bar is labelled with its percentage" | yes (pct ≥ 0) |
| `geom_text` top right | `ref$label` "Mean X m³/s", signif 2, at x = 2026.45, y = ymax | "given in m³/s at the top right of each panel" | yes |
| facets | station × window, strips carry the window dates | (implicit) | yes |
| fill, alpha and linetype legends | registry labels; alpha keys drawn in the below colour | same terms as the caption | yes |
| y scale | 0 to 1.2 × max | "as a percentage" | yes |
| 08EE003 note | `base_003` = 1981–1998, `miss_003` = 1999–2010, computed | "the 1981–2010 normal rests on 1981–1998: no window in 1999–2010 has 80% of its days" | yes (accepted title tradeoff) |

Prose beside it (:334–340):
- "100% is normal and lower is drier": yes.
- "a typical year sits under it; the dashed line marks the median year": guarded, `round(max median_pct) < 100`, measured 64–96%.
- "From 2023, every bar falls below the median year as well as the mean": guarded at :230 and :244.
- "3 were drier than any 1981–2010 year": `value < q_min`, exact; guarded > 0.
- "same side of normal in every timing window and year": guarded at :251, over the five years drawn.
- "one catchment holds the other": the map guard.

Opening (:315–320):
- "below normal in every timing window at both gauges in 2023–2026": guarded at :227–233.
- "21 of those 24 … nine years in ten": Finding 2.
- "2022 was above normal in some windows": guarded at :248.
- "2 pass the trend test, all of them downward, about as many as chance": guarded at :294.
- 08EE003's "1981–1998": computed.

### Figure 2: map (`map`, :477–512; caption `cap_map`, :462–469)

| mark | what it draws | caption phrase | exact? |
|---|---|---|---|
| `geom_sf` catch, fill = part | two catchment polygons: 08EE003 beneath (light), 08EE013 on top (darker); grey outline | "the land each one drains (shaded)" | yes |
| `geom_sf` `lakes_near` | FWA lakes ≥ 100 ha intersecting the 8 km bbox, cut to it (19) | "lakes of 100 ha and up (blue) are drawn only near the catchments" | yes (fix verified) |
| `geom_sf` `thin_streams` | blue lines with order ≥ 5 segments in the box, not main, cut to it (27) | "other streams of order 5 and up (thin) … drawn only near the catchments" | yes |
| `geom_sf` `main_streams`, heavy | the whole Bulkley River and Buck Creek blue lines | "The Bulkley River and Buck Creek are drawn heavy" | yes |
| `geom_label` `pl_lab` | "Houston", 0.035·dy below the town point; the town point itself is not drawn | "Houston is labelled" | yes |
| `geom_sf` stations, shape 21 | 08EE013 and 08EE003 | "The two gauges (points)" | yes |
| `geom_label` `st_lab` | the station names with numbers | (the gauges' names; the caption names both) | yes |
| `geom_segment` with `geom_text` | scale bar of `sb_km` = 30 km, labelled | "the bar is 30 km" | yes |
| `annotation_custom` keymap | BC outline (parts ≥ 2,000 km²) with the frame rectangle | "the inset places the map in British Columbia" | yes |
| legends (shape, colour, fill) | station, heavy streams, two catchment classes | consistent | yes |
| `coord_sf` frame | `bb`: catchments + 3 km, extended down 22%, set to aspect | (the empty strips beyond the box) | yes; the caption says the thin and blue layers are drawn only near the catchments |

Prose beside it (:472–475):
- "Both gauges are near Houston": guarded, < 10 km.
- "Buck Creek joins the Bulkley River in the town": guarded, `into1` and mouth < 2 km.
- "the Bulkley gauge sits downstream of its mouth, so it measures Buck Creek's flow": the containment guard.
- "Buck Creek drains 24%": the area ratio.
- "joins the Skeena River at Hazelton": guarded.
- "about 120 km north-west of Houston" (hz_km, hz_dir): computed.

### Figure 3: hydrograph (`hydrograph`, :572–596; caption `cap_hydro`, :563–567)

| mark | what it draws | caption phrase | exact? |
|---|---|---|---|
| `geom_ribbon` | quartiles 25–75 of approved days in the station's baseline years (qb), May 1 – Oct 31, days with n ≥ 10 | "middle half (band)", "1981–2010", "drawn only on days with at least 10 years" | yes; every season day has n ≥ 13 (08EE003) and ≥ 29 (08EE013), so the ribbon bridges no gap |
| `geom_line` median | the median of the same | "median day (grey line)" | yes (#636363) |
| `geom_line` by year | daily q over 2022–2026, merged with the full-season grid, so NA breaks the line | "one line per year, broken where a day has no record" | yes |
| `geom_segment` strips | the three windows as bars below the floor | "The chinook timing windows run beneath as bars" | yes |
| `geom_text` | the window names | (same) | yes |
| log y, breaks above the strips | `scale_y_log10` | "Log scale." | yes |
| x axis | May–Oct, with 45 days of room on the left for labels | "May to October" | yes |
| colour and fill legends | year colours from the registry; "1981–2010 median", "1981–2010 middle half" | yes | yes |

Prose beside it (:570): "The same five years, day by day, against the middle half of 1981–2010 flows on each day": yes.

### Figure 4: heat strip (`heat`, :617–627; caption `cap_heat`, :608–611)

| mark | what it draws | caption phrase | exact? |
|---|---|---|---|
| `geom_tile`, fill = class | q_mean window-years from 1981 to 2026 that `wet_window_stats()` returned (no row under min_frac: measured 0 such rows, 0 NA values), joined to the anomaly (0 NA) | "one cell per window and year, coloured by class"; "How far … above or below its 1981–2010 mean, in %" | yes |
| absent tiles | 41 window-years: 08EE003 1999–2010 (36), 08EE013 1984 spawning and fry (2), and 2016 (3) | "Blank cells have under 80% of their days, or none" | yes |
| white tile borders | | | n/a |
| legend d1–d8 | registry labels matching the :605 breaks | yes | yes (not guarded; pre-existing, see above) |
| facets | per station | | yes |

Prose beside it (:614–615): "Bulkley River near Houston has no window with 80% of its days in 1999–2010": `gap` computed, exact.

### Figure 5: trend (`trend`, :642–653; caption `cap_trend`, :300–305)

| mark | what it draws | caption phrase | exact? |
|---|---|---|---|
| `geom_vline` x = 0 | | "the vertical line is no trend" | yes |
| `geom_point`, colour = trend_start | 24 slopes (2 stations × 3 windows × 2 statistics × 2 starts), with 0 NA slope and 0 NA p | "one colour for the trend from 1981, another for the trend from 2000" | yes |
| shape = sig (16 filled, 1 hollow) | `mk_pvalue < 0.05` | "filled where the Mann–Kendall p is below 0.05 and hollow otherwise" | yes |
| facets: station × variable | window mean (left), lowest 7-day mean (right) | "for the window mean (left) and its lowest seven-day mean (right)" | yes |
| x axis | cd_trend slope of the % anomaly | "Theil–Sen slope … in percentage points of the 1981–2010 mean per year" | yes (cd uses zyp.sen, round 4) |
| legends | "Since 1981/2000", "p < 0.05 / p ≥ 0.05" | yes | yes |

Prose beside it (:631–640):
- "Of 24 slopes, 2 have p below 0.05, all of them downward, about what chance alone gives (1)": computed; guarded within 1.
- "the timing windows overlap": guarded, `shared > 0`.
- "one gauge drains into the other": the map guard.
- "'from 2000' starts in 2011": `start_003`, guarded `> 2000`.
