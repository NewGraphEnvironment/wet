# Backlog move 19: small-stream logger records into wet (#235, batch 21: #215)

## Outcome

`wet_temp_daily()` now reads small-stream logger records beside the ECCC gauges. The first series is UNBC's Northern Hydrometeorology Group's Nechako loggers: both Zenodo records are pinned at Zenodo's checksums, with a tracked manifest and a 32-site registry, and backed up privately. Ids in a logger registry go to `wet_logger_daily()`; every other id goes to the unchanged ECCC query. Logger days follow the archive's rules, plus three logger-only rules (stuck runs, deployment ends, air days) whose thresholds were measured on the ECCC archive and registered in `research/station_water_temperature.md` ("Logger records") before any logger day was screened. `scripts/temp_loggers.R` places each site on the Freshwater Atlas and its main-flow tree, and writes the series' check report. Upper Bulkley (#251), Morice (#252) and the baseline scored on the logger pool (#253) are their own issues. The lesson worth keeping came from the thresholds. The owner's rule took a high percentile of the ECCC archive raw, and the archive's own faulty sensors set the tail, so the percentile measured the faults the rule exists to catch. Amendment 1 screened the reference first, before anything was scored. The general form: a threshold taken from a reference's tail assumes the reference is free of the defect it screens for, so look at the tail's members before registering it.

## Measurement

- **Thresholds** (`data/checks/temp_logger_thresholds.txt`, 17,312,829 archive readings): the first, unscreened run gave a stuck threshold of 687 h (08LG048 held 4.00 °C for 3,314 h; 07FA004 8.50 °C for 676 h) and August air 24.97 °C. Under Amendment 1, 6 station-years with a run of 168 h or more and 135 days with a range above 20 °C are left out. Shipped: air 12.09, 13.86, 16.83, 16.59 and 18.38 °C (May–September), stuck 154 h.
- **Nechako** (`data/checks/temp_loggers_nhg_15053907.txt`): 34,778 site-days, 34,017 kept (650 hour rule, 100 deployment ends, 11 air days, 0 stuck). 30 complete growing seasons at 22 sites, which overturns the plan's "near zero", and 24 more needing only their shoulders filled. 28 of 32 sites placed (24 by name, 4 by nearest; the 4 lake sites unplaced), all on the main-flow tree. The two records agree on 87 % of shared readings; Chedakuz and Endako show a daylight-saving shift in the earlier record. A first draft named Whitesail as shifted; code-check round 2 showed Whitesail differs at every alignment, cause unresolved.
- **Reader:** 38 s for all 32 sites from cache; both reports rerun byte-identical.
- Every guard was shown red with its rule removed (stuck, deployment, air, hours, routing, valid range, ice exemption, fetch flag).

## Evidence

`data/checks/temp_logger_thresholds.txt` and `data/checks/temp_loggers_nhg_15053907.txt` (tracked). The archive hours cache is `<WET_DATA_ROOT>/temp_loggers/eccc_hours.rds`. The Zenodo files are in wet's cache, `temp_loggers/nhg/<record>/`, and backed up at `s3://fresh-bc/temp_loggers/nhg/`. Code-check: `review-round1.md` to `review-round5.md`, `review-verdict.md` (ended on an enumeration).

Closed by: PR for branch `235-backlog-move-19-small-stream-logger-reco` (relates to #215)
