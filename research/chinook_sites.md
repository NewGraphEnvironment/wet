# Chinook pilot sites beyond Maxan: which streams, and what the method finds there

**Verified:** 2026-10-28 (the 1951–1980 against 2016–2025 section 2026-10-30; covariance_pick 2026-11-19; natural stations outside HYDAT as donors 2026-11-25) · **Issues:** #126 (component of #118; after #120, #121), #152, #147 (via #167), #202 (via #211; spawned #227) · **Produced by:** `scripts/chinook_sites_use.R` → `data/checks/chinook_sites_use.txt` (NuSEDS All Areas 2026-06-01, md5 25bb43441645519f18eb4853dd1cf399; fwapg `bcfishobs.observations`; HYDAT 2026-07-17); `scripts/departure_site.R` and `scripts/departure_site_snow.R` per site of `scripts/departure_sites.csv` → `data/checks/departure_site[_snow]_<site>_<group>_20260717.txt`; article `vignettes/articles/flow-change-sparse-gauges.Rmd` (listed in place of the Maxan article); `scripts/departure_donors.R` under the rule in `scripts/departure_donors_rule.R` → `data/checks/departure_donors_20260717_20261028.txt`

## Which streams, and why

#126 tests the Maxan method (#120, #121) at three more Chinook streams. Each target needs recorded Chinook use before it is fixed. Two sources count: NuSEDS, DFO's escapement database, matched to the stream on its FWA watershed code; and the provincial fish observations, matched on the stream's blue line. A NuSEDS use record is a row with adult presence or a spawner count above zero. A row reading "not inspected" or "none observed" does not count.

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

The Chinook windows are the Bulkley's (Gottesfeld and Rabnett 2007) at every site. Gosnell also runs under the Morice's (Bustard and Schell 2002: migration 05-01 to 09-30, spawning 09-01 to 10-07). No cited windows exist yet for the upper Fraser or the Cottonwood.

## What the method finds at each

The method is #120's, fixed at what shipped for Maxan: extension by OLS, k = 5, and carried departures by inverse distance, k = 5, each scored held out at the gauges in a box the same size as Maxan's, centred on the target. The `maxan` row reproduces #120's and #121's runs exactly (parity gates in both scripts). Change is 2011–2025 against the years before 1981, under the Bulkley windows unless named.

