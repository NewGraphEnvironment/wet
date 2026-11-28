# Enumeration after code-check round 3

Round 3 named two mechanisms: a sentence wider than the comparison behind it, and a pointer such as "the tracked report", whose target moves when the file is regenerated.

## A. The moving pointer

- Every sentence or line in `research/`, `CLAUDE.md`, `README.md`, `NEWS.md` and `vignettes/` that names one of the three regenerated reports: 34, each read. One states what the committed copy is (this branch's own sentence in `research/discharge_publish.md`, true of it). The rest say how scripts treat a report, point to numbers the rerun did not change, or tell of past events. One sentence was stale (the 34f38a9 one, already stale on `main`), and round 3's fix put it in the past tense.
- Every value the report diff removed (66cf795, bc55d30, crate 0.16.0, 136.7 min, e9305ea5..., 68ae10bc..., the 94 s hash time), searched in all tracked text outside `planning/` and `data/`: the hits are in one paragraph of `research/discharge_publish.md`, all in past-tense accounts of the #163 and #164 builds.

## B. Claims wider than their comparison

Recomputed from the run logs, md5 lists, reports and git (17 claims, 0 failing):

```
HOLDS segment_output: ran at 6a1d7316, stated duration, exit 0  [2026-11-27 23:06:31 to 2026-11-27 23:15:03, 8.5 min]
HOLDS segment_daily_output: ran at 40e25e56, stated duration, exit 0  [2026-11-27 23:15:36 to 2026-11-28 01:25:29, 129.9 min]
HOLDS discharge_build: ran at 2ee50dc4, stated duration, exit 0  [2026-11-28 01:27:04 to 2026-11-28 04:45:24, 198.3 min]
HOLDS BUILD log first output line is "BUILD run (no upload)", no put/published line
HOLDS segment: 23 of 23 md5-identical, and the before list is the pre-move record  [23 before, 23 after]
HOLDS segment_daily: 246 of 246 md5-identical, and the before list is the pre-move record  [246 before, 246 after]
HOLDS monthly report differs in its commit line alone  [1]
HOLDS daily report differs in commit line and elapsed alone  [2]
HOLDS publish report: changed lines are commit/crate, fit+receipt md5, recipe_id, hash seconds, daily table commit  [['wet commit 2ee50dc4 (s', 'tree fit and receipt m', 'receipt recipe_id b351', 'receipt hashed in 100 ', 'daily: table built at ']]
HOLDS 16 of 16 cross-checks ok, no FAIL in the report  [16]
HOLDS values compared 15,040,448,264, 0 differing (log)
HOLDS 512 of 512 identical to a0318b7, tree parts md5 = live parts md5 = d554e3aa...
HOLDS second merge moved none of the 3 reports or 5 named scripts  [[]]
HOLDS monthly guard from 6a1d7316 at this head lists exactly the 12 files named  [12]
HOLDS since the park, of the plan's files only discharge_publish_own.R moved (first merge)  [['scripts/discharge_publish_own.R']]
HOLDS segment_output.R, wb_output.R, wb_fit_lib.R, wet_source_pick.R unchanged 66cf795..6a1d7316  [[]]
HOLDS crate 0.16.0..0.21.0: no discharge schema, conform or receipt file changed  [['R/crt_handler_dfo_nuseds_all_areas.R', 'R/crt_ingest.R', 'R/crt_schema_cols.R']]
17 claims checked, 0 fail
```

Not recomputable from files: the pre-run probes (their output is quoted in `findings.md`). The receipt comparison and the live-object check are claims about the public bucket: round 1 rebuilt the new `recipe_id` and fit-and-receipt digest from the public manifest and receipt, and round 3 reran the live check (760 of 760).
