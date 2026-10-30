# Findings — Next pass on the two flow-change articles (#152)

## Issue context

**If we do it:** the two listed flow-change articles say plainly what each does differently. One measures flow at long-record gauges; the other rebuilds flow history where gauges are few. Each compares periods chosen for a stated, cited reason, and both cite from a script-written `.bib`. The rebuilt article also gains what only the stored Maxan article said: snow fitted at measured gauges, and the lowest seven-day flow. **If we never do:** the titles read as the same article twice, "since 2011 against before 1981" and "the last five years against 1981–2010" sit side by side with no reason given for either, and the comparison article keeps hand-typed references.

**Scope changed 2026-10-30 (user):** this issue is now the next pass on both listed flow-change articles, so each is edited once:
- the comparison article, which this issue held already;
- `vignettes/flow-departure-normal.Rmd`, shipped in #145.

The stored Maxan article (`vignettes/short-record-flow.Rmd`) stays as it is. It is not published, and #148 is closed. Two of its findings move here (part B).

## Decided (user, 2026-10-30)

- **Titles:**
  - "Measured Stream Flow Against Its 1981–2010 Normal: Two Long-Record Gauges" for `flow-departure-normal`;
  - "Rebuilding Stream Flow History Where Gauges Are Few" for `flow-change-sparse-gauges`.

  Each title says what the article does (measuring; rebuilding), not the species or the place. **The addresses stay as they are** (user, 2026-10-30): `articles/flow-departure-normal.html` and `articles/flow-change-sparse-gauges.html` still describe the articles, and renaming them again would stack a second redirect on today's. Only the titles change: each article's `title:`, its `VignetteIndexEntry`, the README's "Learn more" lines and `_pkgdown.yml` if it names them.
- **Periods:**
  - Rebuilt article: **1951–1980 against the last 10 years**. 1951–1980 is the three decades before warming accelerated, the reference Hansen et al. (2012) used and `cd` uses. It also starts when ERA5-Land's snow does (1950).
  - Measured article: **the last 10 years against the 1981–2010 normal**. It cannot reach 1951–1980: Buck Creek's record starts in 1973.
- **Every use of 1981–2010 is cited as tightly as possible, with real references.** Give the reason in one sentence and back each part with a source a reader can open:
  - 1981–2010 is a WMO climatological standard normal period: Arguez and Vose (2011, p. 699), and WMO-No. 1203 (2017) for the definition.
  - It is the period `wet`'s published flows are normals of: the water balance runs on `climr`'s 1981–2010 normals, and routed PCIC is the 1981–2010 run. Cite `climr` and PCIC's data and model papers.
  - Say plainly that it already contains part of the warming, citing Hansen et al. (2012), which is why the rebuilt article measures change from 1951–1980 instead.
- **Moved from the stored Maxan article:** measured snow, and the lowest seven-day flow (below). Not moved: Foxy Creek, Maxan's catchment area, its own five-summer scores, and the small-flow caveat. Maxan's chinook use stays with #137.

## Proposed

### A. Count first: can every stream reach 1951–1980?

