# #5 scoping: own open estimate vs adopting a gap-fill product

## Outcome

This branch began as the #5 plan: map coverage, then validate a chosen gap-fill product (BC Water Tool was the leading candidate) on HYDAT basins outside the PCIC domain. That plan was approved, then redirected before any phase ran.

The new direction (user, 2026-09-26): build our own open estimate and evaluate other groups' data against it, because their model code does not ship with their data. A research pass settled the method and its inputs, and the work was split:

- **#11** (new): an open province-wide runoff estimate that reimplements Chapman, Kerr & Wilford 2018, the BC Water Tools method. It is validated with blocked cross-validation on HYDAT.
- **#5** (retitled): a coverage map, plus scoring of PCIC, Raven and BC Water Tool against our estimate and HYDAT, with a disagreement log.

`task_plan.md` holds the superseded phases. None were executed; the Phase 1 coverage work carries over to #5. `issue_drafts.md` is the text that was filed.

Decisions approved for #11:
- 1981–2010 normal.
- CGIAR Soil-Water Balance v3 AET, adjusted by land cover.
- No final adjustment to gauges.
- climr installed.
- NGE `trap` for input snapshots, `crate` for shape-shifting schemas, and `cd` for ERA5-Land snow predictors.

## Measurement

Desk research plus probes; nothing was fitted. Distilled in [`research/water_balance_method.md`](../../../research/water_balance_method.md) and [`research/runoff_prior_art.md`](../../../research/runoff_prior_art.md).

**What we have to work with:**
- The PCIC Raven network is fetchable in bulk from `services.pacificclimate.org/bbox-server` (OGC API Features). `rivers` holds 26,662 reaches.
- HYDAT (2025-12-04): 1,442 natural-flow BC stations. About 400 are in sub-basins outside PCIC. 460 have ≥ 10 years of record and were never flagged regulated.
- fwapg's `fwa_stream_networks_mean_annual_precip` is populated locally (3,075,336 rows, 246 groups), but it is 1991–2020 and annual only.

**What the BC Water Tools publish:**
- Chapman 2018 is open access. Its coefficients and land-cover ET ratios are not published.
- An undocumented final adjustment to measured flows brings their gauges to about 0 % error.
- 23 points where a reimplementation must choose are listed.
- The `nr-bcwat` per-tool metadata is internally inconsistent: Cariboo's accuracy numbers are a copy of Omineca's, and the station counts contradict the news releases.

**Inputs and licences checked:**
- CGIAR Soil-Water Balance v3 is CC0 and has monthly AET.
- climr 0.2.2 cannot compute Eref or CMD. Its reference map reports 1961_1990.
- Hydrologic zones layer `HYDZ_HYDROLOGICZONE_SP`: 29 zones, OGL-BC.

**Wrong turns:**
- The research survey said climr supplies Eref and CMD. Running it showed "calculation is not supported yet".
- Two attempts to pull a 1981–2010 normal from climr's observed series failed on the API. That is left as the first probe in #11.

## Evidence

The research files above, plus the probe commands recorded in `findings.md` and in this session's transcript.

Closed by: PR from `5-coverage-beyond-peace-fraser-and-columbi` (Relates to #5, #11)
