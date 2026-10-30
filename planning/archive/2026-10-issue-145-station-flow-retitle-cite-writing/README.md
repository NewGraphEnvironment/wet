## Outcome

The station-flow article is now `vignettes/flow-departure-normal.Rmd`, "How Stream Flow Has Departed from Its 1981–2010 Normal: A Case Study". `articles/station-flow.html` redirects to it through `_pkgdown.yml`'s `redirects:`. It cites from `vignettes/flow-departure-normal.bib`, written by the new `data-raw/vignette_bib.R <article>` from each package's own `citation()` and the Zotero group library; #148 and #152 reuse the script. The prose was rewritten against every rule in soul's `writing.md`:
- it opens with what `wet` does and the answer;
- "timing window" has its own section;
- each stream is placed from its mouth, not its gauge, through `vm_into()` (moved to `scripts/vignette_map_lib.R`) and the new `mouths` and `towns` layers in `station_map.rds`;
- every statistic is defined and cited;
- every caption names every mark;
- chinook is in lower case.

At the plan gate the user asked for climate in the title. "Climate normal" is WMO's term for 30-year averages of climatological data, which stream flow isn't, so the title says "1981–2010 Normal". The prose names 1981–2010 as one of WMO's 30-year normal periods (Arguez and Vose 2011, p. 699, read from the PDF). The title asserts no cause.

## Measurement

- **Word count:** body prose went from 581 to 699 words in the first pass (the cap was raised from 600 to 700 at the gate), and to 627 after the user's review; the file from 704 to 751 lines. The first full draft came to 751 words. Cutting captions' restatements and the recipe's repeated software list brought it under. The floor was set by the answer-first opening, the timing-window section, the place sentence and the inline citations, each `[@key]` counting as a word.
- **Parity:** `vm_into()` against `chinook_sites_map.rds`: all six columns `identical()`. `station_map.rds` rebuilt with every old layer `identical()`, except lakes, which match only after sorting: `vm_lakes()` has no `ORDER BY`.
- **Mouths:** Buck Creek's is 0.89 km from Houston; the Bulkley's is 1.15 km from Hazelton, 115 km north-west of Houston.
- **`knitr::write_bib()`** writes each package's DESCRIPTION entry: wet without its DOI, ggplot2's manual rather than its book. This contradicts `writing.md`, so the script uses `utils::citation(pkg)[[1]]`. Recorded in soul#27.
- **The Zotero failure that made wet#149 write its `.bib` by hand was curl's user agent, not Zotero.** m1's `~/.curlrc` sets a browser user agent, and Zotero 7 drops browser-looking requests with an empty reply. rbbt is unaffected. The Web API key sessions kept asking about is cyclops-materialized at a path `/zotero-api` does not name. Both are filed in soul#590. Four works (Mann 1945, Kendall 1975, Theil 1950, Sen 1968) were added to the group library through the Web API.
- **Review:** `/code-check branch` ran five rounds, plus the plan review: six agents in all.

| Round | Findings | Fixed | Inside previous fix? |
|---|---|---|---|
| plan | 2 blockers, gaps | folded in | — |
| 1 | 3 | 3 | — |
| 2 | 1 | 1 | n |
| 3 | 2, plus an enumeration of ~75 prose claims | 2 | n |
| 4 | 1 | 1 | y (lakes selected near, drawn whole) |
| 5 | 2 low, plus an enumeration of every figure mark against its caption | 2 | n |

  The loop ended on round 5's enumeration. Each new guard was shown to fire on the case it exists for. The mechanism the rounds named: a guard checked that what was drawn, counted or sorted lay in the sentence's set, while the sentence claimed the set itself.

## Revision after the user's review (2026-10-30)

Read as a review copy (a private claude.ai artifact), the article was revised:
- The year-by-year departure strip and the Theil–Sen/Mann–Kendall trends were dropped, with their four statistics citations.
- The day-by-day figure became the 1981–2010 mean and median day against the 2022–2026 ones, in segment-discharge's style, then split per gauge into the whole year (with the migration window) and July to October on its own scale (with the spawning window).
- A change figure, in flow-change-sparse-gauges' form, gives each window's change in mean flow from 1981–2010 to 2022–2026.
- Fry migration was dropped: it falls within migration and spawning together, which a guard checks day by day.
- The map moved above the bars.
- `fwapg` is described as software, not the Atlas, and the Data list was cut to four lines.

Review round 6 (`review-round6.md`) found six issues in that revision, all fixed. Chief among them, the 1981–2010 line at the Bulkley gauge had averaged years outside its normal (2010 and single spot readings in 2000–2009); it now uses only the normal's years. Also, a percentile bootstrap of five years undercovers: simulated, its "90%" range held the truth 82% of the time. So the bar is described as the middle 90% of resampled changes, and no count rests on it. The later moves (the map first, two windows, the split figure) were checked by rendering and reading, with no reviewer agent, at the user's request.

## Owed

- The `.bib` was not regenerated after the revision: Better BibTeX stopped answering after Zotero's 10.0.7 auto-update. It lacks the Gottesfeld and Rabnett url (now on the Zotero item) and holds six entries the article no longer cites. Tracked in wet#152. Better BibTeX's key migration and key drift: soul#595.

## Evidence

- `findings.md`: Phase 0 and Phase 2 measurements, and the errors table.
- `review-plan.md`
- `review-round*.md`

Closed by: the PR for #145
