# Code review, round 4: #11 Phase 1 staged diff

Reviewer: subagent, 2026-09-26. Probes were read-only against the cached `data/`, with scratch scripts in the session scratchpad. No repo file was edited apart from this one.

## Round-3 fixes verified

| fix | probe | result |
|---|---|---|
| 1. Zones grid rasterised in memory, then `writeRaster(INT1U)`, key + zip md5 | cached `hydz_…_f369d684.tif`: Byte, NoData=255, `isNA` 1,601,204, min 1, max 29, zero cells 0 | **correct** |
| 2. climr key carries `wet_raster_md5(elev)` | synthetic grids, file and memory | no false hits. Two values-level quirks lead to cache misses only; see finding 3 |
| 3. AET key `sprintf("%.6f", bbox)` | `crop(snap = "out")` on a 1/120 grid, bbox offset from a cell edge | **still collides below 1e-6**; see finding 1 |
| 4. DEM VRT `-vrtnodata -9999` | cached DEM: `isNA` 929,845, min −0.96, max 4396.9, 0 cells < −1000, 61 cells < 0; cells that are NA in the DEM and non-NA in climr: 0 | valid values unchanged, gaps NA. The **doc is still wrong**, and the **key did not change**; see findings 2 and 4 |

Manifest md5s were recomputed for all seven files, and all seven match `data/checks/wb_inputs.txt`.

## Enumeration (re-derived)

A builder's input set is its formals, plus every file, URL, option, package default and code constant it reads.

| artefact | key | inputs that change content | covered? | atomic write |
|---|---|---|---|---|
| CGIAR RARs `data/cgiar/*.rar` | fixed name, md5 against the live figshare API | figshare file | yes, by the md5 check | `.part`, then rename |
| extraction `src/.extracted` | marker | the RARs | yes. The marker is written last, and a missing marker removes `src`. A new figshare version is accepted as out of scope | marker last |
| AET crop `cgiar_aet_<%.6f bbox>.tif` | bbox at `%.6f` | the snapped crop extent, the archives (accepted), datatype INT2U (a constant) | **no, below 1e-6** (finding 1) | tempfile in `dir`, then rename |
| GLO-90 DEM `glo90_<%.3f ext>_<dims>.tif` | ext at `%.3f`, dims, lon/lat enforced | template lattice, the VRT nodata code path, bucket (accepted), `wet.glo90_base` | **lattice offsets under 0.0005° collide** (finding 2); **code change not in key** (finding 4) | tempfile in `dir`, then rename |
| climr normals `climr_<ds>_<y0-y1>_<ext>_<dims>_<md5(years, vars, elev values)>.tif` | dataset, all years, vars in order, ext, dims, DEM values | all of these, plus refmap, climr version and climr's cache (all accepted) | yes, for false hits. An ext collision at `%.3f` is closed by the values md5 unless the DEM is constant | tempfile in `dir`, then rename. The anomaly tempfile is not cached |
| zones zip | fixed name | BC catalogue file | accepted (md5 in manifest) | `.part`, then rename |
| zones shapefile | none | zip | not trusted (re-unzipped with `overwrite = TRUE` every run) | n/a |
| zones grid `hydz_<AET key>_<zip md5[1:8]>.tif` | AET key + zip md5 | AET grid (through its key, which inherits finding 1), zip content, `field`, datatype, projection | yes, apart from finding 1's inheritance and code constants | tempfile in `hydz_dir`, then rename. The tmp is not cleaned on error; that is debris only, never matching a key |
| `data/checks/*.txt` | none | the run | not a cache (tracked, regenerated) | `file(..., "w")`; accepted |

## Findings

- **[fragile] R/wet_cgiar_aet.R:25.** The `%.6f` key still collides for bboxes that crop differently. This is the same defect as round 3's finding 3, one scale down.
  - Measured on a 1/120° grid over −140..−138 with `crop(snap = "out")`:
    - xmin −139 → 60 columns
    - xmin −139 − 1e-7 → 61 columns
    - xmin −139 − 1e-8 → 61 columns
  - terra applies no tolerance at a cell edge. Both −139 − 1e-7 and −139 key to `-139.000000`, so the second call gets the 60-column crop, which does not cover its bbox.
  - Computed bboxes (`floor(x * 10) / 10`, reprojected extents) routinely land within 1e-7 of a cell edge.
  - The driver is safe today only because it rounds the bbox to 0.1°.
  - Any finite decimal encoding of the requested bbox has this hole. The key must be the value that decides the content.
  - **Fix:** snap the bbox outward to the CGIAR lattice (origin −180/90, res 1/120) inside the function. Then use those snapped numbers both for the `crop()` extent and for the key.
  - Distinct lattice extents differ by at least 0.0083°, so `%.6f` of them cannot collide.
  - The zones-grid key is derived from this basename, so it inherits the fix.

