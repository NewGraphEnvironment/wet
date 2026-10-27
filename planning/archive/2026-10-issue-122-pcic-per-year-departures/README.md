## Outcome

#122 asked whether, at a site without a record, year-to-year flow departures are better carried from gauged neighbours or read off PCIC's routed flow at the site, and whether PCIC's modelled years can choose the neighbours. A rule registered in `scripts/departure_pcic.R`'s header before any candidate existed (5904cd7; amended at a8ff752 and 5a67a46 before the body, and at b518ebc after it and before any run) scored three donor weightings, then donors against PCIC's own departures and a blend, held out at the 290 calibration gauges PCIC covers, 1951–2012. wet gained `wet_routed_years()` (PCIC's per-year sub-basin days, fwapg#42's product, routed to a segment day by day) and `wet_departure_carry(weights =, modelled =)`. Donors chosen by modelled covariance ship; PCIC alone and the blend do not. The durable verdict is `research/pcic_hydrology.md`, "Per-year routed flow and the departure competition (#122)", with a pointer from `research/station_flow_departure.md`'s #120 section.

## Measurement

Median per-gauge centred log NSE of the Chinook migration-window mean, held out / leak-free (`data/checks/departure_pcic_20260717.txt`):

- Stage 1: distance 0.67 / 0.64, covariance (same 5 nearest) 0.68 / 0.66, covariance_pick (best 5 of 15 by modelled r) 0.72 / 0.69. covariance_pick ships, +0.054 / +0.047 against the 0.01 margin. The header's expected null (reweighting the same neighbours by r changes little) held at +0.01 to +0.02; the gain comes from choosing other donors.
- Stage 2: donors 0.72 / 0.69, PCIC 0.48 / 0.48, blend 0.71 / 0.69. Donors ship; the blend misses the margin both ways (−0.009 / +0.008).
- PCIC's own skill by basin: Columbia 0.63, Fraser 0.49, Peace 0.43, Coast 0.41; correlation above NSE at every gauge.
- The run is reproducible: two runs at 42fdd45 and two at 846f9d7 each gave a byte-identical report, and the series of all four are `identical()` but for the commit and md5 stamps, so code-check rounds 5–7 changed only what the report prints.
- Every refusal in the header fired on a staged break (mutation table in `findings.md`), and one fired for real: run 0 read another session's fwapg build on localhost through the `WET_PG*` defaults, and `routed_daily_fingerprint()` refused it.

Wrong turns, kept: the pre-run check of the reload compared `pcic.runs` rows, not the tables, and missed that the `PG*` database never held the 1951–2012 daily rows (loaded from fwapg's published file with `load/pcic_run.sql`); the first mutation harness cloned with GNU `cp -c`, which failed, so two cases met an empty directory; a pair-run wrapper reported "identical" after both runs had refused, comparing the committed report with itself; and the fwapg checkout's product directory was emptied mid-branch by another session, so the product is now read from wet's own `data/pcic_years/`.

## Evidence

`data/logs/122/` — `run*.log` and `run*.start` (run 0 the wrong database, runs 1–2 at 42fdd45, runs 3–4 at 846f9d7, the stopped ones marked), `report_run*.txt`, `mutations*.log`, `load_daily_1951-2012.log`.

## Owed

- Tick #122 in #118's component list.

Closed by: PR (opened from branch `122-pcic-per-year-routed-flow-keep-the-years`)
