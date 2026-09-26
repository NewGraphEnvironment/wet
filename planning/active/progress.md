# Progress — Province-scale upstream accumulation without the order-8 skip (#2)

## Session 2026-09-26

- Plan-mode exploration — phases approved by user
- Created branch `2-province-scale-upstream-accumulation-wit` off main
- Scaffolded PWF baseline from issue #2 with approved phases
- Next: start Phase 1
- Phase 1: `wet_upstream_sums()` (segment-tree range sums) with brute-force oracle tests.
- Phase 2: basin fetch + irregular pairs; Fraser in about 13 s. fwapg's stored upstream area found stale; live FWA_Upstream re-check exact on 401/401; full re-check running.
- Phase 3: `wet_upstream_mean()` on range sums, `wet_pcic_annual()`, point sampling, SALR gate unchanged.
- /code-check: 3 rounds; round 2 found a defect inside round 1's fix; ended on round 3's enumeration; 8 fixes.
- Fraser run (`scripts/mad_basin.R 100`) downloading PCIC per year in the background.
- Phase 4: whole Fraser, 99.782 % within tolerance; all 2,189 differences attributed (1,403 reproduced as fwapg-side, 786 stale-area necessary condition, 0 unexplained); Hope −7 % vs HYDAT. /code-check on Phase 4: 3 rounds, ended on enumeration. Evidence files tracked.
- Next: Phase 5 — comment on #2, notes on #3/#4/#6, archive, PR.
