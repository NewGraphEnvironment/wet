# Plan review — #43 (Plan agent, 2026-10-06)

Returned as reply text (Plan agents cannot write files); recorded here with dispositions.

## Blocker
1. Byte-for-byte proof impossible: code_md5 and stations-file content change by design. [Proof restated: identical() on annual objects, all.equal 1e-12 on monthly-share metrics (findings).]
2. pooled_variant.txt not hashed, so a stale fit ships silently. [Hashed into score_code_md5 when present; fits.rds records pooled_variant.]
3. Fixing "other" fails the headwater gate (42.3 vs 31.6) and undoes the AET carry. [Amendment 6: wb_validate stops; decision to user.]

## Gap
4. No script for acceptance. [scripts/wb_fit_accept.R.]
5. Acceptance metric underspecified (obs < 10 mm NA; own-release obs; nesting only after rerun). [Amendment 8.]
6. Gate flip not covered by acceptance. [Amendment 9.]
7. Test obs > 0 vs headline 10 mm floor. [Amendment 2: >= 10 mm.]
8. Distributary/overflow channels in test pool. [Amendment 2: name screen.]
9. Unseen zones crash wet_wb_adjust. [Dropped per fit, as wb_output.]
10. Silent losses in with_predictors. [Counts at each filter in the report.]
11. Stations file without test must fail. [stop() on null or empty.]
12. Carry check: record carried fit's md5. [Third line of aet_winner.txt.]
13. wb_map can overwrite the published map. [Refuses unless the shipped release.]

## Ordering
14. Closing wb_validate cfu missing from Phase 3. [Added.]
15. Rerun validate after pooled_variant.txt. [Added to Phase 4.]
16. A fixed variant breaks #15 reproduction. [Amendment 7: wb_aet_compare refuses a fixed-variant fit.]
17. Separate code-only and rebuild proofs. [Phase 3 split.]

## Assumption
18. Determinism: lm.fit/folds deterministic; BLAS may differ. [Measured: 6e-14 in monthly NSE only.]
19. Orphans at key root after Phase 3. [Move to _pre43/ after verification.]
20. Pooling can shift on the new release (zone 05 has 7, 07/10 have 8). [Validate report prints the pooled set per fit.]

## Independence
21-22. Test gauges share sub-sub-drainages and twins with calibration gauges; leak favours "other". [Amendment 1: sub-sub-drainage hold-out.]

## Noise
23-25. Short records noisy; 1-point band over all gauges dilutes to a tie; caveat overclaimed. [Amendments 3-5: decision gauges, minimum 10, bootstrap context, caveat retired only if informative.]

## Scope
26. Station-flow scripts share the silent HYDAT default. [File an issue.]
27. Which report name is canonical after the switch. [Phase 5.]
28. m1 bundle must match the new layout. [Phase 5.]

## Acceptance
29. findings.md issue context contradicts the plan. [Marked superseded.]
30. Amendments must be dated before scoring. [Dated 2026-10-06; nothing scored.]
31. wb_stations comment wrong about `[`. [Fixed.]
