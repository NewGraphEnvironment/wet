## Checklist read

- code-check.md, `## Mechanisms`: the prose (`|` rows skipped) of "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies", "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree, and what generators leave in it", "A wrapper's exit is not the work", "Zero-length, empty, and unset are three different things", "The probe is broken before the world is", "Written data outlives the fix" and "Serialization loses meaning silently". "One fact derived twice" was read in part. Outside Mechanisms I read "Documentation Staleness". About 36 headings were not read.
- code-check-r.md, read in full:
  - "`deparse(body(f))` excludes formal defaults, so a body scan cannot see a default"
  - "`deparse()` re-encodes non-ASCII, so it answers about itself rather than the file"
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "`identical()` on two reader results tests the reader, not the file"
  - "`tolerance` in testthat is RELATIVE, so it pins a published figure far more loosely than it looks"
  - "Rscript reads a script as it runs, so never edit a script while a run of it is in flight"
  - "`match()` treats NA as a matchable VALUE, so two unknowns join to each other"

  About 141 not read.
- code-check-shell.md: none read. This round's code runs no shell. All not read.
- code-check-spatial.md: none read. dd585ef adds no spatial code. All not read.

Probes. All ran in a detached scratch worktree of HEAD, now removed. Its `data/wb_term` held symlinks to the main checkout's caches and a copy of `diagnose_20260717.rds`. The copy is byte-identical to the original (`cmp`).

- `scratchpad/p5/enum.R` parses scripts/wb_term_diagnose.R and lists every top-level `<-` target. For the statements run45() selects, it lists their order and their free variables (codetools::findGlobals). It also lists the columns each statement reads.
- `scratchpad/p5/checkC.R` runs wb_small_basin.R lines 119-150 and 269-348 verbatim on a chosen cache. On the real cache it passes: n 48, "compensating".
- Three cache mutations were tried; see finding 1.

## Enumeration

The selected statements are listed in file order, from parse(). wb_term_diagnose.R has five top-level targets assigned twice: `b`, `ec`, `g`, `pc` and `zs`.

- **`years`, `min_basins`, `omega_max`, `out_dir`, `vars`, `pcic_run`, `hz_zip`, `pcic_code`**: covered. These are literals, or md5sum() of the nine package files, all taken from #45's current text.
- **`pcic_key`**: covered. Its free variables are pcic_code, pcic_run, vars and years, all selected. It is #45's own key.
- **`eccc_key`**: covered. Its free variables are hz_zip and years, plus the md5 of the current script. It is #45's own key.
- **`f_eccc`**: covered. Its free variables are eccc_key and out_dir. It sits at statement 57, after the derivations, but it is evaluated in the first call, which is correct.
- **`b$r_o` … `b$cf_model`** (16 targets): covered. setequal() holds the top-level `b$` targets to `derived`.
  - The base columns they read are aet_cfu, aet_fu, cv_ann, obs, p_yr and pet_yr (fit), and bf_c, e_c, p_c, pet_c and ro_c (PCIC). All are in `cols_fit` or `cols_pcic`.
  - Their only free variable is `b`, set to `t45$b`.
  - `cf_p`, `cf_model`, `w_harg` and `w_pcic` call `wet_aet_budyko()` from the load_all() search path. These columns are compared with the cache, so they are tied by content.
- **`lerr`, `omega_implied`**: covered. Their free variables are `b` (in t45) and `wet_aet_budyko`.
- **`ec` (statement 59, readRDS(f_eccc)), `ec` (statement 60, the filter), `ec$ratio`**: covered.
  - Both top-level `ec` assignments are selected, in file order, which is correct.
  - The `ec <- merge(...)` inside `if (!file.exists(f_eccc)) {}` is correctly skipped: the top-level expression is an `if`, so target() returns "", and the script refuses earlier when f_eccc is missing.
  - The result is compared with `tm$eccc` by all.equal(). verdict() reads `ec$zone`, `elev` and `ratio` from it.
- **`med`**: covered. It is the same name as the global `med` (stats::median), and the definitions are identical.
- **`verdict`**: covered. Its free variables are `ec`, `min_basins` and `omega_max` (all in t45) and `med`. It reads these columns of `d`:
  - aet_cfu, aet_mod16, elev, p_yr and ppt_tc (fit, held);
  - p_c (PCIC, held);
  - closure, da, dp, gap, le_c, le_o, w_harg and w_pcic (derived, recomputed).
