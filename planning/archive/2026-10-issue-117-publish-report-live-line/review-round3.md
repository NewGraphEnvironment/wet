# Code-check round 3 (#117, #94): branch f4351217...2fec813

## Checklist read

- code-check.md (330,698 bytes): the prose of all 14 H3s under `## Mechanisms` (table rows skipped). None of the 21 H3s under "Rules that stand alone", Security, or Spreadsheets and PDFs read; none names a tool or shape this diff uses.
- code-check-r.md (177,187 bytes): read 10 headings in full: "Read-back shape must match write-back shape", "`on.exit()` at a script's top level never fires", "Tests that silently do not run", "testthat counts an uncaught error under `error`, not `failed`", "A `skip_if_not()` skips only its own `test_that()` block", "`$` on a list partial-matches…", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "`sort()` and `order()` collate by `LC_COLLATE`…", "`tempfile()` lives in the session tempdir…", "Rscript reads a script as it runs…", "A `pkg::` call in a test passes `devtools::test()`…", "`identical()` on two reader results tests the reader, not the file". About 115 not read.
- code-check-shell.md (124,118 bytes): read "`git diff a..b` compares TIPS…" and "git pathspec excludes: use the long form". About 95 not read.
- code-check-spatial.md (155,517 bytes): none read. The diff uses no spatial tool.

## Mechanism

Both earlier findings come from one assumption. **An artifact's identity is stated by a name that other artifacts can carry too, and each guard keeps its own copy of what that name covers.**

- Plan review: the report was tied to its tree by commit and no-FAIL. A commit names code, not inputs, so two trees built at one commit carried the same name. The fix binds by content (`tree parts md5`).
- Round 2: "which files are publish code" is a fact written down by hand in two lists, `publish_own` (discharge_publish.R) and `own` (segment_daily_output.R). They agreed only because someone kept them in step. A file added to one list (vignette_data_lib.R) still trips the other, and a file this branch edits trips any list that omits it.

The same shape has a third form in this branch: a report's *format* written in one place and parsed in another. These are the line literals: the tree line, the live-build line, and the `## Against the published tree` header.

## Enumeration: every place the mechanism reaches

Measured on the branch at 2fec813. The guard diffs were replayed with `git diff --name-only` against the reports' commits (28105a3, f99df25). Mutations ran on a copy, and the copy's files were restored and compared with `cmp`.

