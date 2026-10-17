## Outcome

The README was rewritten to soul's readme convention, at the user's steer: "plain language. temp discharge. not too much detail. big picture". It opens with modelled monthly flow on almost every BC stream, published openly, and flow and water temperature at stations in the seasons that matter to fish. A province map of where each river's default flow comes from is drawn by `data-raw/readme_figure.R` from the bundled article data. The example reads one Bulkley segment's published flow without credentials. Learn more lists all three articles and the water-temperature functions.

The issue's link item had moved by the time the work started. link#331 merged on 2026-10-16, so link can read wet's published discharge. The README now says so, and no longer names `lnk_discharge()`, which is internal to link.

The `_pkgdown.yml` reference index is in eight groups. DESCRIPTION's `Description` and the GitHub About now match the README. The About's earlier text claimed climate-scenario output, which is not built. The citation workflow keeps New Graph Environment Ltd. as an author.

The plan review moved the date-window functions into their own group, since flow and temperature share them, and added the "modelled long-term average" qualifier. Code-check took three rounds, and each finding was a sentence naming a set by its best-known members: water temperature needing only duckdb (it also needs tidyhydat), and two `_pkgdown.yml` group descriptions, one of them inside the previous round's fix. An enumeration of all 8 descs against their 46 members ended the loop. A NOTICE for Copernicus and PCIC attribution is left to the user.

## Measurement

The README is 548 words on main, 657 in the first draft and 582 at merge.

Closed by: PR (see branch `75-readme-correct-the-link-connection-list`)
