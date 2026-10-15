# Code-check round 5 (#81): lifecycle states of the AET decision

Scope: branch 81-retire-fit-20251014-as-a-gate-re-decide at 23c94e1, read in full: wb_aet_compare.R,
wb_validate.R, wb_cv_lib.R, wb_score_md5.R, wb_output.R, wb_fit_lib.R, wb_pooled_test.R, segment_output.R,
discharge_publish.R, pcic_routed_lib.R, wb_fit_accept.R, wb_upstream_identity.R. Checked by reading only; the data
is not on this machine.

## Lifecycle table

| # | State | What the code does | Verdict |
|---|---|---|---|
| 1 | Shipped release, no aet_decision, rule picks cfu | `ship = cfu`, `to_user` FALSE unless `ship_raw`; writes `cfu, score_code_md5`; wb_validate (no arg) writes fits.rds cfu | OK |
| 2 | Shipped release, no aet_decision, rule picks X != cfu | `to_user` TRUE; the winner was unlinked at line 29, so none exists. wb_validate with no arg stops (ship_aet NA); `wb_validate.R X` scores X but `X %in% NA` is FALSE, so no fits.rds. wb_output / segment_output / discharge_publish / pcic_routed_lib all need aet_winner.txt and stop (readLines error or explicit stop). An earlier fits.rds can stay current by md5, but every consumer also needs the winner | OK |
| 3 | aet_decision X, rule picks X | Ships X. The report reads "SHIPS: X, the user's decision ...; the rule chose X" | OK |
| 4 | aet_decision X, rule picks cfu | Ships X, and the report shows both (round 4 design) | OK |
| 5 | aet_decision X, rule picks Y | Ships X, and the report shows both | OK |
| 6 | New release, shipped fit has no decision | The guard passes, then as in 1 and 2 | OK |
| 7 | New release, shipped fit has X, new fit has none | wb_cv_lib.R stops wb_validate, wb_aet_compare and wb_pooled_test. The stop comes before wb_aet_compare's unlink, so a winner the new fit already had survives. wb_output (which does not source wb_cv_lib) still accepts it for the new release, but segment_output and discharge_publish refuse a release that is not shipped. After the bump, it is the accepted round-4 gap, and wb_fit_accept.R:47 (same-AET stop) is the barrier | OK before the bump; accepted gap after it |
| 8 | New release, new fit has its own record | Allowed by design. wb_fit_accept.R:47 then stops on differing AETs (#83, known) | OK (known #83) |
| 9 | Winner would ship raw under a fixed variant | `ship_raw` is checked for `ship` (the decision or the winner): to_user, no winner. wb_validate.R:116 refuses the same case for ship_aet. The two agree because both use keep_adjust_for() and the same stored keep_adjust | OK |
| 10 | aet_decision deleted after shipping | score_code_md5 changes, so fits.rds, the winner and the cv files are all stale. wb_output, segment_output, discharge_publish and pcic_routed_lib refuse. A rescore returns to the default: cfu ships only if the rule picks it, and otherwise to_user | OK as designed, but see finding 1 for the case where the deletion is accidental |
| 11 | Downstream scripts | All four check `fits$code_md5` and `winner[1:2] == c(fits$aet, score_code_md5)`. discharge_publish additionally stops on aet != cfu (#83). pcic_routed_lib reads `cv_aet-<fits$aet>`, which is right for any AET. Not in the list but observed: wb_term_diagnose.R:116 and wb_gauge_diversion.R:241 hard-code cv_aet-cfu while calling it "the shipped fit". Their reports label it cfu explicitly and ship nothing, so this is not a finding | OK |

I reviewed the round-3 fix code (the wb_cv_lib.R carry guard, the discharge_publish cfu stop and the
wb_upstream_identity comment) and found no defect in what it does on the path it covers. The round-4 fix code
(aet_decision ships whatever the rule picks; the unlink before the early stops in compare; the validate message) is
also correct on its own path.

## Findings

- **[severity: fragile]** scripts/wb_cv_lib.R:114-122 (together with the key move that wb_upstream_identity.R
  describes): the record of the user's decision is guarded only across HYDAT releases under the same province key.
  It is not guarded when the province run moves to a new key, or when the shipped fit's directory does not exist yet
  under the current key (`file.exists(f_ref_decision)` is then FALSE and the guard passes).

  This is a hand-carry operation the repo already does: #16 moved the fits and their decision files to a new key by
  hand. If aet_decision.txt is left behind in that move, the copied fits.rds, winner and cv files fail their md5
  check. Every error message then points to "rerun scripts/wb_validate.R ... and scripts/wb_aet_compare.R", none of
  them to the missing decision. The rescore, now with no decision, follows the default:
  - In state 4 (the user decided X != cfu and the rule picks cfu), it writes `cfu` and the report says "SHIPS: cfu,
    the rule's winner and #15's AET". The user's decision is dropped and nothing says one existed. That is exactly
    the silent fallback the round-3 guard was written to prevent, reached by another route.
  - In states 3 and 5 it goes to the user, which is safe.

  Today's impact is bounded: discharge_publish.R refuses any AET other than cfu, so X was never published, and the
  live product stays cfu. That bound lasts only until #83 lifts the cfu guard.

  Cheap fix: record the decision in what the fit writes (for example `aet_decision = aet_decision[1]` or NA in
  fits.rds and the cv files). wb_cv_lib.R would then refuse when the fit's existing fits.rds records a decision and
  the directory has none, with a message saying to copy the file or remove fits.rds to return to the default
  deliberately. Validate rewrites fits.rds only after wb_cv_lib.R has run, so the check fires first. Alternatively,
  make the key move refuse when the old key's shipped fit has aet_decision.txt and the new one does not (the file
  wb_upstream_identity.R already compares the two keys in).

No other defects found. In state 7, a winner surviving the wb_cv_lib-level stop is the accepted round-4 gap (bump),
not a new one.
