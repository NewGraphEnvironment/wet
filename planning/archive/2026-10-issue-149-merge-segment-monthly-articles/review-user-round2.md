# Review round 2: reader-review changes to segment-discharge (64c4272..HEAD: d2ba1e4, 6923b24, ac44c5c)

## Checklist read

- `code-check.md` (37 H3): read the prose of all 14 under `## Mechanisms` (table rows skipped), plus
  "An assertion that matches an interpolated value cannot see the claim around it". 22 skipped.
- `code-check-r.md` (111 H3): read "Moving prose into a code chunk hides it from tools that scan the
  document", "A duplicate knitr chunk label fails the build…", "`source()`ing a config into the render
  environment…", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package",
  "A `{python}` chunk needs reticulate even with `eval = FALSE`". 106 skipped.
- `code-check-spatial.md` (93 H3): read "sf: `st_intersection()` / `st_difference()` return a
  GEOMETRYCOLLECTION…", "`st_union()` fails after `st_transform()`…", "`geom_sf(data = NULL)` draws
  nothing", "`sf::st_make_valid()` rewrites geometry…", "FWA main flow is not edge type 1000 alone",
  "A name is not a key…". 87 skipped.
- `code-check-shell.md` (67 H3): none read; the diff has no shell. 67 skipped.
- pkgdown (CLAUDE.md "pkgdown Publishing"): footnotes (none in the Rmd; the one `[^` hit is a regex at
  :1061), root markdown (not touched).

Probes: `readRDS("inst/vignette-data/segment_values.rds")$segments` (fwa 4,907,441; no_lut 369,217;
neither 374,598; pick_routed 3,154,131; pick_balance 1,378,712; far_low 222,906; no_lut_connector
366,362); `data/checks/segment_output_20260717.txt:12-16`; `scripts/segment_output.R:103-216`; the
rendered prose of `docs/articles/segment-discharge.html` (built 21:04, same minute as ac44c5c);
the new `area_in()` on the bundle's catchments (EPSG 3005: 0.99987, 0.99996; Quick-in-Buck 0.077) and with
Houston's catchment shifted 500 km (returns 0, so the guard fires); word count on HEAD with the
chunk's own logic (1,820 < 2,000); duplicate chunk labels (none); `.Rbuildignore` (the .bib ships);
every `href="#ref-*"` has an `id` (7/7); knowledge's articles do use `bibliography:` and print
`citation("knowledge")`.

**The Limits fix holds structurally.** `segment_output.R:142-145` builds `s` from
`seg$watershed_feature_id %in% ws` (segments with a lut watershed in a basin's output; NA watersheds never
match), `seg_ids` is `s$linear_feature_id` (:149), routed rows are fetched only `JOIN seg_ids` (:150-153),
and both `rows_b` and `rows_r` are subsets of `s`. A segment with no lut row gets no row from either
source, and the report's "with a watershed but in no basin's output: 0" closes the other gap. The script's
own `stopifnot(!anyNA(out$pick))` also means a segment with `source` NA has no balance row, so `neither`
is exactly "no row from either source". `own_pct` = (fwa − neither)/(fwa − no_lut) = 4,532,843 /
4,538,224 = 99.88 %, and every segment with a value is matched, so the numerator is the matched set's.

## Mechanism

The mechanism (a sentence reworded, count to share or a new phrase for a code-defined set, while its guard
or denominator stayed) was checked against every changed sentence below. Inside the article, ac44c5c's
rewordings each now carry the right denominator. It still reaches two places outside the sentence it
started in: CLAUDE.md:51, which changed "the share of segments with a value" in its first item but kept
"the province counts" in its `pick` item (finding 3); and the fork commit, which moved from a value printed
from `ps$routed_commit` to a literal in the .bib, while the guard compares the data with a literal in
the Rmd and never reads the .bib (finding 2). A milder form survives at :256–258, where the count-to-share
rewrite fixed the denominator but dropped the connective, so the 5 % can be read as an extra balance share
(finding 1).

## Enumeration

