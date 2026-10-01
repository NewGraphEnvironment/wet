# Task: Vignette: flow in species windows at two real-time stations (#27)

## Problem

wet has no vignettes and no pkgdown site. The station-departure path (#25) runs from `scripts/station_departure.R`, which needs HYDAT, the water-temp-bc S3 archive and the ECCC real-time feed, so it can't run at build.

## What I found that shaped the plan

- **Repo.** wet is **PRIVATE** and Pages is not enabled (the Pages API returns 404). The standard r-lib pkgdown workflow still builds the site and pushes `gh-pages`, but nothing serves it until the repo goes public and Pages is turned on. That switch belongs to the public flip, not to this issue.
- **The species-timing CSV.** knowledge `data/life_history_timing.csv` (knowledge is private; pinned at `c97c4d0`, 2026-09-30) has 12 BULK rows. CO migration has no `end`, which leaves 11 usable windows: CH migration, spawning, incubation, emergence and fry_migration; CO spawning; ST spawning; SK spawning; BT migration, spawning and incubation. Most rows carry the note "no source in template; to confirm with knowledge holders", and the vignette's limits section will say so. (Corrected in Phase 2: the planning-time claim of two duplicate rows was wrong. It came from reading `head -3` and a grep together, so the first two rows were printed twice.)
- **Sibling patterns** (drift `origin/main`, since the local clone is stale):
  - the `wordcount` chunk in `vignettes/articles/temporal-composition.Rmd`, which strips the YAML, code fences and inline R, then `stop()`s over the cap;
  - the gq registry built as `gq_reg_merge(gq_reg_main(), gq_reg_custom(system.file("cartography", "<x>.csv", package = ...)))` → `gq_tmap_classes()` → named `values` and `labels`, with a `stopifnot()` on the class set;
  - `_pkgdown.yml` with `url` plus `bootstrap: 5`;
  - `pkgdown.yaml`, the r-lib template with a job-level concurrency group.
- **What the script does that the vignette reuses:**
  - the provisional-winter drop: a window touching Nov–Apr drops any year that has provisional days;
  - the `min_baseline = 10` refusal;
  - baseline 1981–2010;
  - `trend_start`.
  - Its MAD and `frac_below` machinery is **not** needed: none of the four figures uses `frac_below`, so the vignette needs no `wet_station_select()` and no HYDAT at build.
- **Installed:** cd 0.5.0 (public), gq 0.14.0 (public), bookdown, ggplot2, knitr, rmarkdown, pkgdown, Kendall and zyp.

### Three deviations from the issue text

1. **Window statistics are computed live in the vignette** from the bundled daily series, not bundled. `wet_window_stats()` is pure and needs no network, so running it demonstrates the package and avoids holding the same fact twice. If it proves slow at build (more than about 10 s), I'll fall back to bundling.
2. **The vignette's packages go in `Suggests`, not `Config/Needs/website`.** That covers knitr, rmarkdown, bookdown, ggplot2, gq, Kendall and zyp. Vignettes are also built under `R CMD check`, so `Config/Needs/website` should hold only pkgdown-only extras. There may be none, in which case the field is omitted rather than invented.
3. **No patchwork.** The species windows are drawn as strips inside the hydrograph panel, below the data on the same log axis, rather than as a second stacked plot. That keeps the dependency count down.

## Phase 1: pkgdown scaffold

- [x] `_pkgdown.yml`: `url: https://newgraphenvironment.github.io/wet/` and `template: bootstrap: 5`. No `reference:` section, so pkgdown lists every export and `check_pkgdown()` can't fail on a missing one.
- [x] `.github/workflows/pkgdown.yaml`: the r-lib template as in drift, with `needs: website`.
- [x] `DESCRIPTION`:
  - add the pkgdown site to `URL`;
  - `VignetteBuilder: knitr`;
  - Suggests: `bookdown`, `ggplot2`, `gq`, `Kendall`, `knitr`, `rmarkdown`, `zyp`;
  - Remotes: add `NewGraphEnvironment/gq`.
- [x] `.Rbuildignore`: `^_pkgdown\.yml$`, `^docs$`, `^pkgdown$`, `^data-raw$`. `.gitignore`: `docs/`, `vignettes/*.html`, `vignettes/*_files/`.
- [x] Verify with `pkgdown::check_pkgdown()` and a local `pkgdown::build_site()` (reference pages only).

## Phase 2: bundled data

- [x] `data-raw/station_vignette_data.R`, run against `data/hydat/20260717/Hydat.sqlite3`:
  - `wet_station_daily(c("08EE013", "08EE003"), hydat)`, trimmed to the columns the vignette uses, → `inst/vignette-data/station_daily.rds` (xz).
  - The knowledge CSV is fetched at a **pinned SHA** via `gh api`. The BULK rows, deduplicated and with incomplete rows dropped (each drop logged by the script), go to `inst/vignette-data/life_history_bulk.csv`.
  - Provenance (HYDAT release, knowledge SHA, retrieval date, per-source date ranges) is stored with the rds, so the vignette's "Cached inputs" note is computed, not typed.
- [x] `tests/testthat/test-vignette_data.R`, written first:
  - total `inst/vignette-data/` size under 500 KB;
  - the expected columns, and every `start`/`end` matching `MM-DD`;
  - no duplicate windows;
  - both stations and all three sources present.
- [x] Run the script and commit the data together with the test.

## Phase 3: vignette

- [ ] `inst/cartography/wet_station.csv`, a gq custom registry. The class layers are:
  - `record_source`: HYDAT open water, HYDAT ice, provisional, real-time;
  - `departure_class`: binned % of normal, diverging;
  - `recent_year`: lines for 2023–2026, plus the baseline band;
  - `station`.
  - Hex values appear only in this CSV, with the source palette noted per row (Okabe-Ito or ColorBrewer, as in drift). The vignette asserts the class sets.
- [ ] `vignettes/station-flow.Rmd` (`bookdown::html_vignette2`, about 150–200 lines):
  1. Framing: one paragraph.
  2. Recipe: an `eval = FALSE` chunk with the real calls (`wet_station_daily()`, `wet_window_stats()`, `cd_baseline()`/`cd_anomaly()`/`cd_trend()`), then a hidden loader that reads `inst/vignette-data/` and builds the windows from the CSV.
  3. **The record by source:** annual day counts per station, stacked by source, with ice days shaded within HYDAT.
  4. **Daily hydrograph** (the key figure): the 1981–2010 median and IQR per day of year, drawn only on days with at least 10 baseline years, so 08EE003's missing winter baseline shows as a gap. Recent years are lines, with provisional days dashed. The species windows are strips under the data. Log y axis, one facet per station.
  5. **Departure heat strip:** window × year of the `q_mean` anomaly (% of 1981–2010 normal, binned), faceted by station. Provisional cells and ice-heavy cells (more than half the days ice) are marked. Provisional-winter cells and windows with too few baseline years are shown as not computed, not hidden.
     - **The drop rule stays as in the script**: a window touching Nov–Apr drops any year with provisional days, because provisional winter flow is uncorrected stage under ice. The vignette **says what was dropped**, in a sentence computed from the data that lists each station's dropped window-years (e.g. "CH incubation 2025 at 08EE013"). It gives the reason in one line, with Buck Creek's provisional and approved winter flows computed from the bundled series.
  6. **Trends:** Theil-Sen slope (%/yr) per window for `q_mean` and `q_min7`, by station, with Mann-Kendall p < 0.05 marked.
  7. **What it does not show:**
     - provisional winters are ice readings;
     - 08EE003 was a seasonal gauge until 2010;
     - a mean-based normal is skewed by wet years;
     - the windows come from the literature, and most are not yet sourced;
     - plus a "Cached inputs" disclosure.
  - Captions and inline numbers are computed. Figures are referred to in words. A `wordcount` chunk enforces a cap of about 900 words, set from the first draft.
- [ ] README: one line linking the vignette or site. CLAUDE.md: name the vignette and its `data-raw/` script under "Station flow departure".

## Phase 4: verification

- [ ] `rmarkdown::render()` the vignette. Read every figure PNG and self-review: is each prominent element in a legend, is there a hierarchy, is the type readable at about 700 px?
- [ ] `pkgdown::build_site()` locally: the article renders, with no `\@ref`.
- [ ] `devtools::document()`, `lintr::lint_package()` and `devtools::test()`.
- [ ] `devtools::check()` with vignettes. Report the result, including anything skipped.
- [ ] Spawn a Plan review once the baseline lands, running concurrently and not as a gate. Fold its findings in as they arrive.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Out of scope and follow-ups

- Enabling GitHub Pages happens at the public flip.
- **knowledge CSV defect**: CO migration has no end. I'll put a draft issue for knowledge in the final report and won't file it unasked.
- No R-CMD-check workflow is added; the issue doesn't ask for one.
