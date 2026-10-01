# Findings — Vignette: flow in species windows at two real-time stations (#27)

## Issue context

**If we do it:** wet has a worked example of its newest path (daily series → windows → departure) on real stations, with its limits stated, and pkgdown is set up for every later vignette. That is half the bar for making wet public. **If we never do:** the station path is documented only by a script (`scripts/station_departure.R`) and a research note.

## Problem

wet has no vignettes and no pkgdown site. The station-departure path (#25) runs from `scripts/station_departure.R`, which needs HYDAT, the water-temp-bc S3 archive and the ECCC real-time feed, so it can't run at build.

## Proposed Solution

- **Scaffold, shared with every later vignette:**
  - `_pkgdown.yml` and the pkgdown workflow;
  - `VignetteBuilder: knitr`, with knitr, rmarkdown, bookdown and ggplot2 in Suggests;
  - `Config/Needs/website` for anything used only at build.
- `data-raw/station_vignette_data.R` → `inst/vignette-data/`, under 500 KB. It holds the 08EE013 and 08EE003 daily series, their window statistics, and a snapshot of the BULK rows of knowledge's `life_history_timing.csv`. The vignette never touches a database or the network at build.
- `vignettes/station-flow.Rmd`, about 150–200 lines, output `bookdown::html_vignette2`, with a word-cap chunk:
  1. Framing: one paragraph.
  2. Recipe: the real calls in a chunk that is not run, plus a hidden loader.
  3. Four figures:
     - **The record by source:** HYDAT, provisional and real-time per station, with the ice share shaded. This shows what every later number rests on.
     - **Daily hydrograph:** the 1981–2010 median and interquartile band, with recent years as lines and the species windows as bands along the axis. This is the key figure.
     - **Departure heat strip:** window × year in % of normal, with provisional and ice-heavy cells marked.
     - **Trends:** Theil-Sen per window for the mean and the 7-day minimum.
  4. Close: "What it does not show".
     - Provisional winter flows are ice readings.
     - Bulkley near Houston was a seasonal gauge until 2010.
     - The mean-based normal is skewed by wet years.
     - The windows come from the literature, not from observation.
- Colours come from a small gq custom registry, with no hex literals. Captions and inline numbers are computed from the data. Figures are referred to in words, not with `\@ref` (it breaks under pkgdown).

Patterns borrowed from the sibling vignettes:
- the shape of drift's `trajectory-break-detection`;
- the data-raw → `inst/vignette-data/` pattern and the "Cached inputs" disclosure from link and cd;
- drift's word cap and gq registry.

Things to avoid: long interpretive paragraphs, copy-pasted captions, multi-MB bundled data, and an ending on a widget.

Relates to #25


## Plan-gate decision (2026-10-01)

Asked whether to keep provisional winter days and note them instead of dropping. Kept the script's drop rule (window touching Nov-Apr drops years with provisional days: uncorrected stage under ice, 6.5-15 vs 0.2-2 m3/s at 08EE013); the vignette states what was dropped, computed from the data (airvine).

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Bundled data (Phase 2, 2026-10-01)

`data-raw/station_vignette_data.R` → `inst/vignette-data/`, 61 KB total (rds xz, 60 KB; csv 1 KB). Retrieved 2026-10-01 with HYDAT 20260717:

| station | hydat | provisional | realtime |
|---|---|---|---|
| 08EE003 | 1930-09-09 .. 2025-03-04 (12,557 d) | 2025-03-05 .. 2026-09-12 (540 d) | 2026-09-13 .. 2026-09-30 (18 d) |
| 08EE013 | 1973-01-01 .. 2025-03-02 (18,620 d) | 2025-03-03 .. 2026-09-12 (559 d) | 2026-09-13 .. 2026-09-30 (18 d) |

The species windows: 12 BULK rows at knowledge `c97c4d0`; CO migration was dropped for having no end, leaving 11. **Wrong turn:** at planning I reported two exact duplicate BULK rows. That came from a `head -3` printed together with a grep of all BULK rows, so the first two rows appeared twice. The script's `duplicated()` check found none.
