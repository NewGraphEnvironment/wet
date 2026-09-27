# Review: Phase 2 of #11 (HYDAT stations), round 3

## Mechanism and enumeration

The two earlier findings have different mechanisms:

- **R1** was a driver-type defect: a bigint arrived as `integer64`.
- **R2** was a label defect. Neither R2 finding was inside the R1 fix.

The mechanism behind R2 is **a label that names a category or cause, where the code computes a proxy for it.** "Seasonal" was really *no complete year in the window*. The same shape recurs below. Every place in the diff that says what a number means is listed here, with a verdict against what the code computes.

| Where | Claim | What the code computes | Verdict |
|---|---|---|---|
| `wet_station_select` doc | regulation flag 0; no record means left out | inner JOIN on `REGULATED = 0` | OK. REGULATED is only 0/1; the station is the primary key |
| `wet_station_select` doc | complete year = 12 months, each with >= `min_days` days | `n >= min_days`, `COUNT(DISTINCT MONTH) = 12` | OK |
| `wet_station_select` doc | "Seasonal gauges therefore never qualify" | follows from the 12-month rule | OK |
| `wet_station_select` @return | `drainage_area_gross_km2`, `n_years` | HYDAT gross area in km2; count of complete years | OK |
| `wet_station_monthly` doc and @return | same years for every month, shares sum to 1, annual = volume / 365.25 | as stated | OK (R1 and R2 also checked against MONTHLY_MEAN) |
| `wet_mm_to_m3s` / `wet_month_days` docs and examples | 365 default; months sum to 365.25; 500 mm over 1e8 m2 ≈ 1.59 | as stated (1.5855) | OK |
| `wet_station_snap` doc | area chosen from stored `fwa_watersheds_upstream_area` | as stated | OK; the stored area also matches the live area for this run (see below) |
| `wet_station_snap` `@param lake_dist`, report line, decision 9 | **"possible lake outlet" / "lake-outlet flag"** | any `fwa_lakes_poly` within 500 m of the snapped point | **WRONG, finding 1** |
| report `## Accepted by WSC sub-drainage`, rds column `subdrainage`, progress.md "97 sub-drainages", task_plan line 58 | **WSC sub-drainage** | `substr(station_number, 1, 4)`, which is the **sub-sub-drainage** | **WRONG, finding 2** |
| report `HYDAT: Hydat.sqlite3 (tidyhydat 1.0.1)` | which HYDAT this is | tidyhydat's package version, not the database release | **WRONG, finding 3** |
| report `## Selection (BC stations with daily flow in the window)` | stations with flow | any DLY_FLOWS row in 1981-2010 | OK; 0 BC stations have only all-NULL rows |
| report `regulated (flag 1)`, `no regulation record`, `seasonal or gappy`, `fewer than 10`, `selected` | counts by drop reason | as stated; they sum to 860 | OK (R2's fix holds) |
| report `5 candidates within 1 km`, `+/- 10 %`, `500 m`, `>= 20 days` | the parameters used | hardcoded literals that equal the defaults the script calls | OK now; they will go stale silently if a default changes |
| report `area ratio of accepted` | FWA area / gross | stored FWA area / gross | OK; stored = accumulated here |
| task_plan Phase 2 checkbox | "picker on the ratio of **accumulated** upstream FWA area" | stored area | Numerically harmless, measured below; the prose overstates what the code does |
| test comment "08ME023: nearest segment drains ~3 km2; gauge drains 144 km2" | | nearest candidate 36 m away at 3.1 km2; the picked one at 147.9 km2 | OK |
| progress.md "352 stations selected (251 regulated, 118 …, 137 short dropped)" | | 251/118/137 are *dropped* counts, not a breakdown of the 352, and the 2 with no record are omitted | Ambiguous prose. Not a number error |

**Stored vs accumulated area (checks the ACCEPTED premise):** I summed `ST_Area` over `fwa_upstream(wscode, localcode, …)` for all 352 snapped watersheds against the local fwapg. The accumulated / stored ratio is 0.99999999999998 to 1.0000009 (p1, p50 and p99 are all 1.0). No accept or reject verdict flips. Stored area is good enough here, both for choosing a candidate and for accepting it.

**The pick and the accept rules use different scales.** The pick uses |log ratio|, which is symmetric, but acceptance uses |ratio − 1| <= 0.1, which is not. So a candidate at ratio 1.104 beats one at 0.900, and the station is then rejected. I checked all 1,638 real candidates. No rejected station had another candidate inside ±10 %, so this does not happen today.

## Findings

- **[severity: medium, flag means something other than its label]** `R/wet_station_snap.R` (the `lake` EXISTS clause and `@param lake_dist`), `scripts/wb_stations.R` (the report line `"accepted within 500 m of a lake (lake-outlet flag): %d"`), and decision 9 ("Lake outlets are flagged"). The flag is **true when any lake polygon is within 500 m of the snapped point**. That is not what a lake outlet is, and it errs in both directions. I measured this against the local fwapg: for every lake within 500 m of the 52 flagged stations, I checked whether any stream segment carrying that lake's `waterbody_key` is upstream of the snapped point (`fwa_upstream` with blue_line_key and measure).
  - **33 of the 52 flagged stations have no lake upstream at all.**
    - The lakes near 30 of them are off the network: ponds beside the channel, with a median largest area of 0.3 ha.
    - 3 are *inlets*, where the lake is downstream of the gauge:
      - 08LE077 (a 30,737 ha lake)
      - 08NE008 (31,932 ha)
      - 08MC045 (217 ha)
  - Of the 19 flagged stations that do have a lake upstream, 8 have only ponds under 1.5 ha.
  - **False negatives:** 15 accepted, unflagged stations have a lake of at least 100 ha upstream on their network, within 3 km of the gauge. They include textbook lake outlets:
    - 08JB003 Nautley River near Fort Fraser, 845 m below Fraser Lake (5,435 ha)
    - 08LD001 Adams River near Squilax, 984 m below Adams Lake (13,229 ha)
    - 08KD001 Bowron River near Wells, 550 m below Bowron Lake (1,022 ha)

  About 11 of the 52 flagged stations sit at an outlet of a lake of 100 ha or more. So "52 lake outlets" in a tracked report that Phase 8 will cite in `research/` is wrong. Any later use of `lake` would also stratify on noise: as a covariate, as an exclusion, or in "lake outlets flagged" diagnostics. There are two fixes:
  - **Relabel** everywhere as "within 500 m of any lake polygon". That means the roxygen, the report line and decision 9's wording.
  - **Or make it mean outlet:** a lake above an area threshold whose segments are upstream of the snapped point, within some along-stream distance. The `fwa_upstream(blue_line_key, measure, …, true)` test above does this in about 2 s for 257 stations.

  No test covers `lake` at all, so neither version is pinned.

- **[severity: low-medium, wrong hierarchy level on a tracked count and a saved column]** `scripts/wb_stations.R`: `st$subdrainage <- substr(st$station_number, 1, 4)` and the report heading `"## Accepted by WSC sub-drainage"`. Also `progress.md` ("97 sub-drainages") and the task_plan line 58 checkbox ("counts by sub-drainage").
  - In WSC station numbers:
    - the first 2 digits are the major drainage area
    - the 3rd character is the **sub-drainage**
    - the 4th is the **sub-sub-drainage**

    tidyhydat's own vignette calls `08MF` "the 08MF sub-sub-drainage".
  - The 97 codes are sub-sub-drainages. The accepted stations span 18 sub-drainages.
  - This matters because decision 10 and `wet_cv_folds()` block the CV by **sub-sub-drainage**. The only column carrying it in `data/wb/stations.rds` is named for the coarser level, and the tracked report calls 97 blocks "sub-drainages".
  - Someone who takes the name at face value may use it for sub-drainage folds. The report also overstates the number of independent blocks at that level: 97 against 18.
  - Fix: rename the column and heading to `subsubdrainage` (or add both `substr(,1,3)` and `substr(,1,4)`), and correct progress.md.
  - Out of the diff, the same slip in the opposite direction: `research/runoff_prior_art.md:94` calls `08L*` a sub-sub-drainage. It is a sub-drainage.

- **[severity: low, provenance label that does not identify the data]** `scripts/wb_stations.R`, the report line `sprintf("HYDAT: %s (tidyhydat %s)", basename(hydat), packageVersion("tidyhydat"))`.
  - The tidyhydat version does not identify the HYDAT release. `download_hydat()` pulls whatever ECCC currently publishes, so the same tidyhydat 1.0.1 yields a different database after a quarterly release.
  - The database records its own release in `VERSION`: `1.0 | 2025-10-14 15:09:54` locally. The report prints only the name, which is always `Hydat.sqlite3`, and the package version.
  - The counts (860 / 352 / 309) are therefore not tied to a reproducible HYDAT release in the tracked evidence.
  - Fix: add `SELECT Date FROM VERSION` to the line.

Nothing else found. I also checked these, with no defects:

- Every BC station with a DLY_FLOWS row in the window has at least one non-NULL flow.
- The rejected-snap reasons map correctly.
- Stored area equals live accumulated area on all 352 snapped watersheds.
- No station loses an acceptable candidate to the log/linear asymmetry.
