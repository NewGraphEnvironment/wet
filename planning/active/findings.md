# Findings — Order wet_ws_fetch() rows so province runs reproduce to the bit (#76)

## Issue context

**If we do it:** a province run (`scripts/wb_province.R`) gives the same upstream means to the bit whenever the database holds the same FWA polygons, so a rerun can be checked with `identical()`. **If we never do:** reruns agree only to rounding (a relative 6.6e-14 at worst, measured below), and every comparison of two runs needs a tolerance.

## Problem

`wet_ws_fetch()` (`R/wet_ws_fetch.R`) selects a basin's polygons with no `ORDER BY`, so they come back in PostgreSQL's physical order, which changes as the database is written to. `wet_upstream_sums()` adds polygons that share `(wscode, localcode)` with `rowsum()` in that order, so the floating-point sums depend on it.

Measured 2026-10-14 (#16), comparing the province run of 2026-09-28 (`962a9cc2c4`) with that of 2026-10-14 (`e675918817`) on the same FWA polygons, across 24 basins and 3,245,453 watersheds:
- 17 of the 24 basins came back in a different row order;
- the watershed sets, codes and NA patterns were identical;
- the worst relative difference in any numeric upstream mean was 6.6e-14 (basin 200, `tave_10`).

## Proposed

Add `ORDER BY watershed_feature_id` to the query (and to any other fetch whose rows are summed). It changes `R/wet_ws_fetch.R`, which `scripts/wb_province.R` hashes into its run key, so it lands with the next province run rather than on its own.

Relates to #16.


**Same class elsewhere (2026-10-18):** `scripts/segment_output.R` took the published routed month 0 (the mean of twelve months) in the routed table's storage order. #101 now reads those rows `ORDER BY linear_feature_id, month`, and #103's republish carries the change. In link the class is NewGraphEnvironment/link#356.


## Exploration (plan mode)

`wet_ws_fetch()` returns a basin's polygons in PostgreSQL's physical order, and
`wet_upstream_sums()` adds polygons that share `(wscode, localcode)` with `rowsum()` in input
order, so two province runs on the same FWA polygons agree only to rounding (6.6e-14 relative
at worst, #16). Exploration found two more places where order reaches the sums or the files:

- `R/wet_upstream_sums.R`: `rowsum(vals[valid, ], match(kb, uk))` sums each `(W, L)` group in
  row order; `rowsum(vals[ib[keep], ], ia[keep])` sums the irregular pairs in the pairs'
  row order. The segment tree itself is built on sorted keys and is order-free.
- `wet_upstream_irregular()` (`R/wet_ws_fetch.R`) also has no `ORDER BY`, and its rows feed the
  second `rowsum()`.
- `wet_ws_geom()` has no `ORDER BY`: it does not change the per-polygon sample values
  (`terra::extract()` per polygon, `rowsum()` over cells by ID), but it sets the row order of
  `data/wb/<key>/sample/<WSG>.rds`, so those files are not `identical()` across runs either.
- Downstream scripts find the run with `wb_key_dir()` (the one complete run), not by
  recomputing the key, so merging the change breaks nothing: the next `wb_province.R` run
  computes a new key (it hashes `R/wet_ws_fetch.R` and `R/wet_upstream_sums.R`) and the old run
  is set aside then, as with `_pre16`. `wb_term_diagnose.R`'s `pcic_key` hashes both files too,
  so its PCIC cache rebuilds on its next run.

## Phase 1: the tests against the code on main (2026-10-23)

`NOT_CRAN=true`, `testthat::test_file()` after `load_all()`, at c681044:

| test | on main |
|---|---|
| sums do not depend on the row order of ws | 2 of 5 permutations fail: the (W, L) group 1e16, 1, -1e16 sums to 1 instead of 0 when the 1 is added last |
| sums do not depend on the row order of irregular_pairs | 2 of 3 permutations fail the same way (the mouth's three irregular pairs) |
| a basin from fwapg sums the same in any row order (basin 925, 1,049 polygons) | fails on `wet_ws_fetch()` returning rows out of id order. With that unordered fetch, the shuffled 925 summed identically on main; with the ordered fetch (round 1 of code-check, reproduced 2026-10-24), main's sums fail at `test-wet_upstream_sums.R:173`. So whether the live test reaches the defect depends on the starting order; the offline tests reach it every time |
| area means per polygon do not depend on the polygons' order (`wet_ws_sample()`) | passes: each polygon's cells are summed alone, so the sample stage was already order-free; only its file row order follows the fetch |

A first draft of the pairs fixture passed on main: reversing the pairs gave the order -1e16, 1, 1e16, which also sums to 0. The permutation must put the 1 last (2, 4, 3); the test now asserts the pairs' order before permuting.

## Phase 2: the pairs' order is by id, not by position (2026-10-23)

The plan said to order the irregular pairs by `(ia, ib)`. `ib` is the upstream polygon's row in `ws`, so that order still follows `ws`'s row order. They are ordered by `(ia, id_up)` instead (grouping by `ia` is fine: it only says which watershed a pair adds to). The pairs test gained a `ws` permutation, `c(1, 2, 4, 3)`, that puts the mouth's pairs in position order 2, 4, 3. A mutant copy of `R/wet_upstream_sums.R` with `order(ia[keep], ib[keep])`, loaded into the namespace from the scratchpad, fails that loop (`test-wet_upstream_sums.R:151`); the committed code passes it.

## Phase 3: live check on m1's fwapg (2026-10-24 UTC)

Scratchpad script `live_check.R`: each basin fetched twice (`wet_ws_fetch()`, `wet_upstream_irregular()`), then `area_m2`, `area_m2 * lat` and `area_m2 * lon` summed upstream in fetch order and with both tables shuffled (`set.seed(76)`), under main's `R/wet_upstream_sums.R` and the branch's.

| basin | polygons | irregular pairs | fetches identical | main, shuffled | branch, shuffled | time |
|---|---|---|---|---|---|---|
| 100 (Fraser) | 644,710 | 676,496 | yes | differs, 4.41e-16 relative at worst | identical | 48 s |
| 300 (Columbia) | 307,101 | 38,649 | yes | differs, 3.83e-16 | identical | 18 s |

The shuffled differences are smaller than #16's 6.6e-14 because those were upstream *means*, a ratio of two sums each carrying the error, over every layer and all 24 basins.

## Fetch sweep: verdicts (2026-10-24 UTC)

An Explore agent classified the 52 fetch sites the detector listed (one, `R/wet_segment_monthly.R:301`, has `ORDER BY 1, 2` after all). Each flagged site was read before acting:

| site | verdict | action |
|---|---|---|
| `scripts/wb_province.R:72` (`fwa_bcboundary`, ~28,000 pieces dissolved into `in_bc.tif`) | the dissolve's last bits can follow input order, and `in_bc` reaches every upstream file as `bc_fraction` | `ORDER BY bcboundary_id` (its primary key) |
| `scripts/mad_basin.R:94` | `tapply(seg$mad_mm, seg$watershed_feature_id, `[`, 1)` keeps the first segment's fwapg value, which drives the flip search and cause attribution; the parquet at :283 is written in fetch order | `ORDER BY s.linear_feature_id` |
| `scripts/mad_parity.R:112` | `merge()` keeps fetch order among a watershed's segments into the written csv | `ORDER BY s.linear_feature_id` |
| `R/wet_station_snap.R:126-127` | `order(station, score, distance)` then `!duplicated()`: an exact tie (two segments meeting at the nearest node, one watershed) falls to fetch order | `linear_feature_id` as last sort key; test |
| `R/wet_station_daily.R:179` (duckdb over the provisional archive) | safe only if the archive never repeats a station and day; not checked | left: outside #76, reported |
| every other site | safe: single row, joined or compared on a unique key, sorted before use, counts or set membership, or SQLite on a fixed file | none |

## Plan review: verdicts (2026-10-24 UTC)

Review in `review-plan.md`. Each claim checked before acting:

| finding | verdict | action |
|---|---|---|
| B1 identity script cannot run the owed check | **confirmed** (:51, :75 are #16-specific; :90 is #16's tracked report) | not generalised: it stays #16's record. The owed check is now the new `scripts/wb_upstream_order.R` (replays two runs' stored orders) and, after the next run, `identical()` of a rerun's files |
| B2 `(ia, ib)` in the plan | already corrected in Phase 2 | none |
| G1 `sum()` may use long double | **confirmed** by reading (m1 has none, so it passed here) | fixture guard uses `Reduce(`+`, …)` |
| G2 double copy; "3.2 M per basin" | **confirmed** | `vals[which(valid)[o], ]`; plan text fixed (province total; Fraser 644,710) |
| G3 snap tie, mad_parity csv | **confirmed** | see sweep table |
| G4 stale wording | `wb_share_snow.R:18-19, :143`, identity :86 and research :519 describe #16's pre-#76 runs and stay true as written; research :285 revised (snap) | :285 only |
| S1 re-keying cascades | **confirmed** (`wb_key_dir()` sees one complete run; `fit_20260717` lives under `e675918817`) | owed list says the run happens only inside a release chain |
| A1 same software | **confirmed** | CLAUDE.md, identity header, research say "same software" |
| A2 the 6.6e-14 vs 4e-16 explanation | plausible; not measured | Phase 3 note revised below |
| AC1 replay basin 200 on m1 | **not possible on m1**: its runs are the reduced bundle (basin 100 stores 94 of 644,710 watersheds, 925 none) | `scripts/wb_upstream_order.R`; owed on m4. Tested on two scratch runs built from m1's fwapg (basins 100 and 999, the second shuffled): branch "identical: 2 basins (2 stored in another order), 644770 watersheds"; a scratch copy on main's sums stops "100: the sums differ" |
| AC2/AC3 | agreed: the 925 test pins only the `ORDER BY`, fetching twice in one state is trivial | Verification wording revised; `live_check.R` and the replay stay recorded here |
| `wb_province.R:256` column order | **confirmed** | `need <- sort(unique(...))` |
| `wb_cv_lib.R:37` same pattern | real, but `wb_cv_lib.R` is hashed into the fit scores (`wb_score_md5.R:14`), so changing it stales the shipped fit | left, reported |

Note on Phase 3's live check: its columns all have one sign, so it cannot show cancellation; #16's larger 6.6e-14 was probably signed layers near zero (`tave_10` in October), not the means being ratios. The replay script adds a signed column for that reason.

## Code-check round 3: the snap tie never reaches wet (2026-10-24 UTC)

Round 3 (`review-round3.md`) found a defect inside the plan-review fix: the `linear_feature_id` tie-break in `wet_snap_pick()` cannot see the tie its comment named. fwapg's `fwa_indexpoint()` keeps one segment per stream with `DISTINCT ON (blue_line_key) ... ORDER BY blue_line_key, distance_to_stream` (fork `db/schema.sql:2409`, `:2442` at ae8f7c7), so of two segments of one stream at the same distance, the plan's first row is the only one returned. Reproduced on m1's fwapg:

| gauge | segments (one stream) | distance, m | watersheds | shipped snap |
|---|---|---|---|---|
| 08EC013 | 5086038, 5086970 | 39.330232870264837 both | 7660731, 7660693 | 5086970 |
| 08KD006 | 703862843, 703862887 | 67.563694090612884 both | 8483126, 7713002 | 703862843 |

The defect is fwapg's: filed on our fork as NewGraphEnvironment/fwapg#39 (`upstream-draft`, with a draft for upstream, not posted). wet's tie-break stays for ties between candidates it does receive (other streams); its comment and research `water_balance_method.md` (stations rebuild) were narrowed to say so.

**Enumeration that ends the loop.** The mechanism behind rounds 2 and 3: assuming the rows a function receives are the whole candidate set, when something upstream of it already chose among them by row order (round 2: two runs' codes and areas; round 3: fwapg's own pick). In this diff it can reach wet only through SQL functions that pick rows. Every fwapg function wet's SQL calls (`git grep` over `R/`, `scripts/`, `data-raw/`), with its definition read from m1's fwapg:

| function | calls | picks rows? | verdict |
|---|---|---|---|
| `fwa_upstream` | 7 | no (`DISTINCT ON`, `LIMIT`, `ORDER BY` absent) | order-free |
| `fwa_indexpoint` | 4 (`wet_station_snap.R`, `wb_gauge_diversion.R`, `vignette_map_lib.R`, `mad_basin.R`) | yes | fwapg#39 |
| `fwa_watershedatmeasure` | 1 (`vignette_map_lib.R`, map layers only) | yes (`LIMIT 1` picks, ordered on measures and area; ties not measured) | fwapg's; cartography only |

Every wet-side `ORDER BY` in the diff ends on a primary key (rounds 1-3), and every in-R pick on the province path is ordered (round 3 mutated each ordering line alone; each turns a test red).

## Errors Encountered

| Error | Resolution |
|-------|------------|
| replay of the two stored runs on m1: `irregular_pairs$id_up must be irregular polygons in ws` | m1's runs are the reduced bundle; replay moved to a script for m4 |
