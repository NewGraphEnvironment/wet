# Code review, round 1: #27 vignette diff (`git diff origin/main...HEAD`)

Reviewer: subagent, 2026-10-01. Read all four checklists. Nothing in `code-check-spatial.md` applies, because the diff has no spatial code. All probes ran on a copy (`$TMPDIR/wet_review1`), and nothing in the repo was modified apart from this file.

What I checked and found sound:
- Ran the purled vignette with `load_all()` on the copy. All four ggplots build. There are no NA classes in the heat strip and no non-finite anomalies.
- Re-derived every inline number against the bundled data, and each matches the render:
  - 58–81%
  - 44%
  - 6.6–15.0 and 3.9 m³/s
  - 64% / 59%
  - 0.91 / 0.59 / 36%
  - 7 of 11
  - 6 / 0
- Ran `pkgdown::build_site_github_pages()` on the copy with CLAUDE.md removed. It builds, and the workflow's allowlist gate passes (exit 0) on the real `docs/`. pkgdown 2.2 adds `404.md`, `authors.md`, `index.md` and `LICENSE*.md`, and the gate already covers them. `search.json` carries no CLAUDE text.
- No duplicate chunk labels. No hex literals in the Rmd. `.check_packages_used_in_tests` is clean. cd and gq are PUBLIC, so CI can install them through `Remotes`.

## Findings

- **[severity: bug]** vignettes/station-flow.Rmd:169 (caption) and :392-394 (limits bullet). "Bulkley River near Houston ran only in open water until 2010" and "was a seasonal gauge until 2010" are contradicted by the bundled data and by Figure 1 itself:
  - 1971 is a full 365-day year with about 150 HYDAT ice (B) days.
  - 1980–1998 carry some B days.
  - 2000–2009 hold only 4–7 days a year, which is a near-absent record rather than open-water seasons.

  `first_full` takes the first year of the *last* run of ≥360-day years (2011), so "until 2010" is right only as "year-round only since 2011". A reader comparing the caption with the bar chart directly above it will see the 1971 bar. A related gap: the trend figure's "Since 2000" points for 08EE003 are really 2010/2011–2026 slopes (n_years 14–16), because nothing exists in 2000–2009.

- **[severity: bug]** vignettes/station-flow.Rmd:284-286 vs :297-309/:328. The prose says the provisional-winter drops are "the same at both stations" (BT incubation 2024–2025; CH emergence 2025–2026; CH incubation 2024–2025; CO spawning 2025; ST spawning 2025–2026). In Figure 3, `no_baseline` is assigned after `dropped` and overrides it. As a result, 08EE003 shows only 3 "Provisional winter, dropped" cells (CH emergence 2025–26, CO spawning 2025), against 9 at 08EE013; the incubation and ST spawning drops render as "Under 10 baseline years". The sentence and the figure the reader is looking at disagree about 6 cells. `drop_text` is built from `stats$dropped` and does not exclude `thin` periods, while the figure does.

- **[severity: fragile]** vignettes/station-flow.Rmd:226, :234-236. "In the Chinook spawning window, both stations ran X%–Y% below normal in every year from A to B" hardcodes "both stations", "below" and "every year", while X, Y, A and B are computed. Three gaps:
  - `pct()` takes `abs()`, so a positive anomaly after a data refresh would still print as "below".
  - Nothing checks that `spawn` has 4 rows per station. If the refresh runs in early January, `last_year` becomes a year with no CH spawning window-year, yet the sentence still says "every year from 2023 to 2027".
  - No `stopifnot` guards the claim, unlike the colour classes.

  This is true today: all 8 rows are −58.5 to −81.5.

- **[severity: fragile]** vignettes/station-flow.Rmd:356-357, :364-366. "Of the slopes significant at p < 0.05, 6 are negative and 0 positive" counts CH spawning and SK spawning separately. Both windows are 08-01–09-15 in the bundled table, so the series and slopes are identical (08EE013 window mean from 2000: −1.804, p 0.0343, twice). The two significant 08EE013 window-mean slopes are one result counted twice, so there are 5 distinct results. The denominator is also unstated: 76 slopes are tested, and about 4 would reach p < 0.05 by chance, so "6 of 76" reads very differently from "6".

- **[severity: fragile]** man/wet-package.Rd. The DESCRIPTION URL change regenerates this file (it adds the pkgdown URL to "Useful links"). The regenerated copy is modified in the working tree but in none of the branch's commits, so the committed docs are stale relative to DESCRIPTION. Commit it with the branch.

- **[severity: fragile]** data-raw/station_vignette_data.R:44. `hydat = basename(dirname(hydat))` takes the "HYDAT release" from the directory name, not from the database. With `WET_HYDAT` pointed at tidyhydat's default location, for example, the vignette's Cached inputs line would print a folder name as the release. Read it from HYDAT's own `VERSION` table on the connection already opened at line 37.
