## Outcome

Backlog move 27 (#243, closing #225's available half): TerraClimate's 1981–2010 runoff climatology and the BC 1961–1990 runoff isolines scored against the held-out balance and HYDAT at the shipped fit's 315 calibration gauges, under a rule registered before any product value was read (`scripts/runoff_products_rule.R` at a5e867c; the owner's thresholds of 2026-11-27: signed median error by hydrologic zone, material past 20 points, theirs/ours/unresolved by which side is outside ±20 %, leave-one-gauge-out stability, and a period-ratio test for the isolines). `scripts/runoff_products_compare.R` writes `data/checks/runoff_products_compare_20260717.txt`; the findings and the disagreement log are `research/runoff_products.md`. GEOGLOWS v2 was split to #244 (its reach crosswalk is a PR on its own) and the BC Water Tool's estimates to #245 (not released). Learned on the way: terra 1.9.50's exact extract takes ellipsoidal cell areas on a projected CRS and runs about 100 times slower than on lon/lat, so an equal-area grid is sampled under a planar ("local") label; and a cache comment rewritten over three review rounds kept producing a defect until stage 2 was keyed on the md5 of the file it samples.

## Measurement

- TerraClimate runoff: median error −33.0 % at all 315 gauges (middle half −45.5 to −13.3 %; 23 % within ±20 %), against the balance's −3.6 % and routed PCIC's −2.6 % (283). Theirs province-wide and in 14 zones (two more unstable), unresolved in zone 04, ours in zone 24 (the balance +36.4 %). Its precipitation term's median is −202 mm, AET +85 mm, storage +3 mm, zone adjustment −50 mm. Monthly share NSE 0.55 against the balance's 0.94. Plumbing against `ppt_tc − aet_tc`: 0.70 % at 314 fully covered gauges (bound 5 %).
- Isolines (TIN): +1.8 % at the 292 gauges they cover (middle half −14.0 to +17.8 %; 61 % within), against the balance's −4.5 % there; not material province-wide or in 17 zones; ours in zone 24 and (unstable) zone 09; theirs (period untested) in zone 29. Inverse distance a median 0.0 % from the TIN; flat-triangle share median 0.20 (95 gauges above 0.5).
- Period: 121 natural BC gauges with 20+ complete years in both 1961–1990 and 1981–2010; province ratio 0.985, zones 0.95–1.03; it changes no verdict.
- terra sampling: 70–100 ms per polygon on BC Albers (15–50 min per watershed group) against under 1 ms on lon/lat; planar fractions within 1.1e-7 of the ellipsoidal. With it the whole run takes about 15–19 minutes cold with 6 workers on m1, a minute from cache.
- Wrong turns kept: the first run sampled isolines ellipsoidally for an hour (5 groups done) before the cause was found; `cv_aet-cfu.rds` is a list (`nrow()` NULL); the period errors first took the zone's observed values instead of the scored subset's; three rounds of cache-comment rewording before the key itself was fixed.

## Evidence

`data/logs/243/runoff_products_compare_run*.log` and `data/logs/243/runoff_products_fetch.tsv` in the main checkout (m1); caches under its `data/runoff_products/`. The tracked report's md5 per code commit is in `progress.md` (final, after merging main: `9c78e624c708d546ce77685564505093` from code commit 01e52b2b, runs 17 and 18).

Closed by: PR for branch `243-backlog-move-27-the-runoff-products-no-r` (closes #243, #225)
