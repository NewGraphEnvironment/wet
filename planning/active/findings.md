# Findings — station-flow article: retitle to stream flow, cite from a Zotero .bib, apply the writing conventions (#145)

## Issue context

**If we do it:** the station-flow article's title and address say what wet measures (stream flow), with the salmon windows as the example. It cites the way segment-discharge does, and meets the writing conventions segment-discharge was brought to in #149. All three changes happen in one pass, so the article is edited once. **If we never do:** the listed article "Chinook Flow at Two Stations" reads as a fish package's page, its address and title disagree with "How Stream Flow Has Changed Where Gauges Are Few", and its references stay hand-typed while segment-discharge's come from a `.bib`.

**Scope changed 2026-10-30:** this issue now covers `vignettes/station-flow.Rmd` alone, with its citations (from #152) and the writing pass added, so the article is changed once. The short-record article's retitle moved to #148, which decides that article's content. The comparison article's citations stay in #152.

## Problem

At #126's review the user asked that article titles and HTML names tell the reader what the package does: flow and temperature, not Chinook. #126 retitled only its own article. #149 then moved segment-discharge to pandoc citations from a `.bib` and brought it to the writing conventions; station-flow still has hand-typed references and one line per package from the internal `wet_software_cite()`.

## Proposed

1. **Title and address.** A title naming the change in window flow at two gauged stations, in step with "How Stream Flow Has Changed Where Gauges Are Few" (wording chosen at the plan gate). Rename the file so the address says the same, and redirect `articles/station-flow.html` through `_pkgdown.yml`'s `redirects:`, as #149 did for `monthly-flow.html`. Update `README.md`'s "Learn more" line and `_pkgdown.yml`'s article list; NEWS keeps its historical mentions.
2. **Citations in #152's form.** Build `data-raw/vignette_bib.R` here (#152's step 1): it reads the article's citation keys and writes its `.bib` from the Zotero group library through Better BibTeX, stopping on a key Zotero does not return. The article then carries `bibliography:` and `link-citations: true`, author-year `@key` citations linked to a `::: {#refs}` list, every package its code and recipes use cited inline (ours included), and `citation("wet")` printed. Its `wet_software_cite()` call goes; the helper stays until #152's last article.
3. **Writing conventions.** A pass against every rule in the organisation's writing conventions. `CLAUDE.md`'s "Writing for the Reader" carries their index, but rules have been added since it was synced, so read the full text. Among them: species names in lower case, one sentence placing each place, an article that stands alone, captions naming every mark, every statistic defined and cited, and each guard covering the set its sentence names. Keep the word cap and a `stopifnot()` beside every number the prose quotes.

**Prerequisite:** the `.bib` step needs Zotero's local Better BibTeX endpoint answering on the machine that runs it, and every work the article cites in the group library. How package entries are written (from Zotero, or from each package's `citation()` as segment-discharge's are) is decided at the plan gate.

Relates to #27, #126, #146, #148, #149, #152.


## Plan-mode exploration (2026-10-30)

- Body prose 581 words (cap 600), file 704 lines, at 38a9672.
- Group library (local id 9 = group 4733734), read-only sqlite probe: present: Gottesfeld & Rabnett 2007, HYDAT, FWA stream network, fwapg (smnorris and NGE fork), wet, R. Absent: Mann 1945, Kendall 1975, Theil 1950, Sen 1968; no R package except wet.
- Zotero Web API key is materialized on m1 at `~/.config/newgraph/zotero-api-key` (600; cyclops `inventory.md`). soul's `/zotero-api` skill §4 names `~/.zotero-api-key`, a path that does not exist, which is why sessions report no key.
- Zotero was not running at plan time (23119: curl 000). Earlier today with Zotero running, BBT gave an empty reply (memory).
- `writing.md` "Name, link and cite the software": packages through `knitr::write_bib()`, literature through rbbt/BBT. knowledge's `data-raw/vignette_bib.R` is the model for the literature half.
- "Climate normal": WMO defines climatological standard normals as 30-year averages of climatological data (1981–2010 is one); stream flow is not climatological data, so the title says "1981–2010 Normal" and the prose names the period as WMO's.
- The comparison article places streams from their mouths (`data-raw/chinook_sites_map.R` receiving-river and mouth queries; `compass()`/`km()` in flow-change-sparse-gauges.Rmd:142–167).

## Errors Encountered

| Error | Resolution |
|-------|------------|
