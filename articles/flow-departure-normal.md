# How Stream Flow Has Departed from Its 1981–2010 Normal: A Case Study

The R package [`wet`](https://newgraphenvironment.github.io/wet/)
([Irvine 2026c](#ref-wet)) measures stream flow and water temperature on
British Columbia’s Freshwater Atlas. This case study uses its station
records at two gauges near Houston to ask how summer flow, in the weeks
when chinook salmon migrate and spawn, has departed from its 1981–2010
normal: its mean over one of the 30-year periods the World
Meteorological Organization sets for climate normals ([Arguez and Vose
2011, 699](#ref-arguez_vose2011DefinitionStandard)).

**The answer.** Over 2022–2026, mean flow in every timing window at both
gauges was below its 1981–2010 normal, by 25% to 62%. Every window at
both gauges was below normal in each year from 2023, and 13 of those 16
window means were drier than nine 1981–2010 years in ten. At Bulkley
River near Houston, the normal rests on 1981–1998, the years with enough
record.

## Where are the gauges?

Both gauges are near Houston. Buck Creek joins the Bulkley River in the
town, and the Bulkley gauge sits downstream of its mouth, so it measures
Buck Creek’s flow as well: Buck Creek drains 24% of the area above it.
The Bulkley joins the Skeena River at Hazelton, about 120 km north-west
of Houston.

![The two gauges (points) and the land each one drains (shaded). Buck
Creek's catchment (567 km²) lies inside the Bulkley gauge's (2,315 km²),
so the two records are not independent. The Bulkley River and Buck Creek
are drawn heavy; other streams of order 5 and up (thin) and lakes of 100
ha and up (blue) are drawn only near the catchments. Houston is
labelled, the bar is 30 km, and the inset places the map in British
Columbia.](flow-departure-normal_files/figure-html/map-1.png)

The two gauges (points) and the land each one drains (shaded). Buck
Creek’s catchment (567 km²) lies inside the Bulkley gauge’s (2,315 km²),
so the two records are not independent. The Bulkley River and Buck Creek
are drawn heavy; other streams of order 5 and up (thin) and lakes of 100
ha and up (blue) are drawn only near the catchments. Houston is
labelled, the bar is 30 km, and the inset places the map in British
Columbia.

## What is a timing window?

A chinook salmon life history timing window is the part of the year when
a life stage is in the stream. Two are used here: adults migrate
upstream from May 1 to August 1, and spawn from August 1 to September
15. The dates come from New Graph’s species-timing table for the
Bulkley, which cites Gottesfeld and Rabnett
([2007](#ref-gottesfeld_rabnett2007SkeenaFish)). Its fry migration
window falls within these two, so it is not shown on its own, and its
other 2 chinook timing windows, incubation and emergence, reach into
November–April, when the gauges can read under ice, so they are left
out. A timing window’s flow in a year is its mean daily flow, counted
when 80% of its days have a record.

## How did the last five years compare with normal?

Each bar is one timing window in one year: its mean flow as a percentage
of that window’s 1981–2010 mean, so 100% is normal and lower is drier.
Wet years pull the mean up, so a typical year sits under it; the dashed
line marks the median year.

From 2023, every bar falls below the median year as well as the mean,
and 6 were drier than any 1981–2010 year. The two gauges fall on the
same side of normal in every timing window and year, partly because one
catchment holds the other.

![Mean flow in each chinook timing window, 2022–2026, as a percentage of
its 1981–2010 mean (solid line, given in m³/s at the top right of each
panel). Each bar is labelled with its percentage, coloured by whether it
falls below or above the mean, and paler where any of its days are
provisional. The dashed line is the median 1981–2010 year. At Bulkley
River near Houston (08EE003), the 1981–2010 normal rests on 1981–1998:
no window in 1999–2010 has 80% of its
days.](flow-departure-normal_files/figure-html/recent-1.png)

Mean flow in each chinook timing window, 2022–2026, as a percentage of
its 1981–2010 mean (solid line, given in m³/s at the top right of each
panel). Each bar is labelled with its percentage, coloured by whether it
falls below or above the mean, and paler where any of its days are
provisional. The dashed line is the median 1981–2010 year. At Bulkley
River near Houston (08EE003), the 1981–2010 normal rests on 1981–1998:
no window in 1999–2010 has 80% of its days.

## What did the year look like?

The same comparison day by day: the last five years’ mean and median day
against 1981–2010’s, over the whole year and, on its own scale, over the
months around spawning, where the spring freshet would otherwise flatten
the low summer flow.

![Daily flow at each gauge: the whole year (left), with the migration
window beneath, and July to October (right), with the spawning window,
on its own scale. Lines are the mean (solid) and median (dashed) day
over the years of each gauge's 1981–2010 normal (grey) and over
2022–2026 (colour). A normal line is drawn on days with at least 10 of
those years on record, so at the Bulkley gauge it runs only from 1 May
to 8 November; a 2022–2026 line on days all 5 years have a record. The
shaded months, November to April, are when the gauges can read under
ice.](flow-departure-normal_files/figure-html/hydrograph-1.png)

Daily flow at each gauge: the whole year (left), with the migration
window beneath, and July to October (right), with the spawning window,
on its own scale. Lines are the mean (solid) and median (dashed) day
over the years of each gauge’s 1981–2010 normal (grey) and over
2022–2026 (colour). A normal line is drawn on days with at least 10 of
those years on record, so at the Bulkley gauge it runs only from 1 May
to 8 November; a 2022–2026 line on days all 5 years have a record. The
shaded months, November to April, are when the gauges can read under
ice.

## How much has mean flow changed?

Each point is the change in a timing window’s mean flow, from its
1981–2010 mean to the mean of 2022–2026. Its bar spans the middle 90% of
changes from resampling the years in each period; with only five recent
years, one of them wet, the bars are wide.

![Change in each chinook timing window's mean flow, from its 1981–2010
mean to the mean of 2022–2026, at each gauge (point); the bar spans the
middle 90% of changes from resampling the years in each period, and the
vertical line is no
change.](flow-departure-normal_files/figure-html/change-1.png)

Change in each chinook timing window’s mean flow, from its 1981–2010
mean to the mean of 2022–2026, at each gauge (point); the bar spans the
middle 90% of changes from resampling the years in each period, and the
vertical line is no change.

## How were the numbers made?

These calls produced the window statistics, with normal and departure
from the R package [`cd`](https://newgraphenvironment.github.io/cd/)
([Irvine 2026a](#ref-cd)). They read HYDAT, the
[water-temp-bc](https://github.com/NewGraphEnvironment/water-temp-bc)
archive and ECCC’s real-time feed (through
[`tidyhydat`](https://docs.ropensci.org/tidyhydat/) ([Albers
2017](#ref-tidyhydat))), so the article runs on a cached copy of their
output.

``` r

library(wet)

# HYDAT, then ECCC provisional, then real-time, per station
daily <- wet_station_daily(c("08EE013", "08EE003"))

windows <- data.frame(window = c("Migration", "Spawning"), start = c("05-01", "08-01"),
                      end = c("08-01", "09-15"))
stats <- wet_window_stats(daily, windows, stats = "mean")

# normal and departure are cd's, one station per call
buck <- stats[stats$station_number == "08EE013", names(stats) != "station_number"]
base <- cd::cd_baseline(buck, 1981:2010)
departure <- cd::cd_anomaly(buck, base)
```

## What does it not show?

- **The latest years are provisional:** approved HYDAT flows end in
  March 2025, so 2 of the five years rest on provisional flows, which
  may be revised.
- **Some bars have days missing:** 2 of the 20 bars rest on 80%–91% of
  their days: Bulkley River near Houston in 2025 (migration and
  spawning).
- **Some normals have years missing:** a year is left out of a timing
  window’s normal when the window has under 80% of its days, so Buck
  Creek at the Mouth lacks 1984 in spawning; Bulkley River near Houston
  lacks 1999–2010 in every timing window.
- **The timing windows come from the literature, not from observation:**
  New Graph’s species-timing table cites Gottesfeld and Rabnett
  ([2007](#ref-gottesfeld_rabnett2007SkeenaFish)) for both.

## Software and citation

The flows in this article are cached from HYDAT release 2026-07-17, with
provisional and real-time flows retrieved 1 October 2026. The timing
windows are New Graph’s species-timing table at commit c97c4d0, and the
catchments, the stream mouths and the rivers they join are the
Freshwater Atlas’s.

The software, each cited:

- [`wet`](https://newgraphenvironment.github.io/wet/) ([Irvine
  2026c](#ref-wet)) reads the gauge records and makes the timing-window
  statistics.
- [`cd`](https://newgraphenvironment.github.io/cd/) ([Irvine
  2026a](#ref-cd)) takes the normal and the departures.
- [`tidyhydat`](https://docs.ropensci.org/tidyhydat/) ([Albers
  2017](#ref-tidyhydat)) reads the ECCC real-time feed.
- [`fwapg`](https://smnorris.github.io/fwapg/) ([Norris
  2024](#ref-norris2024smnorrisfwapg)) loads the Freshwater Atlas into
  PostgreSQL and delineates each gauge’s catchment from it.
- [`ggplot2`](https://ggplot2.tidyverse.org/) ([Wickham
  2016](#ref-ggplot2)),
  [`gq`](https://newgraphenvironment.github.io/gq/) ([Irvine
  2026b](#ref-gq)) and [`sf`](https://r-spatial.github.io/sf/) ([Pebesma
  and Bivand 2023](#ref-sf)) make the figures and the map;
  [`knitr`](https://yihui.org/knitr/) ([Xie 2026b](#ref-knitr)) and
  [`bookdown`](https://pkgs.rstudio.com/bookdown/) ([Xie
  2026a](#ref-bookdown)) render the article, all in R ([R Core Team
  2025](#ref-base)).

This build ran on `wet` 0.4.31, `cd` 0.6.13, commit 86989e3, `gq` 0.16.1
and commit aa082d0. To cite `wet`:

Irvine A (2026). *wet: Stream Flow and Water Temperature for the BC
Freshwater Atlas*. New Graph Environment Ltd.
<doi:10.5281/zenodo.23305781> <https://doi.org/10.5281/zenodo.23305781>.
Version 0.4.31, <https://github.com/NewGraphEnvironment/wet>.

### Data

- Daily flow: the Water Survey of Canada’s HYDAT ([Environment and
  Climate Change Canada
  2021](#ref-environmentandclimatechangecanada2021NationalWater)),
  release 2026-07-17.
- Provisional and real-time daily flow: Environment and Climate Change
  Canada’s records, as archived by
  [water-temp-bc](https://github.com/NewGraphEnvironment/water-temp-bc),
  and its real-time feed.
- Timing windows for chinook salmon: New Graph’s species-timing table
  ([Gottesfeld and Rabnett
  2007](#ref-gottesfeld_rabnett2007SkeenaFish)).
- Streams, lakes, catchments and place names: the Province of British
  Columbia’s Freshwater Atlas ([FLNRORD
  2021](#ref-flnrord2021FreshwaterAtlasb)) and BC Geographic Names,
  through DataBC.

## References

Albers, Sam. 2017. “tidyhydat: Extract and Tidy Canadian Hydrometric
Data.” *The Journal of Open Source Software* 2 (20).
<https://doi.org/10.21105/joss.00511>.

Arguez, Anthony, and Russell S. Vose. 2011. “The Definition of the
Standard WMO Climate Normal: The Key to Deriving Alternative Climate
Normals.” *Bulletin of the American Meteorological Society* 92 (6):
699–704. <https://doi.org/10.1175/2010BAMS2955.1>.

Environment and Climate Change Canada. 2021. “National Water Data
Archive: HYDAT.” Service description. Environment and Climate Change
Canada (ECCC).
<https://www.canada.ca/en/environment-climate-change/services/water-overview/quantity/monitoring/survey/data-products-services/national-archive-hydat.html>.

FLNRORD. 2021. “Freshwater Atlas Stream Network - Data Catalogue.”
Published by Ministry of Forests, Lands, Natural Resource Operations and
Rural Development.
<https://catalogue.data.gov.bc.ca/dataset/freshwater-atlas-stream-network>.

Gottesfeld, A, and K Rabnett. 2007. *Skeena Fish Populations and Their
Habitat*. Skeena Fisheries Commission.

Irvine, Allan. 2026a. *cd: Climate Departure Analysis from ERA5-Land
Reanalysis*. New Graph Environment Ltd.
<https://github.com/NewGraphEnvironment/cd>.

Irvine, Allan. 2026b. *gq: Cartographic Style Management Across
Rendering Targets*. <https://github.com/NewGraphEnvironment/gq>.

Irvine, Allan. 2026c. *wet: Stream Flow and Water Temperature for the BC
Freshwater Atlas*. New Graph Environment Ltd.
<https://doi.org/10.5281/zenodo.23305781>.

Norris, Simon. 2024. *fwapg*. <https://github.com/smnorris/fwapg>.

Pebesma, Edzer, and Roger Bivand. 2023. *Spatial Data Science: With
applications in R*. Chapman and Hall/CRC.
<https://doi.org/10.1201/9780429459016>.

R Core Team. 2025. *R: A Language and Environment for Statistical
Computing*. R Foundation for Statistical Computing.
<https://www.R-project.org/>.

Wickham, Hadley. 2016. *ggplot2: Elegant Graphics for Data Analysis*.
Springer-Verlag New York. <https://ggplot2.tidyverse.org>.

Xie, Yihui. 2026a. *bookdown: Authoring Books and Technical Documents
with R Markdown*. <https://github.com/rstudio/bookdown>.

Xie, Yihui. 2026b. *knitr: A General-Purpose Package for Dynamic Report
Generation in R*. <https://yihui.org/knitr/>.
