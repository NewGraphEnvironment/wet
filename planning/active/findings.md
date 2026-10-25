# Findings — Maxan Creek Chinook pilot: extend 08EE018's window flows from its neighbours and score donor-carried departures, HYDAT only (#120)

## Issue context

**If we do it:** flow in the Chinook migration and spawning windows at Maxan Creek is known per year from 1930 to 2025, with an error per year, from five observed years and two long-record neighbours, and donor-carried departures have their first held-out score. **If we never do:** #118 has no measured starting point, and every later step builds on an estimator nobody has tested.

Component 1 of #118. Needs no new data: HYDAT release 20260717 (`WET_HYDAT_RELEASE`) and the functions wet already has.

## Problem

Every flow wet publishes at a segment is a 1981–2010 normal. A question about change over time (how much flow did Chinook have in the migration window before 1980 against the last 15 years) can be answered only at a gauge, and Maxan Creek's gauge ran for five years.

What HYDAT 2026-07-17 holds (measured 2026-10-24):

| station | name | km² | flow record | years with the full migration window |
|---|---|---|---|---|
| 08EE018 | Maxan Creek above Bulkley Lake | 363.4 | 1974–1979, discontinued | 5 (1975–1979; both windows complete) |
| 08EE003 | Bulkley River near Houston | 2,319 | 1930–2025 | 43, 11 before 1981 |
| 08EE013 | Buck Creek at the mouth | 568.6 | 1973–2025 | 51, 8 before 1981 |

Windows: the `CH` rows of `inst/vignette-data/life_history_bulk.csv`, migration 05-01 to 08-01 and spawning 08-01 to 09-15.

## Proposed approach

1. **Window series per gauge and year.** `wet_station_daily()` then `wet_window_stats()` on the two windows, for the three gauges and for every HYDAT gauge in the Bulkley and neighbouring watershed groups with at least three complete window years (count them at plan time; they are the independent tests, since Houston contains Maxan).
2. **Record extension.** Relate 08EE018's window values in 1975–1979 to 08EE003 and 08EE013, and extend across 1930–2025 with a prediction interval per year. Candidates: regression in log space, the line of organic correlation (MOVE.1), and a ratio of means; at window level and day by day. Leave-one-year-out over the five years is the error check.
3. **Donor-carried departures.** Baseline and anomaly at each donor through cd (`cd_baseline()`, `cd_anomaly()`), the weighted anomaly carried with `wet_donor_mean()` onto the target's own baseline, scored at the target's observed years. Score at Maxan and at every short-record gauge from step 1.
4. **The rule first.** The scoring rule (statistic, held-out set, margin over the no-departure baseline) is registered in the script's header and committed before any candidate is coded, as #15, #70 and #102 did.
5. **Outputs.** `scripts/departure_pilot.R`, a report under `data/checks/`, and the findings in `research/station_flow_departure.md`. Nothing is published.

## Decisions for the plan gate

- Which window statistics count: mean, `min7`, `max`, and the date of half the window's volume (a new `wet_window_stats()` statistic).
- The periods: a pre-1980 baseline against the last 15 years, a trend over the whole record, or both.
- Whether a departure is carried as a ratio or a log difference.
- The donor pool and `k`.

Relates to #118, #25, #102, #70.


## Regional gauge pool, measured 2026-10-24 on HYDAT 20260717

Box lon −128.8…−125.0, lat 53.6…55.8. 94 BC gauges; 58 with ≥3 complete migration-window years (≥80 % of the 93 days 05-01…08-01); 53 natural (`REGULATED = 0`); 13 with ≤10 years. Complete years counted from `DLY_FLOWS` days present, not `wet_window_stats()` (which also requires the window-year to lie inside the record), so Phase 2 may differ by one at a record's ends (08EE003: 43 in the issue, 44 here).

