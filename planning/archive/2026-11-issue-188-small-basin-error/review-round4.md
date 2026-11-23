## Checklist read

- code-check.md, `## Mechanisms`: prose read, `|` rows skipped, for "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output" and "A guard's scope, escape hatches, and remedies". "A fix lands in one of two callers that share a harness" was read in part. The other eight Mechanisms H3s were taken from the index line only. Not read: everything under Rules that stand alone, Security, and Spreadsheets and PDFs, about 24 headings.
- code-check-r.md, read in full:
  - "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"
  - "`deparse(body(f))` excludes formal defaults, so a body scan cannot see a default"
  - "`deparse()` re-encodes non-ASCII, so it answers about itself rather than the file"
  - "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"
  - "`tempfile()` lives in the session tempdir, so a path printed in an error names a file R is about to delete"
  - "Copy a live SQLite database with its `-wal`" (for its mtime point)

  Used from the index: "Rscript reads a script as it runs, so never edit a script while a run of it is in flight". About 133 not read.
- code-check-shell.md, read in full: "Git plumbing calls whose default answers a different question". About 110 not read.
- code-check-spatial.md: none read (the round-3 fix adds no spatial code). All not read.

Probes (read-only, under the scratchpad):
- `fn_expr()` finds exactly one top-level `verdict <-` in each file, and the two deparse identical (57 lines).
- `system2()` with git missing errors ("error in running command"). Outside a repository both calls return `character(0)` with status 128, so `term_commit` is `numeric(0)` and the script stops.
- A scratch repository (scratchpad/r4/g) shows a merge brought in an edit committed earlier on a side branch, after the cache was written: `git log -1 --format=%ct -- f` gives the side commit's date (Jan 2), which is older than a cache made at Jan 3 with the old code, though the file changed in the tree at the merge (Jan 4).
- This worktree's `data/wb_term` is a symlink to the main checkout's `data/wb_term`, and three worktrees are live (main, wet-187, wet-188). So any branch's run of #45 writes the cache this script reads.

## Enumeration

Round 3's places, at HEAD 698fbc8, plus new ones.

Inputs of scripts/wb_small_basin.R:
- WET_HYDAT_RELEASE / `release`: covered.
- province run `key_dir`: covered.
- stations file (`s$release`): covered.
- `cal` and `cal$fold`: covered.
- `cv_aet-cfu.rds` (order, obs, code_md5, the four medians): covered.
- glacier cache key without `fwa_watersheds_poly`: accepted, not raised.
- glacier SQL sum order: not raised (below printed precision).
- #45 cache, fit-derived columns (`cols_fit`, merged rows averaged): covered (f8ff320, unchanged).
- #45 cache, its row set: covered transitively.
- #45 cache, PCIC columns (`p_c`, `e_c`, `ro_c`, `bf_c`, `pet_c`): **finding 1**. They are made by the nine package files in #45's `pcic_code`, and the fix ties the cache only to the commit date of scripts/wb_term_diagnose.R.
- #45 cache, derived columns verdict() reads (`le_o`, `le_c`, `closure`, `dp`, `da`, `gap`, `w_harg`, `w_pcic`, `r_o`), and `tm$eccc`: **finding 1**. They are now tied to #45's code by mtime against commit time, which is a proxy for "made by this tree's script".
- the copied verdict() body: covered, by the parse equality (698fbc8).
- the copied rule constants `min_basins` and `omega_max` (scripts/wb_small_basin.R:118-119), free variables of verdict(): **finding 2**. The parse equality does not reach them.
- scripts/wb_small_basin_rule.R and the registered header: covered. The header text is unchanged since 9f5a0da apart from the amendment list, and 698fbc8 does not touch it.
- WET_SB_INSAMPLE: covered.

Inputs of scripts/wally_compare.R: all six covered, unchanged since round 3 (WALLY raw files accepted; zone CSV held to Table 1; cv_aet-cfu.rds held to the article bundle; monthly_values.rds; stations file; HYDAT).

Printed orders and values: all covered, unchanged since round 3 (factor-level tables, `order(-used)` with no ties, CSV order, two-digit zone sort, `again` loop order, `set.seed(188)` per `score_b()`, BLAS last bits, `wet_fwa_upstream()` C collation, glacier sum).

