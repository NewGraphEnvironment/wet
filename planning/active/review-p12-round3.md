# Review p12, round 3 (fixes + cache-key mechanism)

## Mechanism

**A key that names an input instead of hashing the thing the content was computed from.**
The cache key and the computation are written separately, and nothing ties the key's
components to what the compute actually reads. Round 2 was the omission form (source
missing from the key). The fix introduces the naming form of the same mechanism: `url`
is in the fractions key, but the source *file* the fractions are computed from is itself
cached under `basename(url)` only, so the url component certifies a provenance the content
does not have. The md5 component is correct (it hashes the bytes actually read); the url
component is not load-bearing and can mislabel.

## Enumeration

| Cache | Content depends on | Key / path covers | Gap |
|---|---|---|---|
| `wet_landcover_nrcan()` source `dir/basename(url)` | bytes at `url` | `basename(url)` only (`file.exists`) | **url path/host not covered** — a different url with the same basename is never downloaded (probed) |
| `wet_landcover_dest()` fractions | grid (ext, dims, crs), class names + codes + order, source bytes, warp method/datatype (code) | grid key, `table$class`, `table$nrcan_2020_codes`, url, md5(src) | md5 covers the bytes used; url is covered in the key but not in the source cache above, so it can label old-source fractions as new-url |
| `wet_terraclimate_aet()` sources `TerraClimate_<period>_<var>.nc` | bytes at `<base>/<file>` | period + var in filename only | same shape: `wet.terraclimate_url` change never re-downloads (base url not in path, not in key) |
| `wet_terraclimate_aet()` grid `tc_<period>_<key>.tif` | grid, vars (names/order), nc bytes, bilinear + crop margin (code) | grid key, vars, md5(ncs), period | covered |
| `wet_climr_normals()` (new call with Tmax/Tmin vars) | elev values + grid, years, vars (order), dataset, climr refmap/obs data + climr version | grid key, md5(elev values), years, vars, dataset (filename) | climr version / upstream climr data not keyed — pre-existing, external, recorded in manifest; the new vars set gets its own key (no collision with P/T file) |
| `wet_cgiar_aet()` crop | cells, extracted CGIAR grids | cell indices; archives md5-checked vs figshare before extraction; `.extracted` marker | figshare revision after extraction not re-checked — pre-existing, not in this diff, fixed v3 dataset |
| `scripts/wb_province.R` run key (unstaged, context only) | all `f_in` files + code | basenames of `f_in` (content-keyed names) + md5 of R files and `chapman_table3.csv` | covered for landcover/tc/climr; `one()` errors (does not pick) when a second `lc2020_frac_*` / `tc_19812010_*` appears |

## Findings

- **[bug]** R/wet_landcover_nrcan.R:41-43 — round 2's "a different url option would be served old
  fractions" is only half fixed. `src <- file.path(dir, basename(url))` and
  `if (!file.exists(src)) wet_download(...)` mean a new `wet.nrcan_landcover_url` with the same
  basename (e.g. a revised product at `.../v2/landcover-2020-classification.tif`) is never fetched;
  the new key (url differs) then rebuilds fractions **from the old file** and stores them under a
  key that claims the new url. Probed with a mocked `wet_download` that serves code 1 for `v1/lc.tif`
  and code 10 for `v2/lc.tif`: only the v1 url was downloaded, the second call returned a new path
  (`lc2020_frac_6934ab4bb0.tif` vs `..._abdd436023.tif`) with `grass = 0, con = 1`, i.e. v1 content.
  The md5 in the key keeps the fractions consistent with the bytes, so nothing is internally
  inconsistent — but the url component is decorative and the source is stale. Not reachable with the
  default url (the scripts never set the option), which is why this is not a pipeline-breaker today.
  Fix: key the source path on the url (e.g. `file.path(dir, paste0(substr(wet_md5_text(url), 1, 8), "_", basename(url)))`),
  or drop url from the fractions key and state that the option only changes where a missing file is
  fetched from. Also `scripts/wb_inputs.R` hardcodes the default url and source path in the manifest
  rows, so with the option set the manifest would name a source that was not used.
- **[fragile]** R/wet_terraclimate_aet.R:385-390 — same shape: `ncs` are named by period and var only,
  so changing `wet.terraclimate_url` reuses existing .nc files. The key is honest here (url is not in it,
  md5 is), so it serves content consistent with its key; it only means the option is inert once files
  exist. Report only for consistency with the finding above.

Test check (tests/testthat/test-wet_landcover_nrcan.R, "a cached fraction grid is returned without
rebuilding..."): sound. `local_mocked_bindings` binds in the `wet` namespace (the same binding worked
via `with_mocked_bindings(.package = "wet")` in the probe); the first call cannot download (mock stops)
and the source exists, so it computes from the copied file; the cache hit is proven by the
`wet_landcover_fractions` mock; and the guard fires — in a temp copy with `md5sum(src)` removed from the
key the test fails at line 76 ("Expected ... to throw a error"). It does not cover the url component,
which is consistent with the finding above (the url component does not do what the test name implies
for "a new source").
