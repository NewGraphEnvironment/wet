# Other groups' runoff products at the calibration gauges, and the disagreement log

**Verified:** 2026-11-27 · **Issues:** #243 (backlog move 27), #225; #244 (GEOGLOWS v2) and #245 (the BC Water Tool's modelled estimates) append to the log · **Produced by:** `scripts/runoff_products_compare.R` → `data/checks/runoff_products_compare_20260717.txt`, under the rule `scripts/runoff_products_rule.R`, registered at a5e867c before the script or any product value existed (thresholds the owner's, 2026-11-27). The shipped fit (HYDAT 2026-07-17, province run 768876badf). Run logs and the fetch log: `data/logs/243/`. Two runs gave byte-identical reports. · **Status:** TerraClimate runoff and the isolines scored; GEOGLOWS v2 and the Water Tool's estimates open.

## The answer

At the 315 calibration gauges, **TerraClimate's runoff runs a median 33 % below observed mean annual runoff** (middle half −46 to −13 %; 23 % of gauges within ±20 %), where the held-out balance is −4 % and routed PCIC −3 %. Under the rule that is "theirs" province-wide and in 14 hydrologic zones (two more unstable), "unresolved" in the Northern Interior Plains, and "ours" in the Southern Thompson Plateau (zone 24), where the balance runs +36 % and TerraClimate −13 %. Most of TerraClimate's shortfall is its precipitation: over the 315 gauges, the median of its precipitation's difference from climr's is −202 mm, and of its AET's from ours −85 mm.

**The 1961–1990 runoff isolines are a median +2 % from observed** at the 292 gauges they cover (middle half −14 to +18 %; 61 % within ±20 %), against the balance's −5 % at the same gauges: not material province-wide or in 17 zones (two more unstable; 7 have too few gauges). They are "ours" in the Southern Thompson Plateau, where the balance's +36 % is the outlier, "ours" but unstable in the Southern Hazelton Mountains (zone 9), and "theirs" in Western Vancouver Island (zone 29: isolines −22 %, balance +9 %), where too few long-record gauges give a period ratio to test whether 1961–1990 explains it.

So the isolines, drawn from the same gauges for an earlier period, match the gauges better than the held-out balance does. TerraClimate, which uses no gauge, misses them more than either: its monthly shape too (median per-gauge share NSE 0.55 against the balance's 0.94 and routed PCIC's 0.89, at the 283 gauges routed PCIC shares).

## TerraClimate runoff

- **What was read.** `TerraClimate_19812010_q.nc`, the 1981–2010 climatology of TerraClimate's runoff (variable `q`, 12 monthly layers, mm per month), at its own 1/24° lattice with no resampling. Annual runoff is the sum of the months. It covers every calibration basin: none is dropped by the rule's 95 % coverage, lake outlets included.
- **Plumbing.** At the 314 gauges TerraClimate covers wholly, its annual runoff is a median 0.7 % from the province run's `ppt_tc − aet_tc` (TerraClimate's precipitation and AET resampled to the 30″ grid), inside the rule's 5 % bound. So the sampling reads the file as the province run read its siblings.
- **Where the gap comes from.** At each gauge TerraClimate's gap to the held-out balance splits exactly into four terms: precipitation (`ppt_tc − p_yr`), AET (`−(aet_tc − aet_cfu)`), TerraClimate's storage and fill (`q − (ppt_tc − aet_tc)`), and the balance's zone adjustment (`−(cv_ann − (p_yr − aet_cfu))`). Precipitation is the largest term in every zone judged "theirs" (a median −126 to −1,404 mm) but two, the Northern Rocky Mountains and the Lower Columbia Basin, where the zone adjustment is as large or larger. TerraClimate's lower AET offsets part of it (+29 to +147 mm), and its storage term is under 10 mm. On the south coast and western Vancouver Island (zones 25–27, 29) the zone adjustment also raises the balance by a median 119 to 491 mm: our own unadjusted P − AET is low there too, and the adjustment, fitted to other gauges, corrects it. That part of the gap is the gauges' information, which a gauge-free product cannot have.
- **Independence.** TerraClimate uses no gauge, so each "theirs" is a fair test of it against observed flow. It also has no glacier or groundwater terms (`runoff_prior_art.md`, rank 5).
- **Access.** The file's host serves THREDDS's default robots.txt, which disallows `/thredds/fileServer/`, `ncss`, `dodsC`, `wcs`, `wms`, `cdmremote` and the generated catalogs (read 2026-11-27). The runoff climatology is served only there. The owner chose one logged fetch (2026-11-27), as `wet_terraclimate_aet()` had already fetched the AET and precipitation climatologies from the same path: 86,671,480 bytes, md5 `691e6bfe3d37e0b377f61ccf3607b3e6`, logged in `data/logs/243/runoff_products_fetch.tsv`. No other TerraClimate request was made.

## The 1961–1990 runoff isolines

