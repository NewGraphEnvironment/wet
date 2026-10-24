# Task: Order wet_ws_fetch() rows so province runs reproduce to the bit (#76)

## Problem

`wet_ws_fetch()` (`R/wet_ws_fetch.R`) selects a basin's polygons with no `ORDER BY`, so they come back in PostgreSQL's physical order, which changes as the database is written to. `wet_upstream_sums()` adds polygons that share `(wscode, localcode)` with `rowsum()` in that order, so the floating-point sums depend on it.

Measured 2026-10-14 (#16), comparing the province run of 2026-09-28 (`962a9cc2c4`) with that of 2026-10-14 (`e675918817`) on the same FWA polygons, across 24 basins and 3,245,453 watersheds:
- 17 of the 24 basins came back in a different row order;
- the watershed sets, codes and NA patterns were identical;
- the worst relative difference in any numeric upstream mean was 6.6e-14 (basin 200, `tave_10`).

## Decided at the gate

Plan approved by the user 2026-10-23 (PDT) via /planning-init 76; the mechanism below is the agent's, stated at the gate for review.

Two layers, each for its own reason:
1. **Canonical order inside `wet_upstream_sums()`**: sort the valid rows by
   `(key, watershed_feature_id)` before the group `rowsum()`, and the irregular pairs by
   `(ia, id_up)` before theirs (`(ia, ib)` at the gate; corrected in Phase 2). The sums then no longer depend on any caller's row order
   (`mad_basin.R`, `mad_parity.R`, the province run), and the property is testable offline.
   Cost: one radix order per basin (3.2 M watersheds over the province; the Fraser 644,710).
2. **`ORDER BY` on a unique key in the fetches** (`wet_ws_fetch()`: `watershed_feature_id`;
   `wet_upstream_irregular()`: `a.watershed_feature_id, b.watershed_feature_id`;
   `wet_ws_geom()`: `watershed_feature_id`; `wet_upstream_pairs()`: `a.watershed_feature_id,
   uw.watershed_feature_id`), so the rows written to `sample/` and `upstream/` come out in one
   order and whole files compare with `identical()`.

No province run on this branch: it is m4's, and it lands with the next release run (owed below).

## Phase 1: Tests that fail on the current code
- [x] `test-wet_upstream_sums.R`: polygons sharing one `(W, L)` with values chosen so summation
      order changes the double (e.g. `1e16, 1, -1e16`); permuting `ws` rows gives `identical()`
      sums once matched on `watershed_feature_id`
- [x] same for `irregular_pairs`: permuting the pairs' rows gives `identical()` sums
- [x] `test-wet_ws_sample.R`: `method = "area"` on permuted polygons gives `identical()` values
      per id (pins that the sample stage is order-free; expected to pass already)
- [x] live test (`local_fwapg()`, skips without a database): on one small basin, sums from the
      fetch and from its rows reversed are `identical()`
- [x] run them against the current code and record which fail (restore-the-bug, in findings)

## Phase 2: Canonical order in wet_upstream_sums()
- [x] order valid rows by `(kb, watershed_feature_id)` (radix) before the group `rowsum()`;
      order irregular pairs by `(ia, id_up)` before theirs (corrected from `(ia, ib)`: `ib` is a position in `ws`, see findings)
- [x] roxygen: one sentence that the sums do not depend on row order; `devtools::document()`
- [x] Phase 1 tests pass; existing oracle tests pass

## Phase 3: ORDER BY in the fetches
- [x] `ORDER BY` on a unique key in `wet_ws_fetch()`, `wet_upstream_irregular()`,
      `wet_ws_geom()`, `wet_upstream_pairs()`; `@return` says rows come in id order
- [x] sweep `R/` and `scripts/` for other DB fetches whose rows are summed; add `ORDER BY` on a
      unique key where found, list each verdict in findings
- [x] live check on m1's fwapg: `wet_ws_fetch()` twice and a basin's sums twice `identical()`

## Phase 3b: Plan review and sweep fixes (added 2026-10-24)
- [x] `wet_upstream_sums()`: one copy (`vals[which(valid)[o], ]`); fixture guard with `Reduce()`
- [x] `wet_station_snap()`: `linear_feature_id` breaks exact ties; test
- [x] `ORDER BY` in `wb_province.R`'s boundary fetch, `mad_basin.R`, `mad_parity.R`; zone columns from sorted groups
- [x] `scripts/wb_upstream_order.R`: replay two runs' stored row orders through the current sums

## Phase 4: Docs
- [x] `scripts/wb_upstream_identity.R` header: runs made since #76 reproduce to the bit;
      a comparison with a run made before it still needs the tolerance (kept at 1e-10)
- [x] `CLAUDE.md` "A rerun agrees with the last only to rounding … (#76)": rewrite the same way
- [x] grep `research/` for the rounding sentence and revise where found
- [x] ~~`NEWS.md` line~~: left to `/gh-pr-merge`, whose release commit writes NEWS in this repo (the last four NEWS commits are all `Release vX`)

## Owed at the end (reported, done after merge)

- [ ] On m4: `Rscript scripts/wb_upstream_order.R data/wb/_pre16/962a9cc2c4 data/wb/e675918817`
      (the two stored orders that differed, through the new sums; must print "identical")
- [ ] The next province run on m4 (`scripts/wb_province.R 4`, new key) carries the change. It
      happens only inside a release chain: `wb_key_dir()` then sees only the new key, and
      `fit_20260717` lives under `e675918817`, so the fit is refit or carried over, then
      `wb_output.R`, `segment_output.R` and the vignette data (their `province_run` and
      `upstream/400.rds` md5) follow. Set `e675918817` aside, never delete it (tag
      `aet-15-record`'s recipe reads it)
- [ ] Until that run, `discharge_publish.R` refuses a build: `R/` changed since the segment
      report's commit. A republish needs the province run, `wb_output.R` and
      `segment_output.R` first (the chain the next release runs anyway)
- [ ] After that run, confirm the claim the docs now make as "should": a second run (or one
      basin accumulated again from the run's samples) `identical()` to it
- [ ] Issue body: edit to say what landed and that the run is pending

## Validation

- [ ] Tests pass (`devtools::test()`, with `NOT_CRAN=true` for any single-file rerun)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: the permutation tests fail on main and pass on the branch (shown by running them
on both); the live test pins the fetch order only; the evidence on real data is the Fraser and
Columbia shuffles and the replay script's two-way test (findings); `lintr` clean;
`pkgdown::check_pkgdown()` (no exports change, so a formality).

