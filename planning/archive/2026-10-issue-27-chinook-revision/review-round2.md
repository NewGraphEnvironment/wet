# Code review, round 2: #27 Chinook revision (staged diff + 4dae2da)

Reviewer: general-purpose subagent, 2026-10-01. Method: rendered a copy of the
repo (`pkgload::load_all(); rmarkdown::render()` with the knit environment
saved), recomputed every inline `r` value and caption from that environment,
read figures 1–4, and checked the bundled `station_daily.rds`,
`life_history_bulk.csv` and `station_map.rds` directly.

## Round-1 fixes, checked

- Fix 1 (intro ice sentence): correct. Incubation (Aug 1 – Mar 31) reaches
  Nov–Mar and emergence (Apr 15 – Jul 7) reaches April. `left_out` is derived
  from `ice_months`.
- Fix 2 (08EE003 gap): **the heat prose, the limits bullet and the research
  file are now correct, but the figure 2 caption is not.** See finding 1.
- Fix 3 (fry migration citation): correct. The guard reads `note`; only the
  fry_migration row carries "other area".
- Fix 4 (tmap): removed from Suggests. `gq::gq_tmap_classes()` (gq 0.16.0) is
  plain list code and never touches tmap. No other tmap use.
- Fix 5 (window dates): correct. `w_start` is derived, and the recipe's typed
  starts and ends are pinned by the `stopifnot` at line 73.

Recomputed and correct (no action): 24%; 567 / 2,315 km²; 2023–2026; 64%–96%;
21 of 24; 6 below the minimum (08EE003 migration 2023–2026, 08EE013 migration
2024–2025); lowest = 08EE003 spawning 2024 at 19%; 2022 the only exception
(08EE003 spawning 2022 is 98.9%, so "migration and fry migration" is exact);
15 of 15; 24 slopes, 2 significant, both negative (08EE013 spawning, 08EE003
migration, since 2000); about 1 by chance; 38 shared days (of 55); "from 2000"
starts in 2011; HYDAT ends March 2025, 2 provisional years; gap = exactly
1999–2010; research numbers (126–206%, 0.997 / 0.998); NEWS and README match.

## Findings

- **[bug] vignettes/station-flow.Rmd:345-349 (`cap_recent`).** The rendered
  caption says "Bulkley River near Houston (08EE003) has complete windows in
  1981–1998 only, so that is its baseline." That is false.
  - The same figure draws complete 08EE003 window-years for 2022–2026.
  - `stats` holds complete 08EE003 windows in 1931, 1933, 1944–1951, 1971,
    1980 and 2011–2026.
  - `base_span` comes from `qb`, which is cut to `baseline` years. So its value
    means "within 1981–2010", but the caption drops that qualifier.
  - This is round 1's defect again, one axis over. The fix reworded the
    sentence and kept the unqualified subject. The limits bullet at line 579
    gets this right ("Its 1981–2010 baseline has complete windows in 1981–1998
    only"). The caption needs the same qualifier, e.g. "%s's %s baseline is
    %s."

- **[fragile] vignettes/station-flow.Rmd:348 and 578.** "so that is its
  baseline" (caption) and "has a shorter normal" (limits bullet) both assert
  that 08EE003's span is shorter than `base_text`. Nothing guards that.
  - If a data refresh filled 1999–2010, `base_span[["08EE003"]]` would become
    "1981–2010" and both sentences would still render.
  - The bullet would then read "has a shorter normal. Its 1981–2010 baseline
    has complete windows in 1981–2010 only", which contradicts itself.
  - Every other comparative in the vignette has a `stopifnot`. This one needs
    `stopifnot(base_span[["08EE003"]] != base_text)`.

- **[fragile] research/station_flow_departure.md:50-52 and 62.** The diff makes
  the unchanged "Species windows (#27)" section false, and it still speaks in
  the present tense:
  - Line 50: "`vignettes/station-flow.Rmd` runs the same path over the 11
    complete BULK windows". It now runs 3.
  - Line 52: "the vignette lists every window-year it drops". It no longer
    drops or lists any.
  - The new section's line 62 also says the revision removed "the ice prose".
    The vignette intro still carries ice prose ("when the gauges can read under
    ice").

  A reader landing on line 50 from CLAUDE.md's pointer gets a description of a
  vignette that no longer exists. Mark the older section as the pre-revision
  run, or put it in the past tense.
