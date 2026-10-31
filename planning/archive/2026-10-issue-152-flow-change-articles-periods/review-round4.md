## Checklist read

- code-check.md, `## Mechanisms`: the prose of every H3, skipping `|` rows. "A guard's scope, escape hatches, and remedies" was read in full.
- code-check-r.md: index headings for the R this diff uses (`stopifnot` guards, `round()`, dplyr-free base subsetting).
- Method: I rendered both articles at HEAD d915856 into a temp dir (`pkgload::load_all` + `rmarkdown::render`). The tree stayed clean.
- I stripped the HTML to text and took every claim from that text. Each value was recomputed from `inst/vignette-data/chinook_sites_values.rds` and the site reports' section 5, or from the measured article's own code, run via `knitr::purl` up to `map-data`.
- I checked both new research sections against the report's printed values and against the bundle.

## Findings

- **[bug]** `inst/cartography/wet_station.csv:46` → `vignettes/articles/flow-change-sparse-gauges.Rmd:425` (Figure 4 legend). Figure 4's legend calls the OLS band **"90% range of a filled-in year"**. I confirmed this in the rendered PNG.
  - Round 3 reworded the caption to "the band its fitted relation predicts". It left the registry label untouched.
  - Rmd:80 says "the years figure's band is not called one". The new research section says "it does not call the years figure's OLS band a 90 % range, because its held-out coverage in the site reports is 83–85 %".
  - Measured held-out coverage of the band at the three drawn sites: Maxan 85.0, Swift 82.7, Naver 85.3.
  - So the figure still makes the claim, and the research sentence about the article is false.
  - No guard reads the legend text.
  - Fix: relabel the `band` row, for example "Range its fitted relation predicts". Then assert `!grepl("90", pal_series$labels[["band"]])` beside Rmd:80.
  - **Rule:** code-check.md "A proxy is not the property" (a sentence describing a figure is a claim about the criterion the figure stands in for; end by enumerating every result-describing sentence). Also writing.md "A caption names every mark the figure draws".
  - **Inside an earlier round's fix?** yes (round 3: the caption fix missed the legend).

- **[bug]** `research/chinook_sites.md`, section "## 1951–1980 against 2016–2025 (#152)", the bullet "The migration window". It says Maxan's extended route's 1951–1980 years "rest on the Bulkley at Quick (08EE004) and Telkwa (08EE008)". Two problems:
  - HYDAT 20260717 `STATIONS` names 08EE008 **GOATHORN CREEK NEAR TELKWA**. Telkwa River is 08EE020, and there is no Bulkley gauge at Telkwa.
  - The report's provenance line (`departure_site_maxan_bulk_20260717.txt`, section 5, "migration mean: extended 11 08EE004, 11 08EE008, 3 08EE013, 5 observed") shows the two named gauges carry 22 of the 30 years. The other 8 rest on Buck Creek (3) and Maxan's own measured summers (5).
  - Fix: write "rest mostly (22 of 30 years) on the Bulkley at Quick (08EE004) and Goathorn Creek near Telkwa (08EE008)".
  - **Rule:** agent-operations §3, "Documents that share an ancestor corroborate nothing" (read the code or artifact behind a stated quantity or scope; check `every`, `each` and `all N`), and code-check.md "A guard's scope…" (compression adds a claim never in the source).
  - **Inside an earlier round's fix?** no (original branch text, unchanged through rounds 1–3).

