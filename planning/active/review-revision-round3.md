# Revision review round 3 (#126): enumeration check

Reviewed at HEAD cc7ea28. Rendered a copy of `vignettes/articles/flow-change-sparse-gauges.Rmd` into the session scratchpad (installed bundle md5s equal to `inst/vignette-data/`: values 1802e1cf..., map 394d7b23...; `wet_station.csv` identical). Every stopifnot() passed and the word cap held. Every number was recomputed from the bundle, and every figure was read from the rendered PNG. Donor sets were cross-checked against `data/departure/departure_site_*_20260717.rds`, read only.

## Enumeration verified

| # | verdict |
|---|---|
| 1 | Holds: four sites; Swift, Naver and Gosnell use from `v$use`. |
| 2 | Holds: obs_n is 5, 14, 18 and 0; Gosnell's kind is `ungauged`. |
| 3 | Holds as a method statement (registered headers). |
| 4 | Holds: carried spawning changes are -46, -12, -41 and -35%, shown as "12% to 46%"; the guard is `all(spw$pct < 0)`. |
| 5 | Holds: upper bounds are -17 (Maxan), -4 (Naver), -5 (Gosnell) and +6 (Swift), so the text names Maxan, Naver and Gosnell. |
| 6 | Holds: every migration mean row, both routes and both window sets, has a range that spans 0 (MORR -15..+16). |
| 7 | Holds under BULK: spawning against migration is 0.49/0.63, 0.43/0.51, 0.42/0.60 and 0.45/0.65. Under MORR, Gosnell's spawning score is 0.66, above its migration 0.62, so the qualifier "under these windows" is needed and present. |
| 8 | Holds at the precision a reader takes it. The degree spans are equal (3.8 by 2.2). Ground areas are 60.0, 62.7, 61.8 and 60.7 thousand km² (within 4.5%), which is visually the same size. |
| 9 | Holds: every drawn donor lies in its box (st_intersects, 0 outside for all four). |
| 10-13 | Holds: nus_first 1970 and 55 use years out of 55 for Swift; 1985 and 24 out of 39 for Naver; Gosnell nus_use 1 in 2001, obs 3. |
| 14 | Holds: 1985-1998, 1956-1975, Maxan 1975-1979. |
| 15 | Holds. Unique donors drawn: Maxan 6, Swift 5, Naver 10, Gosnell 5, matching the rendered dots one for one. Every drawn donor is a donor of a q_mean statistic, which is what the article shows. The only per-statistic difference is Naver's spawning min7 carried set, and it adds 08KD001, already an extension donor for the mean, so the union is unchanged. No donor falls outside its square extent. |
| 16 | Holds: May 1 to August 1 and August 1 to September 15 come from `wb`; `windows` begins with BULK at all four. |
| 17 | Holds: each peak falls inside the blue band in the render and is guarded. |
| 18 | Holds and is guarded. Naver is the closest case, about 2.7 against a third of 9.1, which is about 3.0. |
| 19 | Holds: the pick rows are all `pcic_routed`, 365 days per site. |
| 20 | Holds (OLS single donor; borrowed `years` at all four). |
| 21 | Holds, and the figure draws every mark the caption names. Large orange points are measured years (size 1.2, 74 rows = 2 × (5 + 14 + 18)). The grey line and ribbon are drawn (measured rows have lo = hi = dep, so the ribbon pinches there rather than breaking). The blue line is drawn. Small points appear only for isolated years: borrowed at Maxan and Gosnell 1931 and 1933, and Swift spawning 1915. The one isolated filled year, Swift spawning 1915, also gets its range bar. No filled year without a ribbon or bar exists outside `alone`: probed every filled year with a range and no neighbouring range, and found none. The black lines equal the carried change (guarded). |
| 22 | Holds: rank Maxan -46, Naver -41, Gosnell -35, Swift -12; extended spawning changes are -56, -25 and -28, shown as (25%-56%). |
| 23 | Holds: every series' post-2011 years start at 2011 and end in 2024 or 2025 (n_post 14 or 15). |
| 24 | Holds: the MORR spawning window starts 1 September, 31 days after the Bulkley's; the change is -23% (-47..+11), smaller than -35%. |
| 25 | Holds: the table cells match `scores` and `score_settings`; `sc$ols` equals the migration mean (k = 5) ols (0.50, 0.14, 0.63, 0.48), as the caption says. |
| 26 | Holds: migration is at least 0.5 in every box, MORR 0.62 included; BULK spawning runs 0.42-0.49. "Their ranges ... carry that weaker score" is true because `ci_c` resamples held-out carried residuals (scripts/departure_site.R, the block after "new in #126"). |
| 27 | Holds: ols is within 0.15 of Maxan for Naver and Gosnell in both windows; Swift's is 0.14 (at least 0.2 below); ext_gauges is 11; Swift's extended interval is wider than its carried one in both windows. |
| 28 | Holds: SWE migration r2 0.409-0.510 is shown as 41-51%, and every lo is above 0; spawning SWE is at most 0.155 (16%); melt doy in spawning is at most 0.229 (23%). |
| 29 | Holds: err_n 29, requiring 10 or more baseline years (`length(o) >= 10`); log_ratio is log(pub/obs), so the error is above measured; the median 0.187 is 21% and q75 0.468 is about 60%. |
| 30 | Holds (guarded `windows` column). |
| 31 | Holds (method). |
| 32 | Holds: HYDAT 20260717; every pick is `pcic_routed`. |

**Items in the article that have no row.** Each was checked and holds:
- Locator legend "Gauges each stream borrows from lie in its box": 0 donors outside their box.
- Panel legend "Gauge it borrows from" holds, as row 15.
- Scale bars: the extents are in EPSG:3005 metres, so `sb_km * 1000` is the right length.
- Hydrograph legend "Typical flow, 1981-2010" holds.
- Strip labels on the year and change figures come from `wb`.
- Change legend labels map extended and carried correctly.
- "A stream's flow in a window is its mean over those days" holds, since the statistic is q_mean.
- The data-citation paragraph: the build digest comes from the bundle; the NuSEDS release date is not guarded but matches the use report's source.

These are omissions from the enumeration, not defects in the article.

## Clean

None of the latest commit's changes introduced a defect:
- The isolated filled-year bar draws only where `alone & route == "filled"` (Swift spawning 1915), carries no legend entry, and its lo/hi are inside the trained y-range.
- Each panel's donors are exactly the extension and carried donors, and every gauge drawn is a donor of the mean statistic.
- "Large orange points" matches the sizes, 1.2 against 0.6.
- "Under these windows" is the qualifier MORR needs.

No sentence, caption, cell or label is broader than the bundle supports.
