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
   `(ia, ib)` before theirs. The sums then no longer depend on any caller's row order
   (`mad_basin.R`, `mad_parity.R`, the province run), and the property is testable offline.
   Cost: one radix order over ~3.2 M rows per basin.
2. **`ORDER BY` on a unique key in the fetches** (`wet_ws_fetch()`: `watershed_feature_id`;
   `wet_upstream_irregular()`: `a.watershed_feature_id, b.watershed_feature_id`;
   `wet_ws_geom()`: `watershed_feature_id`; `wet_upstream_pairs()`: `a.watershed_feature_id,
   uw.watershed_feature_id`), so the rows written to `sample/` and `upstream/` come out in one
   order and whole files compare with `identical()`.

No province run on this branch: it is m4's, and it lands with the next release run (owed below).

## Phase 1: Tests that fail on the current code
- [ ] `test-wet_upstream_sums.R`: polygons sharing one `(W, L)` with values chosen so summation
      order changes the double (e.g. `1e16, 1, -1e16`); permuting `ws` rows gives `identical()`
      sums once matched on `watershed_feature_id`
- [ ] same for `irregular_pairs`: permuting the pairs' rows gives `identical()` sums
- [ ] `test-wet_ws_sample.R`: `method = "area"` on permuted polygons gives `identical()` values
      per id (pins that the sample stage is order-free; expected to pass already)
- [ ] live test (`local_fwapg()`, skips without a database): on one small basin, sums from the
      fetch and from its rows reversed are `identical()`
- [ ] run them against the current code and record which fail (restore-the-bug, in findings)

## Phase 2: Canonical order in wet_upstream_sums()
- [ ] order valid rows by `(kb, watershed_feature_id)` (radix) before the group `rowsum()`;
      order irregular pairs by `(ia, ib)` before theirs
- [ ] roxygen: one sentence that the sums do not depend on row order; `devtools::document()`
- [ ] Phase 1 tests pass; existing oracle tests pass

## Phase 3: ORDER BY in the fetches
- [ ] `ORDER BY` on a unique key in `wet_ws_fetch()`, `wet_upstream_irregular()`,
      `wet_ws_geom()`, `wet_upstream_pairs()`; `@return` says rows come in id order
- [ ] sweep `R/` and `scripts/` for other DB fetches whose rows are summed; add `ORDER BY` on a
      unique key where found, list each verdict in findings
- [ ] live check on m1's fwapg: `wet_ws_fetch()` twice and a basin's sums twice `identical()`

## Phase 4: Docs
- [ ] `scripts/wb_upstream_identity.R` header: runs made since #76 reproduce to the bit;
      a comparison with a run made before it still needs the tolerance (kept at 1e-10)
- [ ] `CLAUDE.md` "A rerun agrees with the last only to rounding … (#76)": rewrite the same way
- [ ] grep `research/` for the rounding sentence and revise where found
- [ ] `NEWS.md` line

## Owed at the end (reported, done after merge)

- [ ] The next province run on m4 (`scripts/wb_province.R 4`, new key) carries the change; set
      the current run aside first, and run `wb_upstream_identity.R` against it (to rounding,
      since the old run was summed in the old order)
- [ ] Issue body: edit to say what landed and that the run is pending

## Validation

- [ ] Tests pass (`devtools::test()`, with `NOT_CRAN=true` for any single-file rerun)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: the permutation tests fail on main and pass on the branch (shown by running them
on both); the live test reruns a real basin's fetch and sums with `identical()`; `lintr` clean;
`pkgdown::check_pkgdown()` (no exports change, so a formality).

