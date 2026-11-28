# Backlog move 22: what we can bring, written down, and the baseline read against Bayesian practice (#238)

## Outcome

Two research files, one PR. [`research/temperature_bayesian_alignment.md`](../../../research/temperature_bayesian_alignment.md) (#218) reads the water-temperature gap fill and the whole-station baseline against *Statistical Rethinking* and *BDA3*: 64 modelling choices, each at the line that makes it with a verdict (12 aligned, 21 differs, 7 differs by design, 24 outside the books), what each difference costs in wet's own results, and the departures a network model could remove, largest first (no uncertainty reaching GSDD; stations sharing nothing; no priors; correlated parameters treated as unrelated; plug-in intervals; air and observations as exact). [`research/temperature_network_model.md`](../../../research/temperature_network_model.md) (#217) writes down what a stream temperature network model is for, what we can bring (each input as a file with its columns and where it stands), what we are hoping for, where results would live, how it is tested on the baseline's holdout, and the questions to work through, among them the two ways SSN2 holds a region with more than one outlet (decided: the file lists them and move 23's gate chooses). `scripts/temperature_bayesian_alignment_check.R` holds every quote to its printed page, every row to its anchor's line (whole-line), every formal and numeric constant in scope to its value, the baseline's positional fill settings to the fill's defaults, and every number written with a unit or a sign to its source. The owner approved both files' wording on 2026-11-27, after an outside-modeller cold read was folded in; the input no issue built became #249 (catchment traits and a prediction point per segment). What was learned: a text-level guard keeps failing toward pass wherever its two patterns of one fact disagree. Code-check ran four rounds, three of them finding a defect inside the previous fix, and ended on an enumeration of the 11 pattern pairs the check compares (`findings.md`). The cold read also caught a partition factor described backwards (SSN2's makes separate networks uncorrelated) and a fold of mine that misdescribed the leak-free pool.

## Measurement

- The check against planted breaks: 12 in Phase 1, then each round's probes (rounds 1–4, about 35 in all), every one exit 1 once fixed; a run without the books exits 2. Tables in `findings.md`.
- The quote half reads 20 quotes on their printed pages (Rethinking offset 16, BDA3 offset 10); 34 numbers with a unit in the alignment file and 2 in the network file, each inside a listed figure (an independent scan for unit-adjacent digits found the same 34 and 2).
- Correction to the plan: gsdd 0.3.0.9007 has no `complete` argument; its season choices are `start_temp = 5`, `end_temp = 4`, `window_width = 7`, `ignore_truncation = FALSE`, and `complete = TRUE` is internal.

## Evidence

`data/checks/temperature_bayesian_alignment_*.txt`

## Owed

- #217's body reworded in the file's terms once it exists (its title and a `## Decisions` line were written on 2026-11-26, on the owner's word), and a comment on #217 saying what remains (the outside read) and that nothing is left to build
- Mark #217 done by hand once a reader outside has read the file and its open points are settled or listed (the owner picks the reader after the PR)
- #214's checklist: tick item 5 (#218) and propose to the owner the wording for the #217 line, edited on his word
- A comment on #236: its build reruns `scripts/temperature_bayesian_alignment_check.R` and updates the rows it moves
- The cred issue offering a shared page-anchored quote check, linked from wet's check header once filed (proposed in knowledge's, not edited there)
- #223's line on multiple outlets edited (the issue for traits per segment is filed: #249)

Drafts of each text above, for the owner's word: `owed-drafts.md` in this directory.

Closed by: the PR from branch `238-backlog-move-22-what-we-can-bring-writte`
