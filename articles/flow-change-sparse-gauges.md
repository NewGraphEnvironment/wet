# Rebuilding Stream Flow History Where Gauges Are Few

Many streams that matter to salmon were gauged for only a few summers,
or never. This article uses the R package
[`wet`](https://newgraphenvironment.github.io/wet/) ([Irvine
2026c](#ref-wet)) to rebuild their summer flow history from nearby
gauges, and asks how it has changed since 1951–1980, at four streams in
northern British Columbia that chinook salmon use: Maxan Creek, with
five full summers on record; Swift Creek and Naver Creek, with 14 and
18; and Gosnell Creek, never gauged. One method, fixed before any
result, runs at each and is scored on gauges it was not given.

**The answer.** In the chinook salmon life history timing window for
spawning, mean flow over 2016–2025 was lower than over 1951–1980 at all
four streams, by 15% to 46% from nearby gauges’ departures; at Maxan,
Naver and Gosnell creeks that route’s 90% range stays below no change.
Borrowed, the window’s lowest seven-day flow fell at Maxan, Naver and
Gosnell creeks, clearly only at Maxan, and held at Swift. In the
migration window borrowed mean flow shows no clear change at any stream.
Snow over every catchment peaked lower and melted earlier. Borrowed mean
flow scores worse in the spawning window than in the migration window at
all four under Bulkley windows.

## Where are the four streams?

The four streams are in northern British Columbia, two in the Skeena
system and two in the Fraser. Maxan Creek flows into the upper Bulkley
River near Topley, south-east of Smithers, and Gosnell Creek into the
Thautil River just above the Morice River, south-west of Houston. Naver
Creek flows into the Fraser River near Hixon, south of Prince George,
and Swift Creek into the McLennan River, a Fraser tributary, at
Valemount. Each borrows from gauges in a same-sized box around it.

![Maxan and Gosnell creeks in the Skeena system, with the gauges each
borrows from. The inset locates the map in British
Columbia.](flow-change-sparse-gauges_files/figure-html/skeena-1.png)

Maxan and Gosnell creeks in the Skeena system, with the gauges each
borrows from. The inset locates the map in British Columbia.

![Swift and Naver creeks in the Fraser system, with the gauges each
borrows from. The inset locates the map in British
Columbia.](flow-change-sparse-gauges_files/figure-html/fraser-1.png)

Swift and Naver creeks in the Fraser system, with the gauges each
borrows from. The inset locates the map in British Columbia.

Fisheries and Oceans Canada’s spawner surveys find chinook in Swift
Creek in most years since 1970, with a major spawning site within five
kilometres of its mouth in the provincial records, and in Naver Creek in
most years since the mid-1980s. Gosnell Creek’s record is thinner:
adults found in one survey, in 2001, and three provincial records.

## What is a chinook salmon life history timing window?

A chinook salmon life history timing window, or window for short, is a
stretch of the year when chinook use a stream for a part of their life
cycle. In the upper Bulkley River, the early run of chinook passes
Moricetown Canyon before about July 30, and chinook spawn in August and
September ([Gottesfeld and Rabnett 2007,
355](#ref-gottesfeld_rabnett2007SkeenaFish)). New Graph’s species-timing
table sets the Bulkley’s windows from that report, used here at all four
streams: adult migration from May 1 to August 1, and spawning from
August 1 to September 15. A window’s flow in a year is its mean daily
flow. At every stream, flow peaks inside the migration window, as snow
melts, and in the spawning window falls under a third of its peak.

![Each stream's typical year (1981–2010), with the two chinook salmon
life history timing windows shaded: wet's published daily flow at the
gauge, or at Gosnell Creek's
mouth.](flow-change-sparse-gauges_files/figure-html/windows-1.png)

Each stream’s typical year (1981–2010), with the two chinook salmon life
history timing windows shaded: wet’s published daily flow at the gauge,
or at Gosnell Creek’s mouth.

## Which years are compared?

Each stream’s last ten years, 2016–2025, are compared with 1951–1980,
the three decades before global warming sped up ([Hansen et al.
2012](#ref-hansen_etal2012Perceptionclimate)); ERA5-Land’s snow covers
all of it. [Measured Stream Flow Against Its 1981–2010
Normal](https://newgraphenvironment.github.io/wet/articles/flow-departure-normal.md)
instead measures this decade at two long-record gauges against
1981–2010, a period already holding part of the warming.

## How has flow changed?

Two routes fill in the years a stream was not measured. A gauged
stream’s missing year comes from one nearby gauge, through a fit between
the two over their shared years. Any stream can also borrow nearby
gauges’ departures from their own typical flow, year by year.

![Each chinook salmon life history timing window's mean flow, year by
year, as a share of its 1981–2010 typical flow (log scale). Large orange
points are measured summers; the grey line fills the other years from
one nearby gauge, with the band its fitted relation predicts; the blue
line is borrowed from nearby gauges' year-to-year departures. A small
point is a year with no neighbouring year on its line. Black lines are
the borrowed route's typical departure over 1951–1980 and
2016–2025.](flow-change-sparse-gauges_files/figure-html/years-1.png)

Each chinook salmon life history timing window’s mean flow, year by
year, as a share of its 1981–2010 typical flow (log scale). Large orange
points are measured summers; the grey line fills the other years from
one nearby gauge, with the band its fitted relation predicts; the blue
line is borrowed from nearby gauges’ year-to-year departures. A small
point is a year with no neighbouring year on its line. Black lines are
the borrowed route’s typical departure over 1951–1980 and 2016–2025.

The drop in the chinook salmon life history timing window for spawning
is largest at Maxan and Naver creeks and smallest at Swift Creek, and
filling in each gauged stream’s own record gives drops in the same
direction (27%–57%), clear of no change only at Maxan. Borrowed, the
spawning window’s lowest seven-day flow fell by 26% to 40% at Maxan,
Naver and Gosnell creeks, again clear only at Maxan.

![Change in each chinook salmon life history timing window's mean flow
(top) and its lowest seven-day flow (bottom), from 1951–1980 to
2016–2025 (to 2024 where 2025 is not yet approved), with its 90% range,
by each route the legend
names.](flow-change-sparse-gauges_files/figure-html/change-1.png)

Change in each chinook salmon life history timing window’s mean flow
(top) and its lowest seven-day flow (bottom), from 1951–1980 to
2016–2025 (to 2024 where 2025 is not yet approved), with its 90% range,
by each route the legend names.

The Morice has windows of its own: chinook spawn there from the first
week of September to the first week of October ([Bustard and Schell
2002, 27](#ref-bustard_schell2002ConservingMorice)), so its spawning
window, September 1 to October 7, falls a month later than the
Bulkley’s. Under it Gosnell Creek’s spawning-window drop is smaller,
23%, and its range reaches no change.

## How well does the method score?

| Stream | Filled-in record | Gauges tested | Borrowed, migration | Borrowed, spawning | Gauges scored |
|:---|---:|---:|---:|---:|---:|
| Maxan Creek | 0.50 | 21 | 0.63 | 0.49 | 31 |
| Swift Creek | 0.14 | 11 | 0.51 | 0.43 | 13 |
| Naver Creek | 0.63 | 17 | 0.60 | 0.42 | 24 |
| Gosnell Creek | 0.48 | 18 | 0.65 | 0.45 | 30 |

Held-out scores of each window’s mean flow, over the gauges in each
stream’s box: the median over gauges, where 1 is perfect and 0 is no
better than the average year. The filled-in column is the migration
window’s; Gosnell Creek has no record of its own to fill in. {.table}

Both routes are scored by hiding a gauge’s own record and predicting it
from its neighbours. A score of 0.5 was set as the method’s bar before
any stream was run. The borrowed departures clear it in the chinook
salmon life history timing window for migration in every box and, under
the Bulkley’s windows, fall below it in the spawning window in every
box, 0.42–0.49, so those ranges carry that weaker score. Borrowed, the
lowest seven-day flow scores below the bar in 7 of 8 windows and boxes.
Filling in a record scores poorly in the upper Fraser, with 11 long
enough records to test it, so Swift Creek’s filled-in change is its less
certain route.

## Does snow explain it?

Snow itself changed: over 2016–2025, peak snow over each catchment held
6% to 9% less water than over 1951–1980, and half had melted 9 to 16
days earlier (ERA5-Land ([Muñoz-Sabater et al.
2021](#ref-munoz-sabater_etal2021ERA5Landstateoftheart)), summarised per
year by [`cd`](https://newgraphenvironment.github.io/cd/) ([Irvine
2026a](#ref-cd))).

Flow in the chinook salmon life history timing window for migration
rises with peak snow: the borrowed departures at all four streams, with
90% ranges above zero and 41–51% of their spread explained, and measured
flow at all 8 snow gauges near the streams (named in advance at Maxan
Creek, elsewhere the nearest two with long records), 25–62%. In the
spawning window peak snow explains at most 16% of the borrowed
departures and 31% of measured flow; the melt date explains at most 23%
of the borrowed departures but 64–66% of measured flow on the Nanika and
Morice. ERA5-Land’s 0.1° cells are coarse here.

## Where could it be wrong?

- **Gosnell Creek’s flow is never measured.** Its departures are tested
  only at the gauges around it, and its typical flow is `wet`’s
  published flow for the stream. At 29 gauges in its box with ten or
  more baseline years, that published flow in the chinook salmon life
  history timing window for spawning runs a median 21% above measured,
  and about 60% or more above at a quarter of them.
- **The windows are the Bulkley’s** at all four streams. Only the Morice
  has its own cited windows.
- **Each filled-in year rests on one neighbouring gauge**, and the
  earliest years on whichever single gauge reaches back that far.

## Software and citation

The flows in this article are from HYDAT release 20260717 ([Environment
and Climate Change Canada
2021](#ref-environmentandclimatechangecanada2021NationalWater)). Gosnell
Creek’s typical flow and the hydrographs are `wet`‘s published daily
flow (build 0f4f8ca; for these four streams, routed flow from the
Pacific Climate Impacts Consortium ([Pacific Climate Impacts Consortium,
n.d.](#ref-pacificclimateimpactsconsortiumGriddedHydrologic)), placed on
the Freshwater Atlas by New Graph’s fork of `fwapg` ([Norris and Irvine
2026](#ref-norris_irvine2026NewGraphEnvironmentfwapg))). Snow is
ERA5-Land’s ([Muñoz-Sabater et al.
2021](#ref-munoz-sabater_etal2021ERA5Landstateoftheart)), summarised per
year by `cd`. Spawner surveys are Fisheries and Oceans Canada’s NuSEDS
([Fisheries and Oceans Canada,
n.d.](#ref-fisheriesandoceanscanadaNuSEDSNewSalmon)), release of 1 June
2026; fish observations are the Province of British Columbia’s ([MoE
2024](#ref-moe2024KnownBC)). The streams, lakes and catchments are the
Freshwater Atlas’s ([FLNRORD 2021](#ref-flnrord2021FreshwaterAtlasb)),
held in PostgreSQL by `fwapg` ([Norris
2024](#ref-norris2024smnorrisfwapg)), and place names are BC Geographic
Names’. How each stream was chosen, and how the method is run and
scored, is set out in [`wet`’s research
notes](https://github.com/NewGraphEnvironment/wet/blob/main/research/chinook_sites.md).

The software, each cited:

- [`wet`](https://newgraphenvironment.github.io/wet/) ([Irvine
  2026c](#ref-wet)) reads the gauge records, fills in and borrows the
  window flows, and scores them.
- [`cd`](https://newgraphenvironment.github.io/cd/) ([Irvine
  2026a](#ref-cd)) summarises ERA5-Land’s snow per year.
- [`ggplot2`](https://ggplot2.tidyverse.org/) ([Wickham
  2016](#ref-ggplot2)),
  [`gq`](https://newgraphenvironment.github.io/gq/) ([Irvine
  2026b](#ref-gq)) and [`sf`](https://r-spatial.github.io/sf/) ([Pebesma
  and Bivand 2023](#ref-sf)) make the figures and maps;
  [`knitr`](https://yihui.org/knitr/) ([Xie 2026b](#ref-knitr)) and
  [`bookdown`](https://pkgs.rstudio.com/bookdown/) ([Xie
  2026a](#ref-bookdown)) render the article, all in R ([R Core Team
  2025](#ref-base)).

The data were bundled at `wet` commit `52facd0`; this build ran on `wet`
0.4.33, `cd` 0.6.13, commit 86989e3, `gq` 0.16.1 and commit aa082d0. To
cite `wet`:

Irvine A (2026). *wet: Stream Flow and Water Temperature for the BC
Freshwater Atlas*. New Graph Environment Ltd.
<doi:10.5281/zenodo.23305781> <https://doi.org/10.5281/zenodo.23305781>.
Version 0.4.33, <https://github.com/NewGraphEnvironment/wet>.

## References

Bustard, D, and C Schell. 2002. *Conserving Morice Watershed Fish
Populations and Their Habitat*. Community Futures Development
Corporation of Nadina.
<https://waves-vagues.dfo-mpo.gc.ca/Library/315091.pdf>.

Environment and Climate Change Canada. 2021. “National Water Data
Archive: HYDAT.” Service description. Environment and Climate Change
Canada (ECCC).
<https://www.canada.ca/en/environment-climate-change/services/water-overview/quantity/monitoring/survey/data-products-services/national-archive-hydat.html>.

Fisheries and Oceans Canada. n.d. “NuSEDS-New Salmon Escapement Database
System - Open Government Portal.”
<https://open.canada.ca/data/en/dataset/c48669a3-045b-400d-b730-48aafe8c5ee6>.

FLNRORD. 2021. “Freshwater Atlas Stream Network - Data Catalogue.”
Published by Ministry of Forests, Lands, Natural Resource Operations and
Rural Development.
<https://catalogue.data.gov.bc.ca/dataset/freshwater-atlas-stream-network>.

Gottesfeld, A, and K Rabnett. 2007. *Skeena Fish Populations and Their
Habitat*. Skeena Fisheries Commission.
<https://waves-vagues.dfo-mpo.gc.ca/library-bibliotheque/327687.pdf>.

Hansen, James, Makiko Sato, and Reto Ruedy. 2012. “Perception of Climate
Change.” *Proceedings of the National Academy of Sciences* 109 (37).
<https://doi.org/10.1073/pnas.1205276109>.

Irvine, Allan. 2026a. *cd: Climate Departure Analysis from ERA5-Land
Reanalysis*. New Graph Environment Ltd.
<https://github.com/NewGraphEnvironment/cd>.

Irvine, Allan. 2026b. *gq: Cartographic Style Management Across
Rendering Targets*. <https://github.com/NewGraphEnvironment/gq>.

Irvine, Allan. 2026c. *wet: Stream Flow and Water Temperature for the BC
Freshwater Atlas*. New Graph Environment Ltd.
<https://doi.org/10.5281/zenodo.23305781>.

MoE. 2024. “Known BC Fish Observations and BC Fish Distributions.”
<https://catalogue.data.gov.bc.ca/dataset/known-bc-fish-observations-and-bc-fish-distributions>.

Muñoz-Sabater, Joaquín, Emanuel Dutra, Anna Agustí-Panareda, et al.
2021. “ERA5-Land: A State-of-the-Art Global Reanalysis Dataset for Land
Applications.” *Earth System Science Data* 13 (9): 4349–83.
<https://doi.org/10.5194/essd-13-4349-2021>.

Norris, Simon. 2024. *fwapg*. <https://github.com/smnorris/fwapg>.

Norris, Simon, and Allan Irvine. 2026. *fwapg, newgraph branch*. New
Graph Environment Ltd.
<https://github.com/NewGraphEnvironment/fwapg/tree/newgraph>.

Pacific Climate Impacts Consortium. n.d. “Gridded Hydrologic Model
Output.” <https://data.pacificclimate.org/portal/hydro_model_out/map/>.

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
