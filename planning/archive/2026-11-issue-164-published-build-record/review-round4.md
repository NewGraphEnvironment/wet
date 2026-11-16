# Code-check round 4: b78dc41 (segment_group.R published mode checks scoring code against the build's commit)

## Checklist read

- code-check.md, `## Mechanisms`: I read the prose of these H3s (not the `|` rows): A guard that fails toward pass; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; Restore the bug and prove the guard fires; One fact derived twice; Zero-length, empty, and unset are three different things.
- code-check-r.md: `system2(stdout = TRUE)` warns on a non-zero exit instead of raising; `$` on a list partial-matches; `tryCatch()` nests its handlers (to rule it out: none here); `deparse(body(f))` excludes formal defaults (to rule out the parse/eval pattern: the code evaluates the whole assignment, so defaults are kept).
- code-check-shell.md: Git plumbing calls whose default answers a different question; A fetch can fail and still deliver the commit, so when you need an object, test the object; `git diff a..b` compares TIPS. I found no heading on short SHAs as such.

## What I read and probed

- I read the diff, scripts/segment_group.R lines 1-200 and 530-575, scripts/wb_score_md5.R, the helpers in scripts/wb_fit_lib.R, the provenance and manifest write in R/wet_catalog.R, and scripts/discharge_publish.R lines 57-100, 225-250 and 440-505.
- The chain of trust holds:
  - BUILD refuses a dirty `R`/`scripts` (line 63).
  - It records HEAD's short sha as provenance `wet_commit` (lines 66 and 490).
  - It recomputes `score_code_md5` at that commit and holds `fits.rds` and `aet_winner.txt` to it (lines 236-240).
  - It copies that same `fits.rds` into `fit/` (line 450).
  - PUBLISH uploads the BUILD's manifest unchanged and refuses if `R`/`scripts` moved since `built_at` (line 79).
  - So the scoring files at the manifest's `wet_commit` are the files the published fit's `code_md5` was checked against.
- `wb_score_md5.R` is in its own file list, so the list taken from the current checkout equals the build commit's whenever the diff passes. The `wb_stations_path` stub shadows the global one, and the closure's parent chain reaches base for `file.exists`, `c` and `stop`.
- `system2(..., stderr = FALSE)` returns `0L` for a present commit and `128L` for an absent one (probed). Under `/bin/sh`, `^{commit}` passes through unquoted.
- I ran the list derivation and the diff read-only against three commits:
  - `a0318b7`: 0 files differ.
  - `797a5d4`: 0 files differ.
  - `HEAD~40`: 6 files differ.
  - So the guard can fire.
- Nothing later in segment_group.R reads `score_files`, `aet_code_md5` or `fit_decisions`, so moving the `source()` into the default branch leaves no undefined name in published mode.
- A malformed `wet_commit` fails toward refusal: NULL, NA, length > 1 (the `||` errors), and an ambiguous short sha (git exits non-zero) each stop the run.

## Findings

- **[severity: fragile]** scripts/segment_group.R:128 — The check uses `git diff --name-only <commit> -- <files>`, which compares the commit with the working tree through the index. The index honours the `assume-unchanged` and `skip-worktree` flags. A scoring file edited after either flag was set is therefore invisible to this check, and also to the dirty check at line 83 (`git status`). Published mode would then build under changed scoring code while reporting the build's `score_code_md5`.
  - The property the BUILD checked is file content (`tools::md5sum`), so here the proxy (the index's view) differs from the property.
  - Reproduced in a scratch repo: after `git update-index --assume-unchanged f` and an edit to `f`, both `git diff --name-only <c> -- f` and `git status --porcelain` print nothing. Once the flag is cleared, the diff lists `f`.
  - It needs a deliberately set index flag. `git ls-files -v R scripts` shows none in this checkout today, so it cannot fire here now.
  - Sparse checkout's `skip-worktree` removes the file instead, and `score_files_for()`'s `file.exists()` refuses that case.
  - A fix that reads content directly: for each file, compare `git rev-parse <commit>:<f>` with `git hash-object <f>`. Or compare `tools::md5sum(f)` with the md5 of `git show <commit>:<f>` written to a tempfile, which mirrors exactly what the BUILD hashed.
  - **Rule:** code-check.md "A proxy is not the property" (and code-check-shell.md "Git plumbing calls whose default answers a different question")

Apart from that, I found nothing that could cause a failure, a security problem or data loss.