| site | box: extension pool | ols / ratio median NSE (#120's pick) | carried median NSE | spawning mean, carried (90 %) | spawning mean, extended (90 %) | migration mean, carried |
|---|---|---|---|---|---|---|
| Maxan (08EE018) | 21 | 0.50 / 0.42 (ols) | 0.63 | -46 % (-66..-17) | -56 % (-73..-28) | -3 % |
| Swift (08KA012) | 11, below #120's floor of 15 | 0.14 / 0.17 (ratio) | 0.51 | -12 % (-28..+6) | -25 % (-43..-2) | +2 % |
| Naver (08KE014) | 17 | 0.63 / 0.63 (ratio, within the margin) | 0.60 | -41 % (-63..-4) | -29 % (-55..+16) | -3 % |
| Gosnell (ungauged) | 18 | 0.48 / 0.35 (ols) | 0.65 | -35 % (-55..-5) | — | +4 % |
| Gosnell, Morice windows | 18 | 0.49 / 0.40 (ols) | 0.62 | -23 % (-47..+11) | — | -1 % |

- **Does Maxan's result hold?** The spawning-window drop and the flat migration window hold at all three. The drop is smallest at Swift. The carried route clears no change at Maxan, Naver and Gosnell under the Bulkley windows. Under the Morice's later windows, Gosnell's range reaches no change. This is attributed to the method and the windows, not to any product.
- **The extension does not travel as well as the carried departures.** In the upper Fraser box, whose eastern part (east of about -118.5°) is mostly Alberta and dropped by the BC filter, only 11 gauges have 30-year records, and OLS scores 0.14. #120's rule would ship ratio in two of the three new boxes, both times by a small margin. The carried departures clear #120's usable bar (0.5) on the migration-window mean in every box, and fall below it on the spawning-window mean in every box under the Bulkley windows, Maxan's included: 0.49 (Maxan), 0.43 (Swift), 0.42 (Naver), 0.45 (Gosnell). Under the Morice's windows Gosnell's box scores 0.66. The spawning-window intervals carry those held-out residuals, so they are wide, but the drop is the headline in the window where the carry is weakest.
- **The snow regression (#121, unchanged)** holds at every site. The carried migration-window departure rises with peak SWE, with a 90 % range above zero everywhere and R² 0.41 (Maxan), 0.41 (Swift), 0.51 (Naver) and 0.51 (Gosnell). In the spawning window R² is 0.01 (Maxan), 0.16 (Swift), 0.02 (Naver) and 0.04 (Gosnell). The 3,000 mm SWE cap binds in no watershed in any year, Swift's glacier-fed basin included (plan review item 18 is not borne out).
- **Gosnell's normal** is routed PCIC (`pick`) on mouth segment 139028198: 34.4 m³/s in the migration window and 8.7 in the spawning window (Bulkley windows). Its error at the 29 departure-pool gauges of its box with an accepted snap, as log(published / observed 1981–2010), has a median of +0.04 (migration) and +0.19 (spawning). In the spawning window that is a median of +21 % and an upper quartile of +60 %. The water balance's station-set flag marks a gauge as partly in sample only where its pick is the balance, and 25 of the 29 picks are routed PCIC, so the flag does not separate in-sample from out-of-sample here. The spawning-window normal is the weak part. The result at Gosnell itself is untested.
- **Naver's years since 1999** rest, for the migration-window mean, on 08KH006 to 2024 (2025 on 08KH001), and for the spawning-window mean on 08KC001 (08KG001 in 2008–2010 and 2013); not on the Quesnel at Likely or the West Road as the issue guessed. #120's donor rule needs a donor that covers every one of the target's 1956–1975 years.
- **Snow gauges** were chosen by the header's rule. One amendment was made after a run: an accepted snap is required, because Naver's second gauge by the rule, 08KD001, has none.

## 1951–1980 against 2016–2025 (#152)

The comparison article now measures change from 1951–1980 to 2016–2025. 1951–1980 comes before global warming sped up (Hansen et al. 2012, who chose it for that reason), and ERA5-Land's snow reaches back to 1950. Section 5 of each site report (registered at b66b577 before any body code) gives both routes over those periods, computed after #126's draws and outside the parity gate's `mx_core`. The rerun changed every report by additions only. Each period has 20–30 years of 1951–1980 and 9 or 10 of 2016–2025: approved HYDAT ends in 2024 for most series, and in 2025 for every Swift series and some of Naver's filled-in ones.

**The intervals hold their coverage.** Each interval was put through 1000 simulated no-change series, normal with the series' own SD in each period and the same residual pool. They covered 0.904–1.000. The article calls a change interval a 90 % range only above 0.87, so every change range it draws on qualifies; it does not call the years figure's OLS band a 90 % range, because its held-out coverage in the site reports is 83–85 %. Not tested: autocorrelated years, and donor sets that differ between the periods. The measured article's percentile bootstrap of a ratio of means has no residual. It covers only 0.834–0.867 at its 9 or 10 recent years (`data/checks/departure_interval_coverage.txt`), so that article does not call its range a 90 % range.

Change, Bulkley windows unless named, carried / extended, with the 90 % range:

| site | spawning mean | migration mean | spawning min7 | migration min7 |
|---|---|---|---|---|
| Maxan | -45 % (-67..-11) / -57 % (-76..-28) | -16 % (-35..+7) / -28 % (-46..-5) | -40 % (-63..-2) / -58 % (-78..-21) | -17 % / +4 % |
| Swift | -15 % (-32..+5) / -27 % (-47..0) | -5 % / -4 % | +1 % / -18 % | +49 % (-2..+123) / +55 % (+8..+125) |
| Naver | -46 % (-69..-5) / -40 % (-67..+6) | -11 % / 0 % | -33 % (-56..+5) / -25 % | -20 % / +14 % |
| Gosnell | -35 % (-56..-3) | -4 % | -26 % (-49..+13) | +38 % |
| Gosnell, Morice windows | -23 % (-50..+15) | -8 % | -31 % (-57..+10) | +12 % |

- **The spawning-window drop holds** on the earlier reference: it is largest at Maxan and Naver and smallest at Swift. The carried range clears no change at Maxan, Naver and Gosnell, as against before 1981.
- **The migration window** shows no clear change on the carried route at any site. Maxan's extended route, whose 1951–1980 years rest on the Bulkley at Quick (08EE004) and Goathorn Creek near Telkwa (08EE008), falls by 28 %, with a range below zero.
- **The lowest seven-day flow** in the spawning window, carried, falls at Maxan, Naver and Gosnell (the range clears no change only at Maxan) and holds at Swift (+1 %; extended, -18 %). Its carried held-out scores are below #120's 0.5 bar in 7 of the 8 site-windows (0.23–0.59), so it is the weakest statistic the article shows.
- **Snow** over each target's watershed, 1951–1980 to 2016–2025:
  - peak SWE fell 6–9 % (Maxan 260 → 235 mm, Swift 555 → 524, Naver 243 → 223, Gosnell 974 → 891);
  - the 50 % melt date came 9–16 days earlier.
  
  At the measured snow gauges, migration-window flow rises with peak SWE at all eight, with a range above zero and R² 0.25–0.62. In the spawning window R² is at most 0.31. The 50 % melt date explains more there at two gauges: 64–66 % of measured spawning-window flow at the Nanika (08ED001) and Morice (08ED002), Gosnell's snow gauges, under the Bulkley windows. Elsewhere it explains at most a third, and 18–19 % at those two gauges under the Morice's later windows.

## covariance_pick at the sites (#147)

#122 shipped `covariance_pick` at the calibration gauges: among the 15 nearest donors, the 5 whose routed PCIC years correlate best. Section 6 of each site report (rule registered in `scripts/departure_site.R`'s header at 68a983d, amended before any run at 37e0633) scores it against inverse distance at each box's covered gauges, leave-one-gauge-out and leak-free, on the migration-window mean. It ships where it wins by 0.01 under both, with at least 10 gauges scored, the target covered and at least 5 covered donors. PCIC's per-year files (fwapg commit 26d7582) come from wet's cache (#135). Sections 1–5 of every report are unchanged, Gosnell's aside (below).

| site (windows) | covered / box pool | distance | covariance_pick | leak-free (d / c) | ships |
|---|---|---|---|---|---|
| Maxan | 49 / 53 | 0.62 | 0.67 | 0.56 / 0.65 | covariance_pick |
| Swift | 27 / 30 | 0.55 | 0.61 | 0.56 / 0.56 | distance |
| Naver | 54 / 58 | 0.58 | 0.75 | 0.47 / 0.66 | covariance_pick |
| Gosnell | 50 / 54 | 0.64 | 0.67 | 0.57 / 0.65 | covariance_pick |
| Gosnell, Morice windows | 50 / 54 | 0.62 | 0.66 | 0.57 / 0.66 | covariance_pick |

(Median per-gauge centred log NSE, migration mean, over the covered gauges; both weightings on the same gauges and years.)

- **Coverage:** PCIC covers every box, the Morice and upper Fraser included. The uncovered gauges are three or four per box (08EC014 and 08JA002/005/006 in the Skeena boxes).
- **Where it ships, the borrowed route moves.** 1951–1980 to 2016–2025, Bulkley windows, carried under covariance_pick:

  | site | spawning mean | migration mean | spawning min7 | migration min7 |
  |---|---|---|---|---|
  | Maxan | -66 % (-82..-36) | -30 % (-49..-4) | -65 % (-81..-37) | -42 % (-68..+3) |
  | Naver | -35 % (-59..+2) | -13 % | -30 % (-52..+4) | -16 % |
  | Gosnell | -29 % (-48..-5) | -10 % | -37 % (-56..-15) | -20 % |
  | Gosnell, Morice windows | -16 % (-42..+23) | -14 % | -27 % (-48..+3) | -47 % (-66..-19) |

  Every interval's measured coverage is 0.92 or more. Maxan's migration-window drop is now clear of no change.
- **Maxan's 1951–1980 base is 10 years** under covariance_pick: its donors (08EE003, 08EE013, 08JA016, and 08JB002 for max) hold no record from 1952 to 1970, against 20–30 years on every other route.
- **Held-out scores rise** wherever it ships, most in the spawning window (Maxan 0.49 → 0.66, Naver 0.42 → 0.60, Gosnell 0.45 → 0.71) and for the lowest seven-day flow, now below the 0.5 bar in 4 of 8 site-windows rather than 7.
- **Gosnell's normal-error rows moved** for another reason: the published build changed under the report (digest 0f4f8caa → d554e3aa, #163's upload of LEUT, UEUT and UNRS on 2026-11-14), so four Nechako box gauges' picked source and the error quartiles changed. The mouth's normal did not.
- **The stations beyond HYDAT** (#142, #144) add no donor at these sites (`research/station_sources.md`, "At the chinook sites' boxes"), and held out province-wide they make carried departures worse (below).
- The short-record article stays on distance at Maxan, #120's record; the comparison article carries the shipped route.

## Natural stations outside HYDAT as donors (#202, via #211)

**Registered:** 2026-11-25, before any score existed. The rule is the header of `scripts/departure_donors_rule.R`; the scoring script, `scripts/departure_donors.R`, refuses to run when that file differs from its registering commit.

The question: does adding the natural stations outside HYDAT (the province's non-integrated network, #142, and the BC Water Tool's gauges, #144, with `regulation == "natural"` from #196) bring a carried departure closer to the observed one?

As seen before registration (2026-11-25, throwaway probes; the report's section 1 restates them from its own data): of the 75 natural stations none has 10 complete migration window-years in 1981–2010, so none has the baseline `wet_departure_carry()` needs, and 71 have none at all. They hold 185 complete migration window-years, 179 of them in 2010 or later; 36 stations have at least 3, 33 through 2024. A third of those window-years are unchecked throughout. In the four chinook boxes, Maxan and Gosnell hold 2 such stations with 2 window-years each, Swift none and Naver 6, so no site report could move.

The only route open is an estimated baseline: each station is extended into 1981–2010 from HYDAT gauges by OLS, as #120 extends a short-record target, and its observed years then depart from that estimated mean. An OLS fit's residuals sum to zero over its fit years, so a station's level over those years is its extension gauge's; only its year-to-year variation is its own, with one or two degrees of freedom at 3 or 4 years. No gain is the likely result today.

The test, held out province-wide: every natural HYDAT gauge in its own box's departure pool, with a box of #126's size centred on it, carried by #120's inverse-distance route (k = 5) with and without the stations, each station's fit years stopping at 2024 (the last year HYDAT 20260717's approved record is broadly complete) and its later years entering as observed. The score is the RMSE of the log departure from the gauge's own 1981–2010 mean over the 2011–2025 years a station is among the donors. The route ships if the median paired difference is at most −0.01 leave-one-gauge-out and leak-free, with at least 10 gauges scored under each (the owner's bar, 2026-11-25); everything else the rule lists is reported and decides nothing.

### Result (2026-11-25)

**The donor pool stays HYDAT-only.** With the stations, the carried migration-window departure is worse: the median paired difference in RMSE is +0.032 leave-one-gauge-out (50 gauges scored, 16 better and 34 worse) and +0.015 leak-free (53 gauges, 17 better), against a bar of −0.01 [M, the report's sections 2 and 3]. The 90 % interval on each median lies above zero. Every other scored statistic and window has a positive median too, except the migration window's centre-of-volume day (cov_day), at −0.08 days leave-one-out and −0.09 leak-free, with intervals spanning zero.

What the reported lines show, deciding nothing:

- **The loss is in the year-to-year pattern, not only the level.** The centred log NSE on the scored years, which removes each series' mean, falls from 0.83 to 0.75 (leave-one-out); the mean signed error moves from −0.012 to −0.021. A station's fit on its 3 to 8 fit years gives slopes from −3.55 to 6.76 on the nearest extension gauge, so its estimated 1981–2010 mean, and every departure from it, carries that noise.
- **Short records are part of it; day status is not the cause.** Keeping only stations with at least 5 fit years shrinks the loss to +0.013 (23 gauges); dropping every window-year with an unchecked day makes it +0.077 (23 gauges), so leaving the unchecked days out does not reduce the loss. With k = 3 the loss is +0.065, with k = 8 +0.011; leaving out the stations at a HYDAT site whose gauge is in the box or regulated, +0.037. No sensitivity would ship.
- **A station takes a HYDAT donor's place, and that place costs little on its own.** A station among the five nearest pushes out a HYDAT gauge: 210 of 263 scored gauge-years have fewer HYDAT donors with the stations than without, and the ones kept are always among those without. In the 2011–2025 years in which none of the chosen stations has a value, the carry renormalises over the HYDAT donors left and the median difference is +0.001, so the loss comes from the stations' own departures.
- **Who they are:** 225 of 392 held-out gauges have a candidate in their box, but a station is among the five donors at only 75 on the migration mean, and 25 distinct stations stand behind the scored gauges: 10 on Vancouver Island (08H), 6 of the Water Tool's Horn River Basin gauges in the Liard drainage (HRB), 4 in the Columbia (08N), 3 in the Nechako (08J) and 2 in the Peace (07F).

Attribution: ours, in the method, not the stations' records. The test found no fault in their day status; the loss comes from estimating a 1981–2010 mean from 3 to 8 recent years, which no current record can avoid. At the four chinook boxes nothing moves: Maxan's and Gosnell's two stations hold 2 window-years each, under the 3 a candidate needs; Swift's box holds none; Naver's four stations with 3 window-years were eligible donors here, and the verdict covers them. The test can be rerun as the records lengthen; with the most any station holds now at 8 fit years, the next useful rerun is once several hold 10 or more. Joining a provincial station's days to the HYDAT gauge at its site, which would give two natural HYDAT gauges with a baseline their recent years (08JC017, 08NJ168), is #227.
