# Code review, round 3: #11 Phase 1 staged diff

Reviewer: subagent, 2026-09-26. The probes ran against the cached `data/` read-only, and in the session scratchpad. No repo file was edited apart from this one.

## Mechanism

The stated mechanism is "a cache that trusts a file whose name does not encode every input, or whose write is not atomic". The atomic half is now closed: every cached write goes through a same-directory tempfile or `.part` followed by a rename.

The key half is still open, because the keys are hand-picked lists of the call's parameters. Rounds 1 and 2 each found the next parameter (`vars`, then the full `years`). Two kinds of input are still missing:

- **Upstream data contents.** A downstream cache is keyed on the grid or name of its upstream file, not on what the file contains. So a rebuilt or replaced upstream never invalidates it.
- **A lossy encoding of a parameter.** `format()` keeps 7 significant digits and follows `options(digits)`. The key then stands in for the bbox without being the value that decides the content, which is the extent after the crop snaps out to the grid.

To terminate this by enumeration, a builder's input set is its formals, plus every file, URL, option and package default it reads. The table lists that set for each cache.

| artefact | key | inputs that change content | atomic write | verdict |
|---|---|---|---|---|
| CGIAR RARs `data/cgiar/*.rar` | name | figshare file | `.part`, then rename; md5 checked against the live API | sound |
| CGIAR extraction `src/.extracted` | marker | the two RARs | a marker written after both extractions; a missing marker removes `src` | sound. The RARs are re-fetched only in the no-marker branch, so the marker cannot outlive them. |
| AET crop `cgiar_aet_<bbox>.tif` | `format(bbox, nsmall = 3)` | the snapped extent; the archives (by design) | tempfile, then rename | **lossy key**, finding 3 |
| GLO-90 DEM `glo90_<ext>_<dims>.tif` | ext (`%.3f`) + dims; lon/lat enforced | template grid, `wet.glo90_base`, bucket contents | tempfile, then rename | sound for the grid. The base URL and the bucket version are accepted. |
| climr normals `climr_<ds>_<y>_<ext>_<dims>_<md5>.tif` | dataset, years, vars, ext + dims | **the DEM's values**, plus the refmap default and the climr version | tempfile, then rename | **missing input**, finding 2 |
| zones zip `bc_hydrologic_zones.zip` | fixed name | the BC catalogue file | `.part`, then rename | stale on an upstream change. The manifest md5 records it; accepted. |
| zones shapefile `data/hydz/BC_Hydrologic_Zones/` | none | the zip | unzipped with `overwrite = TRUE` on every run | sound, since it is not trusted |
| zones grid `hydz_<bbox>.tif` | the AET basename | the AET grid, **the shapefile's contents**, `field`, datatype | tempfile, then rename | stale if the zip is refreshed (same class as finding 2); the **content is wrong**, finding 1 |
| climr's own cache (`climr::cache_path()`: refmap and obs tiles) | climr's | climr's database | climr's | **missing from your enumeration.** It feeds the normals and the ECCC check, so a stale climr cache propagates into both, and `overwrite = TRUE` in wet does not refresh it. |
| `data/checks/*.txt` | none | the run | `file(..., "w")`, not atomic | not a cache: the reports are tracked and regenerated every run |

## Findings

- **[bug] scripts/wb_inputs.R:63-64.** The zones grid has no NA. Cells outside every zone, which is the ocean and ground beyond the extended layer, are written as the value **0**.
  - Measured on the cached `data/hydz/hydz_-139.100_48.200_-114.000_60.100.tif`: 1,601,204 cells are 0 and `isNA` is 0.
  - GDAL reports NoData=255, but no cell holds 255. `HYDZN_NO` runs 1-29 in the shapefile, so 0 is not a zone.
  - The cause is `terra::rasterize(..., filename = tmp, wopt = list(datatype = "INT1U"))` (terra 1.9.46).
  - Measured on a 216 x 252 window at the SW corner:
    - rasterize to a file with the default datatype: 54,432 NA
    - rasterize in memory, then `writeRaster(datatype = "INT1U")`: 54,432 NA
    - rasterize with `filename` + `wopt = list(datatype = "INT1U")`, even with `NAflag = 255`: **0 NA**, all 0
  - Effect: in Phase 2+, an `is.na()` land or zone mask covers nothing, and any tabulation by zone gains a 37% "zone 0". The tracked manifest md5 `432a538e…` is this grid.
  - Fix: rasterize in memory, then `writeRaster(tmp, datatype = "INT1U")`, then rename. The fix will not reach the cached file, because the cache key is unchanged, so delete `data/hydz/hydz_*.tif` and rerun the script.
  - This looks like a terra defect (`rasterize` straight to file with `INT1U` initialises the background to 0). By the house rule it should be filed upstream, with this repro, not only worked around.