- **Names a selected statement could read that the selection skips** (`conn`, `cal`, `cv`, `fit_dir`, `stamp`, `dry`, `min_cover`, `basins`, `g`, `pc`, `n_floor_*`): none is read today (findGlobals). No guard checks this, however. t45's parent is globalenv, where this script defines `b`, `med`, `cal`, `cv`, `d`, `err`, `release` and `fit_dir`. A future #45 statement that reads one of those names would silently take the small-basin script's value instead of failing. This is not raised: it does not happen today.
- **A derivation in a form other than a top-level `b$x <-`** (`b[["x"]] <-`, `b <- transform(...)`, one inside an `if` or `local`): the selection cannot see it. A column made that way stays in `t45$b` straight from the cache, untied. This is not raised: verdict() reads no such column today.
- **`tm$basins`, fit columns** (`cols_fit`, gauges per watershed): covered.
- **`tm$basins`, PCIC columns** (`p_c`, `e_c`, `ro_c`, `bf_c`, `pet_c`, `pcic_cover` against pcic_upstream_<basin>_<pcic_key>.rds): covered.
- **`tm$basins`, derived columns**: covered.
- **`tm$basins` not read by check C** (`station_name`, `linear_feature_id`, `fwapg_mm`): not read; accepted.
- **`tm$basins` row set** (which watersheds, once each): **finding 1**.
- **`tm$eccc`**: covered by content against #45's filter over the current key's file.
- **`tm$zones`**: covered as the reference for `again`. Its zone set follows the row set (finding 1).
- **`tm$release`**: covered.
- **The header**: its text is unchanged since 9f5a0da except the amendment list (diffed). wb_small_basin_rule.R and its test are unchanged since 9f5a0da.

## Findings

- **[severity: fragile]** scripts/wb_small_basin.R:303-330. Check C holds each cached row to its sources, but it never holds the cache's set of rows. Nothing derives which watersheds #45's current code keeps: #45's `basins` list, its `pcic_cover >= min_cover` filter, and its one-row-per-watershed merge. So a cache with a row missing, a row extra or a row twice passes every guard, and C's small-basin population moves with it.
  - **What was probed.** Each mutated cache was run through check C's code verbatim (`scratchpad/p5/checkC.R`); each passed:
    - one small row dropped: n 48 to 47, le_o 0.138 to 0.133;
    - the same row duplicated: n 49, le_o 0.144;
    - a cache written by a #45 whose `basins` lacks the Peace, with its zone verdicts recomputed by #45's own judge(): 164 rows, 18 stored zones, C's n 46.
  - **How it happens without anyone editing this branch.** This is round 4's shared-cache case, closed for columns but not for rows. data/wb_term is one directory shared by every worktree. Suppose a branch edits #45's `min_cover` or `basins` and reruns it. This branch then reads the new cache. This branch's eccc_key file still exists from earlier, and stage 3 is unchanged, so `tm$eccc` matches. The PCIC files are keyed on package code, not on the script. The derivations are the same. `again` compares the cache with itself.
  - **The same gap appears when** an edit to #45 is run and then reverted.
  - **Today:** none of these happened. The row set this probe derives from the upstream caches equals the cache's 192 watersheds, with no duplicates (`scratchpad/p5/rowset.R`).
  - **Fix:** add `basins` and `min_cover` to the first run45() call. Build the expected set: for each `code` in `t45$basins`, the `watershed_feature_id`s of pcic_upstream_<code>_<pcic_key>.rds that are in `cal$watershed_feature_id` and have `coverage >= t45$min_cover`. Then refuse unless `setequal(expected, b$watershed_feature_id)` and `!anyDuplicated(b$watershed_feature_id)`. This was tested by hand on the real cache: it is equal.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ("compare **per source**, or an item present in one and absent from another passes"). Each row is checked from the cache toward its sources, never from the sources back to the cache. Also code-check.md "A proxy is not the property": every present row agrees, which is not the same as "made by #45's current code".

- **[severity: fragile]** CLAUDE.md:40. The line says check C runs "#45's `verdict()`, copied and held to its 21 stored zone verdicts". Since dd585ef the code no longer copies verdict(). It evaluates it, with #45's constants, derivations and ECCC filter, from scripts/wb_term_diagnose.R by parse(), and holds the cache to the fit and #45's keyed caches. A later session reads CLAUDE.md as the description of the script, and the header's amendment 3 already says "read 'taken from #45's script'". The report line was updated in dd585ef; CLAUDE.md was not.
  - **Rule:** code-check.md "Documentation Staleness".

The amendment text (header lines 95-111) matches the code:
- Amendment 3's list (constants, derivations, ECCC filter and verdict() taken by parse(); base columns held to the fit and to the caches named for #45's current keys) is what lines 278-347 do.
- Amendment 2 (the fit's columns rebuilt as #45 builds them) still holds: `cols_fit`, gauges per watershed averaged.
- "It changes no number" holds: an earlier run of this HEAD's script (`scratchpad/sb_9.txt`) is byte-identical to data/checks/wb_small_basin_20260717.txt.
- Neither amendment claims the row set is held, so finding 1 makes no header sentence false. It does make the stale() message's "is not what … makes from this fit now" claim more than the code checks.

/private/tmp/claude-501/-Users-airvine-Projects-repo-wet-188/594eb592-213b-4e77-ba50-0b61e76dd713/scratchpad/review-round5.md
