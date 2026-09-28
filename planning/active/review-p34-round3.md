# Review p34, round 3: every key or guard that decides whether a stored result is reused or compared

I worked out the call graph with `codetools::findGlobals()`, following it transitively over `asNamespace("wet")` after `load_all()`, starting from the `wet_*` calls each script makes. I did not work it out from memory.

- **Province (`wet_ws_geom`, `wet_ws_sample`, `wet_ws_fetch`, `wet_upstream_irregular`, `wet_upstream_means`, `wet_pet_hargreaves`, `wet_aet_budyko`, `wet_aet_landcover`):** the calls reach 19 functions in 9 files: wet_aet_budyko, wet_aet_landcover (which holds `wet_chapman_table3` and reads `inst/extdata/chapman_table3.csv`), wet_climr_normals (`wet_md5_text` only), wet_mm_to_m3s, wet_pet_hargreaves (`wet_ra`, `wet_pos`), wet_upstream_means, wet_upstream_sums (`wet_seg_*`, `wet_count_lt`), wet_ws_fetch (`wet_ws_geom`, `wet_upstream_irregular`, `wet_check_wscode`) and wet_ws_sample (`wet_ws_frame`). **Every one of them is in `code_files`.**
- **Scoring (wb_cv_lib.R + wb_validate.R):** the calls reach 17 functions in 9 files. **Every one of them is in `score_files`.** `wet_climr_normals.R` is reached only for `wet_md5_text`, which builds the key and does not compute any score.

## Enumeration

| # | Stored thing / guard | Content depends on | Key or guard covers | What can slip through | Wrong or mixed numbers? |
|---|---|---|---|---|---|
| 1 | `data/wb/<key>/` (the run key) | the content of the 7 inputs, the province code, the fwapg DB | `basename(f_in)` and the md5 of `code_files` (all 9 reachable R files, the script and the csv; a missing file stops the run) | the input file *names* stand in for their content, and see row 8. Neither key covers the fwapg DB | yes, through row 8. The DB stays fixed within one run |
| 2 | `in_bc.tif`, `layers.tif` (`file.exists` skip) | the key's inputs and code, and `fwa_bcboundary` | the key dir | nothing beyond row 1. Both are written to a temp file and renamed | no |
| 3 | `sample/<WSG>.rds` (`file.exists` skip) | `layers.tif`, `in_bc.tif`, the FWA polygons, `wet_ws_*` | the key dir. A smoke run (`WET_WB_GROUPS`) writes into the same key, so its samples come from the same code | nothing beyond row 1 | no |
| 4 | `upstream/<CODE>.rds` (`file.exists` skip) | the samples, the FWA topology, `wet_upstream_*` | the key dir. A missing sample stops `readRDS` | nothing beyond row 1 | no |
| 5 | `upstream/_complete` | every entry in `codes` has an rds | an existence check over `codes`. The CV lib needs exactly one complete dir | the old `5c2feaefad` is complete too, so once the new run finishes, the lib stops on "found 2" until the old dir is removed. That is a loud stop | no (the failure is loud) |
| 6 | `one()` / `climr_with()` | the single matching file | stops unless exactly one file matches. The temp files (`file*.tif/.vrt`) do not match the patterns | a rebuilt input that keeps its old *name* (row 8) | through row 8 |
| 7 | `score_code_md5` in `cv_aet-<v>.rds` | the run dir, `stations.rds`, the scoring code | `score_files` (complete, see above; a missing file stops the run), plus `station_number` identity. The run dir itself gives location | none found | no |
| 8 | **Per-input caches** `wet_landcover_nrcan`, `wet_terraclimate_aet`, `wet_climr_normals`, `wet_cgiar_aet`, `wet_dem_glo90`, and the hydz raster in `wb_inputs.R` | the source bytes, the parameters, the grid **and the code that computes the grid** | source md5, parameters, grid key (landcover also covers the crosswalk and `fact`; climr covers the years, vars and elev md5). **The builder's own code is covered by none of them.** `overwrite = FALSE` everywhere, and `wb_inputs.R` never passes `overwrite` | a fix to a builder (for example `wet_landcover_fractions`) reuses the old file under the same name | **yes, see Finding 1** |
| 9 | `fits.rds` → wb_output.R / wb_map.R | the ship-variant fit | the key dir. It is written in the same run as `cv_aet-cgiar.rds`, which wb_aet_compare.R verifies against `score_code_md5` | a later rewrite of `stations.rds` or change to the scoring code without rerunning cgiar leaves an older fit that is still internally consistent. wb_output.R does not re-check it | no mixing: it is one consistent fit, applied with its own `aet` |
| 10 | `runoff_annual.tif` → wb_map.R | fits and layers | the key dir | wb_map.R pairs it with `fits.rds$calibration`. If cgiar is revalidated after wb_output.R, the dots and the grid come from different fits | only the sanity map, with no numbers |
| 11 | temp files `file*.rds` / `file*.parquet` left in `upstream/` or `output/` by a killed run | none | the listers in wb_cv_lib.R and wb_output.R glob `\.rds$` / `\.parquet$` and would pick them up | only a partially written file can be left behind, since the rename happens straight after the write, and `readRDS` / `read_parquet` then errors | no (the failure is loud). None are present now |