Before any edit, count each of the four streams' years in 1951–1980, per route (filled record and borrowed departures), from `scripts/departure_site.R`'s series. Name the gauges each early year rests on. Early years lean on one or two long gauges (Maxan's on the Bulkley at Quick). If a stream has too few years, decide the period with the user before writing. The site reports' "years before 1981 by source" lines are the starting point.

### B. Rebuilt article (`vignettes/articles/flow-change-sparse-gauges.Rmd`, new title)

1. **Change, 1951–1980 against the last 10 years**, with `scripts/departure_site.R` re-run for the new periods and its reports regenerated. The 90% range's method must hold its coverage at the recent period's ten years, or be labelled as resamples, and no count may rest on a range that does not (measured in #145's review: a percentile bootstrap of five years covered 82%).
2. **The lowest seven-day flow** beside the window mean at all four streams. All four site reports already compute it (`min7`); at Maxan the spawning window's fell about two thirds.
3. **Snow, measured.** The snow itself changed: at Maxan, half the snowmelt came about ten days earlier in 2011–2025 than in 1950–1980, and peak snowpack held less water. Add the fits at the measured snow gauges (08EE003 and 08EE013 for Maxan; each site's `snow_gauges`), not only the borrowed departures, from `data/checks/departure_site_snow_*_20260717.txt`. Include the grid caveat: ERA5-Land cells of about 0.1°, coarse for a small watershed. Cite ERA5-Land (Muñoz-Sabater et al. 2021) and `cd`: hourly reanalysis from 1950, aggregated to annual layers over British Columbia, published as COGs with a STAC catalogue.
4. **Citations from a `.bib`:** `data-raw/vignette_bib.R vignettes/articles/flow-change-sparse-gauges.Rmd`. Add Hansen et al. (2012) (PNAS, doi 10.1073/pnas.1205276109) and WMO-No. 1203 to the group library first.
5. The pass against the organisation's writing conventions, as #145 did; keep the word cap and a guard on every quoted number.

### C. Measured article (`vignettes/flow-departure-normal.Rmd`, new title)

1. **The last 10 years against the 1981–2010 normal:** the bars, the change figure and the year figure's recent lines. Recompute every quoted number. Its change range takes the same method as B1.
2. The tight 1981–2010 citation above, in the sentence that defines the normal. It replaces the bare WMO sentence.
3. One sentence saying what the rebuilt article does differently, and linking it (writing.md "Write each article to stand alone": the sentence, not a reliance on it).
4. **Rerun `data-raw/vignette_bib.R` on it** once Better BibTeX answers again: it went down after a Zotero update on 2026-10-30. The committed `.bib` lacks the Gottesfeld and Rabnett 2007 url, which was set on the Zotero item after the last export, and still holds six entries the article no longer cites (Theil, Sen, Mann, Kendall 1975, and the `Kendall`/`zyp` packages).

### D. segment-discharge

Run `data-raw/vignette_bib.R` on `vignettes/segment-discharge.Rmd` so its hand-written `.bib` comes from Zotero too. Add Chapman, Moriasi and Nash to the group library first. This re-keys its package entries to `@<pkg>` and R to `@base`.

### E. The helper

`wet_software_cite()` stays while the stored Maxan article calls it; that article is not being edited. Update `CLAUDE.md`'s article paragraphs for the new titles and periods.

Relates to #110, #137, #145, #149


## Gate exploration (2026-10-30)

- The site series live on m4 only (`data/departure/`, gitignored); m1 has none. The #126 runs and logs (`data/logs/126/`) are m4's.
- Years per series (m4, `mx[[...]]`): carried 1951–1980: maxan 20–21, gosnell 21, naver 26–28, swift 27–28; extended 1951–1980: maxan 30 (5 observed), naver 30 (18 observed), swift 27–28. 2016–2025: 9 at maxan/gosnell/naver carried (last 2024), 10 at swift (last 2025) and naver's extended migration mean.
- `departure_site.R`'s parity gate compares `mx_core` (pre < 1981, post 2011–2025, `diff`, `ci`, `carried`) with the pilot's `mx`, so the new periods are added after `mx_core`, never inside it.
- Measured article bundle `station_daily.rds` ends 2026-09-30; 08EE013 has no 2016 window-year in either window.
- Better BibTeX on m1: `curl -A curl/8 http://127.0.0.1:23119/better-bibtex/cayw?probe=true` returns "No endpoint found": Zotero answers, BBT is not loaded.
- Group library (libraryID 9) already holds hansen_etal2012Perceptionclimate, arguez_vose2011DefinitionStandard, moriasi_etal2007Modelevaluation, nash_sutcliffe1970Riverflow, munoz-sabater_etal2021ERA5Landstateoftheart, schnorbus2018VICGlacierVICGL, craig_etal2020Flexiblewatershed. Missing: WMO-No. 1203, Werner et al. 2019 (PNWNAmet), Chapman et al. 2018 (`chapman_etal2018Wateralloc` is hand-written in segment-discharge.bib).

## Phase 1: the count (A), measured on m4 2026-10-30

Years in 1951–1980 / 2016–2025 per series, from `data/departure/departure_site_*_20260717.rds` (`mx[[...]]`), with the gauges the 1951–1980 years rest on (carried: the `donors` strings of those years; extended: `e$donor` counts):

| site (windows) | carried 1951–80 / 2016–25 | carried donors, 1951–80 | extended 1951–80 / 2016–25 | extension donors, 1951–80 |
|---|---|---|---|---|
| maxan (BULK) | 20–21 / 9 | 08EE008, 08EE013, 08EE003, 08JA016, 08EE020 | 30 / 9 (5 observed) | 08EE004 10–11, 08EE008 11–12, 08EE013 3 |
| swift (BULK) | 27–28 / 10 | 08KA008, 08KA007, 08KA001, 08NC004 | 27–28 / 10 | 08KA001 16, 08KA007 11–12 |
| naver (BULK) | 26–28 / 9 | 08KE009, 08KE016, 08KD006, 08KD007 (08KD001 in spawning min7) | 30 / 9–10 (18 observed) | 08KE009 8–9, 08KH006 2–3, 08KD001 1 (cov_day spawning: 08KD001 10, 08KH006 2) |
| gosnell (BULK, MORR) | 20–21 / 9 | 08ED002, 08ED001, 08EE020, 08EE013, 08EE003 | — | — |

Every stream reaches 1951–1980 with at least 20 years by either route, so no period decision goes back to the user. The early years lean on few gauges: at Maxan the filled-in record rests on the Bulkley at Quick (08EE004) and Telkwa (08EE008); at Gosnell some borrowed years rest on 08ED002 alone (a donor string of weight 1.0000).

## Plan correction: Phase 2 split (2026-10-30)

The rebuilt article's interval adds held-out residuals drawn from pools (`cr$resid`, `run_for()$r`) that exist only inside a `departure_site.R` run and are not saved. So its coverage is measured inside the site run (registered in the header with the #152 addition, `set.seed(1520)`), and `scripts/departure_interval_coverage.R` measures only the measured article's interval, from its committed bundle. The 0.87 rule is the same in both.

## Phase 2: the measured article's interval coverage (2026-10-30)

`data/checks/departure_interval_coverage.txt`: the percentile bootstrap of a ratio of means at the article's own years (18 or 29–30 baseline against 9–10 recent) covers 0.834–0.867, under the 0.87 bar at all four gauge-windows. So the measured article calls the bar "the middle 90% of resampled changes" and no count rests on it. A synthetic check of the rebuilt article's interval (20 against 10 years, residual SD half the series') covered 0.92, and 0.87 with no residual; its own coverage comes from the site runs.

## Zotero items added (2026-10-30, Web API, group 4733734)

- WPDHK5RW: WMO (2017), *WMO Guidelines on the Calculation of Climate Normals*, WMO-No. 1203, url library.wmo.int/idurl/4/55797. No ISBN: a search snippet gave 978-92-63-11203-3, but neither WMO's record (a JS app) nor the NCEI copy (404 to WebFetch) could be opened to confirm it.
- IAXTU7FP: Werner et al. (2019), Scientific Data 6, 180299, doi 10.1038/sdata.2018.299 (CrossRef).
- MD7D8CDK: Chapman, Kerr and Wilford (2018), JAWRA 54(3) 676–693, doi 10.1111/1752-1688.12643 (CrossRef).

They get citation keys only once Better BibTeX is running again and Zotero has synced and restarted.

## Phase 3: the site runs on m4 (2026-10-30, 21:50–22:04Z, logs `data/logs/152/` on m4)

Every site and snow report changed by additions only (25 and 13 lines), so the parity gates held and neither the published build nor cd's layers drifted. Coverage of every interval with one: 0.904–1.000, so the rebuilt article's ranges stay "90% ranges".

Change from 1951–1980 to 2016–2025, Bulkley windows, % (90% range), carried / extended:

| site | spawning mean | migration mean | spawning min7 | migration min7 |
|---|---|---|---|---|
| Maxan | −45 (−67..−11) / −57 (−76..−28) | −16 (−35..7) / −28 (−46..−5) | −40 (−63..−2) / −58 (−78..−21) | −17 / +4 |
| Swift | −15 (−32..5) / −28 (−47..0) | −5 / −4 | +1 / −18 | +49 (−2..123) / +55 (8..125) |
| Naver | −46 (−69..−5) / −40 (−67..6) | −11 / 0 | −33 (−56..5) / −25 | −20 / +14 |
| Gosnell | −35 (−56..−3) | −4 | −26 (−49..13) | +38 |
| Gosnell, Morice windows | −23 (−50..15) | −8 | −31 (−57..10) | +12 |

Snow over each target's watershed, 1951–1980 to 2016–2025: peak SWE −6 to −10% (Maxan 260→235 mm, Swift 556→524, Naver 243→223, Gosnell 974→891); 50% melt date 9–17 days earlier (Maxan 12.6, Swift 9.0, Naver 10.5, Gosnell 16.5).

## Errors Encountered

| Error | Resolution |
|-------|------------|
