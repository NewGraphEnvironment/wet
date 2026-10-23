# Findings — Articles: bring the three vignettes to soul's current writing convention (#110)

## Issue context

**If we do it:** the three articles follow soul's current `writing.md` (open with the answer; plain words; no word that dates and no pointer to pending work; name, link and cite the software, with a computed "Software and citation" section). Each article says which code and which release it describes, and none of its sentences goes false when an open issue closes. **If we never do:** the articles cite no software, and several sentences rest on open issues or dated wording that will go stale.

## What the convention asks (soul `conventions/writing.md`, 2026-10)

- **Name, link and cite the software.** A software name goes in code font and is linked on first mention, saying what it is ("the R package `wet`"). An article ends with a "Software and citation" section computed in the article with `knitr::write_bib()`, which reads each package's `inst/CITATION`, citing it by concept DOI, version and commit. The commit is `packageDescription("<pkg>")$RemoteSha` only when that is a 40-character hash; otherwise print the version alone, or build from a GitHub install so the commit is recorded. wet already has what this needs: `inst/CITATION` reads `Config/DOI` (10.5281/zenodo.23305781), and every release is tagged.
- **No word that dates, and no pointer to pending work** ("Cut what serves the authors"): drop "current", "yet" and "new", and drop issue links for what is not done.
- **One "how it's built" link at the end, as a link the reader can open, not a repository path.**
- **When explaining a decision, list every check and the way it points**, or cut the explanation as how the decision was reached.

## Found, per article (audited 2026-10-20)

- **`vignettes/segment-discharge.Rmd`**
  - No "Software and citation" section.
  - `wet`, `fwapg`, `duckdb` and Postgres are in plain type and unlinked.
  - "The current build has … parts" dates.
  - The Nechako Reservoir sentence links fwapg#24, which is open. It will go false when that is fixed.
  - The "how it's built" link's text is the path `research/water_balance_method.md`.
  - Candidate: the Limits line "The zone adjustment … is kept for what it does on larger rivers" explains a decision without its checks.
- **`vignettes/monthly-flow.Rmd`** — **done under #107** (PR #112, wet 0.4.17, 2026-10-23), for this article only: its citation chunk is written inline there (`citation` chunk, `knitr::write_bib()` over `wet`, `duckdb`, `ggplot2`, `gq`, with DOI, version and commit-if-hash), and this issue lifts it into the shared helper (To do 2) when it does the other two articles. The three items below are closed there: a "Software and citation" section with a data line and a "Scores" line for the literature; no issue numbers in prose; `duckdb` in code font and linked.
  - A day of the user reading it (2026-10-23) found what the convention did not name: terms borrowed from a sibling article undefined, prose repeating a table's numbers, a statistic with no definition or reference, a build-provenance "Validation" section that served the authors, and no table convention. The rules proposed are NewGraphEnvironment/soul#519; the other two articles should take them with this issue, in particular the segment-discharge article's own Validation section (the same shape, cut in monthly-flow) and `knitr::kable(format = "html") |> kableExtra::kable_styling(full_width = FALSE) |> kableExtra::footnote()` for a table note (`kableExtra` is now in Suggests).
- **`vignettes/station-flow.Rmd`**
  - No "Software and citation" section.
  - Prose names the path `data-raw/station_vignette_map.R`.
  - Not yet read line by line for software names.

## The word caps

`segment-discharge.Rmd` holds its body prose to 900 words (at 899 after #99) and `station-flow.Rmd` to 600. A citation section and "the R package `wet`" wording add words, so either cut other prose to fit, or decide to raise or exclude the citation section from the count. The cap was set as a guard in #71 and #29, so changing it is a decision for this issue, not a side effect.

## To do

1. Per article: code font and first-mention links for software names; remove dating words and open-issue pointers (state what the build shows instead); the one method link with plain text.
2. A shared helper or chunk that writes the "Software and citation" section from `knitr::write_bib()` and prints concept DOI, version and, when it is a hash, the commit, rather than three copies.
3. The cap decision above, then fit each article to it, rendered before and after with the stripped text diffed (`r-packages.md`, vignettes item 4).

Relates to #71, #29, #99.




## Context measured at plan time (2026-10-23)


Issue #110 audited wet's three articles against soul's `writing.md` (2026-10). `monthly-flow.Rmd` was done under #107, with its "Software and citation" chunk written inline. The other two articles cite no software. They also carry dated wording ("The current build has"), an open-issue link (fwapg#24, still OPEN), repository paths as link text, and a build-provenance "Validation" section of the kind #107 cut. The issue also asks the other two articles to take soul#519's reader-pass rules (still open in soul): no Validation section, a table note via `kableExtra::footnote()` instead of a long caption, named statistics defined with a reference.

Measured now (same counter as the article guards):

| article | body prose words | cap |
|---|---|---|
| segment-discharge | 899 | 900 |
| station-flow | 535 | 600 |
| monthly-flow | 1,762 | none |

Installed `wet` is 0.4.15 and main is 0.4.17. pkgdown renders against the installed copy, so install the branch before any render.

## Errors Encountered

| Error | Resolution |
|-------|------------|
