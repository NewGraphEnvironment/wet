# Plan review (Plan agent, 2026-10-18, against HEAD 5215906)

Findings and what was done with each. A probe or code read checked each one before it was acted on.

| id | finding | disposition |
|---|---|---|
| B1 | PUBLISH (`discharge_publish.R:61-124`) uploads and verifies but writes no report; `vd_published()` (`vignette_data_lib.R:68-73`) needs the report's "identical to the published build" line to name the live build, so Phase 4 refuses after an upload unless BUILD is rerun and its report committed (#77 did this: 5ad20df) | Folded: Phase 3 gains "rerun BUILD after the upload, commit its N of N report" |
| O1 | BUILD refuses an R/ or scripts/ change made after the segment table's commit; PUBLISH refuses one made after BUILD | Accepted risk: the R/ and scripts/ diff is the pin and a comment; any /code-check fix there reruns segment_output + BUILD |
| O2 | the routed report's "Not like for like" bullet reads "Routed flow is 1981-2010; the balance is 1981-2010 normals" | Kept: still true, the difference left is the gauges' complete years; rewording is a scripts/ edit that would rerun the chain |
| O3 | `vd_commit()` refuses uncommitted data-raw changes | Folded: commit data-raw edits before running the data scripts |
| O4 | machine moves: pull on m4 before segment_output, on m1 before Phase 4; data scripts need `WET_FWAPG_COMMIT=7c30f58` | Folded |
| G1 | monthly-flow.Rmd has more routed-value stopifnot()s (Buck Creek peak, Quick July-Aug, q_short, poor window, `5:9 %in% r_closer`, basin-size table) | Knit decides; rewrite prose wherever one fails |
| G2 | the #67 attribution's per-gauge shares came from the long-record block | Done: recomputed on `both` and asserted > 50 % in score-text; findings wording settled to "PCIC's model" |
| G3 | no check of the shared period once the 1951-2012 assertion goes; segment article period hand-typed | Done for monthly (`period_of()` equal); segment article: assert against `prov$routed` |
| G4 | redundant routed_text uses, "from their own periods", What's next item | Done |
| G5 | segment-discharge checks that could flip (`nech_bal > 90`, `n_rt_closer > n_both/2`) | Knit decides |
| G6 | keep `hydat <- wb_hydat(release)`; edit no64/values/header | Done |
| G7 | research/water_balance_method.md:76-111 quotes 1951-2012 results; discharge_publish.md:62; CLAUDE.md:49, :63; README alt text | Folded into Phase 5 / Phase 4 |
| G8 | verify the live manifest's pcic_routed entry and DISTINCT source, period over the live parts | Folded into Verification |
| A1 | m4's fwapg must hold the same run | segment_output's fingerprint guard checks it |
| A2 | gauges' years are each gauge's complete years within 1981-2010 | Prose says "the period the gauges are scored over", not "the gauges cover it exactly" |
| A3 | manifest names a branch commit and v0.4.13 | As for earlier publishes; merge with a merge commit (gh-pr-merge), never squash |
| A4 | March-April narrowly past -10 % | Knit decides |
| S1 | local Postgres `discharge.*` on m4 goes stale after the upload | Folded: reload on m4 with `wet_db_load()` after the upload |
| S2 | NEWS | Left to /gh-pr-merge |
| S3 | fixture "1951-2012" in helper-discharge.R | Left: made-up data; changing it rebuilds the shipped fixture manifest |

## /code-check branch

| Round | Findings | Fixed | Accepted | Inside previous fix? |
|---|---|---|---|---|
| 1 | 2 (discharge_publish.md status stale and claimed an upload; probes cited under gitignored data/logs) | 2 | 0 | — |
| 2 | 1 (round 1's status rewrite left "The upload took about 4 min" reading as #103's) | 1 | 0 | yes |
| 3 | 3 ("every routed value changed" unmeasured, 3,824,264 of 40,524,444 equal; discharge_publish.md:77 fingerprint still the 1951-2012 run's; water_balance_method.md:74 Salmon per-gauge routed errors from the 1951-2012 run, outside the diff) | 3 | 0 | no |

Ended by enumeration: every publish-state sentence in research/discharge_publish.md (the Verified line, the 8 Status sentences, the 5 manifest-bullet sentences; 14 in all) assigned to the build it describes. Only round 2's sentence was wrong; it now follows the 2026-10-15 upload it describes. R/, scripts/, data-raw/, tests and vignettes: no findings in either round.

Round 3 (after the upload and Phase 4) named the mechanism: the sentences to update came from a planning-time list of lines, not a grep for the values that changed. It enumerated every sentence in the diff stating a publish state, period, build commit, count or score against the reports, the evidence files and the live manifest (all true but the two above). I then grepped the tracked text (research/, CLAUDE.md, README.md, vignettes/, R/, scripts/, data-raw/, tests/, man/) for the changed values (`178035348`, `1951-2012`/`1951–2012`, the old pick counts 3,152,838 / 1,380,005 / 224,199, "every routed value") and for every per-gauge routed figure in research/ and the vignettes: the remaining hits are labelled history, CLAUDE.md's daily-series period (true), the test fixture's period, and water_balance_method.md:82, whose routed numbers match the current report. Each number in the round-3 fixes traces to a query (m1 `pcic.discharge_monthly` join) or a report line. Ended by that enumeration; 3 rounds, 3 reviewer agents.
