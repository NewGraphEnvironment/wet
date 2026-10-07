# Mean Annual Discharge per Segment

wet gives every stream segment of British Columbia’s Freshwater Atlas a
mean annual discharge: the average flow, in cubic metres per second,
over 1981–2010. This article explains what that number is, which of
wet’s two estimates to use, how close it comes to measured flow, and
where it is weakest.

## What mean annual discharge is

A stream’s mean annual discharge is the volume of water that passes a
point in an average year, spread over the seconds in that year. It comes
from **runoff**: the depth of water, in millimetres a year, that the
land upstream yields to the stream once rain and snow have met
evaporation and plant use. Spread that depth over the area upstream and
it becomes a volume. A 100 km² basin yielding 300 mm a year passes about
0.95 m³/s: 0.3 m over 100 million m² is 30 million m³ a year, and a year
is 31.5 million seconds. Runoff in mm compares basins of any size;
discharge in m³/s is what a stream carries.
[`wet_mm_to_m3s()`](https://newgraphenvironment.github.io/wet/reference/wet_mm_to_m3s.md)
converts one to the other.

The terms used below:

- **[Freshwater
  Atlas](https://www2.gov.bc.ca/gov/content/data/geographic-data-services/topographic-data/freshwater)**
  (FWA): BC’s mapped stream network. A *segment* is one piece of a
  stream line. Each segment drains a small *watershed* polygon, and the
  province is split into 246 *[watershed
  groups](https://catalogue.data.gov.bc.ca/dataset/freshwater-atlas-watershed-groups)*,
  such as the Salmon River and the Bulkley River below.
- **[Stream order](https://en.wikipedia.org/wiki/Strahler_number)**: 1
  for a headwater stream, rising by one where two streams of the same
  order meet. The maps here draw order 3 and up.
- **[HYDAT](https://www.canada.ca/en/environment-climate-change/services/water-overview/quantity/monitoring/survey/data-products-services/national-archive-hydat.html)**:
  the Water Survey of Canada’s archive of flow measured at gauges. A
  *calibration gauge* is one of the 290 HYDAT gauges the water balance
  is fitted and scored on.
- **[PCIC hydrologic model
  output](https://services.pacificclimate.org/portal/hydro_model_out/map/)**:
  runoff and baseflow from the Pacific Climate Impacts Consortium’s
  VIC-GL model, on a grid of 0.0625° cells. It covers the Peace, Fraser
  and Columbia.
- **[fwapg](https://github.com/smnorris/fwapg)**: an open database
  toolkit for the Freshwater Atlas. It publishes a mean annual discharge
  per segment from PCIC’s output, and “fwapg” below means that estimate.
- **Open water balance**: wet’s own estimate, after [Chapman et
  al. (2018)](https://www2.gov.bc.ca/assets/gov/environment/air-land-water/water/northeast-water-strategy/chapman_et_al-2018-jawra.pdf),
  the method behind the province’s [water
  tools](https://www2.gov.bc.ca/gov/content/environment/air-land-water/water/water-science-data/water-data-tools).
  Precipitation less evapotranspiration per grid cell is averaged
  upstream, then adjusted by hydrologic zone against HYDAT gauges. Its
  code and inputs ship with wet.
- **[Hydrologic
  zone](https://catalogue.data.gov.bc.ca/dataset/bc-hydrologic-zones)**:
  one of BC’s 29 regions of similar runoff. The balance fits one
  adjustment per zone.
- **Held out**: scored at a gauge the fit did not see. wet holds out
  each Water Survey sub-sub-drainage in turn (the first four characters
  of a station number, such as 08EE), fits on the rest, and predicts the
  gauges it held out. This is *blocked cross-validation*: whole blocks
  are held out, so a gauge’s neighbours on the same river cannot vouch
  for it.
- **Headwater and nested gauges**: a nested gauge’s basin holds another
  gauge’s; a headwater gauge’s does not.
- **Error**: modelled minus observed runoff, as a percentage of
  observed. One scale runs through every figure: more than 20% under,
  0–20% under, 0–20% over, more than 20% over.

## Which estimate to use

**Use wet’s open water balance everywhere, and read fwapg beside it
where fwapg has a value.** Two reasons favour the balance, and one
favours fwapg.

The balance covers the province. fwapg covers 112 watershed groups in
the Peace, Fraser and Columbia. Even there it skips the largest rivers:
of the 13,883 segments of order 8 and up, the Fraser and Thompson among
them, it gives a value on 38.

The balance’s code and inputs ship with wet, so a wrong value can be
traced to its cause and fixed in the open. fwapg republishes PCIC’s
model output, which wet can reproduce but not re-run.

fwapg is the closer of the two where both can be scored. At the 168
calibration gauges with a fwapg value, its mean absolute error is 25.5%
against the balance’s 30.5%. The two numbers are not quite like for
like. The balance’s is out of sample, and slightly optimistic, because
its final variant was chosen after its first failed. Some of fwapg’s may
be in sample: PCIC calibrated VIC-GL over 1985–2005, and which gauges it
was calibrated on is not published with fwapg’s values. The comparison
also leaves out the 18 gauges in PCIC’s groups where fwapg has no value,
mostly large rivers, where the balance does best. So where fwapg has a
value and the two disagree, check the nearest gauge before trusting
either. A rule set before this comparison was run would reopen the
recommendation if the balance were more than 5 points worse. It is 5.03
points worse, just past that line, and the recommendation stands on the
first two reasons.

![Held-out error of the water balance against fwapg's error, at the 168
calibration gauges where fwapg has a value. The shaded square holds the
gauges both products put within ±20%. Between the dashed diagonals, the
left and right wedges hold gauges where the balance is closer, the top
and bottom wedges those where fwapg is. 2 gauges beyond +200% are drawn
at the edge.](segment-discharge_files/figure-html/compare-1.png)

Held-out error of the water balance against fwapg’s error, at the 168
calibration gauges where fwapg has a value. The shaded square holds the
gauges both products put within ±20%. Between the dashed diagonals, the
left and right wedges hold gauges where the balance is closer, the top
and bottom wedges those where fwapg is. 2 gauges beyond +200% are drawn
at the edge.

| Gauges | n | Error, balance | Error, fwapg | Within ±20%, balance | Within ±20%, fwapg |
|:---|---:|---:|---:|---:|---:|
| All | 168 | 30.5% | 25.5% | 48% | 60% |
| Headwater | 134 | 33.4% | 28.7% | 44% | 55% |
| Nested | 34 | 19.0% | 12.6% | 62% | 76% |
| Peace | 21 | 19.6% | 14.2% | 62% | 90% |
| Fraser | 73 | 29.4% | 28.8% | 41% | 45% |
| Columbia | 74 | 34.7% | 25.4% | 50% | 65% |

Mean absolute error and share of gauges within ±20% for each product, at
the 168 calibration gauges where both have a value, by gauge type and by
basin. {.table}

## How close it is, province-wide

Out of sample, the balance’s annual runoff at a gauge is off by 28% on
average, and 51% of gauges fall within ±20%. It does better on larger
rivers. Nested gauges average 17% against 31% for headwater ones, and
basins over 1,000 km² average 21% against 43% for those under 100 km².
One zone stands out: zone 24, the Southern Thompson Plateau, a semi-arid
interior plateau, where the 8 gauges average 102%.

![The 290 calibration gauges, filled by the water balance's held-out
error at each. PCIC's coverage, where fwapg also has values, is
outlined; zone 24, the weakest, is shaded; the two groups mapped below
are in black.](segment-discharge_files/figure-html/map-province-1.png)

The 290 calibration gauges, filled by the water balance’s held-out error
at each. PCIC’s coverage, where fwapg also has values, is outlined; zone
24, the weakest, is shaded; the two groups mapped below are in black.

![Held-out error at the 290 calibration gauges, in classes of 10%,
coloured by the error scale. Gauges beyond +200% are counted in the last
bar.](segment-discharge_files/figure-html/hist-1.png)

Held-out error at the 290 calibration gauges, in classes of 10%,
coloured by the error scale. Gauges beyond +200% are counted in the last
bar.

## Salmon River: two estimates side by side

Both products cover the Salmon River, a headwater group of the Fraser
(1,794 km²), and they disagree there. The open water balance gives a
median 1.47 times fwapg’s value per segment. The 5 gauges in and around
the group show where each misses.

The balance runs high at all of them, by +6% to +38%. At the 2 smallest
basins, fwapg is within 5%, so the gap there is the balance’s. At the 3
larger ones, fwapg runs −14% to −25%, and the two share the gap. At
08KC001, the gauge that drains the whole group, they bracket the
observation: +38% against −25%.

| Gauge | Area (km²) | Observed (mm) | Water balance (held out) | fwapg |
|:---|---:|---:|---:|---:|
| 08KC001 Salmon River near Prince George | 4,227 | 205 | +38% | −25% |
| 08KC003 Muskeg River north of Joanne Lake | 297 | 224 | +35% | −2% |
| 08JE004 Tsilcoh River near the Mouth | 439 | 180 | +34% | −1% |
| 07ED001 Nation River near Fort St. James | 4,356 | 401 | +6% | −14% |
| 08JE001 Stuart River near Fort St. James | 14,235 | 285 | +11% | −17% |

Calibration gauges within 30 km of the Salmon River group, and its
outlet gauge (first row): mean annual runoff observed in 1981–2010, and
each product’s error against it. {.table style="width:100%;"}

![Mean annual discharge on 2,180 of the 2,181 Salmon River segments of
order 3 or more, from fwapg (left) and the open water balance (right),
with the gauges of the table filled by each product's error. Rivers
outside the group are
grey.](segment-discharge_files/figure-html/map-salr-1.png)

Mean annual discharge on 2,180 of the 2,181 Salmon River segments of
order 3 or more, from fwapg (left) and the open water balance (right),
with the gauges of the table filled by each product’s error. Rivers
outside the group are grey.

## Bulkley River: the water balance alone

fwapg has no values in the Bulkley River, in the Skeena (7,762 km²),
which lies outside PCIC’s coverage. The open water balance is the only
estimate there. Its 7 gauges average 37% held-out error, from −38% to
+95%, in zones 08 and 09.

The map’s segment values come from the fit that includes every gauge,
while the gauges are filled by the held-out error, so a gauge can look
worse than the segment it sits on. Take 08EE004, Bulkley River at Quick
(7,341 km²). It measured 561 mm a year, or 130.7 m³/s over its basin.
Predicted with its sub-sub-drainage held out, the balance gives 509 mm,
or 118.5 m³/s (−9%). The segment it sits on reads 120.8 m³/s on the map
(−8%), closer, because that fit saw this gauge.

![Mean annual discharge on 7,748 of the 7,755 Bulkley River segments of
order 3 or more, from the open water balance, and the 7 calibration
gauges in the group, filled by the balance's held-out error. The keymap
marks the group in
BC.](segment-discharge_files/figure-html/map-bulk-1.png)

Mean annual discharge on 7,748 of the 7,755 Bulkley River segments of
order 3 or more, from the open water balance, and the 7 calibration
gauges in the group, filled by the balance’s held-out error. The keymap
marks the group in BC.

| Gauge | Area (km²) | Observed (mm) | Water balance (mm, held out) | Error |
|:---|---:|---:|---:|---:|
| 08EE004 Bulkley River at Quick | 7,341 | 561 | 509 | −9% |
| 08EE013 Buck Creek at the Mouth | 567 | 238 | 212 | −11% |
| 08EE020 Telkwa River below Tsai Creek | 364 | 1,234 | 792 | −36% |
| 08EE008 Goathorn Creek near Telkwa | 122 | 449 | 665 | +48% |
| 08EE025 Two Mile Creek in District Lot 4834 | 22 | 180 | 352 | +95% |
| 08EE012 Simpson Creek at the Mouth | 13 | 631 | 771 | +22% |
| 08EE028 Station Creek above Diversions | 10 | 894 | 555 | −38% |

The 7 calibration gauges in the Bulkley River group: mean annual runoff
observed in 1981–2010, the water balance’s held-out prediction, and its
error. {.table}

## Limits

In order of how much they affect a user:

- **Coverage.** Outside the Peace, Fraser and Columbia, and on the
  segments fwapg leaves empty inside them, the open water balance is the
  only estimate. A model that classifies habitat on fwapg’s discharge
  gets nothing there.
- **Dry zones.** In zone 24 and the other semi-arid interior zones,
  runoff is a small remainder of precipitation, so a small error in
  evapotranspiration is a large one in runoff. The zone adjustment
  passes its gate only under a variant offered after the pre-set one
  failed, so all the skill figures here are mildly optimistic
  (`research/water_balance_method.md`).
- **Small streams.** Gauged basins under 100 km² average 43% error, and
  93% of the Salmon River’s watersheds with a stream are that small.
- **Segments without a watershed.** In the two groups mapped here, 8
  segments of order 3 to 7 have no watershed polygon in the Freshwater
  Atlas lookup, so neither product gives them a value. They are left off
  the maps, which leaves short gaps in some streams.

## How it is built

wet rebuilds fwapg’s numbers from PCIC’s output with its own code, and
on every one of the 9,000 Salmon River segments fwapg gives a value, it
matches fwapg to the five decimals fwapg stores.

fwapg gives each watershed the value of the PCIC cell under its
centroid. A cell is 0.0625°, about 7 by 4 km here, so a small watershed
gets one cell’s value. wet can instead weight every cell by the area it
covers. Under 10 km², 11% of watersheds move by more than 5%, by up to
24% at the 99th percentile. Above 100 km², the 99th percentile is 2.8%,
because a large basin averages many cells either way.

![Change in mean annual runoff from area-weighted sampling, against
centroid sampling, for the 4,248 Salmon River watersheds that carry a
stream. Upstream area is on a logarithmic
axis.](segment-discharge_files/figure-html/sampling-1.png)

Change in mean annual runoff from area-weighted sampling, against
centroid sampling, for the 4,248 Salmon River watersheds that carry a
stream. Upstream area is on a logarithmic axis.

fwapg’s stored upstream area is a stale snapshot. In the Fraser, 1,731
of 644,710 polygons carry a stored area that differs from the area
accumulated from the Freshwater Atlas today. None of them changes a
Salmon River segment, so the match above does not test it. wet uses the
accumulated area except when it reproduces fwapg.

The PCIC path for one headwater group, as `scripts/mad_parity.R` runs
it, needs fwapg and the PCIC server. The open water balance is a
pipeline of scripts (`scripts/wb_inputs.R` to `scripts/wb_output.R`; see
the package’s `CLAUDE.md`).

``` r

library(wet)
conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")

# PCIC VIC-GL runoff and baseflow over the group's extent, 1981-2010
bbox <- c(-124.12, 54.22, -123.12, 55.11)
runoff <- terra::rast(wet_pcic_fetch("RUNOFF", bbox, "1981-01-01", "2010-12-31"))
baseflow <- terra::rast(wet_pcic_fetch("BASEFLOW", bbox, "1981-01-01", "2010-12-31"))
mad_cell <- wet_runoff_annual(runoff) + wet_runoff_annual(baseflow)   # mm/yr per cell

# every watershed polygon in the Fraser; those inside the extent get a cell value
ws <- wet_ws_fetch(conn, "100")
in_bb <- ws$lon >= bbox[1] & ws$lon <= bbox[3] & ws$lat >= bbox[2] & ws$lat <= bbox[4]
cells <- wet_ws_sample(mad_cell, ws[in_bb, c("watershed_feature_id", "lon", "lat")], "centroid")
up <- wet_upstream_mean(ws, cells, "total", irregular_pairs = wet_upstream_irregular(conn, "100"))
up$mad_m3s <- wet_mm_to_m3s(up$value, up$upstream_area_m2)
```

**Cached inputs.** This article runs on saved outputs: PCIC VIC-GL
through `scripts/mad_parity.R`; the open water balance from province run
962a9cc2c4 (annual AET cfu, HYDAT release 2025-10-14); fwapg’s values at
the gauges; built 6 October 2026 at commit 42adbb1. Regenerated by
`data-raw/segment_vignette_data.R`. Map layers from the Freshwater Atlas
(fwapg), BC Geographic Names and the BC Hydrologic Zones, by
`data-raw/segment_vignette_map.R`.
