# Review: reader-review changes to segment-discharge (64c4272..HEAD: d2ba1e4, 6923b24)

## Checklist read

- `code-check.md` (37 H3): read all 14 under `## Mechanisms` (prose, `|` rows skipped), plus
  "An assertion that matches an interpolated value cannot see the claim around it" and
  "Documentation Staleness". 21 not read (security, spreadsheets/PDF, infra-only, cli pluralisation, etc.).
- `code-check-r.md` (111 H3): read "Moving prose into a code chunk hides it from tools that scan the
  document", "A duplicate knitr chunk label fails the build…", "`source()`ing a config into the render
  environment…". 108 not read (no testthat, DBI, arrow, yaml, cli or shell-out code in this diff).
- `code-check-spatial.md` (93 H3): read "sf: `st_intersection()` / `st_difference()` return a
  GEOMETRYCOLLECTION…", "`st_union()` fails after `st_transform()`…", "FWA main flow is not edge type 1000
  alone", "A name is not a key…". 89 not read.
- `code-check-shell.md` (67 H3): none read; the diff has no shell.

Probes run: the bundle's `segments` and map `drawn` counts; `data/checks/segment_output_20260717.txt`
lines 12–16 and 53–57; `scripts/segment_output.R` lut handling; the word-count logic on HEAD (1,802 words;
1,896 at 64c4272); duplicate chunk labels (none); the built `docs/articles/segment-discharge.html`
(prose, `id="ref-*"` vs `href="#ref-*"`: all 7 keys resolve, no `???`); a disjoint-polygon probe of the new
`area_in()` in a scratch dir.

## Enumeration

| # | Sentence / item (Rmd line) | Claim | Guard | Covers exactly? |
|---|---|---|---|---|
| 1 | 185–186 "It has a value on 99.9% of the segments that drain a watershed of their own." | (with value) / (with own watershed) = 99.9 at 0.1 | 148–149 `own_pct`, `round(own_pct,1)==99.9` | Precision yes. **Set no**: denominator is "has a row in `fwa_streams_watersheds_lut`", which includes off-own-line segments the article itself (250–252) says the lookup gives *another line's* watershed. Finding 2. |
| 2 | 186–187 "Segments without one, almost all connection lines and secondary channels, have none." | no-lut segments have no value; >90 % are connector/secondary edge types | 149 `no_lut <= neither`, `no_lut_connector > 0.9*no_lut` | "almost all": yes (366,362/369,217). "have none": guard is necessary only, but structural (`scripts/segment_output.R:16-18`). **Set**: as row 1, a side channel without a watershed *of its own* does have a value. Finding 2. |
| 3 | 187–188 "It is public, in three datasets:" | three datasets | 136 parts partition into 3 datasets | Yes |
| 4 | 190–191 `segment_monthly` "each segment's flow from each source, for the year (month 0) and the twelve calendar months" | content | 138 sources | Yes (unchanged semantics) |
| 5 | 194 `segment_daily` "per day (29 February folded into 28)" | content | 137 sources, group parts | Yes |
| 6 | 212–213 "after @chapman_etal2018Wateralloc:" | citation | key resolves (HTML `#ref-chapman_etal2018Wateralloc`) | Yes |
| 7 | 243 "Most segments, 69%, have a value from both sources" | n_both/fwa, "most" | 239 `n_both_src > 0.5*fwa`; n_both = 3,374,133 = report line 14 | Yes |
| 8 | 255–257 "`pick` takes routed PCIC on 64% of the Freshwater Atlas's segments and the balance on 28%, **5% of them** because routed flow is far low." | far-low share *of the balance's segments* | none on the share; value is `far_low / fwa` | **No**: 5% is of all FWA segments; of the balance's picks it is 16%. Finding 1. |
| 9 | 278–284 caption "nor the few (under 1%) of that order with neither" | none < 1 % of drawn main-flow order ≥ 5 | 284 `drawn[["none"]] < 0.01*sum(drawn)` (1,557 / 284,553) | Yes |
| 10 | 389–390 comment + 479–483 "Chinook salmon windows for the Bulkley, from New Graph's species-timing table, which cites @gottesfeld_rabnett2007SkeenaFish" | the table cites that one source for the three rows | 390 `identical(unique(ch$source), key)` | Yes |
| 11 | 471–472 "flows north-west from Houston to join the Skeena at Hazelton" | Quick gauge W and N of Houston gauge | 468 | Yes (Hazelton accepted) |
| 12 | 472 "Three gauges in its basin sit one inside the next" / 473–475 "measures it too … drains the whole basin above" | nesting | 459–465 `area_in() > 0.99` | Direction and set yes, but **fails toward pass** on disjoint catchments. Finding 3. |
| 13 | 951–953 Limits "Of the 374,598, 369,217 have no watershed in the lookup…" (unchanged, context changed) | counts | none needed (printed) | Antecedent count removed at the pick paragraph; still two segment counts. Finding 4. |
| 14 | 976 "The province shares are from the segment table that build was cut from." | provenance | setup chunk / data script | Yes |
| 15 | 998–1005 "made with … `fwapg` and New Graph's fork of it [@norris…], … `wet`; recipes read it with `duckdb`; figures drawn with `ggplot2`, `gq` and `sf`" | software used | none (descriptive) | Holds by code read (gq: registries, bbox, breaks) |
| 16 | 1007–1008 `citation("wet")` | prints wet's citation | renders (HTML shows concept DOI) | Yes |
| 17 | 1017–1019 Data: product address, manifest, "reads the build of 24 October 2026" | address, read path, build date | 52 manifest = `wet_catalog_url`; `built_text` from `pub$built` | Yes |
| 18 | 1020–1023 Data: routed flow "by New Graph's fork of `fwapg` [@norris…]" (bib `version = 7c30f58`) | fork commit | 1012 `identical(ps$routed_commit, "7c30f58")` | Yes; HTML prints "Version 7c30f58" |
| 19 | 1024–1025 Stream network: "Province of BC's … through DataBC [@flnrord…]" | credit | bib entry | Yes |
| 20 | 1026–1028 Gauge records: HYDAT [@eccc…], release | release | `ps$hydat_release` | Yes |
| 21 | 1040–1041 Chinook windows: table [@gottesfeld…] | credit | row 10 | Yes |
| 22 | 1043–1046 `## References` / `::: {#refs}`; YAML `nocite` for Nash and Moriasi | bibliography | HTML: 7 `id="ref-*"`, every `href="#ref-*"` (incl. the two raw-HTML table notes) matches | Yes |
| 23 | Word-count chunk with new YAML (no `---` inside `nocite: \|`) | cap 2,000 | runs: 1,802 | Yes |

