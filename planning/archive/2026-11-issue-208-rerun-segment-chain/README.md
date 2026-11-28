## Outcome

The segment chain (`segment_output.R`, `segment_daily_output.R`, `discharge_publish.R` BUILD) was rerun at `wet` 0.7.0 on the full province run. Every table and every published part came out byte-identical, and nothing was uploaded, so the live manifest and receipt still name build a0318b7 (`wet` 0.4.35). The three reports are committed. Two things were learned. The BUILD compares its parts with the md5s the live manifest lists and reads no live object, so "512 of 512 identical" alone does not check the live parts: `wet_catalog_verify()` over the live manifest does, and was run after it. And the tables are current only for the code they were built under: `main` moved during the runs, and with it merged the BUILD's code guard lists 12 station, logger and temperature files that are not on `publish_own`, so a BUILD at this branch's head would refuse the tables until they are rerun or those files are checked and listed. [wet#209](https://github.com/NewGraphEnvironment/wet/issues/209) (move 16) meets this if a candidate ships. The current statement of the build is in `research/discharge_publish.md`.

## Measurement

| run (UTC, 2026-11-27 to 11-28) | time | result |
|---|---|---|
| monthly segment table | 8.5 min | 23 of 23 files md5-identical to the previous table |
| daily segment table | 2 h 10 min (136.7 min in the report before) | 246 of 246 identical |
| publish BUILD | 3 h 18 min | 512 of 512 parts identical to live; 16 of 16 cross-checks ok; 15,040,448,264 values compared, 0 differing |
| live objects against the live manifest | about a minute | 760 of 760 match size and md5; a wrong md5 and a missing key both fail |

- Of the 760 files the manifest lists, only `receipt.json` differs from live: time, `wet` commit and version, `crate` version (0.16.0 to 0.21.0) and the `recipe_id`. The installed `crate` was newer than the plan expected and was left as it was; the parts' bytes did not move.
- What changed because of this: nothing was republished. Move 16 starts from tables and parts checked as of this rerun.
- Wrong turns, from the code check: the first record claimed the issue's "every live part checked" on the BUILD's line alone (round 2), and described the trees as differing in the receipt alone when only the manifest's listed files had been compared (round 3).

## Evidence

Run logs and the before and after md5 lists: `data/logs/208/` in the main checkout of the machine that holds the full province run. The previous segment tables are set aside as `_pre208` beside the fit there; they are md5-identical to the new ones. The code check: `review-round*.md`, `review-enumeration.md`, `review-verdict.md`.

Closed by: the pull request for branch `208-backlog-move-15-re-run-the-segment-chain`.
