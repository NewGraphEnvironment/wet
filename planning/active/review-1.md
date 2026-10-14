# Plan review 1 (#59), Plan agent, delivered 2026-10-14

Findings, most severe first, with the disposition taken.

1. BLOCKER: observed months pooled per station would move the article's numbers ("up to 27 %" -> 26 %): `obs12` is built per station *and window*, from that window's years. -> Fixed: `wet_flow_window()` called per station and window on that window's years.
2. BLOCKER: fixture parts cannot ship (paths > 100 bytes). -> Already corrected (`\dontrun{}` example); task_plan lines updated.
3. ACCEPTANCE: routed_annual "identical" cannot hold (Postgres avg() vs R mean()). -> Measured max abs diff 6.8e-13 on 20,000 segments; compare report reproduced; plan line updated; stale comment in segment_vignette_data.R fixed.
4. GAP: Postgres path returns all-NA for an unloaded scenario or source. -> Fixed: stops naming wet_db_load(..., scenario =); test added.
5. GAP: routed table named twice (lib `routed_table`, package lookup). -> routed_annual() asserts they agree.
6. GAP: parquet path does not verify parts. -> Documented in roxygen (callers needing it bracket with wet:::wet_catalog_verify(), as the data scripts do).
7. ASSUMPTION: common-year windows differ from wet_month_days() (28.25) and real-year wet_window_stats(). -> Documented; issue body qualifies "day-weighted annual"; doy 1-365 recorded as a requirement on #70.
8. ORDERING: commit before each guarded rerun; render before editing. -> Followed (baseline rendered from HEAD before the windows edit).
9. ACCEPTANCE: regenerate on the same machine; ignore the Validation paragraph in the render diff. -> Regenerated on m1; diff excludes provenance.
10. ACCEPTANCE: oracle test should use the article's Chinook windows. -> Test reads life_history_bulk.csv.
11. GAP: from = "fwapg" with the default source errors. -> A missing `source` defaults to the sources `from` holds.
12. SCOPE: which hand reads stay. -> segment-discharge.Rmd recipe (needs `pick`), the bundle read in monthly_vignette_data.R (needs period/pick/coverage/runoff_mm), and the publish/segment_output reads of the routed table stay; named in the PR.