The round-3 fix code:
- `fn_expr()`: covered. It parses with `keep.source = FALSE`, so comments are dropped. It deparses the whole `function(...)` expression, defaults included. A missing, `=`-assigned or doubled `verdict` stops the script.
- `system2("git", ...)` with git not on PATH: covered (errors).
- `system2("git", ...)` outside a work tree: covered (empty output, then a stop).
- a shallow clone: covered. `git log` dates the boundary commit, which is later than the real change, so the check fails toward refusal.
- a worktree: covered (git resolves the `.git` file).
- `log.showSignature` or other extra stdout from git: covered (length is not 1, so the script stops).
- the dirty check, `git status --porcelain -- f`: **finding 1** (minor sub-case). It skips a path flagged `--skip-worktree` or `--assume-unchanged`.
- the mtime-against-commit-time comparison under a merge, a branch switch, a cache shared across worktrees, a cache copied without its mtime, or an uncommitted edit later reverted: **finding 1**.
- the guard reads scripts/wb_small_basin.R from disk, not the `verdict` the run defined: **finding 2** (minor sub-case).

Prose the branch adds, against the set and report it cites:
- research/monthly_error.md:5 (pointer sentence): covered (698fbc8 names both reports).
- research/monthly_error.md answer bullet 3 (+1.9, +14.3, +2.7, +15.6): covered. It matches wb_small_basin_20260717.txt section B.
- research/monthly_error.md "That bias comes in with the zone adjustment" (84/231, the four medians, +17.0 to +21.0; "every class" by elevation and aridity, low elevation at +10.1; 3 zones readable, 08 and 28 below): covered. It matches section A.
- research/monthly_error.md "What drives the raw contrast is unresolved" (48 basins, raw +14.8 %, "compensating", sum dP 10931 and sum dA 9219 both positive): covered. It matches section C.
- research/monthly_error.md "Catchment traits: undecided" (40.4 to 33.7, +0.2, −8.8 to +15.6, area-only +3.8 and 40.4 to 34.9): covered.
- research/wally.md answer (25 classes; routed's 23 named; "6 to 43 stations"; "up to 5 traits", which zones 15, 19, 23 and 24 have): covered. It matches the CSV and report section 4.
- research/wally.md:51, the RMSE/STEYX ratio: covered (698fbc8 names routed's 23).
- research/wally.md, the province-wide bullets (balance 87 % at 315, routed 90 % at 283, XGBoost 96 % over 480): covered. The body names each set.
- research/wally.md, "The other 202" breakdown (110 + 76 + 11 + 5 = 202; 280 + 3 + 32 = 315): covered.
- research/README.md, the wally and monthly_error rows: covered.
- data/checks/wally_compare_20260717.txt, the ratio line: covered (it names 23 classes).
- research/water_balance_method.md, the small-basins bullet: covered.
- CLAUDE.md, the wb_small_basin line: covered. It says verdict() is "held to its 21 stored zone verdicts". That is true but incomplete; it says nothing false.
- the header's amendment list: it names no amendment for 698fbc8's guard, while amendment 2 (an analogous guard) is listed. Nothing in the registered text became false, and no number changed, so this is not raised.

## Findings

- **[severity: fragile]** scripts/wb_small_basin.R:351-359. The staleness check accepts the #45 cache when its mtime is later than the committer date of the last commit to scripts/wb_term_diagnose.R. That ordering stands in for "the cache was made by the script now in this tree", and the two part in common cases. In each case below, a cache made by other code passes, and check C reads #45's derived columns (`le_o`, `le_c`, `closure`, `dp`, `da`, `gap`, `w_harg`, `w_pcic`), `r_o` and `tm$eccc` from it. Round 3's finding 1 is then open again for exactly the columns the fix was meant to tie:
  - **A merge or a branch switch.** `git log -1 -- f` dates the commit that made the change, not when the change reached this tree. Probed: an edit committed on a side branch at T1, a cache written at T2 > T1 by the old code, then the merge. The check passes on a cache made before the tree's script changed. A checkout of another branch whose last edit to the file predates the cache passes the same way.
  - **A cache shared across worktrees.** `data/wb_term` in this worktree is a symlink to the main checkout's (three worktrees live). A run of #45 from any branch, with any edit to its derivations, writes a cache newer than every other branch's last commit to the file, and every branch then accepts it.
  - **A copied cache.** CLAUDE.md has reduced bundles copied between machines rather than rebuilt. A copy that does not keep mtimes (`cp`, `scp` without `-p`, `rsync` without `-t`) stamps the copy's time, so any cache passes.
  - **An uncommitted edit, run and then reverted.** The cache is newer than the last commit and the file is clean again, so it passes, though the cache came from the edit.
  - **Index flags.** The dirty check is `git status --porcelain`, which skips a path flagged `--skip-worktree` or `--assume-unchanged`, so an edited, flagged script reads clean.
  - **Package code.** The cache's PCIC columns (`p_c`, `e_c`, `ro_c`, `bf_c`, `pet_c`) come from the nine package files #45 hashes into `pcic_key` (`R/wet_pcic_*.R`, `R/wet_ws_*.R`, `R/wet_upstream_*.R`, `R/wet_runoff_annual.R`). The check ties the cache to none of them.

  No number is wrong today: the cache (2026-11-13 09:17) was made after ed8f459 and agrees with #45's tracked report. Possible fixes:
  - Tie by content, not time. Recompute the derived columns from the cache's base and PCIC columns with #45's own lines 143-176, taken by `parse()` as `fn_expr()` takes verdict(), and require them equal to the cache's.
  - Or tie `tm$eccc` by content too: rebuild #45's `eccc_key` from the current script's md5 and the zones zip, and require `tm$eccc` equal, after #45's filter, to `eccc_climr_<key>.rds`.
  - Or have #45 stamp its cache with the md5 of its script and of its `pcic_code` files, and compare those md5s. This edits #45's script, so it forces the rerun already accepted.
  - **Rule:** code-check.md "A proxy is not the property". Also "A guard's scope, escape hatches, and remedies": "already current" and "never regenerated" are separated by regeneration status, and here the status read is a timestamp ordering. The index-flag case is code-check-shell.md "Git plumbing calls whose default answers a different question".

- **[severity: fragile]** scripts/wb_small_basin.R:118-119 and 336-346. The parse equality holds the text of verdict() to #45's, but verdict() reads two rule constants that this script copies separately: `min_basins <- 4` and `omega_max <- 5`. #45 defines them at its lines 26-27. Neither is compared.
  - **How it goes unnoticed.** An edit to #45's `omega_max` moves the commit date, forces a rerun, and the rerun writes new derived verdicts. `again` then compares this script's verdict(), still using 5, with the 21 stored zone verdicts.
  - **Why `again` cannot catch it.** `omega_max` enters only through `w_high` and `w_low` in `p_corr` and `a_corr`. Those decide a zone's verdict only when its decomposition share lands in the band, so most of the 21 can stay unchanged and `again` passes.
  - **What check C then prints.** Its "omega > 5 under both PETs" shares and its decomposition use the stale threshold. The label's "5" is also a literal in the sprintf at line 460.

  This is round 3's case 2 ("a rerun after such an edit that leaves the 21 zone verdicts unchanged while this script's copy differs"), still open for the rule's constants. A smaller instance of the same gap: `fn_expr("scripts/wb_small_basin.R")` reads the file on disk, not the `verdict` the running process defined. A run from a copy of the script, which code-check-r.md recommends for long runs, is therefore held to the tree's copy, not its own.

  Fix: take `min_basins` and `omega_max` from #45's parse as `fn_expr()` takes verdict(), by the same top-level `<-` match, and refuse unless they equal this script's. Then compare #45's verdict() expression with the in-memory function (`identical(body(verdict), body(eval(expr)))` and the same for `formals`), rather than with this file's text.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (the guard covers the function's text, not everything the copied rule reads). The disk-versus-memory part is code-check.md "A proxy is not the property".

/private/tmp/claude-501/-Users-airvine-Projects-repo-wet-188/594eb592-213b-4e77-ba50-0b61e76dd713/scratchpad/review-round4.md
