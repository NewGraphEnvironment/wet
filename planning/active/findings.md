# Findings — Province-scale upstream accumulation without the order-8 skip (#2)

## Issue context

Needed by every build below. The #1 prototype (`wet_upstream_pairs()`) materialises every (watershed, upstream polygon) pair: 722 k pairs for SALR, a 4,587-polygon headwater group. That will not reach the Fraser mainstem. fwapg avoids the problem by skipping order ≥ 8 mainstems, which drops exactly the reaches a station check needs.

## Proposed

- Accumulate per watershed group, pre-aggregated at `wscode`/`localcode` (fwapg `extras/discharge/discharge.sh:48-56` suggests this), and carry group outflow totals downstream across group boundaries.
- Group boundaries cut mainstems (SALR has two LSAL polygons upstream of it), so a group's inflow set is not simply "whole upstream groups".
- Output: per fundamental watershed `sum(value·area·cover)`, `sum(area·cover)`, and the upstream area. Both denominators in `wet_upstream_mean()` can then be served from it.
- No order ≥ 8 skip.

## Done when

- The chain produces the SALR parity result unchanged (identical to fwapg after 5-decimal rounding).
- It runs on the whole Fraser, with runtime and memory reported.
- It matches fwapg on a non-headwater group, for example LSAL or BOWR plus its inflow.

Relates to #1.


## Exploration (plan mode, 2026-09-26)


**Scale.** `fwa_watersheds_poly` has 3.24 M polygons province-wide and 644,710 in the Fraser (`wscode <@ '100'`), which collapse to 593,916 distinct (wscode, localcode) positions.

### Code semantics.
- wscode is the stream the polygon drains to. localcode is either equal to it (the reach below the first tributary), or wscode plus the position label of the nearest downstream confluence.
- Labels are fixed width: 3 characters at the root, 6 below. Since `.` sorts before digits, **ltree order equals C-locale byte order of the dotted strings**. Subtree X is the key range `[X, X||'/')`.

**Join-free exact method.** For a watershed a = (W, L), and any upstream polygon b with a valid code (`Lb <@ Wb`), the `FWA_Upstream` set is at most two contiguous ranges of the (W, L)-sorted positions:
- W = L: the subtree of W, `[W, W/)`.
- W ≠ L:
  - R1: `wscode = W AND localcode >= L`, the tail of W's own rows;
  - R2: wscode in `[L||'/', W||'/')`, the tributaries above position L with their subtrees. This holds for any L, including the irregular localcodes on a.
- So: collapse polygons to positions with additive sums, sort in C order, take cumulative sums, find each range's ends by binary search (`findInterval`), and difference. This is O(N log N) with no pairs.

The exploration agent checked this on the live DB. For 15 Salmon polygons it matched `FWA_Upstream` and the stored `upstream_area_ha` exactly. In 300 random polygons there were 11 differences, all from **irregular upstream polygons b** (localcode not under their wscode: 204 in the Fraser, a few thousand province-wide), which `FWA_Upstream`'s localcode guards exclude. The fix:
- run the range method over valid b only;
- add each irregular b to the watersheds that `FWA_Upstream` actually counts it for, with a small targeted SQL join (`a.wscode_ltree @> b.wscode_ltree` uses the gist index; at most ~17 candidate streams per b).

**Independent check.** `whse_basemapping.fwa_watersheds_upstream_area` was built by the pairwise `FWA_Upstream` join over `ST_Area(geom)` (`fwapg/extras/lookups/sql/fwa_watersheds_upstream_area.sql`). So accumulated area must reproduce it for every Fraser polygon. This tests topology without any PCIC data.

**Other edge cases** (Fraser):
- 76 tributary wscodes whose parent has no polygons: handled, because ranges do not need parent rows.
- 134 localcodes deeper than wscode + 1: valid when under wscode.
- 309,794 polygons with W = L.

**Cross-group inflow is free.** Accumulating over a whole top-level basin (`100`, `200`, …) makes watershed-group boundaries irrelevant, including LSAL slivers upstream of SALR. The issue's "per group, carry totals across boundaries" is superseded.

### Scale of the rest of the chain.
- **PCIC.** A Fraser bbox is ~22 k cells × 10,957 days, about 0.5 GB per variable, too much to hold as one daily raster. Fetch and reduce per year, and cache each year.
- **Sampling.**
  - Centroid: from DB-computed lon/lat points, so no geometry transfer.
  - Area-weighted: needs geometry. Fetch it one watershed group at a time to bound memory.


