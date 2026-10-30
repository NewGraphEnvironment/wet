## Checklist read

- `code-check-r.md`:
  - "Moving prose into a code chunk hides it from tools that scan the document".
  - "A duplicate knitr chunk label fails the build". I ran the duplicate-label grep over the Rmd and it found none.
- `code-check.md`: the prose of every H3 under `## Mechanisms`. These I read closely for the guard checks:
  - "A guard that fails toward pass"
  - "A proxy is not the property"
  - "A guard's scope, escape hatches, and remedies"
  - "Restore the bug and prove the guard fires"
  - "One fact derived twice"
  - "An assertion that matches an interpolated value cannot see the claim around it" (under Rules that stand alone)
- CLAUDE.md "pkgdown Publishing": footnotes, and checking structure against the built page.
- `writing.md`'s index lines "Name, link and cite the software" and "State each claim by the code's definition".

What I checked:
- `git diff 32d202b..HEAD` (125a55c, d7043ce).
- The built page `docs/articles/segment-discharge.html`. Its mtime equals d7043ce's commit time, and it carries the DBI, RPostgres, knitr and kableExtra entries.
- `inst/vignette-data/segment_values.rds` `$segments`, read in R (identical to the installed copy).
- `data-raw/segment_vignette_data.R:85-97`: `connector_edges` and the count query.
- `scripts/segment_output.R:103-110`.
- `scripts/wb_inputs.R:62-65,214`, `R/wet_climr_normals.R` and `R/wet_snow_normals.R`.
- `R/wet_db_load.R`.
- `citation()` for wet, gq, cd, duckdb, ggplot2, sf, climr, DBI, RPostgres, knitr, kableExtra and base.
- The fork's `research/pcic_routed_flow_periods.md` on `newgraph`: it exists, 8,008 bytes.
- HTTP status of every new link: all 200.

The tree was not modified apart from this file.

Mechanical checks, all of which pass:
- All 22 .bib keys are cited or nocited, and every cited key resolves.
- The page has 22 `id="ref-…"` entries.
- The page has no `??` or `(key?)`.
- No later chunk uses `own_pct`, `wtd`, `wtd_diff`, `plain` or `rt_seg`.
- No chunk label is duplicated.
- The `Timing window` header renders as written (`check.names = FALSE`, Rmd:916).
- The word-count chunk stops at "## Software and citation", so the new software list does not count against the cap.

## Mechanism

Earlier rounds kept finding the same mechanism: a sentence reworded or moved while its guard still tests the old claim, a narrower set or another denominator. Here it reaches one more place, the opening's "almost every one of them an estimate" (F1):
- d7043ce now guards the sentence over the right set: segments with a value, over every segment but the unmatched connectors. That gives 99.82%, against a threshold of 99.
- The definition of "stream" that makes it true lives only in the chunk comment.
- 125a55c removed the prose that said the unmatched segments are connectors, and d7043ce dropped its guard (`no_lut_connector > 0.9 * no_lut`).
- So the reader is told that almost every stream has a value, and then (Limits, Rmd:943-946) that 8% of segments have none, with nothing tying the two together.

The second half of the mechanism is new prose that makes claims about code or data nobody checked. Applied to the software list:
- Every role claim holds against the code.
- One package called with `::` in the Rmd, `bookdown`, is uncited, while CLAUDE.md:51 says every package is cited (F3).
- The new .bib entries match `citation()`, but one title renders a package name wrong (F2).

## Enumeration

Each item gives the claim or change, then its guard or evidence, then the verdict.

### Code

- **Rmd:145-150: comment and guard `stream_pct > 99`.**
  - What it computes: `(fwa - neither) / (fwa - no_lut_connector)`. That is the segments with a value over every segment except the unmatched connection lines and secondary channels. `connector_edges` are 1100, 1150, 1300, 1350, 1400 and 1450 (data-raw/segment_vignette_data.R:89-92).
  - The numerator is a subset of the denominator: the 369,217 unmatched segments all fall in `neither`.
  - Value: 4,532,843 / 4,541,079 = 99.82%. Over all segments the share is 92.37%, so the guard tells the right denominator from the wrong one and can fail: about 36k more valueless segments would trip it.
  - The comment's pointer "(the Limits bullet)" for "an unmatched segment is in no source's table" is now true. Rmd:943-946 says both sources are published only on matched segments.
  - Verdict: **y** for the computation. The prose side is F1.
