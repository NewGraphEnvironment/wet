# Progress — Routed PCIC over 1981-2010: switch the pcic run and republish (#103)

## Session 2026-10-18

- Plan-mode exploration; phases approved by user. #103 publishes alone, ahead of #102 (user agreed: #102 is unstarted, the vignette data scripts refuse until a republish, and #103's period test decides the monthly article's #67 text).
- Created branch `103-routed-pcic-over-1981-2010-switch-the-pc` off main (5611166 + release 0acfcc1 + syncs, 2675636)
- Scaffolded PWF baseline from issue #103 with approved phases
- Next: Phase 1 (flip the pin)
- Phase 1: pin flipped (ba1dda5); tests 1208 passed, 0 failed, 0 errors. The test-vignette_data.R routed-period expectation moved to Phase 4 (it reads the committed rds)
- m4 worktree `~/Projects/repo/wet-103` made, `data/*` inputs symlinked to the main checkout as in wet-101