| # | place | what it compares | holds |
|---|---|---|---|
| 1 | discharge_publish.R:61 (BUILD and PUBLISH) | `git status` of R, scripts, data/checks, DESCRIPTION | y. After PUBLISH the report is modified, so BUILD, PUBLISH and vd_commit refuse until it is committed, which PUBLISH's closing message asks for |
| 2 | discharge_publish.R:76 PUBLISH | `git diff built_at HEAD -- R scripts`, no exclusions | y. It refuses the b4bbc50 tree, which is accepted. After the next BUILD, the report commit after PUBLISH touches only data/checks |
| 3 | discharge_publish.R:86-87 PUBLISH | segment and daily report heads, against the manifest's commits | y (unchanged) |
| 4 | discharge_publish.R:91-98 PUBLISH | HEAD's report: `wet commit <built_at> `, `tree parts md5 <tree>`, no FAIL | y. The tracked report has no tree line, so it is refused until the next BUILD (owed) |
| 5 | discharge_publish.R:211 BUILD monthly guard | `git diff 28105a3 HEAD -- R scripts` minus `publish_own` and `daily_own` | y. The replay prints nothing |
| 6 | discharge_publish.R:246 BUILD daily guard | `git diff f99df25 HEAD -- R scripts` minus `publish_own` | y. The replay prints nothing |
| 7 | discharge_publish.R:221, wb_output.R:36, segment_output.R:71, segment_daily_output.R:63, pcic_routed_lib.R:92, wb_fit_accept.R:58 | `score_code_md5`, the md5 of `score_files_for()`'s list (wb_score_md5.R:13) | y. No file this branch changed is on the list |
| 8 | discharge_publish.R:539, segment_daily_output.R:68, monthly_vignette_data.R:305 | `shape$code_md5` against `fits$code_md5` | y (unchanged) |
| 9 | segment_daily_output.R:80-82 `own` | `git diff 28105a3 HEAD` minus `own` | n. It names `scripts/vignette_data_lib.R`. Accepted: it fails safe and asks for segment_output.R |
| 10 | segment_output.R:51, pcic_routed_compare.R:27 | `git status` only; no code-diff guard | y |
| 11 | wb_province.R:52-61 | md5 of `code_files` → run key | y. None of the branch's files is on the list, so the key 92b893c4da is unchanged |
| 12 | wb_shape_daily.R:136 | md5 of `shape_files` | y. None of the branch's files is on the list |
| 13 | wb_term_diagnose.R:38 | md5 of the PCIC R files | y. None of the branch's files is on the list |
| 14 | vignette_data_lib.R:18 `vd_commit` | `git status` of R, scripts, data-raw, data/checks | y |
| 15 | vignette_data_lib.R:63-77 `vd_published` | report: live line (commit, N/N/N, live digest), `tree parts md5` = live digest, no FAIL | y. It refuses the tracked report until the next BUILD (owed). That BUILD's tree is byte-identical to the live one, so its report is accepted without a republish: both lines carry the live digest, and `build_commit` is the BUILD's commit |
| 16 | vignette_data_lib.R:101 `vd_segment_report` | segment report, against `git show <build_commit>:<it>` | y. After a PUBLISH, `build_commit` is still the BUILD's commit, and BUILD refuses a dirty data/checks |
| 17 | vignette_data_lib.R:45 `vd_routed_check` | routed report line, against the fwapg commit and fingerprint | y (unchanged) |
| 18 | tree-line format: `publish_tree_line()` (lib:30), the `sprintf` in vd_published (:76) and the BUILD writer (:710) | three spellings of one line | y. BUILD writes it through `publish_tree_line()`. The vd copy and the lib copy are each held to the test fixture's literal: mutations `pl_tree` and `vd_tree` go red |
| 19 | live-line format: `publish_live_line()` against `re_same` in vd_published | writer and parser | y. Test 3 feeds `publish_report_live()`'s output to `vd_published()`, and `vd_digest` goes red |
| 20 | header `## Against the published tree`: BUILD literal (:721), `publish_report_live()` (lib:202), test fixture | writer and parser of the report's layout | **fragile**, see the finding below. No test holds the BUILD's literal to the lib's, and the lib checks it only after the upload |
| 21 | PUBLISH pre-check (:95) against `publish_report_live()` (lib:198-199) | two copies of "this build's passing report" | y. They differ only on a duplicated tree line (`any` against `sum == 1`), which BUILD never writes |
| 22 | `wet_catalog_digest()` | sorted `<key> <md5>` lines, radix sort | y. Order-insensitive and locale-free; key and md5 are validated by `wet_catalog()` |

Readers of `data/checks/discharge_publish_<release>.txt`:
- BUILD writes it (discharge_publish.R:700-736).
- PUBLISH reads HEAD's copy (:91).
- `publish_report_live()` reads and rewrites the working copy (lib:196-210). By row 1 it equals HEAD's.
- `vd_published()` reads it (vignette_data_lib.R:69), through data-raw/segment_vignette_data.R:106, data-raw/monthly_vignette_data.R:169 and data-raw/segment_vignette_map.R:46.

Nothing else parses it. station_vignette_map.R and monthly_vignette_map.R source the lib only for `vd_connect()`. CLAUDE.md, NEWS.md and research/ cite it in prose only.

Mutation table, test-publish_report_live.R (failed / error):
- pl_verify 4/F, pl_setequal 2/F, pl_digest 2/F, pl_commit 1/F, pl_tree 2/F, pl_fail 1/F, pl_header 0/T, vd_digest 1/F, vd_tree 1/F.
- pl_nrow 0/F: the `!nrow(verified)` arm cannot fail on its own, because an empty `verified` already fails `setequal()`. It is redundant, not a defect.

## Findings

- **[severity: fragile]** scripts/discharge_publish_lib.R:202-206, with scripts/discharge_publish.R:91-98 and :721.
  - The check that the report has exactly one `## Against the published tree` header with a live-build line under it runs only in `publish_report_live()`, which is after the upload.
  - PUBLISH's pre-upload check (:95) tests the commit, the tree line and FAIL, but not the layout.
  - The layout is a literal in the BUILD writer (:721) and a second literal in the lib. No test holds the two together: the test fixture carries a third copy.
  - If they drift, PUBLISH uploads and then refuses with "rerun PUBLISH, which skips every part already live" (lib:40-42). A rerun reads the same committed report and refuses again, so that remedy cannot succeed for this refusal.
  - The result is a live tree whose tracked report never names it. Only a further BUILD (about 3.5 h) recovers it.
  - It cannot happen with today's code, because BUILD and PUBLISH must run at the same R/ and scripts/ (row 2) and the literals agree.
  - Fix: run the structural half of `publish_report_live()` on `rep_head` in the pre-upload check, for example a helper returning `h` used in both places, so a malformed report refuses before anything is written.

No bug or security issue found.
