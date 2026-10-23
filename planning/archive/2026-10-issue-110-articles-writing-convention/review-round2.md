# Review round 2: branch 110-articles-bring-the-three-vignettes-to-so (base e2d083b..f1a44cf)

## Checklist read

- `code-check.md`: the prose (no `|` rows) of all 14 H3s under `## Mechanisms`, plus "An assertion that matches an interpolated value cannot see the claim around it". The other 22 headings were read as index lines only.
- `code-check-r.md`: read in full "Moving prose into a code chunk hides it from tools that scan the document", "A duplicate knitr chunk label fails the build", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared", "`cffr::cff_create()` writes a CRAN DOI…", "Inserting a helper between a roxygen block and its function rebinds `@export`", "Tests that silently do not run" and "`vapply(..., USE.NAMES = FALSE)` strips ALL dimnames" (8). The other 103 were read as index lines only.
- `code-check-shell.md`: index only. The diff has no shell (0 of 67 read in full).
- `code-check-spatial.md`: index only. No spatial code changed (0 of 93 read in full).

## Probes run (in the scratchpad copy r2/, not the repo)

- `test-wet_software_cite.R` under `load_all()` with `NOT_CRAN=true`: 4 blocks, 15 expectations, 0 failed, 0 errors, 0 skipped. `utils::citation("wet")` finds `inst/CITATION` in the source tree, so the DOI test passes there as well as against the installed package.
- The monthly-flow render on HEAD is byte-identical in text to main's (`cmp` of the stripped text).
- The rendered segment-discharge score table has its caption ("Table 2: …") and its `kableExtra` footnote in a `<tfoot>`. kableExtra, Kendall, zyp, cd and tidyhydat are all in Suggests.
- Read the bundle provenance. `prov$routed_commit` is fwapg's commit (7c30f58), so the Data line's "fork of `fwapg` at commit 7c30f58" is right. `hydat_release` is "2026-07-17 08:08:08.000", and `substr(…, 1, 10)` prints the date. Both bundles were built 2026-10-20, so the new `identical(map$provenance$built, prov$built)` guard holds and can fire.
- `data-raw/segment_vignette_data.R:150-165` compares routed month 0 on the gauge segments with fwapg's mean of twelve months, and refuses on any difference or on zero compared. The rewritten sentence "the routed values were held equal to `fwapg`'s before they were written" is now the claim that code supports.
- `prov$keep_adjust` is TRUE and `gate_pass` is FALSE (an override can hold the adjustment, per the script's comment). "Kept by decision" is supported, and the `limits` chunk pins it.
- `wet_station_daily()` reads the real-time feed with `tidyhydat::realtime_ws()`, which supports station-flow's recipe sentence. The life-history CSV cites `gottesfeld_rabnett2007SkeenaFish` for all three open-water windows, and the `limits` chunk pins that, so the Data line's single source for the windows holds.

## Findings

- **[severity: bug (published claim wider than the data)]** `vignettes/segment-discharge.Rmd:379`: "The numbers in this article are the published product's." Many of the article's numbers are not the published product's:
  - Every balance score (the "Open water balance (held out)" columns of Table 2; the headwater, small-basin and dry-zone averages; the "closer at 169 of 290" count) comes from blocked-CV predictions of the fit. These are `sk$err_pct`, from `shipped_heldout()` in `data-raw/segment_vignette_data.R:57-60`. The article itself says these values are *held out*, which is exactly what the published balance is not.
  - The observed runoff they are scored against is HYDAT's.
  - The province counts are from the tracked segment report.

  The paragraph's third sentence ("Its scores come from the water balance fit…") contradicts its first. This is the same shape round 1 found two sentences later: a provenance sentence that claims more than the bundle holds. Fix: drop the sentence, or narrow it ("Its flows and picks are the published product's").

- **[severity: fragile (attribution gap in a new citation line)]** `vignettes/segment-discharge.Rmd:413-425`: the new Data line lists the balance's inputs as climr normals, CGIAR AET held to Fu–Budyko, and the BC Hydrologic Zones. It omits two inputs that shape the published values:
  - **ERA5-Land snow normals** (`snowmelt_doy_50`, `swe_max`, through `cd`). Since #16 and #102 they are among the static predictors on which the donor picks the k = 5 gauges whose shares give every published balance month and day (`research/water_balance_method.md`, "Monthly shares from donor gauges").
  - **The Copernicus GLO-90 DEM**. climr's 1981–2010 normals are downscaled onto it (`research/water_balance_method.md:13`), and it gives the `elev` predictor.

  Both are Copernicus products whose licences ask for a source notice where derived products are distributed. As written, the line reads as the balance's complete input list. Fix: add both to the Data line.

- **[severity: minor bug (published claim)]** `vignettes/station-flow.Rmd:649-650`: "The map's layers come from the Freshwater Atlas and BC Geographic Names." The station points come from HYDAT STATIONS (`data-raw/station_vignette_map.R:9`, `vm_stations(hydat, …)`), not from either source named. This predates the branch (main: "Map layers from the Freshwater Atlas (fwapg) and BC Geographic Names"), but the branch rewrote the sentence. Fix: "…the Freshwater Atlas, HYDAT's station locations and BC Geographic Names", or "most of the map's layers…".

## Not findings (checked)

- Round 1's three fixes are correct:
  - The narrowed routed claim matches lines 150-165 of the data script.
  - The new date guard compares two `Date`s that are equal today and would differ after a map-only regeneration, so it can fire.
  - CLAUDE.md:50 now says monthly-flow has no word cap, which `grep wordcount vignettes/*.Rmd` confirms. Its other claims hold: no issue pointers remain in any article's prose (the only GitHub link to a PR is the merged fwapg PR 6), and the remaining "latest" and "New" are "latest release", "the latest years" and "New Graph".
- The word-cap guards fail loudly (`stopifnot(length(cite) == 1)`) if the heading is renamed. Round 1 measured 829/900 and 580/600.
- `format(ct[[1]], style = "text")` returns one string with embedded newlines. In a markdown bullet these become lazy continuation lines, and they render inside the item. This behaves as on main's inline chunk.
- Station-flow's Theil–Sen and Mann–Kendall definitions and the four trend references were checked in round 1 (against `cd::cd_trend()` and Crossref). Theil (1950) is cited by part I's pages only, which is incomplete but not wrong.

## Verdict

One sentence to fix before merge (segment-discharge:379, which claims every number is the published product's). The segment-discharge Data line omits ERA5-Land and GLO-90, two inputs to the published monthly and daily values. Station-flow's map-layer sentence leaves out HYDAT's station points, a minor pre-existing inaccuracy. The code (helper, tests, guards) is clean.
