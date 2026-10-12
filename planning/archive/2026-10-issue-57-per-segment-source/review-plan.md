# Plan review (#57), Plan agent, 2026-10-11

Findings in brief, each with what became of it. The agent returned its review as reply text, and this is the record of it.

| id | finding | outcome |
|---|---|---|
| B1 | No accumulated area for routed `runoff_mm` on m1 (the reduced bundle) | Build runs on m4, which has the full `upstream/` (mechanism change, progress.md) |
| B2 | Monthly routed `runoff_mm` must use month days, not 365.25 | Already so: `days[month + 1]` with `wet_month_days()`. Routed month 0 is the unweighted mean of 12 months (#58's definition), so it is not the day-weighted sum; stated in research |
| B3 | A reduced bundle must be refused | `segment_output.R`: basins must match `upstream/`; months 0–12 and watershed count per basin asserted |
| G1 | Guards: clean tree, shipped release, routed report, unlink first, invariants | All in; unlink moved ahead of every refusal; `release == wb_shipped_release` added |
| G2 | `routed_annual()`'s IN list does not scale | Per-basin temp-table join; mean of 12 with all 12 required, the same definition |
| G3 | Segments with no basin | No rows; counted in the report (no lut; lut but in no basin; routed left out) |
| G4 | `bc_fraction` dropped; routed `coverage` NA | Kept to #7's approved columns; noted in research |
| G5 | Stale `segment/` after a refit | `wb_output.R` now removes `segment/` with `output/` |
| G6 | Gauge pick: held-out or shipped balance | Held-out, stated in the report |
| G7 | Cut defined twice | `far_low` is required, and `routed_far_low` is the one definition; lib comment covers both uses |
| G8 | GUIC > 50 % flips; 08KH006, Taku | GUIC attributed from the report (research); 08KH006 is in the gauge list |
| G9 | NEWS; lint scripts | NEWS is `/gh-pr-merge`'s release step; scripts linted with `lintr::lint()` |
| G10 | CLAUDE.md "model code does not ship" | Now reads "in place of our own" |
| O2 | Report parsing by the vignette chain | New section; no line starts `all `; `routed:`/`table:` lines unchanged (verified by diff) |
| A1–A5 | Annual definitions, per-watershed balance, flips beyond placement, months follow the annual pick, test edges | Report breaks flips out by edge type and stream order; research states A1–A4; tests cover balance 0, routed 0, negative |
| S1 | #7 partition key `period` vs a column | #7 body edited (partition on scenario only, or keep `period` a column; `AND pick`) |
| S2 | Vignette: prose only, no station numbers, word cap | Prose only; render passed its guards |