- **What was read.** `WHSE_WATER_MANAGEMENT.HYDZ_ANNUAL_RUNOFF_LINE` from the BC WFS (OGL-BC; no robots.txt on the host): 66 lines at nine levels from 50 to 4,000 mm, held to the server's count. No two lines of different levels touch or cross.
- **Two surfaces.** The lines are densified to 1 km (31,474 points) and gridded by sf's GDAL (3.8.5) on a fixed 1 km BC Albers grid, as a TIN that does not extrapolate beyond its triangulation and as inverse distance (power 2, 50 km radius, 12 points). The verdict is the TIN's. Inverse distance is a median 0.0 % from it at the scored gauges (middle half −2.0 to +1.7 %), and gives the same verdict in every zone but two whose TIN verdict is unstable (zones 7 and 23), marked "surface-dependent".
- **Flat triangles.** Where the TIN's three vertices sit on one level, it is flat (measured as TIN cells within 0.001 mm of a level). That holds over a median 20 % of a basin's area, more than half of it at 95 gauges, and nearly all of it in the Kootenay basins (zones 19–21), where the surface is the level of the line around them. Inverse distance has the same bias, so their agreement cannot show it.
- **Coverage.** 23 gauges fall below 95 % cover: 21 in the north (six in the Stikine's drainage, five in the Skeena's and the Nass's, eight in the Liard's, and the Finlay and the Alces in the Peace's) and two in the Flathead near the border.
- **Not independent.** The isolines were drawn from Water Survey of Canada gauges, so they are not an independent test of the balance at those gauges. `water_balance_method.md` called them "independent" until this was scored.
- **The period.** The isolines describe 1961–1990, and observed flow is from complete years in 1981–2010. At 121 natural BC gauges with at least 20 complete years in each period, mean annual flow over 1981–2010 is a median 0.985 of that over 1961–1990, and each zone with three or more such gauges is within 0.95 to 1.03. Scaled by it, no zone's isoline verdict changes. Western Vancouver Island has two such gauges, so its "theirs" stays untested.

## Sampling on BC Albers with terra

terra 1.9.50's exact extraction (`extract(exact = TRUE)`, which `wet_ws_sample(method = "area")` calls) takes each cell's ellipsoidal area on a projected CRS. It was about 75–90 ms per FWA polygon on the 1 km BC Albers grid, 15–45 minutes per watershed group, against about 1 ms per polygon on a lon/lat lattice. Neither the raster's extent nor its cell size moved it. With raster and polygons labelled `"local"` (the same coordinates), the same call was more than 100 times faster (0.025 s against 3.6 s for 50 SALR polygons), with fractions within 1.1 × 10⁻⁷ of the ellipsoidal ones. BC Albers is equal-area, so planar fractions are its area fractions, and the script samples the isolines that way. The province run samples on lon/lat and is not affected.

## Disagreement log

One row per material disagreement under the rule (a zone with at least 5 scored gauges, or the province, whose product and balance medians differ by more than 20 points, one of them outside ±20 %). Errors are median annual error over observed, %. Report sections: verdicts in 8, evidence in 9.

| Product | Where | Product | Balance | Verdict | Evidence |
|---|---|---|---|---|---|
| TerraClimate runoff | BC (315 gauges) | −33.0 | −3.6 | theirs | precipitation term's median −202 mm; gauge-free |
| TerraClimate runoff | 01 Northern Coast Mountains | −38.4 | −13.4 | theirs | precipitation −467 mm |
| TerraClimate runoff | 03 Northern Rocky Mountains | −39.5 | +7.3 | theirs | precipitation −138 mm; the zone adjustment adds 142 mm to the balance, the larger term |
| TerraClimate runoff | 04 Northern Interior Plains | −64.7 | −32.9 | unresolved | both low; 5 gauges |
| TerraClimate runoff | 05 Northern Central Uplands | −33.8 | −7.3 | theirs | precipitation −147 mm |
| TerraClimate runoff | 07 Southern Rocky Mountain Foothills | −38.4 | −5.2 | theirs | precipitation −196 mm |
| TerraClimate runoff | 08 Nechako Plateau | −25.6 | +16.1 | theirs | precipitation −126 mm |
| TerraClimate runoff | 10 Central Coast Mountains | −31.1 | −11.1 | unstable (theirs) | precipitation −624 mm |
| TerraClimate runoff | 13 Upper Fraser Basin | −43.7 | −14.5 | theirs | precipitation −282 mm |
| TerraClimate runoff | 14 Northern Columbia Mountains | −34.8 | −3.9 | theirs | precipitation −151 mm |
| TerraClimate runoff | 19 Upper Kootenay Basin | −37.0 | −14.0 | unstable (theirs) | precipitation −147 mm |
| TerraClimate runoff | 20 Central Kootenay Basin | −42.9 | −9.4 | theirs | precipitation −173 mm |
| TerraClimate runoff | 21 Lower Kootenay Basin | −22.6 | +1.9 | theirs | precipitation −346 mm |
| TerraClimate runoff | 22 Lower Columbia Basin | −22.5 | +0.2 | theirs | precipitation −171 mm; the zone adjustment adds 203 mm to the balance, the larger term |
| TerraClimate runoff | 24 Southern Thompson Plateau | −12.5 | +36.4 | ours | the balance's dry-interior overshoot (`monthly_error.md`) |
| TerraClimate runoff | 25 Eastern South Coast Mountains | −59.3 | +8.9 | theirs | precipitation −546 mm; the zone adjustment adds 299 mm to the balance |
| TerraClimate runoff | 26 Central South Coast Mountains | −55.1 | −0.7 | theirs | precipitation −1,017 mm; zone adjustment 491 mm |
| TerraClimate runoff | 27 Western South Coast Mountains | −53.6 | −9.3 | theirs | precipitation −1,404 mm; zone adjustment 119 mm |
| TerraClimate runoff | 29 Western Vancouver Island | −43.3 | +8.8 | theirs | precipitation −1,126 mm; zone adjustment 408 mm |
| Runoff isolines | 09 Southern Hazelton Mountains | +10.7 | −25.2 | unstable (ours) | drawn from the gauges |
| Runoff isolines | 24 Southern Thompson Plateau | −8.2 | +36.4 | ours | drawn from the gauges; period ratio 0.968 |
| Runoff isolines | 29 Western Vancouver Island | −21.9 | +8.8 | theirs (period untested) | drawn from the gauges; two long-record gauges, no ratio |
