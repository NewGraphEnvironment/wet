# Progress — Dry-interior runoff: rescore zones 23/24 without regulated or diverted gauges (#53)

## Session 2026-10-07

- Plan-mode exploration — phases approved by user ("go all phases")
- Baseline reproduced on m1 from `fit_20260717/cv_aet-cfu.rds`: dry 42.8 % (40), zone 24 92.8 % (9), all 27.5 % (315)
- Created branch `53-dry-interior-runoff-rescore-zones-23-24` off main
- Scaffolded PWF baseline from issue #53 with approved phases
- Next: Phase 1, pre-register the rule
- Stage 1 of `scripts/wb_gauge_diversion.R` written and run: licence (117,945) and dam (2,490) snapshots held to the WFS count. First run's guard fired on 10,000 duplicated ids: `paste0()` wrote startIndex 100000 as `1e+05`, which the server answers with page 1; fixed with `sprintf("%d")`, sequence check kept. Refetched once more to add `LICENCE_STATUS_DATE`.
- Rule pre-registered in `findings.md` from the vocabularies only (no gauge join)
