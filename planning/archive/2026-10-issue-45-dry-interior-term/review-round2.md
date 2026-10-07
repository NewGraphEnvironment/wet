# Code review, round 2: scripts/wb_term_diagnose.R (#45)

Scope: the three round-1 fixes first, then the whole script against findings.md "Pre-registered
attribution rule" + "Amendment 1" + "Implementation readings". Probes were read-only, run in the
session scratchpad: `save_atomic()` on a 5-layer named, timed raster and on an rds; terra
`extract(<hydz polygons>, <points>)` on the real zones shapefile (unzipped into the scratchpad,
not data/hydz/); `cv_aet-cfu.rds` fields; `linear_feature_id` NA/format in stations_20260717.rds.
No PCIC value, data/wb_term/ or the report was read.

## Round-1 fixes: all three are correct, and none adds a defect

- **id.y check (line 194).** On the real shapefile with 4 points, one of them offshore: `id.y` is
  num `1 2 3 4`. The offshore point keeps a row with `HYDZN_NO = NA`. After the dedupe,
  `nrow(zp) == nrow(ec) && all(zp$id.y == seq_len(nrow(ec)))` is TRUE. `HYDZN_NO` is numeric, and
  `sprintf("%02d")` gives "15"/"24", which matches `cal$zone` and wb_inputs.R's
  `rasterize(field = "HYDZN_NO")`.
- **w_high (lines 211-212).** `!is.na(w) & w > 5` is FALSE for NA (FALSE & NA = FALSE) and TRUE
  for Inf. Every basin is now in both denominators, which matches the second Implementation
  reading. `w_low` uses `is.finite(w) & w <= 5`, so both Inf and NA fail, as (AET) requires.
- **save_atomic (lines 42-47).**
  - `filetype = "GTiff"` is explicit, so the `.part` extension does not affect driver detection.
  - Read back after the rename: names `p_c e_c ro_c bf_c pet_c` survive, so the `stopifnot` on
    line 80 holds. Values, and even `time`, survive too.
  - No sidecar was left behind, under either the `.part` name or the final name.
  - The rds branch writes and reads back. `file.rename()` overwrites an existing target, and the
    `.part` file sits in the same directory, so the rename is atomic.
  - The braceless `if … else` across lines is valid inside a function body.

## Findings

