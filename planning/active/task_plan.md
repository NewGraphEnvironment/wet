# Task: station-flow article: retitle to stream flow, cite from a Zotero .bib, apply the writing conventions (#145)

At #126's review the user asked that article titles and HTML names tell the reader what the package does: flow and temperature, not Chinook. #126 retitled only its own article. #149 then moved segment-discharge to pandoc citations from a `.bib` and brought it to the writing conventions; station-flow still has hand-typed references and one line per package from the internal `wet_software_cite()`.

## Context

`vignettes/station-flow.Rmd` ("Chinook Flow at Two Stations") reads as a fish package's page. Its references are typed by hand, and one line per package comes from the internal `wet_software_cite()`. #149 brought segment-discharge to pandoc citations from a `.bib` and to the writing conventions. This issue does the same for station-flow, in one edit: a new title and address, citations from a `.bib` written by a new `data-raw/vignette_bib.R` (#152's step 1), and a pass against every rule in soul's `conventions/writing.md`, read in full (497 lines, current with origin).

## Decided at the gate (user, 2026-10-30)

- **Title:** "How Stream Flow Has Departed from Its 1981–2010 Normal: A Case Study". The user picked "…from Its Climate Normal…" if the term is accurate. WMO's climatological standard normal is a 30-year average of *climatological* data, and stream flow isn't climatological data, so the title says "1981–2010 Normal". The prose says once that 1981–2010 is WMO's standard climate normal period, cited. **The title asserts no cause:** the article measures departure and trend, not attribution.
- **File and address:** `vignettes/flow-departure-normal.Rmd` → `articles/flow-departure-normal.html`; `articles/station-flow.html` redirected through `_pkgdown.yml`'s `redirects:`.
- **Word cap:** raised from 600 to 700 body-prose words. Report before and after counts (581 now).
- **Zotero:** I add the missing works myself through the Web API. The key is materialized on m1 at `~/.config/newgraph/zotero-api-key`, per cyclops `inventory.md`. Fix the reason sessions don't find it, so the user needn't say it again (Phase 0).
- **Package entries:** follow `writing.md` "Name, link and cite the software": `knitr::write_bib()` from each package's own `citation()`, keyed `@<pkg>`. Literature comes from the group library through rbbt and Better BibTeX. A key neither source returns stops the script.

## Phase 0: Zotero set-up, and the fix so it needn't be told again
- [x] Confirm the key works without printing it: cyclops `scripts/zotero/verify-key.sh --from file` (a GET through a 600-perm curl config; expect 200). The key never enters a command line or the transcript.
- [x] Through the Web API, search group 4733734 for the works the article cites that the read-only sqlite probe did not find: Mann 1945 (10.2307/1907187), Kendall 1975 *Rank Correlation Methods* 4th ed., Theil 1950, Sen 1968 (10.1080/01621459.1968.10480934), and WMO-No. 1203 (2017) *Guidelines on the Calculation of Climate Normals*. Create the ones still missing, with `extra` empty so BBT derives the keys. Metadata from Crossref and the publishers.
- [x] Launch Zotero (`open -a Zotero`), wait ~30 s, and confirm BBT answers on 23119. It returned an empty reply earlier today with Zotero running (memory `zotero_mcp_unconfigured_m1`). If it still fails, diagnose before Phase 4, and file it if it's not ours.
- [x] Read the new items' BBT keys from a consistency-checked copy of `zotero.sqlite` (references.md: `immutable=1` can't confirm a write).
- [x] File a soul issue: `/zotero-api` SKILL.md §4 reads the key from `~/.zotero-api-key`, while cyclops materializes it to `~/.config/newgraph/zotero-api-key` (or `scripts/op/read-secret.sh 'Zotero API Key'`). That's why sessions report "no key" and ask. soul#184 / soul#177 named "three competing homes" and closed with the skill still stale. Rewrite memory `zotero_mcp_unconfigured_m1.md` so it names the Web API key and route on m1, not just the MCP gap.

