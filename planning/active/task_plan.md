# Task: Dry-interior precipitation: score climr against plateau-elevation observations (#50)


- #45 compared our P (climr) and AET (cfu) with PCIC's PREC and EVAP. Under the rule fixed in advance, no single term was found to be off: zones 15 and 24 read "compensating".
- The evidence gathered after the rule was applied leans to precipitation:
  - climr / PNWNAmet P is 1.36–1.61 in the dry zones, against 1.15 elsewhere, while the AET ratio is about the same everywhere.
  - Across the dry basins, runoff error correlates with ΔP / P at r = 0.32, and with ΔA / P at r = −0.04.
  - In zone 24, the implied Budyko ω is implausibly high (> 5) at 4 of 8 basins.
- ECCC normals can't settle it, because the stations sit in the valleys, well below the gauge basins (median basin elevation is 1,345–1,553 m). Only zone 15 has enough stations, and there the climr / ECCC median is 1.05.

**Decided at the plan gate (2026-10-07):**
- **Scope:** score and decide only. If the verdict is "climr high", the P correction (a scoring-input change that needs a refit on m4) gets its own issue, shown as a draft first.
- **Data home:** the fetch lives in a wet script, cached under `data/` (gitignored), as #45 did for ECCC. It is promoted to a `wet_*` function, or to cd, only if it becomes a recurring input. No `bcsnowdata` dependency: the files are plain CSVs.

## What exploration settled

