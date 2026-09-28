# Findings — MOD16 AET as a challenger to the shipped annual AET (#18)

## Issue context

**If we do it:** the one ET product #15 deferred gets scored. If it beats what ships (`max(CGIAR, Fu–Budyko)`), it replaces it, especially on the dry interior plateaus, where zone 24 still runs +102 %. **If we never do:** #15's comparison stays one product short, and "MODIS would have done better" remains an untested claim.

## Problem

#15 deferred MOD16A3GF v061 (LP DAAC, annual ET, 500 m, from 2000) because it needed an Earthdata login. That's now set up through `earthdatalogin`: a test tile (h10v03, 2010) downloads and reads, with ET in mm/yr and fill codes for water, barren, snow and urban. MOD16 is Penman–Monteith on MODIS land cover and LAI, not capped by a coarse precipitation field, so it's the independent AET #15 lacked.

## Proposed Solution

- **Fetcher:** `wet_mod16_aet(grid)`, following `wet_terraclimate_aet()`. It fetches the BC tiles for every year it averages, masks the fill codes, averages the annual ET, reprojects from sinusoidal with the two-step method from #15 (average in the target CRS, not across a rotation), and carries a method version in its cache key.
- **Gap cells:** these take the shipped AET, and their count is reported.
- **Scoring:** challenger variants `mod16` and `max(CGIAR, mod16)`, scored with `scripts/wb_validate.R` and compared under #15's rule with the shipped variant as the incumbent. That means the same 2-point headwater margin, the nested-basin guards and the fully nested selection. The rule is fixed here before any scoring.
- **Period (disclosed):** 2001–2020, 20 complete years with the most overlap with the gauge record. The rest of the model is on 1981–2010 normals.

Relates to #15


## Exploration (2026-09-27)

- Template fetcher: `R/wet_terraclimate_aet.R`; two-step reprojection: `R/wet_landcover_nrcan.R`.
- `scripts/wb_aet_compare.R` hard-codes cgiar as incumbent; it is in `score_code_md5`, so any edit forces a rescore of every variant (the new province key forces it anyway).
- #15 rerun chain: ~4 min per variant, ~6 min compare (`data/logs/20260928_run15c.log`).
- Earthdata login: earthdatalogin netrc (see memory); `earthdatalogin` not in DESCRIPTION.

## MOD16A3GF v061 probe (2026-09-27)

- `ET_500m` is UInt16 with `valid_range=0, 65500`, `scale_factor=0.1`, `_FillValue=65535`, units kg/m²/yr (= mm/yr). terra applies the scale on read (`scoff` 0.1/0), so values come back in mm. The HDF4 subdataset is `HDF4_EOS:EOS_GRID:"<f>":MOD_Grid_MOD16A3:ET_500m`, 2400 × 2400, 463.3127 m, on the sinusoidal sphere R = 6371007.181.
- The gap codes (MOD16 v6.1 user guide, lines on MOD16A3/A3GF): 65529 unclassified, 65530 urban, 65531 permanent wetland, 65532 perennial snow/ice, 65533 barren/sparse, 65534 water/salt, 65535 fill. The plan's 32761–32767 are the int16 MOD16A2 codes. In h10v03 2010: 65530 3,611 px; 65531 6,556; 65532 281,957; 65533 8,668; 65534 2,448,044 (ocean and off-globe). The valid range in that tile is 182.5–1281.8 mm.
- **CMR** (public, no login): 240 granules for the BC grid bbox over 2001–2020, one per tile-year, for 12 tiles. Three of them (h08v03, h20v01, h23v02) never touch the grid, because CMR's bbox match is loose. `wet_modis_tiles()` gives 9: h08v04, h09v03, h09v04, h10v03, h10v04, h11v02, h11v03, h12v02, h12v03. That makes 180 granules at about 21.7 MB, about 3.9 GB.
- **Download:** `curl` with `netrc = 1, netrc_file = <earthdatalogin netrc>, cookiefile = ""` follows the URS redirect and returns a byte-identical file in about 5 s. `earthdatalogin` is not used: `edl_search()` and `edl_download()` call `edl_netrc()` with its shared default login whenever they do not find a netrc entry, and that overwrites the real one (memory: earthdata-login). `curl` and `jsonlite` are already imported.
- **`terra::densify()` on lon/lat follows great circles.** A raster's extent has parallels for edges, and a 5.5° top edge at 50 N bows about 0.03° north when densified geodesically. That wrongly added h10v03 to a grid topping at 49.98 N. The fix is `flat = TRUE`. Over 600 random extents, planar-densified, undensified and a 360 k-point sample oracle all agreed, so the planar densify is hygiene and has no known case. The great-circle bug is pinned by a test.

