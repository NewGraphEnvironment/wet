## Outcome

Province runs on the same FWA polygons now give upstream means that are `identical()`, not equal only to rounding (two runs from scratch on 2026-10-24, below). `wet_upstream_sums()` adds the polygons that share `(wscode, localcode)`, and each watershed's irregular pairs, in `watershed_feature_id` order. Its sums therefore no longer depend on the row order of either input. Ordering the pairs by their position in `ws`, as first planned, would still have followed row order, so they are ordered by `id_up`. The fetches on the province path (`wet_ws_fetch()`, `wet_upstream_irregular()`, `wet_ws_geom()`, `wet_upstream_pairs()`, the BC boundary in `wb_province.R`) order on a primary key, so the run's files come out in one row order.

A sweep of 52 other database fetches found three more where fetch order reached a result: a tie in `wet_station_snap()`'s pick, and the first-segment pick and written row order in `mad_basin.R` and `mad_parity.R`. Code-check round 3 then showed that the snap tie the new tie-break was written for never reaches wet. fwapg's `fwa_indexpoint()` keeps one segment per stream by row order, and two calibration gauges sit on such a tie (NewGraphEnvironment/fwapg#39, drafted for upstream and not posted). `scripts/wb_upstream_order.R` replays two runs' stored row orders through the current sums. The change landed with province run `92b893c4da` and a refit of `fit_20260717` under it whose decisions all came out unchanged; the rebuilt product passes every check and was published on 2026-10-24. Two runs under the new code, made after the merge, were identical, so the docs no longer say "should".

## Measurement

- **Offline fixtures** (a `(W, L)` group of 1e16, 1, -1e16, which sums to 0 or 1 by order): main fails 2 of 5 `ws` permutations and 2 of 3 pair permutations; the branch passes all. A mutant ordering pairs by position fails the `ws[c(1, 2, 4, 3), ]` loop.
- **Live, on m1's fwapg** (`area_m2`, `area_m2 * lat`, `area_m2 * lon`, both tables shuffled, `set.seed(76)`):
  - Fraser: 644,710 polygons, 676,496 pairs. Main's sums move by up to 4.41e-16 relative; the branch's are `identical()`.
  - Columbia: 307,101 polygons, 38,649 pairs. Main's move by up to 3.83e-16; the branch's are identical.
- **`wb_upstream_order.R` on two scratch runs** (Fraser and basin 999, the second shuffled): branch "identical: 2 basins (2 stored in another order), 644770 watersheds"; main's sums stop on basin 100.
- **The real stored orders could not be replayed on m1.** Its runs are the reduced bundle (basin 100 keeps 94 of 644,710 watersheds), so that check was run on m4.
- **The real stored orders, replayed on m4** (2026-10-24, main at 212f184): `wb_upstream_order.R data/wb/_pre16/962a9cc2c4 data/wb/e675918817` printed "identical: 24 basins (17 stored in another order), 3245453 watersheds" in 80 s. The counts are #16's: the 17 basins whose rows came back in another order now sum to the same bits in both orders.
- **Two province runs under the new code, on m4** (2026-10-24, main at 212f184, `wb_province.R 4`, each about 15 min): the first in the main checkout, the second from scratch in a worktree of the same commit with its own `data/wb` and the same inputs. Both took key `92b893c4da`. Of 276 files, 275 are byte-identical; the other is `sample_times.txt` (wall-clock timings). All 270 rds (246 sample groups, 24 upstream basins, 3,245,453 watersheds) are `identical()`, and both rasters' values. So "should" is now measured: a rerun on the same FWA polygons and software gives the same upstream means to the bit.
- **The release chain under the new run, on m4** (2026-10-24, branch `76-province-run-chain`, `data/logs/76/chain.sh` and `chain_b.sh`): `e675918817` moved to `data/wb/_pre76/`, the shipped fit's decision files copied into `92b893c4da/fit_20260717/`, every AET variant rescored, compared and the winner refit. Every decision is identical (winner `cfu`, donor shares, the snow specification, the adjustment kept); every number is within 1.29e-12 relative of the fit under `e675918817` (`check_refit.R`, which matches the zone coefficients on zone, because the zone columns now come sorted). The balance output (42,190,889 rows) and the segment table (102,790,688 rows) keep their rows; at most 7.2e-11 relative (6.4e-12 absolute) of their values move. The tracked reports change only in their commit and province-run lines and in the order of the zone rows. The publish BUILD passes every check (0 values differing); 6 of 512 parts are byte-identical to the live build, and the routed parts differ too, only in the balance's `runoff_mm` they carry (part 920: 2,238 values, at most 9.1e-13). Uploaded the same day (Owed). Two stops, both in the chain's own check scripts: `check_refit.R` first compared the coefficients by row position, and `compare_parquet.R` tripped on row names after sorting.
- **The sample stage was already order-free**: each polygon's cells are summed alone.
- **#16's 6.6e-14** was larger than the 4e-16 seen here, probably from signed layers near zero (`tave_10`), not measured.
- **Snap ties:** 08EC013 sits 39.330232870264837 m from two segments of one stream, and 08KD006 67.563694090612884 m. Each pair is in different watersheds.

## Evidence

Measurements are in `findings.md` (Phase 1, Phase 3, sweep, plan review and round 3 tables). The probes were scratch scripts, not committed. The m4 logs are `data/logs/76/20261024T*` on m4: the replay (`T0641`), the two province runs (`T0735`, `T0751`) and the comparison (`T0807`, from `data/logs/76/run_compare.R`). The chain's logs are the other files in `data/logs/76/` on m4 (`chain*.log`, one log per step, `check_refit.R`, `compare_parquet.R`). Reviews: `review-plan.md`, `review-round1.md` to `review-round3.md`.

## Owed

- [x] On m4: `Rscript scripts/wb_upstream_order.R data/wb/_pre16/962a9cc2c4 data/wb/e675918817`
      (the two stored orders that differed, through the new sums; must print "identical").
      Done 2026-10-24: "identical: 24 basins (17 stored in another order), 3245453 watersheds"
- [x] The next province run on m4 (`scripts/wb_province.R 4`, new key) carries the change.
      Run 2026-10-24: key `92b893c4da`, beside `e675918817`, so `wb_key_dir()` on m4 now finds two
      complete runs. `e675918817` set aside at `data/wb/_pre76/` (never delete it: tag
      `aet-15-record`'s recipe reads it), the fit refit and the outputs rerun (Measurement)
- [x] `discharge_publish.R` BUILD under the new run: every check passes, 6 of 512 parts
      identical to the live build, not uploaded
- [x] The upload: 2026-10-24, 506 of 512 parts sent (about 40 min), all verify; live build b4bbc50.
      BUILD rerun after it (34f38a9): 512 of 512 identical to live. Logs `data/logs/76/20261024T2033*`, `T2114*`
- [x] Then the vignette data (`data-raw/segment_vignette_data.R`, `segment_vignette_map.R`,
      `monthly_vignette_data.R`) on m1, from a reduced bundle of `92b893c4da` cut to the same 335
      watersheds as the old one (m1's old bundle set aside at `data/wb/_pre76_m1/`). Every value is
      equal to the old bundles' within 1e-9; only provenance differs. The rendered articles' text
      differs only in the build commit and the date read. Logs `data/logs/76/20261025T*` on m1
- [x] After that run, confirm the claim the docs now make as "should": a second run (or one
      basin accumulated again from the run's samples) `identical()` to it. Done 2026-10-24: a
      second run from scratch, 270 of 270 rds `identical()`
- [x] Issue body: edit to say what landed and that the run is pending
- [ ] NewGraphEnvironment/fwapg#39: fix on the fork (end both orderings on `linear_feature_id`); post the draft upstream only on the user's word

Closed by: PR #115 (relates to #76, left open for the owed runs)
