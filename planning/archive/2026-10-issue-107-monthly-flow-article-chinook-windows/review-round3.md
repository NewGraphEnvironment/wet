# Code-check round 3 — branch 107-monthly-flow-article-chinook-windows-fro at e3a16ad

Read-only review against merge-base 5bc6cc2. Diff: `CLAUDE.md` (one paragraph),
`data-raw/monthly_vignette_data.R`, `tests/testthat/test-vignette_data.R`,
`vignettes/monthly-flow.Rmd`. Also read: the rendered text
(`scratchpad/render_after/monthly-flow.txt`), `inst/vignette-data/monthly_values.rds`
(`str()`, provenance, `published_check`, per-station day counts) and
`segment_values.rds` (names), `R/wet_routed_days.R`, `R/wet_shape_predict.R`,
`R/wet_shape_within.R` (`wet_shape_months`), `R/wet_values_compare.R`,
`R/wet_flow_window.R`, `R/wet_doy_month.R`, `R/wet_donor_mean.R`,
`R/wet_segment_monthly.R` (`wet_segment_read`, `wet_segment_parts`),
`R/wet_segment_daily.R`, `scripts/discharge_publish.R` 520-615,
`scripts/pcic_routed_lib.R` 136-200, `scripts/vignette_data_lib.R` 62-130,
`scripts/wb_shape_daily.R` (the fields `shape_daily.rds` carries), `inst/CITATION`,
`DESCRIPTION` (`Config/DOI`), `NEWS.md` and `.github/workflows/update-citation-cff.yaml`
(what the DOI is declared to be).

## Checklist read

- `code-check.md` (329 KB): the `## Mechanisms` prose of all 14 H3s in full, table rows
  skipped; plus "An assertion that matches an interpolated value cannot see the claim
  around it" and "A pluralisation marker takes the quantity of whatever was substituted
  last" in full. Not read: the other 23 H3s under "Rules that stand alone", "Security" and
  "Spreadsheets and PDFs" (none names a shape this diff uses).
- `code-check-r.md` (175 KB): read in full the sections "Moving prose into a code chunk
  hides it from tools that scan the document", "A `data-raw/` script must load the source
  tree", "Tests that silently do not run", "A duplicate knitr chunk label fails the build",
  "`$` on a list partial-matches", "`nzchar(NA)` is TRUE", "`paste()` with a zero-length
  argument returns length ONE", "Under `R CMD check`, tests run from a temp dir",
  "`vapply(..., USE.NAMES = FALSE)` strips ALL dimnames", "`stats::aggregate()` has three
  separate silent behaviours", "`match()` treats NA as a matchable VALUE", "`unlist()`
  prefixes a `split()` group's name", "`tolerance` in testthat is RELATIVE", "`[[` on a named
  ATOMIC vector", "`data.frame()` recycles a scalar against a zero-length column", "Postgres
  row order is never fixed unless the query fixes it", "A `pkg::` call in a test passes
  `devtools::test()`", "`c(name = x)` keeps `x`'s own name", "duckdb in R: the query that
  autoloads `icu`", "`ifelse()` with an all-NA test". 20 of 111 headings; the other 91 name
  tools the diff does not touch (xml2, glue, readr, sf, pak, climr, python, ...).
- `code-check-shell.md` (121 KB): index only, 0 of 67 sections. The diff adds no shell, sed,
  git or `gh` code.
- `code-check-spatial.md` (154 KB): index only, 0 of 92 sections. The diff adds no terra, sf,
  bcdata or GDAL code.

## Findings

