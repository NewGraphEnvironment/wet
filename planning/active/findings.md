# Findings — Article: stream temperature for every reach, from stations to a network model (#220)

## Issue context

**If we do it:** anyone can see in four pictures what growing-season degree days are, where we have temperature and where we do not, and how the pieces get from stations to every reach. **If we never do:** the only public account is the roadmap issue, which is text, assumes the vocabulary, and is written for a modeller.

## Problem

The roadmap (#214) tracks what is being finished and in what order. It is the right place for status and the wrong place to learn the idea: it has no figures, and a reader has to know what a holdout, an open-loop fill or network kriging is before the first section. The functions have reference pages and the methods have research files, but nothing shows how they fit together.

## Proposed approach

One article, `vignettes/articles/segment-temperature.Rmd`, answering the reader's questions in order, each with one figure:

1. **What are growing-season degree days, and why do they matter for fish?** One station's year: the observed days, a gap, the fill across it, and degree days accumulating, with the season's start and end marked.
2. **Where do we have temperature, and where not?** One basin on a map: the stream network, the gauges on it, and the reaches with no station.
3. **How do we get from stations to every reach?** The whole chain as one diagram: observations, fills, catchment traits, air temperature, the baseline, a network model, degree days at every reach. It marks what exists, what is being built and what a network model adds, and where a process model that already exists (PCIC's channel-scale output, #219) sits beside it as a comparison and as a source of future change.
4. **How will we know it works?** The holdout as a sketch: hide a station, predict it from traits, from its nearest neighbours in trait space and from the network, and compare each with the station's own fit.

It closes with what is not known yet: the error at the stations themselves, and the thresholds: growing-season degree-day thresholds exist for cutthroat trout (from Colorado subspecies, applied to westslope cutthroat in the Elk Valley reports), and none has been found yet for the other BC species.

How it is built:

- **Figures come from wet's own functions and a committed bundle** built by a `data-raw/` script, so the site build needs no database. Map layers go through `scripts/vignette_map_lib.R`, with towns labelled and the river named.
- **The diagram is drawn in code,** not pasted in as an image.
- **Plain language.** Each term is defined where it first appears: reach, air2stream, open-loop, holdout, kriging.
- **It says what it stands on:** `fwapg` (Simon Norris) for the network, the Nechako and Skeena network models by their published memos, `gsdd` for the degree-day rule, PCIC for the process model. Citations from a `.bib`, as the other articles do.
- **No status and no counts that move.** The article links #214 for what is done and what is next, and carries no checklist.
- **One address, revised in place.** The page is `articles/segment-temperature.html`, the twin of `segment-discharge`, and the address does not change. This first version is titled for what it is ("Stream Temperature per Segment: How We Get There") and opens by saying the product is not built yet. Once it is, the same page is rewritten to say what the product is and how well it does.
- **Which basin and which station** are picked by a rule written in this issue's plan (a basin the network check has run clean on, a station with a complete season and a real gap), not by eye.

## Out of scope

- Results from the baseline or from the PCIC comparison. The article describes the tests; scores go in when #213 and #219 have run, as a revision.
- A second basin.
- The network model itself.

## Done when

- The article is on the site with its four figures, and rebuilds identically from the bundle.
- A reader with none of our context can say, after reading it, what goes to a network model and what comes back.
- #214 links it at the top.

Relates to #214, #213

## Errors Encountered

| Error | Resolution |
|-------|------------|
