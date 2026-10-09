# Progress — Score PCIC routed flow at the gauges; replace the vignette's fwapg comparison (#58)

## Session 2026-10-09

- Plan-mode exploration — phases approved by user
- Created branch `58-score-pcic-routed-flow-at-the-gauges-rep` off main
- Scaffolded PWF baseline from issue #58 with approved phases
- Next: start Phase 1
- Phase 1: `scripts/pcic_routed_lib.R` and `scripts/pcic_routed_compare.R` (4c32936). Against the pre-rebuild table they reproduce #57's balance columns exactly and its routed columns to within 0.3 points (findings.md).
- Phase 2 held: at 08:2x PDT another session was running the fwapg crosswalk job against fresh-db from its fwapg#2 branch (uncommitted `blue_line_paths` refactor). A rebuild would collide on the same staging and output tables. Escalating the choice to the user. Phase 4/5 code proceeds meanwhile.
- Phase 4 code: tests expect the routed shape; data-raw reads routed flow through `pcic_routed_lib.R` and checks the tracked report; the map outline is routed coverage; the registry label is "PCIC routed flow coverage". Data rebuild pending the routed table.
