## Checklist read

- `code-check-r.md`: "Moving prose into a code chunk hides it from tools that scan the document", "A duplicate knitr chunk label fails the build" (duplicate-label grep run over the Rmd: none).
- `code-check.md`, prose of every H3 under `## Mechanisms`, with "A guard that fails toward pass", "A guard's scope, escape hatches, and remedies", "Restore the bug and prove the guard fires" and "One fact derived twice" read closely for the guard checks.
- pkgdown and citation rules: CLAUDE.md "pkgdown Publishing" (footnotes, structural checks against the built page) and `writing.md`'s "Name, link and cite the software" / "State each claim by the code's definition" index lines.

What I checked:
- `git diff 32d202b..HEAD`.
- The built page `docs/articles/segment-discharge.html`, whose mtime matches the 125a55c commit time and which carries the new heading.
- The bundles in `inst/vignette-data/`, read in R. The tree was clean after.
- `citation()` of duckdb 1.5.2, ggplot2 4.0.3, sf 1.1.2, gq 0.16.0, cd 0.6.11, climr 0.2.2 and wet 0.4.29.
- Crossref for 10.1016/j.envsoft.2020.104728.
- UVic DSpace metadata for hdl 1828/21631.
- The fork's `research/pcic_routed_flow_periods.md` on `newgraph`, and its `research/README.md`.

Mechanical checks, all of which pass:
- Every `[@key]` / `@key` in the Rmd resolves to a .bib entry, and every .bib entry is cited or nocited.
- Every `href="#ref-…"` in the HTML has a matching `id="ref-…"`: 17 of 17.
- The HTML has no `???` or `(key?)`.
- No later chunk uses `wtd`, `wtd_diff`, `plain` or `rt_seg`; grep of the Rmd, `data-raw/`, `scripts/`, `R/` and `tests/` finds nothing.
- The moved `map-pick-data` and `map-pick` chunks use only `map`, `sk`, `bc`, `sg`, `pct`, `pal_outline`, `pal_pick` and `pal_gauge`, all defined in `load` and `product` before them. They do not use `pick`'s `rg`, `nech_bal` or `pct_of`.
- No later chunk uses an object defined only in `map-pick-data` (`lab`, `mp`, `rv`, `drawn` and the rest).
- No prose refers to the map's position or a figure number.
- `Timing window` works: `data.frame(..., check.names = FALSE)` (Rmd:918), and the built table header reads "Timing window". The 9 columns match `align = "llrrrrrrr"`.
- Word count, by the chunk's own rule: 1,830 words at 32d202b and 1,768 at HEAD, under the 2,000 cap.

## Enumeration

Each line gives the claim, then the guard, then **covered**: whether the guard covers the claim exactly, and why.

### What it is: opening paragraph (Rmd:172–178)

- **E1. "The R package `wet` [@irvine2026wetStream] publishes the mean flow … for the year, each month and each day."** Wording unchanged; the citation is new.
  - Guard: `product` chunk, Rmd:136–139 (three datasets).
  - Covered: y.
- **E2. "Few streams in BC have a gauge, so this gives almost every one of them an estimate: …"**
  - Guard: Rmd:150–151, `round(own_pct, 1) == 99.9`.
  - Covered: **n**. The guard's denominator is the segments linked to a watershed polygon. The sentence's set is BC's streams. See F2.
- **E3. "Each value comes from one of two sources, and the map shows which one a reader gets by default on BC's larger rivers."**
  - Guard: Rmd:138 (`setequal(seg_parts$source, …)`) and Rmd:196 (`names(mp$drawn)`). "Larger rivers" = `mp$min_order` (5) and up, interpolated in the caption.
  - Covered: y.
- **E4. Removed: "It has a value on 99.9% of the segments matched to a watershed polygon. Segments matched to none, almost all connection lines and secondary channels, have no value."**
  - Guard: Rmd:152 `no_lut_connector > 0.9 * no_lut` was kept. Its comment (Rmd:148) now attributes the claim to the Limits bullet.
  - Covered: **n**. No prose carries the connector claim any more. See F1.

### Map caption, `cap_pick` (Rmd:197–201)

- **E5. "The source of the default flow (`pick`, under "Which value to use") on main-flow rivers of stream order %d and up (wider for higher orders), %s of BC's segments, and the %d calibration gauges."**
  - Values are interpolated (5; 6% = 282,996 / 4,907,441; 315). The section named exists (Rmd:263). `order_width` increases with order (Rmd:183).
  - Covered: y.
- **E6. The caption's remaining sentences** (wording unchanged).
  - Guard: Rmd:196, 202–203.
  - Covered: y.

### Routed PCIC paragraph (Rmd:237–246)

