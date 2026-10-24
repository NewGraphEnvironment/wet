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

## Errors Encountered

| Error | Resolution |
|-------|------------|