- **[fragile, low]** `vignettes/monthly-flow.Rmd:712-715` (Limits bullet) — "the balance's
  days carry a within-month shape fitted at gauges, **not the gauge's own**" is false for one
  of the two gauges in the table that bullet describes. `wet_donor_mean()` gives all weight to
  a donor at distance 0 (`wt <- if (any(dd == 0)) as.numeric(dd == 0)`), so on 08EE013's
  segment the published days carry Buck Creek's own observed within-month weights, and the
  windows paragraph says so eight lines up ("the shape they are laid on is fitted at the gauges
  and this one's nearest is itself", pinned by `abs(wp("move_balance","08EE013") -
  wp("move_obs","08EE013")) < 1`). The first Limits bullet covers the in-sample case for the
  *months* only. Nothing ties the bullet to the data; the article's own assertion contradicts
  it. Remedy: scope it as the first bullet scopes the months, e.g. "fitted at gauges (on a
  calibration gauge's own segment, that gauge's own)".

No other real issue found. The data script's routing path is the build's own
(`wet:::wet_routed_days()` on a fold whose per-sub-basin values do not depend on which
sub-basins are read, `rowsum()` summing in the stored `upstream_subids` order), so the
rounding-tie count is 0 by construction and the recorded 0 is consistent (tradeoff 2). The
balance-days check uses the default relative 1e-9 where the publish uses `tol = 0`; the header
says so (another machine's last bits), and the bundled `max_abs_diff` for that row is 0.
`n_src` is in the same order as `cmp`. `match()` keys are asserted non-NA before use
(`stopifnot(!anyNA(j))`; `seg_bulk$watershed_feature_id` asserted non-NA). `aggregate()`'s
`na.omit` cannot drop a row because `!anyNA(pub_day$q_m3s)` is asserted and the compared count
is held to `nrow(pb_b12)`. `vapply(..., numeric(12))` followed by `t()` gives a 1 x 12 matrix
for one held segment, which `wet_shape_months()` accepts. `wet_segment_parts()` filters the
full `cat_pub` by dataset and scenario, then `wet_parts_groups()` by `BULK`, so passing the
whole catalog is correct. `d$RemoteSha` on `packageDescription()` has no longer sibling key to
partial-match. No duplicate chunk label in the vignette (`provenance-days`, `citation` are
new and unique). The test adds no new `pkg::` beyond `stats::` and `wet:::`. The "concept
DOI" sentence is a contract this repo declares (`NEWS.md`, the CFF workflow read
`Config/DOI` as the concept DOI), so it is a hardcoded judgement, not a derived fact.

## Mechanism (what produced rounds 1 and 2's findings)

Both earlier findings were **prose stating a fact that the data or the document layout
holds, with no guard tying the sentence to it**: "the third segment's days rest on the
publish report" restated which-set the data script's `held` filter produced; "the scores
below" restated a position the section order holds; a signed move beside "below" restated a
sign the number carries. Each is `code-check.md`'s "One fact derived twice" (the sentence is
one derivation, the computation another, and nothing compares them) and "A guard that fails
toward pass"'s *"a comment stating a property is an unexecuted claim"*. The fix shape is the
same each time: compute the claim inline (`held_text`, `drop_of()`), or assert it beside the
number it accompanies, so a rebuilt bundle that falsifies the sentence fails the render
rather than publishing it.

The finding above is one more instance: a which-set sentence ("not the gauge's own") whose
population (every segment) the data contradicts for a member the article itself names.

## Enumeration: every changed sentence stating a count, direction, sign, position or which-set

Rmd line numbers at e3a16ad. "Tied" names the `stopifnot()` or inline `r` expression.

| Rmd | Sentence (claim) | Kind | Tied? |
|---|---|---|---|
| 71-81 | "thirteen values per source", "routed PCIC covers fewer segments than the balance", "twelve months" | count / which-set | pre-existing prose, unchanged except the `wet` link; out of scope (tradeoff 6) |
| 78-79 | "takes the same windows from the published days" | which-set | tied: `src_d` is the same `windows` through the same `wet_flow_window()` call, `all(src_d$basis == "daily")` |
| 115-118 | "placed on FWA segments by `fwapg`" | attribution | wording only; no quantity |
| 123-124 | "a method chosen by a rule set before it was tried" | process claim | not data; `prov$share_method == "donor"` asserted at 607 |
| 409-410 | "The product holds monthly means and ... daily means" | which-set | tied: `v$segments`, `v$segments_daily` both read; render fails if absent |
| 413-414 | "In fry migration, the one window where the approximation is large" | count (one) | tied: `identical(poor_w, "Fry migration")` (371), `length(poor_w) > 0` (358) |
| 415-416 | "the gauge's own days run X below its monthly means at Buck Creek and Y at 08EE003" | direction, sign | tied: `drop_of()` asserts `x < 0` and prints `-x`; `all(win$move_obs[in_poor] < -15)` |
| 417-418 | "Routed PCIC's days fall further (A and B)" | direction, comparison | tied: `all(win$move_routed[in_poor] < win$move_obs[in_poor])`; `drop_of()` sign |
| 418-422 | "its error from the days is smaller than from the months at both: P against Q at Buck Creek, R against S at 08EE003" | comparison, sign | tied: `all(abs(err_of("routed_daily")[in_poor]) < abs(err_of("routed")[in_poor]))`; `ep("routed","08EE013") > 0`, `ep("routed_daily","08EE013") < 0`; values printed signed by `pct()` |
| 422-425 | "The balance's days at Buck Creek fall as the gauge's do (Z)" | direction, equality | tied: `abs(wp("move_balance","08EE013") - wp("move_obs","08EE013")) < 1`; `drop_of()` sign |
| 423-424 | "the shape they are laid on is fitted at the gauges and this one's nearest is itself" | which-set | tied indirectly by the < 1 point assertion above; `prov$shape_method == "donor"` asserted at 759 (a later chunk, but any chunk failing fails the render) |
| 424-425 | "so its window error from the days is its annual error, W" | equality | tied: `abs(ep("balance_daily","08EE013") - wb_off[["08EE013"]]) < 2` |
| 425-426 | "At 08EE003 the balance's days fall only V" | direction, magnitude | tied: `wp("move_balance","08EE003") < 0`; `abs(wp("move_balance","08EE003")) < abs(wp("move_obs","08EE003")) / 2`; `drop_of()` sign |
| 427-428 | "the shape its donor gauges give holds more of late summer than this gauge carries, and its error stays U" | direction, magnitude | tied: the < half assertion (the days fall less than the gauge's, i.e. the shape keeps more of the window) and `ep("balance_daily","08EE003") > 300` |
| 433-435 | "In migration and spawning they agree within N%" | which-set, bound | pre-existing (`good_w`, `max(approx_w[good_w])`) |
| 434-435 | "the days move no source's window by more than 1% in migration or a tenth in spawning" | bound, which-set | tied: `all(abs(c(win$move_routed, win$move_balance)[!in_poor]) < 10)` and `[win$window == "Migration"] < 1`. The length-6 logical index recycles over the length-12 `c()`, which selects the right rows from both halves. "spawning" as the only other good window rests on `identical(poor_w, "Fry migration")` |
| 439-440 | "routed PCIC's error from the months, which in that window reaches M" | superlative | pre-existing (`worst("routed")`, 359) |
| 440-442 | "its window error from the months is the approximation's and its annual error's" | composition | pre-existing (362-363) |
| 463-469 | table caption: "Each source twice: from its published months ... and from its published days" | which-set | tied to the table's own columns (`routed_daily`, `balance_daily` built in `win`) |
| 548 | "(blocked cross-validation), as the fit stored them" | which-set | pre-existing; reference removed only |
| 633-636 | "the snow terms and the donor method were each kept by a rule set before they were tried" | which-set, process | tied for which-set: `identical(prov$share_spec, "snow")`, `identical(prov$share_method, "donor")` (607); "rule set before" is a process claim, not data |
| 655-656 | "recorded here" | position | layout; reference to #67 removed |
| 712-713 | "the window table measures it against the published days" | which-set | tied: the table carries the days columns |
| 713-714 | "the balance's days carry a within-month shape fitted at gauges, not the gauge's own" | which-set | **NOT tied, and false at 08EE013** (the finding above) |
| 714-715 | "routed PCIC's days carry its model's shape" | which-set | description of the source; not data |
| 716-717 | "The scores above are of the months" | position, which-set | layout (the "Monthly error at the gauges" section precedes Limits in the same file); cannot move with the bundle |
| 717 | "the days' shape is scored where it was fitted, not here" | which-set | layout: no daily score in this file |
| 718-719 | "The scores are medians over the province by month, split by basin size and lake outlets; they are not split by region or season" | which-set | describes the `scores`/`groups` chunks; cannot move with the bundle |
| 776-777 | "Routed PCIC's days on the three segments were routed again" | count (three) | tied: `tests/testthat/test-vignette_data.R` `expect_equal(nrow(sd), 3 * 2 * 365)` and `expect_setequal(sd$linear_feature_id, sg$linear_feature_id)`; in the vignette `stations` is the hard-coded 3 and `all(prov$shape_stations %in% stations)`. `stations_bulk` is a code constant, so another machine or release cannot change it |
| 778-779 | "equal after rounding to the published values" | which-set | tied: `all(prov$published_check$differing == 0)` (35-36); the bundled routed-days row is `tol = 0` |
| 779 | "`tie_text` one rounding step apart at a tie" | count | tied: computed from `prov$day_tie`, asserted numeric and >= 0 |
| 780-782 | "made again from its published months laid on the fit's daily shape (`shape_method`, shape code `md5`)" | which-set | tied: inline from `prov`, `identical(prov$shape_method, "donor")`, md5 regex |
| 782 | `held_text`: "on all three segments" / "at A and B, the gauge(s) whose watershed predictors the copy of the fit held; the other segment(s') days rest on ..." | which-set, count, plural | tied: computed from `prov$shape_stations` against `stations`; plural markers branch on the lengths (round 1's fix) |
| 782-783 | "On all three, each calendar month's days average to the published month" | count, which-set | tied: the test recomputes it from the bundle over every station in `sd` (`from_days` vs `bm`, tolerance 1e-9); the script holds the compared count to `nrow(pb_b12)` |
| 809 | "`wet`'s DOI is its concept DOI, which resolves to the latest release" | which-set | not tied to data; a contract literal this repo declares (`NEWS.md`, CFF workflow). Cannot move with the bundle |
| 809-810 | "How the balance is built: [link]" | reference | not a quantity |

Data script and test (changed comments and messages that state a fact):

| File:line | Claim | Tied? |
|---|---|---|
| `monthly_vignette_data.R:46-60` header: "equal after rounding, or one 1e-5 step apart ... counted on its own", "within 1e-9", "a reduced bundle keeps the calibration gauges' only" | the tie rule and tolerances match the code (290-294, 328-329); "calibration gauges' only" is a fact about the bundle on the building machine, recorded as `shape_stations` rather than asserted |
| `monthly_vignette_data.R:296-298` comment "so not 08EE003's" | a fact about this machine's bundle; the code derives `held` from the data and records `seg_h$station_number`, so the comment can go stale on a full run without the code being wrong (the vignette no longer states it, round 1's fix) |
| `monthly_vignette_data.R:333` message "one 1e-5 step apart at a rounding tie (not counted as differing)" | tied: `day_tie` is what was subtracted |
| `test-vignette_data.R:159-160` comment "the same segments' 365 days of each source" | tied: `expect_setequal(sd$linear_feature_id, sg$linear_feature_id)`, `nrow(sd) == 3 * 2 * 365`, `expect_setequal(sd$doy, 1:365)` |
| `test-vignette_data.R:177-179` "the days by routing them again and by making them again from the published months and the fit's shape" | tied: `grepl("^routed days", chk$check) == 1`, `grepl("^balance (days\|months from the days)", ...) == 2`, all `differing == 0` |
| `CLAUDE.md:10` "routed PCIC routed again from ... on only the sub-basins the three weights name (fingerprint held to the tracked daily report, the publish's tie rule)" | matches `monthly_vignette_data.R:148-165, 280-294` |

The only untied sentence that the data contradicts is Rmd 713-714. The untied sentences at
716-719 and 809 describe this file's layout or a declared contract, which a rebuilt bundle on
another machine or release cannot falsify.
