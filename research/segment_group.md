# One watershed group's balance, rebuilt alone

**Verified:** 2026-11-15 (BULK from the published fit, byte-identical to the province run's build, #164); 2026-11-14 (parity after #158's donor tolerance, on province run `768876badf` and live build 3e8a968, #163); 2026-11-04 · **Issues:** #157 (spawned #158 and #160), #158 (closed by #163's tolerance), #160 (the fit published, #164) · **Produced by:** `scripts/segment_group_closure.R` → `data/checks/segment_group_closure.txt` (fwapg on the development machine); `scripts/segment_group.R BULK` and `SALR` with `WET_WB_RESAMPLE=1` → `data/checks/segment_group_{BULK,SALR}_20260717.txt`, run on the machine holding the province run, against the live build (province run `92b893c4da` and live build b4bbc50 under #157; `768876badf` and 3e8a968 under #163); run logs `data/logs/157/segment_group_*` and `data/logs/163/f_segment_group_*` on the machine that ran each · **Status:** measured; the build ships as a script, and since #164 also runs from the fit published beside the product (#160)

## The answer

A per-group build is worth having for the 138 of the province's 246 groups whose rows reach polygons in at most two other groups, and its smallest shape needs no published fit where the province run's inputs are. One group's balance rows and pick come back in about 20 seconds, against about 11 minutes for the province's sampling and accumulation. Rebuilt that way, SALR and BULK equal the published product in every watershed and segment row. Before #163 BULK differed at 11 watersheds that sit at calibration gauges, where the donor shares' exact-zero test turned on the last bits of the upstream means (#158); the test now has a tolerance.

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

The reach is the whole closure for 106 groups. BULK is one: it holds polygons at the bottom of the Bulkley, so its rows reach all of the Morice above (35,191 polygons). SALR holds none at the bottom of the Salmon, so its rows reach its own 4,587 polygons and 2 of LSAL's, not the 12,481 under its root. The gap is widest on the Fraser's main stem: UFRA's rows reach 23,358 polygons where its closure is 644,770 (the Fraser's 644,710 and 60 under drainage 999), while FRCN's rows reach the whole Fraser. 54 groups lie under more than one top-level drainage code, so their published rows sit in several parts.

## How long it takes

On the machine with the province run's `layers.tif`, BULK takes 8 s to sample, 2 s to accumulate and under a second to apply the fit, with 3 s to read its published rows. SALR takes 2 s to sample and under a second to accumulate and to apply the fit, with 3 s for the read. Where the province run's sample of a group exists the build reads it, and it samples only a group that has none. BULK and SALR resampled under today's terra and GDAL are `identical()` to the province run's samples.

## Parity with the published product

The group's upstream means differ from the province run's by at most 1.4e-12 relative in BULK and 4.1e-15 in SALR, because the polygons are added in another order. In both, every zone column the basin carries and the reach lacks is 0 on the group's rows, so leaving it out moves nothing.

| group | watershed rows | segment rows | beyond 1e-9 relative | pick |
|---|---|---|---|---|
| SALR | 59,631 | 117,000 | 0 | identical |
| BULK | 272,610 | 390,481 | 0 (132 watershed, 144 segment before #158's tolerance) | identical |

BULK's differing rows are 11 watersheds in months 1–12, at up to 5.8e-5 relative; annual flow is unaffected. All 11 sit at calibration gauges. In the province run a gauge's watershed is at distance exactly 0 from its own donor row, because the donor rows are the province run's own upstream means, and `wet_donor_mean()` then gives it the gauge's shares alone. In the group build that distance is tiny but not 0, the zero test fails, and the other four donors take a small weight. Attribution: ours, the donor rule's exact-zero test (#158), not the reach. Of BULK's 12 watersheds within 1e-9 of a donor row, one stayed at exactly 0 and kept its months.

Since #163 a donor within 1e-9 times the median distance takes the whole weight, shared equally by every donor within it (`wet_donor_mean()`), so those 12 keep their gauge's shares by either route. Refitted under it, every decision and number of the shipped fit was identical, and both groups rebuilt on the live build differ from it by at most 1.2e-12 in any `q_m3s` or `runoff_mm` value (largest relative difference in the upstream means 1.4e-12 in BULK, 4.1e-15 in SALR, as before).

The comparison can fail. With MORR's polygons removed from BULK's reach, 3,449 watershed rows and 4,825 segment rows differ, by up to 336 m³/s.

## What the build buys, and what it does not

It buys one group's balance rows and pick in seconds from fixed inputs and a fixed fit. A change to the segment step it carries (the pick rule, the lut) can be tried there and read against the published product in seconds.

It does not build from other inputs: it refuses any province run but the one the shipped fit and the live build were made from, so a scenario from new input layers needs a mode without those guards and without the comparison. Nor does it reach a refit, which needs every calibration gauge.

## From the published build (#160)

Since #164 the build publishes the fit beside the product: `fit/fits.rds` and each watershed group's province-run sample, `fit/sample/part-<GROUP>.parquet`, listed in the manifest's `fit` entry with the fit release, province run and scoring code (`research/discharge_publish.md`). `WET_GROUP_FROM=published Rscript scripts/segment_group.R <WSG>` reads both from there, each file fetched into wet's cache and checked against its md5, and checked again after the build. It needs no province run: what it still needs is this checkout, which must hold the build's commit (the manifest's `wet_commit`) with the scoring code files unchanged since it, and fwapg, for the FWA polygons and segments the reach is cut from and for routed PCIC's published annual flow, which the pick reads from the parts. It refuses a reach group with no published sample, `WET_WB_RESAMPLE` and `WET_GROUP_DROP`, which need the province run's layers. Its report is `data/checks/segment_group_<WSG>_published_<release>.txt`; the upstream means against the province run's are not compared there. The scoring md5 cannot be recomputed there, because it also hashes the stations file and the fit's decision files, which only the province machine holds; the BUILD checked the fit against it at that commit. Measured on 2026-11-15 against the live build a0318b7, from a checkout with no `data/wb`: BULK in 23 s (2.8 s fetching fits.rds and the BULK and MORR samples), its `watershed.parquet` and `segment.parquet` byte-identical to the default mode's (272,610 and 390,481 rows), and both at parity with the published rows (`data/checks/segment_group_BULK_published_20260717.txt`, `data/checks/segment_group_BULK_20260717.txt`).

Samples rather than `layers.tif` (decided at #164's gate, kept once measured): the 246 samples are 1.1 GB as rds on the province machine against 526 MB for `layers.tif` (one sample, SETN, 21.3 MB as rds and 26.0 MB as zstd parquet, reading back `identical()`), but a group's build fetches only its reach's groups rather than the whole grid, and the values cannot move with a terra or GDAL upgrade.
