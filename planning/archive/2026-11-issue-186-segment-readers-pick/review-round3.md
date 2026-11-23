## Checklist read

Mechanisms: guard that fails toward pass; fixture that cannot reach the failure mode; verification that reads its own output; zero-length/empty/unset. code-check-r.md: database driver values are not base R types; `match()` NA; `paste()`/`data.frame()`/`rbind` of zero-length; `bind_rows` of empty; `$` partial matching.

Probed: zero ids (early return with zero-row logical `pick`), zero rows from Postgres or duckdb (`match()` on empty key gives NA, `as.logical(logical(0)[NA idx])` is NA logical), a source whose groups hold no part (typed zero-row frame including logical `pick`, rbind with non-empty frames keeps logical), duckdb BOOLEAN and RPostgres boolean both arrive as logical (and `as.logical()` is applied regardless), fwapg `rep(NA, n)` logical (and `rep(NA, 0)` after `rbind` of empty frames is still logical), `key()` is built from source/segment/time only so the extra column does not affect the duplicate check, `match()` takes `pick` through the same index as `q_m3s` so the row is the right one, `dbListFields(conn, DBI::Id(schema, table))` (worked under RPostgres; the drop-column test reaches it), pick_only loads (picked rows TRUE, others NA by design, a test asserts it), the daily reader (same function, tests extended), consumers (`wet_flow_window` selects `by`/`q_m3s` only; `routed_annual` selects columns; `identical(recipe, mine)` in monthly_vignette_data.R now has the same five names in the same order, both logical, `rownames` reset on both; `segments` carries `pick` from `pub_bulk`; segment_vignette_data.R's `by_id` selects three columns so is unaffected).

Ran `NOT_CRAN=true devtools::test(filter = "wet_segment")` in a /tmp copy of HEAD against localhost Postgres: FAIL 0, WARN 0, SKIP 0, PASS 103 (no skips, so the Postgres tests did run).

Vacuity: the pick assertions compare with `expect_identical` against fixture values and add explicit TRUE/FALSE expectations per (source, segment) so a column of all NA or all TRUE would fail; the missing-column test drops the column and expects the named error.

## Clean

No real issues found in the readers or their consumers.
