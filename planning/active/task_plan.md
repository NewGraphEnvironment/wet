# Task: MOD16 AET as a challenger to the shipped annual AET (#18)

#15 deferred MOD16A3GF v061 (LP DAAC, annual ET, 500 m, from 2000) because it needed an Earthdata login. That's now set up through `earthdatalogin`: a test tile (h10v03, 2010) downloads and reads, with ET in mm/yr and fill codes for water, barren, snow and urban. MOD16 is Penman–Monteith on MODIS land cover and LAI, not capped by a coarse precipitation field, so it's the independent AET #15 lacked.

**If we do it:** the one ET product #15 deferred gets scored. If it beats what ships (`max(CGIAR, Fu–Budyko)`), it replaces it, especially on the dry interior plateaus, where zone 24 still runs +102 %. **If we never do:** #15's comparison stays one product short.

## Pre-set decision rule (fixed here, before any MOD16 variant is scored)

Challengers (annual AET layers; raw = upstream mean `p_yr` − upstream mean AET):
- `mod16`: MOD16A3GF v061 annual ET, mean over 2001–2020. It is reprojected with the two-step method. Gaps are filled with the shipped AET, weighted by area (below).
- `cmod16`: max(CGIAR `aet_yr`, `mod16`).

The **incumbent** is the variant #15's unchanged rule selects on this run. That is expected to be `cfu`, and the script asserts #15's result reproduces.

A challenger replaces the incumbent only if **all** of the following hold, scored as shipped under blocked CV:
- (a) its headwater MAE is at least **2.0 points** below the incumbent's;
- (b) its all-station MAE is no higher than the incumbent's;
- (c) its nested MAE is at most 1.0 point above the incumbent's, and its nested within ±20 % is at most 3 points below;
- (d) under a fully nested selection, where each outer fold picks among {incumbent, `mod16`, `cmod16`} by (a)–(c) on an inner blocked CV, headwater MAE is below the incumbent's.

If several challengers pass, the lowest headwater MAE wins. If none passes, the incumbent stays.

Disclosed up front:
- **Period:** MOD16 covers 2001–2020, while the rest of the model uses 1981–2010 normals.
- **Gap fill:** gaps (barren, snow/ice, water and urban codes) take the shipped AET, which pulls alpine cells toward the incumbent's behaviour.
- **MOD16 can exceed P in dry cells:** cells stay signed and only the output is floored at 0, as now.
- **Nested selection:** it does not re-run #15's stage inside each fold, because the incumbent is fixed.
- **Adoption principle:** MOD16's production code does not ship, but it would enter as an input, in CGIAR's position, not as a published product. The issue authorizes shipping it if it wins.

## Phase 1: MOD16 fetcher (tests first)
- [ ] Probe (scratchpad): download h10v03 2010 and confirm the `ET_500m` subdataset name, the 0.1 scale, the fill codes (32761–32767) and the valid max. Run `edl_search()` over the grid bbox for 2001–2020 and record the BC tile list, the granule count and the total size in `findings.md`.
- [ ] `tests/testthat/test-wet_mod16_aet.R` uses synthetic sinusoidal tiles (GeoTIFF stand-ins, with the HDF reader and the download mocked). It covers:
  - fill codes are masked and the scale is applied;
  - the per-pixel mean over years honours `min_years`;
  - the two-step reprojection lands exactly on the grid (`compareGeom`, and a constant field comes back exact);
  - `frac_mod16` is the valid share at a gap edge;
  - a missing tile-year stops with a clear error;
  - a cached result comes back without a download or a rebuild.
- [ ] `R/wet_mod16_aet.R`, with the signature `wet_mod16_aet(grid, years = 2001:2020, dir = "data/mod16", overwrite = FALSE, timeout, fact = 4, min_years = 10)`. It returns a GeoTIFF with two layers: `aet_mod16` (mm/yr, the mean over valid sub-cells) and `frac_mod16` (the valid share, 0–1). Internals:
  - granule listing via `earthdatalogin::edl_search()`, which requires every tile × year to be present;
  - `edl_download()` to `.part`, then rename;
  - a running sum and count per tile in sinusoidal, then a mosaic, then nearest onto `disagg(grid, fact)`, then `aggregate(mean)`;
  - a cache key of grid key + years + `min_years` + `fact` + the md5 of the files read + `wet_mod16_method`.
- [ ] Add `earthdatalogin` to Suggests, with a `requireNamespace()` guard (as `climr` has). Also add roxygen with `@examplesIf interactive()`, run `devtools::document()`, then run lintr and the tests.

## Phase 2: Inputs and province layers
- [ ] `scripts/wb_inputs.R`: build MOD16 on the CGIAR grid, and add a manifest row (granule count, combined md5) to `data/checks/wb_inputs.txt`.
- [ ] `scripts/wb_province.R`: add `m16` to `f_in` and `compareGeom`, and `R/wet_mod16_aet.R` to `code_files`. Then add two layers:
  - `aet_mod16 = frac·mod16 + (1 − frac)·aet_cfu`, with `aet_cfu` wherever frac is 0 or NA;
  - `aet_cmod16 = max(aet_yr, aet_mod16)`.

  Write the counts of fully and partly filled cells to `ex_filled_cells.txt`. The mask-unmoved assertion then covers the new layers.
- [ ] `wet_wb_aet_cols()`: add `mod16` and `cmod16`, and update `test-wet_wb_raw.R`.
- [ ] Smoke-test with `WET_WB_GROUPS=SALR,OKAN`, then run the full province under `caffeinate -i`. Move the old run to `data/wb_old/`. Check that the #11/#15 layers match the old run exactly and that the calibration set is the same 290 stations. Commit the run log.

## Phase 3: Rule and scoring
- [ ] `scripts/wb_aet_compare.R`: change `decide(m, incumbent, eligible)` and the nested selection to take the incumbent and the candidates. Then:
  - **Stage 1** is #15's rule, unchanged. It asserts it still picks `cfu` with the #15 numbers.
  - **Stage 2** is the #18 rule above.

  The report shows both stages. It adds `mod16` / `cmod16` detail rows (zones 15/17/23/24, < 100 km², Greata), the gap-fill counts and the period disclosure. `WINNER` is stage 2's result, and `aet_winner.txt` holds it.
- [ ] Update `wb_validate.R`'s usage line. Run `wb_validate.R` for all 10 variants, then `wb_aet_compare.R`, then `wb_validate.R <winner>`, and commit the logs under `data/logs/`.

## Phase 4: Ship and write-up
- [ ] Re-run `scripts/wb_output.R` and `scripts/wb_map.R` on the new key, whichever variant wins. If the winner changed, re-render `research/wb_runoff_annual.png` and do the cartography self-review.
- [ ] `research/water_balance_method.md` §0: add a MOD16 subsection with the results and the attribution (ours, theirs or unresolved). Replace the "MOD16 was deferred" line and update the header line. Also update the `research/README.md` row, and the CLAUDE.md blurb if the shipped AET changes.
- [ ] Edit the issue #18 body with the outcome.

## Validation

- [ ] Tests pass (no network needed)
- [ ] #15's stage reproduces `cfu` and its table on the new key
- [ ] `wb_validation_aet-cgiar.txt` unchanged apart from the run-key line
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
