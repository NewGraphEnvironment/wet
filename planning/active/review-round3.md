## Checklist read
- code-check.md: the prose of all 14 H3 under `## Mechanisms` (table rows skipped) and "Documentation Staleness". 15 of 38 H3 read, 23 not read.
- code-check-r.md: "Regenerated binaries churn git even when nothing changed" and "`identical()` on two reader results tests the reader, not the file". 132 of 134 not read.
- code-check-shell.md: "`git diff a..b` compares TIPS..." and the `pgrep -f` waiter heading. 73 of 75 not read.
- code-check-spatial.md: none of its 99 read (the diff uses no spatial tool).
- index, diff and changed files read from file

## Findings

- **[severity: fragile]** research/discharge_publish.md:5. The Status paragraph now has two present-tense "The tracked report is" sentences naming different builds. The new one says it is the BUILD at wet 2ee50dc4. An earlier one, left in place, says "The tracked report is the BUILD rerun after that upload, at wet 34f38a9 ... Its line predates the parts' digests (#94), so the vignette data scripts refuse it until the next BUILD writes them." Both halves are false of the report this branch commits: it names 2ee50dc4, it carries both digests, and findings.md records that `vd_published()` passes on it. The earlier sentence was already stale on main. The last fix rewrote the sentence about #163's upload but not this one. Put it in the past tense ("The report tracked after that upload was ..., and its line predated the digests").
  - **Rule:** code-check.md, "Documentation Staleness"

- **[severity: fragile]** research/discharge_publish.md:5 and planning/active/findings.md:22. "Its tree differs from the live one in `receipt.json` alone" and "the new tree and the live one each hold 760 files and only `receipt.json` differs" are false as worded. The tree also holds `manifest.json` (listed as part of the tree in the header of scripts/discharge_publish.R), and that file differs too. The live manifest names wet a0318b7 / 0.4.35, segment commits 66cf795 and bc55d30, and schema version 0.16.0. `wet_manifest_write()` in the new BUILD writes 2ee50dc4, 6a1d7316, 40e25e56, 0.21.0, a new `built` time and a new receipt entry. The comparison behind the sentence covers only the 760 files the manifest lists, and the manifest is not one of them. Say "of the 760 files the manifest lists, only `receipt.json` differs (the manifest itself also names the new build)".
  - **Rule:** code-check.md, "A guard's scope, escape hatches, and remedies" (a claim's quantifier wider than what was enumerated)

- **[severity: fragile]** research/discharge_publish.md:5. "On 2026-11-28 (UTC) the chain was rerun at 0.7.0" is only partly true. According to the run logs, the monthly segment run started and ended on 2026-11-27 UTC (23:06:31Z to 23:15:03Z), and the daily run started at 23:15:36Z that day. Only the end of the daily run, the BUILD and the live check fall on 11-28. findings.md has it right ("2026-11-27 to 11-28 (UTC)"), so use that range. The "Verified: 2026-11-28" entry can stay.
  - **Rule:** none

## Mechanism

A sentence written for one referent or scope is carried to another, and nothing re-reads it against the artifact it is now about. It takes two forms.
1. **Wider than the comparison.** The wording covers a bigger set, or a further-downstream object, than the evidence read: manifest md5s read as live parts (round 2), "no report or table script moved" (round 1), "tree" for the manifest's file list, and one day for a two-day run.
2. **A moving pointer.** "The tracked report" means whatever file is committed now, so regenerating it changes every present-tense sentence that uses the phrase. Round 2 fixed one such sentence and not its neighbour.

Round 1's machine-setup line is a separate mechanism: session troubleshooting copied into committed public text. I found no further instance in the text the last two commits added.

## Every place it reaches in the added text

| Place | Claim | Verdict |
|---|---|---|
| research:3 Verified | 11-28: rerun at 0.7.0, nothing uploaded, every live object checked against the manifest | Holds as the date verified. "Live object" means the manifest's files |
| research:5 | "On 2026-11-28 (UTC) the chain was rerun" | Finding 3 |
| research:5 | live manifest and receipt still name a0318b7 | Holds (manifest read anonymously) |
| research:5 | 23 monthly and 246 daily table files identical | Holds (before and after md5 lists) |
| research:5 | BUILD's 512 parts identical to live | Holds: the BUILD against the manifest, then the manifest against the live objects |
| research:5 | tracked report is that BUILD, with its four identifiers; live-build line is the BUILD's own | Holds against the report |
| research:5, the unchanged sentence about 34f38a9 | a second "tracked report" | Finding 1 |
| research:5 | tree differs in `receipt.json` alone | Finding 2 |
| research:5 | BUILD compares with manifest md5s, not objects; 760 listed files matched afterwards | Holds (`publish_live_line()`; rerun below) |
| research:5 | "That upload's report carried a live-build line PUBLISH wrote itself" | Holds: the report committed after #163's upload (e7f1fe11) names 3e8a968, 512 of 512, where the report before it named b4bbc50, 499 |
| research:93 (unchanged), "tracked segment report" | identical to its copy at the BUILD's commit | Holds as a rule; findings.md records that `vd_segment_report()` passes |
| findings: probes paragraph | database, versions, fingerprints | Not rechecked this round |
| findings: run table | times, commits, md5 counts, 16 checks, values compared | Times, md5 lists, checks, values and 512 of 512 match the logs and report |
| findings:22 | "each hold 760 files and only `receipt.json` differs" | Finding 2 |
| findings: live-objects paragraph | BUILD reads no live part; 760 files, bytes, digest, two deliberate breaks; scoped "for each file" | Holds |
| findings: guards after the runs | the two guards and two test files pass | Not rerun this round; round 1 reports them |
| findings: main moved | 12 files at this head | Scoped to the monthly guard. Rounds 1 and 2 each listed the same files |
| progress: second merge | moved none of the three reports or the five named scripts | Holds as now scoped |
| progress: round 2 line and task_plan live-object box | "all 760 live objects", "every live object checked against the live manifest" | Holds for the listed files; the count or the phrase "against the live manifest" bounds it. Unlisted keys cannot be seen, since the bucket allows no listing |
| task_plan Phase 2 and 3 boxes | tables compared, nothing published, no part differed | Holds |
| review-round1.md, review-round2.md | dated review records | Describe the tree at their own time; no change needed |

I reran the live check (anonymous reads) at 2026-11-28 04:54:59 UTC: 760 of 760 ok, 34,805,125,351 bytes, digest d554e3aad481d86bffa4baef687287ed, and both deliberate breaks failed as described.
