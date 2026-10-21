# Progress — Publish segment_daily (#99)

## Session 2026-10-20

- Plan-mode exploration on m1 — phases approved by user (gate: per-group daily parts; I merge and release crate; publish during the branch)
- Created branch `99-publish-segment-daily-the-balance-s-dail` off main (40560dc)
- Scaffolded PWF baseline from issue #99 with approved phases
- Next: start Phase 1

- Plan review (Plan agent) folded into task_plan.md; findings in `review-plan.md`
- crate: issue crate#33, branch `33-segment-daily-schema` (0156b4f, ab3e701, d507dfb); review round 1 (`review-crate-r1.md`) found the routed February claim wrong, fixed in d507dfb
- Phase 3 (readers over `doy`): `wet_timebase()` daily, `wet_segment_daily()`, per-group parts, `wet_db_load(doys, groups)`, `wet_values_compare(time)`, fixture daily parts; tests pass, each new guard mutated once and seen to fail
- Phase 1 probe (19.8 min on m1 against m4's fwapg): routed days reproduce all 40,524,444 rows of `pcic.discharge_monthly`; per-day clamp 1.092 % (0.050 % mid-network)
- Phase 2: crate review rounds 2 and 3 (`review-crate-r2.md`, `review-crate-r3.md`) each found a wording defect in the previous fix (fixed dc8bc41, cef7c3e); round 3's claim table covers every sentence. PR crate#34 merged (d79f7e5), released crate v0.8.0, installed on m1 and m4
- m4 worktree `~/Projects/repo/wet-99` (data inputs linked to the main checkout's); `segment_output.R` rerun started there 14:00 UTC
- `/code-check branch`, three rounds (`review-round1.md` … `review-round3.md`):

  | Round | Findings | Fixed | Accepted | Inside previous fix? |
  |-------|----------|-------|----------|----------------------|
  | 1     | 3        | 3     | 0        | —                    |
  | 2     | 3        | 3     | 0        | y (the subset exemption) |
  | 3     | 1        | 1     | 0        | y (reach of r2's exemption) |

  Ended by enumeration: round 3 walked every place its two mechanisms reach (fixture of one group with both sources; a condition standing for a property) and found one open instance, fixed in d20a624. Fixes 90d3c00, b69e2c8, d20a624.
- First province daily run on m4 (code f35c673/86a5b78) passed both guards on the Fraser (22 min for drainage 100) and was stopped at 14:45 UTC as superseded; log kept as `data/logs/99/segment_daily_output_run1_stopped.log` on m4
- Monthly table rerun on m4 at d20a624 started 14:46 UTC; full test suite on m1 started
- Final province daily run on m4 at 6bb261e: exit 0, 132.0 min, every guard passed; report committed from m4 (77585a8). Figures in `findings.md`
- BUILD (`discharge_publish.R`) started on m4 17:07 UTC
- BUILD at 77585a8 on m4 (17:06–20:36 UTC, 3 h 29 min): 512 parts, 15,040,448,264 values compared, 0 differing; 67 monthly parts identical to live 8ca2dee (608147e)
- PUBLISH run by the user on m4: the live manifest named 77585a8 by 21:46 UTC; all 512 parts verify anonymously from m1
- BUILD again at 608147e (21:47–01:22 UTC): 512 of 512 parts identical to live, 0 differing (258618b)
- Article data regenerated on m1 against live 77585a8 (segment, map, monthly; 4 min, every guard passed); against the committed bundles only provenance moved, plus the segment bundle's new `daily`. The segment article's prose cap (900 words) refused the daily additions at 949; tightened to 899. Both articles render
- Issue #99's body: outcome line, the measured clamp, consistency and size; follow-up #107 filed