- **Removed `wtd`/`wtd_diff` and its guard.** It went with the removed routed sentences. Nothing else uses it. Verdict: **y**.

### What it is

- **Rmd:170 "The R package `wet` [@irvine2026wetStream] publishes …".**
  - Evidence: the bib entry equals `citation("wet")` without its version.
  - Verdict: **y**.
- **Rmd:172-174 "Few streams in BC have a gauge, so this gives almost every one of them an estimate".**
  - Guard: Rmd:149-150.
  - Verdict: **y** by the guard, **n** for the reader, because the definition of "stream" is not in the prose (F1).
- **Rmd:175-176 "Each value comes from one of two sources, and the map shows which one a reader gets by default on BC's larger rivers."**
  - Guard: Rmd:136-139 (sources) and Rmd:194 (`mp$drawn` names). "Larger" means `mp$min_order` (5) and up, which the caption interpolates.
  - Verdict: **y**.
- **Rmd:195-200 `cap_pick` "The source of the default flow (`pick`, under "Which value to use") on main-flow rivers of stream order %d and up … %s of BC's segments, and the %d calibration gauges …".**
  - Evidence: values interpolated (5; 6%; 315). The named section exists (Rmd:261), and `order_width` rises with order. The rest of the caption is unchanged, guarded at Rmd:194 and 201-202.
  - The map now precedes the section it points to, and the caption names that section, so the forward reference is explicit.
  - Verdict: **y**.

### Routed PCIC paragraph (Rmd:235-244)

- **"models runoff with VIC-GL [@schnorbus2018VICGlacierVICGL] and routes it down its rivers with Raven [@craig_etal2020Flexiblewatershed], published as hydromosaic".**
  - Evidence: CLAUDE.md data sources say hydromosaic is Raven over VIC-GL. The two references check: hdl 1828/21631 resolves, and the Raven paper's DOI matches the bib.
  - Verdict: **y**.
- **"New Graph's fork of the PostgreSQL tools `fwapg` [@norris2024smnorrisfwapg; @norris_irvine2026…] places that flow on Freshwater Atlas segments, as the fork's notes set out".**
  - Evidence: the notes file exists on `newgraph`. It gives the per-segment weights and `q = greatest(sum(q_acc) + q_local*share, 0)`.
  - Verdict: **y**.
- **Removed: the routed month as the mean of its days; days clamped and rounded so they need not average to the month; the annual value as the plain mean of twelve months.**
  - Evidence: no later prose depends on it. Round 1 measured routed day means within 0.13% of the month, so the unqualified "`segment_daily`: `segment_monthly` per day" (Rmd:231) still holds at the article's precision.
  - Verdict: **y**.

### How to read it

- **Rmd:301: duckdb cited inline.**
  - Evidence: the entry equals `citation("duckdb")` without its version.
  - Verdict: **y**.
- **Rmd:327-328 "`wet_flow_window()` the mean flow over a timing window from days or months".**
  - Guard: Rmd:319-321 (`basis == "daily"`, the window as written). CLAUDE.md describes the function as giving mean flow over month-day windows.
  - Verdict: **y**.

### What a year looks like

- **Rmd:470-475 "chinook salmon life history timing windows on the Bulkley, the weeks each life stage needs the river: adults migrating upstream from …, spawning from …, fry moving downstream from …. They come from New Graph's species-timing table, which cites @gottesfeld_rabnett2007SkeenaFish."**
  - Guard: Rmd:377-383 (three CH stages, none crossing the new year, one source key) and `span_of()`/`one()`. "The weeks each life stage needs the river" is a gloss with no number.
  - Verdict: **y**.