## MOD16 build and province smoke (2026-09-28 UTC)

- `wet_mod16_aet(<CGIAR grid>)`: 180 granules (9 tiles × 20 years) in 13.8 min, giving `data/mod16/mod16_2001_2020_9ca6be3764.tif`. ET is 183–786 mm/yr (mean 410).
- **Over BC** (in_bc ≥ 0.5, CGIAR valid; 1.91 M cells): mean MOD16 cover is 0.926, and 4.7 % of cells have none (water, ice, barren). On fully covered cells MOD16 averages 409 mm against CGIAR's 430 mm, correlation 0.67. At the Greata Creek area (-119.85, 49.75) MOD16 gives 429 mm against CGIAR's 266 mm: higher in the dry interior, the direction #15 needed.
- **Smoke** (`WET_WB_GROUPS=SALR,OKAN`, run key 711a9d102f): every column of the #15 run (495b33ec47) is identical in both groups, `cover` included, so the mask did not move. The new columns `aet_mod16`, `aet_cmod16` and `frac_mod16` have no NA where the #11 layers have values. `ex_filled_cells.txt` keeps its nine lines byte-identical and added three MOD16 lines, labelled "full" 137,890, "partial" 179,665 and "gap" 208,815.4. "full" was in fact the count of cells with **no** MOD16 (frac 0). Code-check measured the smoke layers.tif and found 2,124,695 cells with frac 1. The code now writes `mod16_whole`, `cfu_whole`, `cfu_part` and `cfu_cell_equivalents`, and the full run's file is the record. The smoke directory was deleted when the relabel changed the run key.

## Compare dry run against the #15 run (2026-09-28 UTC)

This was a scratch copy with mod16 and cmod16 stood in by cfu's scores, the md5 check relaxed, and no tracked or winner file written (their md5s were checked unchanged afterwards).
- **Stage 1 reproduces #15 exactly.** The top table matches, (a)-(c) pick cfu, the nested selection gives 32.3 / 28.6 / 17.3 / 70.8, and the folds give fu 6 / cfu 87. The reproduction assertion passed.
- **Stage 2 with challengers identical to cfu:** (a)-(c) keep cfu, all 93 folds pick cfu, and the nested headwater MAE is **33.2**, against cfu's as-shipped 31.2, so (d) fails.
- **The plan review's R1 premise is false.** It held that a fold picking cfu reproduces cfu's shipped predictions. It does not: each fold's inner gate (adjust or raw) and pooled variant are chosen on its own training stations.
- **(d), against the as-shipped score, is therefore about 2 points stricter** than comparing nested with nested. The rule is kept as approved, because it is the same form #15 used against cgiar and no MOD16 score exists yet. The report adds cfu alone under the nested procedure, so the bar is visible.

## Full province run (2026-09-28 UTC; key adc88b19c8)

- `wb_inputs.R` in 37 s: every input was cached, the manifest was rewritten with the MOD16 rows, and climr vs ECCC is unchanged (MAP ratio median 1.034). `wb_province.R 4` took 13.5 min. Its record is `data/checks/wb_province_run.txt`.
- **Reproduces #15** (`data/wb_old/495b33ec47`):
  - all 53 old layers in `layers.tif` are identical;
  - all 24 upstream basin files hold the same watershed set;
  - every old column agrees within 5.4e-14 relative after matching by `watershed_feature_id`.
  - **Row order differs between runs**, because the watershed query has no ORDER BY. The first verifier compared by position and stopped the chain; everything downstream joins by id.
