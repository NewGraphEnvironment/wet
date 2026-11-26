## Outcome

Tested the natural stations outside HYDAT (the province's non-integrated network and the BC Water Tool's gauges, `regulation == "natural"`) as departure donors for #202, under a rule registered before any score (`scripts/departure_donors_rule.R`, committed alone at a7455e45). None holds the 10 years of 1981–2010 record a baseline needs, so each station with at least 3 complete migration window-years through 2024 (33) was given a baseline estimated by OLS extension from HYDAT gauges, and #120's inverse-distance carry was scored with and without them, held out at every natural HYDAT gauge in its own box's departure pool. **The donor pool stays HYDAT-only:** the stations made the carried migration-window departure worse. The loss is in the year-to-year pattern as well as the level, comes from estimating a 1981–2010 mean from 3 to 8 fit years (attributed to the method, not the stations' records: leaving unchecked days out does not reduce it), and holds under every sensitivity. No site report, article or shipped function moved; help text, NEWS, CLAUDE.md and two research files say what was found. Same-site continuation, the other piece #202 raised, is #227. Findings: `research/chinook_sites.md`, "Natural stations outside HYDAT as donors"; `research/station_sources.md` revised to match.

## Measurement

From `data/checks/departure_donors_20260717_20261028.txt` (HYDAT 20260717, station snapshot 20261028):

- 75 natural stations, 36 with at least 3 migration window-years, 33 through 2024; none with 10 baseline years (the most over any statistic and window is 5). Every pre-registration count matched the report's section 1.
- Median paired RMSE difference (log departure, with minus without): +0.0317 leave-one-gauge-out (50 gauges, 16 better, 34 worse; 90 % interval 0.0064..0.0629), +0.0147 leak-free (53; 0.0049..0.0523); bar −0.01. Centred log NSE 0.827 → 0.750.
- Sensitivities (migration mean, leave-one-out): at least 5 fit years +0.0130; no unchecked day +0.0768; k = 3 +0.0649; k = 8 +0.0108; without stations at a HYDAT site in the box or regulated +0.0373. None would ship.
- A station took a HYDAT donor's place in 210 of 263 scored gauge-years; in years none of the chosen stations has a value the difference is +0.0014.
- Site parity: the pools at 08KA012 (30, 11, 13) and 08KE014 (58, 17, 24) equal the Swift and Naver site reports'.

Wrong turns kept: the first full run scored nothing because the script's station table dropped `regulation` and `dd_candidate()` answered a zero-length vector (fixed in the script, guarded; the registered rule file untouched). The code check ran 4 rounds; round 2 found defects inside round 1's fixes (cache key, a reworded bullet), round 3 named the mechanism (set claims written from the idea of the set) and one of its fixes was itself wrong until measured; round 4's enumeration of 50 quantified sentences and every cached input ended it.

## Evidence

`data/logs/211/*` (in the main checkout once moved; dev, final, r1–r3 cold and warm runs, and the test suite).

## Owed

- Before this worktree is removed, move its `data/logs/211/` and `data/departure_donors/` into the main checkout's `data/`.

Closed by: PR (this branch), `Fixes #202`, `Fixes #211`
