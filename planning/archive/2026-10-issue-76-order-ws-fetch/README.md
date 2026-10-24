## Outcome

Province runs on the same FWA polygons should now give upstream means that are `identical()`, not equal only to rounding. `wet_upstream_sums()` adds the polygons that share `(wscode, localcode)`, and each watershed's irregular pairs, in `watershed_feature_id` order. Its sums therefore no longer depend on the row order of either input. Ordering the pairs by their position in `ws`, as first planned, would still have followed row order, so they are ordered by `id_up`. The fetches on the province path (`wet_ws_fetch()`, `wet_upstream_irregular()`, `wet_ws_geom()`, `wet_upstream_pairs()`, the BC boundary in `wb_province.R`) order on a primary key, so the run's files come out in one row order.

A sweep of 52 other database fetches found three more where fetch order reached a result: a tie in `wet_station_snap()`'s pick, and the first-segment pick and written row order in `mad_basin.R` and `mad_parity.R`. Code-check round 3 then showed that the snap tie the new tie-break was written for never reaches wet. fwapg's `fwa_indexpoint()` keeps one segment per stream by row order, and two calibration gauges sit on such a tie (NewGraphEnvironment/fwapg#39, drafted for upstream and not posted). `scripts/wb_upstream_order.R` replays two runs' stored row orders through the current sums. The change lands with the next province run, which belongs to a release chain. No two runs under the new code exist yet, so the docs say "should".

## Measurement

- **Offline fixtures** (a `(W, L)` group of 1e16, 1, -1e16, which sums to 0 or 1 by order): main fails 2 of 5 `ws` permutations and 2 of 3 pair permutations; the branch passes all. A mutant ordering pairs by position fails the `ws[c(1, 2, 4, 3), ]` loop.
- **Live, on m1's fwapg** (`area_m2`, `area_m2 * lat`, `area_m2 * lon`, both tables shuffled, `set.seed(76)`):
  - Fraser: 644,710 polygons, 676,496 pairs. Main's sums move by up to 4.41e-16 relative; the branch's are `identical()`.
  - Columbia: 307,101 polygons, 38,649 pairs. Main's move by up to 3.83e-16; the branch's are identical.
- **`wb_upstream_order.R` on two scratch runs** (Fraser and basin 999, the second shuffled): branch "identical: 2 basins (2 stored in another order), 644770 watersheds"; main's sums stop on basin 100.
- **The real stored orders could not be replayed on m1.** Its runs are the reduced bundle (basin 100 keeps 94 of 644,710 watersheds), so that check is owed on m4.
- **The sample stage was already order-free**: each polygon's cells are summed alone.
- **#16's 6.6e-14** was larger than the 4e-16 seen here, probably from signed layers near zero (`tave_10`), not measured.
- **Snap ties:** 08EC013 sits 39.330232870264837 m from two segments of one stream, and 08KD006 67.563694090612884 m. Each pair is in different watersheds.

## Evidence

Measurements are in `findings.md` (Phase 1, Phase 3, sweep, plan review and round 3 tables). The probes were scratch scripts, not committed. Reviews: `review-plan.md`, `review-round1.md` to `review-round3.md`.

## Owed

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
- [x] Issue body: edit to say what landed and that the run is pending
- [ ] NewGraphEnvironment/fwapg#39: fix on the fork (end both orderings on `linear_feature_id`); post the draft upstream only on the user's word

Closed by: PR (see `progress.md`)
