# Task: Segment-discharge vignette: lead with the published product and read it from the manifest (#64)

## Problem

`vignettes/segment-discharge.Rmd` (880 lines, six sections) predates the publish in #7:

- **It never reads the published product.** It reads `inst/vignette-data/segment_values.rds`, built on 2026-10-11 by `data-raw/segment_vignette_data.R` from the fit outputs and fwapg's tables. Nothing in it reads the manifest (`https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`), the parquet parts or `discharge.fwa_v1_segment_monthly`. The inputs are the same as the product's, but nothing checks the vignette's values against the published ones.
- **It never says where the data is**, or how to get it (`wet_catalog()`, `wet_db_load()`, `month = 0 AND pick`).
- **It buries the point.** "How it is built" opens with wet's match to fwapg's old unrouted annual table on the Salmon River (to five decimals), then a centroid-versus-area sampling scatter. Both are checks on wet's code, not on the product, and they read as unexplained to anyone who did not do that work. Much of the source is label placement and frame guards for two worked-basin maps.

## Context

`vignettes/segment-discharge.Rmd` was written before the publish in #7. It never says where the product lives or how to load it. Its values come from a one-off `segment_values.rds` that nothing compares with the published parts, and the readers' numbers sit behind a check of fwapg parity, a sampling plot and label-placement code. `scripts/discharge_publish.R` compares row and `pick` counts only, never a flow value. This work:

- adds value-by-value cross-checks to the publish BUILD;
- makes the vignette data read the published parts and refuse to build on a mismatch;
- rewrites the page to lead with the product.

Decisions made at the plan gate:
- **No republish.** BUILD is rerun on m4 with the new checks, and also checks that every part's md5 equals the live manifest's. If they all match, S3 stays at build 7c62b9e and the report records the match. If any differ, I stop and come back to you.
- **SALR is the one worked basin.** BULK's map, keymap, gauge trace and table go.

Mechanism choices (mine):
- The vignette data reads the published parts with duckdb `read_parquet(<catalog hrefs>)` over httpfs, filtered on `watershed_group_code`, so row-group pruning reads only a few row groups. `wet_catalog_verify()` runs before and after the read, so a read during a publish is refused. httpfs is installed on m1.
- The routed checks in BUILD read fwapg per drainage code, with the query shape `segment_output.R` already uses, and join in R. No postgres_scanner.

## Phase 1: Value-level cross-checks in the publish BUILD
- [x] ~~`scripts/discharge_publish_lib.R`~~ `R/wet_values_compare.R` (internal, so `data-raw/` shares it, and listed in BUILD's `publish_own`): `wet_values_compare(a, b, id_col, value, tol)` → `c(compared, differing, max_abs_diff)`. Differing means `|a − b| > tol` (relative 1e-9 by default), and keys present on only one side count as differing.
- [x] Add tests for it in `tests/testthat/test-discharge_publish_lib.R`, or extend the existing lib tests if there are any: equal, differing, one-sided key, NA on one side. Restore the bug and watch each test go red.
- [x] `scripts/discharge_publish.R` BUILD, per drainage code after the parts are written, reading the written parts back with duckdb:
  - `pcic_routed`, months 1–12, against `fwa_stream_networks_discharge_monthly` for the same segment and month.
  - `pcic_routed`, month 0, against the mean of that segment's 12 published months.
  - The routed months-1–12 total against the report's fingerprint total (178,035,348.248310 m³/s, to the 6 decimals stored).
  - `wet_balance`, all 13 months, against the fit's `output/<code>.parquet` reached through `fwa_streams_watersheds_lut` (an independent path from the segment table's join).
  - `wet_balance` against the #57 segment table rows for the same segment and month (a check of the write).
- [x] `scripts/discharge_publish.R` BUILD: compare each part's md5 with the live manifest's (`wet_catalog()`) and report `identical to published: n of N` with the published build commit. This is a report line, not a refusal: a new release is meant to differ.
- [x] Report: a new section, "Value cross-checks", with one row per check giving compared, differing and largest difference. A check with any differing row fails the build, as the existing `checks` do.
- [ ] Commit. Then on m4, in a fresh worktree off this branch with `data/wb` symlinked (m4 memory note), run BUILD, copy back `data/checks/discharge_publish_20260717.txt`, and commit it. If any part's md5 differs from the published one: stop, report, ask.

## Phase 2: Vignette data from the published parts
- [ ] `data-raw/segment_vignette_data.R`:
  - Read segment values for SALR and BULK from `wet_catalog()`, month 0, both sources, with `pick`. BULK stays only if Phase 3 still needs it; otherwise SALR alone.
  - Read each gauge's segment values the same way, filtered to the gauges' groups.
  - Verify the parts by HEAD/ETag before and after the read.
