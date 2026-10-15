# Plan review (Plan agent, spawned 2026-10-14 23:48 UTC, delivered as reply text)

Reviewed against HEAD 3306477 plus the uncommitted Phase 4 diff. Findings and dispositions (the full reply is in the session transcript).

| id | finding | disposition |
|---|---|---|
| B1 | `mv 962a9cc2c4 data/wb/_pre16` leaves `upstream/_complete` one level down, so `wb_key_dir()` finds two runs | Set aside as `data/wb/_pre16/962a9cc2c4/` (nested); plan wording fixed; `wb_share_snow.R` already globs `_pre16/*/fit_<release>` |
| G1 | rule metric ambiguous: `nse_share_median` drops floored and low gauges; float edge | Rule now NSE of the 12 held-out shares against the observed per gauge (obs >= 10 mm), paired over gauges both specs score, unrounded gain >= 0.01 − 1e-9; independent of the annual balance and so of the AET variant |
| G2 | which fit's outcome decides #16 | Each fit ships its own outcome; #16's outcome is the shipped fit's (fit_20260717). With G1 the outcome is the same for every AET variant of a fit |
| G3 | `share` "is the shipped one" circular | `predict_cv(share_specs =)`; callers pass the spec explicitly (wb_validate after the rule; monthly_vignette_data.R from the cv file's `share_spec`, "base" for older fits); `fits.rds$share_spec` recorded |
| G4 | keep `cv_share` as the shipped spec | Kept; `cv_shares` holds all specs |
| G5 | zone/lake not in the cv file | Stored (`zone`, `lake`) in Phase 5 |
| G6 | silent unequal n | `predict_cv()` stops on NA share predictors and on unequal training n per fold |
| G7 | snow key churns with cd rebuilds; manifest bytes may differ from those read | Key on the extracted 1981–2010 band values (`wet_raster_md5`), tested against a rebuilt file and an appended year; `wb_inputs.R` fetches once and passes local paths. Pinning with trap not done (noted) |
| G8 | a committed non-uploaded BUILD report blocks vignette-data regeneration until upload | Stated in the PR and the follow-up |
| G9 | published description omits ERA5-Land | `discharge_publish.R` adds it when `fits$share_spec == "snow"`, with the Copernicus attribution; landed before the rerun |
| G10 | stale docs (CLAUDE.md monthly-flow paragraph, monthly_vignette_data.R header) | Phase 7 |
| G11 | plan facts: 0.86 shipped (0.87 is fit_20251014); zones 27–29 share NSE 0.60–0.67 (≈0.5 is monthly NSE); 7 cells swe but no melt; fill is iterative 3×3 means | Plan wording corrected |
| O1 | freeze hashed and keyed code before the rerun | lintr, document, tests and `/code-check branch` before Phase 6 |
| O2 | identity gate before decisions are applied | `scripts/wb_upstream_identity.R` runs right after `wb_province.R` and must pass before any fit |
| O3 | predictor decisions before pre-registration | Probed: 513 cells at 5,000–10,000 mm swe_max (glacier points, not constant); 835 cells with >=20 % of years melting before day 60 (calendar-year statistic, bimodal on the coast). User chose a 3,000 mm cap on swe_max (2026-10-14); doy kept as published, limitation documented |
| O4 | commit reports before `segment_output.R` | Phase 6 order |
| A1 | glacier swe | see O3 |
| A2 | doy bimodal | see O3 |
| A3 | m4 layout: don't link `data/checks`, `data/basin`; BUILD rewrites `data/publish` | Worktree links only gitignored input dirs and `data/wb`, `data/snow`; own `data/publish` |
| A4 | "byte-identical" | Condition is "parts identical N of N" in the BUILD report |
| S1 | annual-only fit readers keep naming the old key | Stated in the PR; values hold under O2's identity |
| S2 | #68 cannot close unless the rejected path | #68 stays open unless Phase 7's switch lands |
| S3 | doy-only transparency | Added as a non-deciding spec |
