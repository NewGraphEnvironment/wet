# Review p5, round 3

Scope: the working-tree diff of scripts/wb_{aet_compare,cv_lib,output,validate}.R plus the new
scripts/wb_score_md5.R. Read only; nothing under data/wb touched, no wb_*.R run.

## Enumeration

Derived by grepping scripts/ for md5, file.exists, readRDS, readLines, `_complete` and unlink.

| Stored stamp / marker | Gates | Compared against | Can a stale value pass? |
|---|---|---|---|
| `cv_aet-<v>.rds$code_md5` (wb_aet_compare.R:28) | the comparison reusing a variant's scores | current `score_code_md5` (recomputed from the files) | No |
| `cv_aet-<v>.rds$station_number` (:27) | same | current `cal$station_number` | No (and stations.rds is also inside the md5) |
| `aet_winner.txt` line 2 (wb_validate.R) | which variant writes fits.rds | current `score_code_md5` | Only through the decision rule: `scripts/wb_aet_compare.R` is not in `score_files`, so an edit to the rule (`decide()`, `eligible`, the nested pass test) leaves the old winner valid. See F3 |
| `aet_winner.txt` line 2 (wb_output.R:34) | shipping | current `score_code_md5` | Same caveat as above |
| `aet_winner.txt` line 1 vs `fits$aet` (wb_output.R:35) | shipping | another stored value, but both sides are pinned to the current md5 by :28 and :34 | No |
| no winner file, so cgiar (wb_output.R:38) | shipping | `fits$code_md5` == current (:28) | No. The compare unlinks the winner at start, so an aborted compare leaves a non-cgiar fits refused (fails closed) |
| `fits.rds$code_md5` (wb_output.R:28) | shipping | current `score_code_md5` | No |
| `fits.rds` read by wb_map.R:15 | the map's calibration points | nothing | Yes. See F2 |
| `runoff_annual.tif` (wb_map.R:14) | the tracked map PNG | existence only | Yes. wb_output now unlinks it before its guard, but wb_validate.R rewrites fits.rds without touching it. See F2 |
| `output/<CODE>.parquet` (the deliverable) | downstream use | nothing; not unlinked before the guard | Yes, once the writer is restored. See F1 |
| `upstream/_complete` (wb_cv_lib.R:9, wb_output.R:16, wb_map.R:12) | picking the run dir | existence; written only when every current basin code has an rds (wb_province.R:237) | No, within a key |
| province run key (wb_province.R:54) | reuse of in_bc.tif, layers.tif, sample/*.rds, upstream/*.rds | current input basenames and the md5 of the current code_files | Partly. `wet_upstream_irregular()` lives in R/wet_upstream_pairs.R, which is not in `code_files`, so an edit there reuses stale upstream/*.rds. This predates #15; see Note |
| input basenames in the key (tc_19812010_<key>.tif etc.) | same | a content key built with a hand-bumped method constant (`wet_terraclimate_method`) | Only if a constant is not bumped. 4a9b82b did bump it (`-1` to `-2`), so the CRS fix changed the key |
| layers.tif, in_bc.tif, sample/*.rds | reuse inside a key | existence; each is written tmp-then-rename | No partial file. in_bc depends on the fwa_bcboundary table, which is not keyed (acceptable) |

Sourcing wb_score_md5.R from wb_output.R works. `wet_md5_text()` is internal (R/wet_climr_normals.R,
not in NAMESPACE), but wb_output.R:13 calls `devtools::load_all()`, whose default `export_all = TRUE`
puts it in scope. Every path in `score_files` is relative to the repo root, which every wb_*.R script
already assumes (`data/wb`). The script lists itself. Nothing is written before the guard: the only
action before it is the tif unlink.

## Findings

### F1 (real, blocker): the diff deleted wb_output.R's entire output section, so it writes no parquet and crashes after the tif

The hunk that inserted the guard replaced HEAD lines 22 to about 88 (`git diff --stat`: +17 / −65).
Those lines were not the old guard. They were:

- `dir.create(output)` and `days`
- the whole per-basin loop that writes `output/<CODE>.parquet` and builds `tally`
- the HYDAT and fwapg block that builds `g` (the major-river mouths against HYDAT)

What remains still references `tally` (lines 67 to 72) and `g` (lines 77 to 78), which are now defined
nowhere (grep confirms). A run of the current file therefore:

1. passes the guard;
2. writes `runoff_annual.tif` (line 58);
3. stops at line 67 with `object 'tally' not found`.

It writes no parquet, which is the pipeline's deliverable per CLAUDE.md, and no report. Under
run15c.sh's `set -e` the runner stops before wb_map. Run by hand, wb_map would map a tif whose
wb_output "failed". There is no `output/` directory in data/wb/495b33ec47 yet, so nothing stale ships
today. The in-flight run will fail at this step if it reaches wb_output.R.

Fix: restore HEAD's lines 22 to about 88 (from `dir.create(file.path(key_dir, "output"), ...)` through
`g$bc_fraction <- ...`) after the guard block. Then also `unlink(file.path(key_dir, "output"),
recursive = TRUE)` next to the tif unlink. Otherwise a refused run leaves the previous accepted fit's
parquets as the deliverable: the same mechanism as round 2's finding 3, on the other output.

### F2 (real, stale output): wb_map.R still needs a tie to fits.rds; the tif unlink alone does not cover the case where wb_validate.R rewrites fits

The unlink at the top of wb_output.R covers "wb_output refused". It does not cover "fits.rds changed
and wb_output did not run": wb_validate.R <winner> rewrites fits.rds, then a runner stops or wb_map is
run by hand. wb_map then maps the old tif (the previous fit) with the new fit's `$calibration` points,
and overwrites the tracked research PNG. It checks only that the tif exists.

Cheapest fix, at the single writer: wb_validate.R unlinks `runoff_annual.tif` (and `output/`) in the
same branch where it `saveRDS`es fits.rds. Then a tif exists only if wb_output ran after the last fit.
Alternatively, wb_map could refuse when `file.mtime(tif) < file.mtime(fits.rds)`.

### F3 (real, narrow; round 2 called it a note): the winner's md5 does not cover the decision rule

`score_files` omits scripts/wb_aet_compare.R. The winner's line 2 is compared with the current state,
but "current state" excludes the file that produced line 1. An edit to `decide()`, `eligible` or the
nested-selection pass test, without rerunning the compare, keeps the old winner valid in both
wb_validate.R and wb_output.R, and ships it. This is the r2 mechanism (a stamp that covers less than
the value depends on).

Fix: the compare writes a third line, `md5(scripts/wb_aet_compare.R)`, and wb_validate.R and
wb_output.R check it against the current file. Adding the file to `score_files` would instead
invalidate every cv_aet-*.rds on a rule edit, which is more rescoring than the change needs.
wb_validate.R's `length(w) != 2` check would need updating either way.

## Note (predates #15)

wb_province.R's `code_files` lacks R/wet_upstream_pairs.R (`wet_upstream_irregular()`, called during
accumulation). An edit there reuses stale upstream/*.rds under the same key. It is outside this diff.
It is worth one line in `code_files`, or an issue.

## Verdict

F1 is a blocker introduced by this diff: it looks like an Edit whose old_string spanned the output
section. The guard logic itself is sound. Every shipping gate now compares against the recomputed
current md5, the only stored-to-stored comparison (winner line 1 against `fits$aet`) is pinned on
both sides, and no path deadlocks. The remaining gaps are F2 (the map's input is not tied to the fit)
and F3 (the decision rule is outside the stamp).
