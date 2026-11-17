# Monthly flow error at the gauges: by region and season, routed PCIC's shape, and DFO's Fraser benchmark

**Verified:** 2026-11-17 · **Issues:** #166 (backlog move 4), carrying #6, #67 and #162 · **Produced by:** `scripts/gauge_monthly_compare.R` → `data/checks/gauge_monthly_compare_20260717.txt`. Inputs: the shipped fit (HYDAT 2026-07-17, province run 768876badf), fwapg 5d50cc1's routed 1981–2010 run, and fwapg#42's per-year sub-basin days for 1981–2010 (rows built at fwapg 26d7582, on the same crosswalk). Two runs from a frozen copy at the commit the report names gave byte-identical reports (and two each at ba29835 and 7a8a5ac before code review rounds 1 and 2) (`data/logs/166/`). The rules for #67's checks are registered in the script header at 520b9ca, before the numbers they judge. · **Status:** measured; the draft to PCIC is not sent.

The two published sources are scored against each gauge's monthly means over its complete years in 1981–2010. The open balance is held out (blocked CV), as it ships, and routed PCIC is the published run on the gauge's segment. Both are compared at the 283 shared gauges (routed has flow there and carries at least a fifth of observed annual flow), and the balance alone is scored at all 315. The gauge table is the one the segment-discharge article reads (`inst/vignette-data/monthly_values.rds`), identical value by value.

## The answer

- **Routed PCIC is low in spring and high in late summer, across the province.** By season, its median error is −17 % in March–May and +17 % in July–August. Over the year it is −3 %. The balance's worst month is April (+10 %), and no season is off by more than 6 %.
- **Routed PCIC's shape is in PCIC's own outflow (theirs).** At the 242 gauges where fwapg's crosswalk only relabels PCIC's outflow, routed is −13 % in March–April and +17 % in July–August.
- **Its small-basin loss is mostly volume, not shape.** Under 100 km² routed's monthly NSE is 0.44, but its share NSE, which leaves annual volume out, is 0.80, against the balance's 0.91.
- **Neither PCIC's sub-basin resolution nor a late melt explains the shape loss that remains** (checks 2 and 3 unresolved under the registered rule; check 2's gap runs the other way from the resolution reading).
- **On DFO's weakest statistic routed PCIC scores far higher.** That is the across-gauge R² of the lowest August and September in 1981–2010 (0.97 and 0.98, against DFO's 0.35 and 0.34). At the gauge, though, those lows are where routed is weak: its lowest August is more than half again the observed one at 37 % of the Fraser gauges.

## #6: by region, season and basin size

- **Routed PCIC by major basin, March–April against July–August:**
  - the spring shortfall is deepest in the Fraser (−23 %);
  - the summer excess is largest in the Columbia (+32 %);
  - Peace and Coast run −7 to −14 % and +17 to +19 %.
- **Routed PCIC by hydrologic zone:** the July–August excess passes +30 % in zones 10 (Central Coast Mountains), 19 to 20 (Kootenay), 23 (Okanagan Highland) and 27 (Western South Coast Mountains). The March–April shortfall passes −25 % in zones 01, 09, 10, 14, 16, 20, 22, 23, 25 and 26.
- **The balance's regional errors are zonal levels, not a seasonal shape:**
  - zone 24, Southern Thompson Plateau: +47 to +62 % by season, the dry interior that #45 and #53 diagnosed without naming one term;
  - zone 08, Nechako Plateau: +12 to +27 %;
  - zone 25, Eastern South Coast Mountains: +50 % in winter and +36 % in spring;
  - zone 28, Eastern Vancouver Island: +45 % in summer and +69 % in July–August.
- **By basin size,** the balance runs high in every season under 100 km² (+14 to +31 %). From 100 km² up it is within about ±10 % by season, except July–August above 10,000 km² (−20 %).
- **Routed's July–August excess holds in every size class** (+11 to +33 %). Its March–April shortfall is absent under 100 km² (−1 %) and deepens with size, to −25 % above 10,000 km².
- Zones with fewer than 5 shared gauges (02, 06, 11, 12, 17) are marked in the report and are not read here.

## #67: routed PCIC's seasonal shape

**On fwapg 5d50cc1 (the Nechako rebuild), at 283 gauges:**
- March −11.1 %, April −12.2 %, July +19.7 %, August +12.3 %, against −11, −12, +20 and +13 % on 7c30f58 at 279 gauges, so the rebuild did not move the shape;
- routed is low in March–April at 64 % of the gauges, high in July–August at 67 %, and both at 44 %;
- by size class, routed's median monthly NSE is 0.44, 0.80, 0.92 and 0.95, against #67's 0.43, 0.80, 0.92 and 0.95.

**Volume against shape.** Monthly NSE scores volume and shape together. Under 100 km² it follows routed's absolute annual error (Spearman −0.77), while share NSE, the NSE of a gauge's twelve monthly shares of its year, barely does (−0.19).

| Basin size | Gauges | Routed monthly NSE | Balance monthly NSE | Routed share NSE | Balance share NSE |
|---|---|---|---|---|---|
| < 100 km² | 76 | 0.44 | 0.64 | 0.80 | 0.91 |
| 100–1,000 | 106 | 0.80 | 0.82 | 0.88 | 0.93 |
| 1,000–10,000 | 83 | 0.92 | 0.87 | 0.93 | 0.96 |
| > 10,000 | 18 | 0.95 | 0.93 | 0.95 | 0.97 |

