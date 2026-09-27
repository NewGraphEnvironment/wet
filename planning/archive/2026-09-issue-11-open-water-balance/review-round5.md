# Code review, round 5: #11 Phase 1 staged diff

Reviewer: subagent, 2026-09-26. Probes ran in a scratch copy of the tracked and staged tree, and against the cached `data/` read-only. The only repo file written is this one.

The three new test files pass in the copy with `NOT_CRAN=true`: `cgiar_aet` 8 tests, `dem_glo90` 6, `climr_normals` 6. That includes the live climr point-parity test. There were no failures and no skips.

## Content-as-function-of-key table

**Notation.** `C = (c0, c1, r0, r1) = wet_cgiar_cells(bbox)`. `S` is the extracted CGIAR source, and `G(r)` is the full-precision (extent, nrow, ncol, CRS) of a raster.

**Accepted inputs** (the manifest records their md5s and versions):

- the figshare CGIAR version
- the GLO-90 bucket contents and `tileList.txt`
- the climr version, its refmap and its own cache
- the terra and GDAL versions. These are not on the brief's list, but they are the same kind of input as the climr version.

| artefact | content = f(...) | key | inputs outside key (non-accepted) | same key, different content? |
|---|---|---|---|---|
| RARs `data/cgiar/*.rar` | figshare file | fixed name, md5 vs live figshare on every extraction | none | no. The md5 is re-checked before any extraction; the file is downloaded to `.part` and renamed on 200 |
| `src/` + `.extracted` | f(RARs) | marker presence | none | only if the RARs change after extraction, which is an accepted figshare version change |
| AET crop `cgiar_aet_c<c0>-<c1>_r<r0>-<r1>.tif` | `crop(S, ext(-180 + c/120, ...), snap = "near")`, INT2U, fixed names | `C` | code constants only (INT2U, layer names, `res`) | **no**. The extent is computed from `C`, not from `bbox`, and the mapping from nominal edge to source edge is a bijection (see below) |
| GLO-90 DEM `glo90v2_<md5(G)[1:12]>.tif` | `project(vrt(tiles(ext(G))), G, "average")`, `-vrtnodata -9999`, FLT4S | `G` at `%.17g` + CRS proj string, `v2` code tag | `getOption("wet.glo90_base")`: only tests set it, and it is a different source rather than a different grid | no, apart from the base option |
| climr normals `climr_<ds>_<y0>-<y1>_<md5(G)[1:8]>_<md5(years, vars, values)[1:8]>.tif` | `downscale_core(elev values on G, refmap(G), mean anomaly(ds, years), vars)` | ds (raw), all years, vars in order, `G`, elev values (NaN → NA) | none | no. The filename parses uniquely from the right, since `%d-%d` and hex contain no `_`; vars cannot contain `,` or `\|` (they are regex-validated), so the vkey string is injective |
| zones zip | BC catalogue file | fixed name | none (accepted, manifest md5) | n/a |
| zones grid `hydz_<C>_<zipmd5[1:8]>.tif` | `rasterize(project(shp), AET grid(C), HYDZN_NO)`, INT1U | `C` + zip md5 | **which `.shp` `list.files(hz_dir)[1]` returns** | **yes, conditionally**. See finding 1 |
| `data/checks/*.txt` | the run | none (tracked report) | n/a | not a cache. The md5s of all 7 manifest files were recomputed and match |

So the termination condition holds for the AET crop, the DEM (by its grid) and the climr normals. It holds for the zones grid except in the case in finding 1.

### Round-4 fixes verified

**Lattice math.**

- Probe: every edge k in 0..43200 (x) and 0..18000 (y), under four float constructions (`-180 + k*res`, `-180 + k/120`, `round(.., 10)`, `(k - 21600)/120`).
- Result: `floor(. + tol)` and `ceiling(. - tol)` both return k, with 0 mismatches.
- Every 0.1° value from −180 to 180 maps to an exact lattice multiple.
- Negative lon and southern lat both give non-negative indices through the `+180` and `90 -` offsets. Out-of-range values give negative indices or indices above 43200; `crop` clips those deterministically.
- A NA or Inf bbox fails loud, in `stopifnot` or at `sprintf("%d")`.

**The crop extent equals the keyed cells, in index space.** The real source is not on the nominal lattice:

- measured res is `0.0083333337679505` (float32 1/120), not 1/120
- ymax is `90.0000078`
- xmax is `180.0000188`

