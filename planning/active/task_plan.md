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
- (d) under a fully nested selection, where each outer fold picks among {incumbent, `mod16`, `cmod16`} by (a)–(c) on an inner blocked CV, headwater MAE is below the incumbent's **as-shipped headwater MAE on this run** (the number (a) uses; #15's cfu: 31.2 %, not its nested 32.3 %).

If several challengers pass, the lowest headwater MAE wins. If none passes, the incumbent stays. If #15's stage does not return `cfu` on this run, the script stops: the gap fill is built on `aet_cfu`, so the plan is revisited rather than the rule reinterpreted.

**Frozen before the first `wb_validate.R mod16`** (review R4): years 2001–2020, `min_years` 10, `fact` 4, the gap codes (every value above the valid 0–65500), the area-weighted fill from `aet_cfu`, `frac` counted over all `fact²` sub-cells. A change after that is allowed only as a documented correctness fix, with both scores reported and the pre-set one deciding.

Transparency only, never deciding: a two-stage nested selection (each fold runs #15's stage, then this one with its own stage-1 winner as incumbent), the per-fold choice counts, the distribution of each station's upstream MOD16 share, and headwater MAE for stations whose basin is at least 80 % MOD16.

Disclosed up front:
- **Period:** MOD16 covers 2001–2020, while the rest of the model uses 1981–2010 normals.
- **Gap fill:** gaps take the shipped AET, which pulls those cells toward the incumbent's behaviour and dilutes the challengers' power to clear the 2-point margin. The gap codes (MOD16 v6.1 user guide, MOD16A3/A3GF) are 65529 unclassified, 65530 urban, 65531 permanent wetland, 65532 perennial snow/ice, 65533 barren/sparse, 65534 water, and 65535 fill. Gap cells also mix periods (1981–2010 there, 2001–2020 elsewhere).
- **MOD16 can exceed P in dry cells:** cells stay signed and only the output is floored at 0, as now.
- **Fixed incumbent:** the incumbent's score is itself the best of #15's candidates on these stations, so it is optimistic, and measuring challengers against it is conservative toward the incumbent. The two-stage nested selection above is reported for that reason.
- **Adoption principle:** MOD16's production code does not ship. It would enter as an input AET (CGIAR's position), not as a discharge product we publish. The issue authorizes shipping it if it wins. If it wins, rebuilding the inputs needs an Earthdata login.

## Phase 1: MOD16 fetcher (tests first)
- [x] Probe (scratchpad): download h10v03 2010 and confirm the `ET_500m` subdataset name, the 0.1 scale, the fill codes and the valid max. List the granules over the grid bbox for 2001–2020 and record the BC tile list, the granule count and the total size in `findings.md`. *(The fill codes are 65529–65535, not 32761–32767.)*
- [x] `tests/testthat/test-wet_mod16_aet.R` uses synthetic sinusoidal tiles (GeoTIFF stand-ins, with the HDF reader and the download mocked). It covers:
  - fill codes are masked and the scale is applied;
  - the per-pixel mean over years honours `min_years`;
  - the two-step reprojection lands exactly on the grid (`compareGeom`, and a constant field comes back exact);
  - `frac_mod16` is the valid share at a gap edge;
  - a missing tile-year stops with a clear error;
  - a cached result comes back without a download or a rebuild.
- [x] `R/wet_mod16_aet.R`, with the signature `wet_mod16_aet(grid, years = 2001:2020, dir = "data/mod16", overwrite = FALSE, timeout = 600, fact = 4, min_years = 10)`. It returns a GeoTIFF with two layers: `et_mod16` (mm/yr, the mean over valid sub-cells) and `frac_mod16` (the valid share, 0–1). Internals:
  - granule listing via a public CMR search, which requires every tile × year to be present *(revised: no `earthdatalogin`; see findings)*;
  - `wet_download()` with the Earthdata netrc to `.part`, then rename, then open the granule before keeping it;
  - a running sum and count per tile in sinusoidal, then a mosaic, then nearest onto `disagg(grid, fact)`, then `aggregate(mean)`;
  - a cache key of grid key + years + `min_years` + `fact` + the md5 of the files read + `wet_mod16_method`.
