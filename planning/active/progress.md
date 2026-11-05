# Progress — Build one watershed group's segment product from a published fit? (#157)

## Session 2026-11-04

- Plan-mode exploration — phases approved by user, parked
- Plan review (Plan agent) run during plan mode and folded in: `planning/active/review-plan.md`
- Created branch `157-build-one-watershed-group-s-segment-prod` off origin/main
- Scaffolded PWF baseline from issue #157 with approved phases
- Next: parked 2026-11-04; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#157 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `157-build-one-watershed-group-s-segment-prod`,
parked 2026-11-04 by `/planning-init wet#157 park`, branched from origin/main at 8ad7d6b.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[157-build-one-watershed-group-s-segment-prod]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-157 157-build-one-watershed-group-s-segment-prod and cd there
git checkout 157-build-one-watershed-group-s-segment-prod   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git merge origin/main   # a conflict: main moved meanwhile; resolve it, commit, and go on

Then read planning/active/task_plan.md, findings.md, progress.md and review-plan.md if present.
The gate decisions, the measurements and the Plan-agent review are already folded in:
do not re-plan and do not re-ask them.
Start Phase 1 and run every phase to the PR (/code-check branch, /planning-archive,
/gh-pr-push). This message is the resume instruction that starts the run-to-PR
mandate; the merge stays with me.
```

## Session 2026-11-04 (resumed)

- Resume checks clean; branch current with origin and main.
- `wet_ws_roots()` and `wet_ws_closure()` in `R/wet_ws_closure.R`: one fetch and one irregular query per group, `wscode_ltree <@ ANY($1::ltree[])` (bitmap scan on the gist index; BULK + SALR closures together 47,672 rows in 32 ms). Coastal groups have thousands of roots (MORI 2,398), so a per-root loop over `wet_ws_fetch()` was not used; the live test holds BULK's closure identical to `wet_ws_fetch(conn, "400.431358")`.
- Tests: 1,106 expectations, the 925 sums identity and BULK's closure live on m1's fwapg.
- `scripts/segment_group_closure.R` on m1's fwapg: 27 s for 246 groups (the plan-mode psql pass took 24 min, its roots computed in SQL). Same distribution as plan mode: 53 / 59 / 62 / 72 groups by groups spanned, 146 / 52 / 48 by closure size, 54 over more than one drainage code; 72 groups have a three-digit root (48 of them Fraser, Peace or Columbia, the rest small coastal drainages such as ALBN's 930). Report `data/checks/segment_group_closure.txt`, log `data/logs/157/segment_group_closure_m1.log`.
- `scripts/segment_group.R` run on m4 from worktree `~/Projects/repo/wet-157` (data/wb symlinked to the main checkout's), logs in m4's main checkout `data/logs/157/segment_group_*`. Whole build in about 20 s per group (BULK: sampling 9 s, accumulation 2 s, read of the published parts 3 s).
- Resampling BULK and SALR on m4 gives samples `identical()` to the province run's.
- SALR: every watershed and segment row equal to the published product within 1e-9 relative (largest 4.6e-13 mm), pick identical.
- BULK: 11 watersheds (132 watershed rows, 144 segment rows, months 1-12 only) differ by 5.8e-5 relative. All 11 sit at a calibration gauge: the province run's upstream means are the donor rows, so their distance is exactly 0 and `wet_donor_mean()` gives the gauge's shares alone; the closure's sums differ in the last bits (upstream means ≤ 1.4e-12 relative), the distance becomes ~1e-15, and the other donors weigh in at about 1e-6 / d each. Attribution: ours, the donor rule's exact-zero test. The listing first printed the wrong columns (fixed at ae518cb); probe `scratchpad/probe_donor.R` confirmed 12 BULK watersheds at distance 0 in the province run, 1 in the group build, and no share difference elsewhere.
- Deliberate break (MORR removed from BULK's closure): 3,449 watershed and 4,825 segment rows differ, up to 336 m3/s; report `data/logs/157/segment_group_BULK_drop-MORR_20260717.txt` on m4.
- Filed #158 (donor shares' exact-zero distance test at calibration gauges; a scoring-file change, so not in this branch). Verdict in `research/segment_group.md` with a row in `research/README.md`, a script line in `CLAUDE.md`, and #157's body answered in place.
- Correction: the closure note above says the 72 three-digit-root groups include "48 of them Fraser, Peace or Columbia". Wrong, from the plan-mode note: the 48 closures over 200,000 polygons are groups on the Fraser, Columbia, Skeena, Stikine, Peace and Liard main stems and in the 910 and 915 coastal drainages (code-check round 1). Research file and #157's body corrected.
- `/code-check branch` round 1 (`review-round1.md`): 3 findings, all fixed: a deliberate break overwrote the group's real parquet (now under `drop-<G>/`); `INSTALL httpfs` before `LOAD`; the research sentence above. Branch-mode setup: soul's `gh_rest.sh` does not parse under `/bin/bash` 3.2, filed as soul#718; default branch read with `gh api` instead.
- Full suite on m1: 0 failed, 5 skipped (fwapg#41 snap tests and similar), log `data/logs/157/devtools_test_m1.log`.
- `/code-check branch` round 2 (`review-round2.md`): 2 findings, both in the verdict and one inside round 1's fix ("72 groups have a whole drainage as their closure"; the code counts closures that include one), plus claims the script cannot back (resampling "only a group whose inputs changed"; building a scenario from new layers, which the province-run and live-build guards refuse). Fixed, and the claims enumerated (below).
- Enumeration of every claim in `research/segment_group.md`, its README row, the CLAUDE.md line, #157's Answer and the two scripts' headers, each against its report or code. Beyond round 2's: "about half" made exact (112 of 246, closure ≤ 3 groups); round 1's own fix was wrong again: by the root holding the most polygons the 48 largest are Fraser 13, Columbia 7, Peace 5, Liard 5, Stikine 4, coastal 910 14, no Skeena or 915 (probe `scratchpad/probe48.R`, codes named from `fwa_stream_networks_sp`); "tributary and headwater groups need a few neighbours" replaced (LNRS needs 18 others); the zone-column claim scoped to BULK and SALR; "tests a change in the segment layer" restated as a change tried in the script's own segment step; the closure script's "about five minutes" (27 s); the script header's "donor near-tie" (the mechanism found is the exact-zero test).
- `/code-check branch` round 3 (`review-round3.md`): the mechanism behind rounds 1-2 is one set described as another. The closure under a group's roots is enough, not what the rows need: SALR's rows reach 4,589 polygons (its 4,587 and 2 of LSAL's) of its closure's 12,481 (reproduced with the brute oracle, `scratchpad/probe_reach.R`). The plan-mode "position-aware refinement changes no count" was wrong. Plan corrected: `wet_ws_reach()` trims a closure to what `FWA_Upstream` reaches from the group's rows (same ranges as `wet_upstream_sums()`; tested against the oracle on 40 random trees, a mutant without the tributary range caught on 18 of 40; live SALR = SALR + 2 LSAL, BULK = whole closure); `segment_group.R` accumulates over the reach; the closure table counts both (195 s): reach ≤ 3 groups for 138 groups (closure 112), over 200,000 polygons for 24 (closure 48), reach = closure for 106; UFRA 23,358 of 644,770. Also the roxygen's whole-basin condition (any group polygon with a basin-root wscode, whatever its localcode).
- BULK, SALR and the MORR break rerun on m4 at fd808ab: SALR still 0 rows differing (upstream means ≤ 4.1e-15 relative, over 4,589 polygons now); BULK unchanged (its reach is its closure); break unchanged.
