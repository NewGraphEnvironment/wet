# Monthly Flow per Segment

The published discharge table
([`vignette("segment-discharge")`](https://newgraphenvironment.github.io/wet/articles/segment-discharge.md))
gives an FWA segment thirteen values per source it covers (routed PCIC
covers fewer segments than the balance): the mean annual flow (month 0)
and the mean flow of each calendar month (months 1–12). This article is
about the twelve months. It shows how to read them for one stream, sets
them against observed flow and Chinook life-stage windows on the Bulkley
River, and scores both sources month by month at the gauges the water
balance is calibrated on. The scores are where the monthly values are
right and where they are not, and the article ends with the list of what
to fix.

## What a month holds

Each source fills the twelve months its own way:

- **Routed PCIC** (`pcic_routed`) is the mean of each month’s daily flow
  over 1981–2010 from PCIC’s Raven routing of VIC-GL runoff, placed on
  FWA segments by NewGraphEnvironment/fwapg#6. Its month 0 is the plain
  mean of the twelve months, not weighted by their days. On the three
  segments below that moves it by at most 0.4%.
- **The water balance** (`wet_balance`) is the annual flow over
  1981–2010 split into months by the shares of the year that the five
  calibration gauges most like it carry
  ([`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md),
  \#102). Its months are volume shares of its month 0, so they add up to
  it exactly.

Both sources cover 1981–2010, the period the gauges are scored over.
Neither is the gauge record.

## Reading a segment’s twelve months

The parts are public and the bucket allows no listing, so the manifest
names them. One stream is one `linear_feature_id`. Naming its watershed
group as well lets duckdb skip the row groups that cannot hold it, which
keeps the read to seconds.

``` r

library(wet)
# Buck Creek at its mouth, where gauge 08EE013 sits
q <- wet_segment_monthly(NULL, 17094080, groups = "BULK")

# twelve months a column per source
reshape(q[q$month > 0, c("source", "month", "q_m3s")], idvar = "month",
        timevar = "source", direction = "wide")
```

[`wet_segment_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_segment_monthly.md)
reads the parts through duckdb when it is given no database connection,
and the table
[`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
writes when it is. It returns `linear_feature_id, month, q_m3s, source`,
in the shape of
[`wet_station_monthly()`](https://newgraphenvironment.github.io/wet/reference/wet_station_monthly.md)’s
`station_number, month, q_m3s` for a gauge, so a gauge comparison is a
join on `month`. A segment with no value for a source comes back with
its months as `NA`, not as missing rows.
`data-raw/monthly_vignette_data.R` runs this read and refuses to bundle
the values below unless it returns them.

## The Bulkley at three gauges

![Mean monthly flow on the segments three Bulkley gauges sit on, from
each source, beside the gauge's observed monthly means over 1981–2010.
At Bulkley River near Houston (08EE003), a seasonal gauge, only the
months with 10 or more years of 20 days' flow are drawn (May–October).
The strips under each panel are the Chinook
windows.](monthly-flow_files/figure-html/hydrographs-1.png)

Mean monthly flow on the segments three Bulkley gauges sit on, from each
source, beside the gauge’s observed monthly means over 1981–2010. At
Bulkley River near Houston (08EE003), a seasonal gauge, only the months
with 10 or more years of 20 days’ flow are drawn (May–October). The
strips under each panel are the Chinook windows.

At Buck Creek (08EE013), a snowmelt stream of 567 km², the gauge peaks
in May and so does routed PCIC, which overshoots it: its May–June flow
is 23 m³/s against 16.4 observed. On the Bulkley at Quick (08EE004), a
basin of 7,341 km², routed PCIC falls short of the gauge in May–June by
about a quarter (259 m³/s against 338) and is high in July and August.

Both gauges are among those the balance is calibrated on, so on their
segments its published values are in-sample. The gauge most like each of
them is itself, so the balance there has the gauge’s own monthly pattern
at the balance’s annual flow: about -12% at Buck Creek and -9% at Quick
in every month. The scores further down use the balance held out
instead. 08EE003 is not a calibration gauge: it is seasonal and has no
complete years in 1981–2010, so on its segment the balance is a genuine
estimate for an ungauged site, and the gauge can check it only in open
water.

## Flow in the Chinook windows

The windows start and end mid-month, and the product holds monthly
means. A window’s flow from the product is therefore a day-weighted
mean: each day of the window takes its month’s mean. Two columns of the
table below separate that approximation from model error. *Daily record*
is the gauge’s own daily flow, averaged over the window in each year,
and *Monthly, day-weighted* is the same years’ observed monthly means
put through the day weighting. In migration and spawning they agree
within 3%. In fry migration they differ by up to 27%, because that
window takes half of July, when the flow is falling fast, at July’s
mean. Even there the approximation is smaller than routed PCIC’s error,
which in that window reaches +60%. At Buck Creek the balance carries the
gauge’s own months, so its window error is the approximation’s and its
annual error’s. At 08EE003, which no fit uses, it is +379% to +470% in
the two late-summer windows, while it is -24% in the migration window:
its donor gauges put far more of the year into late summer than this
gauge carries. That error is ours.

| Gauge | Window | Years | Daily record | Monthly, day-weighted | Routed PCIC | Water balance |
|:---|:---|---:|---:|---:|---:|---:|
| Buck Creek at the Mouth (08EE013) | Migration (May 1 – Aug 1) | 30 | 11.7 | 11.7 | 16.4 (+40%) | 10.4 (-11%) |
|  | Spawning (Aug 1 – Sep 15) | 29 | 0.9 | 0.9 | 0.9 (0%) | 0.8 (-9%) |
|  | Fry migration (Jul 15 – Sep 7) | 29 | 1.3 | 1.6 | 1.8 (+39%) | 1.4 (+12%) |
| Bulkley River near Houston (08EE003) | Migration (May 1 – Aug 1) | 18 | 36.8 | 36.8 | 39.8 (+8%) | 27.8 (-24%) |
|  | Spawning (Aug 1 – Sep 15) | 18 | 2.1 | 2.1 | 2.7 (+29%) | 12.0 (+470%) |
|  | Fry migration (Jul 15 – Sep 7) | 18 | 3.3 | 4.0 | 5.2 (+60%) | 15.6 (+379%) |

Mean flow (m³/s) in each Chinook window. Daily record: the gauge’s mean
over the window, averaged over the years in 1981–2010 with enough of its
days. Monthly, day-weighted: the same years’ observed monthly means,
each day taking its month’s mean. The two sources are day-weighted the
same way, with their difference from the daily record in brackets.
{.table}

## Monthly error at the gauges

Monthly flow is scored at the 315 gauges the water balance is calibrated
on, against each gauge’s monthly means over its complete years in
1981–2010. The balance is scored **held out**: each gauge’s months come
from a fit that never saw it or its neighbours (blocked
cross-validation, as `research/water_balance_method.md` describes), as
the fit stored them. Routed PCIC is scored on the segment each gauge
snapped to, at the 290 gauges whose segment carries routed flow, less 11
whose segment carries under 20% of the observed annual flow (left out as
the annual routed comparison leaves them out, which attributes each one:
to the outlet’s placement or the gauge’s snap, to PCIC’s runoff, or
unresolved). That leaves 279 gauges. Each source is scored on every
month of all its own gauges, as modelled over observed flow: the balance
on 3,780 gauge-months, routed PCIC on 3,348. No held-out month of the
balance is zero: each is a mean of five gauges’ observed shares.

![Error in mean monthly flow by month: the median (line) and the middle
half of gauges (band), as a percentage of the gauge's 1981–2010 mean.
The water balance is held out (blocked cross-validation) at 315
calibration gauges; routed PCIC at the 279 of them it covers. Dashed
lines mark ±20%.](monthly-flow_files/figure-html/error-month-1.png)

Error in mean monthly flow by month: the median (line) and the middle
half of gauges (band), as a percentage of the gauge’s 1981–2010 mean.
The water balance is held out (blocked cross-validation) at 315
calibration gauges; routed PCIC at the 279 of them it covers. Dashed
lines mark ±20%.

| Month | Balance median | Balance within ±20% | Routed median | Routed within ±20% |
|:------|---------------:|--------------------:|--------------:|-------------------:|
| Jan   |            +1% |                 43% |           -6% |                34% |
| Feb   |            +2% |                 41% |            0% |                34% |
| Mar   |            -1% |                 42% |          -11% |                33% |
| Apr   |            +7% |                 35% |          -12% |                35% |
| May   |            +4% |                 38% |          -17% |                39% |
| Jun   |            -3% |                 45% |           +1% |                61% |
| Jul   |             0% |                 40% |          +20% |                38% |
| Aug   |            +2% |                 34% |          +13% |                36% |
| Sep   |            -1% |                 36% |           +3% |                44% |
| Oct   |             0% |                 45% |           -3% |                44% |
| Nov   |            +1% |                 47% |           -6% |                41% |
| Dec   |            +1% |                 44% |           -2% |                38% |

Median error in mean monthly flow, and the share of gauges within ±20%
of observed, each source on its own gauges as in the figure above.
{.table}

The two sources’ errors have different shapes.

- **The water balance**’s median error is within ±10% in every month,
  highest in April (+7%). At the 25 gauges routed PCIC does not reach,
  19 of them in WSC drainage area 10 (the Liard), its winter months are
  within ±10% too (-9% in January). Its spread is wide in every month:
  fewer than half of the gauges fall within ±20% in any month. Its
  months are an annual flow times the shares of the year that the five
  calibration gauges most like it carry, alike in elevation, location,
  and two snow terms from ERA5-Land: the day by which half the snowpack
  has melted and the peak snow water equivalent
  ([`wet_share_fit()`](https://newgraphenvironment.github.io/wet/reference/wet_share_fit.md),
  \#16, \#102). At the 243 gauges whose observed flow peaks in May or
  June, the balance is below the gauge in that month at 58% of them, by
  a median of -6%. Held out, its median Nash–Sutcliffe efficiency on the
  monthly climatology is 0.81 over its 315 gauges. This error is ours.
- **Routed PCIC**, on the 279 gauges both sources are scored at, has
  more of them within ±20% than the balance has in 4 of the twelve
  months (May, June, August and September). It reads low in March and
  April (median -11%) and high in July and August (+16%): as if its melt
  starts late and runs on. Its median monthly efficiency is 0.82 over
  its 279 gauges.

Both sources and the gauges cover 1981–2010, so this shape is not a
difference of period. Gauge by gauge, routed PCIC is low in March–April
at 61% of the 279 gauges and high in July–August at 68% (both at 41%). A
misplaced outlet changes one gauge’s hydrograph, mostly in size; it
would not move the median of 279 gauges toward a late melt. So the
median shape comes from the routed model, not from the placement. That
attributes it to PCIC’s model, which wet does not run; it is recorded
here and in \#67.

A second place was not needed to find these patterns, because the
province-wide scores already span regimes. The table below splits them
by basin size and by lake outlets, which a regime contrast would have
sampled one at a time. The balance is the stronger source on basins
under 1,000 km², and routed PCIC on those over it. Routed PCIC is also
the stronger at lake outlets, whose flow a lake holds back and releases
later in the year: routing follows the lake, and the balance’s donor
gauges are matched without regard to it.

| Group             | Gauges | Balance | Routed |
|:------------------|-------:|--------:|-------:|
| All gauges        |    279 |    0.82 |   0.82 |
| \<100 km²         |     74 |    0.61 |   0.43 |
| 100-1000          |    105 |    0.82 |   0.80 |
| 1000-10000        |     82 |    0.87 |   0.92 |
| \>10000           |     18 |    0.93 |   0.95 |
| Lake outlet       |     17 |    0.73 |   0.92 |
| Not a lake outlet |    262 |    0.82 |   0.82 |

Median Nash–Sutcliffe efficiency of the monthly climatology per gauge,
by basin size and lake outlets, on the 279 gauges both sources are
scored at. {.table}

## What’s next

What this exploration found that would make the monthly values more
useful, each with its issue:

- **Routed PCIC’s seasonal shape** (#67): low in early spring, high in
  late summer, over the gauges’ own period. Attributed to PCIC’s model.
  The issue records the evidence and a draft report to PCIC.
- **Monthly scoring by region and season** (#6), which takes over the
  scoring this article starts.

## Limits

- On a calibration gauge’s own segment the published balance is
  in-sample: its months are the gauge’s own monthly pattern at the
  balance’s annual flow (two gauges on one watershed, 08NM240 and
  08NM241, share the mean of theirs), and a watershed much like a gauge
  in elevation, location and snow gets almost the same pattern. The
  scores above use the held-out balance instead.
- 08EE003 is seasonal: its monthly means cover May–October, from 19 of
  the years 1981–2010. Its windows rest on the years the window table
  gives.
- A window’s flow from monthly means is an approximation (the window
  table measures it).
  [`wet_flow_window()`](https://newgraphenvironment.github.io/wet/reference/wet_flow_window.md)
  labels it `basis = "monthly"`, and gives `"daily"` from the same call
  once daily flow is published (#99; the balance’s shape within the
  month is fitted and scored in \#70).
- Routed PCIC’s month 0 is a plain mean of its months, so its months
  converted to millimetres do not add up to its annual runoff exactly.

## Validation

`data-raw/monthly_vignette_data.R` built the data at wet 6ac469a on
2026-10-19, from the published build at wet 8ca2dee
(<https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json>)
and the water balance fit on HYDAT 2026-07-17 (AET cfu). It checked the
bundled published values against what they were built from, and refused
to write unless none differed:

| Check | Compared | Differing |
|:---|---:|---:|
| routed months 1-12 (Bulkley segments and gauges) = fwapg monthly table | 3,480 | 0 |
| routed month 0 (Bulkley segments and gauges) = mean of fwapg’s 12 months | 290 | 0 |
| balance month 0 (Bulkley watersheds), recomputed = fit output | 2 | 0 |
| balance months the fit’s output holds (Bulkley segments) = fit output via lut | 3 | 0 |
| balance months 0-12 (Bulkley segments whose watershed the bundle holds) = fit recomputed via lut | 26 | 0 |

Published values against their sources. {.table}

Where the data were built, the fit’s output held month 0 only, so the
balance’s months 1–12 were recomputed from the fit for the watersheds
that copy held. The balance’s months that neither check covers rest on
the publish report’s value-by-value check of every month
(`data/checks/discharge_publish_20260717.txt`), which the script
requires to have passed for the live build. The held-out monthly balance
is the one the fit stored, under the share specification it shipped, and
scored again it gives the fit’s stored per-gauge scores. Routed flow is
fwapg 7c30f58’s table (40524444 rows, 3377037 segments, 0 null flows,
total 178918222.786650 m3/s).
