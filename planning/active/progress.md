# Progress — Dry-interior runoff: find which term is off, then fix that one (#45)

## Session 2026-10-07

- Plan-mode exploration — phases approved by user; scope: diagnosis plus the written lever choice and rule (build and score in a follow-up issue)
- Created branch `45-dry-interior-runoff-find-which-term-is-o` off main
- Scaffolded PWF baseline from issue #45 with approved phases
- Next: pre-register the attribution rule, then start the PCIC fetch
- README and DESCRIPTION brought up to date (requested mid-run): water temperature path, two segment sources, scenario runs reachable but not built; DESCRIPTION Title/Description had claimed seasonal and climate-scenario output that no script produces
- Plan review (Plan agent) landed: rule holes (shared P bias could not read as P side; lopsided corroboration; gauge-side test before usability). Adopted as Amendment 1, committed 024836d before any PCIC value was seen
- First diagnosis run stopped by hand during the Peace fetch, before any report; its per-basin caches deleted unread; raw daily PCIC files kept
- Amended run started 2026-10-07 07:48 local (frozen copy `data/logs/45/wb_term_diagnose_frozen.R`, log `data/logs/45/20261007_wb_term_diagnose.log`)
- `/code-check` on `scripts/wb_term_diagnose.R`: 3 rounds (`planning/active/review-round{1,2,3}.md`)
  - r1: 2 bugs, 1 fragile, all fixed;
  - r2: 2 fragile, fixed, one of them recorded as a reading in findings;
  - r3: 6 fragile, all in the cache-key family; the fix for one sat inside r2's fix
  - Ended by enumeration of every cache and output the script reads or writes (7):
    - the per-year PCIC downloads (keyed by `wet_pcic_fetch()` on run, variable and indices);
    - `pcic_cell_<code>_<key>.tif` and `pcic_upstream_<code>_<key>.rds` (run, years, variables, package code);
    - `eccc_climr_<key>.rds` (years, zones zip, this script);
    - `data/hydz/src_*` (unzipped every run);
    - `diagnose_<release>.rds` and the report (`wb_report()`, keyed on the release).