- **E7. "PCIC at the University of Victoria models runoff with VIC-GL [@schnorbus2018VICGlacierVICGL] and routes it down its rivers with Raven [@craig_etal2020Flexiblewatershed], published as hydromosaic."**
  - No number, so no stopifnot. Checked against the sources:
    - VIC-GL report: hdl 1828/21631, Schnorbus, issued 2018-02-01, PCIC; "VIC generation 2 deployment report, volume 1".
    - Raven paper: EMS 129:104728, 2020-07, the 12 authors match Crossref.
  - Covered: y.
- **E8. "New Graph's fork of the PostgreSQL tools `fwapg` [@norris2024smnorrisfwapg; @norris_irvine2026NewGraphEnvironmentfwapg] places that flow on Freshwater Atlas segments, as the fork's notes set out."**
  - Checked against the notes: they give each segment's weights (`subid`, local-runoff share, `upstream_subids`, diversions) and `q = greatest(sum(q_acc) + q_local * share, 0)`, so "set out" holds. They do not describe how outlets are snapped to segments. They do mention the crosswalk.
  - Covered: y.
- **E9. Removed: routed's month as the mean of its days, its days clamped and rounded so they need not average to the month, and the annual value as the plain mean of the twelve months (with `wtd_diff`).**
  - Guard removed with it: `wtd_diff > 0` (Rmd:157 comment narrowed accordingly).
  - Covered: y.
  - Measured on the bundle: routed day means are within 0.13% of the published month, and plain against day-weighted annual is within 0.43%. So the unqualified bullet "`segment_daily`: `segment_monthly` per day" (Rmd:230, unchanged) is not made wrong at the article's precision.

### How to read it

- **E10. duckdb cited** [@muhleisen_raasveldt2026duckdb] (Rmd:303).
  - The entry matches `citation("duckdb")` without its version note.
  - Covered: y.
- **E11. "`wet_segment_daily()` reads a segment's days, and `wet_flow_window()` the mean flow over a timing window from days or months"** (Rmd:329–330).
  - Guard: Rmd:320–323 (`vs$daily` basis daily, the window as written).
  - Covered: y.

### What a year looks like

- **E12. "The strips under the hydrographs are chinook salmon life history timing windows on the Bulkley, the weeks each life stage needs the river: adults migrating upstream from …, spawning from …, and fry moving downstream from …. They come from New Graph's species-timing table, which cites @gottesfeld_rabnett2007SkeenaFish."** (Rmd:472–477)
  - Guard: Rmd:377–383 (three CH stages, none crossing the new year, one source = that key) and `span_of`/`one()`.
  - Covered: y. "The weeks each life stage needs the river" is a gloss with no number.
- **E13. `cap_hyd`: "The strips under each panel are the chinook life history timing windows."** (Rmd:484)
  - Guard: same as E12.
  - Covered: y.

### Flow in a timing window, from months or from days

- **E14. Heading "Flow in a timing window, from months or from days"** (Rmd:802). Not a claim.
- **E15. "Read from monthly means, every day of a timing window takes its month's mean. That costs almost nothing where a timing window spans whole months, as migration does from 1 May to 1 August, …"** (Rmd:893–894)
  - Guard: Rmd:812–814 (`basis == "monthly"`) and 875–879.
  - Covered: y.
- **E16. "… several times the gauge in both late-summer timing windows."** (Rmd:906)
  - Guard: Rmd:880, 889 (`late_w`, `length(b003) == 2`, `all(b003 > 200)`).
  - Covered: y.
- **E17. Table column `Timing window`** (Rmd:910).
  - Check: `check.names = FALSE` (Rmd:918).
  - Covered: y. The header renders as written.
- **E18. Table caption: "Flow in each chinook life history timing window, 1981–2010. … averaged over the timing window in each year with enough of its days. … read as a timing window, against the daily record."** (Rmd:922–926)
  - Guard: `wet_window_stats` years, Rmd:840 (`win$years >= min_years`).
  - Covered: y.

### Software and citation

- **E19. "The product is made with … `fwapg` [@norris2024smnorrisfwapg] and New Graph's fork of it [@norris_irvine…], and the R package `wet` [@irvine2026wetStream]"** (Rmd:994–998).
  - Covered: y.
- **E20. "the balance's inputs come through `climr` [@daust_etal2024climr] and `cd` [@irvine2026cd]"** (Rmd:998–999).
  - Covered: **n**. Not true of all its inputs. See F4.
- **E21. "the recipes above read it with `duckdb` […]"** (Rmd:999–1000).
  - Covered: y. The recipes also use DBI and RPostgres, which are uncited; see F3.
- **E22. "the figures are drawn with `ggplot2` [@wickham2016ggplot2], `gq` [@irvine2026gq] and `sf` [@pebesma_bivand2023Spatial]"** (Rmd:1000–1003).
  - Covered: y. The sf entry renders wrong; see F5.

### Data list

- **E23. climr and cd cited** (Rmd:1029, 1038).
  - The entries match `citation()`, without version.
  - Covered: y.
