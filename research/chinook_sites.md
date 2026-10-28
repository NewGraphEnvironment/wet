# Chinook pilot sites beyond Maxan: which streams, and what the method finds there

**Verified:** 2026-10-28 · **Issues:** #126 (component of #118; after #120, #121) · **Produced by:** `scripts/chinook_sites_use.R` → `data/checks/chinook_sites_use.txt` (NuSEDS All Areas 2026-06-01, md5 25bb43441645519f18eb4853dd1cf399; fwapg `bcfishobs.observations`; HYDAT 2026-07-17)

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
- **The ungauged Morice stream: Gosnell Creek.** Owen Creek, the issue's first choice, has no provincial Chinook record, and its 11 NuSEDS rows are all uninspected or empty. The user's rule (2026-10-28) took whichever of Gosnell and Lamprey has more use records and no gauge. They tie at 4. Gosnell's one NuSEDS adult-presence record (2001) is the only spawning record of either, so Gosnell is the target. Its provincial records are inventories from 1981 to 1999. Spawning records in the Morice group sit on the Nanika and the Morice main stem.

The Chinook windows are the Bulkley's (Gottesfeld and Rabnett 2007) at every site. Gosnell also runs under the Morice's (Bustard and Schell 2002: migration 05-01 to 09-30, spawning 09-01 to 10-07). No cited windows exist yet for the upper Fraser or the Cottonwood.