- **[fragile]** `vignettes/articles/flow-change-sparse-gauges.Rmd:501-504` against Rmd:513-515. The sentence reads "Filling in a record scores poorly in the upper Fraser … **so** Swift Creek's filled-in change is its less certain route".
  - The sentence grounds "less certain" in the score. Its population, "filled-in change", includes the lowest seven-day flow (min7) rows that Figure 5 draws.
  - The guard tests a different property, range width, and only for `statistic == "mean"`.
  - On min7 in the migration window, the width proxy reverses. The filled-in range +8..+125 % is narrower than the borrowed −2..+123 %, so a guard widened to the drawn set would fire.
  - By score, which is what the sentence says, the claim holds in all four drawn rows (Swift filled-in against borrowed):

    | statistic, window | filled-in | borrowed |
    |---|---|---|
    | mean, migration | 0.14 | 0.51 |
    | mean, spawning | 0.14 | 0.43 |
    | min7, migration | 0.42 | 0.59 |
    | min7, spawning | −0.17 | 0.32 |

  - Nothing published is wrong; the guard checks a proxy over a subset.
  - Fix: `stopifnot(all(ssc$ols[ssc$site_id=="swift" & ssc$setting %in% c("migration mean, k = 5","spawning mean","migration min7","spawning min7")] < ssc$carried[<same rows>]))`.
  - **Rule:** code-check.md "A proxy is not the property". The guard's filter is also narrower than the sentence's population, which is this review's mechanism.
  - **Inside an earlier round's fix?** yes (the sentence was reworded in rounds 1–3; the guard was not).

