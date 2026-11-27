# Findings — Backlog move 12: Research files around the current state (#189)

## Issue context

**If we do it:** four research notes that grew one section per issue read as what is true now, each number checked against its report, and the revise-in-place rule #181 tests is refined over four files. **If we never do:** readers replay issue-ordered histories to learn what ships today, and `research/station_flow_departure.md` keeps statements last checked on 2026-09-28.

Order: `planning/backlog.md`, move 12. Run `/planning-init <this issue>`: one phase, one PR.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 12, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 14: research files around the current state

**Why here:** one pass, one method (rewrite around the current state, move narrative to archive READMEs, check every number, fix links), run over the files soul's research check flags. It waits on move 10, which rewrites `research/chinook_sites.md`.

**Touches:** `research/water_balance_method.md`, `research/chinook_sites.md`, `research/discharge_publish.md`, `research/station_flow_departure.md`, the links into them in `CLAUDE.md`, the articles and `planning/archive/` READMEs.

**Decided at the gate:** none beyond #181's rule; whichever of move 10 and this move lands second folds the other's `research/chinook_sites.md` changes in.

| issue | title |
|---|---|
| #181 | Consolidate research/water_balance_method.md and research/chinook_sites.md around the current state |
| #183 | Consolidate research/discharge_publish.md around the current state |
| #184 | Consolidate research/station_flow_departure.md around the current state, and re-verify it |


## Planning exploration (2026-11-27, at 49afd870)

`research_check.sh` (soul's published copy):

| file | prose words | issue-headed sections | verified | flag |
|---|---|---|---|---|
| `water_balance_method.md` | 16,109 | 16 | 2026-11-13 | words, sections |
| `discharge_publish.md` | 4,546 | 3 | 2026-11-15 | words, sections |
| `station_flow_departure.md` | 3,186 | 5 | 2026-09-28 | words, sections |
| `chinook_sites.md` | 3,221 | 2 | 2026-10-28 | words |
| `fwapg_mad_method.md` | 1,037 | 2 | 2026-09-25 | age |

- In `water_balance_method.md`, a separate count of non-table words gave about 12,500 in section 0 and 3,578 in sections 1–7.
  "Skill with CGIAR AET, as built in #11" is the largest subsection (2,725), and the current routed-PCIC and segment-pick
  statements are nested under it.
- Hashed or registered scripts cite the file by section (`scripts/wb_cv_lib.R`, `wb_gate_rule.R`, `wb_aet_compare.R`,
  `wb_fit_accept.R`), so those anchors cannot move without staling a fit.
- `research/station_snap.md` cites "Reproducing #15 and #18"; `research/station_sources.md` cites chinook_sites'
  "Natural stations outside HYDAT as donors". Many archive READMEs, plans and review files quote section names.
- Links to the five files outside `planning/archive/`: `CLAUDE.md`, `NEWS.md` (past entries, file-level), `research/`,
  two vignettes and one article (file-level links).
- Every plain-named `data/checks/*.txt` or `data/basin/*.txt` path the five files cite exists and is tracked (wildcard
  forms not checked). The upstream-area reports are in `data/checks/`. The Fraser parity report is the tracked
  `data/basin/100_report.txt` (my first listing missed it; the Plan review found it). The SALR parity tables are in the #1
  archive.
- Checked after the Plan review, each disagreeing with its note: the routed-days figures
  (`segment_daily_output_20260717.txt` lines 21-27), the nested selection (`wb_aet_compare_20260717.txt` lines 29, 40,
  47: 30.7), 08EE013's ice days (HYDAT 20260717: 8,101 of 18,620), and the mixed held-out pools in `chinook_sites.md`
  (Maxan's site report, spawning mean: 0.49 in section 3, 0.50 to 0.66 in section 6).
- #76 is open, though `water_balance_method.md`'s follow-ups read "Done in code".
- The main checkout's `data/pcic/` holds cached BASEFLOW and RUNOFF files; the plan reruns nothing, and whether they cover
  the parity runs was not checked.
- Members #181, #183, #184 read `FREE`; #181, #183, #184 and #206 are open with no label; no open pull request. #189's
  body table lacks #206, which `planning/backlog.md`'s batch 14 names.
- None of the member issues carries a comment.

## Errors Encountered

| Error | Resolution |
|-------|------------|
