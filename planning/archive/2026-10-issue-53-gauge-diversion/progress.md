# Progress — Dry-interior runoff: rescore zones 23/24 without regulated or diverted gauges (#53)

## Session 2026-10-07

- Plan-mode exploration — phases approved by user ("go all phases")
- Baseline reproduced on m1 from `fit_20260717/cv_aet-cfu.rds`: dry 42.8 % (40), zone 24 92.8 % (9), all 27.5 % (315)
- Created branch `53-dry-interior-runoff-rescore-zones-23-24` off main
- Scaffolded PWF baseline from issue #53 with approved phases
- Next: Phase 1, pre-register the rule
- Stage 1 of `scripts/wb_gauge_diversion.R` written and run: licence (117,945) and dam (2,490) snapshots held to the WFS count. First run's guard fired on 10,000 duplicated ids: `paste0()` wrote startIndex 100000 as `1e+05`, which the server answers with page 1; fixed with `sprintf("%d")`, sequence check kept. Refetched once more to add `LICENCE_STATUS_DATE`.
- Rule pre-registered in `findings.md` from the vocabularies only (no gauge join)
- Blind rule review (Plan agent, `review-rule.md`): 4 blockers, 8 gaps. The main one: flags with obs in the denominator select low-obs (high-|%|) gauges, so a drop test can pass without any diversion effect. Amendment 1 (`33de805`) adds an obs-matched null, a naturalized rescore (obs + f·L, no gauge removed) as the deciding "explains" test, replaced and rediverted licence handling, own-reach placement, D-only deciding flag, leave-one-out stability, a threshold sweep and a semi-blind replication
- Stages 2–4 rewritten to the amended rule, then run once (log `data/logs/53/*_run.log`)
- Run (`data/logs/53/20261007_17*`): **not gauge side**, stable under every leave-one-out run and every sensitivity. One dry gauge D-flagged (08LF081, zone 17); none in zone 24 (L 0–2 mm/yr against overshoots of 46–245 mm); naturalized fall in zone 24 0.3 points at f 0.5, 0.6 at f 1
- Placement checked independently on 6 gauges against `fwa_watershedatmeasure()` polygons: the same surface PODs (Hedley differs by 2 non-candidate rows)
- Report fix after the run (display only): purpose shares printed `NaN%` where no licence was in force. Reproduces byte-identical from cache
- `/code-check`: 3 rounds. R1 found repeated licence rows and a T quantity spread over zero-quantity PODs (Deviation 1); R2 found a defect inside that fix (quantity taken across flags) plus report counts over the wrong population; R3 named the mechanism (two row populations) and enumerated all 42 derived quantities, 2 wrong, both report-only. Verdict unchanged throughout: not gauge side. Final report reproduces byte-identical from cache
- Write-up: research §0 "Gauge side in the dry interior (#53)", cross-references in #50's subsection, the ET experiment's candidate list, Follow-ups, research/README.md and the CLAUDE.md script list; checked against the final report
