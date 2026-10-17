# Review round 1 — branch 93-segment-vignette-data-r-refuses-after-a vs main (122bdac)

## Clean

No issues found.

What was checked (each against the code, not the comments):

- `vd_segment_report()` rests on the build at `build_commit` refusing uncommitted `data/checks`. Confirmed at 71af15a: `git show 71af15a:scripts/discharge_publish.R` line 54 runs `git status --porcelain -- R scripts data/checks DESCRIPTION` before both the BUILD and PUBLISH branches. That check has been in the script since it was first added (7e738e1, #7), so every publish report's build commit holds the segment report the build read.
- The guard fails toward refusal in every degenerate case. A file missing at the build commit, an unreachable or ambiguous short sha, or git stderr merged into the output each make `vd_git()` stop or make `identical()` FALSE. If both sides are empty, the check passes, but `seg_num()`'s `length(m) == 1` then stops.
- `wb_report()` returns a root-relative path (`data/checks/...`), so `git show <sha>:<path>` resolves it as intended from the repo root. The `<sha>:<path>` argument holds no shell metacharacters, so `system2()` without `shQuote` is safe.
- The case the guard must catch: the segment report is rerun and committed (possibly alongside the publish report) without a new BUILD. The tracked report then differs from its copy at `build_commit`, so the script refuses.
- The BUILD itself checks the segment report's counts against the table (discharge_publish.R ~line 325), and the vignette script still holds the picks to the publish report's reader counts and fwapg's. So identical to the report the build read means counts the build checked against parts byte-identical to the live build.
- The new `re_seg` requirement in `vd_published()` also applies to `segment_vignette_map.R` and `monthly_vignette_data.R`. The tracked publish report has exactly one matching head line, `wet commit 71af15a (segment table built at e280f5d);`, so neither caller breaks. No other caller, test or vignette still checks the live manifest's `segment_commit` against the segment report.
- The provenance in the regenerated rds (`segment_report_commit` e280f5d, `published$segment_commit` 1718a3d) matches the publish report and the live manifest. The new test assertion matches it, and the vignette's provenance comment describes it correctly.
- The prose in CLAUDE.md and research/discharge_publish.md matches what the code does.
