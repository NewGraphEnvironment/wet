# Code-check round 2 (#76), branch diff against 47ed65e

## Checklist read

- `code-check.md` (37 H3): I read the prose of all 14 H3s under `## Mechanisms`, without their
  table rows. I did not read the other 23 (Rules that stand alone, Security, Spreadsheets and
  PDFs) beyond their index lines. None of them touches this diff.
- `code-check-r.md` (111 H3): I read 20 in full. They are: `on.exit()` at a script's top level;
  testthat counts an uncaught error under `error`; `skip_if_not()` skips only its own block;
  `paste()` with a zero-length argument; `identical()` on two reader results (including the
  part on subsets dropping attributes); tests under `R CMD check` run against the installed
  package; `sort()`/`order()` collate by `LC_COLLATE`; `identical(-0, 0)`; `match()` treats
  NA as a value; `expect_false(identical())`; testthat `tolerance` is relative; `data.frame()`
  recycling against zero length; `Rscript -e` and `--args`; Postgres row order; `sprintf("%g")`
  into SQL; `information_schema` lookups; Rscript reads a script as it runs; range totals as
  differences of running totals; a `pkg::` call in a test; a database driver's value is not a
  base R type (integer64). I did not read the other 91 beyond their index lines.
- `code-check-shell.md` (67 H3): I read none in full. The diff has no shell code, and every
  index line was checked against it.
- `code-check-spatial.md` (93 H3): I read 2 in full, the terra `extract()` one and the
  `terra::project()` one (only a CRS given, so the grid and datum step move between versions).
  I did not read the other 91 beyond their index lines.

## What I checked beyond round 1

- **Edge cases of the reordering.** I ran the branch's and 47ed65e's `wet_upstream_sums.R` in
  a scratch copy (`<scratchpad>/r2/edge.R`):
  - Zero rows: both versions return the same 0-row frame.
  - An all-irregular basin (no valid rows, every pair given): both run, and the result is the
    same under a permutation of `ws` and of the pairs.
  - Double ids: order-independent.
  - `bit64::integer64` ids: radix `order()` sorts positive ids correctly. It misorders negative
    ones, but FWA ids are positive `int4`, which arrive as R integer.
  - No irregular pairs: `keep` comes out as `integer(0)`, so the branch is skipped.
- **Unique keys behind each new `ORDER BY`.** I checked against m1's fwapg: `fwa_bcboundary`,
  `fwa_watersheds_poly`, `fwa_stream_networks_sp`, `fwa_streams_watersheds_lut` and
  `fwa_stream_networks_discharge` each have a primary key on the ordered column. The
  pair-fetch orders (a, b) are unique per pair.
- **`rowsum()`.** It adds rows in the order given, in plain double. Groups are keyed on
  `match(kb[o], uk)` and on `ia`. Neither key depends on the input order, so the doubles do
  not either.
- **The two runs `scripts/wb_upstream_order.R` would read on m1.** Both
  `_pre16/962a9cc2c4` and `e675918817` are reduced bundles. In 4 of 24 basins they store
  different row orders, and `wscode`, `localcode` and `area_m2` are identical per id in all 24.
  On these bundles the script stops loudly at the irregular-pairs check, as its header says
  it would (it needs whole basins).
- **Docs against the code.** The CLAUDE.md, `research/water_balance_method.md`,
  `wb_upstream_identity.R` header and roxygen claims all match the code. The Fraser and
  Columbia shuffle claim is backed by `findings.md`.
- **`sort(need)` in `wb_province.R`.** It changes the order of the zone columns in the
  upstream rds. `wb_cv_lib.R:68`'s `max.col(ties.method = "first")` reads that order, which is
  the accepted tradeoff, and it lands with the next run.

## Findings

- **[severity: fragile]** `scripts/wb_upstream_order.R:364-375`: the script checks only that
  the two runs hold the same set of `watershed_feature_id`. It sums each run's own `wscode`,
  `localcode` and `area_m2`, so any per-id difference in those values between the runs makes
  it stop with "the sums differ between the two runs' row orders". That message blames row
  order for a difference in the inputs. The script exists to tell order from everything else,
  so it should not mix the two. Two fixes would make the replay vary the order alone:
  - require `identical()` `wscode`, `localcode` and `area_m2` after matching on id, with its
    own message;
  - or take run 1's rows in run 2's stored order (`b <- a[match(b$watershed_feature_id,
    a$watershed_feature_id), ]`).

  On m1's two reduced bundles the values are identical per id, so this would not fire there.
  On m4's full runs it is unmeasured.

Nothing else found. The R/ changes, the tests, the other scripts' `ORDER BY`s and the doc
claims are clean.
