# Code review, round 1: #27 Chinook revision (staged diff + 4dae2da)

Reviewer: general-purpose subagent, 2026-10-01. Method: rendered a copy of the
repo (`pkgload::load_all(); rmarkdown::render()`, cd 0.5.8, ggplot2 4.0.3,
gq 0.16.0, sf 1.1.2), saved the knit environment and recomputed every inline
claim from it, read all five figures, and checked the bundled
`station_daily.rds` and `life_history_bulk.csv` directly.

Confirmed correct (no action): 24% share; 567 / 2,315 km²; 64–96% median;
21 of 24 below q10 (and 21 of 24 also hold by direct rank, at least 90% of
baseline years wetter); 6 below the minimum; lowest = 08EE003 spawning 2024 at
19%; 2022 the only exception, migration and fry migration above at both;
15 of 15 agreement; 24 slopes, 2 significant, both negative, about 1 by
chance; 38 shared days; "from 2000" starts 2011; HYDAT ends March 2025, 2
provisional years; 80% min_frac; scale bar 30 km = max(gq_scale_breaks) in km,
converted to m correctly (329 px on a 95.7 km frame); all layers EPSG:3005;
keymap box sits at Houston; `west` picks 08EE003; label offsets match their
comments; snap row order matches `st` (wet_snap_pick keeps station order);
area is taken before ST_Simplify; NEWS and research numbers match the render.

## Findings

- **[bug] vignettes/station-flow.Rmd:164.** "Chinook incubation and emergence run
  through the winter, when the gauges read under ice." That is false for
  emergence, which is 04-15 to 07-07 in `life_history_bulk.csv` (row 5). It is
  left out only because 15–30 April falls in `ice_months`. The research file's
  wording ("touch November–April") is correct; the vignette's is not.

- **[bug] vignettes/station-flow.Rmd:341-343 (`cap_recent`) and 486-487; also
  research/station_flow_departure.md, new section.**
  - The figure 2 caption says "Bulkley River near Houston (08EE003) has no data
    from 1999, so its baseline is 1981–1998." That reads as "from 1999 on", and
    the same figure draws 08EE003 bars for 2022–2026.
  - The heat-strip prose says it "has no record in 1999–2010". The research file
    says "It has no record in 1999–2010."
  - Neither matches the bundled series. `station_daily.rds` holds approved HYDAT
    days for 08EE003 in every year 2000–2009 (4–7 spot values a year, May–Nov),
    and a continuous record from September 2010 (127 days in 2010). Only 1999
    is empty.
  - What the code computes is different in each place. In the caption it is the
    last baseline year with a qualifying window-year, plus 1. In the prose,
    `gap` is the years with no window-year at 80% or more coverage.
  - Fix: word it as no complete window or no continuous record in 1999–2010,
    not "no data" or "no record".

- **[fragile] vignettes/station-flow.Rmd:571-573 (and the guard at 563).**
  "They are Bulkley timings from Gottesfeld and Rabnett (2007)." The guard
  checks only that all three rows carry the same source key. The bundle's own
  note on the fry_migration row says "citation listed under the other area in
  the template". In knowledge `data/life_history_timing.csv`, the G&R citation
  for BULK fry migration was borrowed from the MORR cell. So for fry migration
  the sentence asserts more provenance than the data records.

- **[fragile] DESCRIPTION:42.** `tmap` is still in Suggests. review-27b.md (rows
  17-18: "it is removed from Suggests") and findings.md ("tmap stays out of
  Suggests") both say otherwise, and nothing in R/, tests/ or vignettes/ uses
  tmap (the vignette calls only `gq::gq_tmap_classes`). Harmless to the check
  itself, but CI installs tmap's dependency tree for nothing, and the planning
  record contradicts the tree.

- **[fragile] vignettes/station-flow.Rmd:160-161 and 282-283.**
  - The intro's window timing ("from May", "August and early September", "from
    mid-July") and the recipe's hardcoded `start`/`end` vectors are typed, not
    derived from `windows`.
  - The only guard (line 57) checks stage names, not dates.
  - They match the bundled CSV today. A refresh of `life_history_bulk.csv` at a
    new knowledge sha would change every number while the prose and the recipe
    (introduced as "the calls that produced the numbers") stay as they are.

/Users/airvine/Projects/repo/wet/planning/active/review-round1.md
