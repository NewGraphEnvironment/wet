# Enumeration closing the code check

Round 3 named two mechanisms: a sentence wider than the comparison behind it, and a pointer such as "the tracked report", whose target moves when the file is regenerated. Round 4 corrected two of this file's counts; the blocks below are script output.

## A. The moving pointer

Candidate set 1: sentences in `research/`, `CLAUDE.md`, `README.md`, `NEWS.md` and `vignettes/` matching a name for one of the three regenerated reports, the bare "tracked report" included. Candidate set 2: each value the report diff removed, and the old build commit a0318b7, searched in tracked text outside `planning/` and `data/`.

```
pattern matches (sentences): 34, on 25 lines; about another report: 8; about one of the three: 26
a0318b7: research/discharge_publish.md:5, research/discharge_publish.md:125, research/pcic_scenarios.md:3, research/segment_group.md:57
66cf795: research/discharge_publish.md:5
bc55d30: research/discharge_publish.md:5
crate 0.16.0: research/discharge_publish.md:5
136.7: no hit
e9305ea5: no hit
68ae10bc: no hit
94 s of it: research/discharge_publish.md:5
hashed in 94 s: no hit
```

Of the sentences about the three reports, one states what a committed copy now is: this branch's own, in `research/discharge_publish.md`, true of it. The rest say how scripts treat a report, point to numbers the rerun did not change, or tell of past events. The one stale sentence found (the 34f38a9 one, already stale on `main`) was put in the past tense by round 3's fix; round 4 checked its new wording against git history. The removed values' hits are past-tense accounts of earlier builds. The a0318b7 hits name the live build, which is still a0318b7, or a past load from it.

Round 4 also searched `R/`, `scripts/`, `data-raw/`, `tests/` and `inst/` by fixed phrases and found nothing newly false. A pointer that says only "the report" is outside both phrase searches.

## B. Claims wider than their comparison

Recomputed from the run logs, md5 lists, reports and git:

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
HOLDS crate 0.16.0..0.21.0: among changed files under R/ and the discharge schemas, none is named for discharge, conform or receipt  [['R/crt_handler_dfo_nuseds_all_areas.R', 'R/crt_ingest.R', 'R/crt_schema_cols.R']]
17 claims checked, 0 fail
```

The crate line judges by file name; round 4 also read what `crt_schema_conform()` calls and found no dependence on the changed code.

Outside these checks: the pre-run probes (output quoted in `findings.md`); the guards-after-the-runs paragraph (`vd_published()`, `vd_segment_report()` and the two test files, run once in the build session and again by round 1); and the claims about the public bucket (round 1 rebuilt the new `recipe_id` and fit-and-receipt digest from the public manifest and receipt; round 3 reran the live check, 760 of 760).
