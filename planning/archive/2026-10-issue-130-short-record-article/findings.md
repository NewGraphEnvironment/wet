# Findings — Article: flow change at an ungauged stream, the Maxan Creek Chinook windows (#130)

## Issue context

**If we do it:** a reader can see how Chinook-window flow has changed at a stream with almost no gauge record, Maxan Creek, how sure we are, and how much of the change follows snowpack and melt timing. **If we never do:** the Maxan answer lives only in `research/` and two text reports, which no outside reader will open.

## Problem

The Maxan pilot (#120) and the snow regression (#121) are written up for us: `research/station_flow_departure.md` ("Departures at an ungauged site: the Maxan pilot" and "Snow and the window flows at the pilot"), `data/checks/departure_pilot_20260717.txt` and `data/checks/departure_snow_20260717.txt`. No article, README or vignette mentions Maxan. `vignettes/station-flow.Rmd` shows gauged departures at 08EE013 and 08EE003 in the same Chinook windows, but not an ungauged site.

## Proposed approach

An article (pkgdown vignette) on flow change at an ungauged stream, Maxan Creek as the example, in the order a reader asks:

1. **What changed.** Maxan's migration- and spawning-window flow from 1931, observed in 1975–1979 and extended from neighbouring gauges otherwise, with its 90 % band; the change between the years before 1981 and 2011–2025.
2. **How we know.** Record extension and donor-carried departures in a sentence each, with their held-out scores, and the map of Maxan, Buck and Houston.
3. **Why.** Each year's peak snow and melt date (`wet_snow_annual()`) against the window flow at the three gauges; the snow change since 1950.
4. **Limits.** One donor per extended year, Houston containing Maxan, ERA5-Land's cell size.

Data from a `data-raw/` script into `inst/vignette-data/`, held to the tracked reports, as the other articles are; colours from gq; the writing convention of #110.

**What #122 decided (2026-10-27).** Across the province, donors chosen by how well PCIC's modelled years correlate with the target's carry departures best: median held-out NSE 0.72, against 0.67 for the nearest donors #120 used. PCIC's own departures (0.48) and a half-and-half blend (0.71) do not ship (`research/pcic_hydrology.md`, #122 section). At Maxan itself, on its five years and from the province pool, nearest donors score 0.74 and covariance-picked donors 0.64, with PCIC alone at 0.54.

**Decide first:** which donors carry Maxan's departures in the article's headline. The registered rule's winner, covariance-picked, is the consistent choice, with Maxan's own five-year scores given beside it. Nearest donors would be a choice the rule did not make, and the article would have to say so. Either way, after 2012 only donors carry values, and the extended record (question 1) is unaffected.

Relates to #118, #120, #121, #122, #27

## Exploration (2026-10-27)

- The covariance-picked donors #122 would give Maxan: 08EE013, 08JE004 (Tsilcoh), 07EE009 (Chuchinka), 08KC003 (Muskeg), 08JC017 (Corkscrew), 1973-2025; the nearest-donor series in #122's province pool adds 08FE003 (Kemano, coastal) and 08ED001.
- The pilot's carried donors at Maxan (box pool): 08EE013, 08EE003, 08EE008, 08JA016, 08EE020; its extension chain: 08EE013, 08EE008, 08EE004, 08ED002, 08ED001.
- `scripts/departure_snow.R` saves nothing but its report; the report's per-year snow table is rounded to whole mm and days.

## Errors Encountered

| Error | Resolution |
|-------|------------|
