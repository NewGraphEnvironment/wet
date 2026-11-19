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