| # | Sentence / item (HEAD line) | Claim | Guard (file:line) | Covers exactly? |
|---|---|---|---|---|
| 1 | 186–187 "It has a value on 99.9% of the segments matched to a watershed polygon." | value ∩ lut-matched / lut-matched, 1 dp | Rmd:149–151 `own_pct`, `round(own_pct, 1) == 99.9` | y: denominator fwa − no_lut, the lut-row set (data-raw/segment_vignette_data.R:91 `l.linear_feature_id IS NULL`, held equal to the report's "with a watershed in the lut", :215); numerator all-with-value, which is a subset of matched (segment_output.R:142); printed by `pct1`, guarded on the printed value |
| 2 | 187–188 "Segments matched to none, almost all connection lines and secondary channels, have no value." | unmatched → no value; >90 % connector edge types | Rmd:150–151 `no_lut <= neither`, `no_lut_connector > 0.9 * no_lut` (99.2 %) | y: "have no value" is structural (segment_output.R:142–153), the guard is necessary-only but cannot be wrong while that holds; edge set data-raw/segment_vignette_data.R:89 |
| 3 | 189 "It is public, in three datasets:" | three datasets | setup part partition (unchanged) | y |
| 4 | 191–192 `segment_monthly` "each segment's flow from each source, for the year (month 0) and the twelve calendar months" | content | sources check (unchanged) | y (with :244 saying only most segments have both) |
| 5 | 195 `segment_daily` "per day (29 February folded into 28)" | content | unchanged | y |
| 6 | 214 "@chapman_etal2018Wateralloc:" | citation | resolves (`#ref-chapman_etal2018Wateralloc`) | y |
| 7 | 244 "Most segments, 69%, have a value from both sources" | n_both / fwa, "most" | Rmd:240 `n_both_src > 0.5 * fwa`; n_both = 3,374,133 = report :14 | y: 68.76 → 69 |
| 8 | 256–258 "`pick` takes routed PCIC on 64% of the Freshwater Atlas's segments and the balance on 28%, 5% of all segments because routed flow is far low there." | 64.27, 28.09, 4.54 % of fwa; far_low = flips under the cut | Rmd:240 `far_low > 0`, `far_low == 0.2`; report :15 "222906 of them under the cut" | denominator y (now "of all segments"); set y (flip = routed present and pick balance, only by the cut on own line, segment_output.R:208); **reading n**: finding 1 |
| 9 | caption 279–282 "6% of BC's segments … nor the few (under 1%) of that order with neither" | none < 1 % of drawn main-flow order ≥ 5 | Rmd:284–285 `drawn[["none"]] < 0.01 * sum(drawn)` | y: `drawn` is over `stream_order >= 5 AND edge_type IN main_flow` (data-raw/segment_vignette_map.R:71), denominator includes none (1,557 / 284,553) |
| 10 | 473–474 "flows north-west from Houston to join the Skeena at Hazelton" | Quick gauge W and N of Houston gauge | Rmd:468–470 | y (gauge coordinates: 942,023/1,069,026 vs 953,406/1,044,424; Hazelton accepted) |
| 11 | 474–477 "Three gauges in its basin sit one inside the next … the Houston gauge … measures it too, and the Quick gauge … drains the whole basin above" | nesting | Rmd:460–467 `area_in() > 0.99` with `sum()` | y: disjoint case now returns 0 and fails (probed); `length == 1` asserted on both sides; a GEOMETRYCOLLECTION result keeps its polygon area |
| 12 | 481–485 "the Chinook salmon windows for the Bulkley, from New Graph's species-timing table, which cites @gottesfeld_rabnett2007SkeenaFish" | the table's three rows cite that one source | Rmd:390 `identical(unique(ch$source), key)` | y as worded. The fry-migration row's note ("citation listed under the other area in the template", life_history_bulk.csv:6) is no longer stated; that caveat was cut on the reader's request, and the sentence does not claim Gottesfeld and Rabnett give Bulkley-specific fry dates |
| 13 | 953–956 Limits "The balance reaches a segment through `fwapg`'s lookup …, and both sources are published only on matched segments, so the 8% of segments matched to none have no value." | structural; 7.52 % → 8 | none on the share (computed inline); structure segment_output.R:142–153 | y: verified above; the 5,381 matched segments without a value are not named, but nothing says otherwise |
| 14 | 978–979 "The province shares are from the segment table that build was cut from." | provenance | setup: report equal to the build's copy, every part byte-identical | y by construction: the 99.9/64/28/5/8 % come from `sg` (segment report); 69 % uses `reader` (live build) and the caption's 6 %/under 1 % and the Nechako 98 % come from the map (live build), which equal the table's under the byte-identity check |
| 15 | 1001–1008 "The product is made with … `fwapg` and New Graph's fork of it [@norris…], and the R package `wet`; the recipes above read it with `duckdb`, and the figures are drawn with `ggplot2`, `gq` and `sf`." | software | descriptive; Rmd:74–77, 268–272, 354 | y |
| 16 | 1010–1011 `citation("wet")` | wet's citation | renders "Irvine A (2026) … doi:10.5281/zenodo.23305781 … Version 0.4.29" = DESCRIPTION | y |
| 17 | 1020–1022 Data: product address, manifest, "as `wet_catalog()` does", "reads the build of 24 October 2026" | address, read path, build date | Rmd:52 `pub$manifest == wet:::wet_catalog_url`; R/wet_catalog.R:3–6; `built_text` from `pub$built` | y |
| 18 | 1023–1026 Routed flow "by New Graph's fork of `fwapg` [@norris…]" (References: "Version 7c30f58") | the fork commit printed from the .bib | Rmd:1015 `identical(ps$routed_commit, "7c30f58")` | **n**: the guard checks the data against an Rmd literal, not against the .bib that prints it. Finding 2 |
| 19 | 1027–1028 Stream network: "the Province of British Columbia's Freshwater Atlas Stream Network, through DataBC [@flnrord2021FreshwaterAtlasb]" | credit | bib entry (catalogue URL, FLNRORD) | y |
| 20 | 1029–1031 Gauge records: HYDAT [@eccc…], release 2026-07-17 | release | `ps$hydat_release` | y |
| 21 | 1043–1044 Chinook windows: table [@gottesfeld…] | credit | row 12 | y |
| 22 | 6–7 `nocite` Nash, Moriasi; 1046–1049 `## References` / `::: {#refs}` | bibliography | built page: 7 `id="ref-*"`, all 7 distinct `href="#ref-*"` match, incl. the two raw-HTML table notes | y |
| 23 | CLAUDE.md:51 "what the published product is (the share of segments with a value, …)" | article content | none | y |
| 24 | CLAUDE.md:51 "which value to use (`pick`: its rule, why a default exists, the province counts, …)" (unchanged clause) | article content | none | **n**: the article now gives shares. Finding 3 |
| 25 | CLAUDE.md:51 "the three gauges' FWA catchments and points in `monthly_map.rds` … which guard the sentences on how the gauges nest and which way the Bulkley flows; the article draws no Bulkley map" | article reads | Rmd:456–470 | y |
| 26 | CLAUDE.md:51 "segment-discharge names its software in prose, prints `citation("wet")` and cites from `vignettes/segment-discharge.bib` through pandoc, as knowledge's articles do, and the other articles' package lines still come from … `wet_software_cite()`" | pattern | grep: knowledge `chinook_rearing.Rmd:5,354`, `habitat_thresholds.Rmd:5,404`; `wet_software_cite` in station-flow, short-record-flow, flow-change-sparse-gauges only | y |
| 27 | CLAUDE.md:51 colours "(`pick_source`, `gauge`, `segment_map`, `flow_source`) … (`hydrograph`)" | registry layers read | Rmd:74–85 | y; `bulkley_map` has no reader left (grep outside docs/, planning/, NEWS.md: none) |
| 28 | data-raw/monthly_vignette_map.R:1–6 header | what the article reads | Rmd:456–470 | y |

Removed-object sweep: `reg_main`, `pal_bmap`, `bulkley_map`, `catchment_*`, `#ref-chapman2018`,
`#ref-gottesfeld2007`, `#ref-nash1970`, `#ref-moriasi2007`: no reader left outside `docs/`, `planning/` and
NEWS.md history (`reg_main` in short-record-flow and flow-change-sparse-gauges is their own binding).

## Findings

**[severity: fragile]** vignettes/segment-discharge.Rmd:256–258 — the denominator is fixed, but the
sentence "`pick` takes routed PCIC on 64% of the Freshwater Atlas's segments and the balance on 28%, 5% of
all segments because routed flow is far low there" now has no connective between the 28% and the 5%, so it
also reads as a third list item: the balance on 28% and, besides that, on 5% because routed flow is far
low, which makes 33%. The 5% is part of the 28% (222,906 of 1,378,712; the other 1,155,806, 23.55%, are
segments routed PCIC does not reach). A wording that cannot be read as additive, with the remainder named
and guarded:
"…and the balance on 28%: on 5% of all segments because routed flow is far low there, and on the rest
because routed PCIC has none", with
`stopifnot(sg[["pick_balance"]] - sg[["far_low"]] == n_src[["wet_balance"]] - n_both_src)`
(1,378,712 − 222,906 = 1,155,806 = 4,529,939 − 3,374,133 = the report's "balance only", :14).

**[severity: fragile]** vignettes/segment-discharge.Rmd:1012–1015 — the fork commit printed in the
References ("Version 7c30f58") now comes from `vignettes/segment-discharge.bib:70`, not from
`ps$routed_commit`. The guard `identical(ps$routed_commit, "7c30f58")` compares the data with a second copy
of the literal in the Rmd and never reads the .bib. Its comment states the property ("the fork's commit is
the one segment-discharge.bib carries") without executing it. If the routed run moves to a new fwapg
commit, the guard fires, and updating the Rmd literal alone turns it green while the References still
cite 7c30f58. Read the .bib itself (knitr runs in `vignettes/`), e.g.
`bib <- readLines("segment-discharge.bib"); stopifnot(any(grepl(sprintf("version = {%s}", ps$routed_commit), bib, fixed = TRUE)))`,
and drop the Rmd literal.

**[severity: fragile]** CLAUDE.md:51 — the `pick` item still says the article gives "the province counts"
("which value to use (`pick`: its rule, why a default exists, the province counts, …"), while the same
commit changed the first item to "the share of segments with a value" and the article now prints only
shares (:244, :256–258, :955, :979 "The province shares"). This is the mechanism's own shape: one
restatement reworded, its sibling left behind. Change it to "the province shares". The later "takes the
province's pick counts from the tracked segment report" is about the data script, which does take counts,
and stays.

The ac44c5c fixes hold: "segments matched to a watershed polygon" is exactly the guard's set; the Limits
bullet's "both sources are published only on matched segments" holds by construction
(`segment_output.R:142–153`: routed rows are fetched only for `seg_ids`, the lut-matched segments of a
basin's watersheds); `area_in()`'s `sum()` makes a disjoint pair fail (probed, returns 0); "5% of all
segments because routed flow is far low there" now has the right denominator (finding 1 is only about how
it reads).