- **[bug] R/wet_climr_normals.R:37-44.** The cache key encodes the DEM's extent and dims, but not its values, and the elevation is what drives the lapse-rate downscaling.
  - Any two DEMs on the same grid share one cache file. For example, a flat 600 m DEM (the fixture the tests use) followed by the real GLO-90 on the same grid and `dir` returns the flat-DEM normals without comment.
  - In the pipeline: `wet_dem_glo90(overwrite = TRUE)`, or a DEM rebuilt after a fix, or a different DEM source, leaves `wet_climr_normals()` returning the normals built on the old DEM.
  - This is the mechanism one level up: the downstream key names the upstream's grid, not its content.
  - Fix: fold `tools::md5sum()` of the DEM file into `vkey`. For an in-memory `SpatRaster`, write it to a tempfile first, or refuse to cache. The GLO-90 grid is about 17 MB, so hashing it is cheap.

- **[fragile] R/wet_cgiar_aet.R:22-23.** `format(bbox, nsmall = 3, trim = TRUE)` is a lossy key, and it depends on a session option.
  - `format()` keeps `getOption("digits")` (7) significant digits across the vector, so `c(-139.00001, 48.2, -114, 60.1)` and `c(-139, 48.2, -114, 60.1)` both key to `-139.000_48.200_-114.000_60.100`. Measured.
  - The two crops differ. With `snap = "out"`, -139.00001 takes one more 1/120 degree column, because -139.0 is a CGIAR cell edge.
  - The second call therefore gets back a crop that does not cover its bbox. `-139.12341` and `-139.12344` collide the same way.
  - Under `options(digits = 4)` the same bbox keys differently (`-139.123` against `-139.1234`), and more distinct bboxes collide.
  - The driver rounds to 0.1 degrees, so it is unaffected today.
  - Fix: key on what decides the content, which is the snapped extent (`terra::align()` / `%.6f` of the crop extent), or on `sprintf("%.6f", bbox)`.

- **[fragile] R/wet_dem_glo90.R:4-6.** The doc says cells with no land are `NA`, but they are **0**.
  - Measured on the cached `data/dem/glo90_…_1429x3013.tif`: 0 NA and 1,322,065 cells equal to 0, and the sampled open-ocean points are all 0.
  - `terra::vrt()` over COGs with no nodata fills the missing-tile gaps with 0.
  - Downstream is unaffected today: the climr normals are NA over the ocean anyway (the refmap has no ocean; measured at 3 points). A consumer that takes the DEM's NA as a land mask gets no mask.
  - Fix: set a VRT nodata (`terra::vrt(urls, options = c("-vrtnodata", "-9999"))`), or correct the doc.

## Checked and not a finding

- The ECCC queries are not truncated by `limit`. Measured `numberMatched`: 163 PPT normals, 145 T normals and 1,762 stations, and a full station call returns all 1,762.
- Every cached write uses a tempfile or `.part` in the destination directory, so the rename stays on one filesystem. After a crash the tempfiles are debris, but none of them matches a cache key. The zones `tmp` has no cleanup on error, because it is at script top level; that is debris only.
- `wet_climr_normals()` has the same ext + dims key as the DEM but no lon/lat guard. A projected DEM fails inside climr (`get_bb` returns metres) rather than colliding in the cache, so this is not a cache hazard.
- Re-reading `list.files(hz_dir, "[.]shp$", recursive = TRUE)[1]` on every run could pick up a stale shapefile only if a future zip renamed its layer. That is speculative, so it is not raised.
