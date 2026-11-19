# Plan review for #167 (Plan agent, spawned 2026-11-19T05:12Z, delivered during Phase 3)

Verdicts after probing each finding:

- Q1.1 no seed moves: confirmed by reading; set.seed(120) per window set.
- Q1.2 snow parity breaks with a new column: accepted; the covariance series goes in its own table (Phase 5, only if a site ships).
- Q1.3 exactly-one-line checks: section 6 avoids HEADLINE, Donor chain, `<target> per year` and the change-table header; checked by grep before the runs.
- Q1.4 md5 order: accepted; `/code-check` of the site script before Phase 4.
- Q1.5 no code-md5 lines in reports: accepted; Phase 4 acceptance reworded.
- Q1.6 drift: accepted; stop on any moved line in sections 1–5.
- Q2.7 weighting matches #122: confirmed.
- Q2.8 #58 wording: fixed in the header.
- Q2.9 pcic.runs 1951–2012 row: NOT a blocker; the local database has both runs (queried 2026-11-19, crosswalk 901d1271 for both).
- Q2.10 years and pool: stated in the header; section 3's distance at the same gauges printed.
- Q2.11 plan bullets out of date: updated; refusals listed in the header.
- Q3.12 refusals change as intended: confirmed.
- Q3.13 departure_pcic.R text: amended to name #135.
- Q3.14 departure_pcic.R md5 for #130: noted; no rerun owed here.
- Q4.15 database before body: checked (pcic.series, pcic.runs, bare PG* reach it).
- Q4.16 per-year covariance lines: added.
- Q4.17 map, snow claims, score table: added to Phase 5.
- Q4.18 article route: the gate's chosen option said the article's carried numbers move where it ships; settled. The short-record article stays on distance at Maxan.
- Q4.19 small fixes: noted (8.67 GiB measured; no `wet_pcic_years_dir()`).
- Q4.20 no republish or rescore: confirmed.
