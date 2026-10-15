# Code-check round 4 (#81): closing enumeration of the AET decision lifecycle

Reviewed: branch diff against main (scripts, CLAUDE.md, research), with every changed script read
in full, plus the scripts that read `aet_winner.txt` / `fits.rds` (`wb_fit_accept.R`,
`wb_share_snow.R`, `wb_map.R`, `data-raw/*vignette_data.R`). Read only; nothing was run.

## Lifecycle table

| # | state | what the code does | verdict |
|---|-------|--------------------|---------|
| 1 | shipped release, no `aet_decision.txt`, rule picks cfu | `decided_aet = "cfu"`, `to_user` FALSE, winner `cfu` + `score_code_md5` written; `wb_validate.R` ships cfu | OK |
| 2 | shipped release, no decision, rule picks X != cfu | `to_user`; winner file unlinked at line 41 and not rewritten; `wb_validate.R` without a current winner ships nothing; old `fits.rds` is stale (whatever moved the rule also moved `score_code_md5`), so `wb_output.R` refuses it. If the user says "switch": record X, rescore, compare, ships X. **If the user says "keep cfu": no way to record it** (finding 1) | nothing ships silently; one answer is unrecordable |
| 3 | decision X, rule picks X | winner X written; `wb_validate.R X` ships; `wb_output.R`/`segment_output.R` accept; `discharge_publish.R` stops (manifest says cfu, #83) | OK |
| 4 | decision X, rule picks cfu | `winner != decided_aet` -> DECISION TO USER. Deleting the file ships cfu; "keep X" cannot be recorded (same gap as finding 1) | nothing ships silently |
| 5 | decision X, rule picks Y | DECISION TO USER; recording Y ships Y | OK |
| 6 | new release, shipped has no decision | decided cfu; same as 1/2 on the new fit | OK |
| 7 | new release, shipped has X, new fit has none | comparison stops before scoring. **But it stops before line 41's unlink, so a winner already in the new fit (e.g. cfu from a comparison run before the shipped fit recorded X) survives, still matching the new fit's `score_code_md5`, and `wb_validate.R` on the new release ships it** (finding 2). `wb_fit_accept.R:47` would catch the AET mismatch, but that script cannot currently run (#83), and once `wb_shipped_release` is bumped the guard no longer compares against the old fit at all | guarded only on the path through the comparison |
| 8 | new release, new fit has its own record | any value allowed (as designed); behaves as 3-5 on the new fit. `wb_fit_accept.R:47` then refuses a fit whose AET differs from the old fit's, so a switch made at a new release can never pass acceptance as written (fails closed; #83 territory) | OK (fails closed) |
| 9 | winner ships raw under a fixed pooled variant | `winner_raw` -> DECISION TO USER, no winner file; `wb_validate.R:115` would also stop. Recording `aet_decision.txt` cannot resolve it (only `pooled_variant.txt`/override can), though `wb_validate.R:50-51`'s message points the user there | nothing ships; message misdirects in this case only |
| 10 | `aet_decision.txt` deleted after shipping | `score_code_md5` changes: `fits.rds`, winner and every `cv_aet-*.rds` go stale; `wb_output.R`/`segment_output.R`/`discharge_publish.R`/`pcic_routed_lib.R` refuse; comparison demands a rescore. After rescoring, rule X -> DECISION TO USER; rule cfu -> cfu ships (cfu is #15's registered default, so not an undecided AET; the comment at `wb_aet_compare.R:179-180` "deleting it sends the choice back to the user" holds only when the rule still picks X) | OK |
| 11 | downstream after each | `wb_output.R` and `segment_output.R` require `fits$aet == winner[1]` and `winner[2] == score_code_md5`; `pcic_routed_lib.R` the same plus `cv$code_md5`; `discharge_publish.R` additionally refuses non-cfu; `wb_share_snow.R` takes `winner[1]` without the md5 but checks the cv file's md5; vignette data reads the published build, which only `discharge_publish.R` makes | OK |

## Findings

- **[severity: bug]** scripts/wb_aet_compare.R:31,185 and scripts/wb_cv_lib.R:104-113 — the user's
  decision can only ratify the rule's pick, never override it. After a DECISION TO USER in state 2
  (rule picks X, decided cfu), the issue's premise is that the user decides whether to switch. If
  the answer is "keep cfu", writing `cfu` into `aet_decision.txt` (which line 111 accepts) leaves
  `decided_aet = "cfu"`, `winner = X`, so `to_user` stays TRUE on every rerun, and no winner file is
  ever written. The previous `fits.rds` is stale under the new `score_code_md5` (the change that
  moved the rule moved the md5, and the new decision file moves it again), so `wb_output.R` refuses
  it and nothing ships at the shipped release until the rule itself changes. State 4 ("keep X" when
  the rule now picks cfu) is the same deadlock. CLAUDE.md documents only "a switch the user takes".
  Nothing ships wrongly, but the workflow has no recordable path for one of the two answers the
  DECISION TO USER asks for. A fix: when `aet_decision` exists, write the winner file for
  `aet_decision[1]` (the user's decision, stated in the report beside the rule's pick) rather than
  requiring `winner == decided_aet`; keep the `winner_raw` check against the decided AET's
  `keep_adjust`.

- **[severity: fragile]** scripts/wb_aet_compare.R:36-41 — the round-3 guard (shipped fit records a
  switch, this fit has none) `stop()`s before line 41 unlinks `aet_winner.txt`, so a refused
  comparison leaves an earlier winner in place. A new-release fit compared before the shipped fit
  recorded its switch keeps a `cfu` winner whose md5 is still current (the new fit's
  `score_code_md5` hashes only its own decision files, not the shipped fit's), and
  `wb_validate.R` (which has no such guard) then ships cfu on that release; `wb_output.R` accepts
  it. The only later barrier is `wb_fit_accept.R:47`'s AET-equality check, which cannot run today
  (#83), and after `wb_shipped_release` is bumped the guard stops comparing against the previous
  fit at all. Move the unlink above the guard (and above the `missing_cv` stop at line 29, for the
  same reason), so the comment at line 40 ("a winner is only ever the result of a complete
  comparison under this code") holds on every exit; or apply the same check where
  `wb_validate.R` reads `ship_aet`.

No defect found in the rest of the round-3 fix: the `discharge_publish.R:194` cfu guard sits after
the md5 checks and cannot be reached with a non-cfu fit silently; the `wb_upstream_identity.R`
comment change is text only.

/Users/airvine/Projects/repo/wet/planning/active/review-round4.md
