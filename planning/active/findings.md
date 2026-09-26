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

