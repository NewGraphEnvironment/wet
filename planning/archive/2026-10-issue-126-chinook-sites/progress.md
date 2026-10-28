# Progress — Second-region Chinook pilots (#126)

## Session 2026-10-28

- Plan-mode exploration; phases approved by user (Swift 08KA012; Morice target Gosnell or Lamprey by Chinook record count, Owen dropped; distance-weighted carry; OLS fixed with the race reported)
- Created branch `126-second-region-chinook-pilots-swift-creek` off main
- Scaffolded PWF baseline from issue #126 with approved phases
- User: run all phases to the PR
- Next: start Phase 1
- Phase 1: `scripts/chinook_sites_use.R` → `data/checks/chinook_sites_use.txt` (byte-identical on rerun). NuSEDS All Areas 2026-06-01 downloaded to `data/chinook_sites/raw/`. Morice target: Gosnell Creek (tie with Lamprey at 4; spawning record). Window counts at 08KA012 (14, 1985–1998) and 08KE014 (18, 1956–1975) match the issue. Issue body and title edited. `research/chinook_sites.md` opened.
- Phase 2: `scripts/departure_sites.csv` (maxan, swift, naver, gosnell), `scripts/departure_site_lib.R` (`ds_site()`, `ds_windows()`, `ds_in_box()`), `data-raw/life_history_data.R` → `inst/vignette-data/life_history_morr.csv` (knowledge at c97c4d0, as the BULK file).
- Phase 3: headers of `scripts/departure_site.R` and `scripts/departure_site_snow.R` registered, committed alone. Added beyond the plan: a 90 % interval on the carried before/after change (set.seed(126), after the extension bootstrap), the headline at the ungauged site; the race no longer stops below 15 extension gauges (flagged instead).
- Plan review (Plan agent) landed; dispositions in `planning/active/review-plan.md`. Header amended before any body code (target scaling, area assert, part md5s); vignette-data test budget gets life_history_morr.csv.
- Phase 4: site script runs at all four; maxan passes the parity gate; two fixes in the ungauged path (area parse, source from the catalog) made a full rerun necessary.
- Phase 6/7: bundle and map built (6 KB, 20 KB; every number held to its report line), article drafted and its two figures reviewed and redrawn; tests 213 pass; CLAUDE.md lines and the site-table convention added (memory retired); research results written.
- pkgdown build (scratch destination): articles/chinook-sites.html built; 0 mentions in articles/index.html and in the home navbar; the navbar dropdown gains a 'More articles…' link to the index (pkgdown's behaviour with `navbar: ~`). Article body 584 words.
- Full test suite: 1685 passed, 0 failed, 0 errors, 12 skipped (`data/logs/126/test.log`).
- Byte identity: maxan and swift reports identical across three runs; naver and gosnell (both window sets) identical on a fresh rerun of the committed script (0 diff lines).
- `/code-check branch`: five rounds (plus the plan review: six reviewer agents in all, past the five-per-task bound). Round 2 found a defect inside a round-1 fix, so the loop ended on an enumeration (`review-enumeration.md`), verified row by row by rounds 4 and 5 and corrected after each. The mechanism, named in round 3: a guard checked one value while its sentence spoke for a group. The substantive finding (round 3): borrowed departures score below 0.5 in the spawning window in every box under the Bulkley windows (0.42–0.49), and the article now says so.
- pkgdown build to scratch: the article is built and in neither the index nor the navbar. A `build_site()` generates `pkgdown/favicon/` locally (removed each time; not tracked).
