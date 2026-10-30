# Task: Next pass on the two flow-change articles: retitle to measuring vs rebuilding, cited comparison periods, measured snow and seven-day flow, citations from a .bib (#152)

**If we do it:** the two listed flow-change articles say plainly what each does differently. One measures flow at long-record gauges; the other rebuilds flow history where gauges are few. Each compares periods chosen for a stated, cited reason, and both cite from a script-written `.bib`. The rebuilt article also gains what only the stored Maxan article said: snow fitted at measured gauges, and the lowest seven-day flow. **If we never do:** the titles read as the same article twice, "since 2011 against before 1981" and "the last five years against 1981–2010" sit side by side with no reason given for either, and the comparison article keeps hand-typed references.

## Context

The two listed flow-change articles read as the same article twice. Their titles do not say how they differ. They compare different periods, "since 2011 against before 1981" and "the last five years against 1981–2010", and neither gives a reason. The comparison article also keeps hand-typed references. This pass:

- retitles each article for what it does: measuring, or rebuilding;
- moves both to a cited reference period and the decade 2016–2025;
- adds measured snow and the lowest seven-day flow to the rebuilt article;
- writes all three articles' references from a script-made `.bib`.

## Decided at the gate

- **Issue body (user, 2026-10-30):** the titles, the addresses (unchanged), the periods, the citation of 1981–2010, and what moves from the stored Maxan article.
- **The recent decade is 2016–2025 in both articles (user, 2026-10-30, at this gate).** Consequences:
  - Rebuilt article: approved HYDAT ends in 2024 at Maxan and Gosnell, so they have 9 recent years (2016–2024). Swift has 10 on both routes, and Naver 10 on its filled-in migration route and 9 on the others.
  - Measured article: Buck Creek (08EE013) has no 2016 in either window, so it has 9 bars per window and 9 years in its change. The Bulkley gauge has 10. 2025 is partly provisional. 2026 is dropped.
- **Part A, counted at the gate on m4** from `data/departure/departure_site_*_20260717.rds`: every stream reaches 1951–1980.
  - Borrowed departures: 20–28 of its 30 years per series.
  - Filled-in record: 27–30 years.
  - So no stream forces a different period, and A stays a recorded count (Phase 1), not a decision.

## Phase 1: The count (A), recorded

- [x] On m4, per site, window and route: count the years in 1951–1980 and 2016–2025, and name the gauges each 1951–1980 year rests on (extension donors from `mx$e`, carried donors from `mx$a$donors`). Write the counts to `findings.md`.

## Phase 2: Does the 90% range hold its coverage at ten years?

- [ ] Rebuilt article: coverage measured inside each site run (Phase 3), because the residual pools its interval draws from exist only there (correction, findings.md).
- [x] Measured article: write `scripts/departure_interval_coverage.R`.
  - Register its rule in the header, committed before any body code.
  - It simulates each article's interval at the period lengths it uses: the measured article's percentile bootstrap of a ratio of means (30 or 18 baseline years against 9 or 10 recent), and the rebuilt article's year-resampling bootstrap (20–30 against 9–10).
  - Rule: coverage of 87% or more keeps the name "90% range". Under 87%, each article calls it "the middle 90% of resampled changes" and cuts every count that rests on it.
  - Report: `data/checks/departure_interval_coverage.txt`.
- [x] Run it and commit the report (measured article: 0.834–0.867, under 0.87, so resamples, no count). The outcome feeds Phases 4, 5 and 7.

## Phase 3: The site runs gain the new periods (B1, B3)

- [ ] `scripts/departure_site.R`: register the #152 addition in the header before the body code. It adds a new report section with the change from 1951–1980 to 2016–2025:
  - both routes, every statistic and window;
  - each period's years;
  - a 90% interval from 2000 draws under `set.seed(152)`, taken after #126's draws;
  - the gauges the 1951–1980 years rest on.
  
  `mx_core` and #126's own pre-1981/2011–2025 lines stay as they are, so the parity gate against #120 still holds.
- [ ] `scripts/departure_site_snow.R`: register and add snow before and after over 1951–1980 against 2016–2025, beside the new flow change. The fits and the parity gate are unchanged.
- [ ] Commit, then on m4 check out the branch in its clean main checkout. Rerun from a frozen copy:
  - `departure_site.R` for maxan, swift, naver and gosnell (two window sets for gosnell);
  - then `departure_site_snow.R` for each.
  
  Logs go to `data/logs/152/`. Commit the regenerated `data/checks/departure_site*_20260717.txt`, and return m4 to `main` at the end.

## Phase 4: The bundle (`data-raw/chinook_sites_data.R`)

