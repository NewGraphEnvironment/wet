# Code check, round 1 (#145): branch 38a9672...HEAD

## Checklist read

- Index (`checklist.txt`): in full, all four files' headings and first sentences.
- code-check-r.md: full sections read for "`sort()` and `order()` collate by `LC_COLLATE`…", "Postgres row order is never fixed…", "Moving prose into a code chunk hides it…" and "A duplicate knitr chunk label fails the build…". The remaining ~110 headings were not read in full. I judged the rest from their index lines: "`$` on a list partial-matches…" (`packageDescription()$RemoteSha` has no longer sibling key, so it does not apply), "A `data-raw/` script must load the source tree…" (the map script calls `devtools::load_all()`; `vignette_bib.R` loads nothing of wet), "Tests that silently do not run", "testthat counts an uncaught error under `error`" (used when I ran the test file).
- code-check-spatial.md: full sections read for "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline…" and "A name is not a key: `GNIS_NAME` matches features all over BC". The other ~90 headings were not read in full (no terra or GDAL in this diff).
- code-check-shell.md: no full sections read. The diff has no shell; the index was read only.
- code-check.md: Mechanisms prose read in full for "A guard that fails toward pass" and "A fixture that cannot reach the failure mode", and in part for the rest of the Mechanisms block. Not read: the other 12 Mechanisms H3s in full, and Rules that stand alone, Security, and Spreadsheets.
- writing.md (soul): applied from the index in CLAUDE.md. I did not reread the full text.

## Findings

- **[severity: fragile]** vignettes/flow-departure-normal.Rmd:336 (guards at :227–246): the sentence is "From `r min(low_years)`, every bar falls below the median year as well as the mean". It claims every bar from the first low year through the last year. The guards only cover the low years themselves:
  - `all(low$pct < low$median_pct)` checks only the low-year bars.
  - `identical(sort(c(low_years, up_years)), recent)` with `length(up_years) == 1` does not make the low years one run ending at `last_year`.

  Suppose a refresh puts the one above-normal year inside the span, for example 2024 above with 2022–2023 and 2025–2026 below. Every guard passes, and the article prints "From 2022, every bar falls below…" while the 2024 bars sit above the mean. Today the claim holds, because 2022 is the exception and the low years are 2023–2026. Fix: require `identical(low_years, min(low_years):last_year)`, or reword the sentence to "In `r years_text(low_years)`, every bar…".
  - **Rule:** writing.md "State each claim by the code's definition" (each guard covers the set its sentence names); code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug]** vignettes/flow-departure-normal.Rmd:729–730: the Data list says "Streams, catchments and stream mouths: the Province of British Columbia's Freshwater Atlas Stream Network, through DataBC [@flnrord2021FreshwaterAtlasb]".
  - The catchments are not from the Stream Network dataset. They come from `fwa_watershedatmeasure()` over the FWA's watershed polygons (`scripts/vignette_map_lib.R`, `vm_catchments()`).
  - The lakes the map draws come from `fwa_lakes_poly`, and the keymap's outline from `fwa_bcboundary`. Neither is credited.
  - Before this branch, the line credited only "the stream network" to that dataset. The branch widened it to cover catchments, which makes it a false attribution.

  Fix: credit the Freshwater Atlas as a whole (streams, watersheds, lakes, boundary), or split the bullet by layer.
  - **Rule:** writing.md "State each claim by the code's definition"

- **[severity: fragile]** data-raw/vignette_bib.R:228 and :269: `sort(unique(keys))` and `entries[sort(names(entries))]` sort in the session's `LC_COLLATE`. The committed .bib currently orders `Kendall` between `gq` and `kendall1975RankCorrelation`, which is case-insensitive en_US order. A run under `C` collation (CI, or `LC_ALL=C`) puts `Kendall` first. The same citations then rewrite a file marked "do not edit", and the change looks like a content change. Fix: `sort(..., method = "radix")`.
  - **Rule:** code-check-r.md "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"

## Checked, not flagged

- Every other number and claim in the rendered text (docs/articles/flow-departure-normal.html) has a guard that covers the set it names:
  - 21 of 24, 6, 2 of 24 downward, "(1)"
  - 24%, about 120 km north-west, Buck mouth in Houston, Hazelton < 2 km
  - 1981–1998 and 1999–2010, 2011 start, 3 of 30 bars at 80–91%, 2 provisional years
  - the timing windows left out, the borrowed citation, `cd`'s use of `Kendall` and `zyp` (`cd_trend()` calls `check_installed(c("Kendall", "zyp"))`)
- Bearing check: `atan2(dx, dy)` gives an azimuth from north, and the 45-degree bins are correct.
- `vm_into()`:
  - The SQL is moved verbatim.
  - Its rows come back in the given order (`match()`, `drop = FALSE`).
  - The mouth query's `DISTINCT ON … ORDER BY blue_line_key, downstream_route_measure` is unique within a blue line.
  - The 2 km tolerance on mouth-to-town distances is wide enough for the centreline offset.
- Towns are looked up by name only within 15 km of the mouths and filtered by feature type; the data script checks `setequal()` and that exactly two rows remain.
- No duplicate chunk labels. `tests/testthat/test-vignette_data.R` passes with `NOT_CRAN=true` (247 expectations, 0 failed, 0 errors). The .bib is not in `.Rbuildignore`, so it ships in the package build.
- Arguez and Vose (2011, p. 699) for "one of the 30-year periods the World Meteorological Organization sets for climate normals":
  - Not verified: the journal page answered 403, and the paper is not in the local Zotero full-text cache.
  - From memory, which may be wrong: the paper reserves WMO *standard* normals for 1901–1930, 1931–1960, 1961–1990 and so on, and says WMO recommends updating normals each decade. If so, the article's wording, which avoids "standard", is defensible, but the author should confirm the page says it.
