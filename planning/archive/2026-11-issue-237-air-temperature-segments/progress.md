# Progress — Backlog move 21: Daily air temperature at every stream segment (#237)

## Session 2026-11-26

- Explored and drafted the phases; no plan gate in this pane: parked for the coordinator's plan gate
- Created branch `237-backlog-move-21-daily-air-temperature-at` off origin/main
- Scaffolded PWF baseline from issue #237 with the drafted phases
- Next: parked 2026-11-26; paste the block under ### Resume into a fresh session

### Resume

```
Continue wet#237 from its parked PWF baseline. Repo ~/Projects/repo/wet, branch `237-backlog-move-21-daily-air-temperature-at`,
parked 2026-11-26 by `/planning-init wet#237 park review`, branched from origin/main at da85a4c.
Run these in order, and stop at the first that fails; each failure means what it says:

cd ~/Projects/repo/wet && git fetch -q origin
git worktree list | grep -F '[237-backlog-move-21-daily-air-temperature-at]' || echo none   # a path printed: that tree holds the branch; cd to it and skip the checkout
git branch --show-current; git status --porcelain --untracked-files=no   # another branch with changes, or one another session may be on: do not check out here; git worktree add ../wet-237 237-backlog-move-21-daily-air-temperature-at and cd there
git checkout 237-backlog-move-21-daily-air-temperature-at   # fails: the branch is not on origin
git pull --ff-only   # fails: this machine has commits origin lacks; resume where they were made
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- R/wet_air_daily.R R/wet_catalog.R R/wet_db_load.R R/wet_segment_daily.R R/wet_segment_monthly.R R/wet_station_snap.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- R/wet_temp_fill.R tests/testthat/test-wet_air_daily.R tests/testthat/test-wet_catalog.R tests/testthat/test-wet_db_load.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- tests/testthat/test-publish_own.R tests/testthat/test-air_publish_lib.R scripts/air_publish.R scripts/air_publish_lib.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/air_station_check.R scripts/discharge_publish.R scripts/discharge_publish_lib.R scripts/discharge_publish_own.R   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- scripts/temp_fill_validate.R scripts/temp_baseline_traits.R data-raw/air_example_data.R inst/extdata/air_example/   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- inst/receipt/air_temperature_fwa_v1.yaml inst/receipt/discharge_fwa_v1.yaml data/checks/air_publish_2025.txt   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- data/checks/air_station_check_2025.txt research/air_temperature_segments.md research/README.md   # plan files that moved on main since the park
git diff --name-only da85a4c4418bf6c3b76fea519a1567681857f2ae origin/main -- research/discharge_publish.md research/station_temperature_fill.md CLAUDE.md NEWS.md DESCRIPTION _pkgdown.yml   # plan files that moved on main since the park
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
answer (when the last item moves out, delete the heading), and write a fork you meet
yourself under that same heading.
Start Phase 1 and run every phase to the PR (/code-check branch, /planning-archive,
/gh-pr-push). This message is the resume instruction that starts the run-to-PR
mandate; the merge stays with me.
```

## Session 2026-11-27 (resume)

- Resumed at 3e89bbd8; merged origin/main (v0.7.0; only CLAUDE.md, DESCRIPTION and NEWS.md among the plan's files moved, none in a way that changes a phase). Member check FREE at every phase start so far.
- Owner answered the ten open decisions: all as recommended. Written into "Decided at the gate" and #216's body (`## Decisions`, edge premise corrected, station condition reworded).

## Phase 1, 2026-11-27
- Measurements in `findings.md`: the lookup about 6 min for the province (no cd speed issue), the series about 1.99 GB over 76 years (0.89 GB `tmean` alone), 13 of 279 stations in another cell than their segment's midpoint (27 for the downstream end). No stop rule fired.
- Filed NewGraphEnvironment/cd#161 (cell elevation), wet#246 (`cell_elev_m`, waits on cd#161), wet#247 (stale 59.95° N edge in the gap-fill notes), crate#81 (schemas and `date` type).
- crate branch `air-temperature-fwa-v1` in worktree `~/Projects/repo/crate-air`: `date` type, the two schemas, registry rows, decision record `decisions/nge/20261127_air_temperature_fwa.md`, tests (2,878 pass). Code-check round 1 found two doc claims and a fixture id, fixed; round 2 running. **Phase 4 needs the crate pull request merged, released and installed**; DESCRIPTION's crate floor and the bundled example manifest's crate version (`data-raw/air_example_data.R`, rerun) follow that release.
- Commits: 32717954, a761745d

## Phase 2, 2026-11-27
- `R/wet_air_daily.R`: `wet_air_daily()` (exported) and internal `wet_air_cells()`, `wet_air_cell_id()`. One change from the plan's wording: the result carries `cell_id` (ERA5-Land's own grid, decision 3) and `cell_status` in place of cd's `cell`, since the published key is not cd's cell number; the values, dates, centres and `cell_moved` are compared `identical()` with `cd_extract_daily()` at the stored points.
- `tests/testthat/helper-air.R` masks cd's example cube (cells 1, 2, 6, 7, 19), giving every status; `data-raw/air_example_data.R` writes `inst/extdata/air_example/` (about 22 KB) through `scripts/air_publish_lib.R`'s writer, byte-identical on a rerun.
- `wet_receipt_write()` takes its summary from the declaration and its file from the tree ID: the discharge fixture's receipt and manifest are byte-identical before and after (md5 6e12167e… and fc2b3501…). `wet_db_load()` refuses the air tree before any fetch. cd floor 0.6.13; `wet_air_daily` in the reference index.

## Phase 3, 2026-11-27
- `scripts/air_publish.R`, `scripts/air_publish_lib.R`, `scripts/air_station_check.R`; the lib's tests derive the upload guard's file list from the scripts' calls (they caught `R/wet_db_load.R`'s `%||%`). A trial of the build on VICT and CLAY, 2024–2025, passed every check.
- `/code-check branch`: rounds 1–4 found eleven instances of one mechanism (a fact held in two places, nothing holding them equal), round 4 one inside round 3's fix; ended on an enumeration of 20 facts (`review-enumeration.md`). Bundled tree moved to `inst/air/` so no tarball path passes 100 bytes.
- crate PR #82 merged with the owner's approval and released as crate 0.22.0 (the schemas and the `date` type); installed.

## Phase 4, 2026-11-28
- BUILD at e461b677: 1 h 52 min, every check passing; mutation table in findings; station check passing (314 stations), shown able to fail; second BUILD at b2de756e byte-identical in its parts (digest 97d7eeea), its report the tracked one; reader timed.

## Phase 5, 2026-11-28
- `research/air_temperature_segments.md`, `research/discharge_publish.md`'s naming rule, `research/README.md`, CLAUDE.md, NEWS, #216's body. Review round 5 over these and the reports; verdict `review-verdict.md` (enumeration, 5 rounds).
- Not done here, waiting on the owner: the bucket policy for `air_temperature/*` and the upload (Phase 6 and the PR body).