The largest gap between a nominal edge `k/120` and source edge k is **0.00225 cells in x and 0.00094 cells in y**. Both are far below the 0.5 cell that `snap = "near"` needs, so nominal edge k always maps to source edge k.

The cached crop confirms it:

- dims are 1428 × 3012, which is (5016 − 3588) × (7920 − 4908)
- the extent is `-139.0999979 / -113.9999966 / 48.2000056 / 60.1000063`, which is `-180 + 4908·res_src`, and so on

**wet_grid_key.** It uses `%.17g`, which round-trips a double exactly, plus nrow, ncol and the proj string. The AET file, `rast(AET)` in memory and the DEM file all give `98f0f8e01707`. The shift test covers sub-cell offsets.

**NaN normalisation.** In-memory, INT2S, FLT4S and FLT8S copies of `c(1, NA, 3, 4)` all hash to the same value, and so do integer-typed and double-typed copies of `c(1, 2, 3, 4)`. This holds because `v[is.na(v)] <- NA_real_` coerces `v` to double even when no element is replaced, so the integer `values()` that terra returns for INT files never reaches `writeBin` as 4-byte ints.

**DEM v2 tag.** It is in the key. The cached `glo90v2_*` matches the manifest.

## Findings

- **[low] scripts/wb_inputs.R:55-60. The zones-grid content is not a function of its key when `data/hydz/` holds files from an earlier zip.**
  - **Mechanism:**
    - The zip is unzipped into the shared `hz_dir` with `overwrite = TRUE`, which overwrites files but never removes them.
    - The layer is `list.files(hz_dir, "\\.shp$", recursive = TRUE)[1]`.
    - The key is `C` + md5 of the *current* zip.
  - **Failure case:** the zip is refreshed by deleting it, which is the only way the script re-downloads it, and the catalogue has renamed the layer or its folder.
    - The old `.shp` survives, and `[1]` picks whichever sorts first.
    - A grid keyed to the new zip md5 can then be rasterised from the old zones.
    - The same can happen with stale sidecars (`.prj`, `.cpg`) that the new zip no longer ships.
  - This is the round-1 to round-4 mechanism once more: content that is not determined by its key.
  - **Reach:** only a manual refresh combined with a rename upstream. Nothing is wrong today. There is exactly one `.shp` (`BC_Hydrologic_Zones/BC_Hydrologic_Zones.shp`), and the grid matches the manifest.
  - **Fix:**
    - unzip into a directory named for the zip md5, or into a fresh `tempdir`
    - require exactly one `.shp` (stop if `length != 1`)

No other finding meets the bar.

## Checked and below the bar (not findings)

- **Outward snap is nominal, not exact.** Because the source lattice drifts by up to 1.9e-5° (x) and 7.8e-6° (y), the crop can fall short of the requested bbox by that much.
  - Measured: the requested xmin is −139.1, the crop xmin is −139.0999979. The requested ymin is 48.2, the crop ymin is 48.2000056. That is at most about 2 m.
  - This does not affect key → content.
  - The docs ("snapped outward") and the synthetic test, which uses an exact 1/120 grid, do not exercise it. The driver pads to 0.1°, so nothing downstream reaches it.
- **GLO-90 VRT resolution.** The tiles have mixed x-resolution: 3" below 50° N, 4.5" for 50-60° N, 6" at 60° N. Measured on N49/N50/N60 at W128: `terra::vrt()` builds at the average resolution (0.00125° x) with nearest resampling.
  - So the 30" average is taken over a nearest subsample, and the sub-pixel alignment is shifted by up to about half a VRT pixel.
  - The effect on a 30" mean is small, and the result is still a function of the key, because the tile set is a function of the template extent.
  - `-resolution highest` in the VRT options would remove it. This is a quality note, not a defect.
- **`wet.glo90_base` and `wet.figshare_api`.** These options are not in the keys. They are test hooks. figshare downloads are md5-checked against the same API.
- **Degenerate bbox.** A bbox narrower than about 2e-6 cell that straddles an edge gives `c0 == c1`. `crop` then errors before any write. It fails loud, and nothing is cached.
- **Concurrency.** Two processes extracting at once would race on `unlink(src)`. The final renames are atomic and same-content. This is not a usage pattern here.
- **Atomicity.** All three builders write a tempfile in the destination directory, then rename. `.part` is used for downloads. No `.aux.xml`, `.part` or orphan tempfiles are in `data/`.
- **GLO-90 tile names under float noise.** Extent noise can only add an outer tile column or row, which is then intersected away or contributes nothing. It never drops a needed tile.
