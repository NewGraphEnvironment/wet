# Findings — Second-region Chinook pilots (#126)

## Issue context

**If we do it:** the Maxan method (#120) and the snow explanation (#121) are tested at three more Chinook streams, with the method fixed in advance, so a result at Maxan is either shown to hold elsewhere or found to be Bulkley-specific, and the method gets its first test at a stream with no gauge at all. **If we never do:** every claim about change in Chinook-window flow rests on one site in one snow regime, and on a stream that was at least gauged for five years.

Component of #118. After #121, so the snow regression runs here unchanged.

## Targets

Two cases, deliberately different (revised 2026-10-28; the earlier draft listed the Cottonwood main stem and an unnamed Morice spot):

- **Short record, extended (Maxan's case):** Swift Creek (UFRA) and Naver Creek (COTR). Each target is a discontinued gauge, its record extended from long-record neighbours and scored on its own observed years.
- **No gauge (the case #118 is about):** Owen Creek (MORR). With no record there is nothing to extend and nothing at the place to score against, so only the carried departures run there: neighbours' departures applied to Owen's own normal from wet's published segment flows. The method is scored at the gauges in the same box, and the report says that the result at Owen itself is untested.

Counts are from HYDAT 2026-07-17, as complete Chinook migration windows under the Bulkley timing (measured 2026-10-26); areas for ungauged points are the FWA watershed at the stream's mouth (2026-10-28). Suggested order: UFRA, COTR, MORR.

**UFRA, Swift Creek at Valemount.** Two short records on the creek, either side of 1981, and long neighbours, in a glacier- and snow-fed Rocky Mountain Trench regime. The target is one of the two creek gauges, chosen at the plan gate.

| station | name | km² | migration windows |
|---|---|---|---|
| 08KA010 | Swift Creek above Barrett Creek | 111 | 9 (1972–1980) |
| 08KA012 | Swift Creek near the mouth | 132 | 14 (1985–1998) |
| 08KA011 | McLennan River near the mouth | 524 | 5 (1981–1985) |
| 08KA007 | Fraser River at Red Pass | 1,700 | 70 (1956–2025) |
| 08KA005 | Fraser River at McBride | 6,882 | 72 (1953–2024) |
| 08KA001 | Dore River near McBride | 408 | 62 (1950–52, 1967–2025) |
| 08KA009 | McKale River near 940 m contour | 254 | 51 (1972–2023) |
| 08NC004 | Canoe River below Kimmel Creek | 307 | 51 (1972–2025) |

**COTR, Naver Creek at Hixon (08KE014).** A Fraser tributary in the Cottonwood group, gauged 1956–1975 at 651 km² (908 km² at its mouth; the target is the gauge, so the extended flows sit where flow was measured). Its nearest overlapping neighbour, the Cottonwood River near Cinema, recorded 1954–1999, so it covers all of Naver's years; but both are discontinued, so the years since 1999, where the change shows, rest on Little Swift, Baker, the Quesnel at Likely and the West Road. That is a harder test of the extension than Maxan's. Interior Plateau, with a dense long-record network nearby.

| station | name | km² | migration windows |
|---|---|---|---|
| 08KE014 | Naver Creek at Hixon (target) | 651 | 18 (1956–1975) |
| 08KE009 | Cottonwood River near Cinema | 1,897 | 44 (1955–1998) |
| 08KE024 | Little Swift River at the mouth | 129 | 52 (1972–2024) |
| 08KH001 | Quesnel River at Likely | 5,964 | 100 (1925–2025) |
| 08KG001 | West Road River near Cinema | 12,390 | 69 (1955–2024) |
| 08KE016 | Baker Creek at Quesnel | 1,567 | 60 (1964–2024) |
| 08KH003 | Cariboo River below Kangaroo Creek | 3,259 | 66 (1927–1994) |

**MORR, Owen Creek.** A Morice River tributary, 224 km² at its mouth, with no HYDAT station. It shares Maxan's regime and neighbours: the Morice near Houston (08ED002, 1961–2024) and the Nanika (08ED001, 1950–2024) were among Maxan's donors. The carried departures are scored, held out, at the gauges in the box, the small Thautil Corner Creek (08ED004, 10.6 km², flow 1997–2024) among them, and Owen's normal comes from wet's published segment flows (`pick`), so the result inherits that normal's error, which is reported beside it.

Chinook use at each target, Owen and Naver especially, is not yet checked; it comes from the same per-stream salmon records as #137 (NuSEDS, the provincial fish observations, the literature) and is settled before a target is fixed.

## Timing

Explore each place first with the Bulkley Chinook windows (`inst/vignette-data/life_history_bulk.csv`: migration 05-01 to 08-01, spawning 08-01 to 09-15). The method does not depend on the dates, and timing may be similar across these stocks because flow and temperature drive it.

Each place's own windows come from a cited life-history timing table kept in a separate repository (to be named here once it is public), which is where the timing work is done: NuSEDS escapement records, a literature review and a search of the Pacific Salmon Foundation's library, per watershed group and species. Where those windows differ from the Bulkley's, rerun under them and report both. The Morice already has cited Chinook windows there (Bustard and Schell 2002): migration 05-01 to 09-30 and spawning 09-01 to 10-07, a month later than the Bulkley's spawning window, so for Owen the second run is not optional.

## Approach

- **Key everything on a site table, so a stream or station swaps in as a data edit.** One row per place (id, target station or FWA point, donor box, timing source, streams to label); the pilot, snow, data and map scripts take a site id and name their outputs by it. Maxan, hard-coded across five files today, moves onto it later, not in this issue.
- **One comparison article, unlisted until promoted (decided 2026-10-28).** How Chinook-window flow changed at Maxan, Swift, Naver and Owen side by side, with how well the method scored at each, answering whether the Maxan result holds elsewhere. It lives in `vignettes/articles/` (built for the site only, not shipped in the package) under a pkgdown `internal` section, so it has a working link but no place in the Articles index; promoting it is moving one line in `_pkgdown.yml`. The first build checks that an `internal` section is also kept out of the navbar menu. A page for one stream alone is made later from the same site table, only if someone needs it.
- Reuse `wet_window_extend()` and `wet_departure_carry()` and the scoring in `scripts/departure_pilot.R`, with a box per place and its rule registered in the script's header before any candidate is coded, as #120 did. At Owen only `wet_departure_carry()` runs, on a published normal.
- Fix each target from the tables above, with its Chinook use, before the rule is registered.
- Run #121's snow regression at each place unchanged.
- Run time is minutes, not hours: the pilot ran in about 2 min 40 s and the snow regression in 9 s (2026-10-26).

Relates to #118, #120, #121, #122, #137.




## Plan-mode exploration (2026-10-28)

- Provincial fish observations (`bcfishobs.observations` joined to `fwa_stream_networks_sp` by linear_feature_id), Chinook (CH):
  - Swift Creek (UFRA): 17 records 1974–2012, fry; "major spawning location"; all within 6 km of the mouth (route measure 0–5,984 m). 08KA012 is at -119.2667, 52.8383 (lower creek); 08KA010 at -119.1964, 52.8769, upstream of every record.
  - Naver Creek (COTR): 25 records 1988–2012, fry and parr; spawning, major spawning and rearing.
  - Owen Creek (MORR): no CH. CO 1 (1984), DV 6, LNC 4, MW 3, PK 1 (2009), RB 4, SST 1 (1999), SU 1.
  - MORR CH by stream: Nanika 11, unnamed 11, Morice 10, Lamprey 4, Gosnell 3, Shea 2, Atna, McBride, Thautil, Cedric 1 each. Spawning records only on the Nanika and the Morice.
  - Lamprey Creek (blk 360880441): 1984-09 (FISS 95984, 434 m), 1996 (FISS 106560, 211 m), 1999-02 (FISS 95866, 32 m), 2009-08-18 (Stantec, FDIS 117167, 1,477 m). "Fish observed", no life stage.
  - Gosnell Creek (blk 360885021): FISS 185860 (1979–81 inventories, 6,426 m), FISS 130132 (1984 Kemano baseline, 180 m), FISS 281286 (1999 beaver monitoring, 38 m).
- FWA basin area (sum of `fwa_watersheds_poly` under the stream's wscode, MORR): Gosnell 536.9 km², Lamprey 240.2, Owen 212.5 (the issue says 224), Shea 195.0. `postgisftw.fwa_watershedatmeasure(blk, 1)` errored on the PG* server.
- HYDAT 20260717: no station on Gosnell, Lamprey, Owen or Shea. 08ED stations: 08ED001 Nanika, 08ED002 Morice near Houston, 08ED003 Morice at the mouth, 08ED004 Thautil Corner Creek.
- Timing: knowledge's `data/life_history_timing.csv` (private repo, c97c4d0 2026-09-29) holds BULK and MORR only. MORR CH: migration 05-01..09-30 and spawning 09-01..10-07 (bustard_schell2002ConservingMorice). Nothing for UFRA or COTR.
- Code: `scripts/departure_pilot.R` (835 lines) hard-codes the box, the three pilot gauges and their count checks. `scripts/departure_snow.R` hard-codes the gauges, the fundamental watershed ids (08EE003 7653689, 08EE013 7619666, 08EE018 9939958) and the count guards. `scripts/departure_pcic.R` copies the box and Maxan as well.
- `_pkgdown.yml` has no `articles:` section, so pkgdown lists every vignette automatically.
- Under the pilot's donor rule, an extension donor needs a value in every one of the target's observed years. Naver 1956–1975 therefore rules out Little Swift (from 1972) and Baker (from 1964), against the issue's sentence.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `postgisftw.fwa_watershedatmeasure()` failed inside its own SQL on the PG* server | Summed `fwa_watersheds_poly` under the stream's wscode_ltree instead |

## Phase 1 (2026-10-28)

- NuSEDS's `FWA_WATERSHED_CDE` equals FWA's `fwa_watershed_code` exactly for all five streams, so match on it rather than on names. Owen Creek also exists in NuSEDS area 13 (Johnstone Strait), a different stream.
- NuSEDS Chinook at Owen (4D): 11 rows, all uninspected or none observed. Gosnell: 29 rows, 1 PRESENT (2001). Lamprey: no Chinook rows (coho 20, sockeye 1).
- The local `fresh-db` (WET_PG* defaults) holds `bcfishobs` too, with the same counts as the PG* server.

## Phase 4 results (2026-10-28, first full runs)

- **Parity:** `departure_site.R maxan` reproduces #120's `mx` exactly (identical()). Every report line outside the header and the new carried-interval columns is byte-equal to the pilot report, leak-free lines included. `departure_site_snow.R maxan` reproduces #121's `fits` and series exactly; 19 lines differ, wording only.
- **Swift (08KA012), UFRA box:** 44 natural gauges, box pool 30, extension pool 11 (below #120's floor of 15; most of the box east of about -118.5 is Alberta). The extension race is weak: ols 0.14, move1 -0.24, ratio 0.17, so #120's rule would pick ratio. Carried 0.51 (usable). The donor chain starts at 08LB038, a Thompson-side gauge.
- **Naver (08KE014), COTR box:** box pool 58, extension 17. ols 0.634 against ratio 0.631, so #120's rule would pick ratio (within the 0.01 margin). Carried 0.60. The years since 1999 come from 08KH006, not from the Quesnel at Likely or the West Road as the issue guessed; 08KE009 Cottonwood supplies 1976–1998.
- **Gosnell (ungauged), MORR box:** ols 0.48 against ratio 0.35 under the Bulkley windows (ols also under the Morice's, 0.49). Carried 0.65 (Bulkley windows) and 0.62 (Morice). Normal: routed PCIC (pick) on mouth segment 139028198, migration 34.4 m3/s and spawning 8.7 m3/s under the Bulkley windows. Its error at 29 box gauges: median log ratio +0.035 for migration and +0.19 for spawning; at the 7 outside the balance's station set, +0.035 and +0.24.
- **Spawning-window mean, carried change** (2011–2025 against before 1981, Bulkley windows): Maxan -46 %, Swift -12 %, Naver -41 %, Gosnell -35 %; under the Morice windows Gosnell -23 % (90 % range -47 to +11). Migration-window mean, carried: -3 %, +2 %, -3 %, +4 %.

## Errors Encountered (Phase 4)

| Error | Resolution |
|-------|------------|
| Gosnell: area parse took column 5 of a row whose stream name has two words | Regex on the number after the role column |
| duckdb: `source` not a column with `hive_partitioning = false` | Take the source from the catalog row, as `wet_segment_parts()` does |
