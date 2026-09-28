# Code-check round 1: wet_mod16_aet (#18)

Reviewer: subagent, 2026-09-27. Scope: the staged diff (R/wet_mod16_aet.R, R/wet_cgiar_aet.R's `netrc` arg, tests, Rd, NAMESPACE, planning files), read against the full checklist.

## Findings

- **[fragile]** R/wet_mod16_aet.R:115-120 (`wet_modis_tiles()`, the `terra::relate(p, tp, "intersects")` test). A grid whose north or south edge sits on a multiple of 10 degrees of latitude also selects the tile row beyond it, which contributes no cells. The cause is that `wet_modis_tile_m` is exactly R times 10 degrees in radians, so the parallels at 40, 50 and 60 N project onto tile edges to within float noise. The projected extent then overlaps the next row by a sliver. Measured on a scratch copy:
  - `ymax = 60` (BC's northern border), lon -125 to -115, also selects h11v02 and h12v02;
  - `ymax = 50`, lon -120 to -119, also selects h10v03.

  An interior-only pattern (`"T********"`) selects the same tiles, so the sliver is a real positive-area overlap in floating point, and changing the predicate does not fix it. The values are unaffected, because the extra tiles land on no cell. The cost is every tile-year of each extra tile: 40 granules, about 870 MB, for `ymax = 60` over 2001-2020. It becomes a hard stop in `wet_mod16_check()` if a touched tile has no land granule. The shipped provincial grid (ymax 60.1) is not affected, and neither is the roxygen example (ymin 50 happens to floor the other way). Fix: test the overlap with a tolerance well under a pixel, for example by shrinking `tp` by about 1 m before `relate()`, or by requiring the intersection to exceed a small area. Then add `ymax = 60` and `ymax = 50` grids to the tile test. The existing 50.0119 N case keeps its 1.3 km overlap, so it is unaffected.

No other issues found.

## Checked and clean (measured, not only read)

- Tests: in a scratch copy of the repo, `test_file()` gave 37 expectations, 0 failed, 0 errors, 0 skipped. `mock_read()` stubs the search and the download to error, and the two netrc tests set the option, so no test reaches the network or the real netrc.
- CMR (one public GET, bbox -120,50.5,-119,51, 2010-2011): the `cmr-hits` header is present, and `curl::parse_headers_list()` lowercases it, as verified offline. Each entry has exactly one https `.hdf` link matching the regex. The second https lp-prod-protected link is the `.cmr.xml` file, and the regex rejects it. The time range is Jan 1 to Dec 31 23:59:59, so the year filter is exact.
- `wet_download()` with `netrc = wet_earthdata_netrc()`, run live: `wet_earthdata_netrc()` resolved to the earthdatalogin file and the download followed the URS redirect, 21.7 MB, status 200. `wet_mod16_read()` then passed (scoff 0.1/0, 2400 x 2400). The file went to the scratchpad and has been deleted. `data/mod16/` was not touched; it has a live `.part` from the running pipeline.
- The scaled gap codes in h10v03 2010 are 6553.0-6553.4 and nothing lies between 6550 and 6552.9, so `> 6551` masks exactly the gap codes. The counts match findings.md.
- The 3000 mm plausibility guard: across the 45 cached granules (2001-2005, 9 tiles), the valid maximum after masking is at most 1373.9 mm. The guard cannot false-fire on this data.
- Mosaic: the 9 real 2001 tiles share one CRS string and one resolution (463.3127 m), and their origins match `wet_modis_ul + k * wet_modis_tile_m`. `terra::merge(sprc())` gives a clean 7200 x 12000 mosaic.
- Cache key: `wet_grid_key` (ext, dims, crs) plus years, `min_years`, `fact`, the md5 of every granule read and `wet_mod16_method`. It covers every input that affects the output. Both the result and `.part` are written to a temp file and renamed, and both `file.rename()` return values are checked.
- A 200 that is not a granule is opened, deleted and refused, which is the right direction for that guard. The `wet_download()` change leaves the figshare path unchanged when `netrc = NULL`.
- The `.part`, result and temp files cannot match `wet_mod16_local()`'s regex.
