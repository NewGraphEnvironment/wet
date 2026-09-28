# Progress — Evapotranspiration in the semi-arid interior (#15)

## Session 2026-09-27

- Plan-mode exploration — phases approved by user; the user chose "adopt the winner under a pre-set rule" at the gate, then "go all phases to PR"
- Created branch `15-evapotranspiration-in-the-semi-arid-inte` off main
- Scaffolded PWF baseline from issue #15 with approved phases
- Next: start Phase 1
- Phase 1: Hargreaves PET, Fu–Budyko AET, land-cover ratio and the Table 3 crosswalk, with tests. Code-check round 1 (retry; the first reviewer stalled with no file) found only a wrong example comment (130 → 171 mm, fixed) and a forward Rd link that the Phase 2 commit resolves
- Plan review (Plan agent) folded into the pre-registered rule before any layer was built: margin, nested selection, guards, mask invariance, run-dir move, per-variant fits
- Phase 2: `wet_landcover_nrcan()` (one VRT LUT warp; a 2×2-target fixture exposed a terra average-warp artefact at tiny grids, so the fixture is 4×4 with an `aggregate()` oracle); `wet_terraclimate_aet()` (whole-file download, since the NCSS subset returns empty bodies; a restore-the-bug check showed the nearest-cell fill was dead code under GDAL's reweighting bilinear, so it was removed)
- Phase 3/4 code: layers and mask guard in `wb_province.R`; `wb_cv_lib.R` factored out of `wb_validate.R`; `wet_wb_raw()` shared by validate and output; `wb_aet_compare.R` with the rule and the nested selection
- Code-check on Phases 1–2: four rounds. Round 2 found the fractions cache key omitted the source; round 3 found a defect inside that fix (url keyed, file cached by basename); round 4 was clean with an enumeration of every resampling site. Between rounds 3 and 4 my own spot check against exact-overlap counts found the one-step average warp off by up to 0.3 per cell in western BC. It is now a two-step method, with a rotated-CRS test shown to fail on the old method
- `scripts/wb_inputs.R` running from a frozen copy (`data/logs/20260927_wb_inputs_run.log`)
