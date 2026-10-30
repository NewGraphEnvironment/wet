# Plan review (#145), Plan agent, spawned 2026-10-30 16:45 UTC

The reviewer read the plan, Phase 1 (committed) and Phase 2 (then uncommitted). Its findings, each with what was done.

## Blockers
- **B1. `knitr::write_bib(prefix = "")` gives unusable `@<pkg>` entries.** It writes duplicate `wet` entries (DESCRIPTION and CITATION), R's key is `base`, `@ggplot2` and `@sf` get the DESCRIPTION manuals rather than the books, unbraced titles get re-cased by pandoc, and years follow the install. **Done:** reproduced before the review arrived (write_bib keys `ggplot2`/`sf`/`wet` are the DESCRIPTION entries, with no DOI on wet). The script takes `utils::citation(pkg)[[1]]`, the citation the package asks for, keyed by package name (`R` → `base`). It braces the package name in the title and drops `version` and `note`. This departs from `writing.md`'s "`knitr::write_bib()` … reads each package's `inst/CITATION`", which the measurement contradicts; reported for soul.
- **B2. `tests/testthat/test-vignette_data.R:47` pins the station map's layer names.** **Done:** the test now expects `mouths` and `towns`.

## Accuracy
- **A1. 08EE003's normal rests on 1981–1998 (18 years).** **Done:** the opening says so, not only the caption and limits. The title keeps "1981–2010 Normal", the period both gauges are measured against.
- **A2. "WMO's standard climate normal period" dates.** **Done:** "one of WMO's 30-year climatological standard normal periods", cited to Arguez and Vose (2011) with its page. The prose doesn't call the flow mean a climate normal.
- **A3. The title is static.** **Done:** `stopifnot(identical(baseline, 1981:2010))` beside the title's claim.

## Gaps
- **G1. Ours carry version and commit.** **Done:** the software section prints `wet`, `cd` and `gq`'s installed version, and the commit where the install recorded a 40-hex `RemoteSha`, computed at render.
- **G2/G3. Credit data to its publisher; cite the page that says it.** **Done:** Data list in segment-discharge's form: the Freshwater Atlas through DataBC, HYDAT to ECCC, `fwapg` as the tool, and the windows to New Graph's species-timing table, citing Gottesfeld and Rabnett.
- **G4. Rules Phase 3 didn't list:** plain phrase, code's definition, lead with what the product does, the look-alike test on the heat strip, and listing every check for a decision. **Done:** each was applied in the writing pass; the enumeration in `/code-check` covers the claims.
- **G5/O2. Define a timing window in its own section, before the bars use it.** **Done:** order is opening → "What is a timing window?" → the last five years (bars) → where the gauges are → day by day → every year → trends → recipe → limits → software.
- **G6. Hazelton named but not drawn.** The sentence keeps the gauges near Houston (guarded from the gauge) and adds where each stream's mouth is (guarded from the mouth). Hazelton is 115 km off the map; the keymap places the map in BC. Not drawn, by judgement.
- **G7. `scripts/station_snap_sweep.R:46` and `CLAUDE.md:51`.** **Done** (CLAUDE.md:51 in Phase 4).

## Ordering
- **O1. BBT keys need sync and restart.** Moot: Zotero was not running when the items were created, so its launch did both. The Web API's `data.citationKey` gave all four keys.
- **O3. Recipe and limits.** The recipe sits above the limits; both count toward the cap.

## Assumptions
- **S1. `identical()` after a rerun is fragile.** Confirmed for lakes (row order only, `vm_lakes()` has no `ORDER BY`); compared after sorting (findings.md).
- **S2. Parity proves refactor plus unchanged fwapg together.** Accepted: same SQL moved verbatim, and all six columns identical.
- **S3. `@<pkg>` keys diverge from segment-discharge's hand keys.** Noted for #152, which re-keys segment-discharge when it runs the script.
- **S4. `[@key]` tokens count as words.** Measured in the final count.
- **S5. water-temp-bc** is credited as a data archive in the Data list, with its link.

## Scope
- **Sc1. Key path in a soul issue.** soul is a private repo (checked); the issue names the path, and the fix it proposes leaves `references.md` free of it.
- **Sc2. README.md:44 "Chinook salmon".** **Done:** lower case.
- **Sc3. Shared registry.** No registry label changed.
