# Code-check round 2: #107 branch (ae1c96b against merge-base 5bc6cc2)

## Checklist read

- `code-check.md` (329 KB): the prose of every H3 under `## Mechanisms` (all 14, table rows
  skipped), plus "An assertion that matches an interpolated value cannot see the claim around it"
  and "A pluralisation marker takes the quantity of whatever was substituted last". The other
  standalone, Security and Spreadsheets/PDF rules: index lines only (none name a tool this diff uses).
- `code-check-r.md` (175 KB): full sections for `expect_gt()`/`info`, `$` partial match, `nzchar(NA)`,
  `paste()` zero-length, `strsplit()` trailing field, `identical()` on reader results,
  `vapply(USE.NAMES)`, `stats::aggregate()`, `match()` and NA, testthat `tolerance`, `[[` on atomic
  vectors, `data.frame()` recycling, Postgres row order, `c(name = x)`, `ifelse()` all-NA
  (15 of 111 headings in full; the rest by index line, none naming a shape in this diff: the diff
  has no knitr chunk-label change that collides, no DBI type coercion beyond `::int`, no sprintf
  into SQL of non-finite values).
- `code-check-shell.md` (121 KB): index only. The diff has no shell.
- `code-check-spatial.md` (154 KB): index only. The diff has no terra/sf/GDAL.

Read in full: the branch diff, `data-raw/monthly_vignette_data.R`, `vignettes/monthly-flow.Rmd`,
`tests/testthat/test-vignette_data.R`, the CLAUDE.md paragraph, `scripts/vignette_data_lib.R`,
`R/wet_routed_days.R`, `R/wet_shape_predict.R`, `R/wet_values_compare.R`, `R/wet_flow_window.R`,
`R/wet_doy_month.R`, `scripts/discharge_publish.R:520-619`, `scripts/pcic_routed_lib.R:130-198`,
`data-raw/segment_vignette_data.R:155-199`, `R/wet_segment_monthly.R:110-170` (`wet_segment_read`,
`wet_segment_parts` catalog filter), `R/wet_segment_daily.R`, `R/wet_shape_fit.R:86-92`. The bundle
`inst/vignette-data/monthly_values.rds` was read (read-only Rscript) and its `published_check`,
`shape_stations` (`08EE004`, `08EE013`), `day_tie` (0) and `segments_daily` (2190 rows, 3 x 2 x 365)
inspected; the window moves the prose quotes were recomputed from the bundle through
`wet_flow_window()` (fry migration: routed -33.3 / -24.2 %, balance -21.1 / -5.0 %; spawning at most
-9.2 %; migration at most 0.2 %), which agree with every `stopifnot()` in the `windows` chunk.

## Findings

- **[fragile]** `vignettes/monthly-flow.Rmd:709-710` — the new Limits bullet says "The scores
  **below** are of the months; the days' shape is scored where it was fitted, not here." The scores
  section ("Monthly error at the gauges", line 465) sits *above* Limits (line 695); nothing below
  Limits scores anything. The sentence points the reader the wrong way (a relative descriptor with
  the wrong anchor). Wording fix: "The scores above are of the months".

No other real issue found. Specifically checked and clean:

- **Round-1 fix (`held_text`, `provenance-days` chunk, lines 751-767).** The sentence now branches on
  `prov$shape_stations`, which the data script sets to `seg_h$station_number`, the same rows whose
  days feed the "balance days ... = published months x the fit's shape" check (`compared` =
  `nrow(src_bd)` = 365 x `length(seg_h)`, asserted by `n_src`). All three arms render grammatically:
  all held -> "on all three segments"; 2 held / 1 not -> "the gauges ... ; the other segment's days";
  1 held / 2 not -> "the gauge ... ; the other segments' days". `stations` is defined in the `months`
  chunk, so `all(prov$shape_stations %in% stations)` and `setdiff()` are well-formed; `st_label[...]`
  carries names, which `paste()` in `and_text()` drops. `prov$shape_stations` is an exact key, so
  `$` partial matching cannot reach `shape_method`/`shape_code_md5`. The prose "On all three, each
  calendar month's days average to the published month" is backed by the "balance months from the
  days (Bulkley segments)" check over `pb_b12` (36 rows = 3 x 12).
- **Routed re-route.** `wet_routed_fold()` on the subset of sub-basins the three weights name gives
  the same folded values as the full fold (fold is per sub-basin; `n_days` equality is checked);
  `wet_routed_raw()` sums upstream sets in the order `upstream_subids` lists them, identical to the
  build (`scripts/segment_daily_output.R:207` calls the same function). So this path recomputes the
  parts' values from fwapg's source tables by the build's own route; the tie allowance can only
  excuse a one-step difference, and its count is printed and stored (accepted tradeoff 2). The
  fingerprint guard runs before the reads and `daily_fp` is asserted length 1.
- **Keys and ordering.** `src_rd`/`src_bd` are built row-major from `t()` of one-row-per-segment
  matrices with `rep(id, each = 365)`, matching `wet_values_compare()`'s key; `w_bulk` is
  `ORDER BY linear_feature_id` and duplicates would abort in `wet_values_compare()`. `match()` on
  `seg_bulk$watershed_feature_id` is safe (asserted non-NA at line 127). `aggregate()`'s `na.omit`
  cannot drop rows (`pub_day$q_m3s` asserted non-NA).
- **Guards fail toward abort.** `n_src` pins `compared` to the source row counts for all eight
  checks; `vd_verify(day_parts)` runs before and after the read; `wet_segment_daily(catalog = cat_pub)`
  is filtered to the daily dataset inside `wet_segment_parts()`.
- **Test.** `expect_named()` orders match both bundles (`skill, segments, daily, provenance`;
  `segments, segments_daily, gauges, provenance`). The days-average-to-months expectation uses
  `tolerance = 1e-9` on values of order 1-40, the same bound the script enforces.
- **Citation chunk.** `duckdb`, `gq`, `ggplot2` are in Suggests and `setup-r-dependencies` installs
  Suggests by default, so `requireNamespace()` holds on the pkgdown runner; `d$RemoteSha` and
  `d$Version` have no longer-named siblings in a DESCRIPTION, so `$` cannot partial-match.
- **Chunk labels** are unique (`provenance-days`, `citation` are new); `align = "llrrrrrrr"` has nine
  characters for nine columns.

## Notes (not findings)

- `monthly-flow.Rmd:408` renders "the gauge's own days run `-17%` below its monthly means": `pct()`
  prints the sign and the sentence also says "below", so the sign is stated twice. Wording only.