- [ ] Refuse to build unless:
  - the published balance values equal the fit's `output/` (month 0, through the lut);
  - the published routed values equal `routed_annual()` from fwapg (the tracked routed table).
  Record compared, differing and largest difference for each in `provenance$published_check`.
- [ ] Provenance records the manifest URL, its `built`, its `wet_commit`, `segment_commit` and the md5 of each part read.
- [ ] `skill$routed_mm` and `gauges_salr$routed_mm` come from the published routed value on the gauge's segment, not from fwapg directly.
- [ ] Drop what leaves the page: the `scripts/mad_parity.R SALR` run, `parity`, `sampling`, `upstream_area_100`, `salr_stale_segments`, `fwapg_discharge_rows` and BULK-only items.
- [ ] Keep the existing guards: dirty tree, scoring code, the routed table and commit against the tracked report.
- [ ] Rebuild `inst/vignette-data/segment_values.rds` on m1, and also `segment_map.rds` if the map layers shrink (SALR only). Update `tests/testthat/test-vignette_data.R` to the new names and the published-check fields, including that every `differing` is 0.

## Phase 3: Rewrite the vignette around the product
- [ ] First screen: what `segment_monthly` and `watershed_monthly` hold (one row per feature × month 0–12 × source), the two sources, what `pick` selects (`wet_source_pick()`: routed unless under 0.2 of the balance on a watershed's own line), and the manifest URL. Then a read example (`eval = FALSE`): `wet_catalog()`, `wet_db_load()` with fresh's `month = 0 AND pick` query, and plain duckdb `read_parquet()` on the hrefs.
- [ ] "How each source was made": two short paragraphs. Routed PCIC is placed on the FWA by fwapg's crosswalk. The open balance is fitted by zone at HYDAT gauges and scored held out by blocked CV. Keep the terms the page uses.
- [ ] "How the numbers line up at the gauges":
  - Both sources at the gauges both cover: bias, mean absolute error, spread (IQR), and the share within ±20%.
  - The balance held out at all 315 gauges.
  - Keep the comparison scatter and the province map, and drop the histogram.
  - Cut the strengths-and-limits table and the "which to use" bullets. The page says what `pick` selects and nothing more.
- [ ] SALR worked basin: map, gauge table and paragraph, now on published values, with `pick` shown. Drop BULK. Keep the simplest labelling that passes the cartography self-review. `map_labels()` stays only if SALR needs it.
- [ ] Limits: keep the facts (coverage, dry zones, small streams, segments without a watershed) and drop the advice.
- [ ] Validation: one paragraph that links `research/fwapg_mad_method.md` for the parity and sampling checks, and the publish report for the value cross-checks. Remove the parity, sampling, stale-area and recipe chunks.
- [ ] Remove the code the shorter page no longer needs (BULK, keymap, palettes no longer used). Assert the new prose numbers in `stopifnot()` guards, as the page does now. Keep the named-on-map guard and the word cap, and lower the cap to fit the shorter page.
- [ ] The vignette asserts that `provenance$published_check` has 0 differing rows, and cites the published build in "Cached inputs".
- [ ] Check `inst/cartography/wet_segment.csv`: drop classes the page no longer uses, together with the asserts in the vignette's `classes()`.
- [ ] Render with `devtools::build_vignettes()` or `pkgdown::build_article()`, read every figure PNG against the cartography self-review, and check the word count.

## Phase 4: Research and docs
- [ ] `research/fwapg_mad_method.md`: line 19 points at the vignette. Make the research file the home of the SALR parity and sampling results, with the numbers the vignette quoted (9,000 segments to five decimals, and the share of small watersheds moving by more than 5%) and `scripts/mad_parity.R SALR` as the producer.
- [ ] `research/discharge_publish.md`: record the value cross-checks and their results from the m4 report.
- [ ] `CLAUDE.md` (above the marker): rewrite the segment vignette paragraph (it no longer needs `mad_parity.R SALR` first; it reads the published manifest), and describe the publish BUILD's value checks.
- [ ] Update `NEWS.md` if the repo's practice is a line per user-visible change.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification
- m4 BUILD report: every value check has differing = 0, and parts identical to published reads 67 of 67.
- Data script on m1: the published check passes, and it fails when one bundled value is perturbed (restore the bug).
- Vignette renders. Its first screen names the product, the URL and how to load it, and it carries no recommendation prose beyond `pick`.
