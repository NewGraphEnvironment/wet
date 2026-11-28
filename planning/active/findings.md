# Findings — Backlog move 27: The runoff products no report covers yet (#243)

## Issue context

**If we do it:** every other group's runoff product wet could be checked against is compared with the balance and HYDAT at the same gauges, each material disagreement attributed as ours, theirs or unresolved. **If we never do:** those products are used unchecked, and their errors, or ours, stay invisible.

Order: `planning/backlog.md`, move 27. Run `/planning-init <this issue>`: one phase, one PR. It can start now.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 27, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

### Batch 31: the products no report covers yet

**Why here:** one gauge set, one metric and one disagreement log serve GEOGLOWS v2, TerraClimate runoff and the 1961–1990 runoff isolines (#225). The BC Water Tool's modelled estimates wait on the Province's release, so the plan carries the three available products and files the fourth as its own issue.

**Touches:** a new comparison script with its report under `data/checks/`, `research/runoff_prior_art.md`, a disagreement log under `research/` (named at the plan gate).

**Decided at the gate:** the metric and gauge set, registered before any number; the questions for the Province go through the owner.

| issue | title |
|---|---|
| #225 | Score the products no report scores yet, with a disagreement log: GEOGLOWS v2, TerraClimate runoff, the runoff isolines, the BC Water Tool's modelled estimates |

## Probes during planning (2026-11-26)

- **Runoff isolines:** BC catalogue entry "Hydrology: Normal Annual Runoff Isolines (1961 - 1990) - Historical", OGL-BC, layer `WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE`. The WFS reports `numberMatched="66"`: 66 LineStrings, attribute `ANNUAL_RUNOFF_IN_MM` at nine levels (50 ×1, 100 ×5, 200 ×5, 500 ×10, 1,000 ×11, 1,500 ×4, 2,000 ×17, 3,000 ×6, 4,000 ×7). Coarse levels, so the interpolation between them matters: hence the TIN plus an inverse-distance spread check. `openmaps.gov.bc.ca/robots.txt` answers "File Not Found" (no robots file).
- **TerraClimate runoff climatology:** `http://thredds.northwestknowledge.net:8080/thredds/fileServer/TERRACLIMATE_ALL/climatology/TerraClimate_19812010_q.nc` answers 200 (the name without the underscore after "TerraClimate" answers 404). The host's robots.txt (THREDDS's default) disallows `/thredds/fileServer/`, `/thredds/ncss/`, `/thredds/dodsC/` and the catalogs. `R/wet_terraclimate_aet.R` and `scripts/wb_inputs.R` already fetch the AET and precipitation climatologies from `fileServer`, and `scripts/wb_plateau_p.R` read yearly files through `ncss`; no research file records a robots check for this host. Open decision 2.
- **TerraClimate is already upstream at the gauges:** the province run carries `ppt_tc` (and the AET variants include TerraClimate's), so `scripts/wb_term_diagnose.R`'s `cal` holds `ppt_tc`, `p_yr`, `aet_cfu` at every calibration gauge. q's annual sum can be checked against `ppt_tc − aet_tc` without a new fetch, and a disagreement split into its precipitation and AET terms.
- **The path for a surface at the gauges exists:** `scripts/wb_term_diagnose.R` lines 72–110 (per basin: `wet_ws_fetch()`, `wet_ws_sample(r, wet_ws_geom(conn, g), "area")`, `wet_upstream_means()`), cached per basin and keyed on the code files.
- **Scores to reuse:** `scripts/gauge_monthly_compare.R` (error %, within ±20 %, `wet:::wet_nse()` on months and on shares); `scripts/wally_compare.R` reads observed, balance and routed from `inst/vignette-data/monthly_values.rds` and asserts them equal to `cv_aet-cfu.rds`; routed is scored on 283 shared gauges, the balance on 315.
- **Installed packages:** `check_pkg_stale.sh` lists wet 0.4.44 installed against 0.6.0 (and drift, fresh, link, ngr, spacehakr, xciter, none used here). Scripts call `wet:::`, so wet is installed from the branch before a run.
- **GEOGLOWS v2:** per reach on TDX-Hydro (about 7 M reaches), CC BY 4.0, on AWS (`research/runoff_prior_art.md` §2 row 3). A gauge-to-reach crosswalk held to drainage area is its own piece of work, hence the split.

## At the resume (2026-11-27)

- **Owner's decisions:** the three recommended options (signed median at 20 points; one logged TerraClimate fetch; the period ratio test). Written into #243's body; #225's body rewritten; GEOGLOWS v2 is #244, the BC Water Tool's estimates #245.
- **Members check:** `FREE #225`, exit 0 (soul's `members_check.sh`, called by path: `soul_published_tree` is a function in `skills/_shared/soul_shared.sh`, not on PATH).
- **Lake outlets:** 19 of the 315 calibration gauges (`cal$lake`), not 18.
- **First-level codes:** the 315 gauges sit under 14 first-level watershed codes, spanning 236 of the 246 watershed groups.
- **TerraClimate's robots.txt** (read 2026-11-27, THREDDS's default file) disallows `/thredds/catalog/`, `dodsC`, `wcs`, `wms`, `ncss`, `fileServer`, `cdmremote` and the catalog services. The one fetch of `TerraClimate_19812010_q.nc` (86,671,480 bytes, md5 `691e6bfe3d37e0b377f61ccf3607b3e6`) is logged in `<WET_DATA_ROOT>/logs/243/runoff_products_fetch.tsv`, beside the two WFS requests.
- **The isolines:** 66 lines; densified to 1 km they give 31,474 points.
- **terra's exact extract on a projected CRS is slow.** terra 1.9.50 `extract(exact = TRUE)` on the 1 km BC Albers isoline grid took about 75–90 ms per FWA polygon (16 s for 200 SALR polygons, 15–45 min per watershed group), against about 1 ms on TerraClimate's lon/lat lattice; neither the raster's extent nor its cell size moved it. TerraClimate reprojected to Albers was as slow; with raster and polygons labelled `"local"` (same coordinates) the same call took 0.025 s for 50 polygons, fractions within 1.1e-7 of the ellipsoidal ones. So on a projected CRS terra computes ellipsoidal cell areas. BC Albers is equal-area, so the script samples the isolines under the `"local"` label (`sample_group()`). The province run samples on lon/lat and never met this.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `matrix(NA_real_, nrow(cv), 12)`: non-numeric extent | `cv_aet-cfu.rds` is a list: `length(cv$station_number)` |
| isoline sampling at 15–45 min per watershed group | terra's ellipsoidal path on a projected CRS; planar under a `"local"` label (above) |
