# Chinook pilot sites beyond Maxan: which streams, and what the method finds there

**Verified:** 2026-10-28 · **Issues:** #126 (component of #118; after #120, #121) · **Produced by:** `scripts/chinook_sites_use.R` → `data/checks/chinook_sites_use.txt` (NuSEDS All Areas 2026-06-01, md5 25bb43441645519f18eb4853dd1cf399; fwapg `bcfishobs.observations`; HYDAT 2026-07-17); `scripts/departure_site.R` and `scripts/departure_site_snow.R` per site of `scripts/departure_sites.csv` → `data/checks/departure_site[_snow]_<site>_<group>_20260717.txt`; article `vignettes/articles/chinook-sites.Rmd` (unlisted)

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
- **The ungauged Morice stream: Gosnell Creek.** Owen Creek, the issue's first choice, has no provincial Chinook record, and its 11 NuSEDS rows are all uninspected or empty. The user's rule (2026-10-28) took whichever of Gosnell and Lamprey has more use records and no gauge. They tie at 4. Gosnell's one NuSEDS adult-presence record (2001) is the only spawning record of either, so Gosnell is the target. That tie-break is by definition: a NuSEDS adult-presence record counts as a spawning record, and neither creek has a provincial spawning record. Its provincial records are inventories from 1981 to 1999. Spawning records in the Morice group sit on the Nanika and the Morice main stem.

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
- **The extension does not travel as well as the carried departures.** In the upper Fraser box, whose eastern part (east of about -118.5°) is mostly Alberta and dropped by the BC filter, only 11 gauges have 30-year records, and OLS scores 0.14. #120's rule would ship ratio in two of the three new boxes, both times by a small margin. The carried departures clear #120's usable bar (0.5) in every box.
- **The snow regression (#121, unchanged)** holds at every site. The carried migration-window departure rises with peak SWE, with a 90 % range above zero everywhere and R² 0.41 (Maxan), 0.41 (Swift), 0.51 (Naver) and 0.51 (Gosnell). In the spawning window R² is 0.01 (Maxan), 0.16 (Swift), 0.02 (Naver) and 0.04 (Gosnell). The 3,000 mm SWE cap binds in no watershed in any year, Swift's glacier-fed basin included (plan review item 18 is not borne out).
- **Gosnell's normal** is routed PCIC (`pick`) on mouth segment 139028198: 34.4 m³/s in the migration window and 8.7 in the spawning window (Bulkley windows). Its error at the 29 box gauges, as log(published / observed 1981–2010), has a median of +0.04 (migration) and +0.19 (spawning). At the 7 gauges outside the water balance's station set, the median |log ratio| is 0.08 and 0.70 (a factor of about 2). The spawning-window normal is the weak part. The result at Gosnell itself is untested.
- **Naver's years since 1999** rest on 08KH006, not on the Quesnel at Likely or the West Road as the issue guessed. #120's donor rule needs a donor that covers every one of the target's 1956–1975 years.
- **Snow gauges** were chosen by the header's rule. One amendment was made after a run: an accepted snap is required, because Naver's second gauge by the rule, 08KD001, has none.
