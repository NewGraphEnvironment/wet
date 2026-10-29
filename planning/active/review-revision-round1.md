# Review, revision round 1 (73a6b95..HEAD)

## Findings

1. **Bug: `daily$md5` in the bundle names the wrong part for every site** (data-raw/chinook_sites_data.R:367).
   `dly$md5[match(d$source, dly$source[dly$code == site$wsg_code])]` matches into the *subset*
   `dly$source[dly$code == ...]` but then indexes the *full* `dly$md5`, so it returns rows 1–2 of the
   catalog whatever the group. In the bundle all four sites (BULK, UFRA, COTR, MORR) carry the same two
   md5s (wet_balance 93060932…, pcic_routed 8cf1c2e2…). Gosnell's own report gives MORR's parts as
   wet_balance 6e07e6b1… and pcic_routed 8e6bcacf…, and BULK's pcic_routed is 3d992510… The provenance
   column is wrong at every site. Fix: `parts$md5[match(d$source, parts$source)]`. A hold of Gosnell's
   md5s against the report's `part … MORR md5` lines would have caught it.

2. **The opening answer is the borrowed route's, but the sentences name no route and the guards cover only that route.**
   - "lower … at all four streams, by 12% to 46%": `spw` is `route = "carried"` only. Filling in the record gives
     −56% at Maxan, outside "12% to 46%".
   - "at Maxan, Naver and Gosnell creeks the 90% range stays below no change": on the filled-in route Naver's
     range is −55% to +16%, so it crosses no change. The change figure shows this right below.
   - "The method is weakest in the spawning window": the guard checks only the borrowed scores under the
     Bulkley windows. Swift's filled-in score is 0.14 in both windows, not lower in spawning. Under the Morice
     windows, which the article also uses, Gosnell's borrowed spawning score is 0.66 against 0.62 for migration.
   Either say "borrowed from nearby gauges" (and "under the Bulkley windows") in the answer, or widen the guards
   to both routes and both window sets.

3. **"falls through the spawning window" is broader than its guard, and false at Naver.** The guard compares only
   the first and last day. Naver's published typical year falls from 2.96 m³/s on Aug 1 to 2.52 around Aug 26,
   then rises again to 2.69–2.78 by mid-September. 20 of the 45 day-to-day steps rise, and you can see the
   rise in the hydrograph figure. Swift also stops falling and rises slightly (3.3 → 3.55) in the window's
   second half.

4. **The software sentence's guard covers Gosnell only.** "Gosnell Creek's typical flow and the hydrographs are
   wet's published daily flow (for these four streams, routed PCIC's)" is held by
   `all(v$normal$pick == "pcic_routed")`, but `v$normal` has rows for Gosnell only. The hydrographs of all four
   come from `v$daily`. All four picks are pcic_routed today, but nothing holds it. Add
   `all(v$daily$source[v$daily$pick] == "pcic_routed")`.

5. **The site panels draw empty bands with no rivers or lakes.** The map script clips streams and lakes to
   `map$extents`. The article then pads each extent to the panel aspect with `gq::gq_bbox_aspect()` (default
   margin included), so the padding has no data. Naver's extent is 128 km wide and its panel 203 km, leaving
   about 37 km on each side where the Fraser and the other rivers stop on a straight vertical line. Swift's
   extent is 130 km and its panel 167 km. Maxan and Gosnell lose smaller strips. The caption says "with its main
   rivers", but they are cut off inside the frame. Pad to the panel aspect in the map script, before the clip.

6. **The year-by-year figure leaves out years its period lines use.** Years with no neighbouring year draw nothing
   under `geom_line`, but they count in the black period means and in the change. Borrowed 1931 and 1933 are
   missing at Maxan and Gosnell (both windows), and 1915 at Swift (spawning, both the borrowed and filled
   lines). So the "before 1981" black line starts at 1930.5 or 1914.5 over years with nothing drawn. Draw the
   series with points as well as lines, or start the period segment at the first drawn year and say so.

7. **Minor guard gaps.**
   - The change caption says "(to 2024, or 2025 where recorded)", but the guard is `all(ch$n_post %in% 14:15)`, a
     count. A 2012–2025 series would pass. The data are right today (2011–2024 or 2011–2025 in `v$years`).
     Guard the last year from `v$years` instead.
   - The map script's places check is `setequal(places$name, s$places)`. Two GNS features with one name inside
     an extent (two "Houston"s) pass and draw twice. Use
     `nrow(places) == length(s$places) && setequal(...)`. There are no duplicates in this build (8 rows for 8
     names).

Checked and clean: the scores table and its prose (0.42–0.49, the 0.5 bar in both window sets, within 0.15,
Swift 11 gauges and the wider filled-in ranges); the snow paragraph (41–51%, ≤16%, melt ≤23%, all four lower
bounds > 0); the limits bullet (29 gauges, 21%, 60%); Morice windows 31 days later, −23%, range reaches 0;
the use paragraph; peaks inside the migration window at all four; the period lines' differences equal the carried
change; the y-axis transform and breaks (100% at 0, labels 100 + p); measured rows have lo = hi = dep, so the
ribbon and the departures share one baseline. Per-year `held()` lines are exact whole-line matches with
value/interval/donor/dep/anomaly, or with anomaly, flow and donor count at Gosnell, so a match against another
statistic's table is not plausible. `site_get()`'s new `places` column breaks nothing: neither site script
compares a stored site to the table, and the data script re-reads it. There is no reference to `chinook-sites`
outside planning/archive. The make_valid-on-invalid-rows clip gives only POLYGON/MULTIPOLYGON and
LINESTRING/MULTILINESTRING.
