# Plan review (#36), Plan agent, 2026-10-06

Returned as reply text (read-only agent); recorded here with what was done about each finding.

| id | category | finding | disposition |
|---|---|---|---|
| B1 | Blocker | `wet_window_stats()` default `stats` includes `frac_below`, which needs a threshold; `cov_day` is meaningless for temperature | Tests and examples pass `stats` explicitly; roxygen section "With wet_window_stats()" says why |
| A1 | Assumption | `INSTALL icu` needs network | No icu: day and hour from `epoch_ms()` integer arithmetic, no session zone |
| G1 | Gap | No rule for a day with mixed approvals | `bool_and(final)`: approved only when every reading is final; tested |
| A2 | Assumption | Codes `1`/`4` meaning unknown | Documented as unpublished and treated as provisional (roxygen, research) |
| G2 | Gap | Zero-row `data.frame()` recycling trap | `rep("provisional", nrow(d))`; zero-row shape tested |
| G3 | Gap | `from`/`to` must trim the local day | WHERE on the local day `dd`; boundary test at UTC-8 |
| G4 | Gap | `count()` is BIGINT → double | `CAST(count(*) AS INTEGER)`; `expect_identical(…, 24L)` |
| G5 | Gap | `min_hours`/`valid` validation | Both validated and in the bad-input test |
| G6 | Gap | tidyhydat missing; double warning for a station with no data and no offset | Stops naming tidyhydat; time-zone warning only for stations with rows |
| A3 | Assumption | Glob layout of `Parameter=5/` | Flat `*.parquet` (same as `Parameter=6/`; full-archive reads return all 306 stations) |
| A4 | Assumption | −1 lower bound vs the −5…−0.5 junk band; summer air exposure | Kept −1 (plan gate); coverage report counts −1…−0.5 (12,662); roxygen and research say a range cannot catch summer air exposure |
| N1 | Number | Plan figures were at −5…40, and "~2 %" not derivable | Recomputed at −1…35 by `scripts/temp_coverage.R`: 1.94 % dropped, 630,001 days, 97.75 % pass |
| O1 | Ordering | Roxygen would quote stale coverage counts | Roxygen states the rule and points to the research file; numbers live in the report |
| S1 | Scope | No `symbol` column: say why; `frac_ice` should be NA | `@return` says so; round-trip test asserts `frac_ice` NA |
| S2 | Scope | No dev heading in NEWS; CLAUDE.md data-source line already done | `# wet (development version)` added; only the architecture line added |
| S3 | Scope | Window max of daily max needs a second call | Example makes the second call on `t_max_c` |
| AC1 | Acceptance | Live test criteria; is 08EE013 a temperature station | 08EE013 has 64,898 readings; live test asserts ≥ 50 days, hour rule, ordering of min/mean/max, plausible maxima |
| AC2 | Acceptance | Edge cases: one-reading 15-min hour, `:02` stamps, filter pushing a day below 20 h, duplicate stations | All four tested |
