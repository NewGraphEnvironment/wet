## Outcome

Swift Creek and Naver Creek now run under their own stocks' cited chinook windows, the upper Fraser's (UFRA) and the Cottonwood's (COTR), beside the Bulkley's (#182, carried). `data-raw/life_history_data.R` reads knowledge's life history table at a475dfe7. That is the last commit to touch the table: knowledge#256 closed there, and it rewrote only the UFRA and COTR chinook notes. `data-raw/station_vignette_data.R` keeps BULK at c97c4d0. `lh_pin_guard()` holds every MORR row, every BULK column but `note`, and BULK's chinook rows against that pin and `life_history_bulk.csv`. A restored-defect test covers it (`tests/testthat/test-life_history_pin.R`). Owner decisions at the resume:

- adopt the windows now;
- move only that pin;
- leave the site scripts unchanged, so the new report headers name only the migration row's sources.

Four new site and snow reports were added, and the four BULK reports for Swift and Naver reran byte-identical. #147's rule gives the same weighting under each stream's own windows as under the Bulkley's. Under its own windows each stream's spawning-window drop barely moves: Swift −15 %, Naver −35 %, and neither range clears no change. The comparison article reports this in one paragraph, and its limit now says the Fraser windows' edges are survey estimates. The bundle and map were rebuilt: the Fraser map takes in two donors used only under COTR. `research/chinook_sites.md` has a section "Swift and Naver under their own windows". The code check ran four rounds. Every finding was a sentence whose scope had shifted from its artifact, and round 4's sat inside round 3's fix, so the loop ended on an enumeration of the 41 sentences the branch adds or rewrites.

## Measurement

- Section 6 verdicts (migration mean, leave-one-out gain):
  - Swift, UFRA: distance (−0.021).
  - Naver, COTR: covariance_pick (0.139; leak-free 0.159).
- Shipped borrowed spawning-window mean, 1951–1980 to 2016–2025:
  - Swift: −15.5 % (−33.1..+5.5) under UFRA, against −15.3 % under BULK.
  - Naver: −34.8 % (−59.4..+8.9) under COTR, against −35.2 % under BULK.
- Held-out carried NSE, migration / spawning:
  - Swift, UFRA: 0.55 / 0.42 (BULK 0.51 / 0.43).
  - Naver, COTR, covariance_pick: 0.74 / 0.56 (BULK 0.75 / 0.60).
- Every new interval's coverage is at least 0.931.
- The April-start windows keep both targets' complete migration years: 08KA012 14, 08KE014 18.
- Swift's UFRA snow gauges differ from BULK's (08KA007 replaces 08KA001), because the header's rule depends on the windows' complete years.
- The article's body prose went from 1,139 to 1,253 words; the cap went from 1140 to 1253.
- Details: `findings.md`, "Phase 2 runs"; `research/chinook_sites.md`.

## Evidence

`data/logs/187/*_20261125.log` in the main checkout (site and snow runs 14:31–14:44Z, bundle, map).

## Owed

- File a follow-up issue (no number written before it exists): re-pin and rerun when knowledge#242 revises the UFRA or COTR rows (knowledge#256 closed at the resume). Drafted in `followup-issue.md`; auto mode refused `gh issue create`, so it waits on the owner.

Closed by: PR (this branch), closing #187 and #182.
