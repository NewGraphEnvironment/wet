# Code-check round 2, #243 (branch against origin/main, planning/ excluded; focus on round 1's fixes)

## Checklist read

- code-check.md (38 H3s): the prose of all 14 H3s under `## Mechanisms` read, table rows skipped. 24 not read.
- code-check-r.md (132 headings): read in full: "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "`clusterApply()` returns `NULL` for no tasks, not an empty list"; "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are"; "`sprintf("%g", x)` writes `Inf` and `NA` into SQL as bare words, which Postgres reads as column names"; "`identical()` on two reader results tests the reader, not the file". 127 not read.
- code-check-spatial.md (98 headings): read in full: "terra: `extract()` returns no row for ground beyond the raster, and counts cells by centre"; "`sf::gdal_utils()` does not raise when GDAL cannot open the source"; "terra: `wrap()` carries the tempfile basename in `varnames`, so a committed artifact churns". 95 not read.
- code-check-shell.md (75 headings): none apply (git runs only through `system2()`). 75 not read.

Index, diff and changed files read from file.

## What was checked and holds

- Fix 1 (per-product star): `score_rows()` stars the TerraClimate row and the two isoline rows by each product's own count. The tracked report stars 02, 04 and 05 isolines and 06, 11, 12 and 17 for both products. TerraClimate 02 (n 5), 04 (n 5) and 05 (n 7) are no longer starred. That matches section 8's "too few" cells and the disagreement log's 04 and 05 rows. No other caption claims a zone minimum: section 6's zone table and section 7 make none.
- Fix 2 (a reason per gauge): coverage is `complete.cases()` over every layer, after `extend()` pads ground beyond the raster with NA (`R/wet_ws_sample.R:60-79`). `iso_flat` is NA exactly where the TIN is NA. So for the isolines, "beyond the TIN's triangulation or more than 50 km from a vertex" is the full mechanism on a grid that covers every watershed group. Inverse distance has fewer valued cells than the TIN (1,161,809 against 1,234,489), so naming both is correct. For TerraClimate, ground beyond the lon/lat crop would be a second cause, but no FWA group reaches lat 61 or lon −140/−113. In this run no TerraClimate row is unscored anyway.
- Fix 3 (one path set): `code_paths` drives the guard, `git log` and the printed label. `git log -1 --format=%h -- R scripts data-raw inst/vignette-data DESCRIPTION` is 096ac4be, which is what the tracked report prints.
- research/runoff_products.md against the report: 14 "theirs" plus 2 unstable; P is the largest term except in 03 and 22; AET +29 to +147; storage under 10; zone adjustment 119 to 491 in 25–27 and 29; the 19 TerraClimate and 3 isoline log rows match section 9; 7 isoline zones "too few"; surface-dependent in 07 and 23 only.

## Findings

- **[severity: fragile]** research/runoff_products.md, "Coverage" bullet (line 26) — Round 1's fix rewrote the Skeena clause. The same sentence still files the rest of the 21 northern gauges under "the Liard's and Peace's plains tributaries". By the report's own zones, six of them are mountain gauges, not plains ones: 10AC006 Dease (zone 02, Stikine Plateau), and 10AC004 Blue, 10BA001 Turnagain, 10BB002 Kechika, 10BE008 Geddes and 10BE012 Rabbit (zone 03, Northern Rocky Mountains). Only 10CB001 Sikanni Chief, 10CC002 Fort Nelson and 07FD004 Alces fit "plains", and Sikanni Chief is itself in zone 03. This is the same class as round 1's finding 4, one clause over: the not-scored table does not support the wording. Suggested wording: "the Liard's tributaries (the Dease, Turnagain, Kechika and Fort Nelson among them) and the Peace's Alces".
  - **Rule:** none
- **[severity: fragile]** research/runoff_products.md, "The answer", second paragraph (line 9) — "not material province-wide or in 19 zones" counts zones 07 and 23. The report gives both as "unstable (not material), surface-dependent". The paragraph before counts TerraClimate's "theirs" the other way, as "14 hydrologic zones (two more unstable)", leaving the unstable ones out. A reader of the isoline sentence takes 19 as stable verdicts on one surface. Only 17 are stable, and the two that are not also change with the surface. Write "in 17 zones (two more unstable and surface-dependent; 7 have too few gauges)", or count both products the same way.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
- **[severity: fragile]** scripts/runoff_products_compare.R:31-34 — Round 1's fix 3 made one `code_paths` vector the guard, the recorded commit and the label, and DESCRIPTION is now in all three. The header comment still says the script "refuses an uncommitted R/, scripts/, data-raw/, inst/vignette-data/ or data/checks/", without DESCRIPTION. So a fourth statement of the path set disagrees with the code the fix unified. It is a comment, but it is the script's usage text and the place a reader learns what the guard covers. Add DESCRIPTION, or point the comment at `code_paths`.
  - **Rule:** code-check.md "Documentation Staleness"

No bug found in the code paths: the fixes are correct as far as they reach.
