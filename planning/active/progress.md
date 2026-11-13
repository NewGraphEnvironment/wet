# Progress — Backlog move 1: One refit chain (#163)

## Session 2026-11-12

- Plan-mode exploration — phases approved by the owner as a park
- Created branch `163-backlog-move-1-one-refit-chain-input-key` off origin/main (1d6a89f); claimed #163 (`in-flight`)
- Scaffolded PWF baseline from issue #163 with approved phases
- Next: parked 2026-11-12; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#163 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `163-backlog-move-1-one-refit-chain-input-key`,
parked 2026-11-13 by `/planning-init wet#163 park`, branched from origin/main at 1d6a89f.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[163-backlog-move-1-one-refit-chain-input-key]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-163 163-backlog-move-1-one-refit-chain-input-key and cd there
git checkout 163-backlog-move-1-one-refit-chain-input-key   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git merge origin/main   # a conflict: main moved meanwhile; resolve it, commit, and go on

Then read planning/active/task_plan.md, findings.md, progress.md and review-plan.md if present.
The gate decisions, the measurements and the Plan-agent review are already folded in:
do not re-plan and do not re-ask them.
Start Phase 1 and run every phase to the PR (/code-check branch, /planning-archive,
/gh-pr-push). This message is the resume instruction that starts the run-to-PR
mandate; the merge stays with me.
```

## Session 2026-11-13

- Resumed; decided at resume (owner): PUBLISH under the new run key; retire `adjust_override.txt` with its reader; the CGIAR crop checks figshare's md5 on a rebuild; the two `fu35` gate flips go on; the routed rebuild found on m4 (fwapg#24's Nechako, fwapg 5d50cc1) adopted in this move
- Phases 1–5 landed: ed8f459 (input keys, #51), 0f81f04 (`wb_run_compare.R`), 2f7e5c0 (#158), d7cf0eb (rule registered alone), b8a4849 (gate score), 69e5fc6 / 29e17d8 (gate applied, override reader retired)
- `/code-check branch`: rounds 1–4 (2cc295e, 44cc51a, 9c0f762, ff6a7b2) and the enumeration (4332165); round 4 found a defect inside round 3's fix, so the loop ended on the enumeration
- Phase 6 on m4 (logs `data/logs/163/chain163_[abcd]*`): rekeyed inputs byte-identical, run `768876badf` = `92b893c4da` in every file, reports reproduce byte for byte (b2edff5); refit decisions and numbers identical, `gate_arm` margin; balance `output/` identical. chain_c stopped at the segment compare on the routed rebuild (37d6ae4); chain_d resumed from the routed comparison under `WET_FWAPG_COMMIT=5d50cc1`
- Docs: d9dc394, 5159531
