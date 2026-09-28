# Code-check round 3: wet_mod16_aet (#18)

Reviewer: subagent, 2026-09-27. Scope: the staged diff (`R/wet_mod16_aet.R`, `wet_download(netrc =)` in `R/wet_cgiar_aet.R`, tests, Rd, NAMESPACE). Everything ran in a scratch copy holding the staged versions of the files. The repo and `data/` were not touched. Two public CMR GETs were made for the footprint check below. No test reaches the network.

## Clean

No new issues found.

## The mechanism behind rounds 1 and 2

Both earlier defects come from one design choice. The tile set is decided by a second, hand-rolled coordinate conversion of the grid's **extent**: the MODIS constants (`wet_modis_ul`, `wet_modis_tile_m`, R) plus a `project()` of the extent polygon. It is not taken from the pixels the resampler will actually read, which are the `project(method = "near")` samples at the centres of `disagg(grid, fact)`.

That conversion carried two preconditions that nothing stated or checked:

- the extent's numbers are degrees (round 2's defect);
- a projected coordinate lands strictly on one side of a tile edge (round 1's defect, since 40, 50 and 60 N project onto tile edges to within float noise).

Nothing downstream compares the selected tiles with the pixels that are sampled, and the two ways a mismatch can go fail differently:

- **Too many tiles** is loud or cheap: extra downloads, or a stop in `wet_mod16_check()`.
- **Too few tiles** is silent. A missing tile's pixels come out `NA` after `project()`, which lowers `frac_mod16` exactly as water or ice would. `wet_wb` then fills the cell from `aet_cfu`. No guard sees it: `compareGeom` passes, and the value range looks normal.

So the safety question at every place below is whether under-selection is possible.

## Every place the mechanism reaches

| # | Where | Status |
|---|---|---|
| 1 | `wet_modis_tiles()` h/v candidate range (`floor` on both ends of the projected extent) | **Safe.** A superset by construction: a boundary value floors into the next tile, and `relate()` then filters it out. |
| 2 | `wet_modis_tiles()` 1 m shrink before `relate()` | **Safe** whenever half a fine cell is more than 1 m, i.e. `res / (2 * fact)` > 1 m. For 30″ with `fact = 4` that is about 65 m; for 0.1° with `fact = 20`, about 150 m. A tile holding a sampled centre therefore has grid area more than 1 m deep around it and is kept. Under-selection would need fine cells under about 2 m, which is not a realistic input for a 500 m product. Round 2 found 0 misses in 300 random grids. |
| 3 | `densify(p, 0.01, flat = TRUE)` | **Safe.** A 0.01 is only meaningful in degrees, and that is now guarded. The meridian chord sags about 4 cm, well under the 1 m tolerance. |
| 4 | `is.lonlat()` guard | **Safe.** It returns TRUE for any geographic CRS, including a non-WGS84 datum (NAD83, NAD27). Tile selection and sampling both project with the datum, so they agree. Only the CMR bbox (item 5) reads the numbers as WGS84. NAD27 is about 100 m off in BC, so at worst a tile reached by 1–100 m is missing from CMR's answer, and `wet_mod16_check()` then stops loudly. It never under-selects silently. |
| 5 | `wet_mod16_search()` CMR `bounding_box`, a third derivation based on CMR's great-circle GPolygon footprints | **Safe for BC, measured.** For the 9 BC tiles (2010 granules, BC bbox), 20,001 points were placed on each side of the true sinusoidal boundary and tested against the CMR polygon with `s2`, whose geodesic edges are CMR's model. The largest excursion outside the footprint was 0.084 m (h12v02), and 0.013–0.026 m elsewhere. The one exception was h11v02: 143 m at the antimeridian near 67 N, far from BC. Two other effects are also well under the 1 m shrink: CMR's footprints hug the true west edges to within about 0.2 mm in places, and the `%.6f` bbox rounding moves the bbox by about 0.1 m. So every tile selected by more than 1 m of overlap comes back from CMR, and any miss would be loud anyway. A direct probe (a bbox at 50.0–50.1 N, -117 to -116.5) returned h10v03, even though a naive 4-corner great-circle bottom edge would bow to about 50.26 N there. CMR pads its corners by 0.2–0.5°. |
| 6 | Hard-coded MODIS constants vs the HDF georeferencing | **Safe.** Rounds 1 and 2 measured the real tiles' origins against `wet_modis_ul + k * wet_modis_tile_m` (within mm). The per-tile rasters are mosaicked from each file's own georeferencing, not from the constants. |
| 7 | `wet_mod16_grid()` mosaic, then `project(near)`: where under-selection would surface | **Safe given items 2 and 5.** It has no guard of its own, and that is the silent direction described above. It is noted here, not flagged, because no realistic input reaches it. |
| 8 | Cache key | **Safe.** The md5 list follows the selected tile set, so a change in selection changes the key even without a `wet_mod16_method` bump. |
| 9 | `tiles_oracle()` in the tests uses the same MODIS constants | **Acceptable.** The constants were verified against the real HDFs (item 6), so the oracle does not merely read back the selection's own assumption. |

## Also checked

- Tests (staged files in the scratch copy, `NOT_CRAN=true`, `test_file`): 40 PASS, 0 FAIL, 0 SKIP, 0 WARN.
- `devtools::document()` in the copy regenerates `man/wet_mod16_aet.Rd` and `NAMESPACE` byte-identical to the staged versions.
- `wet_download(netrc =)`: `netrc = 1L` (optional) and credentials are scoped per `machine`, so they reach only urs.earthdata.nasa.gov across the redirect chain. The figshare path is unchanged when `netrc = NULL`.
- `wet_mod16_search()` with zero hits: the empty `entry` gives a 0-row frame, and `wet_mod16_check()` then stops loudly. With more than 2000 hits, the `cmr-hits` guard stops.
