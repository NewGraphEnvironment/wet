# Code-check round 3 (#39): staged diff, data-raw/segment_vignette_{data,map}.R

Probes on 2026-10-06, run against the local fwapg, the working-tree `inst/vignette-data/segment_map.rds`
(built from the staged map script), the committed `segment_values.rds` and `data/wb/stations.rds`.
Context box used in SQL: 1064272 973952 1242738 1178867 (EPSG:3005).

## The mechanism behind round 2's two findings

Every layer is selected by a predicate written for the common case: a hand-picked edge-type list
(single-line main flow), a size or order threshold, or "the group holds any value" as the test for
membership. Each postcondition then checks only that something came back (`nrow > 0`, `setequal` on a
non-empty set, `count(...) > 0`). It never checks the property the layer exists to show: that each
gauge sits on a drawn river, that the outline covers what it says, that the polygons are valid. A
mostly-wrong result passes the guard, so the selection is never tested against its purpose. Round 2's
edge-type list and its simplify-then-snap geometries were two instances. Two more remain, below.

## Findings

- **[severity: bug]** data-raw/segment_vignette_map.R:105-112 (`coverage`), data-raw/segment_vignette_data.R:118-121 and 185 (`fwapg_groups`, `in_pcic`). Here "covered" means `count(mad_mm) > 0`, the SQL form of `nrow > 0`.
  - Of the 123 groups that pass, 11 hold a value on at most 22 % of their segments: FONT has 4 of 20,984; LPRO, MMUS and MPRO about 3 %; UMUS 7 %; KAHN and UPRO 9 %; LSIK and GATA 14 %; FROG 17 %; USIK 22 %. MILL is at 63 %.
  - All 11 are Liard-basin groups where PCIC's Peace grid edge clips them. Together they add 43,288 km², 8.5 % of the 506,496 km² outline. So the province map draws PCIC's coverage into the Liard, which CLAUDE.md says PCIC does not cover (Peace, Fraser and Columbia only).
  - Three calibration gauges fall in these groups:
    - 10CB001, Sikanni Chief near Fort Nelson (USIK). fwapg has a value at its watershed.
    - 10CD004 and 10CD005 (MPRO, about 3 % valued). Both get `in_pcic = TRUE` with `fwapg_mm` NA.
  - The vignette will therefore count those two as "inside PCIC's coverage, fwapg null". The comment at data.R:182-184 gives only two reasons for that, a null row or a large river with no row; grid-edge partial coverage is a third. The planned test `expect_gt(sum(!is.na(fwapg_mm)), 0.75 * sum(in_pcic))` absorbs it.
  - **Fix**: make membership a fraction, e.g. `count(mad_mm) >= 0.5 * count(*)`, with one definition shared by both scripts. Note that a fraction rule alone drops USIK, and then 10CB001, which does have a value, fails `all(sk$in_pcic[!is.na(sk$fwapg_mm)])` and the planned outline-containment test. Choosing between (a) scoring only gauges in fully covered groups and (b) drawing and flagging the partial groups separately is a content decision for the plan gate.

- **[severity: bug]** data-raw/segment_vignette_map.R:88-92 (`context_streams`, `stream_order >= 6`). The header says the layer exists "so a gauge off the group sits on its river". One of the five `gauges_salr`, 08KC003 Muskeg River north of Joanne Lake, is 14 km from SALR. Its segment, 702365476 in MUSK, is **order 5**, so its river is not drawn.
  - Measured on the built rds, its nearest drawn line (SALR segments plus context_streams) is **6,927 m** away. The other four are 29-86 m from theirs: 07ED001 Nation, 08JE001 Stuart, 08JE004 Tsilcoh and 08KC001 Salmon, which are order 6-7 on edge types 1000/1250.
  - `nrow(context_streams) > 0` passes. The planned test checks only that the gauges are inside `context`, not that they are on a line.
  - **Fix**: add the gauges' own rivers. One way is the `blue_line_key`s of the gauges_salr segments within the box. Lowering the threshold to order >= 5 also works, at some cost in size. Then assert, in the test since the gauge list lives in the data script, that each `gauges_salr` point is within about 200 m of a drawn line.

## Where else the mechanism reaches: measured and sound

- **context_streams edge types** (map.R:92): in the box, order >= 6 outside SALR, the list now drops 1475 "lake arm" (184 km: PARA's order-9 Williston arm, NECR, CARP). All 184 km lie inside a drawn context lake (0 km outside). It also drops 1100/1350/1425, about 2 km in total. No gap is drawn.
- **context_lakes `area_ha >= 1000`** (map.R:98): the threshold is per feature, but no waterbody in the box is split into pieces under 1,000 ha that total 1,000 ha or more. `fwa_manmade_waterbodies_poly` has nothing of 100 ha or more in the box, and Williston Lake is in `fwa_lakes_poly` (PARA, 37,471 ha), so the table choice loses no reservoir.
- **lakes, groups** (map.R:67-77): simplify plus snap with no SQL repair, but the R assert at map.R:186-188 covers them and fails toward stop. In the built rds all 9 layers have 0 invalid and 0 empty geometries. context_lakes and coverage are MULTIPOLYGON.
- **segments** (map.R:54-64): lines, with a collapsed segment falling back to its unsnapped line. The count is asserted equal to the source per group, so it is not an existence check.
- **zones** (map.R:138-152): 29 zones, non-empty, unique, valid; asserted.
- **places FEATURE_TYPE list** (map.R:163): a hand list with an existence-only guard (`setequal`), but the output is plausible: SALR frame has Prince George, Mackenzie, Fort St. James, Vanderhoof and Fraser Lake; BULK has Smithers, Houston, Telkwa and New Hazelton. That makes this a content choice, not a defect.
- **Data script guards**: `fw_sk` uniqueness, `!anyNA(near$fwapg_mm)`, `n_match5 == n_segments` and `nrow(par) == n_fwapg` are strict. `nrow(near) > 0` cannot fail, because the outlet is always included. It is harmless, but it says nothing. The `in_pcic` assertion at data.R:187 holds by construction (round 1).
- **`fwapg_max_order_all`** (data.R:125-127) is taken over `fwapg_groups`, so the Liard groups in the first finding also feed it. Any change to the coverage definition should go through this too.
