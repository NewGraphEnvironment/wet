# One watershed group's balance, rebuilt alone

**Verified:** 2026-11-04 · **Issues:** #157 (spawned #158) · **Produced by:** `scripts/segment_group_closure.R` → `data/checks/segment_group_closure.txt` (fwapg on the development machine); `scripts/segment_group.R BULK` and `SALR` with `WET_WB_RESAMPLE=1` → `data/checks/segment_group_{BULK,SALR}_20260717.txt`, run on the machine holding province run `92b893c4da`, against live build b4bbc50; run logs `data/logs/157/segment_group_*` on the machine that ran each · **Status:** measured; the build ships as a script, and publishing the fit is a follow-up

## The answer

A per-group build is worth having for the 112 of the province's 246 groups whose closure is the group alone or two or three groups, and its smallest shape needs no published fit to be useful where the province run's inputs are. One group's balance rows and pick come back in about 20 seconds, against about 11 minutes for the province's sampling and accumulation. Rebuilt that way, SALR equals the published product in every watershed and segment row. BULK equals it except at 11 watersheds that sit at calibration gauges, where the donor shares' exact-zero test turns on the last bits of the upstream means (#158).

## What a group needs

FWA's `FWA_Upstream(a, b)` counts `b` upstream of `a` only when `b`'s watershed code lies under `a`'s. So the polygons a group's rows need are every polygon under the group's roots, its distinct watershed codes with no ancestor among them (`wet_ws_roots()`, `wet_ws_closure()`). That set is closed upstream, and `wet_upstream_sums()` gives its rows the basin's sums up to the order the doubles are added in. A pure-R test checks this against the brute-force `FWA_Upstream` oracle on 40 random trees with irregular codes, and a live test checks it in basin 925.

How many groups a group's closure spans, over the province's 246 groups:

| groups spanned, itself included | groups |
|---|---|
| 1 | 53 |
| 2–3 | 59 |
| 4–10 | 62 |
| more than 10 | 72 |

| polygons in the closure | groups |
|---|---|
| up to 50,000 | 146 |
| 50,000–200,000 | 52 |
| over 200,000 | 48 |

Each of the 48 largest has among its roots the main-stem code of the Fraser (13 groups), the Columbia (7), the Peace (5), the Liard (5) or the Stikine (4), or the code of coastal drainage 910 (14), counting each group by the root that holds the most polygons. A closure holds each root's whole subtree, so these groups need all of that river or drainage. 72 groups' closures include a whole top-level drainage. A group on a tributary needs the groups upstream of it: BULK needs MORR (35,191 polygons), SALR needs LSAL and MUSK (12,481), and LNRS, on the Nechako, needs 18 others (116,474). 54 groups lie under more than one top-level drainage code, so their published rows sit in several parts.

## How long it takes

On the machine with the province run's `layers.tif`, BULK takes 9 s to sample, 2 s to accumulate and 1 s to apply the fit, with 3 s to read its published rows. SALR takes 2 s, under a second and well under a second, with 2 s for the read. Where the province run's sample of a group exists the build reads it, and it samples only a group that has none. BULK and SALR resampled under today's terra and GDAL are `identical()` to the province run's samples.

## Parity with the published product

The group's upstream means differ from the province run's by at most 1.4e-12 relative in BULK and 6.3e-15 in SALR, because the closure's polygons are added in another order. In both, every zone column the basin carries and the closure lacks is 0 on the group's rows, so leaving it out moves nothing.

| group | watershed rows | segment rows | beyond 1e-9 relative | pick |
|---|---|---|---|---|
| SALR | 59,631 | 117,000 | 0 | identical |
| BULK | 272,610 | 390,481 | 132 watershed, 144 segment | identical |

BULK's differing rows are 11 watersheds in months 1–12, at up to 5.8e-5 relative; annual flow is unaffected. All 11 sit at calibration gauges. In the province run a gauge's watershed is at distance exactly 0 from its own donor row, because the donor rows are the province run's own upstream means, and `wet_donor_mean()` then gives it the gauge's shares alone. In the group build that distance is about 1e-15, the zero test fails, and the other four donors take a small weight. Attribution: ours, the donor rule's exact-zero test (#158), not the closure. Of BULK's 12 watersheds within 1e-9 of a donor row, one stayed at exactly 0 and kept its months.

The comparison can fail. With MORR's polygons removed from BULK's closure, 3,449 watershed rows and 4,825 segment rows differ, by up to 336 m³/s.

## What the build buys, and what it does not

It buys one group's balance rows and pick in seconds from fixed inputs and a fixed fit. A change to the segment step it carries (the pick rule, the lut) can be tried there and read against the published product in seconds.

It does not build from other inputs: it refuses any province run but the one the shipped fit and the live build were made from, so a scenario from new input layers needs a mode without those guards and without the comparison. Nor does it reach a refit, which needs every calibration gauge. A portable build, run anywhere, would need the fit published beside the product. The manifest lists only `part-<code>.parquet` keys, so that is a manifest-format change and a republish. It would also need either the samples or `layers.tif`.