Removed-object sweep: `pal_bmap`, `reg_main`, `st_lab`, `area_of`, `a_fit`, `catch$part`, `lim_x/y`,
`map_w/h`, `sb_km`, `*_sty`, `main_streams`, `cap_map`, `xy_tk/xy_ho`, old `#ref-*2007/2018/1970` ids:
none still referenced in the Rmd. `bulkley_map` rows: no reader left (`data-raw/readme_figure.R` reads only
`pick_source`, `segment_map`). `tests/testthat/test-vignette_data.R:192-214` still reads `monthly_map.rds`
layers that remain in the bundle; unaffected.

.bib against 64c4272's hand-typed list: Chapman (authors, 2018, JAWRA 54(3) 676–693, DOI), Moriasi
(six authors, 2007, 50(3) 885–900, DOI), Nash (1970, 10(3) 282–290, DOI) all match. Gottesfeld loses the
middle initials ("A.S."/"K.A." → "A"/"K", from Zotero) and the dropped "p. 355" detail went with its
sentence; neither is a wrong claim. The old upstream `fwapg` (Norris 2024) reference is gone by design.

## Findings

**[severity: bug]** vignettes/segment-discharge.Rmd:255–257 — "the balance on 28%, `r pct_of(sg[["far_low"]])`
of them because routed flow is far low" renders "the balance on 28%, 5% of them". `pct_of()` divides by
`sg[["fwa"]]`, so 5% is 222,906 of all 4,907,441 FWA segments; "of them" reads as a share of the balance's
segments, which is 222,906 / 1,378,712 = **16%**. The old text gave a count, where "of them" was right;
converting to a percent kept the referent and changed the denominator. No guard covers the share. Either
"…and the balance on 28%, `r pct(100 * far_low / pick_balance)` of them (16%) because…" or "…28%; on 5% of
all segments that is because routed flow is far low."

**[severity: bug]** vignettes/segment-discharge.Rmd:185–187 (guard 145–150) — the set named is not the code's
set. "segments that drain a watershed of their own" is computed as segments with a row in
`fwa_streams_watersheds_lut` (`fwa - no_lut`). That set includes the side channels and connectors that the
article's own pick bullet (250–252) says "the lookup gives another line's watershed": at least 72,242 such
off-own-line segments carry both sources (`data/checks/segment_output_20260717.txt:16` and `:56`, the
`own_line FALSE` row). So the next sentence, "Segments without one, almost all connection lines and
secondary channels, have none", is false for exactly those connection lines and side channels, which do
have a value (routed PCIC kept). The 99.9% itself barely moves under either definition
((4,532,843 − 72,242) / (4,538,224 − 72,242) = 99.88 %), so this is wording against the code's definition,
not the number: say "segments with a watershed in the lookup" (the Limits bullet's own term, 952) or
"segments the Freshwater Atlas links to a watershed", and "Segments with none, almost all connection lines
and secondary channels, have no value".

**[severity: fragile]** vignettes/segment-discharge.Rmd:459–465 — the new `area_in()` guard fails toward pass
when two catchments do not overlap at all: `sf::st_intersection()` of two disjoint length-1 `sfc` returns a
length-0 `sfc`, `st_area()` of it is `numeric(0)`, the ratio is `numeric(0)`, and `stopifnot(numeric(0) >
0.99)` passes (probed: prints "PASSED"). The nesting sentence (472–475) is then guarded only against
partial overlap, not against a catchment for the wrong station or a misplaced polygon. The setup chunk
already defines `one()` for exactly this ("stopifnot(logical(0)) passes"); wrap the ratio
(`one(...)`) or take `sum(as.numeric(st_area(...)))`. (The pre-diff `inside()` had the same shape; the diff
rewrote it, so the fix belongs here.)

**[severity: fragile]** vignettes/segment-discharge.Rmd:951–953 — the Limits bullet "**Segments without a
value.** Of the 374,598, 369,217 have no watershed in the lookup…" still prints two segment counts, which
item (1) of the reader's review asked to cut, and its "Of the 374,598" lost its antecedent when the pick
paragraph's "374,598 have neither" was removed (the article no longer states that number anywhere else).
It is also the only place left where the reader meets the 5,381 segments that have a lookup watershed and no
value, which the opening's 99.9% implies. Restate as shares, or as "Almost all have no watershed in the
lookup…", guarded by `no_lut > 0.9 * neither` (369,217 / 374,598 = 98.6 %).