- **Rmd:478-483 `cap_hyd` "… the chinook life history timing windows."** Same guard. Verdict: **y**.
- **Lower-case species name.** The prose has no remaining "Chinook". The strip labels are "Migration", "Spawning" and "Fry migration". Verdict: **y**.

### Flow in a timing window

- **Rmd:800 heading.** Not a claim.
- **Rmd:891-892 "every day of a timing window takes its month's mean … where a timing window spans whole months, as migration does from 1 May to 1 August".**
  - Guard: Rmd:813 (`basis == "monthly"`) and Rmd:874-878 (Migration 05-01..08-01, `approx_w < 1`).
  - Verdict: **y**.
- **Rmd:904 "several times the gauge in both late-summer timing windows".**
  - Guard: Rmd:879 (`late_w`) and Rmd:889 (`length(b003) == 2`, `all(b003 > 200)`).
  - Verdict: **y**.
- **Rmd:908 column `Timing window`.**
  - Evidence: `check.names = FALSE` (Rmd:916), and the HTML header reads "Timing window".
  - Verdict: **y**.
- **Rmd:920-925 table caption "Flow in each chinook life history timing window, … averaged over the timing window in each year with enough of its days … read as a timing window, against the daily record".**
  - Guard: Rmd:840 (`win$years >= min_years`, `!anyNA(win)`).
  - Verdict: **y**.

### Software list (Rmd:991-1007)

- **"`wet` builds and publishes the product".**
  - Evidence: `scripts/segment_output.R` and `scripts/discharge_publish.R` are this repo's.
  - Verdict: **y**.
- **"`fwapg` holds the Freshwater Atlas in PostgreSQL, and New Graph's fork places routed PCIC on it".**
  - Evidence: `whse_basemapping` reads, and `pcic.discharge_monthly` from the fork (CLAUDE.md data sources).
  - Verdict: **y**.
- **"`climr` gives the balance its climate normals, and `cd` its snow normals".**
  - Evidence:
    - climr: `climr::downscale` (scripts/wb_inputs.R:214) and `R/wet_climr_normals.R`.
    - cd: `cd::cd_catalog`/`cd_cache_fetch` (wb_inputs.R:62-65, R/wet_snow_normals.R:87,101).
    - AET (CGIAR) and the DEM (GLO-90) are correctly not attributed to either.
  - Verdict: **y**.
- **"`duckdb` and `DBI` read it in the recipes above, and `RPostgres` loads it into PostgreSQL".**
  - Evidence:
    - Rmd:343-345: `DBI::dbConnect(duckdb::duckdb())`, `dbExecute` and `dbGetQuery`.
    - Rmd:357-358: `DBI::dbConnect(RPostgres::Postgres())` into `wet_db_load()`, which writes through DBI on that connection (R/wet_db_load.R:98-101).
  - Verdict: **y**.
- **"`knitr` and `kableExtra` make the tables".**
  - Evidence: `knitr::kable` at Rmd:747 and 919, and `kableExtra::kable_styling`/`footnote` at Rmd:749-750.
  - Verdict: **y**.
- **"`ggplot2`, `gq` and `sf` the figures".**
  - Evidence: all three figures are ggplot2. gq supplies the registries, `gq_bbox_aspect` and `gq_scale_breaks`. sf supplies `geom_sf` data and `st_transform`. No figure uses another package (the `::` namespaces in the Rmd are bookdown, DBI, duckdb, gq, kableExtra, knitr, RPostgres, sf, stats, utils and wet).
  - Verdict: **y**.
- **"all in R [@rcoreteam2025R]".**
  - Evidence: matches `citation()`. stats and utils, called with `::`, are part of R.
  - Verdict: **y**.
- **Completeness.** `bookdown::html_vignette2` (Rmd:3) is the one package called with `::` that is uncited. Verdict: **n**, see F3.

### Data list

- **Rmd:1036-1037: climr cited.** Verdict: **y**.
- **Rmd:1044-1045: cd cited.** Verdict: **y**.
- **Rmd:1047-1048 "Life history timing windows for chinook salmon: New Graph's species-timing table [@gottesfeld…]".**
  - Guard: Rmd:383.
  - Verdict: **y**.