- **E24. "Life history timing windows for chinook salmon: New Graph's species-timing table [@gottesfeld_rabnett2007SkeenaFish]"** (Rmd:1041–1042).
  - Guard: Rmd:383.
  - Covered: y.

### Bibliography

- **E25. .bib header: "the R packages are each package's own citation() without its version note, keyed by hand."**
  - Matches for duckdb, ggplot2, cd, climr and wet.
  - gq adds `organization`, which `citation("gq")` lacks: harmless.
  - sf drops the publisher's inner braces: F5.

### CLAUDE.md:51

- **E26. CLAUDE.md:51** describes what the article contains: the map up front, routed PCIC described at a high level with its model papers and the fork's notes, the province shares, the chinook life history timing windows, and "flow in a timing window, from months or from days". Those match the article.
- Exceptions:
  - "cites every package it uses inline": F3.
  - "(wet as Irvine 2026)": it renders "Irvine 2026c", because there are three Irvine 2026 entries. Minor; folded into F3.

## Findings

- **F1. [severity: fragile] vignettes/segment-discharge.Rmd:145–152.**
  - The guard comment says the claim "the unlinked almost all connection lines and secondary channels" is "(the Limits bullet)".
  - The Limits bullet "Segments without a value" (Rmd:945–948) says only that "the 8% of segments matched to none have no value". It says nothing about connection lines or secondary channels.
  - That claim left the prose with the removed opening sentences (32d202b Rmd:187–188). So `sg[["no_lut_connector"]] > 0.9 * sg[["no_lut"]]` now guards no sentence, and its comment names a home that does not carry the claim.
  - Fix, either:
    - restore the qualifier in the Limits bullet ("…matched to none, almost all connection lines and secondary channels, have no value"), so the guard and its pointer are true; or
    - say in the comment that the connector check is kept only to support E2 (see F2).

- **F2. [severity: fragile] vignettes/segment-discharge.Rmd:150–151, against Rmd:174–175.**
  - The guard now stands for "Few streams in BC have a gauge, so this gives almost every one of them an estimate". That sentence quantifies over BC's streams. The guard `round(own_pct, 1) == 99.9` is over the segments linked to a watershed polygon only.
  - Over all Freshwater Atlas segments the share with a value is 92.4% (4,532,843 of 4,907,441). The article's own Limits bullet tells the reader that 8% have none.
  - The sentence holds only if "streams" excludes connectors. Then the share is (fwa − neither) / (fwa − no_lut_connector) = 99.8%, which no guard computes.
  - The exact pin `== 99.9` also tests a number the prose no longer prints. A rebuild at 99.8% would refuse an article whose sentence is still true (it fails toward abort for no claim).
  - Fix: guard the set the sentence names, e.g. `(fwa - neither) / (fwa - no_lut_connector) > 0.99` with the connector share (F1), and drop the one-decimal pin.

- **F3. [severity: bug] CLAUDE.md:51.**
  - It says "segment-discharge cites every package it uses inline, author-year, from `vignettes/segment-discharge.bib`". That is false for:
    - `DBI` (the reader recipes at Rmd:345–347 and Rmd:359);
    - `RPostgres` (Rmd:359);
    - `knitr` (`knitr::kable`, Rmd:749 and 921, and the vignette engine).
  - None of these is cited or listed in References. DBI and RPostgres are in code the reader is told to run, which is the case the change ("every package used is cited inline … and listed in References") was meant to cover.
  - Fix: cite DBI and RPostgres from their own `citation()` where the recipes are introduced (and knitr in the closing paragraph if build tools count), or narrow the CLAUDE.md sentence.
  - Same line: "(wet as Irvine 2026)" renders as "Irvine 2026c" in the page.

- **F4. [severity: bug] vignettes/segment-discharge.Rmd:998–999.**
  - "the balance's inputs come through `climr` … and `cd`". The balance's AET and DEM come through neither:
    - AET: `wet_cgiar_aet()`, scripts/wb_inputs.R:41;
    - DEM: `wet_dem_glo90()`, scripts/wb_inputs.R:43.
  - Only the climate normals (`climr::downscale`, wb_inputs.R:214) and the snow normals (`cd::cd_catalog` / `cd_cache_fetch`, wb_inputs.R:62–65) do.
  - The Data list (Rmd:1028–1038) states it correctly.
  - Fix: reword to "the balance's climate and snow normals come through …".

- **F5. [severity: bug] vignettes/segment-discharge.bib:437–444 (`pebesma_bivand2023Spatial`).**
  - `publisher = {Chapman and Hall/CRC}` has single braces, so biblatex reads "and" as a name-list separator. The built References line reads "Chapman; Hall/CRC" (docs/articles/segment-discharge.html, the sf entry).
  - `citation("sf")` gives `publisher = {{Chapman and Hall/CRC}}`, so the entry is not that package's citation, as the .bib header (bib:3–4) says it is.
  - Fix: `publisher = {{Chapman and Hall/CRC}}`.