- [ ] `change` becomes 1951–1980 against 2016–2025, with min7 kept, every row held to the new section's lines.
- [ ] `years` gets period lines on the new periods.
- [ ] New: snow before and after at each site (peak SWE, 50% melt date), held to the snow report's new lines.
- [ ] Update the header. Run on m4 at the committed tree (`vd_commit()`) and commit `inst/vignette-data/chinook_sites_values.rds`.

## Phase 5: The rebuilt article (`vignettes/articles/flow-change-sparse-gauges.Rmd`)

- [ ] Title: "Rebuilding Stream Flow History Where Gauges Are Few".
- [ ] The answer, change figure, years figure and their guards move to 1951–1980 against 2016–2025. Each count is held to Phase 2's outcome.
- [ ] Add the lowest seven-day flow beside the window mean at all four streams (B2).
- [ ] Add measured snow (B3):
  - the snow change over the two periods;
  - the fits at each site's snow gauges, beside the borrowed departures;
  - the ERA5-Land grid caveat (about 0.1° cells);
  - Muñoz-Sabater et al. (2021) and `cd` cited.
- [ ] Say why each period was chosen, cited:
  - Hansen et al. (2012) for 1951–1980;
  - ERA5-Land snow starts in 1950;
  - one sentence on what the measured article does differently, linked.
- [ ] Switch to pandoc citations (`bibliography:`, `::: {#refs}`). Drop the hand-typed references and the `wet_software_cite()` call. Software is cited inline at first mention.
- [ ] Do the writing-conventions pass. Keep the 1,000-word cap, with a `stopifnot()` behind every quoted number.

## Phase 6: References (B4, C4, D: Zotero)

- [ ] Add the missing works to the group library through the Web API:
  - WMO-No. 1203 (2017);
  - Werner et al. (2019), PNWNAmet;
  - Chapman et al. (2018).
  
  Already there: Hansen 2012, Arguez and Vose 2011, Moriasi, Nash and Sutcliffe, Muñoz-Sabater 2021, Schnorbus 2018 and Craig et al. 2020.
- [ ] **Needs the user:** Better BibTeX answers "No endpoint found" on m1, because Zotero disabled it after its update. Please reinstall the BBT line that matches this Zotero (Plugins → gear → Install Plugin From File), then restart Zotero so the new items get keys. Until then, every phase that does not need a `.bib` runs first.
- [ ] Run `Rscript data-raw/vignette_bib.R` on all three articles. Commit each `.bib`.

## Phase 7: The measured article (`vignettes/flow-departure-normal.Rmd`)

- [ ] Title and `VignetteIndexEntry`: "Measured Stream Flow Against Its 1981–2010 Normal: Two Long-Record Gauges".
- [ ] Make `recent` 2016–2025, with Buck Creek's missing 2016 handled and said once.
- [ ] Recompute the bars, the change figure and the year figure's recent lines, and rewrite every claim and guard from the new numbers.
- [ ] The change range follows Phase 2's outcome.
- [ ] Cite 1981–2010 in the sentence that defines the normal, in place of the bare WMO sentence:
  - Arguez and Vose (2011, p. 699) and WMO-No. 1203;
  - it is the period `wet`'s published flows are normals of: `climr` for the balance, and routed PCIC's 1981–2010 run (Schnorbus 2018, Craig et al. 2020, Werner et al. 2019);
  - it already contains part of the warming (Hansen et al. 2012).
- [ ] One sentence on what the rebuilt article does, linked.
- [ ] Rerun its `.bib`. This adds Gottesfeld's url and drops the six uncited entries. Keep the 700-word cap.

## Phase 8: segment-discharge's `.bib` (D)

- [ ] Re-key its package citations to `@<pkg>` and R to `@base`, then run `vignette_bib.R` on it.
- [ ] Render it and check the reference list matches the old one apart from the keys.

## Phase 9: Titles and records (E)

- [ ] README "Learn more" lines get the new titles. `_pkgdown.yml` names paths only (checked, no change).
- [ ] Revise `CLAUDE.md`'s article paragraphs for the new titles, periods and `.bib`. `wet_software_cite()` stays for `short-record-flow`.
- [ ] Revise `research/chinook_sites.md` and `research/station_flow_departure.md` for the new periods and results.

## Owed at the end (reported, done after merge)

- [ ] Check the live site shows both new titles and the article addresses unchanged.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- **Site runs:** the parity gates (#120, #121) still pass on the maxan run, and #126's own lines in every report are unchanged apart from the new section (`git diff` of the reports).
- **Bundle:** every new value is held to its report line by the data script, and other elements are `identical()` to the old bundle where untouched.
- **Articles:** install the branch, then build each article with `pkgdown::build_article()`. Every guard holds, the word caps hold, and no footnote marker appears. Diff the rendered text before and after to confirm only the intended prose moved.
- **References:** each `.bib` is written by the script, with no hand edits. The rendered reference lists are complete, with no `???`.