## Phase 1: Title and address
- [x] `git mv vignettes/station-flow.Rmd vignettes/flow-departure-normal.Rmd`; new `title:` and `VignetteIndexEntry`.
- [x] `_pkgdown.yml`: the article list entry, and a `redirects:` entry `articles/station-flow.html` → `articles/flow-departure-normal.html` (as #149 did for monthly-flow).
- [x] `README.md` "Learn more" line: new title, address and plain description (chinook in lower case).
- [x] Path mentions: `CLAUDE.md` (station-flow paragraph, and the citation and word-cap sentence in the segment-discharge paragraph), header comments in `data-raw/station_vignette_data.R` and `data-raw/station_vignette_map.R`, `scripts/temp_coverage.R:21`, the comment at `vignettes/segment-discharge.Rmd:803`, and the current-state line in `research/station_flow_departure.md`. NEWS and `planning/archive/` keep their historical mentions.

## Phase 2: Place each stream (writing.md "Orient the reader in one sentence per place")
- [x] Move `chinook_sites_map.R`'s receiving-river and mouth queries (`into1`/`into2`/`system`, the blue line's downstream end) into `scripts/vignette_map_lib.R` as one helper. Have `chinook_sites_map.R` call it, and hold the helper's output identical to the tracked `chinook_sites_map.rds` targets columns (parity, without rerunning that script).
- [x] `data-raw/station_vignette_map.R`: add each blue line's (Buck Creek, Bulkley) receiving river and mouth, and the places the sentence names (Houston, and Hazelton for the Bulkley's mouth) from BC Geographic Names. Rerun on m1 against fwapg. Every existing layer must be `identical()` to the old bundle.
- [x] The article guards distance and compass direction from the **mouth**, not the gauge, as the comparison article does (`compass()`/`km()`, flow-change-sparse-gauges.Rmd:142–167).

## Phase 3: Writing pass (every rule in `writing.md`)
- [x] **Open with the answer**: the finding with its numbers, computed inline, before any method. The strongest figure (the last five years as percent of normal) goes right under the opening. A sentence names 1981–2010 as WMO's standard climate normal period, cited.
- [x] **Headings are the reader's questions**, in order: where the streams are, how the last five years compare, day by day, every year since 1981, trends, limits last. Recipe and software come after.
- [x] **Species in lower case** in prose, captions, axis and legend labels, and registry labels (check `inst/cartography/wet_station.csv`). "Chinook salmon life history timing windows" the first time, "timing window" after.
- [x] **Define a term in its own place**: a short passage defining timing window before its first use, with which windows are kept and which are left out (ice), shown in the hydrograph figure.
- [x] **Define, read and cite every statistic at its figure**: percent of normal, the median year, "drier than nine years in ten", Theil–Sen [Theil 1950; Sen 1968], Mann–Kendall p [Mann 1945; Kendall 1975].
- [x] **A caption names every mark**: map (lakes, minor streams, the Houston label, keymap, scale bar), bars (provisional shading, value labels, the mean in m³/s), hydrograph, heat strip, trend (filled vs hollow, colour by start year).
- [x] **A sentence beside a figure says the pattern, not its values**; **cut any number or caveat that changes nothing**; **cut what serves the authors**; **each weakness one sentence about the product**; **stand alone** (no sibling references).
- [x] **Each guard covers the set its sentence names**: a `stopifnot()` beside every number the prose quotes; re-read each moved or reworded sentence with its guard. Word cap 700.

## Phase 4: Citations in #152's form
- [x] `data-raw/vignette_bib.R` (header modelled on knowledge's `data-raw/vignette_bib.R`): `bib_write(rmd, out)` reads the article's keys with `rbbt::bbt_detect_citations()`. Keys naming installed packages come from `knitr::write_bib(prefix = "")`, with the version note dropped so the static file doesn't drift (the article prints `citation("wet")` at render). Literature comes from `rbbt::bbt_bib(library_id = 9)` (local id of group 4733734, confirmed on m1). Strip `file`/`abstract`/`keywords`/`urldate`, refuse a local path, and stop on any key not returned. It takes the article as an argument so #148 and #152 reuse it.
- [x] The article: `bibliography: flow-departure-normal.bib`, `link-citations: true`, author-year citations at first mention for every package its code, recipe and format use (`wet`, `cd`, `tidyhydat`, `Kendall`, `zyp`, `ggplot2`, `gq`, `sf`, `knitr`, `bookdown`, R), a Data list one source per line, `## References` with `::: {#refs}`, and `citation("wet")` printed. The `wet_software_cite()` call goes; the helper and its test stay (#152).
- [x] Run the script; commit `vignettes/flow-departure-normal.bib`.

## Owed at the end (reported, done after merge)

- None in this repo. #148 and #152 reuse `data-raw/vignette_bib.R`. The soul issue from Phase 0 is soul's to land.

## Validation

- [ ] Tests pass
- [ ] `/code-check branch` clean (three-round floor; final round an enumeration of every claim sentence against its guard)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- Install the branch, then render with `pkgdown::build_article("flow-departure-normal")`; every `stopifnot()` passes. In the HTML: every `citation` links to an entry under `#refs`, there is no `???` or unresolved `@key`, and there are no footnotes.
- `pkgdown::check_pkgdown()`; `pkgdown::build_redirects()` writes `articles/station-flow.html` pointing at the new page.
- Word and line counts before and after (`writing.md` "Measure the simplification"); body prose ≤ 700.
- Map bundle: old layers `identical()`; the helper's parity with `chinook_sites_map.rds`.
- `vignette_bib.R` proved to stop on a missing key (temporary bad key in a copy of the Rmd).
- `devtools::test()`, `lintr` on changed R, `R CMD build` vignette build (the `.bib` ships in `vignettes/`).
