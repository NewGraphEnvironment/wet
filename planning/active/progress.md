# Progress — Backlog move 5: More donors and PCIC's years at the chinook sites (#167)

## Session 2026-11-18

- Plan-mode exploration — phases approved by user; batch 7 split out, covariance_pick ships where it wins
- Created branch `167-backlog-move-5-more-donors-and-pcic-s-ye` off origin/main; claimed move #167
- Scaffolded PWF baseline from issue #167 with approved phases
- Next: start Phase 0
- Phase 0: #167 retitled and rewritten for batch 8; batch 7 filed as move 8, #179; #142 and #144 bodies gain the box count; `planning/backlog.md` and `research/station_sources.md` updated
- Plan review spawned in the background at 2026-11-19T05:12Z
- Phase 1: `R/wet_pcic_years.R` (internal cache, size-gated rename) with tests; each guard proved by mutation (no download size check, env var ignored, cached size unchecked: each fails its test); `routed_years_dir()` in `scripts/pcic_routed_lib.R`; `departure_pcic.R` and `gauge_monthly_compare.R` default to it
- Local fwapg holds `pcic.series` (63 rows, 1950–2012, one commit 26d7582, 8.67 GiB) and only the 1981–2010 run's `pcic.subbasin_daily`; cache fill started 2026-11-19T05:16Z, log `data/logs/167/pcic_years_fill_*`
- Phase 2: #147's rule registered in the header of `scripts/departure_site.R`, committed alone before any body code or run
- Phase 3: `site_carry_ship()` in `scripts/departure_site_lib.R` with `tests/testthat/test-departure_site_rule.R`; section 6 in `scripts/departure_site.R` (PCIC prep before the window loop, scoring and the shipped route inside it, `cov` in the rds). The modelled statistics are built inline as #122 builds them (`wet_routed_years()` then `wet_window_stats()`), so no new lib helper was needed. The snow script's covariance series waits for the verdicts: it is needed only where a site ships covariance_pick
- Plan review delivered (findings and verdicts in `planning/active/review-plan.md`); header amended before any run; departure_pcic.R names #135's change
- Code-check round 1 (spawned 05:25Z): 1 bug, the ungauged mouth's integer64 id zeroed by rbind (reproduced, fixed with an assertion)
- Code-check round 2 (05:33Z): 2 fragile (section 6 stopped the run where PCIC covers little; the section 3 comparison line counted other gauges); both fixed
- Code-check round 3 (05:40Z): the mechanism named (section 6 reuses idioms that assume the non-empty pools sections 3 and 5 guarantee) with every place it reaches; 4 fragile fixed (a statistic with no covered donor, the phantom per-gauge line, km medians over scored gauges, the section 3 comparison's count), two inside round 2's fixes; the snow script skips a window the site run could not carry
