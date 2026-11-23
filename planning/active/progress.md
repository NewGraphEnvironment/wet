# Progress — Backlog move 6: Pilot PCIC's channel-scale output on the FWA (#168)

## Session 2026-11-22

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate (soul#928)
- Created branch `168-backlog-move-6-pilot-pcic-s-channel-scal` off origin/main
- Scaffolded PWF baseline from issue #168 with the drafted phases
- Next: parked 2026-11-22; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#168 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `168-backlog-move-6-pilot-pcic-s-channel-scal`,
parked 2026-11-22 by `/planning-init wet#168 park review`, branched from origin/main at eaa12d9.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[168-backlog-move-6-pilot-pcic-s-channel-scal]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-168 168-backlog-move-6-pilot-pcic-s-channel-scal and cd there
git checkout 168-backlog-move-6-pilot-pcic-s-channel-scal   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- planning/backlog.md CLAUDE.md scripts/channel_scale_sites.csv scripts/channel_scale_pilot.R scripts/departure_sites.csv   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/pcic_routed_lib.R scripts/wb_fit_lib.R scripts/mad_basin.R scripts/pcic_routed_compare.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- scripts/gauge_monthly_compare.R R/wet_segment_monthly.R R/wet_station_monthly.R R/wet_station_select.R R/wet_ws_fetch.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- R/wet_ws_sample.R R/wet_upstream_mean.R R/wet_mm_to_m3s.R R/wet_flow_validate.R R/wet_temp_daily.R R/wet_pcic_index.R   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- research/pcic_channel_scale.md research/README.md research/pcic_hydrology.md research/monthly_error.md   # plan files that moved on main since the park
git diff --name-only eaa12d9db71a9b8adf143db1647931c3b4f30a2b origin/main -- research/water_balance_method.md data/checks/channel_scale_pilot_20260717.txt   # plan files that moved on main since the park
git merge origin/main   # a conflict: main moved meanwhile; resolve it, commit, and go on

Then read planning/active/task_plan.md, findings.md, progress.md and review-plan.md if present.
The gate decisions, the measurements and the Plan-agent review are already folded in:
do not re-plan and do not re-ask them.
The Plan review ran before the park: do not run it again at this resume. This replaces
the review planning.md item 3 runs beside Phase 1. Check only what moved: each file a
git diff line above printed changed on origin/main since the park, so re-read it against
the phase that edits it and correct the plan where the code moved.
Nothing printed means the plan stands.
One exception: anything task_plan.md lists under its "## Open decisions" heading is not
settled. Ask me each before the phase that needs it, move it to the decisions once I
answer, and write a fork you meet yourself under that same heading.
Start Phase 1 and run every phase to the PR (/code-check branch, /planning-archive,
/gh-pr-push). This message is the resume instruction that starts the run-to-PR
mandate; the merge stays with me.
```

## Resume and Phases 1-2, 2026-11-23 (m1)

- Resumed in worktree `wet-168`; nothing in the plan's files had moved on origin/main since the park, so the plan stood.
- The owner chose the recommended answer of each open decision: 1 (d) all scored gauges, 2 the six sites, 3 (b) CMIP5 to move 7, 4 (a) water temperature as climatology, 5 (a) 90 % / median.
- Phase 1: database up, fingerprint equal to the tracked routed report (fwapg 5d50cc1); probes in `findings.md`; the rule block registered at 7d6c7b1 (2026-11-23 01:46:50 UTC), before the first fetch.
- Phase 2: the site table written from the rules' picks (1ad0efc), which the script refuses to differ from.
- Commits: 7d6c7b1 (rules), dd0cdbf, 3c05244, 6f4871d (the site check, git quoting, the stations path), 1ad0efc (site table).
