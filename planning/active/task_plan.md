# Task: segment_vignette_data.R refuses after a rerun that leaves every published part identical (#93)

## Context

`data-raw/segment_vignette_data.R:170` requires the tracked segment report to begin
`wet commit <segment_commit>;`, with `segment_commit` from the **live manifest** (1718a3d).
Every rerun of `scripts/segment_output.R` writes the current HEAD into the report (f854c21
since #81, e280f5d since #91), so the script has refused since #81 even though the rerun's
parts are byte-identical to the live ones. The publish report proves that identity: its head
reads `wet commit 71af15a (segment table built at e280f5d)` and it says
`parts identical to the published build acb820f: 67 of 67 here, 67 published`, which
`vd_published()` (`scripts/vignette_data_lib.R:62`) already requires.

Option 1 from the issue: accept a segment report whose commit is the one the passing,
all-identical publish report was built from. That chain is: segment report (commit X) →
publish report built at X, checked value by value, every part byte-identical to the live
build → live build. A segment report rerun after the last BUILD names a newer commit than the
publish report and is still refused, now with the remedy (rerun the BUILD) in the message.
The live manifest's own `segment_commit` needs no separate acceptance: when nothing was
rerun, the publish report names that same commit.

## Phase 1: accept the segment report the identical build was cut from
- [ ] `scripts/vignette_data_lib.R` `vd_published()`: parse the publish report's head
      `^wet commit ([0-9a-f]+) \(segment table built at ([0-9a-f]+)\);`, require exactly one
      match, return it as `segment_commit`; update the function's header comment
- [ ] `data-raw/segment_vignette_data.R:170`: replace the `stopifnot()` on the live manifest's
      commit with a `stop()` requiring the segment report to name `pb$segment_commit`, whose
      message names both commits and says to rerun `scripts/discharge_publish.R` (BUILD);
      update the comments above it and at the top of the file
- [ ] provenance: add `segment_report_commit = pb$segment_commit` (the segment table the
      counts came from) beside `published$segment_commit` (the one the live manifest names)
- [ ] `tests/testthat/test-vignette_data.R`: `segment_report_commit` in the required
      provenance fields, matching `^[0-9a-f]{7,40}$`
- [ ] `vignettes/segment-discharge.Rmd` provenance chunk comment: name the counts' segment
      table (`prov$segment_report_commit`)

- [x] Plan review (Gap): the report's head names only a commit, so compare the whole report with its copy at
      the publish build's commit (`vd_segment_report()` in `scripts/vignette_data_lib.R`; `vd_published()`
      also returns `build_commit`)

## Phase 2: regenerate the vignette data
- [ ] Commit Phase 1 (clean tree for `vd_commit()`), then on m1:
      `WET_FWAPG_COMMIT=341b078 Rscript data-raw/segment_vignette_data.R` — writes
      `inst/vignette-data/segment_values.rds`
- [ ] Diff old vs new bundle: `skill` and `segments` identical, provenance differs only in
      `built`, `wet_commit`, and the new `segment_report_commit`
- [x] Prove the guard still fires: a copy of the segment report naming another commit
      (in a scratch copy of the tree, not the working tree) is refused
- [ ] `monthly_vignette_data.R` and `segment_vignette_map.R` unaffected (they don't read the
      segment report); `devtools::test()` passes; vignette renders

## Phase 3: docs
- [x] `CLAUDE.md` segment-vignette paragraph and `research/discharge_publish.md:78`: the
      segment report must be the one the passing, all-identical publish report was built from
- [ ] Update the m4 publish-state memory (no longer refuses after an identical rerun)

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