- **MOD16 cover on the analysis mask:** `mod16_whole` 2,124,695 cells, `cfu_whole` 137,890, `cfu_part` 179,665, and 208,815 cfu cell-equivalents (8.5 % of 2,442,250 cells).

## Scoring and the decision (2026-09-28 UTC; chain log data/logs/20260928_chain18b.log)

- 10 × `wb_validate.R` at about 4 min each, `wb_aet_compare.R` 9.8 min, then ship, output and map, for 06:02–06:55 UTC in all. Report: `data/checks/wb_aet_compare.txt`.
- **Stage 1 reproduces #15 exactly**, so the assertion passed: cfu at 31.2 / 27.7 / 17.4 / 70.8, nested 32.3, and folds fu 6 / cfu 87.
- **Stage 2: cfu stays.**

| AET | Headwater | All 290 | Nested | Nested ±20 % | Raw headwater |
|---|---|---|---|---|---|
| cfu (incumbent) | 31.2 | 27.7 | 17.4 | 70.8 | 31.6 |
| mod16 | 36.3 | 31.4 | 16.5 | 75.0 | 40.5 |
| cmod16 | 34.6 | 30.4 | 17.7 | 69.4 | 36.3 |
| cgiar (reference) | 38.1 | 33.1 | 17.9 | 72.2 | 39.8 |

- **(a)** fails for both: they are 5.1 and 3.4 points *above* cfu, where the rule needed 2 below. In the nested selection all 93 folds chose cfu (33.2 against 31.2, fail).
- **Not the gap fill.** On the 200 headwater basins that are at least 80 % MOD16: cfu 31.9, mod16 37.5, cmod16 35.6. Station basins are mostly MOD16 (quartiles 0.94 / 0.99 / 1.00; min 0.18).
- **Semi-arid zones, mean error as shipped:**

| Zone | cgiar | cfu | mod16 | cmod16 |
|---|---|---|---|---|
| 17 | +56 | +48 | +108 | +48 |
| 23 | +57 | +20 | +45 | +44 |
| 24 | +231 | +102 | +166 | +165 |
| < 100 km² MAE | 61 | 44 | 55 | 52 |

  - **Greata Creek:** upstream AET is 281 with cgiar, 499 with cfu and 419 with mod16; P 743 and observed 50 imply about 693.
- **MOD16 improves on CGIAR but not on the Budyko floor.** Its nested-basin error is the best of the three (16.5, and 75 % within ±20 %), so it does well on large basins.
- **Other tracked reports changed only by run key**, apart from ordering:
  - `wb_validation*.txt` list the pooled zones 16 17 12 rather than 16 12 17, and the coefficient table's row order moved. The zone columns are ordered by first appearance, which follows the unordered watershed rows. The same set of zones, and byte-identical lines otherwise.
  - `wb_output.txt` changed by the run key only.
  - `research/wb_runoff_annual.png` is byte-identical.

## Plan review (2026-09-27)

`review-plan.md` has every finding and its disposition. The rule was clarified before any MOD16 variant was scored: the (d) threshold, the frozen knobs, the transparency rows and the disclosures.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| A test downloaded a real granule: the stripe grid touched h11v03, the fixture had only h10v03, and `wet_mod16_aet()` searched and fetched with the real netrc | Moved the grid inside h10v03. `mock_read()` now stubs search and download to error, so a forgotten tile fails the test instead of reaching the network |
| `terra::densify(p, 1000)` over-included a tile (great-circle edges) | `densify(p, 0.01, flat = TRUE)` |
| The chain's verifier stopped at `identical(watershed_feature_id)` | Upstream rows come back in a different order each run (no ORDER BY). Compare by id: they reproduce within 5.4e-14 |
