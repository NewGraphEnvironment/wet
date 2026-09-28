# Review p12, round 4: two-step land-cover fractions and the resampling sweep

Reviewer: round 4 subagent, 2026-09-27. Scope: `R/wet_landcover_nrcan.R` (two-step
fractions) and its test, plus every raster-to-grid resample or average in the pipeline
that feeds `scripts/wb_province.R`.

## Mechanism

The defect has two layers.

1. **The resampling assumed a footprint that does not hold across CRSs.** A GDAL
   `average` warp builds each target cell's footprint as an axis-aligned box in the
   source CRS. That is exact only when the source and target are the same CRS, or are
   related by an axis-aligned affine map. From EPSG:3979 to lon/lat at -125, the cell is
   a rotated, sheared quadrilateral, so the box takes in the wrong pixels.
2. **The check could not see it because its oracle used the same method.** r2 compared
   the output against a plain `average` warp of a 0/1 raster. That warp carries the same
   footprint assumption, so the two agreed by construction. An oracle has to reach the
   answer by a route that does not share the assumption under test. The new test does:
   `extract(exact = TRUE)` on densified true footprints, reprojected into the source CRS.

So the question for every site below is this: does a raster get **averaged or
interpolated across a CRS change**, and if so, does its test's oracle share the method?

## Enumeration

| Site | Operation | Source CRS to grid CRS | Footprint issue? | Oracle issue? |
|---|---|---|---|---|
| `R/wet_landcover_nrcan.R` `wet_landcover_fractions()` | nearest onto `disagg(grid, 30)` in the grid's CRS, then LUT VRT, then `aggregate(mean)` | 3979 to 4326 (nearest only); the mean is taken within 4326 | **No.** The CRS change happens only at point sampling. Each block mean is over fine cells laid out exactly inside the coarse cell. | **No.** The rotated-stripe test uses exact overlap on densified footprints. The author reports that it fails with the one-step warp restored. |
| `R/wet_terraclimate_aet.R` | monthly sum, then `resample(bilinear)` from 1/24 deg to 30" | 4326 to 4326 | No. Same CRS, axis-aligned, and it interpolates rather than taking footprint means. | The tests use constant fields, so they can check the summing, the grid and NA-gap reweighting, but not the interpolation weights. This is acceptable for a yardstick layer and can't produce a wrong number here. |
| `R/wet_dem_glo90.R` | VRT at the highest resolution, then `project(average)` to 30" | 4326 to 4326 | No. In the same CRS, an axis-aligned box is the true footprint. The 4.5"/6" tiles resampled to 3" in the VRT give neighbouring source pixels unequal weights (1 or 2 copies). For a smooth elevation field this is noise, not bias. | n/a |
| `R/wet_climr_normals.R` | climr samples its lon/lat refmap at the DEM grid's cell centres and applies lapse rates | 4326 to 4326 | No. Point sampling in the same CRS. | n/a |
| `R/wet_cgiar_aet.R` | `crop(snap = "near")` on the native 30" grid | none | No. It defines the grid and is never resampled. | n/a |
| `scripts/wb_inputs.R` zones | `rasterize(project(hz, 4326), grid)` by cell centre | vector 3005 to 4326 | No. Vertices are reprojected, not a raster. The zones are categorical and assigned by cell centre. | n/a |
| `scripts/wb_province.R` `in_bc` | `rasterize(project(dissolved fwa_bcboundary, 4326), cover = TRUE)` | vector 3005 to 4326 | No. Reprojecting vertex by vertex bends straight edges only when edges are long. I measured the boundary in fwapg: the longest segment on the outer boundary is 17 km (on the Alaska panhandle), and the 99.99th percentile is 1.15 km. The chord error on those is metres against about 925 m cells. (One 815 km "segment" in the raw dump was a jump between rings and lies on no boundary.) The layer is only thresholded at 0.5 or area-weighted. | n/a |
| `R/wet_ws_sample.R` area method | `extract(exact = TRUE)` of FWA polygons reprojected to 4326 | vector 3005 to 4326 | No. The exact overlap is computed against the true (reprojected) polygon. Weighting by the fraction of a lon/lat cell ignores the cos(lat) area change, but only within one fundamental watershed, so the error is negligible. | n/a |
| `R/wet_aet_landcover.R` | `zonal(mean)` on the same grid | none | No. | n/a |

## Checks on the two-step implementation

- **NoData through INT1U `NAflag = 0`, then the LUT.** Source NoData (0) and ground beyond
  the source become NA in `project()`, which is written as 0. The VRT band declares no
  NoDataValue, and a ComplexSource without `<NODATA>` passes the raw 0 through
  `LUT 0:0`. So uncovered ground is 0, not NA. Test 1's no-data cell pins this
  (`rowSums == 0`, `!anyNA`). The live NRCan file is `Byte`, `NoData Value=0`, which is
  consistent with this.
- **Can `aggregate(mean)` on the VRT treat 0 as NA?** No. The VRT band has no NoData, and
  the test above covers it.
- **Alignment.** `disagg(grid, fact)` keeps the extent with exactly `fact` times the rows
  and columns. The VRT GeoTransform is written from the fine file's extent at `%.17g`,
  and `aggregate(fact)` returns exactly the grid's dimensions. `compareGeom()` guards it.
- **Nearest sampling at 1" against the 30 m source.** At 49-60 N, 1" is about 31 m
  north-south and 15-20 m east-west. That is regular point sampling at or above the
  source density, so it adds only aliasing noise, not bias. The 0.002 mean absolute
  difference the author measured against exact overlap agrees with this.
- **Scale.** The fine grid is 42,840 x 90,360, about 3.9e9 cells, in INT1U with LZW. The
  live build (pid 64987) is writing it into `data/landcover/` and was at 23 MB at
  17:28 PDT. `aggregate` works in row chunks, so memory is bounded.

## Clean

I found no failures, wrong numbers or stale cache content.

One efficiency note, not a correctness finding. `terra::disagg(grid, fact)` is called on
`grid[[1]]`, which has values (the CGIAR `aet_yr` layer). terra therefore computes and
writes the full fine grid of values before `project()` uses only its geometry.

- I confirmed this live. The running build left
  `$TMPDIR/Rtmpx1znOY/spat_fddb49ca9d1d_*.tif`, 90360 x 42840 Float32, 263 MB with LZW.
  At province scale terra's `mem_info` says it needs 28.8 GB, which does not fit.
- The cost is one extra pass over about 3.9e9 cells, plus temp disk.
- `terra::disagg(terra::rast(grid), fact)` gives the same geometry with no values. I
  checked this: `compareGeom` is TRUE and `hasValues` is FALSE.
