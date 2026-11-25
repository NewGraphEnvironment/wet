# What wet's scenarios can be built on, and which product covers which watershed group

**Verified:** 2026-11-25 · **Issues:** #169 (backlog move 7), #4 (scenario period means), #5 (coverage); from #168 (`pcic_channel_scale.md`) · **Produced by:** `scripts/scenario_basis.R` → `data/checks/scenario_basis_20260717.txt` (rules registered at 4fd260e); `scripts/pcic_coverage.R` → `data/checks/pcic_coverage_20260717.txt`; `scripts/pcic_coverage_map.R` → `pcic_coverage.png`. HYDAT 2026-07-17, fwapg 5d50cc1's `pcic` schema, the live published build a0318b7. Run logs: `data/logs/169/` (main checkout). **Status:** coverage measured; the two checks scenarios rest on are registered and coded, and their runs wait on PCIC.

## Where things stand

Move 6 chose, by its registered rule 3, CMIP6 routed (PCIC's VIC-GL-Raven channel-scale runs through fwapg's crosswalk) on the coast, Columbia and Peace, and CMIP5 gridded (PCIC's VIC-GL runs) in the Fraser, scored first. The owner kept that answer (2026-11-25). Two checks stand between it and a build, and neither has run:

- **Rule 4**, what each of the 18 CMIP6 runs lacks against the crosswalk fwapg stores, needs hydromosaic's listing of each of 48,716 outlets.
- **Rule 5**, whether the six RCP 4.5 CMIP5 runs' 1981–2010 flow in the Fraser is PNWNAmet's, needs about 9.5 GiB from PCIC's OPeNDAP backend.

PCIC's robots.txt disallows both paths (`pcic_hydrology.md`, "Access and robots.txt"), and the owner chose to ask PCIC first: a note drafted for the owner asks how PCIC would like bulk reads done, and says the project would read politely from about mid-December unless PCIC prefers otherwise. Until then nothing is requested; `WET_SCENARIO_FETCH=1` runs both checks and logs every request.

## Which product covers which watershed group

![Two maps of BC's 246 watershed groups. Left: the published 1981–2010 flow, routed PCIC and the balance on most of the province, routed on part along the coast and islands, and the balance alone in the Liard, the far northeast and the northwest corner. Right: what scenarios would build on, CMIP5 gridded through the Fraser basin, CMIP6 routed across the north, Skeena, Peace and Columbia, part or mixed along the coast, and none in the Liard and the northwest.](pcic_coverage.png)

*Each of BC's 246 watershed groups by the published 1981–2010 source (left; routed PCIC "on" a group where it has a value on 95 % or more of the group's segments, "on part" from 5 % to 95 %) and by the product its scenarios would build on under rule 3 (right; one product where routed PCIC covers 95 % of the group and 95 % of its segments lie in that product's PCIC domains). Dark lines are rivers of stream order 7 and up. The breaks were fixed before the table was read.*

| | groups |
|---|---|
| routed PCIC and the balance (routed on 95 % or more) | 154 |
| routed on part (5–95 %) | 44 |
| the balance alone (under 5 %) | 48 |
| scenarios on CMIP6 routed | 87 |
| scenarios on CMIP5 gridded (the Fraser) | 67 |
| part or mixed | 44 |
| no PCIC product | 48 |

- **Routed PCIC reaches most of the province.** 198 groups have routed flow on at least part of their segments. The 48 with the balance alone are the ones PCIC's routed network does not reach: the Liard basin (the Dease, Kechika, Fort Nelson, Muskwa and Prophet among it), the Hay and Petitot, the Yukon and Alsek headwaters (Atlin, Teslin, Tatshenshini) and the Skagit.
- **The groups "routed on part" are mostly the coast and its islands** (39 of the 44), where PCIC's network places only some segments (`pcic_channel_scale.md`: on the coast 5.5 % of outlets have no FWA stream within 150 m).
- **PCIC's gridded runs cover 138 groups at all and 110 at 95 % or more of their area**: the Peace, Fraser and Columbia, with cells along each divide spilling into the next group (Babine Lake's group lies 22 % on gridded cells). This is the PNWNAmet run's cells with values; that the CMIP5 runs share the domain is PCIC's statement, not measured here.
- **By PCIC domain**, the groups with routed segments: the coast 87, the Fraser 70, the Peace 27 and the Columbia 18; 47 have none.
- **The calibration gauges** (315) lie in 147 groups. The report gives each group's mean absolute percent error of month-0 runoff for routed PCIC (at the 283 gauges where it carries at least a fifth of observed flow) and the balance (held out, at all), as the segment-discharge article scores them.

The CMIP6 count per group is by domain, from the pilot's listings at its scored gauges' outlets (9 GCMs, 8 on the coast, where TaiESM1 has no series); rule 4 would make it per outlet.

**Not in the table, because no report scores them yet:** GEOGLOWS v2, TerraClimate runoff, the BC 1961–1990 runoff isolines, and the BC Water Tool's modelled estimates (not released). Already scored elsewhere: routed PCIC (`pcic_routed_compare`, `gauge_monthly_compare`), the balance (held out, and `gauge_monthly_compare`), PCIC's gridded PNWNAmet run through fwapg (`water_balance_method.md` §0), WALLY (`wally_compare`, by zone).

## Rule 4: what each CMIP6 run lacks

**Not run** (PCIC asked first). As registered: for every outlet of `pcic.fwa_crosswalk`, a run has a series where its listing's streamflow row passes the day test (days from start to end, both counted, equal to `num_times`; starting by 1951-01-01; ending by 2012-12-31 for PNWNAmet and 2099-12-31 for a GCM). Per run, A is the outlets of the stored crosswalk's series set (48,688: every outlet not flagged `no_series`) with no series for the run, and B the outlets outside it with one. Each run is typed "runs as the job stands", "runs on the stored crosswalk" (B only), "lacks series the crosswalk places" or "lacks series at unplaced outlets only", by domain and flag, with whether its outlets with no series pass the 100 at which fwapg's job stops. The listings are a proxy for what a bulk request returns, so they are held to the pilot's bulk cache where both exist.

Known before registration, and so not something the rule could find: CNRM-ESM2-1 has series at outlets where PNWNAmet has none, so fwapg's job, which refuses a crosswalk other than the stored one, would refuse it as it stands; TaiESM1 has no series at any coast outlet the pilot scored. The rule's code, run on the pilot's 247 cached listings as a dry check (not a result), typed TaiESM1 "lacks series the crosswalk places" under both SSPs (74 coast outlets) and the other 16 runs "runs as the job stands", the listings agreeing with the pilot's bulk cache at every outlet.

## Rule 5: CMIP5 gridded in the Fraser

**PNWNAmet's side ran; the CMIP5 score did not** (PCIC asked first). Rule 5 accumulates RUNOFF + BASEFLOW as the pilot's "wet's accumulation" did (centroid sampling, `wet_upstream_mean(..., "total")` with the irregular pairs, over the Fraser's polygons), month by month with `wet_pcic_monthly()`, at the pilot's 73 Fraser gauges with an outlet. Its parity check holds: PNWNAmet's twelve months summed give the pilot's annual flow at its four Fraser sites to two decimals (Salmon River 20.45 m³/s, Quesnel River 134.18, Fraser at Hope 2,476.28, Lillooet River 99.58). Every gauge's accumulated area equals the bundle's, and PNWNAmet's monthly shares reach a median NSE of 0.90 against the observed shares.

When it runs, the Fraser passes if the median over the 73 gauges of |median over the six GCMs' annual flow − PNWNAmet's| / observed flow is at most 0.05, and the median share NSE of the six GCMs' median month falls no more than 0.05 below PNWNAmet's; RCP 8.5 is scored too only where its 1981, 1993 or 2005 differ from RCP 4.5's by more than the packing step. A fail sends the choice back to the owner beside the pilot's CMIP6 numbers for the Fraser (0.082 and −0.036).

Rule 5 is not rule 2 verbatim, in three ways the report states: its year is the twelve months' total, where the pilot took the plain mean of twelve monthly mean flows; its PNWNAmet side is the gridded run accumulated unrouted, where the pilot's was the routed outlet series; and its two sides are different models (VICGL against VICGL-RGM), so a fail may be model structure, not forcing.

## The readers this needed

`wet_runoff_monthly()` and `wet_pcic_monthly()` give a gridded run's mean monthly totals, the twelve summing to `wet_pcic_annual()`'s. `wet_pcic_fetch()` now reads its HTTP status (it waits on 429 and 503, stops on anything but 200), sends a user agent naming wet, and refuses a download whose days are not the ones asked for, which covers a run on a 360-day calendar; PCIC's HadGEM2-ES and CanESM2 RCP 8.5 files read on the standard calendar (`pcic_hydrology.md`).

## Wrong turns

- The coverage map's first render sorted both legends alphabetically and left the rivers, the most prominent lines, out of the legend; caught by the self-review at the published width.
- A tracked report printed this machine's absolute paths before its tracked run; caught before the commit, and the reports name paths under the data root instead.