So #67's reading that "its monthly shape is where it loses" at small basins was mostly volume. The shape gap to the balance is real, but about 0.11 in share NSE, not the 0.20 the monthly NSE shows.

**Check 1, the shape in PCIC's own outflow: theirs.**
- On a segment an outlet is placed on, routed flow is that outlet's accumulated flow: `share` is 1 at all 245 such gauge segments. fwapg accumulates it down the FWA tree of placed outlets (its README, step 5).
- Where the placed outlets above the outlet on the FWA are exactly those in its PCIC subtree, that accumulated flow is PCIC's own outflow.
- This holds at 242 shared gauges, and there routed is −12.6 % in March–April and +16.7 % in July–August, with share NSE 0.89.
- Only 2 shared gauges have an outlet whose networks differ. The 39 without an outlet on their segment show the same shape (−8.1 %, +17.9 %).
- A first version of this check compared the outlet with the segment it is placed on. Those are the same number by construction, which the plan review caught; the archive keeps that run.

**Check 2, PCIC's resolution: unresolved, the gap running the other way.**
- Under 100 km², 41 % of gauges have segments whose flow is all their PCIC sub-basin's local runoff (local share 1), so their months are the sub-basin's own.
- Routed's share-NSE gap to the balance there is 0.02, against 0.12 at the rest: narrower, the opposite of what coarse sub-basins would produce.
- Expressing the catchment in VIC-GL cells was dropped: it is the area divided by a cell area that varies only with the cosine of latitude, so it ranks the gauges almost as area does.

**Check 3, late melt: unresolved.**
- Under 100 km², the share-NSE gap is 0.10 at gauges peaking by May and 0.09 at those peaking later, inside the registered 0.05 margin.
- By mean upstream elevation the gaps are 0.10, 0.13 and 0.07 by tercile, with no trend.

What remains is the attribution #67 already made: the shape comes from PCIC's model (VIC-GL runoff through Raven, driven by PNWNAmet). Which part, snow, forcing or routing, is PCIC's to say.

**What check 1 does not reach.** It rests on fwapg's statement that accumulated flow equals PCIC's outflow where the two networks agree. It does not read PCIC's raw hydromosaic series, and fwapg's staging tables (`fwapg.pcic_outlet_monthly`) are another build, so they cannot stand in for them. #6's second reference, PCIC's `hydro_stn_cmip5` routed flow at 190 stations, is an RVIC product on the CMIP5 VIC-GL runs, not the hydromosaic Raven run that wet publishes. It is not scored here.

## #162: DFO's Fraser threat-layer validation

Iacarella, Paterson, Potapova and Weller (2025, DFO CSAS Res. Doc. 2025/013, App. F, Table F1) score downscaled VIC-GL flow at 86 Fraser gauges, across gauges, in m³/s. They report R², MAE, MAPE and NSE on each month's, season's and year's minimum, maximum and mean over 1981–2010. Here the same statistics are computed at our 87 shared Fraser gauges (08J, 08K, 08L, 08M) for both sources on the Mean columns. Routed PCIC is also scored on the Min columns, routed year by year from fwapg#42's files with `wet_routed_years()`.

**Checks on the per-year files:**
- each file equals its `pcic.series` row;
- the files' bins average to the 1981–2010 run's `pcic.subbasin_daily` within float32 precision at 261 sub-basins;
- the years' routed days average to the published months within 3.3 × 10⁻⁴ relative.

**Not like for like.** DFO's numbers are context, not a race:
- DFO's gauges are not listed and likely include regulated main stems, whose six dam corrections were fitted to the gauges scored. Ours are natural-flow gauges with 10 to 30 complete years (median 28).
- DFO's modelled Min sums each grid cell's own lowest month over the period (p. 30). That is at or below the lowest year of the summed flow, so their 0.35 and 0.34 partly measure that aggregation.
- Statistics across gauges in m³/s are carried by the range of basin sizes. The report adds R² on log flow and each gauge's median absolute percent error.

| August | DFO | routed | balance |
|---|---|---|---|
| R² mean (m³/s, across gauges) | 0.95 | 0.98 | 0.91 |
| R² mean, log flow | | 0.94 | 0.96 |
| median gauge's absolute error, mean | | 0.32 | 0.33 |
| R² min | 0.35 | 0.97 | (no years) |
| MAPE min | 0.85 | 2.16 | (no years) |
| median gauge's absolute error, min | | 0.54 | (no years) |

September reads the same way:
- R² min: 0.34 for DFO, 0.98 for routed;
- MAPE min: 0.79 for DFO, 2.65 for routed;
- median gauge's absolute error, min: 0.55 for routed.

At the gauge, routed's lowest August is a median 7 % above the observed one, and its lowest September 21 % above. Only 23 % and 24 % of gauges are within ±20 %, and 37 % and 41 % are more than half again the observed low. Gauges whose observed lowest year is dry (zero flow) are left out of the percent statistics: 1 to 3 in most months, none in April to June.

#162's second item asks which of DFO's method differences our climatologies share. That is #3's, and it is not taken up here.