- **[fragile]** `vignettes/articles/flow-change-sparse-gauges.Rmd:511-512`. The sentence is "The lowest seven-day flow scores below the bar in 7 of 8 windows and boxes".
  - It names no route, but `m7_sc` (Rmd:452) filters `carried` only.
  - The filled-in route's min7 scores (Bulkley windows: −0.11, 0.28, 0.42, −0.17, −0.02, 0.18, 0.00, 0.32) are below 0.5 in 8 of 8. So the count is true only of the borrowed route.
  - The paragraph's preceding subject is "The borrowed departures", which makes the borrowed reading likely but not stated.
  - Fix: "Borrowed, the lowest seven-day flow scores below…", matching Rmd:460's form.
  - **Rule:** code-check.md "A proxy is not the property" / "A guard's scope…" (route filter narrower than the sentence's words).
  - **Inside an earlier round's fix?** yes (round 1 rewrote this sentence).

Notes, not findings (no published sentence is wrong):
- Rmd:108 comment: it says "6-10% … 9-17 days"; the prose computes 6–9 % and 9–16 days. This is a stale comment only.
- Rmd:127-136 guard: it guards a sentence the article no longer carries ("about as well across the Cottonwood, Morice and Bulkley boxes"). It holds on today's data, but it would refuse a rebuild for a claim nobody reads.

## Word caps and citations

- Body prose, counted with each article's own wordcount code:
  - flow-departure-normal: **699** words against a cap of 700 (passes).
  - flow-change-sparse-gauges: **1000** against 1000 (passes, exactly at the cap).
- Every `@key` in both Rmds resolves in its `.bib`. Neither rendered HTML contains `???` or "(key?)". Both references lists render: 20 entries in the measured article, 18 in the rebuilt one.

## Enumeration (rendered text, claim by claim)

M = matches: the guard's population equals the sentence's, and the value matches at the printed precision.

### flow-change-sparse-gauges.Rmd (rebuilt; Bulkley windows unless named)

| # | claim | population | guard / computation | pop. match | value check |
|---|---|---|---|---|---|
| 1 | changed "since 1951–1980" | periods | Rmd:73 `per_ref` | M | 1951:1980 |
| 2 | Maxan five full summers | obs_n | Rmd:95 | M | 5 |
| 3 | Swift 14, Naver 18 | obs_n | inline | M | 14, 18 |
| 4 | Gosnell never gauged | kind | Rmd:95 | M | ungauged |
| 5 | spawning mean lower at all four, 15%–46%, borrowed | mean/carried/BULK/4 | Rmd:91-92 `spw` | M | −15.28, −44.91, −45.81, −34.76 → 15–46 |
| 6 | 90% range below 0 at Maxan, Naver, Gosnell | same | inline `low_spw` | M | hi −11.3, −5.2, −3.5; Swift +5.1 |
| 7 | "90% range" label on change intervals | all drawn mean+min7 rows | Rmd:81-82 cover ≥ 0.87 | M | min cover 0.904 |
| 8 | borrowed min7 spawning fell at 3, clearly only Maxan, held at Swift | min7/carried/BULK | Rmd:103-107 | M | −39.9, −33.1, −26.1; hi only Maxan < 0; Swift +1.0 |
| 9 | migration borrowed mean no clear change at any stream | mean/carried, both window sets | Rmd:98-99 | M | all 5 ranges straddle 0 |
| 10 | snow over every catchment peaked lower, melted earlier | 4 targets | Rmd:110-114 | M | all negative / earlier |
| 11 | borrowed mean scores worse in spawning than migration at all four (Bulkley) | carried/BULK | Rmd:122 | M | 0.49<0.63, 0.43<0.51, 0.42<0.60, 0.45<0.65 |
| 12 | two in Skeena, two in Fraser | system | Rmd:189-192 | M | — |
| 13 | Maxan into Bulkley near Topley, SE of Smithers | into1, km, compass | Rmd:184,195 | M | — |
| 14 | Gosnell into Thautil above Morice, SW of Houston | into1/2, compass | Rmd:184-196 | M | — |
| 15 | Naver into Fraser near Hixon, S of Prince George | | Rmd:186,197 | M | — |
| 16 | Swift into McLennan, a Fraser tributary, at Valemount | | Rmd:186-197 | M | — |
| 17 | same-sized box | spans | Rmd:199 | M | 3.8 × 2.2 |
| 18 | Swift chinook most years since 1970 | NuSEDS | Rmd:307 | M | 1970, 55 of 55 |
| 19 | major spawning site < 5 km | use_obs | Rmd:310 | M | — |
| 20 | Naver most years since mid-1980s | NuSEDS | Rmd:308 | M | 1985, 24 of 39 |
| 21 | Gosnell one survey 2001, three provincial records | | Rmd:313 | M | 1, 2001, 3 |
| 22 | windows May 1–Aug 1, Aug 1–Sep 15, all four | BULK windows | Rmd:63-64, 138 | M | — |
| 23 | flow peaks in migration window at every stream | daily pick, 4 | Rmd:329-330 | M | — |
| 24 | spawning window under a third of peak | daily pick, 4 | Rmd:332-336 | M | — |
| 25 | Fig 3: typical year 1981–2010, published flow | daily pick | Rmd:582 pcic_routed | M | — |
| 26 | 2016–2025 vs 1951–1980; ERA5-Land covers it | periods | Rmd:73 | M | — |
| 27 | Fig 4: band = "its fitted relation predicts" (caption) | OLS band | — | M (caption) | — |
| 27a | **Fig 4 legend "90% range of a filled-in year"** | OLS band | none | **mismatch** | coverage 82.7–85.3 % → **Finding 1** |
| 28 | Fig 4 black lines = borrowed typical departure per period | per | Rmd:403-406 | M | equals change |
| 29 | drop largest Maxan & Naver, smallest Swift | mean/carried/spawning | Rmd:448-449 | M | −45.8, −44.9 … −15.3 |
| 30 | filled-in same direction, 27%–57%, clear only Maxan | mean/extended/spawning, 3 sites | Rmd:433-434 | M | −27.46, −40.24, −57.44; only Maxan hi < 0 |
| 31 | borrowed min7 spawning fell 26%–40%, clear only Maxan | min7/carried | Rmd:103-107, 454 | M | 26.1–39.9 |
| 32 | Fig 5 caption "to 2024 where 2025 is not yet approved" | recent years | Rmd:393-394; HYDAT-approved only (scripts/departure_site.R:210) | M | 2016–2024 n = 9 consecutive |
| 33 | Morice spawning Sep 1–Oct 7, a month later; Bustard p. 27 | MORR windows | Rmd:440-446 | M | +31 days |
| 34 | Gosnell Morice drop smaller, 23%, range reaches 0 | mean/carried/MORR | Rmd:435-438 | M | −22.57 (−49.6..+15.1) |
| 35 | Table 1 values; filled-in column is migration window's | scores BULK | Rmd:488-497 | M | 0.50/0.14/0.63/0.48 = migration mean k = 5 ols |
| 36 | bar 0.5 set before any stream | rule | — | M | — |
| 37 | borrowed clears 0.5 in migration in every box | carried, both sets | Rmd:123-124 | M | 0.51–0.65 |
| 38 | spawning below in every box, 0.42–0.49 (Bulkley) | carried/BULK | Rmd:123, 510 | M | 0.42–0.49 |
| 39 | **min7 below the bar in 7 of 8** | sentence: no route; guard: carried | Rmd:452 | **route narrower** | 7/8 carried; 8/8 filled-in → **Finding 4** |
| 40 | filling in scores poorly in upper Fraser; 11 records | ols mean | Rmd:498-500, 135 | M | 0.14 (both windows), 11 |
| 41 | **Swift filled-in change "less certain route"** | score; all drawn stats | Rmd:501-504 width, mean only | **proxy, subset** | holds by score in 4 of 4 → **Finding 3** |
| 42 | peak SWE 6%–9% less | sc_t 4 targets | Rmd:110-114 | M | −9.45, −5.70, −8.48, −8.56 |
| 43 | melt 9–16 days earlier | same | same | M | 12.6, 9.0, 10.5, 16.5 |
| 44 | migration rises with SWE, borrowed all four, ranges > 0, 41–51% | carried swe migration | Rmd:523, 529-530 | M | .409, .411, .506, .510 |
| 45 | all 8 snow gauges, 25–62% | observed swe migration | Rmd:542-548 | M | .252–.618, 8 distinct |
| 46 | named in advance at Maxan, else nearest two with long records | gauge rule | scripts/departure_site_snow.R:51-52,198 (≥ 10 baseline years, snap) | M | — |
| 47 | spawning SWE at most 16% borrowed, 31% measured | BULK | Rmd:531, 572 | M | .155, .311 |
| 48 | melt date at most 23% borrowed, 64–66% Nanika & Morice | doy spawning | Rmd:534-538, 552-556 | M | .229; .643, .663 |
| 49 | Gosnell normal error: 29 gauges, median 21%, about 60% at a quarter | normal BULK spawning | Rmd:579-580 | M | exp(.1875) − 1 = 20.6; exp(.4679) − 1 = 59.7 |
| 50 | windows Bulkley at all four; only Morice own | sites$windows | Rmd:138 | M | — |
| 51 | HYDAT 20260717, build 0f4f8ca, bundle 52facd0 | provenance | inline | M | — |

### flow-departure-normal.Rmd (measured)

| # | claim | guard / computation | match | value |
|---|---|---|---|---|
| 1 | 1981–2010 a WMO standard normal; wet's flows normals of it | Rmd:101 | M | — |
| 2 | every window both gauges below normal, 5%–48% | Rmd:306-307 | M | −4.61, −6.50, −7.94, −48.31 |
| 3 | below in each year from 2023 | Rmd:227-233 | M | 2023–2025 |
| 4 | 11 of 12 drier than nine 1981–2010 years in ten | Rmd:238-247 | M | 11/12 (08EE013 migration 2023 above q10) |
| 5 | Bulkley normal rests on 1981–1998 | Rmd:161-166 | M | — |
| 6 | both gauges near Houston | Rmd:347-348 | M | — |
| 7 | Buck joins Bulkley in town; Buck drains 24% | Rmd:340-357 | M | 567/2315 = 24.5 % → 24 |
| 8 | Bulkley joins Skeena at Hazelton, ~120 km NW | Rmd:355-363 | M | computed |
| 9 | Fig 1: catchment areas; order ≥ 5; lakes ≥ 100 ha; near catchments | Rmd:345, 365-380 | M | — |
| 10 | windows; fry within; 2 others into Nov–Apr | Rmd:58-95 | M | — |
| 11 | 80% of days | formals | M | — |
| 12 | typical year under the mean | Rmd:263-265 | M | — |
| 13 | before 2023 both ways in every window | Rmd:254-256 | M | — |
| 14 | from 2023 below median; 5 drier than any year | Rmd:248-251 | M | 5 |
| 15 | same side in all but one of 18 | Rmd:258-262 | M | 18, split 2019 spawning |
| 16 | Fig 2 caption: Bulkley no window in 1999–2010 has 80% | Rmd:161-166 | M | — |
| 17 | Fig 3: ≥ 10 years; Bulkley 1 May–8 November; 9 at Buck, no 2016 | Rmd:567-578, 206 | M | — |
| 18 | resampled bar narrower than a 90% CI with ≤ 10 recent years | md5 pin Rmd:291 → coverage report | M (measured at 9 and 10) | 0.834–0.867 |
| 19 | HYDAT ends March 2025; 1 of ten years provisional | Rmd:694-699 | M | 1 |
| 20 | 2 of 38 bars on 80%–91% of days, Bulkley 2025 | Rmd:267-273 | M | — |
| 21 | Buck lacks 1984 spawning; Bulkley lacks 1999–2010 | Rmd:168-181 | M | — |
| 22 | windows cite Gottesfeld for both | Rmd:97 | M | — |

### research/chinook_sites.md, "## 1951–1980 against 2016–2025 (#152)"

| # | claim | source | match |
|---|---|---|---|
| 1 | 20–30 years of 1951–1980, 9 or 10 of 2016–2025 | change n_pre/n_post: 20–30, 9–10 | M |
| 2 | approved HYDAT ends 2024 for most series; 2025 for every Swift and some of Naver's filled-in | years: 13 of 18 end 2024; Swift 4 of 4 and Naver filled migration end 2025 | M |
| 3 | intervals covered 0.904–1.000 | cover min .904, max 1.000 | M |
| 4 | OLS band held-out coverage 83–85 % | reports: 85.0, 82.7, 85.3 (drawn sites) | M; but the claim that the article does not call it a 90 % range is false (Finding 1) |
| 5 | measured article 0.834–0.867 | coverage report | M |
| 6 | table: all 5 rows × 4 columns, points and ranges | reports' 1-decimal values and the bundle; no value double-rounded (e.g. Gosnell hi −3.468 → −3, Swift extended −27.46 → −27) | M (26 numbers checked) |
| 7 | drop largest Maxan & Naver, smallest Swift; clears 0 at Maxan, Naver, Gosnell as before 1981 | change; earlier table | M |
| 8 | migration: no clear change carried at any site | change | M |
| 9 | **Maxan extended 1951–1980 rests on Bulkley at Quick (08EE004) and Telkwa (08EE008)**; −28 %, range < 0 | report provenance, HYDAT STATIONS | **mismatch**: 08EE008 is Goathorn Creek; the two carry 22 of 30 years (Finding 2); −28.2 (−46.0..−4.8) M |
| 10 | min7 spawning carried falls 3, clear only Maxan, Swift +1 %, extended −18 % | change | M |
| 11 | min7 carried below 0.5 in 7 of 8 (0.23–0.59) | score_settings | M |
| 12 | SWE 6–9 %, Maxan 260→235, Swift 555→524, Naver 243→223, Gosnell 974→891 | snow_change | M |
| 13 | melt 9–16 days earlier | snow_change | M |
| 14 | measured: all eight rise, R² 0.25–0.62; spawning ≤ 0.31 | snow observed | M |
| 15 | melt date 64–66 % at Nanika & Morice (Bulkley); at most a third elsewhere; 18–19 % under Morice | snow observed doy | M (.333069 < 1/3; .182, .190) |

### research/station_flow_departure.md, "## Chinook open-water windows, 2016–2025 (#152)"

| # | claim | source | match |
|---|---|---|---|
| 1 | 08EE003 −7 % migration, −8 % spawning | chg −6.50, −7.94 | M |
| 2 | 08EE013 −5 % migration, −48 % spawning | chg −4.61, −48.31 | M |
| 3 | below normal each year from 2023; 11 of 12 below q10 | low | M |
| 4 | before 2023 both ways | swing | M |
| 5 | same side in 17 of 18; 2019 spawning splits | both | M |
| 6 | Buck no 2016, no days in bundle, 9 recent years | daily 2016 rows = 0 | M |
| 7 | covers 0.834–0.867 < 0.87; article calls it "middle 90 % of changes from resampling", rests no count on it | coverage report; Rmd:650 | M |
| 8 | 1981–2010 cited as WMO normal (Arguez and Vose p. 699; WMO-No. 1203) | article bib | M |

Totals: 97 rows enumerated. Two mismatches: rebuilt-article 27a (the legend) and chinook_sites research row 9. Two more rows (rebuilt-article 39 and 41) have a guard narrower than the sentence or checking a proxy, but print a true value. Every other row matches.
