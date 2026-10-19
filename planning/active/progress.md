# Progress — Routed PCIC over 1981-2010: switch the pcic run and republish (#103)

## Session 2026-10-18

- Plan-mode exploration; phases approved by user. #103 publishes alone, ahead of #102 (user agreed: #102 is unstarted, the vignette data scripts refuse until a republish, and #103's period test decides the monthly article's #67 text).
- Created branch `103-routed-pcic-over-1981-2010-switch-the-pc` off main (5611166 + release 0acfcc1 + syncs, 2675636)
- Scaffolded PWF baseline from issue #103 with approved phases
- Next: Phase 1 (flip the pin)
- Phase 1: pin flipped (ba1dda5); tests 1208 passed, 0 failed, 0 errors. The test-vignette_data.R routed-period expectation moved to Phase 4 (it reads the committed rds)
- m4 worktree `~/Projects/repo/wet-103` made, `data/*` inputs symlinked to the main checkout as in wet-101
- Phase 2 on m1: routed report on the 1981-2010 run; annual skill nearly unchanged; by-month probe shows the #67 shape survives (spring -19.5 -> -11.5 %, summer +18.7 -> +15.8 %); findings.md
- Phase 3 on m4: segment_output on the 1981-2010 run (603ddc1); 4,733 picks moved (3,013 to routed, 1,720 to the balance). BUILD started
- BUILD on m4 (06:04-06:11 UTC): every check ok, 555,857,796 values compared, 0 differing; reader counts 3,154,131 / 1,378,712 equal the segment report; 35 of 67 parts identical to live acb820f; committed 9b601dc from m4
- Upload refused by auto mode's classifier ("Production Deploy"); routes offered to the user (leave auto mode for the step, or run the bare command). /code-check branch started meanwhile, so any R/ or scripts/ fix lands before the upload
- Docs (research, CLAUDE.md) committed 9fecc4a

## Session 2026-10-19

- The user ran the upload on m4 (`WET_PUBLISH=1`); it exited 14:50 UTC. The live manifest now names wet 94deeb5, built 2026-10-19T06:08:31Z, routed `pcic.discharge_monthly` PNWNAmet historical 1981-2010, fingerprint 178918222.786650.
- BUILD rerun on m4 at 00a3805 (no R/ or scripts/ change since 5215906): every check passes, 67 of 67 parts identical to the live 94deeb5 build. Report committed.
- Started the reload of m4's `discharge.*` tables from the live manifest (`data/logs/103/db_reload.R`).
