## Outcome

#163 carried backlog batches 1 and 2 (#23, #51, #24, #21, #158, #47) through one rescore-refit-publish chain instead of six. Input caches are now keyed on their source data: the CGIAR crop on its archives' md5s, checked against figshare's on a rebuild, and the GLO-90 DEM on its tiles' ETags. climr's check against ECCC normals averages the 30 observed years alone (#51). `scripts/wb_run_compare.R` proves one province run equals another, file by file (#24). A rerun under the rekeyed inputs (province run `768876badf`) equalled `92b893c4da` in every file, and every tracked fit report reproduced byte for byte (#21). The donor rule's zero test has a tolerance, so a calibration gauge keeps its own shares when its upstream means differ in their last bits (#158). #47's registered gate keeps the zone adjustment on main-stem evidence, so `adjust_override.txt` and its reader are retired. Mid-chain, m4's routed PCIC table turned out to be fwapg#24's rebuild (fwapg 5d50cc1, which places the Nechako Reservoir). The owner chose to adopt it, so the routed comparison, both segment tables and the BUILD were rerun on it and published. The durable results are in `research/water_balance_method.md` §0 (the gate, the routed comparison on 5d50cc1), `research/segment_group.md` (#158's parity) and `research/discharge_publish.md` (the live build).

## Measurement

- **Inputs (#23):** the rebuilt crop and DEM are byte- and value-identical to the old files (`f24bedbc`, `ae0bdc5602`), so climr was reused. Reading the DEM's 261 tile ETags takes 5.0 s from m1.
- **Province run (#24, #21):** `768876badf` against `92b893c4da`: IDENTICAL, 275 of 275 files, 3,245,453 upstream watersheds. The comparison exits 1 on a single `aet_yr` value multiplied by 1 + 1e-15, and on the pre-#76 run (272 differences, the snow layers). All 11 `wb_validation*` reports and `wb_aet_compare` equal the committed ones once the run key is substituted.
- **climr check (#51):** MAP ratio median 1.034 → 1.035 at 57 ECCC stations. Zone 15's 1.05 in the term diagnosis stands; four valley station ratios rose by 0.01.
- **Gate (#47):** 2 of 20 variant-fits flip, both `fu35`, which cannot win. The shipped `cfu` is kept by the 1.0-point margin arm, at 30.72 against raw 30.69. Refitting under the new scoring code left every decision and number identical; only the code md5s change, and `gate_arm` is `margin`.
- **Balance:** `output/` 24 of 24 files byte-identical, 0 of 168,190,490 values differ. In both segment tables the balance rows are identical (58,889,207 monthly, 1,653,427,735 daily).
- **Routed rebuild (theirs, adopted):** routed total 178,918,222.786650 → 179,854,603.510890 m³/s. Picks moved on 59,206 segments, almost all in LEUT, LNRS, UEUT and UNRS. At 290 gauges routed MAE fell from 24.2 to 23.1 %, and on the Fraser from 30.7 to 27.2 %. The first routed run was mislabelled with the old commit and soft-reset unpushed; the committed report is the rerun.
- **BUILD and PUBLISH:** the BUILD took 3 h 11 min. Every check passed, with 0 values differing over more than 15 billion compared, and 499 of 512 parts were byte-identical to live. PUBLISH uploaded 13 parts in about 2 min, deleted 0 stale keys, and 512 verify anonymously.
- **Group rebuilds (#158):** BULK and SALR rebuilt alone equal every published row. BULK had 132 watershed and 144 segment rows beyond 1e-9 before the tolerance; it has 0 now, at most 1.2e-12 off.
- **Wrong turns:** `check_refit163.R` first stopped on `aet_md5`, a field bound to change with the scoring code that the check had missed. chain_d's BUILD hung 25 min in a database connect while m4's Docker engine was down, and was rerun alone the next day.

## Evidence

`data/logs/163/` on m4: `chain163_[a-f]*`, their step logs (`[a-f]_*`), `20261113T075010Z_run_compare_*`, `wb_gate_main_stems_try.txt`. On m1, `data/logs/163/wb_term_diagnose.log`. The review rounds are `review-round[1-4].md` and `review-enumeration.md` in this directory.

## Owed

- `backlog.md` tick by `/gh-pr-merge` 9c; move 2 (#164) is next and publishes the refit fit

#164's body also carries what waits on the new live build: the `inst/vignette-data/` bundles, the segment-discharge article's Nechako sentences, the README figure, and reloading m1's `pcic` from fwapg 5d50cc1's export.

Closed by: branch `163-backlog-move-1-one-refit-chain-input-key` (the PR is linked from #163)
