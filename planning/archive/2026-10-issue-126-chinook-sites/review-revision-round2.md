# Review, revision round 2 (73a6b95..HEAD, fixes at 964f70b and 9ffc309)

## Findings

1. **New with fix 6: the year-by-year caption still says "Points are measured summers", but the figure now draws other points too.**
   The isolated-year points are drawn in the borrowed colour (Maxan and Gosnell 1931 and 1933 in both windows, Swift spawning 1915)
   and the filled colour (Swift spawning 1915). Gosnell Creek's panels now show points although the article says it was never gauged,
   and the caption tells the reader that points are measured summers. The legend keys the colours, but the caption contradicts what is drawn.
   Also, the one isolated filled year (Swift 1915, lo/hi -32%..+171%) gets no band, because `geom_ribbon` draws nothing for a lone year,
   so "with its 90% range" is not drawn for it. Possible fixes: reword the caption (e.g. "Large points are measured summers; small points
   are years with no neighbouring year"), and draw a `geom_linerange` (or errorbar) for an isolated filled year's lo/hi.
   Check: render a copy and look at the Gosnell rows of the years figure.

2. **Half fixed from round 1, item 2: the answer's last sentence is still not limited to the Bulkley windows.**
   "Borrowing departures, the one route every stream has, scores worse in the spawning window than in the migration window at all four."
   The new guard (`ss_spw < ss_mig`) uses only `group == "BULK"`. The article also runs Gosnell under the Morice windows, and there the
   borrowed route scores *better* in spawning (0.66) than in migration (0.62) (`v$score_settings`, rows gosnell/MORR). Round 1 named exactly
   this case. The route is now named, but the window set is not. The scores paragraph does say "under these spawning windows";
   the answer does not. Fix: add "under the Bulkley windows" to the sentence. The alternative is to extend the guard to MORR, but that
   would fail.

3. **Minor guard gap: the site-panel caption "the gauges its numbers are borrowed from" is not held.**
   `panel()` draws every `map$gauges` row with `role != "target"` and keys it "Gauge it borrows from". That includes the `snow` role,
   which `data-raw/chinook_sites_data.R:270` adds from the site table's `snow_gauges`. Today every snow gauge is also a carried or
   extension donor at its site (checked: 08ED001, 08ED002, 08EE003, 08EE013, 08KE009, 08KH006, 08KA001, 08LB038), so the figure is
   right. But a snow gauge that is not a donor would be drawn as a donor and nothing would stop the build. Fix: draw only the donor
   roles (`role %in% c("carried donor", "extension donor")`), or add a `stopifnot()` that every snow gauge's station is a donor at its site.

Fixes checked and holding:
- md5s are now per site and per source. Gosnell's equal its report's `part ... MORR md5` lines (6e07e6b1..., 8e6bcacf...). Maxan's
  pcic_routed is 3d992510...
- The answer's figures come from the carried route (12%–46%; the ranges for Maxan, Naver and Gosnell stay below 0), and the migration
  guard covers every route and both window sets.
- "under a third of its peak": spawning mean / peak is Maxan 0.04, Swift 0.18, Naver 0.30, Gosnell 0.17. Peaks fall on days 139–166,
  inside May 1–Aug 1.
- The hydrograph source guard covers all four sites' picked days (all pcic_routed).
- The extents are square (130, 163, 199 and 110 km). The streams' bboxes reach every edge of the extent (gap 0 km). Every gauge lies inside.
  The rendered panels have a square map area with no empty bands.
- The last-year guard holds (every series ends in 2024 or 2025).
- The places check rejects duplicates (2 rows per site for 2 names).

Re-verified sentences: the opening counts (5, 14, 18, never gauged); use; "25%–56%"; Maxan and Naver largest, Swift smallest;
Morice 31 days later, −23%, upper bound +10.7%; the scores 0.42–0.49 with migration ≥ 0.5 in every box, filled-in within 0.15,
Swift 0.14 with 11 gauges, Swift's filled-in range wider in both windows; snow 41–51%, ≤16%, melt ≤23%, migration lower bounds > 0;
limits 29 gauges, 21%, 60%. The article renders without error from a copy (load_all). There are 8 figures.
