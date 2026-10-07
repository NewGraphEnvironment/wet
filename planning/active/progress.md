# Progress — Refit the open water balance on HYDAT 2026-07-17, and settle the pooled-zone adjustment (#43)

## Session 2026-10-06

- Plan-mode exploration (pipeline map; m4 state over ssh) — phases approved by user, with three gate decisions: window stays 1981–2010; pooled zones judged on fresh 1–9-year gauges; refit ships unless headwater MAE worse by > 1.0 point
- Created branch `43-refit-the-open-water-balance-on-hydat-20` off main
- Scaffolded PWF baseline from issue #43 with approved phases
- Next: Phase 1 (pre-register rules, correct the issue body)
- Phase 1: rules pre-registered and committed (6c196c4); #43 body corrected (no new years; caveat via fresh gauges)
- Plan review (review-plan.md): 31 findings; rules amended (dated, before any scoring: sub-sub-drainage hold-out, name and 10 mm screens, decision gauges with a floor of 10, gate failure to the user, #15 reproduction without a fixed variant, acceptance metric and gate)
- Phase 2: fits keyed by HYDAT release (scripts/wb_fit_lib.R; stations_<rel>.rds; <key>/fit_<rel>/), WET_HYDAT pinned and checked, AET carry, test set in wb_stations, wb_pooled_test.R, wb_fit_accept.R, wet_hydat_release() with tests. Local smoke test on fit_20251014 cfu: cv_ann and raw identical, monthly NSE within 6e-14
- /code-check rounds 1-3 (review-round1..3.md): the md5 split (a fixed variant had staled the AET winner); a default that shipped cgiar; carry checked consistency not currency; pooled test release; closed by the defaults enumeration (review-enumeration.md)
