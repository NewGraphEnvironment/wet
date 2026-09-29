# Issue #19: key the pre-#15 input caches on their builder code

## Outcome
Four builders returned a cached file whenever its name matched, and the name did not cover their code: `wet_cgiar_aet()`, `wet_dem_glo90()`, `wet_climr_normals()` and the hydrologic-zones grid in `scripts/wb_inputs.R`. Each now hashes a method-version constant into its cache name, as the #15 and #18 builders do. The DEM's hand-typed `glo90v3_` becomes `wet_dem_method`. The climr normals also key on climr's own version, since most of that computation is climr's code. The zones name no longer derives from the CGIAR name: it keys the grid, the zip md5 and `hz_method`. Each builder has a test showing that a file cached under an older name is rebuilt and not returned. All three tests fail on the previous code.

The plan review (`review-plan.md`) changed the design in two places, the zones key and the climr version. It also turned the acceptance criterion into concrete checks, because the original one ("only key/date lines change") could not have been met. `/code-check` ran three rounds, all clean.

Scoped out: the CGIAR and DEM names key the grid, not their source data (the figshare archives and the GLO-90 tiles on AWS). terra and GDAL versions are in no builder's key.

## Measurement
- **Inputs.** The rebuilt CGIAR crop, DEM, both climr normals and the zones grid are identical to the caches they replaced: same values (`wet_raster_md5()`), same geometry, and the same byte md5s. The pre-#19 caches were not stale, even though three of them predate the last commits to their builders (156317e, 3658923).
- **Province.** Run `962a9cc2c4` reproduces #18's `adc88b19c8`. All 56 layers are identical, and the upstream means match within 5.8e-16 of each column's scale. It took 13.4 min.
- **Downstream.** All 10 AET variants were re-scored, and the compare stage-1 check reproduced #15. cfu stays. The 13 tracked reports are identical as line sets once the run key and row order are normalised. The map PNG is byte-identical.
- **What that changed.** The whole shipped water balance now sits on inputs whose names carry their code. Nothing had to be re-derived, and the only thing that moved is the run key.
- **Wrong turns.**
  - The first version of the run comparison reported "REPRODUCED" on #15 vs #18, which have different layer sets. It was made strict before it was relied on.
  - The first report check used BSD awk's missing `asort()` and printed `bad=0` on errors. It was redone in Python.

## Evidence
- `data/checks/wb_province_run.txt`, `data/checks/wb_inputs.txt`, `data/checks/wb_validation*.txt`, `data/checks/wb_aet_compare.txt`, `data/checks/wb_output.txt`.
- Gitignored local logs: `data/logs/20260928_*`.
- The old caches and run: `data/wb_old/pre19_inputs/` and `data/wb_old/adc88b19c8/`.

Closed by: PR (see branch `19-key-the-pre-15-input-caches-on-their-b`)
