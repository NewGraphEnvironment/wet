# Review — Phase 1, round 1 (staged diff: wet_pet_hargreaves, wet_aet_budyko, wet_aet_landcover, wet_chapman_table3)

## Findings

- **[fragile]** man/wet_aet_landcover.Rd:21 (from R/wet_aet_landcover.R:22) — the `frac` doc links
  `[wet_landcover_nrcan()]`, but `R/wet_landcover_nrcan.R` is untracked (`??` in `git status`) and
  not in the staged NAMESPACE. The commit as staged has a dangling Rd link, which `R CMD check`
  reports under "checking Rd cross-references" (Missing link). Resolves itself once
  `wet_landcover_nrcan.R` is committed with a regenerated NAMESPACE; only matters if this commit
  is checked on its own (or the other file is never committed).

- **[bug, doc only]** R/wet_pet_hargreaves.R:23 — example comment says "a July at 50 N with a 20 C
  diurnal range: about 130 mm"; the function returns **171.06 mm** (Ra = 16.30 mm/day at J = 198;
  0.0023 * 32.8 * sqrt(20) * 16.30 * 31 = 171). The code agrees with FAO-56 eq. 52; the comment
  is wrong by ~30 %, and it is the number a reader will sanity-check against.

## Checked and clean (probed with `devtools::load_all()`, terra not attached)

- `SpatRaster * numeric` of length nlyr is per-layer (3-layer, 3-cell probe: unambiguous).
- `sum()`, `!is.na()`, `*` dispatch fine with terra imported, not attached.
- `which.max` returns layer index; zonal zone column carries those indices, matched positionally
  (`z[[1]]`, `z[[2]]`), so duplicate layer names ("lyr.1", "lyr.1.1") are harmless.
- `classify(frac, cbind(NA, 0))` turns NA to 0; an all-NA-frac cell keeps the input AET.
- `mask(maj, domain, maskvalues = c(NA, 0))` drops both FALSE and NA domain cells, for numeric
  and logical domain rasters.
- NA `aet` inside a majority cell: excluded from both mean and `n_cells` — consistent.
- `wet_ra()`: polar day/night clamp works (lat ±89, ±90 give finite values, 0 in polar night);
  FAO-56 Example 8 reproduced by test.
- Budyko: 0^w, negative inputs, NA omega handled; SpatRaster and vector paths agree.
- Tests: 50 pass. Fixtures reach the failure modes of interest (NA frac, partial cover, zero-cell
  class, domain, clamp, min_cells, negative diurnal range, Tmean < -17.8).
- The `man/wet_wb_fit.Rd` change is roxygen catching up with the already-committed
  `R/wet_wb_fit.R` (3658923), not an unrelated edit.