- **[fragile] R/wet_dem_glo90.R:243-245.** The DEM key is still the `%.3f` encoding that round 3 retired for the AET crop.
  - Measured: a 120×120 template on −128..−127/54..55, and the same template `shift(dx = 0.0004)`, both key to `glo90_-128.000_54.000_-127.000_55.000_120x120.tif`. The second call returns elevations averaged onto a grid 0.0004° away.
  - Pipeline templates come from the CGIAR crop and sit on the 1/120 lattice. Those differ by at least 0.0083°, so the pipeline is unaffected.
  - The function takes any lon/lat template, though.
  - **Fix:** use `%.6f` for extents of lattice-aligned grids, or key on the exact extent (`sprintf("%.10g")`, or snapped as in finding 1).
  - The climr normals key has the same `%.3f` extent, but it is protected by the DEM values md5 unless the DEM is spatially constant.

- **[low] R/wet_climr_normals.R:204-219.** `wet_raster_md5()` does not do what its comment says: the same values give different keys from a file and from memory. The only effect is cache misses, never a false hit.
  - The comment says "identical grids of values give identical keys whether they came from a file or memory".
  - Measured on a 3×3 grid with one NA:
    - in memory: NA, md5 `8af9b1…`
    - written as INT2S and read back: NA, `8af9b1…`
    - written as FLT4S and read back: the NA comes back as **NaN**, md5 `f10a57…`
  - The cached GLO-90 DEM reads its 929,845 NA cells as NaN.
  - So passing the DEM as a path once, and as the same values in memory once, rebuilds the climr normals: about 320 MB and a climr run.
  - Float values also hash differently at FLT4S and FLT8S precision. That is correct, since they are different values.
  - **Fix:** normalise with `v[is.na(v)] <- NA_real_` before `writeBin()`, or correct the comment.

- **[low] R/wet_dem_glo90.R:238-271 (written data outlives the fix).** The `-vrtnodata` fix changes the DEM's content but not its cache key.
  - The key format is unchanged from round 3. So a `glo90_*.tif` built before this fix, on any machine or in any `dir` other than the one rebuilt here, is returned with ocean gaps as 0, not NA, and nothing warns.
  - Fixes 1-3 all changed their keys (zip md5, DEM md5, `%.6f`), so they invalidated old caches. Fix 4 is the one that did not.
  - Downstream harm is limited. The climr normals are NA over those cells anyway (measured: 0 cells are NA in the DEM and non-NA in climr), so only a consumer that reads DEM NA as a land mask is affected.
  - **Fix:** delete `data/dem/glo90_*` wherever the pre-fix code ran, or add a short format tag to the DEM key (e.g. `glo90v2_`).

- **[low / doc] R/wet_dem_glo90.R:225-227 and man/wet_dem_glo90.Rd.** The doc says "Tiles that do not exist (open ocean) are skipped, so cells with no land are `NA`". That still over-claims.
  - Only cells outside every tile are NA. Ocean inside an existing tile averages to exactly 0.
  - Measured: 392,220 cells are exactly 0. Of those, 338,211 are NA in the climr normals, which is open ocean, and 54,009 are non-NA, which is coastal.
  - A consumer taking `is.na(dem)` as the land mask gets about 30% of the ocean.
  - **Fix:** say "cells outside every GLO-90 tile are NA; sea inside a tile is 0 m".

## Checked and not a finding

- **Zones grid.** Now carries NA (255 flag) and no 0s. `HYDZN_NO` (1-29) fits INT1U. The `.shp` pick is unchanged from round 3, and remains speculative.
- **`wet_raster_md5`.**
  - It ignores dims, CRS and extent: the md5 is the same for a 3×3 and a 1×9 grid with the same values. The filename carries ext and dims, so this is covered.
  - Cell order is terra's fixed row-major order.
  - `elev` is `[[1]]`, so the layer count is irrelevant.
  - Endianness is local-cache only.
- **`vkey` truncated to 8 hex chars (32 bits).** A collision is negligible at this cache size.
- **Order of `vars`.** It is in the key, and it matches the layer order of `out[[vars]]`. Correct.
- **`-vrtnodata` and valid values.** No cell is below −1000, and the min/max are plausible, so no valid value was mapped to NA. GDAL takes srcnodata from the sources, so the flag does not alter values that the sources report.
- **CGIAR sources.** Monthly grids are INT1U with NoData 255 (BC max 112) and the annual grid is INT2S with NoData −32768. Neither is read as a factor despite the RAT (`is.factor` FALSE). Point extracts from the source and the crop agree. The INT2U crop is lossless.
- **Debris.** No `.aux.xml`, `.part` or orphan tempfiles are in `data/`.
- **`stats::` and `tools::`.** The diff newly adds both, and neither is in Imports. `utils::` was already undeclared at HEAD. R CMD check will give a NOTE ("'::' imports not declared"), not a failure, so it is outside this review's bar and only mentioned here.