- [x] ~~Add `earthdatalogin` to Suggests~~ *(not needed: `curl` and `jsonlite` are already imported)*. Add roxygen with `@examplesIf interactive()`, run `devtools::document()`, then run lintr and the tests.

## Phase 2: Inputs and province layers
- [ ] `scripts/wb_inputs.R`: build MOD16 on the CGIAR grid, and add a manifest row (granule count, combined md5) to `data/checks/wb_inputs.txt`.
- [ ] `scripts/wb_province.R`: add `m16` to `f_in` and `compareGeom`, and `R/wet_mod16_aet.R` to `code_files`. Then add two layers:
  - `aet_mod16 = frac·et_mod16 + (1 − frac)·aet_cfu`, with `aet_cfu` wherever frac is 0 or NA, computed after `ex` is masked;
  - `frac_mod16` as a layer (NA → 0 before masking), for the transparency report;
  - `aet_cmod16 = max(aet_yr, aet_mod16)`.

  Append the counts of fully and partly filled cells to `ex_filled_cells.txt`, keeping its existing lines byte-identical. The mask-unmoved assertion then covers the new layers.
- [ ] `wet_wb_aet_cols()`: add `mod16` and `cmod16`, and update `test-wet_wb_raw.R`.
- [ ] Smoke-test with `WET_WB_GROUPS=SALR,OKAN`, then run the full province under `caffeinate -i`. Move the old run to `data/wb_old/`. Check that the #11/#15 layers match the old run exactly (upstream means to about 1e-12 relative) and that the calibration set is the same 290 stations. Do not re-run `wb_stations.R`. The tracked run record goes in `data/checks/wb_province_run.txt`, because `data/logs/` is gitignored.

## Phase 3: Rule and scoring
- [ ] `scripts/wb_aet_compare.R`: change `decide(m, incumbent, eligible)` and the nested selection to take the incumbent and the candidates. Then:
  - **Stage 1** is #15's rule, unchanged. It asserts it still picks `cfu`, and matches #15's numbers (hard-coded to 0.1) in the top table, the nested selection and the fold counts.
  - **Stage 2** is the #18 rule above.

  The report shows both stages. It adds `mod16` / `cmod16` detail rows (zones 15/17/23/24, < 100 km², Greata), the gap-fill counts and the period disclosure. `WINNER` is stage 2's result, and `aet_winner.txt` holds it.
- [ ] Update `wb_validate.R`'s usage line. Commit every `score_files` edit (and `/code-check` it) **before** the 10-variant loop. Run `wb_validate.R` for all 10 variants, then `wb_aet_compare.R`, then `wb_validate.R <winner>`. The tracked record is the `data/checks/` reports.

## Phase 4: Ship and write-up
- [ ] Re-run `scripts/wb_output.R` and `scripts/wb_map.R` on the new key, whichever variant wins (`wb_map.R` always rewrites `research/wb_runoff_annual.png`). If the winner changed, do the cartography self-review and revisit the "1981–2010" legend.
- [ ] `research/water_balance_method.md` §0: add a MOD16 subsection with the results and the attribution (ours, theirs or unresolved). Replace the "MOD16 was deferred" line and update the header line. Also update the `research/README.md` row, and the CLAUDE.md blurb if the shipped AET changes.
- [ ] Edit the issue #18 body with the outcome.

## Validation

- [ ] Tests pass (no network needed)
- [ ] #15's stage reproduces `cfu` and its table on the new key
- [ ] If `cfu` stays, `wb_output.txt` is unchanged apart from the run key
- [ ] `wb_validation_aet-cgiar.txt` unchanged apart from the run-key line
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