## Phase 1 — Range sums (2026-09-26)

- `wet_upstream_sums()` works as follows: collapse valid polygons to (W, L) positions, radix-sort on `"W L"` keys, then compute range sums with a **segment tree**. It avoids differencing prefix sums: a Fraser-wide cumulative total is about 2.3e11 m², and differencing it would cost small headwaters their 5th decimal. Range ends are found with `wet_count_lt()`, a radix merge count that uses C byte order and so is locale-proof.
  - W = L: the subtree `[W, W/)`.
  - W ≠ L: R1 `[W L, W!)` ∪ R2 `[max(L/, W), W/)`, with the intersection subtracted. This covers irregular a whose L sorts before W, is an ancestor of W, or equals a tributary's code.
- **Oracle:** `fwa_upstream_r()` (test helper) is a brute-force transcription of `whse_basemapping.fwa_upstream(ltree×4)`. The generator's 40 random trees have 1,808 polygons, 71 of them irregular (producing 384 correction pairs), 75 deeper localcodes, 90 tributaries with no parent rows, and 842 W = L rows. All match exactly. Code-check round 1 fuzzed another 1,500 adversarial trees: 0 mismatches.

## Phase 2 — Basin fetch, irregular codes, area check (2026-09-26)

- **Fraser (`100`):** 644,710 polygons. Fetch 1.5 s; irregular pairs 1.2 s (204 irregular polygons, 676,496 pairs, because irregular polygons sit on mainstems); range sums 4.2 s; about 13 s end to end at a peak RSS of 2.1 GB.
- **fwapg's stored `fwa_watersheds_upstream_area` is a stale snapshot, not a reference.** Against it, 1,731 Fraser polygons mismatch (26,541 without the irregular correction). Re-checked against the **live `FWA_Upstream` join**: 401 of 401 (a sample plus the basin mouth) have wet equal to live within 3.6e-14, and stored equal to live in none.
  - The stored table also contradicts itself: 9633006 and 7949160 share a code pair, so they must have identical upstream sets, yet stored gives 50,837 m² vs 12,738,815 m².
  - At the Fraser mouth (7659748): wet = live = 232,150,864,900 m²; stored = 232,150,814,000 m².
  - The full re-check of all 1,731 is running (`data/checks/upstream_area_100.txt`).
- Consequence for parity: fwapg's `mad_m3s` was built with the stored table, so parity mode must divide by it. Live mode divides by accumulated area. In SALR the two agree everywhere (max relative change 5e-16).

## Phase 3 — Chain on range sums (2026-09-26)

- `wet_upstream_mean(ws, values, denom, irregular_pairs, upstream_area)` runs on range sums. `upstream_area` overrides the "total" denominator (fwapg parity), but **coverage always uses accumulated area**.
- `wet_pcic_annual()` fetches and reduces one year at a time. `wet_ws_sample()` accepts lon/lat points for centroid sampling. `wet_ws_geom()` returns geometry for one group.
- **SALR regression gate:** 100 % identical to fwapg after 5-decimal rounding. Range sums vs the old pairwise formula on 4,587 watersheds: max relative difference 2.6e-15. Sensitivity numbers unchanged.

### Code check (Phases 1–3)

| Round | Findings | Fixed | Inside previous fix? |
|---|---|---|---|
| 1 | 2 fragile: `irregular_pairs = NULL` silently dropped irregular polygons; the parity headwater guard used stored-area coverage | 2 | — |
| 2 | 3 fragile: the r1 warning checked only NULL (incomplete or duplicate pairs stayed silent); exported `wet_upstream_sums()` had the same drop; parity CSV coverage used stored area | 3 | **y** |
| 3 | enumeration: 1 bug (the `upstream_area` override leaked into `coverage`: on the Fraser, 1,155 watersheds above 1, max 251), 2 fragile (the pairs check is necessary, not sufficient, so the docs now say what it guarantees; the whole-basin requirement was undocumented) | 3 | n (same mechanism) |

- **Mechanism:** a table that crosses a function or DB boundary (pairs, the stored area table) was trusted to be complete, unduplicated and current.
- **The loop ended on round 3's enumeration** of every `match`/`merge`/`rowsum`/`tapply`/`%in%` and SQL join over such tables, plus all 5 uses of the stored table (see `review-round3.md`).
- **Checks now in place:**
  - NULL pairs with irregular polygons present warn.
  - Pairs missing an irregular id, or with duplicate rows, are an error.
  - Duplicate `upstream_area` ids are an error.
  - Coverage is always live.
