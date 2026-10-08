# Plan review (Plan agent, 2026-10-07) — triage

Full findings were returned as reply text (Plan agents cannot write files); summarised here with the decision on each.

| id | finding | decision |
|---|---|---|
| B1 | ē circular / underspecified; standardise peer innovations by σ̂_j, robust mean, min overlap before freeing b | Already two-stage (stage 1 b = 0). Adopted: clip each peer's errors at ±4 σ̂_j, overlap ≥ 180 days before b is freed. Not standardised: dividing by σ̂_j inflates a non-tracking peer (lake outlet, small σ̂) to unit noise in ē; raw errors keep it small |
| B2 | 0 °C floor in the predict step; ice days bias the fit | Moot after G1: the floor is inside the deterministic open-loop S only; the Kalman state u is linear; output floored |
| B3 | Seasonal logger shoulders (Mar–Apr, Oct–Nov) not filled by default and not validated | Add holdout (c) shoulders; document `from`/`to` for seasonal loggers; acceptance: non-NA GSDD for a May–Oct logger |
| G1 | One-step ML targets persistence; open-loop could beat the fill on whole seasons; S_t + u_t formulation | **Confirmed by the 08E spike and adopted**: form 1 tied open-loop on whole seasons (1.28 vs 1.27 °C); S_t + u_t gives 0.99 (findings.md) |
| G2 | No seasonal hysteresis term | Report monthly bias and residual autocorrelation in validation |
| G3 | Interval calibration on real data | Coverage by holdout in the report; document that pointwise bounds do not sum to a GSDD interval |
| G4 | air missing, initial state, obs noise, max gap, `status` of filled days | Interpolate air (documented); stationary prior (done); obs_sd fixed 0.1 (arg); filled `status = "provisional"` so `frac_provisional` does not count them as approved |
| G5 | `wet_temp_gsdd()` columns, unit, msgs | Return a superset of `wet_window_stats()` columns (+ `frac_filled`); unit `degC_day`; msgs = FALSE |
| G6 | Pool = whole call is meaningless province-wide | Add `pool` argument (named by station); validation uses WSC sub-drainage |
| V1 | Leakage; nested peers | Validation calls the public function with held rows deleted; one holdout per pool per call. Nested proxy: a peer in the same sub-sub-drainage (first 4 chars), labelled as a proxy |
| V2 | Baseline ladder | open-loop; forward restart (filter, b = 0); smoother b = 0; full; linear interpolation on bridging gaps |
| V3 | Truth definition; RMSE on observed only; count truth first | Adopt wording; count truth set before running |
| V4 | More gap lengths | 7, 30 days mid-summer + season + shoulders |
| O2 | Pre-register the decision rule | Rule written in findings.md and committed before the validation run |
| A1 | cd/gsdd already installed | Installed by this session at 14:xx; noted |
| A2 | Pin gsdd SHA | Not pinned (convention: never a bare SHA); report records gsdd version |
| A3 | Same-day air vs lag | Keep same-day; documented |
| A4 | b recovery ill-defined | Tests check b ∈ (1, 2) for trackers (λ/mean λ) and |b| < 0.1 for non-tracker, plus RMSE gain — matches the advice |
| S1 | Parity in its own issue | Kept: approved in plan |
| S2 | Parity station-year sets and gsdd window | Handled in Phase 5 |
| AC4 | Unit tests: status through wet_window_stats, floor not moving days above 0 | Add |