| station | name | km² | reg | mig yrs | spw yrs | first | last | pre-1981 | 2011– |
|---|---|---|---|---|---|---|---|---|---|
| 08EE004 | Bulkley River At Quick | 7341 | 0 | 94 | 94 | 1931 | 2024 | 50 | 14 |
| 08EF001 | Skeena River At Usk | 42270 | 0 | 92 | 92 | 1928 | 2024 | 48 | 14 |
| 08JB002 | Stellako River At Glenannan | 4004 | 0 | 77 | 78 | 1930 | 2025 | 32 | 15 |
| 08JA013 | Skins Lake Spillway, Nechako Reservoir | 14000 | 1 | 70 | 70 | 1956 | 2025 | 25 | 15 |
| 08ED002 | Morice River Near Houston | 1889 | 0 | 63 | 63 | 1962 | 2024 | 19 | 14 |
| 08EE008 | Goathorn Creek Near Telkwa | 121.300003051758 | 0 | 63 | 64 | 1961 | 2024 | 19 | 14 |
| 08EB004 | Kispiox River Near Hazelton | 1859 | 0 | 60 | 61 | 1965 | 2024 | 16 | 14 |
| 08EC004 | Pinkut Creek Near Tintagel | 790.200012207031 | 1 | 60 | 61 | 1962 | 2024 | 18 | 14 |
| 08EF005 | Zymoetz River Above O.K. Creek | 2919 | 0 | 59 | 60 | 1964 | 2023 | 17 | 12 |
| 08FF001 | Kitimat River Below Hirsch Creek | 1999 | 0 | 59 | 60 | 1965 | 2024 | 15 | 14 |
| 08FF002 | Hirsch Creek Near The Mouth | 353.5 | 0 | 58 | 58 | 1966 | 2023 | 15 | 13 |
| 08FF003 | Little Wedeene River Below Bowbyes Creek | 180 | 0 | 58 | 60 | 1967 | 2025 | 13 | 15 |
| 08JB008 | Nadina River At Outlet Of Nadina Lake | 376.100006103516 | 1 | 57 | 60 | 1966 | 2024 | 13 | 14 |
| 08ED001 | Nanika River At Outlet Of Kidprice Lake | 719.599975585938 | 0 | 54 | 56 | 1950 | 2024 | 11 | 14 |
| 08EC013 | Babine River At Outlet Of Nilkitkwa Lake | 6729 | 0 | 53 | 53 | 1972 | 2024 | 9 | 14 |
| 08EE012 | Simpson Creek At The Mouth | 13.3500003814697 | 0 | 52 | 52 | 1969 | 2024 | 8 | 14 |
| 08EE013 | Buck Creek At The Mouth | 568.599975585938 | 0 | 51 | 50 | 1973 | 2024 | 8 | 13 |
| 08EE020 | Telkwa River Below Tsai Creek | 364.600006103516 | 0 | 49 | 49 | 1976 | 2024 | 5 | 14 |
| 08JA015 | Laventie Creek Near The Mouth | 81.4300003051758 | 0 | 47 | 47 | 1977 | 2023 | 4 | 13 |
| 08EE003 | Bulkley River Near Houston | 2319 | 0 | 44 | 44 | 1931 | 2024 | 12 | 14 |
| 08EE025 | Two Mile Creek In District Lot 4834 | 19.8199996948242 | 0 | 42 | 42 | 1983 | 2024 | 0 | 14 |
| 08EB005 | Skeena River Above Babine River | 12590 | 0 | 41 | 41 | 1971 | 2024 | 10 | 14 |
| 08EC001 | Babine River At Babine | 6331 | 0 | 41 | 41 | 1930 | 1985 | 36 | 0 |
| 08EG011 | Zymagotitz River Near Terrace | 372.5 | 0 | 34 | 34 | 1961 | 1994 | 20 | 0 |
| 08ED004 | Thautil Corner Creek Near Morice Lake | 10.6400003433228 | 0 | 27 | 27 | 1998 | 2024 | 0 | 14 |
| 08EF006 | M3 Creek Near Smithers | 9.75 | 0 | 27 | 25 | 1998 | 2024 | 0 | 14 |
| 08FF006 | Renegade Creek Near Kitimat | 5.46000003814697 | 0 | 27 | 28 | 1998 | 2024 | 0 | 14 |
| 08EC014 | Twain Creek Tributary Near Babine Lake | 9.81999969482422 | 0 | 26 | 24 | 1998 | 2024 | 0 | 13 |
| 08JA029 | Whitesail Middle Creek Near Tahtsa Reach | 5.8899998664856 | 0 | 26 | 26 | 1998 | 2023 | 0 | 13 |
| 08EB003 | Skeena River At Glen Vowell | 25960 | 0 | 25 | 25 | 1961 | 1985 | 20 | 0 |
| 08EE014 | Canyon Creek Near Smithers | 247.699996948242 | 1 | 23 | 23 | 1973 | 1995 | 8 | 0 |
| 08JB013 | North Beach Creek Above Allin Creek | 7.15999984741211 | 0 | 23 | 25 | 1998 | 2023 | 0 | 11 |
| 08EE005 | Bulkley River Near Smithers | 8899 | 0 | 22 | 23 | 1947 | 2024 | 7 | 13 |
| 08JA002 | Ootsa River At Ootsa Lake | 4450 | 0 | 21 | 23 | 1930 | 1952 | 21 | 0 |
| 08EG006 | Kitsumkalum River Near Terrace | 2191 | 0 | 20 | 21 | 1930 | 1950 | 20 | 0 |
| 08EG017 | Deep Creek Above Reservoir | 13.5 | 0 | 18 | 17 | 1992 | 2009 | 0 | 0 |
| 08EB006 | Compass Creek Near Kispiox | 18.9899997711182 | 0 | 17 | 17 | 1998 | 2014 | 0 | 4 |
| 08JA016 | Macivor Creek Near The Mouth | 55.4199981689453 | 0 | 16 | 18 | 1977 | 1995 | 4 | 0 |
| 08JA005 | Tahtsa River Near Ootsa Lake | 1442 | 0 | 15 | 22 | 1931 | 1952 | 15 | 0 |
| 08FF005 | Kilometre 18.9 Creek Near Kitimat | 12.5200004577637 | 0 | 13 | 13 | 1997 | 2009 | 0 | 0 |
| 08JA003 | Whitesail River Near Ootsa Lake | 1013 | 0 | 13 | 19 | 1932 | 1952 | 13 | 0 |
| 08EE010 | Kathlyn Creek Above Simpson Creek | 19.0400009155273 | 0 | 12 | 9 | 1967 | 1979 | 12 | 0 |
| 08EF003 | Zymoetz River Near Terrace | 3021 | 0 | 12 | 13 | 1952 | 1964 | 12 | 0 |
| 08EE028 | Station Creek Above Diversions | 10.1199998855591 | 0 | 11 | 11 | 1985 | 1995 | 0 | 0 |
| 08EF004 | Kitseguecla River Near Skeena Crossing | 702 | 0 | 11 | 11 | 1961 | 1971 | 11 | 0 |
| 08EE001 | Bulkley River Near Hazelton | 12070 | 0 | 10 | 11 | 1928 | 1941 | 10 | 0 |
| 08EE009 | Richfield Creek Near Topley | 161.800003051758 | 0 | 10 | 10 | 1965 | 1974 | 10 | 0 |
| 08JB012 | Endako River At Outlet Of Burns Lake | 788.200012207031 | 0 | 9 | 8 | 1996 | 2004 | 0 | 0 |
| 08EC002 | Fulton River At The Mouth | 1419 | 1 | 7 | 8 | 1964 | 1970 | 7 | 0 |
| 08JE005 | Kazchek Creek Near The Mouth | 850.5 | 0 | 7 | 7 | 1980 | 1989 | 1 | 0 |
| 08EG019 | Kitsumkalum River Below Alice Creek | 2067 | 0 | 6 | 6 | 2019 | 2024 | 0 | 6 |
| 08EE018 | Maxan Creek Above Bulkley Lake | 363.399993896484 | 0 | 5 | 5 | 1975 | 1979 | 5 | 0 |
| 08JA006 | Tahtsa River At Outlet Of Tahtsa Lake | 659.799987792969 | 0 | 5 | 6 | 1931 | 1953 | 5 | 0 |
| 08JB006 | Nadina River Near Noralee | 1032 | 0 | 5 | 8 | 1951 | 1958 | 5 | 0 |
| 08EB007 | Kitwanga River Near Kitwanga | 820 | 0 | 4 | 4 | 2021 | 2024 | 0 | 4 |
| 08EC008 | Morrison River At Outlet Of Morrison Lake | 436.600006103516 | 0 | 3 | 5 | 1966 | 1970 | 3 | 0 |
| 08JA025 | Kasalka Creek At The Mouth | 222.199996948242 | 0 | 3 | 3 | 1993 | 1995 | 0 | 0 |
| 08JA026 | Mount Baptiste Creek Below 1040 M Contour | 81.3600006103516 | 0 | 3 | 3 | 1993 | 1995 | 0 | 0 |

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Rule registered (Phase 1, 2026-10-25)

