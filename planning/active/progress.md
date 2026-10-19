# Progress — Monthly shares from donor gauges (#102)

## Session 2026-10-19

- Plan-mode exploration — phases approved by user (months only, daily later; symmetric leak test); user: "go all phases to pr"
- Created branch `102-monthly-shares-from-donor-gauges-day-of` off main
- Scaffolded PWF baseline from issue #102 with approved phases
- Next: start Phase 1
- Phase 1 rule a8ca570; Phase 2 b053f9d; Phase 3 3fe75bf; Phase 4 + plan review aed04b4
- m1 probe (read-only): donor 0.9389 / leak-free 0.9353 vs regression 0.8735 -> donor would ship
- Code-check branch: R1 1 finding (5e08841), R2 3 fragile incl. one inside a review fix (d746734), R3 clean with mechanism + enumeration (14 share_method branches, all hold); loop ended on enumeration
- Full suite 1227 pass / 0 fail
- m4: worktree ~/Projects/repo/wet-102 (data/* symlinked), set-aside data/wb/e675918817/_pre102/fit_20260717, chain scripts in data/logs/102/
- m4 chain A (22:09-22:15 UTC): ten variants rescored, annual identical to _pre102, #16 median 0.873517978845096 exactly, donor in every variant; compare keeps cfu (scoring md5 37d93d99)
- m4 chain B (22:15-22:37 UTC): ship cfu with donor shares (b78d2a5), breakdowns + daily shape (565f6b0; within-month donor on held-out months 0.849 -> 0.909 = free curve 0.9091), output (613ba15; month 0 identical in 24 basins, 38.3 M of 38.9 M watershed-months moved), routed compare (2fe90c6), segment (8ca2dee), BUILD (941a87c; 20/67 identical to 94deeb5, all value checks 0 differing)
- Research section + CLAUDE.md (57370c4); m1 reduced bundle replaced (old in data/wb/_pre102_m1/)
- Next: user uploads from m4 wet-102; then BUILD again, vignette data + monthly article rewrite
