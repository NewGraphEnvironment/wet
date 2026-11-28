## Outcome

The station-flow vignette was revised for review after #29 shipped it with 11 BULK windows, ice handling and no map. It now covers Chinook only: the three windows that stay in open water (migration, spawning, fry migration), and the last five years (2022–2026) against 1981–2010.

Additions:
- a map of both stations and their nested FWA catchments, from `data-raw/station_vignette_map.R` (a 64 KB xz rds of sf layers);
- one key figure, with each window-year as a percent of the 1981–2010 mean and the median baseline year drawn too;
- a short computed interpretation.

The heat strip and trends stay, cut to the three windows. The ice machinery and the record-by-source figure are gone.

**What was learned.** Every review defect was a prose word whose meaning lived somewhere the sentence did not show, which is a wider version of #29's lesson:
- a column that did not exist, so `$` returned NULL and a count read 0;
- a qualifier dropped from a caption;
- "complete" meaning 80% of days;
- one noun counting two different units;
- a distance threshold set to pass.

Guards on inline values were not enough. The loop ended on a sentence-by-sentence enumeration of every rendered claim (`enumeration-27.md`, `review-round4.md`, 44 rows).

## Measurement

- **Chinook open-water windows, 2022–2026 vs 1981–2010** (also in `research/station_flow_departure.md` § Chinook open-water windows):
  - every window at both stations was below its mean in 2023–2026;
  - 21 of those 24 station-window values fall below the baseline's 10th percentile, and 6 below its minimum;
  - the lowest is 08EE003 spawning 2024, at 19%;
  - 2022 was above the mean in migration and fry migration at both stations (126–206%).
- **A median baseline year is 64–96% of the mean.** That changed the key figure: it draws a second reference line, and the interpretation is anchored on rank.
- **Catchments are nested.** Buck Creek (567 km²) is 24% of 08EE003's 2,315 km². FWA area against HYDAT gross area is 0.997 and 0.998.
- **08EE003's baseline is 1981–1998.** In 2025 its three windows rest on 80–91% of their days, because of two provisional gaps.
- **Bundle:** 132 KB in total. The same map layers as a GeoPackage were 2.9 MB, 804 KB of it the BC outline at 144k vertices; the outline is now 736 vertices.
- **Tests:** 603 pass. `devtools::check()` gives 1 ERROR, from `test-wet_pcic_annual.R` needing undeclared ncdf4. It fails identically on main (577 pass, 1 fail in a clean worktree). The vignette rebuilds under check.
- **Reviews:** a plan review (`review-27b.md`, 30 findings) and four code-check rounds, which found 5, 3, 7 and 5 issues. Round 2 found a defect inside round 1's fix, so only an enumeration could end the loop. That enumeration is round 4's 44-row table, with mutation tests of four guards.

Closed by: PR (see `git log`), Relates to #27

## From research/station_flow_departure.md (moved by #189)

## Chinook open-water windows, 2022–2026 (#27 revision)

The revised vignette keeps only the Chinook windows that stay in open water: migration (05-01–08-01), spawning (08-01–09-15) and fry migration (07-15–09-07). Incubation (08-01–03-31) and emergence (04-15–07-07) touch November–April, so they are left out rather than corrected. That removes the provisional-winter drop rule from the vignette (it was a no-op for these three windows) and the ice discussion, leaving one sentence on why the winter-touching windows are out.

- **Every window at both stations was below its 1981–2010 mean in 2023–2026.** That is 24 station-window values (2 stations × 3 windows × 4 years): 21 of them fall below the baseline's 10th percentile, and 6 below its minimum (08EE003 migration 2023–2026, 08EE013 migration 2024–2025). The lowest is 08EE003 spawning 2024, at 19% of the mean. 2022 was wet in migration and fry migration, above the mean at both stations (126–206%); its spawning window was below (71% and 99%).
- **A median baseline year is 64–96% of the mean** across the six station-windows. The key figure therefore draws the median year as a second reference line, and the interpretation is anchored on rank, not on sign.
- **08EE003's 1981–2010 baseline is 1981–1998** (18 years) in all three windows. It has no window with 80% of its days in 1999–2010: only a few spot values a year in 2000–2009, and a record from September 2010 that is continuous except for two provisional gaps in 2025 (1–8 July and 3–11 August). Its three 2025 windows rest on 80–91% of their days (37 of 46, 85 of 93 and 46 of 55), which `wet_window_stats()` accepts at `min_frac = 0.8`.
- **The catchments are nested.** Buck Creek's FWA catchment (567 km²) lies inside 08EE003's (2,315 km²): 24% of its area. FWA area against HYDAT gross area is 0.997 and 0.998. For each window and recent year (15 pairs), the two stations fall on the same side of the mean, partly by construction.
- **Trends** use the three windows, 2 variables, 2 starts and 2 stations: 24 slopes, 2 significant at p < 0.05, both negative. These are 08EE013 spawning mean and 08EE003 migration mean, both since 2000. Fry migration shares 38 of its 55 days with spawning, so the tests are not independent.
