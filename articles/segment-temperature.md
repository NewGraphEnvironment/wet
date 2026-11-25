# Stream Temperature per Segment: How We Get There

**The R package [`wet`](https://newgraphenvironment.github.io/wet/), for
stream flow and water temperature in British Columbia, does not yet give
temperature for every stream reach** ([Irvine 2026c](#ref-wet)). This
article shows where that work starts, what it aims for, and how it will
be tested. The aim is growing-season degree days, a measure of how much
warmth a stream gives young fish in a year, at every reach (a mapped
stretch of stream) in British Columbia. Today they can be computed at a
few hundred stations across the province. Getting from those to every
reach takes a model on the stream network. [The
roadmap](https://github.com/NewGraphEnvironment/wet/issues/214) says
what is done and what is next.

## What are growing-season degree days, and why do they matter for fish?

A fish grows faster in warmer water, up to a point. **Growing-season
degree days** add up that warmth over the part of the year when a stream
is warm enough for growth: each day’s mean water temperature, summed
from the first week that averages above 5 °C to the first week that
falls below 4 °C ([Coleman and Fausch
2007](#ref-coleman_fausch2007ColdSummera)). A stream that holds 10 °C
for 100 days gives 1,000 degree days. Where the total is low, fish that
hatch in summer can be too small to survive their first winter ([Coleman
and Fausch 2007](#ref-coleman_fausch2007ColdSummera)), so the total
helps say which streams can produce fish.

The figure shows one year at one station: Simpson Creek at its mouth,
about 4 km north-west of Smithers, where it joins Kathlyn Creek on the
way to the Bulkley River. The station recorded every day from March
through November of 2020 except 29 days from 25 August. A season with a
missing day has no total, so the gap is filled first.
[`wet_temp_fill()`](https://newgraphenvironment.github.io/wet/reference/wet_temp_fill.html)
fills it with **air2stream**, a model of how water temperature follows
air temperature ([Toffolon and Piccolroaz
2015](#ref-toffolon_piccolroaz2015hybridmodel)), corrected by the
station’s own readings on either side of the gap and by what nearby
stations did on the same days. Run on air temperature alone,
uncorrected, the model is called **open-loop**. A reach with no station
has no readings, so open-loop is where it starts.

![Two stacked charts of Simpson Creek in 2020. The top chart shows daily
water temperature rising from near zero in winter to a summer peak, with
a gap in late August and September filled by a modelled line, and a
second line for what air temperature alone predicts. The bottom chart
shows degree days climbing to 1,460 by the end of the growing
season.](segment-temperature_files/figure-html/year-1.png)

Simpson Creek at its mouth in 2020. Top: each day’s mean water
temperature as the station recorded it (black); the 29 days filled
across the gap from 25 August to 22 September (orange), with the fill’s
95% interval (pale band); and what air temperature alone gives through
air2stream, the open-loop line (blue). Bottom: degree days adding up
through the growing season, 28 April to 22 October (shaded in both
panels), to 1,460; the stretch that rests on filled days is orange. The
last reading before the gap, 15.5 °C after 9.6 °C the day before, is
most likely a sensor leaving the water, and the fill starts from it.

The fill restarts from every reading, so a bad one is carried into it.
Here the last reading before the gap is about 6 °C above the day before
while the air barely warmed. The figure shows the year as the method
gives it; hiding that one reading lowers the total from 1,460 to 1,393
degree days.

## Where do we have temperature, and where not?

The aim is the whole province; the Bulkley River basin is used here only
as an example. A **reach** here is one stream segment of the Freshwater
Atlas, the province’s map of its streams ([FLNRORD
2021](#ref-flnrord2021FreshwaterAtlasb)). The Bulkley River runs
north-west from Houston past Smithers to meet the Skeena River at
Hazelton, and the stream network of its basin has tens of thousands of
reaches. About a dozen hold a federal hydrometric station that has
recorded water temperature, some only recently. Small-stream loggers are
not in `wet` yet.

![Map of the Bulkley River basin in north-west British Columbia, densely
covered by thin blue stream lines, with about a dozen orange and black
points marking temperature stations on its rivers and
creeks.](segment-temperature_files/figure-html/map-1.png)

One basin as an example, the Bulkley River: every reach of its stream
network (blue, heavier on larger streams) and the federal hydrometric
stations that have recorded water temperature (orange points; Simpson
Creek’s, the first figure’s, is black). The Bulkley, Morice and Telkwa
rivers are drawn heavy and named. Lakes of 500 ha and up are pale blue;
land outside the basin is dimmed, with its larger rivers thin and the
Skeena named. Houston, Smithers and Hazelton are labelled (open
squares), the bar is 30 km, and the inset places the map in British
Columbia.

The network drawn stands on Simon Norris’s
[`fwapg`](https://smnorris.github.io/fwapg/) ([Norris
2024](#ref-norris2024smnorrisfwapg)), which loads the Freshwater Atlas
into PostgreSQL. Side channels are trimmed from it so that water never
splits on its way downstream, as a stream network model needs; that step
runs from a fork of `fwapg` today ([Norris and Irvine
2026](#ref-norris_irvine2026NewGraphEnvironmentfwapg)).

## How do we get from stations to every reach?

The diagram shows how readings at a few stations become a value
everywhere; its colours say which parts exist.

![Flow diagram. Station readings and air temperature feed gap filling;
filled records and catchment traits feed a baseline; the baseline, the
stream network and air temperature at every reach feed a network model,
which gives degree days at every reach. A process model sits to one
side.](segment-temperature_files/figure-html/chain-1.png)

From station readings to degree days at every reach. Each box is one
piece and each arrow says what feeds what. The box’s colour says where
the piece stands: in place (green), being built (orange), what a network
model would add (blue), and a process model that already exists
(purple), joined by dashed arrows because it is a comparison and a
source of future change, not a step in the chain.

- **Catchment traits** describe the land above a point: its position,
  elevation, snow, lakes and glaciers.
- **The baseline** is the simple answer: what catchment traits alone can
  say. air2stream has three settings that say how closely a stream’s
  water follows the air, fitted at each station. The baseline predicts
  them where there is no station from catchment traits, two ways: by a
  relation fitted across stations, or from the stations most like it.
- **A network model** fits every station at once and lets reaches on the
  same stream inform each other. It can draw on everything above it in
  the diagram: the network, the stations and their filled records, the
  traits, air temperature at every reach, and how the baseline did. What
  is needed from it is temperature at every reach with its uncertainty,
  and degree days with that uncertainty carried through. Network models
  of weekly stream temperature have been fitted for the Nechako and
  Skeena watersheds ([Hill et al.
  2024](#ref-hill_etal2024Spatialstream); [Hill et al.
  2025](#ref-hill_etal2025Spatialstream)), and this work follows them.
  The method and the time step are open.

A **process model** works the other way, simulating water and heat
moving down rivers from the weather. The Pacific Climate Impacts
Consortium’s model ([Pacific Climate Impacts Consortium
2026](#ref-pacificclimateimpactsconsortium2026VICGLRavenMBCn)) gives
daily water temperature at points on its own river network, on past
weather and under climate models to 2100. Its temperatures can be
compared with the same station records, and it is one way to ask where
streams are becoming warm enough for fish.

## How will it be tested?

By hiding stations. A **holdout** takes a station’s whole record away,
predicts it as if the station had never been there, and compares the
prediction with what the station recorded. Three simple predictions are
to be tested this way, at stations across the province with a complete
growing season, on daily temperature and the season’s degree days: the
baseline’s two, and one that adds the stream network. The same hidden
stations are there for any model to be compared on.

![Three copies of a small branching stream network with seven stations.
One station is marked as hidden in each; the stations used to predict it
differ, and the third copy marks the stream through the hidden
station.](segment-temperature_files/figure-html/holdout-1.png)

The test, as a sketch on a made-up network (pale lines). One station is
hidden (orange) and its air2stream settings are predicted three ways,
each drawing on the stations in blue and leaving the grey ones out: from
catchment traits, a relation fitted to every other station; from the few
stations whose catchments are most like it, wherever they are; and from
traits and the stream network together, leaning most on the stream that
runs up and down from the hidden station (heavy line). The first two are
the baseline.

The third is **kriging**: estimating a value at an unmeasured place from
measured places, weighting the near ones most. On a stream network, near
is measured along the water and in the direction it flows. Here it is a
simple stand-in for the network, not the network model: it adds the
network to the same traits, so its difference from the baseline is what
the network adds. Each of the three is then run through air2stream on
the hidden station’s own air temperature and compared with two marks:
the model fitted to that station’s own record, the best these three
could do, and the average of all stations, what knowing nothing gives.
Each is tried twice, with and without the hidden station’s neighbours up
and down its stream; for the network’s prediction that difference is
what the neighbours are worth.

## What is not known yet?

- **The error with no station.** Even at a station, when a whole growing
  season is hidden, air2stream on air temperature alone misses that
  season’s total by about 129 degree days on average. With air2stream, a
  reach with no station can only do worse; how much worse is what the
  test measures.
- **Small streams.** Most reaches are small streams and few stations sit
  on one, as in the basin above, so the test says least about them.
- **Readings that are not water.** Nothing screens yet for one like the
  first figure’s.
- **The thresholds.** They exist for cutthroat trout in high-elevation
  Colorado streams, where 900 to 1,200 degree days gave the best
  recruitment and under 800 was unsuitable ([Coleman and Fausch
  2007](#ref-coleman_fausch2007ColdSummera)). Reports on westslope
  cutthroat trout in the Elk Valley apply them ([Thorley and Branton
  2022](#ref-thorley_branton2022SubjectMatter); [Hocking et al.
  2022](#ref-hocking_etal2022SubjectMatter)). None has been found yet
  for other British Columbia species.

## How were the numbers in the first figure made?

The fill borrows from its sub-drainage’s other stations, so the recipe
reads them all.

``` r

library(wet)

# the gauges of WSC sub-drainage 08E; most record no water temperature, and
# wet_temp_daily() warns of those and returns the ones that do
st <- tidyhydat::allstations
st <- st[startsWith(st$STATION_NUMBER, "08E"), ]
water <- wet_temp_daily(st$STATION_NUMBER, from = "2002-01-01", to = "2025-12-31")
st <- st[st$STATION_NUMBER %in% water$station_number, ]

# daily air temperature at each, then the fill and the degree days
air <- cd::cd_extract_daily(data.frame(id = st$STATION_NUMBER, lon = st$LONGITUDE, lat = st$LATITUDE),
                            "2002-01-01", "2025-12-31", variables = "tmean")
pool <- stats::setNames(substr(st$STATION_NUMBER, 1, 3), st$STATION_NUMBER)
filled <- wet_temp_fill(water, air, pool = pool)
gsdd <- wet_temp_gsdd(filled)
gsdd[gsdd$station_number == "08EE012" & gsdd$year == 2020, ]
```

## Software and citation

Water temperature was read from the archive on 25 November 2026, for
2002-01-01 to 2025-12-31; station coordinates and areas are HYDAT’s,
release 2026-07-17; and the data were built at commit 36700ca2.

The software, each cited:

- [`wet`](https://newgraphenvironment.github.io/wet/) ([Irvine
  2026c](#ref-wet)) reads the station records, fills them and sums the
  degree days.
- [`cd`](https://newgraphenvironment.github.io/cd/) ([Irvine
  2026a](#ref-cd)) serves daily air temperature at the stations.
- [`gsdd`](https://github.com/poissonconsulting/gsdd) ([Thorley and
  Lyons 2026](#ref-gsdd)) applies the growing-season rule, and
  [`tidyhydat`](https://docs.ropensci.org/tidyhydat/) ([Albers
  2017](#ref-tidyhydat)) gives each station’s time zone.
- [`fwapg`](https://smnorris.github.io/fwapg/) ([Norris
  2024](#ref-norris2024smnorrisfwapg)) loads the Freshwater Atlas into
  PostgreSQL, and the network with no splits is built on it ([Norris and
  Irvine 2026](#ref-norris_irvine2026NewGraphEnvironmentfwapg)).
  [`SSN2`](https://usepa.github.io/SSN2/) ([Dumelle et al.
  2024](#ref-SSN2)) is the software for kriging on a stream network.
- [`ggplot2`](https://ggplot2.tidyverse.org/) ([Wickham
  2016](#ref-ggplot2)), [`ggrepel`](https://ggrepel.slowkow.com/)
  ([Slowikowski 2026](#ref-ggrepel)),
  [`gq`](https://newgraphenvironment.github.io/gq/) ([Irvine
  2026b](#ref-gq)) and [`sf`](https://r-spatial.github.io/sf/) ([Pebesma
  and Bivand 2023](#ref-sf)) make the figures and the map;
  [`knitr`](https://yihui.org/knitr/) ([Xie 2026b](#ref-knitr)) and
  [`bookdown`](https://pkgs.rstudio.com/bookdown/) ([Xie
  2026a](#ref-bookdown)) render the article, all in R ([R Core Team
  2025](#ref-base)).

This build ran on `wet` 0.5.0, `cd` 0.6.13 (commit 1e44183) and `gq`
0.25.0 (commit 298b016); the data were built with `cd` 0.6.13 and `gsdd`
0.3.0.9009. To cite `wet`:

Irvine A (2026). *wet: Stream Flow and Water Temperature for the BC
Freshwater Atlas*. New Graph Environment Ltd.
<doi:10.5281/zenodo.23305781> <https://doi.org/10.5281/zenodo.23305781>.
Version 0.5.0, <https://github.com/NewGraphEnvironment/wet>.

### Data

- Water temperature: Environment and Climate Change Canada’s hydrometric
  stations ([Environment and Climate Change Canada
  2021](#ref-environmentandclimatechangecanada2021NationalWater)), as
  archived by
  [water-temp-bc](https://github.com/NewGraphEnvironment/water-temp-bc)
  ([Irvine 2025](#ref-irvine2025NewGraphEnvironmentwatertempbc)).
- Air temperature: ERA5-Land ([Muñoz-Sabater et al.
  2021](#ref-munoz-sabater_etal2021ERA5Landstateoftheart)).
- The process model: the Pacific Climate Impacts Consortium’s
  channel-scale output ([Pacific Climate Impacts Consortium
  2026](#ref-pacificclimateimpactsconsortium2026VICGLRavenMBCn)), named
  here and not yet read by this article.
- Streams, lakes, the basin and place names: the Province of British
  Columbia’s Freshwater Atlas ([FLNRORD
  2021](#ref-flnrord2021FreshwaterAtlasb)) and BC Geographic Names,
  through DataBC.

## References

Albers, Sam. 2017. “tidyhydat: Extract and Tidy Canadian Hydrometric
Data.” *The Journal of Open Source Software* 2 (20).
<https://doi.org/10.21105/joss.00511>.

Coleman, Mark A., and Kurt D. Fausch. 2007. “Cold Summer Temperature
Limits Recruitment of Age‐0 Cutthroat Trout in High‐Elevation Colorado
Streams.” *Transactions of the American Fisheries Society* 136 (5):
1231–44. <https://doi.org/10.1577/T05-244.1>.

Dumelle, Michael, Erin E. Peterson, Jay M. Ver Hoef, Alan Pearse, and
Daniel J. Isaak. 2024. “SSN2: The next generation of spatial stream
network modeling in R.” *Journal of Open Source Software* 9 (99): 6389.
<https://doi.org/10.21105/joss.06389>.

Environment and Climate Change Canada. 2021. “National Water Data
Archive: HYDAT.” Service description. Environment and Climate Change
Canada (ECCC).
<https://www.canada.ca/en/environment-climate-change/services/water-overview/quantity/monitoring/survey/data-products-services/national-archive-hydat.html>.

FLNRORD. 2021. “Freshwater Atlas Stream Network - Data Catalogue.”
Published by Ministry of Forests, Lands, Natural Resource Operations and
Rural Development.
<https://catalogue.data.gov.bc.ca/dataset/freshwater-atlas-stream-network>.

Hill, N. E., J. L. Thorley, and A. Irvine. 2025. *Spatial Stream Network
Analysis of Skeena Watershed Stream Temperatures 2025*. Analytic
Appendix. Poisson Consulting.
<https://www.poissonconsulting.ca/analyses/skeena-stream-temp-25/>.

Hill, N. H., J. L. Thorley, and A. Irvine. 2024. *Spatial Stream Network
Analysis of Nechako Watershed Stream Temperatures 2022b*. Poisson
Consulting Analysis Appendix.
<https://www.poissonconsulting.ca/analyses/fish-passage-22b/>.

Hocking, M., C. Whelan, and T. Hatfield. 2022. *Subject Matter Expert
Report: Water Temperature and Ice. Evaluation of Cause – Reduced
Recruitment in the Harmer Creek Westslope Cutthroat Trout Population*.
Consultant's report prepared for Teck Coal Ltd. Ecofish Research Ltd.
<https://www.teck.com/media/Water,-Air-Temp-and-Ice-Harmer-Creek-Evaluation-of-Cause-SME-Report.pdf>.

Irvine, Allan. 2025. *water-temp-bc*.
<https://github.com/NewGraphEnvironment/water-temp-bc>.

Irvine, Allan. 2026a. *cd: How far any BC watershed’s climate has
shifted from your chosen baseline*. New Graph Environment Ltd.
<https://doi.org/10.5281/zenodo.23264994>.

Irvine, Allan. 2026b. *gq: One Set of Map Styles for QGIS, Report
Figures and Web Maps*. New Graph Environment Ltd.
<https://doi.org/10.5281/zenodo.23524719>.

Irvine, Allan. 2026c. *wet: Stream Flow and Water Temperature for the BC
Freshwater Atlas*. New Graph Environment Ltd.
<https://doi.org/10.5281/zenodo.23305781>.

Muñoz-Sabater, Joaquín, Emanuel Dutra, Anna Agustí-Panareda, et al.
2021. “ERA5-Land: A State-of-the-Art Global Reanalysis Dataset for Land
Applications.” *Earth System Science Data* 13 (9): 4349–83.
<https://doi.org/10.5194/essd-13-4349-2021>.

Norris, Simon. 2024. *fwapg*. <https://github.com/smnorris/fwapg>.

Norris, Simon, and Allan Irvine. 2026. *fwapg, newgraph branch*. New
Graph Environment Ltd.
<https://github.com/NewGraphEnvironment/fwapg/tree/newgraph>.

Pacific Climate Impacts Consortium. 2026. “VIC-GL-Raven MBCn CMIP6:
Vector Hydrologic Model Output.” Pacific Climate Impacts Consortium,
University of Victoria, May. <https://services.pacificclimate.org/chyp>.

Pebesma, Edzer, and Roger Bivand. 2023. *Spatial Data Science: With
applications in R*. Chapman and Hall/CRC.
<https://doi.org/10.1201/9780429459016>.

R Core Team. 2025. *R: A Language and Environment for Statistical
Computing*. R Foundation for Statistical Computing.
<https://www.R-project.org/>.

Slowikowski, Kamil. 2026. *ggrepel: Automatically Position
Non-Overlapping Text Labels with ’ggplot2’*.
<https://doi.org/10.32614/CRAN.package.ggrepel>.

Thorley, Joe, and Sarah Lyons. 2026. *gsdd: Calculate Growing Season
Degree Days from Water Temperature Data*.
<https://github.com/poissonconsulting/gsdd>.

Thorley, Joseph L., and Maggie A. Branton. 2022. *Subject Matter Expert
Report: Energetic Status at the Onset of Winter Based on Fork Length and
Wet Weight. Evaluation of Cause – Reduced Recruitment in the Harmer
Creek Westslope Cutthroat Trout Population*. Report prepared for Teck
Coal Limited. Poisson Consulting Ltd. and Branton Environmental
Consulting.
<https://www.teck.com/media/Energetic-Status-Harmer-Creek-Evaluation-of-Cause-SME-Report.pdf>.

Toffolon, Marco, and Sebastiano Piccolroaz. 2015. “A Hybrid Model for
River Water Temperature as a Function of Air Temperature and Discharge.”
*Environmental Research Letters* 10 (11): 114011.
<https://doi.org/10.1088/1748-9326/10/11/114011>.

Wickham, Hadley. 2016. *ggplot2: Elegant Graphics for Data Analysis*.
Springer-Verlag New York. <https://ggplot2.tidyverse.org>.

Xie, Yihui. 2026a. *bookdown: Authoring Books and Technical Documents
with R Markdown*. <https://github.com/rstudio/bookdown>.

Xie, Yihui. 2026b. *knitr: A General-Purpose Package for Dynamic Report
Generation in R*. <https://yihui.org/knitr/>.
