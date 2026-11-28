# Chinook pilot sites: which streams, and what the method finds there

**Verified:** 2026-11-27 (re-read: every figure below against `data/checks/chinook_sites_use.txt`, the seven `departure_site_*` and seven `departure_site_snow_*` reports, the pilot's two reports and the donor test's report; the donor test's counts "as seen before registration" are the rule header's. The scripts were not re-run) · **Issues:** #126 (component of #118; after #120, #121), #152, #147 (via #167), #182 (via #187), #202 (via #211; spawned #227) · **Produced by:** `scripts/chinook_sites_use.R` → `data/checks/chinook_sites_use.txt` (NuSEDS All Areas 2026-06-01, md5 25bb43441645519f18eb4853dd1cf399; fwapg `bcfishobs.observations`; HYDAT 2026-07-17); `scripts/departure_site.R` and `scripts/departure_site_snow.R` per row of `scripts/departure_sites.csv` → `data/checks/departure_site[_snow]_<site>_<group>_20260717.txt`; article `vignettes/articles/flow-change-sparse-gauges.Rmd`; `scripts/departure_donors.R` under the rule in `scripts/departure_donors_rule.R` → `data/checks/departure_donors_20260717_20261028.txt`

The method is in [`station_flow_departure.md`](station_flow_departure.md).

## Which streams, and why

#126 tests the Maxan method (#120, #121) at three more chinook streams. Each target needs recorded Chinook use before it is fixed. Two sources count: NuSEDS, DFO's escapement database, matched to the stream on its FWA watershed code; and the provincial fish observations, matched on the stream's blue line. A NuSEDS use record is a row with adult presence or a spawner count above zero. A row reading "not inspected" or "none observed" does not count.

| stream | group | km² at mouth | HYDAT stations inside | NuSEDS Chinook rows (use) | provincial Chinook records (spawning) |
|---|---|---|---|---|---|
| Swift Creek | UFRA | 186.8 | 08KA010, 08KA012 | 60 (57, 1970–2024) | 17 (1) |
| Naver Creek | COTR | 907.9 | 08KE014 | 50 (24, 1985–2023) | 25 (6) |
| Gosnell Creek | MORR | 536.9 | none | 29 (1, 2001) | 3 (0) |
| Lamprey Creek | MORR | 240.2 | none | 0 | 4 (0) |
| Owen Creek | MORR | 212.5 | none | 11 (0) | 0 |

- **Swift Creek: 08KA012, near the mouth.** Every provincial Chinook record lies within 6 km of the mouth, around this gauge. One of them is a major spawning location; another eight are fry, from 2012. 08KA010, above Barrett Creek, is upstream of all of them. 08KA012 has 14 complete migration windows (1985–1998), all inside the 1981–2010 baseline. That makes it a different test from Maxan's five summers, which fall before the baseline.
- **Naver Creek: 08KE014, at Hixon,** with 18 windows (1956–1975), all before the baseline. This is the Maxan-like case, at 651 km² gauged out of 908 km² at the mouth.
- **The ungauged Morice stream: Gosnell Creek.** Owen Creek, the issue's first choice, has no provincial Chinook record, and its 11 NuSEDS rows are all uninspected or empty. The user's rule (2026-10-28) took whichever of Gosnell and Lamprey has more use records and no gauge. They tie at 4. Gosnell's one NuSEDS adult-presence record (2001) is the only spawning record of either, so Gosnell is the target. That tie-break is by definition: a NuSEDS adult-presence record counts as a spawning record, and neither creek has a provincial spawning record. Its provincial records are inventories from 1981 to 1999.

## How each site is run