- **[fragile: pre-registration, unrecorded reading]** scripts/wb_term_diagnose.R:211-214, the
  "under both PETs" clauses of (i′) and of the AET corroboration. The script takes the **smaller of
  two per-PET shares**: `min(mean(high_harg), mean(high_pcic)) >= 0.5`. That passes when half the
  basins are high under Hargreaves and a *different* half are high under PET_NATVEG.
  - The rule's text ("> 5 … at ≥ half the basins under both Hargreaves `pet_yr` and PCIC
    `PET_NATVEG`") reads just as naturally **per basin**: `mean(high_harg & high_pcic) >= 0.5`.
    That reading is stricter.
  - The same applies to `w_low > 0.5`.
  - The two readings can give different (i′) and AET-side verdicts. The one in use is not among
    the "Implementation readings" in findings.md. The report states it ("the smaller under the
    two PETs"), but only after the values are out.
  - Record the reading in findings.md now, while no PCIC value has been seen, so it cannot later
    look like a choice made after the fact. Whether `w_pcic` would separate the two readings
    cannot be checked without PCIC values.

- **[fragile: stale cache can silently drop gauges]** scripts/wb_term_diagnose.R:60 and 88.
  - `pcic_upstream_<code>_<release>.rds` holds the upstream means **cut to
    `cal$watershed_feature_id`**. Its key is the release only.
  - `cal` also depends on the province run (`key_dir`, through the `coverage`/`bc_fraction`
    filters in wb_cv_lib.R).
  - A new province run under the same release reuses the old cut. Any calibration basin missing
    from it then drops out at the `merge()` on line 105 with no message, and `n_in_basins` simply
    reads lower.
  - It does not affect the current run. Either add `basename(key_dir)` to the filename, or
    `stopifnot(all(cal$watershed_feature_id[<in basin>] %in% up$watershed_feature_id))`. The
    simpler fix is to add the key to the filename.

## Operational note (not a defect in the diff)

The in-flight run (`data/logs/45/wb_term_diagnose_frozen.R`, PID 72216) is a copy made **before
all three fixes**. Diff against the staged script: it has `identical(zp$id.y, …)`, the old
`na.rm` `w_high`, and in-place `writeRaster`/`saveRDS`.

- It will stop at the stage-3 `stopifnot` before it writes `eccc_climr.rds`, any report or any
  value. The old `w_high` therefore never reaches a verdict, and the firewall holds.
- Its `pcic_cell_*.tif` and `pcic_upstream_*.rds` caches are complete if it reaches that stop
  normally, and the fixed script reuses them.
- If the run is killed during a write instead, delete the cache it was writing before running
  the fixed script.

## Checked against the rule and found faithful (no finding)

- **Order of tests:** too few (n < 4 distinct basins) → `le_o < 0.10` gives no gap → usable
  (`ale_c > 0.25` or median |closure / R_c| > 0.25) → shared overshoot (`le_c >= 0.10` and
  `>= 2/3 · le_o`; P shared iff `tc_o <= 0.90` and `tc_c <= 0.90`, else gauge side) → decompose.
  The decomposition is always computed and reported.
- **Decomposition:**
  - G ≤ 0 is undefined.
  - Both bands are inclusive [⅔, 1.5].
  - Because share_p + share_a = 1, P band, A band, compensating (> 1.5) and mixed (share_p in
    (⅓, ⅔)) cover every case.
  - P corroboration is an OR of (i′), (ii′) and (iii). (ii′) needs ≥ 3 stations, and NA counts
    as unavailable rather than failed.
  - AET corroboration is the AND of `w_low > 0.5` and `mod16 >= 1.00`.
- **omega_implied:**
  - The Fu AET rises with ω, so `f(1.0001) >= 0` gives 1, and `f(50) < 0` or
    `aet >= min(P, PET)` gives Inf. Those are the rule's "no solution" cases.
  - uniroot's endpoints always bracket a root.
  - `wet_aet_budyko(p, pet, w)` takes the arguments in this order.
- **Fu counterfactual:** the default ω = 2.6 is the ω that `aet_fu`/`aet_cfu` used
  (wb_province.R:119-123, cfu = max(CGIAR, Fu 2.6)).
- **Dedupe:** numerics are averaged per `watershed_feature_id` after the ≥ 0.95 cover filter.
  The "< 20 years" count uses gauges (`g`), as its label says.
- **Stability:** leave-one-basin-out on each judged zone and on the pooled stratum, with the
  minimum applied to the zone only, as recorded.
- **Lever:**
  - Votes come from 15, 17, 23 and 24.
  - Only the three term verdicts vote, so "unstable (…)" casts none.
  - The lever needs ≥ 2 votes and a strict majority.
  - It is vetoed only when the pooled verdict is the other term
    (`identical("AET", setdiff(...))` works; NA never vetoes).
- **SQL:** no `linear_feature_id` is NA among the accepted stations, and none prints in
  scientific notation, so the `IN (…)` list is valid. `mad_mm` exists
  (research/fwapg_mad_method.md).
- **cv:** `cv_aet-cfu.rds` carries `aet`, `release`, `code_md5`, `cv_ann` and `station_number`.
- **ECCC:** the climr and ECCC block matches wb_inputs.R (refmap_climr + mswx.blend 1981-2010,
  mean over years). The 500 m filter runs against the median basin `elev` of the subset being
  judged.
- **Report:** `%d` fields (`n`, `n_eccc`, vote counts) are integers in both the list path and the
  data-frame row path. `closure` in the zone table is the median absolute value; in the "sound"
  section it is the signed median, and each label says which.
