# Plan review (#149), Plan agent, spawned 2026-10-29 23:22Z

The agent reviewed the plan against both HEAD articles and spot-checked the merged draft. The findings are condensed below, each with what was done about it. Its full reply is in the session transcript.

## Blockers

- **B1a. The draft said each of the 11 left-out gauges was "an outlet placed off the gauge's river".** Verified false against `data/checks/pcic_routed_compare_20260717.txt`: 6 are placement or snap, 1 is PCIC runoff (08NE039) and 4 are unresolved. Fixed: "which the routed comparison leaves out and attributes one by one".
- **B1b. "Median monthly error within ±10% in every month" is true on all 315 gauges, but the table's 279-gauge column prints +10% (Apr).** Verified: April is +10.4 % on the 279 gauges. Fixed: the bullet says "At all 315 gauges".
- **B2. Name collisions between the two articles** (`v`, `prov`, `map`, `sg`, `classes()`, `pal_map`, `pct()`, `both`). Already resolved in the draft: `vs`/`vm`, `ps`/`pm`, `map`/`bmap`, `sg`/`bs`, the three-argument `classes()`, `pal_outline`/`pal_bmap`, unsigned `pct()` with `signed()`, and `ann` for the yearly frame. Signed values now print with "−" (U+2212); the number check normalises that.
- **B3. Duplicate chunk labels.** Already unique in the draft (the render would stop otherwise).

## Gaps

- **G1. The linked article defines only migration and spawning, not fry migration, and the strips appear before any prose defines a window.** Fixed: the year section names all three windows with their dates, from the bundle, before the hydrographs. The window section links "What is a window?" only for how windows are set.
- **G2. Other mentions.** Fixed: `research/water_balance_method.md:81` (present tense) and the `data-raw/monthly_vignette_data.R:383` comment. `scripts/station_snap_sweep.R:46` was already done. Left alone: `tests/testthat/test-vignette_data.R:1-4`, which lists the data scripts, not the article.
- **G3. 500 KB budget.** Accepted as per bundle. The merged article reads 505 KB across seven files, and the tests and the scripts' checks are keyed per bundle.
- **G4. Redirects.** Checked: `build_redirects()` writes `docs/articles/monthly-flow.html` as a meta refresh to `.../articles/segment-discharge.html` with `noindex`. A meta refresh drops an anchor.
- **G5. The shown recipes and what the data scripts ran.** Added a guard that the bundled daily read's window is the recipe's `spring` 04-15 to 06-15. The rest of the recipe text is not compared to the script; recorded as a residual.
- **G6. Word count.** Same as Phase 1's: 2,372 before.

## Ordering

- O1: done (G1). O2: section order 4 → 5 → 6 kept. O3: the `.Rmd` removal, `_pkgdown.yml` and the redirect landed in two adjacent commits; `check_pkgdown()` was not run between them.

## Scope

- **S1. Small-basins weak against stronger under 1,000 km².** Fixed: the small-basins bullet ends "By monthly score it is still the stronger source under 1,000 km²". The large-basin bullet now says routed PCIC is the stronger over 1,000 km² and at lake outlets.
- **S2. "Closer at most gauges" said twice.** Fixed: the count moves into the section's opening sentence.
- **S3. "Keep every guard".** Read as the data scripts' guards. Article guards are removed only with their sentences, and `progress.md` lists them.
- **Routed is "low in March and April" while the table's lowest month is May.** Fixed: "low from March to May", with the spring guards on months 3–5.

## Acceptance

- **AC1/AC2. Number check, sign-aware and in both directions.** Done. The only new numbers are the 279-gauge yearly scores (21.5 %, 27.2 %, +5.1 %, +9.3 %, 55 %, 66 %, 168), the balance's +10 % April median on 279 and the 315-gauge NSE 0.81. Every number gone belongs to a cut table (month table, NSE group table, Buck Creek spring table, the window table's flow columns), the `drop_of` sentence, or the 290-gauge yearly scores.
- **AC3. Figures.** Done. The Bulkley map, the hydrographs and the error-by-month figure are byte-identical to the old renders. The province map matches a fresh render of the old source (`0948cf24…`); the first baseline render's PNG differed in an environment-only way.
- **AC4. Search and sitemap.** Done. After `build_search()`, neither `docs/sitemap.xml` nor `docs/search.json` names `monthly-flow`.