- **Extension** (gauged sites): OLS on the nearest covering donor, k = 5, fixed before these runs; the pilot's race and its pick are still reported and decide nothing.
- **Carried departures:** the 5 donors' log departures, weighted by inverse distance, or `covariance_pick` (of the 15 nearest, the 5 whose routed PCIC years correlate best) where it ships at the site. It ships where it beats inverse distance by 0.01 on the migration-window mean at the box's covered gauges, leave-one-gauge-out and leak-free, with at least 10 gauges scored, the target covered and at least 5 covered donors (section 6 of each site report; rule registered in `scripts/departure_site.R`'s header at 68a983d, amended before any run at 37e0633). PCIC's per-year files (fwapg commit 26d7582) come from wet's cache.
- Boxes are the size of Maxan's, centred on the target. PCIC covers every box, the Morice and upper Fraser included; 2 to 4 gauges per box are uncovered (08EC014 and 08JA002, 005 and 006 in the Skeena boxes).
- Each site runs under the Bulkley's chinook salmon life history timing windows, and each but Maxan also under its own group's:

| group | migration (sources) | spawning (sources) |
|---|---|---|
| BULK | 05-01 to 08-01 (Gottesfeld and Rabnett 2007) | 08-01 to 09-15 (the same) |
| MORR (Gosnell) | 05-01 to 09-30 (Bustard and Schell 2002) | 09-01 to 10-07 (the same) |
| UFRA (Swift) | 04-01 to 08-10 (Bradford and Taylor 2023, p. 131, citing COSEWIC 2018: spring- and summer-run adults bound above the Thompson enter the Fraser from April; NuSEDS) | 08-11 to 09-05 (NuSEDS median start and end of spawning; Candy et al. 2002 for 2001 peak weeks) |
| COTR (Naver) | 04-01 to 08-09 (Candy et al. 2002, p. 22: the Cottonwood passes the lower Fraser in April and May; NuSEDS) | 08-10 to 09-06 (NuSEDS; Candy et al. 2002) |

knowledge's life history table holds the cited UFRA and COTR windows (rows added at its 4e2d8a0c; notes revised at a475dfe7, starts, ends and sources unchanged). `data-raw/life_history_data.R` reads the table at a475dfe7 while `data-raw/station_vignette_data.R` keeps BULK at c97c4d0; `lh_pin_guard()` stops the read unless every MORR row is unchanged in every column and every BULK row in every column but `note`, and unless BULK's chinook migration and spawning rows equal `life_history_bulk.csv`'s (`tests/testthat/test-life_history_pin.R`). The UFRA and COTR spawning edges are medians of NuSEDS start and end dates, which are estimates written on the record, mostly with no note of how they were made, rather than the first and last spawners seen, so they support the middle of each window, not its edges. The new reports' headers name the migration row's sources only (the site scripts were not changed, since an edit would stale every site's saved series); the spawning sources are above.

### How well each box carries and extends

Carried: median per-gauge centred log NSE at the box's PCIC-covered gauges, both weightings on the same gauges and years, migration mean (section 6).

| site, windows | covered / box pool | distance | covariance_pick | leak-free (d / c) | ships |
|---|---|---|---|---|---|
| Maxan (BULK) | 49 / 53 | 0.62 | 0.67 | 0.56 / 0.65 | covariance_pick |
| Swift, BULK | 27 / 30 | 0.55 | 0.61 | 0.56 / 0.56 | distance |
| Swift, UFRA | 26 / 29 | 0.55 | 0.53 | 0.59 / 0.53 | distance |
| Naver, BULK | 54 / 58 | 0.58 | 0.75 | 0.47 / 0.66 | covariance_pick |
| Naver, COTR | 52 / 54 | 0.60 | 0.74 | 0.54 / 0.70 | covariance_pick |
| Gosnell, BULK | 50 / 54 | 0.64 | 0.67 | 0.57 / 0.65 | covariance_pick |
| Gosnell, MORR | 50 / 54 | 0.62 | 0.66 | 0.57 / 0.66 | covariance_pick |

The shipped route's held-out score for each statistic, on the same covered gauges, with distance's in brackets where `covariance_pick` ships:

| site, windows | migration mean | spawning mean | migration min7 | spawning min7 |
|---|---|---|---|---|
| Maxan | 0.67 (0.62) | 0.66 (0.50) | 0.41 (0.22) | 0.59 (0.42) |
| Swift, BULK | 0.55 | 0.43 | 0.59 | 0.32 |
| Swift, UFRA | 0.55 | 0.42 | 0.53 | 0.22 |
| Naver, BULK | 0.75 (0.58) | 0.60 (0.42) | 0.35 (0.30) | 0.64 (0.38) |
| Naver, COTR | 0.74 (0.60) | 0.56 (0.38) | 0.31 (0.27) | 0.64 (0.40) |
| Gosnell, BULK | 0.67 (0.64) | 0.71 (0.49) | 0.39 (0.33) | 0.56 (0.43) |
| Gosnell, MORR | 0.66 (0.62) | 0.72 (0.68) | 0.49 (0.29) | 0.57 (0.39) |

- The migration-window mean clears the 0.5 usable bar in every row. The spawning-window mean falls below it only at Swift.
- The lowest seven-day flow carries least well at most sites, though not in every site-window. Under the Bulkley windows it is below 0.5 in 4 of the 8 site-windows (on inverse distance over every donor, section 3's pool, it was below in 7).
- The change intervals carry each route's held-out residuals, so a weaker score widens them.

**The extension travels less well than the carried departures.** The pilot's race, rerun at each box on the migration-window mean (median NSE, OLS / ratio), would pick OLS at Maxan (0.50 / 0.42) and at Gosnell under both window sets (0.48 / 0.35; 0.49 / 0.40), and the ratio at Swift (0.14 / 0.17; UFRA 0.10 / 0.14) and at Naver (0.63 / 0.63 within the margin; COTR 0.55 / 0.58). OLS runs everywhere. In the upper Fraser box, whose eastern part (east of about −118.5°) is mostly Alberta and dropped by the BC filter, only 11 gauges (10 under UFRA) have 30-year records, under the pilot's 15.

## What changed, 1951–1980 to 2016–2025

1951–1980 comes before global warming sped up (Hansen et al. 2012, who chose it for that reason), and ERA5-Land's snow reaches back to 1950. Each change is a route's mean over its 2016–2025 years less its mean over its 1951–1980 years, with a 90 % interval from resampling years and adding held-out residuals (sections 5 and 6, registered at b66b577 and, for `covariance_pick`, with section 6's rule).

**The shipped carried route:**

| site, windows | route | spawning mean | migration mean | spawning min7 | migration min7 |
|---|---|---|---|---|---|
| Maxan | covariance_pick | −66 % (−82..−36) | −30 % (−49..−4) | −65 % (−81..−37) | −42 % (−68..+3) |
| Swift, BULK | distance | −15 % (−32..+5) | −5 % (−17..+10) | +1 % (−23..+32) | +49 % (−2..+123) |
| Swift, UFRA | distance | −15 % (−33..+5) | −6 % (−17..+6) | −6 % (−29..+25) | −3 % (−27..+32) |
| Naver, BULK | covariance_pick | −35 % (−58..+2) | −13 % (−32..+12) | −30 % (−52..+4) | −16 % (−51..+48) |
| Naver, COTR | covariance_pick | −35 % (−59..+9) | −11 % (−27..+10) | −32 % (−53..+0) | +65 % (+7..+151) |
| Gosnell, BULK | covariance_pick | −29 % (−48..−5) | −10 % (−25..+9) | −37 % (−56..−15) | −20 % (−44..+14) |
| Gosnell, MORR | covariance_pick | −16 % (−42..+23) | −14 % (−28..+3) | −27 % (−48..+3) | −47 % (−66..−19) |

**The extended (filled-in) record**, at the gauged sites (Gosnell has none):

| site, windows | spawning mean | migration mean | spawning min7 | migration min7 |
|---|---|---|---|---|
| Maxan | −57 % (−76..−28) | −28 % (−46..−5) | −58 % (−78..−21) | +4 % (−49..+107) |
| Swift, BULK | −27 % (−47..+0) | −4 % (−19..+14) | −18 % (−42..+16) | +55 % (+8..+125) |
| Swift, UFRA | −32 % (−49..−6) | −5 % (−21..+12) | −27 % (−48..+0) | +2 % (−25..+43) |
| Naver, BULK | −40 % (−67..+6) | −0 % (−26..+36) | −25 % (−52..+18) | +14 % (−28..+75) |
| Naver, COTR | −43 % (−70..+7) | +2 % (−18..+26) | −29 % (−57..+20) | +1 % (−35..+52) |

- **Spawning-window mean.** Lower on the shipped route in every row. Under the Bulkley windows the drop runs, largest first, Maxan (−66 %), Naver (−35 %), Gosnell (−29 %), Swift (−15 %); the range stays below zero only at Maxan and Gosnell. Under Gosnell's own Morice windows it reaches zero. Swift's and Naver's own windows barely move the drop. Filled in, it falls at every gauged site, with the range below zero at Maxan and at Swift under UFRA.
- **Migration-window mean.** On the shipped route it is lower in every row, by 5 to 30 %; filled in, it is lower at Maxan and Swift, about unchanged at Naver (−0 and +2 %). The range stays below zero only at Maxan, on both routes.
- **Spawning-window lowest seven-day flow.** Carried, under the Bulkley windows it falls at Maxan, Naver and Gosnell, clearly at Maxan and Gosnell, and holds at Swift (+1 %; filled in, −18 %).
- **Migration-window lowest seven-day flow** has no common sign: it clearly falls only at Gosnell under the Morice windows and clearly rises only at Naver under the Cottonwood's (carried) and Swift under the Bulkley's (filled in). Its held-out scores are low (above).
- **The intervals hold their coverage.** Each was put through 1000 simulated no-change series, normal with the series' own SD in each period and the same residual pool: inverse-distance and filled-in intervals covered 0.904–1.000, `covariance_pick`'s 0.92 or more. The article calls a change interval a 90 % range only above 0.87, so every change range it draws on qualifies. It does not call the years figure's OLS band a 90 % range, because its held-out coverage at the three gauged sites, in their Bulkley-window reports, is 83–85 % for the migration-window mean (85–88 % for the spawning-window mean). Not tested: autocorrelated years, and donor sets that differ between periods.
- **Years behind each period.** 2016–2025 has 9 or 10 on every route; the tenth, where there is one, is 2025, which approved HYDAT holds for only some stations (each report's `rec` column says which series reach it). 1951–1980 has 20–30, with these exceptions on the `covariance_pick` route, which can choose donors with short or broken records: Maxan's means, `min7` and `cov_day` rest on 10 years (their donors, 08EE003, 08EE013 and 08JA016, hold no record from 1952 to 1970; the maximum, which also draws on 08JB002, has 30); Naver's migration-window maximum under the Cottonwood windows on 14; its spawning-window `cov_day` under the Bulkley's on 18; and Gosnell's migration-window `min7` under the Morice's on 17.
- **Naver's filled-in years since 1999** rest, for the migration-window mean, on 08KH006 to 2024 (2025 on 08KH001), and for the spawning-window mean on 08KC001 (08KG001 in 2008–2010 and 2013). The extension's donor rule needs a donor covering every one of the target's 1956–1975 years.
- The stations beyond HYDAT add no donor at these sites ([`station_sources.md`](station_sources.md), "At the chinook sites' boxes"), and held out province-wide they make carried departures worse (below).

## Snow

- **The carried migration-window departure rises with peak snow at every site**, with a 90 % range above zero (peak SWE as the only predictor). R² on the shipped route, Bulkley windows: 0.42 (Maxan), 0.41 (Swift), 0.53 (Naver), 0.48 (Gosnell). In the spawning window it is 0.01, 0.16, 0.04 and 0.20. The same holds under each site's own windows. The 3,000 mm SWE cap binds in no watershed in any year, Swift's glacier-fed basin included.
- **Snow over each target's watershed, 1951–1980 to 2016–2025:** peak SWE fell 6–9 % (Maxan 260 to 235 mm, Swift 556 to 524, Naver 243 to 223, Gosnell 974 to 891), and the 50 % melt date came 9 to 16 days earlier.
- **At the measured snow gauges** (Bulkley windows), migration-window flow rises with peak SWE at all eight, with a range above zero and R² 0.25–0.62. In the spawning window peak SWE's R² is at most 0.31. The 50 % melt date explains more there at two gauges, 64–66 % of spawning-window flow at the Nanika (08ED001) and Morice (08ED002), Gosnell's snow gauges. Elsewhere it explains at most a third, and at those two under the Morice's later windows 18–19 %.
- **Snow gauges.** Maxan's (08EE003, 08EE013) are named in the site table. The others are the first two, with at least 10 baseline years in both windows and an accepted snap, of the target's extension donor chain (Swift, Naver) or carried donors (Gosnell). They can therefore depend on the windows: Swift's are 08LB038 and 08KA007 under UFRA and 08LB038 and 08KA001 under BULK. The accepted-snap condition was added after a first Naver run, whose second gauge by the rule, 08KD001, has none.

## Gosnell's normal

Gosnell Creek is ungauged, so its normal is routed PCIC (`pick`) on mouth segment 139028198, from the published daily flows (build digest `d554e3aa`): 34.4 m³/s in the migration window and 8.7 in the spawning window (Bulkley windows; 24.0 and 5.3 under the Morice's). The normal's error is measured at the 29 departure-pool gauges of its box with an accepted snap, as log(published / observed 1981–2010). Under the Bulkley windows the median is +0.04 (migration) and +0.19 (spawning); in the spawning window that is +21 %, with an upper quartile of +47 %. Under the Morice's the medians are +0.05 and −0.00, and the spawning upper quartile is +26 %. Routed PCIC is the pick at all 29 under both, so the report's flag for gauges in the water balance's station set (where the published balance is partly in sample) does not separate in-sample from out-of-sample here. The spawning-window normal is the weak part: over the 29, its median absolute log error is about twice the migration window's (0.32 against 0.16 under the Bulkley windows, 0.23 against 0.13 under the Morice's, from the report's per-gauge rows). The result at Gosnell itself is untested.

## Maxan by inverse distance: the pilot's record

The pilot ran before `covariance_pick` existed, and [Chinook Flow at a Short-Record Stream](https://newgraphenvironment.github.io/wet/articles/short-record-flow.html) publishes its answer; `scripts/departure_site.R maxan` reproduces it. The shipped route at Maxan is `covariance_pick` (above).

**1931–2024.** Maxan's window flows are extended by OLS through a chain of its five nearest covering donors. For the migration-window mean three supply years: Buck Creek (08EE013) 1973–1974, 1980–2015 and 2017–2024, around Maxan's own 1975–1979; Goathorn Creek (08EE008) 1961–1971 and 2016; and the Bulkley at Quick (08EE004), which contains Maxan, 1931–1960 and 1972. In the spawning window Goathorn supplies 1960–1971, 1984 and 2016, Quick 1931–1959 and 1972, and Buck Creek the other years it supplies above, less 1984. The Morice and the Nanika supply none, being farther; the Nanika reaches back to 1950, but Quick comes first in the chain. Every extended year rests on one donor, through a relation fitted on Maxan's five years.

| window statistic | change, 2011–2025 against before 1981 (extended) | 90 % interval |
|---|---|---|
| migration mean | −14 % | −33 % to +9 % |
| spawning mean | −56 % | −73 % to −28 % |
| spawning 7-day minimum | −65 % | −78 % to −43 % |

The interval resamples years within each period and adds a held-out residual to each extended year. The donor-carried route, which needs no Maxan baseline, gives a smaller drop in both means: −3 % for migration and −46 % for spawning. Over the record the two routes agree closely on the migration-window mean (correlation 0.93) and less on the spawning-window mean (0.78). Spawning-window flows are small: in 80 of 94 years the mean is under 0.5 m³/s. From 1951–1980 to 2016–2025, the same inverse-distance route gives −45 % (−67..−11) in the spawning mean, −16 % (−35..+7) in the migration mean, −40 % (−63..−2) in the spawning `min7` and −17 % (−50..+38) in the migration `min7`.

Of the 50 years before 1981, Quick supplies 31 in the migration window and 30 in the spawning window, every year before 1961 and 1960 respectively, so those decades carry the Bulkley's own history. Only the migration-window mean was used to choose a method; the rest is reported and decides nothing.

**Snow and the pilot's window flows** (both predictors, percent change in the migration-window mean with its 90 % interval; method in [`station_flow_departure.md`](station_flow_departure.md)):

| series, migration-window mean | n | per 100 mm more peak snow | per 10 days later melt | R² | residual SE (log) |
|---|---|---|---|---|---|
| Bulkley near Houston (08EE003), observed | 36 | +17 % (+1 to +36) | +21 % (+8 to +35) | 0.40 | 0.28 |
| Buck Creek (08EE013), observed | 51 | +27 % (+15 to +40) | +12 % (+3 to +22) | 0.48 | 0.28 |
| Maxan (08EE018), extended | 75 | +21 % (+10 to +34) | +18 % (+11 to +26) | 0.46 | 0.28 |
| Maxan, donor-carried | 65 | +20 % (+11 to +29) | +10 % (+5 to +16) | 0.50 | 0.20 |

All eight intervals exclude zero. Peak snow and melt date are correlated (r = 0.50 to 0.57 over the migration-window fits' years), so each alone takes up some of the other: alone, peak snow gives +30 % to +39 % per 100 mm and melt date +18 % to +28 % per 10 days. In the spawning window R² is at most 0.07 and every slope's interval spans zero. The residuals show little year-to-year persistence (lag-1 autocorrelation −0.07 to 0.19). In all three watersheds peak snow over 2011–2025 averaged about 10 mm (3 to 4 %) less than over 1950–1980, and the 50 % melt date came about 10 days earlier (9 at Houston, 11 at Buck, 10 at Maxan). Applying Maxan's migration-window slopes to that change gives −17 % on the extended series and −11 % on the carried one, most of it from the earlier melt; that arithmetic is not part of the registered specification. The pilot measured −14 % and −3 % between 2011–2025 and the years before 1981, which reach back to 1931.

- In 1950 and 1951 the carried departure equals Houston's, its only donor with a value then, and Houston contains Maxan.
- Houston's watershed contains Buck's and Maxan's, so the three fits share ground and weather.
- Houston has 36 fitted years: 8 of its 44 complete migration windows fall before 1950, and it has none between 1999 and 2010.
- Of Maxan's extended years since 1950, Buck Creek supplies most since 1973; in the migration window Goathorn supplies 1961–1971 and Quick 1950–1960 and 1972, and in the spawning window Goathorn 1960–1971 and Quick 1950–1959 and 1972.

## Natural stations outside HYDAT as donors

**Registered:** 2026-11-25, before any score existed. The rule is the header of `scripts/departure_donors_rule.R`; the scoring script, `scripts/departure_donors.R`, refuses to run when that file differs from its registering commit.

The question (#202, tested in #211): does adding the natural stations outside HYDAT (the province's non-integrated network and the BC Water Tool's gauges, with `regulation == "natural"`) bring a carried departure closer to the observed one?

As seen before registration (2026-11-25, throwaway probes; the report's section 1 restates the province-wide counts from its own data, and the box counts below come from the same probes): of the 75 natural stations none has 10 complete migration window-years in 1981–2010, so none has the baseline `wet_departure_carry()` needs, and 71 have none at all. They hold 185 complete migration window-years, 179 of them in 2010 or later; 36 stations have at least 3, 33 through 2024. A third of those window-years are unchecked throughout. In the four chinook boxes, Maxan and Gosnell hold 2 such stations with 2 window-years each, Swift none and Naver 6, so no site report could move.

The only route open is an estimated baseline: each station is extended into 1981–2010 from HYDAT gauges by OLS, as #120 extends a short-record target, and its observed years then depart from that estimated mean. An OLS fit's residuals sum to zero over its fit years, so a station's level over those years is its extension gauge's; only its year-to-year variation is its own, with one or two degrees of freedom at 3 or 4 years. No gain is the likely result today.

The test, held out province-wide: every natural HYDAT gauge in its own box's departure pool, with a box of #126's size centred on it, carried by #120's inverse-distance route (k = 5) with and without the stations, each station's fit years stopping at 2024 (the last year HYDAT 20260717's approved record is broadly complete) and its later years entering as observed. The score is the RMSE of the log departure from the gauge's own 1981–2010 mean over the 2011–2025 years a station is among the donors. The route ships if the median paired difference is at most −0.01 leave-one-gauge-out and leak-free, with at least 10 gauges scored under each (the owner's bar, 2026-11-25); everything else the rule lists is reported and decides nothing.

### Result (2026-11-25)

**The donor pool stays HYDAT-only.** With the stations, the carried migration-window departure is worse: the median paired difference in RMSE is +0.032 leave-one-gauge-out (50 gauges scored, 16 better and 34 worse) and +0.015 leak-free (53 gauges, 17 better), against a bar of −0.01 [M, the report's sections 2 and 3]. The 90 % interval on each median lies above zero. Every other scored statistic and window has a positive median too, except the migration window's centre-of-volume day (cov_day), at −0.08 days leave-one-out and −0.09 leak-free, with intervals spanning zero.

What the reported lines show, deciding nothing:

- **The loss is in the year-to-year pattern, not only the level.** The centred log NSE on the scored years, which removes each series' mean, falls from 0.83 to 0.75 (leave-one-out); the mean signed error moves from −0.012 to −0.021. A station's fit on its 3 to 8 fit years gives slopes from −3.55 to 6.76 on the nearest extension gauge, so its estimated 1981–2010 mean, and every departure from it, carries that noise.
- **Short records are part of it; day status is not the cause.** Keeping only stations with at least 5 fit years shrinks the loss to +0.013 (23 gauges); dropping every window-year with an unchecked day makes it +0.077 (23 gauges), so leaving the unchecked days out does not reduce the loss. With k = 3 the loss is +0.065, with k = 8 +0.011; leaving out the stations at a HYDAT site whose gauge is in the box or regulated, +0.037. No sensitivity would ship.
- **A station takes a HYDAT donor's place, and that place costs little on its own.** A station among the five nearest pushes out a HYDAT gauge: 210 of 263 scored gauge-years have fewer HYDAT donors with the stations than without, and the ones kept are always among those without. In the 2011–2025 years in which none of the chosen stations has a value, the carry renormalises over the HYDAT donors left and the median difference is +0.001, so the loss comes from the stations' own departures.
- **Who they are:** 225 of 392 held-out gauges have a candidate in their box, but a station is among the five donors at only 75 on the migration mean, and 25 distinct stations stand behind the scored gauges: 10 on Vancouver Island (08H), 6 of the Water Tool's Horn River Basin gauges in the Liard drainage (HRB), 4 in the Columbia (08N), 3 in the Nechako (08J) and 2 in the Peace (07F).

Attribution: ours, in the method, not the stations' records. The test found no fault in their day status; the loss comes from estimating a 1981–2010 mean from 3 to 8 fit years (starting in 2010 or later at 31 of the 33 eligible stations; 1AHA040's are 1999–2002), which no current record can avoid. At the four chinook boxes nothing moves: Maxan's and Gosnell's two stations hold 2 window-years each, under the 3 a candidate needs; Swift's box holds none; Naver's four stations with 3 window-years were eligible donors here, and the verdict covers them. The test can be rerun as the records lengthen; with the most any station holds now at 8 fit years in the migration window, the next useful rerun is once several hold 10 or more. Joining a provincial station's days to the HYDAT gauge at its site, which would give two natural HYDAT gauges with a baseline their recent years (08JC017, 08NJ168), is #227.
