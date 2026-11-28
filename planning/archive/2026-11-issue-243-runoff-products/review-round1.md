# Code-check round 1, #243 (branch against origin/main, planning/ excluded)

## Checklist read

- code-check-r.md (132 headings): read in full: "`on.exit()` at a script's top level never fires"; "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"; "`clusterApply()` returns `NULL` for no tasks, not an empty list"; "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"; "`$` on a list partial-matches, so a longer sibling key answers for a missing one". Index lines checked against the diff for: `sort()` and `order()` collate by `LC_COLLATE`; `ifelse()` with an all-NA test; `match()` treats NA as a matchable VALUE; Rscript reads a script as it runs; `tempfile()` lives in the session tempdir; `download.file(quiet = TRUE)`; Forked `parallel::mclapply()`. 120 not read.
- code-check-shell.md (75 headings): none apply (the diff runs git only through `system2()`, covered under R). 75 not read.
- code-check-spatial.md (98 headings): read in full: "`sf::gdal_utils()` does not raise when GDAL cannot open the source"; "terra: `extract()` returns no row for ground beyond the raster, and counts cells by centre"; "The BC WFS caps an un-paged `GetFeature` at 10,000 features and still answers HTTP 200"; "A GDAL failure partway through `sf::st_read()` returns the rows read so far, with only a warning"; "GDAL reserves 3,276 MB per process before reading a cell, and PSOCK workers outlive their master". 93 not read.
- code-check.md (38 headings): the prose of all 14 H3s under `## Mechanisms` read (table rows skipped). 24 under the other sections not read.

Index, diff and changed files read from file.

## What was verified and holds

- Rule file at HEAD is byte-identical to a5e867c (md5 86c78950…, as the report prints); a5e867c touched only the rule file and planning; the script refuses another version.
- Rule vs code: coverage is `complete.cases()` over all sampled layers in `wet_ws_sample()`, and `iso_flat` is NA exactly where the TIN is, so isoline coverage is "both surfaces have a value"; GDAL `linear:radius=0` never extrapolates; the period scaling, LOO stability (no minimum on subsets), province-wide no-minimum and surface-dependent marking match the header.
- The four-term split is an identity, and `p_yr − aet_cfu` is `wet_wb_raw(, "cfu")`, so "zone adjustment" is the right label.
- Monthly units: `obs_mm` months sum to month 0 exactly at every gauge; TerraClimate `q` is mm per month; NSE comparisons are like for like.
- The grid (x 270000–1880000, y 360000–1740000) covers `ST_Extent(fwa_watershed_groups_poly)` = (273315, 367781, 1870652, 1735771) on m1's fwapg.
- `$` reads on `cv` (`obs`, `aet`, `zone`, `cv_ann`) and on data-frame rows all have exact keys; `clusterApplyLB()` is not reached with zero tasks; every sort uses radix; the period-gauge query and zone extraction match the rule.
- research/runoff_products.md's numbers checked against the report: 14 zones "theirs" plus 2 unstable; 19 TerraClimate log rows and 3 isoline rows equal section 9's list; P largest except zones 03 and 22; AET +29 to +147; storage under 10; zone adjustment 119 to 491 in zones 25–27, 29; 23 isoline drops; 95 gauges above 0.5 flat; period ratios 0.951–1.033; scaling changes no isoline verdict (checked in every zone that has a ratio, zone 23 included); share NSE 0.55 / 0.94 / 0.89 at 283. The terra timing figures are in planning/active/findings.md.

## Findings

- **[severity: fragile]** scripts/runoff_products_compare.R:536 and :541 (report section 4) — The note says "Zones with fewer than 5 scored gauges are marked * and not read", but line 541 stars a zone when *either* product has fewer than 5. So the TerraClimate rows of zones 02 (n 5), 04 (n 5) and 05 (n 7) are starred and called "not read". Section 8 still gives them verdicts, and research/runoff_products.md's disagreement log reads two of them (04 "unresolved", 05 "theirs"). The tracked report contradicts itself and the research file about which TerraClimate zones count. Fix: star each product's row by its own n, or reword the note.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** scripts/runoff_products_compare.R:505, :511–516 (report section 2) — The not-scored table's caption gives "a lake outlet" as a reason a gauge is not scored, and the by-zone line counts lake outlets among those TerraClimate does not score. Nothing in the coverage computation looks at lakes: coverage is the share of basin area on cells with values. In this run no gauge is unscored for being a lake outlet (08EC013 is dropped from the isolines at 0.935 cover, and its flag says yes only by coincidence). The rule's reported item, "The gauges each product does not score, by zone and reason", gets a fixed caption listing candidate reasons, not a reason per gauge. As written, the report states a cause that its data does not show.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: fragile]** scripts/runoff_products_compare.R:61, :64, :476 — `code_commit` is the last commit to R/, scripts/, data-raw/, inst/vignette-data/ **and DESCRIPTION**, but the header the report prints says "(the last commit to R/, scripts/, data-raw/, inst/vignette-data/)". The clean-tree guard on line 61 covers data/checks but not DESCRIPTION. So the guard, the recorded commit and the printed label each name a different set. An uncommitted DESCRIPTION edit (an Imports floor that `load_all()` enforces) passes the guard, and the report then names a commit that does not hold it. Fix: use one path vector for all three.
  - **Rule:** code-check.md "One fact derived twice" ; code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/runoff_products.md, "Coverage" bullet — "21 in the north and northeast (the Stikine, the Nass, the upper Skeena, …)". Among the 21 are 08EF001 (Skeena River at Usk, near Terrace) and 08EB004 (Kispiox River near Hazelton). Neither is upper Skeena, and Usk is not in the north or northeast in the sense the sentence implies. The report's not-scored table does not support the wording; name the middle Skeena, or say "the Skeena".
  - **Rule:** none

Nothing else found: the fetch logging, the WFS count check, the clash check, the gridding, caching, sampling and accumulation, the period ratio, the verdicts and the per-gauge table are sound against the rule and the tracked report.