## Findings

- **[real, fragile] The input caches are keyed on everything except their own code, and the province key hides this.**
  - **Where:** `R/wet_landcover_nrcan.R:53,62-65`, `R/wet_terraclimate_aet.R:45-47`, `R/wet_climr_normals.R:45-49`, `R/wet_cgiar_aet.R:28-29`, `R/wet_dem_glo90.R:24-25`, `scripts/wb_inputs.R:70-74` (hydz).
  - **The gap:** each builder returns the existing file whenever its name matches. The name encodes the source md5, the parameters and the grid, but not the computation. So after a fix to a builder, `wb_inputs.R` silently reuses the stale grid under the unchanged name.
  - **How the province key makes it worse:** `wb_province.R` puts `R/wet_landcover_nrcan.R`, `R/wet_terraclimate_aet.R` and `R/wet_climr_normals.R` in `code_files`. The same fix therefore yields a new run key, and the new run is computed from the stale input. Its comment ("a code change never reuses old samples") holds for the samples but not for the inputs. The result is a fresh-looking run carrying pre-fix `aet_lc` / `aet_tc` / climate values.
  - **It already happened today.** The build now running (pid 64987) was started with `rm data/landcover/lc2020_frac_3c1bab8d1c.tif &&` in front. The code change at 17:30 (`wet_landcover_nrcan.R`) would otherwise have been ignored, and the rebuilt file keeps the same name `lc2020_frac_3c1bab8d1c.tif`. A manual delete is the only thing that protects the input today.
  - **No code_files entry exists for hydz.** Its rasterising code lives in `wb_inputs.R`, and neither key covers it. The comment's own example, the terra#2195 fix for a 0 background, is exactly the kind of change that would not reach an existing `hydz_*.tif`.
  - **Fix, either of these:**
    - Fold a per-builder method version into each dest key (`source_id` / `key` / `vkey`), bumped with any change to the computation. The md5 of the R source is not available once the package is installed.
    - Have `wb_province.R` stop when any `f_in` is older than the md5-recorded builder file that produced it. This compares mtimes, but it fails toward a stop.
  - **Scope:** the pipeline as it will run next (one province run on the current inputs) is correct, provided no builder changes again before `wb_province.R` starts. The gap opens on the next builder fix.

Nothing else in the enumeration can produce wrong or mixed numbers. Rows 1–7 and 9 are sound for the planned order: province → validate per variant → compare → output. Rows 5 and 11 fail loudly. Row 10 affects only the map.

/Users/airvine/Projects/repo/wet/planning/active/review-p34-round3.md