`scripts/departure_pilot.R` header committed alone at 6894c27 and pushed before any candidate code; `grep -c "<-"` on it is 0. Settled in the header beyond the plan's wording:

- **Donor chain for extension.** The plan expected Maxan's series from 1931 (Houston or Quick), but review item 1 places Buck (from 1973) nearest. The header resolves it: the extension donors are the k nearest extension-pool gauges covering every observed year, and each year takes the nearest of them with a value. So k bounds the chain, and the years before 1961 rest on one or two donors.
- **Question 1's donors** are extension-pool gauges (a donor must be long to extend); question 2's are departure-pool gauges (a donor needs its own baseline).
- **Predictor SD** is taken over the box pool (natural, ≥3 complete migration years), one scaling for both questions.
- **Short-record set** is defined as box-pool gauges with 3–10 complete migration years. The findings table's 13 includes one regulated gauge (08EC002), so the natural count should be 12; Phase 2 measures it.
- **Scope calls kept as planned:** day-by-day extension is a reported-only sensitivity; the pseudo-record refusal floor is 15.

## The pool as the script measures it (Phase 2)

`wet_window_stats()` complete window-years on HYDAT 20260717: 81 natural box gauges in STATIONS, one excluded for missing metadata (08EE007), box pool 53, extension pool 21, departure pool 31, short-record 13. 08EE003 counts 44 (the issue's 43 came from a different count); the script fixes 44 and asserts 43 or 44. The 13 short-record gauges differ from the findings table's 13: 08EC002 (regulated) is out, and 08EE028 is in at 10 years; it is also in the departure pool (10 baseline years), so it is scored in both sets. 08EE003 has only 18 baseline years.

## `wet_window_extend()` guards proved (Phase 3)

| planted defect | test result |
|---|---|
| ratio as a mean of ratios | 1 failure |
| donor coverage rule removed | 1 failure, 1 error |
| MOVE.1 slope multiplied by r (ols's) | 2 failures |

Each restored and `cmp`-checked against the saved copy. The predictor space projects with `terra` (already imported), not `sf`.

## Question 1 decided by the registered rule (Phase 3, run 2026-10-25)

Migration-window mean, k = 5, 21 extension-pool gauges, 218 scored blocks: median per-gauge NSE ols 0.50, move1 0.47, ratio 0.42. **OLS ships for Maxan** (beats ratio by 0.09 against a 0.01 margin). Coverage of the nominal 90 % interval: ols 85 %, move1 90 %, ratio 89 %; OLS's own interval is a little narrow, the leave-gauge-out quantiles are on target. Every sensitivity of the migration mean (k = 3, 8, leak-free) keeps OLS first. The rule would pick ratio on migration min7 (all three negative) and migration cov_day (ratio 0.63), which decide nothing. Multi-donor OLS (0.30 against 0.56 for ols on the same years) and day-by-day (0.36 against 0.52) both lose. At 08EE018 leave-one-year-out every year comes from Buck (08EE013).

| Error | Resolution |
|-------|------------|
| pilot-count guard fired on a correct count | the counts were named by station, not role; named by role |
| `cor()` warned on a target with constant `cov_day` | MOVE.1 takes r = 0 when the target does not vary; test added |
| leave-one-year-out RMSE squared the mean | `sqrt(mean(x^2))` |
