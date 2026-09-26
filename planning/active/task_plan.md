# Task: Province-scale upstream accumulation without the order-8 skip (#2)

Needed by every build below. The #1 prototype (`wet_upstream_pairs()`) materialises every (watershed, upstream polygon) pair: 722 k pairs for SALR, a 4,587-polygon headwater group. That will not reach the Fraser mainstem. fwapg avoids the problem by skipping order ≥ 8 mainstems, which drops exactly the reaches a station check needs.

## Phase 1 — Range-sum core (pure R, oracle-tested)
- [x] `wet_upstream_sums(ws, cols)`:
  - Input: `data.frame(watershed_feature_id, wscode, localcode, <additive cols>)`.
  - Mark valid rows (`localcode` equal to or under `wscode`) and collapse valid rows to positions.
  - Sort with `method = "radix"`, which is C-locale and independent of the session locale.
  - Take cumulative sums; resolve R1/R2/subtree ranges with `findInterval`.
  - Return upstream sums per `watershed_feature_id`, with the irregular ids as an attribute.
- [x] Test helper `fwa_upstream_r()`: a brute-force R transcription of `whse_basemapping.fwa_upstream(ltree×4)`, used only as the test oracle.
- [x] Tests against brute force, exact equality:
  - a hand-built SALR-shaped tree;
  - randomised trees with duplicate positions, W = L rows, deeper localcodes, tributaries whose parent has no rows, and irregular b (excluded from ranges and reported).
  - Also check that the sort is locale-proof.

## Phase 2 — Basin fetch and irregular-code correction (fwapg)
- [x] `wet_ws_fetch(conn, wscode)`: all polygons in a basin (`wscode_ltree <@ $1`) with `watershed_group_code`, codes as text, `ST_Area(geom)`, and centroid lon/lat (`ST_Transform(ST_Centroid(geom), 4326)`, as fwapg does).
- [x] `wet_upstream_irregular(conn, wscode)`: (a, b) pairs from `FWA_Upstream` for irregular b in the basin. Merge them into the sums in R so the result equals `FWA_Upstream` exactly.
- [x] `scripts/upstream_area_check.R`: accumulated area vs `fwa_watersheds_upstream_area` for all 644,710 Fraser polygons (relative tolerance 1e-9). Report mismatches, runtime and peak memory.

## Phase 3 — Wire into the chain
- [x] `wet_upstream_mean()` takes accumulated sums (`sum(value·area·cover)`, `sum(area·cover)`, upstream area) instead of pairs, with the same `total`/`covered` semantics and NA rules (#1 code-check). Update its tests.
- [x] Keep `wet_upstream_pairs()` as the documented slow oracle for spot checks.
- [x] `wet_pcic_annual(variable, bbox, years, run)`: fetch and reduce one year at a time via `wet_pcic_fetch()`, then take the mean over years. The result must equal `wet_runoff_annual()` on the SALR subset.
- [x] `wet_ws_sample()` at scale: centroid from `wet_ws_fetch()` points; area-weighted over geometry fetched per watershed group.
- [x] `scripts/mad_parity.R` on the new path. **SALR stays identical to fwapg after 5-decimal rounding** (regression gate).

## Phase 4 — Whole Fraser
- [x] `scripts/mad_basin.R 100`: fetch PCIC 1981–2010 for the Fraser, sample (centroid and area), accumulate, and join to segments.
- [x] Record runtime and peak memory (`/usr/bin/time -l`).
- [x] Parity vs `fwa_stream_networks_discharge` on every Fraser segment where fwapg has a value, identical after rounding. Break it down by watershed group, and name LSAL and BOWR explicitly as non-headwater cases.
- [x] Report the order ≥ 8 mainstem segments fwapg lacks. Sanity-check Fraser at Hope against HYDAT 08MF005's 1981–2010 mean (reported, not gated; station validation is #6).
- [x] Update `research/fwapg_mad_method.md` with the range method, the area check and the Fraser parity/sensitivity. Update the CLAUDE.md architecture line.

## Phase 5 — Close out
- [ ] Comment the result on #2, and note in #3/#4/#6 that basin-scale accumulation is available.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