### Bibliography

- **bib:4-5 header: "the R packages are each package's own citation() without its version note, keyed by hand".**
  - Evidence:
    - wet, cd, duckdb, ggplot2, climr, DBI, RPostgres and R match.
    - sf (`citation()`'s first entry, the book) matches, and its publisher is now `{{Chapman and Hall/CRC}}`, rendering "Chapman and Hall/CRC".
    - knitr matches `citation()`'s first entry, the package manual.
    - kableExtra matches `citation()` exactly, but renders wrong: F2.
    - gq's added `organization` was already accepted as harmless.
  - Verdict: **y**, except F2.
- **Rendered References.**
  - All authors split correctly ("R Special Interest Group on Databases (R-SIG-DB), Hadley Wickham, and Kirill Müller"; "Wickham, Hadley, Jeroen Ooms, and Kirill Müller").
  - No stray braces.
  - The one defect is kableExtra's title: "Construct Complex Table with ’Kable’ and Pipe Syntax".
  - Verdict: **n**, see F2.

### CLAUDE.md:51

- **The article's order and content.** Map first, three datasets, routed PCIC at a high level with its model papers and the fork's notes, the province shares, the chinook life history timing windows, "flow in a timing window, from months or from days". These match the Rmd. Verdict: **y**.
- **"segment-discharge cites every package its code and recipes use inline, author-year, … and prints `citation("wet")`".**
  - Evidence: true for every `::`/`library()` package except bookdown. The citation chunk prints `citation("wet")`.
  - Verdict: **n** (F3), unless front matter is meant not to count.

## Findings

- **F1. [severity: fragile] vignettes/segment-discharge.Rmd:172-174 against Rmd:943-946 (guard Rmd:145-150).**
  - The opening says the product gives almost every stream an estimate. The guard makes that true by defining "stream" as every segment but the unmatched connection lines and secondary channels: 99.82%, against 92.37% over all segments.
  - That definition is now only in the chunk comment. The Limits bullet tells the reader that "the 8% of segments matched to none have no value", and nothing says those 8% are almost all connectors. So the article states 8% without a value next to "almost every one", and the code's definition never reaches the prose ("State each claim by the code's definition").
  - Round 1's F1 offered restoring the qualifier in the Limits bullet. d7043ce instead dropped `sg[["no_lut_connector"]] > 0.9 * sg[["no_lut"]]`, which measures 366,362 / 369,217 = 99.2%.
  - Fix: add to the Limits bullet "…matched to none, almost all of them connection lines and secondary channels, have no value", and restore that guard beside it. This puts the guard's definition in the prose without bringing back the opening sentence the reader asked to remove.

- **F2. [severity: bug] vignettes/segment-discharge.bib:190 (`zhu2024kableExtra`).**
  - `title = {{kableExtra}: {{Construct Complex Table}} with 'kable' and {{Pipe Syntax}}}` leaves `'kable'` unprotected. The CSL title-cases it, and the built References read "kableExtra: Construct Complex Table with ’Kable’ and Pipe Syntax". That is a package name capitalised wrong, with typographic quotes (docs/articles/segment-discharge.html, the Zhu 2024 entry).
  - Fix: `with {'kable'} and` (or `{`kable`}`), then check the rebuilt page.

- **F3. [severity: fragile] vignettes/segment-discharge.Rmd:3 and CLAUDE.md:51.**
  - The article is rendered with `bookdown::html_vignette2`, the one package the Rmd calls with `::` that is neither cited nor listed in References.
  - CLAUDE.md:51 says the article "cites every package its code and recipes use". The reader asked for every package to be cited inline.
  - Two ways to close it:
    - add `bookdown` (from `citation("bookdown")`) to the software list's knitr line ("…render the page and make the tables"); or
    - narrow the CLAUDE.md sentence to the packages the chunks and recipes call.
  - Whether build tooling in the front matter counts is a judgement. As written, the claim and the article disagree.
