# Stream Discharge per Segment

## What it is

The R package [`wet`](https://newgraphenvironment.github.io/wet/)
publishes the mean flow of British Columbia’s Freshwater Atlas stream
segments, in cubic metres per second, for the year, each month and each
day. It is public at `s3://fresh-bc/discharge/fwa/v1/`. The bucket
allows no listing, so a reader starts from the manifest,
<https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json>,
which lists every part with its rows, size and md5. The build this
article reads has 512 parquet parts, 33.23 GB, built on 20 October 2026
at `wet` commit 77585a8.

- **`segment_monthly`**: one row per segment, month and source with a
  value, 102,790,688 rows. Month 0 is the annual mean and months 1–12
  the calendar months.
- **`watershed_monthly`**: the same per fundamental watershed, the small
  polygon each segment drains, from the water balance only.
- **`segment_daily`**: `segment_monthly` per day, 2,886,046,240 rows (29
  February folded into 28), one part per source and watershed group.
  Clamped daily and folded, routed PCIC’s days need not average to their
  month.

Each row comes from one of two sources:

**Routed PCIC** (`pcic_routed`, 1981–2010). The Pacific Climate Impacts
Consortium runs the VIC-GL hydrologic model on a 0.0625° grid, driven by
observed climate, and routes its runoff with the Raven model
([hydromosaic](https://beehive.pacificclimate.org/chyp/)). New Graph’s
[fork](https://github.com/NewGraphEnvironment/fwapg/pull/6) of
[`fwapg`](https://github.com/smnorris/fwapg), PostgreSQL tools for the
Freshwater Atlas, places PCIC’s outlets on Freshwater Atlas segments and
spreads flow between them by drainage area. The annual value is the mean
of the twelve months.

**Open water balance** (`wet_balance`, 1981–2010). `wet`’s own estimate,
after [Chapman et
al. (2018)](https://www2.gov.bc.ca/assets/gov/environment/air-land-water/water/northeast-water-strategy/chapman_et_al-2018-jawra.pdf):
precipitation less actual evapotranspiration from climate normals,
averaged over each watershed’s upstream area and adjusted per
[hydrologic
zone](https://catalogue.data.gov.bc.ca/dataset/bc-hydrologic-zones)
against the Water Survey of Canada’s
[HYDAT](https://www.canada.ca/en/environment-climate-change/services/water-overview/quantity/monitoring/survey/data-products-services/national-archive-hydat.html)
gauges. It covers almost all of BC, and its code and inputs are open.

## Which value to use

3,374,133 segments have a value from both sources, and the two differ,
so one row per segment is marked as the default with `pick`. It is
chosen once per segment, on annual flow, and the same source is picked
for every month:

- **routed PCIC**, where it has a value;
- **the balance** where routed PCIC’s annual flow is under a fifth of
  the balance’s on a segment that lies on its own watershed’s line. Off
  that line (side channels, and connectors and waterbody connections the
  lookup gives another line’s watershed), routed PCIC is kept however
  low it is;
- **whichever has a value**, where only one does.

Of the 4,907,441 segments in the Freshwater Atlas, `pick` takes routed
PCIC on 3,154,131 (64%), the balance on 1,378,712 (28%; 222,906 of them
because routed flow is far low), and 374,598 have neither, almost all of
them connection lines and secondary channels with no watershed polygon
of their own. The balance takes every segment with a value in the Liard,
where routed PCIC has none, and 98% of those in the four Nechako
Reservoir groups, where routed flow is far below the balance’s.

![The source \`pick\` takes on main-flow rivers of stream order 5 and up
(wider for higher orders), 6% of BC's segments, and the 315 calibration
gauges. Smaller streams are not drawn, nor the 1,557 segments of that
order with neither.](segment-discharge_files/figure-html/map-pick-1.png)

The source `pick` takes on main-flow rivers of stream order 5 and up
(wider for higher orders), 6% of BC’s segments, and the 315 calibration
gauges. Smaller streams are not drawn, nor the 1,557 segments of that
order with neither.

## How to read it

Read the parts from the bucket with the R package
[`duckdb`](https://r.duckdb.org/). `scenario`, `forcing` and `source`
are in each part’s path, not the file, so read with `hive_partitioning`.
Parts are sorted by `watershed_group_code`, so a read for one group
opens a few row groups:

``` r

library(wet)
cat <- wet_catalog()   # the manifest: one row per part, with its href
segs <- cat$href[cat$dataset == "discharge/fwa/v1/segment_monthly"]

duck <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(duck, "LOAD httpfs")
# the default annual flow on the Bulkley's segments
DBI::dbGetQuery(duck, sprintf("
  SELECT linear_feature_id, source, q_m3s
  FROM read_parquet([%s], hive_partitioning = true)
  WHERE scenario = 'historical' AND watershed_group_code = 'BULK' AND month = 0 AND pick",
  paste0("'", segs, "'", collapse = ", ")))
```

Or load it into [`PostgreSQL`](https://www.postgresql.org/) beside the
Freshwater Atlas:

``` r

conn <- DBI::dbConnect(RPostgres::Postgres(), dbname = "fwapg")
wet_db_load(conn, cat)   # discharge.fwa_v1_segment_monthly
```

[`wet_segment_daily()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_daily.md)
reads a segment’s days, and
[`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
a window’s flow:

``` r

q <- wet_segment_daily(NULL, 17094080, groups = "BULK")
wet_flow_window(q, data.frame(window = "spring", start = "04-15", end = "06-15"))
```

| Source      | From the days | From the months |
|:------------|:--------------|:----------------|
| pcic_routed | 22.20         | 19.74           |
| wet_balance | 15.40         | 13.61           |

Mean flow (m³/s) at Buck Creek’s mouth, 15 April to 15 June, from the
published days and, by the same call on the monthly rows, from the
months. {.table}

Besides flow (`q_m3s`) a row carries `runoff_mm`, the same water as a
depth over the area upstream (NA for a routed row off its watershed’s
own line), `coverage`, the share of that area the balance’s inputs
cover, and `period`.

## How good it is

Both sources are scored against mean annual runoff over 1981–2010 at the
315 HYDAT gauges the balance is calibrated on. Error is modelled minus
observed, as a percentage of observed. The balance is scored *held out*:
each Water Survey sub-sub-drainage (such as 08EE) is left out of the fit
in turn and predicted from the rest, so a gauge’s neighbours on the same
river cannot vouch for it.

|  | Routed PCIC, 290 gauges | Open water balance (held out), 290 gauges | Open water balance (held out), all 315 gauges |
|:---|---:|---:|---:|
| Mean absolute error | 24.2% | 27.6% | 27.5% |
| Bias (mean error) | +1.4% | +9.0% | +8.5% |
| Middle half of errors | −14% to +12% | −15% to +24% | −16% to +24% |
| Within ±20% | 63% | 54% | 53% |
|  PCIC does not list the gauges it calibrated to, so its errors may be partly in sample. |  |  |  |

Error in mean annual runoff at the calibration gauges. {.table .table
style="width: auto !important; margin-left: auto; margin-right: auto;border-bottom: 0;"}

Routed PCIC is closer than the held-out balance at 169 of the 290 gauges
both cover. Where each is weak:

- **Headwaters.** The balance averages 31% error at headwater gauges,
  whose basin holds no other gauge, against 18% at nested ones.
- **Small basins.** It averages 40% on basins under 100 km² against 20%
  on those over 1,000 km².
- **The dry interior.** In zone 24, the Southern Thompson Plateau, its 9
  gauges average 93%: runoff there is a small remainder of
  precipitation, so a small error in evapotranspiration is a large one
  in runoff.
- **The Liard.** Routed PCIC has no value at 25 gauges, most of them in
  the Liard, where the balance is the only estimate.

## Limits

- **Coverage.** Besides the Liard, routed PCIC has no value in a few
  northern and border basins, and only some on the outer coast’s
  islands.
- **The zone adjustment is kept by decision.** On headwater basins it
  does not beat raw precipitation less evapotranspiration, and zones
  with too few gauges for their own adjustment get none.
- **Segments without a value.** Of the 374,598, 369,217 have no
  watershed in the lookup through which the balance reaches a segment.

## Software and citation

The routed values at the gauges and the picks on the map are the
published product’s, read on 2026-10-20 from the build at `wet` commit
77585a8; the routed values were held equal to `fwapg`’s before they were
written. The province counts are from the segment table that build was
cut from. The balance’s scores are its held-out predictions from the fit
on HYDAT 2026-07-17, against HYDAT’s observed runoff. The build’s own
check of its published flows is [its
report](https://github.com/NewGraphEnvironment/wet/blob/main/data/checks/discharge_publish_20260717.txt).

- `wet` 0.4.19,
  [doi:10.5281/zenodo.23305781](https://doi.org/10.5281/zenodo.23305781).
  Irvine A (2026). *wet: Stream Flow and Water Temperature for the BC
  Freshwater Atlas*. New Graph Environment Ltd.
  <doi:10.5281/zenodo.23305781>
  <https://doi.org/10.5281/zenodo.23305781>. Version 0.4.19,
  <https://github.com/NewGraphEnvironment/wet>.
- `duckdb` 1.5.6. Mühleisen H, Raasveldt M (2026). *duckdb: DBI Package
  for the DuckDB Database Management System*. R package version 1.5.6,
  <https://r.duckdb.org/>.
- `ggplot2` 4.0.3. Wickham H (2016). *ggplot2: Elegant Graphics for Data
  Analysis*. Springer-Verlag New York. ISBN 978-3-319-24277-4.
  <https://ggplot2.tidyverse.org>.
- `gq` 0.16.1,
  [doi:10.5281/zenodo.23524719](https://doi.org/10.5281/zenodo.23524719),
  commit `367b562`. Irvine A (2026). *gq: Cartographic Style Management
  Across Rendering Targets*. New Graph Environment
  Ltd. <doi:10.5281/zenodo.23524719>
  <https://doi.org/10.5281/zenodo.23524719>. Version 0.16.1,
  <https://github.com/NewGraphEnvironment/gq>.
- `sf` 1.1-3,
  [doi:10.1201/9780429459016](https://doi.org/10.1201/9780429459016).
  Pebesma E, Bivand R (2023). *Spatial Data Science: With applications
  in R*. Chapman and Hall/CRC. <doi:10.1201/9780429459016>
  <https://doi.org/10.1201/9780429459016>.
  <https://r-spatial.org/book/>.

Cite `wet` by the DOI above, which resolves to its latest release. How
the balance is built, and each of its choices tested: [the water balance
method](https://github.com/NewGraphEnvironment/wet/blob/main/research/water_balance_method.md).

Data: routed flow from the Pacific Climate Impacts Consortium,
University of Victoria
([hydromosaic](https://beehive.pacificclimate.org/chyp/): VIC-GL
hydrologic model output routed with Raven, PNWNAmet forcing), placed on
the Freshwater Atlas by New Graph’s fork of `fwapg` at commit 7c30f58;
the stream network from the BC Freshwater Atlas through Norris, S.
(2026), *fwapg: PostgreSQL tools for working with British Columbia’s
Freshwater Atlas*, <https://github.com/smnorris/fwapg>; gauge records
from the Water Survey of Canada’s HYDAT, release 2026-07-17; 1981–2010
climate normals from the R package
[`climr`](https://github.com/bcgov/climr); actual evapotranspiration
from CGIAR-CSI’s Global High-Resolution Soil-Water Balance v3 ([figshare
7707605](https://figshare.com/articles/dataset/Global_High-Resolution_Soil-Water_Balance/7707605)),
held no lower than a Fu–Budyko estimate; elevation from the Copernicus
GLO-90 DEM; for the monthly shares, ERA5-Land snow normals (Copernicus
Climate Change Service) through the R package
[`cd`](https://newgraphenvironment.github.io/cd/); hydrologic zones from
the province’s BC Hydrologic Zones.

Method: Chapman, A.R., Kerr, B. and Wilford, D. (2018), A water
allocation decision-support model and tool for predictions in ungauged
basins in Northeast British Columbia, Canada, *Journal of the American
Water Resources Association* 54(3), 676–693,
[doi:10.1111/1752-1688.12643](https://doi.org/10.1111/1752-1688.12643).
