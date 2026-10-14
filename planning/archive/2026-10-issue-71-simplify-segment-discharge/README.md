# Simplify the segment-discharge article (#71)

## Outcome

`vignettes/segment-discharge.Rmd` now answers three questions in order: what the product is, which value to use, and how far to trust it. `pick` has its own early section giving its rule, why a default exists and the province counts. One province map shows the source `pick` takes on main-flow rivers of order 5 and up, with the Liard and the Nechako Reservoir labelled. The Salmon River tables and maps, the four-wedge scatter and their guards are gone, and the score table stays with one sentence on each weakness.

`data-raw/segment_vignette_map.R` now reads every segment's pick from the live published parts, under the same guards as the values script. Those guards are: the publish report passing, md5s verified before and after the read, and every picked id present in fwapg. `data-raw/segment_vignette_data.R` keeps the gauges and the routed check, and takes the province counts from the tracked segment report, held to the reader counts and to fwapg.

The column stays `pick` in v1. Renaming it `is_default` at v2 is recorded in `research/discharge_publish.md`.

What review taught: the four defects the plan review and the code check found in the prose had one mechanism. Each time, the prose restated a set the code defines (far-low flips, segments with neither, "off its own line", a build) by its most familiar member or by a nearby proxy, and the guard then tested the proxy. Round 3 ended the loop by walking every claim the branch adds against the code and the data.

## Measurement

- Province: 4,907,441 FWA segments. `pick` takes routed PCIC on 3,152,838 (64 %) and the balance on 1,380,005 (28 %); for 224,199 of those, routed is far low. 374,598 have neither: 369,217 have no lut watershed, and 366,362 are connection lines or secondary-flow channels by edge type. Do not count them by `stream_order = 1`, which FWA gives these lines whatever they are.
- Liard basin: 0 routed, 716,213 balance, 38,270 neither. Nechako Reservoir groups (LEUT, UEUT, UNRS, LNRS): 1,046 routed, 59,821 balance (98 %), 7,047 neither.
- Map: 284,553 main-flow segments of order ≥ 5, about 6 % of segments, dissolved to 17,866 vertices; `segment_map.rds` 104 KB (was 147). The bundle totals 129 KB of 500. Reading `pick` province-wide from the parts takes 17 s.
- The neither class is not drawn: 1,557 main-flow segments of order ≥ 5, about 0.2 % of drawn length, cannot be seen at page width.
- Article: 860 words of body prose (was 1,124) and 386 lines (was 664). The issue forecast "roughly half". The six required sections and their guards kept the words at 77 %.
- The SALR comparison in `research/water_balance_method.md` is reproduced by commits up to 6be3e11. Its bundle was built at 7b83959.

## Evidence

Run logs are local to m1 (`data/logs/71/`, gitignored). Tracked inputs: `data/checks/segment_output_20260717.txt` and `data/checks/discharge_publish_20260717.txt`. The reviews are in this directory: `review-plan.md` and `review-round{1,2,3}.md`.

Closed by: PR #72
