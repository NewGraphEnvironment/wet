# One watershed group's balance, rebuilt alone

**Verified:** 2026-11-04 · **Issues:** #157 (spawned #158) · **Produced by:** `scripts/segment_group_closure.R` → `data/checks/segment_group_closure.txt` (fwapg on the development machine); `scripts/segment_group.R BULK` and `SALR` with `WET_WB_RESAMPLE=1` → `data/checks/segment_group_{BULK,SALR}_20260717.txt`, run on the machine holding province run `92b893c4da`, against live build b4bbc50; run logs `data/logs/157/segment_group_*` on the machine that ran each · **Status:** measured; the build ships as a script, and publishing the fit is a follow-up

## The answer

A per-group build is worth having for the 138 of the province's 246 groups whose rows reach polygons in at most two other groups, and its smallest shape needs no published fit where the province run's inputs are. One group's balance rows and pick come back in about 20 seconds, against about 11 minutes for the province's sampling and accumulation. Rebuilt that way, SALR equals the published product in every watershed and segment row. BULK equals it except at 11 watersheds that sit at calibration gauges, where the donor shares' exact-zero test turns on the last bits of the upstream means (#158).

## What a group needs

A group's rows need the polygons `FWA_Upstream` counts upstream of at least one of them: their reach (`wet_ws_reach()`), which gives them the sums a whole basin gives them, up to the order the doubles are added in. The build finds it in two steps. `FWA_Upstream(a, b)` counts `b` only when `b`'s watershed code lies under `a`'s, so every polygon under the group's roots, its distinct codes with no ancestor among them, is a closed set holding the reach (`wet_ws_roots()`, `wet_ws_closure()`). That set also holds each root's stream below the group and the tributaries there, which `wet_ws_reach()` then trims off with the same ranges `wet_upstream_sums()` sums over. Pure-R tests check both steps against the brute-force `FWA_Upstream` oracle on 40 random trees with irregular codes, and live tests check them in basin 925, BULK and SALR.

How many groups and polygons a group's rows reach, over the province's 246 groups, with the closure beside it:

| groups spanned, itself included | reach | closure |
|---|---|---|
| 1 | 59 | 53 |
| 2–3 | 79 | 59 |
| 4–10 | 60 | 62 |
| more than 10 | 48 | 72 |

| polygons | reach | closure |
|---|---|---|
| up to 50,000 | 172 | 146 |
| 50,000–200,000 | 50 | 52 |
| over 200,000 | 24 | 48 |

The reach is the whole closure for 106 groups. BULK is one: it holds polygons at the bottom of the Bulkley, so its rows reach all of the Morice above (35,191 polygons). SALR holds none at the bottom of the Salmon, so its rows reach its own 4,587 polygons and 2 of LSAL's, not the 12,481 under its root. The gap is widest on the Fraser's main stem: UFRA's rows reach 23,358 polygons where its closure is the Fraser's 644,770, while FRCN's and LFRA's reach all of it. 54 groups lie under more than one top-level drainage code, so their published rows sit in several parts.

## How long it takes

On the machine with the province run's `layers.tif`, BULK takes 8 s to sample, 2 s to accumulate and under a second to apply the fit, with 3 s to read its published rows. SALR takes 2 s to sample and under a second to accumulate and to apply the fit, with 3 s for the read. Where the province run's sample of a group exists the build reads it, and it samples only a group that has none. BULK and SALR resampled under today's terra and GDAL are `identical()` to the province run's samples.

## Parity with the published product

The group's upstream means differ from the province run's by at most 1.4e-12 relative in BULK and 4.1e-15 in SALR, because the polygons are added in another order. In both, every zone column the basin carries and the reach lacks is 0 on the group's rows, so leaving it out moves nothing.

| group | watershed rows | segment rows | beyond 1e-9 relative | pick |
|---|---|---|---|---|
| SALR | 59,631 | 117,000 | 0 | identical |
| BULK | 272,610 | 390,481 | 132 watershed, 144 segment | identical |

BULK's differing rows are 11 watersheds in months 1–12, at up to 5.8e-5 relative; annual flow is unaffected. All 11 sit at calibration gauges. In the province run a gauge's watershed is at distance exactly 0 from its own donor row, because the donor rows are the province run's own upstream means, and `wet_donor_mean()` then gives it the gauge's shares alone. In the group build that distance is tiny but not 0, the zero test fails, and the other four donors take a small weight. Attribution: ours, the donor rule's exact-zero test (#158), not the reach. Of BULK's 12 watersheds within 1e-9 of a donor row, one stayed at exactly 0 and kept its months.

The comparison can fail. With MORR's polygons removed from BULK's reach, 3,449 watershed rows and 4,825 segment rows differ, by up to 336 m³/s.

## What the build buys, and what it does not

It buys one group's balance rows and pick in seconds from fixed inputs and a fixed fit. A change to the segment step it carries (the pick rule, the lut) can be tried there and read against the published product in seconds.

It does not build from other inputs: it refuses any province run but the one the shipped fit and the live build were made from, so a scenario from new input layers needs a mode without those guards and without the comparison. Nor does it reach a refit, which needs every calibration gauge. A portable build, run anywhere, would need the fit published beside the product. The manifest lists only `part-<code>.parquet` keys, so that is a manifest-format change and a republish. It would also need either the samples or `layers.tif`.