**Observations** (located by the source search, 2026-10-07; zone membership from the official zone layer, to be re-checked against `data/hydz/bc_hydrologic_zones.zip` as #45 used):

- **Snow courses** (`env.gov.bc.ca/wsd/data_searches/snow/asws/data/allmss_archive.csv` plus `allmss_current.csv`; locations in WFS `WHSE_WATER_MANAGEMENT.SSL_SNOW_MSS_LOCS_SP`):
  - 38 courses in the dry zones with ≥ 20 April 1 surveys in 1981–2010: zone 15 has 15, zone 17 has 4, zone 23 has 8, zone 24 has 11.
  - Elevations run about 940–2,040 m, median about 1,460 m, the same band as the gauge basins.
  - SWE is a **lower bound** on winter P.
- **ASWS precipitation gauges** (glycol standpipe, unshielded, year-round):
  - the daily archive to 2011-09-30 (catalogue `daily.csv`; the old `daily_asp_archive.csv` link is 404);
  - hourly `PC_Archive.csv` and `PC.csv`, 2003 to now;
  - locations in WFS `SSL_SNOW_ASWS_STNS_SP`.

  Only about 7 dry-zone gauges have multi-year records: 2F05P (zone 23, 19 water years), 2E07P, 1C12P, 2B06P, 1C18P and 2F18P (zone 24, 5 water years). Nine more have PC from 2015–2025 only. Gauge P is a **lower bound** (snow undercatch); no BC catch ratio is published.
- **Wildfire stations** are tipping buckets, rain only, so they are out of scope.

**Independence:**
- climr's `refmap_climr` in BC is the 1981–2010 BC PRISM.
- The PCDS climatology list for ENV-ASP holds 23 pillows (including 2B06P and 3A24P), which are probably PRISM inputs, so scoring climr there is partly circular. Those gauges get flagged.
- PNWNAmet shares PRISM lineage (rescaled to ClimateWNA 1971–2000 normals).
- TerraClimate (WorldClim v2 plus CRU) is the most independent of the three.
- Snow courses are probably not PRISM inputs (unverified).
- climr precipitation is **not** elevation-adjusted (`ppt_lr = FALSE`), so a point query returns its 2.5 km cell value.

**Products, and what is on m1:**
- **climr 0.2.2:** observed years 1901–2024. `climr::downscale()` at points with `obs_ts_dataset = "mswx.blend"` gives per-year monthly PPT. The same call is already used in `scripts/wb_term_diagnose.R` (ECCC stage) and in `scripts/wb_inputs.R`.
- **PNWNAmet:** taken as PCIC VIC-GL `PREC` via `wet_pcic_fetch()` / `wet_pcic_annual()`, through 2012, Fraser/Columbia/Peace only. #45's daily per-year PREC files for 1981–2010 are already cached in `data/pcic/`.
- **TerraClimate monthly per-year:** not on m1. Fetch with an OPeNDAP or NCSS subset of the aggregated `ppt` file at `thredds.northwestknowledge.net`.

**Reuse:**
- the zone-intersection, ECCC-download and `save_atomic` patterns in `scripts/wb_term_diagnose.R`;
- `wet:::wet_download()` and `wet:::wet_md5_text()` for keyed caches;
- `wet_pcic_fetch()`.

No package code changes, so no fit goes stale and everything runs on m1.

**Prior art:** cd's `data-raw/qa_snow_validation*.R` compared ASWS peak SWE with ERA5-Land (cd#48, cd#56).

## Phase 1: Pre-register the rule (before any product value at any site)

- [x] Write the rule in `findings.md` and commit it before `scripts/wb_plateau_p.R` computes any product value. The skeleton is below; thresholds are fixed there.
- [x] Plan-agent review of the rule, run blind (no values). Amend, commit the amendment, and record any disclosure of what was already known (as #45's Amendment 1).

**Rule skeleton** (thresholds to be fixed in findings):

*Sites:*
- dry = zones 15/17/23/24;
- contrast = all other zones inside PCIC's domain, so PNWNAmet exists, in the same elevation band (about 900–2,100 m);
- every product is taken at the site: climr at the point, PNWNAmet and TerraClimate at the containing cell;
- each product is compared only in the water years it covers;
- per site, a ratio of sums over its years. Per group, the median over sites.

*Tests:*
- **T1, gauges, relative (primary for "climr high"):** D = (dry median climr/gauge) ÷ (contrast median climr/gauge). Undercatch largely cancels in the ratio. #45's pattern predicts about 1.25–1.40.
  - "climr high" needs D ≥ threshold;
  - from ≥ 4 dry gauges;
  - stable when each gauge is left out in turn;
  - still holding without the PRISM-input gauges, or that check reported as unavailable.
  - The same D is reported for PNWNAmet and TerraClimate.
- **T2, gauges, absolute (corroboration):**
  - in-situ catch at each ASWS site = peak pillow SWE ÷ gauge accumulation from Oct 1 to the date of peak SWE, floored at 1;
  - climr ÷ catch-adjusted gauge P ≥ threshold at ≥ half the dry gauges.
- **T3, snow courses, lower bound:**
  - a product whose Oct–Mar P is below April 1 SWE at ≥ half the dry courses is "low there" (it can name a product low, never one high);
  - also reported: each product's dry ÷ contrast factor on P/SWE. Melt and sublimation confound it, so it does not decide anything.

*Verdict mapping:*
- **climr high** = T1, and T2 holds or is unavailable.
- **PNWNAmet low** = T3 for PNWNAmet.
- Both can hold.
- **Neither** → name the evidence that would decide it.
- The disagreement with PNWNAmet is attributed ours/theirs/unresolved (CLAUDE.md).

## Phase 2: Observations (no product values)

- [x] `scripts/wb_plateau_p.R` stage 1: fetch and cache the snow-course archive and locations, the ASWS daily archive, the `PC_Archive`/`PC` hourly files and the station locations, under `data/plateau_p/`. Caches are keyed on content md5 and the script.
- [x] Zones by intersection with `data/hydz/bc_hydrologic_zones.zip`. Elevation, PCIC-domain flag, and PRISM-input flag (PCDS ENV-ASP climatology list).
- [x] Completeness rules:
  - snow courses: survey date within the April 1 window;
  - gauges: complete water years (≥ 330 days daily; hourly PC resets and gaps handled; counted).
- [x] In-situ catch per ASWS site (observations only).
- [x] Inventory section of the report: sites per zone and group, elevations, years, flags.

## Phase 3: Products at the sites, and the verdict

- [x] climr per-year monthly PPT at each site (`climr::downscale`, mswx.blend, ≤ 2024).
- [x] PNWNAmet: PCIC `PREC` daily for each site's cell, ≤ 2012. Reuse the cached `data/pcic/` years, fetch any missing ones, report the cell index.
- [x] TerraClimate monthly `ppt` for each site's cell, by year, ≤ 2024 (subset fetch, cached).
- [x] T1–T3, per zone, pooled dry and contrast, with leave-one-out. Write `data/checks/wb_plateau_p.txt` (tracked; observations do not depend on the HYDAT release) and the per-site rds under `data/plateau_p/`.

## Phase 4: Write-up

- [x] `research/water_balance_method.md` §0: new subsection "Plateau precipitation (#50)" with provenance header. Update the #45 subsection's "What would decide it", the Follow-ups list and the zone 24 line.
- [ ] Edit #50's body to the outcome.
- [ ] If climr is high: draft the correction issue (candidate layer, independence from the scored gauges, scored under #45's rule (a)–(e)), show it, and file on OK. Otherwise name what is next.

## Validation

- [ ] Tests pass (`devtools::test()`; no package code expected to change)
- [ ] `/code-check` clean on each commit (the script gets the full rounds, ending with an enumeration of its caches)
- [x] The report reproduces byte-identical on a second run from cache
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
