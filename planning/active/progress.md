# Progress — Score PCIC routed flow at the gauges; replace the vignette's fwapg comparison (#58)

## Session 2026-10-09

- Plan-mode exploration — phases approved by user
- Created branch `58-score-pcic-routed-flow-at-the-gauges-rep` off main
- Scaffolded PWF baseline from issue #58 with approved phases
- Next: start Phase 1
- Phase 1: `scripts/pcic_routed_lib.R` and `scripts/pcic_routed_compare.R` (4c32936). Against the pre-rebuild table they reproduce #57's balance columns exactly and its routed columns to within 0.3 points (findings.md).
- Phase 2 held: at 08:2x PDT another session was running the fwapg crosswalk job against fresh-db from its fwapg#2 branch (uncommitted `blue_line_paths` refactor). A rebuild would collide on the same staging and output tables. Escalating the choice to the user. Phase 4/5 code proceeds meanwhile.
- Phase 4 code: tests expect the routed shape; data-raw reads routed flow through `pcic_routed_lib.R` and checks the tracked report; the map outline is routed coverage; the registry label is "PCIC routed flow coverage". Data rebuild pending the routed table.
- 2026-10-09 ~09:2x PDT: fwapg-56 gave the go-ahead; the pinned run at 218a47f started. Before-fingerprint: 40,524,612 rows, 3,377,051 segments, 0 null, sum(round(q,6)) 178169881.209890.
- 09:07 PDT: m1 rebooted (uptime), killing the run partway through the paths step, before the routed table was dropped (same fingerprint afterwards). The scratchpad worktree was lost too.
- 09:42 PDT: worktree recreated at 218a47f and the run restarted. Log: `data/pcic_routed/build_218a47f.log` (gitignored, survives a reboot).
- Vignette "Two estimates" section rewritten for routed PCIC (committed WIP; SALR/BULK still read the old fields until the data rebuild).
- ~09:50 PDT: m1 rebooted a second time, killing the restarted run at its outlets step; the routed table still matched the before-fingerprint at 12:55.
- 12:57 PDT: worktree moved to `data/pcic_routed/fwapg-218a47f` (gitignored and build-ignored; the scratchpad does not survive a reboot) and the job started detached with nohup (PID in `data/pcic_routed/build.pid`), so it no longer depends on the Claude session.
- 13:05 PDT: third forced reset of m1 (memory pressure from the fwapg#2 SSNbler batch next to colima's 32 GiB VM; findings.md). The run died in the paths step again; the routed table is unchanged. Held on the user's instruction until fwapg finishes; the rebuild may move to m4. Resume: Phase 2, from the `data/pcic_routed/fwapg-218a47f` worktree (or the same commit on m4).
