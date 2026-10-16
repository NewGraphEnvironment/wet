# Plan review (#89), Plan agent, 2026-10-16 16:20 UTC

Findings as delivered (reply text; the agent cannot write files), condensed:

- **Acceptance:** under the new rule the real report changes in substance, not only stamps: the stage 1 heading, the (d) line (against cfu 30.7, not cgiar 37.4), the fold counts and the two-stage line. The real case will likely print "(d) ... fail" with WINNER cfu, as stage 2 already does.
- **Gap:** (d) against cfu's as-shipped 30.7 % is stricter than against cgiar: cfu's score is post-selection (pooled variant and override decided on cfu's fit; its own nested score is 32.5 %). Disclose in the rule text and research, as #18 did for stage 2.
- **Gap:** the #81 subsection's numbers (31.5 % vs cgiar 37.4 %, folds 68/26) come from a report a later rescore rewrites; mark them as made under cgiar as incumbent.
- **Gap:** the re-stamp check compares with a copy wb_validate.R overwrites in place; check against the main checkout's copy, with code_md5 equal to the sandbox stamp, and before any winner file exists.
- **Gap:** the harness re-stamps without checking that the source scores are current; assert all ten source code_md5 agree with aet_winner.txt line 2.
- **Acceptance:** run `real` under old code; the report must equal the tracked one byte for byte.
- **Assumption:** k-scaling holds for (a)-(c) only; the nested selection refits on raw (floors at 0, unscaled gate tolerance). fu25's (d) likely ~29.9 vs 30.7, not certain. (b)/(c) are never binding for a synthetic fu.
- **Ordering:** pre-declare a fallback (fu40) if fu25's (d) fails.
- **Ordering:** wet-89old has no harness (copied there as sandbox_89.R; already handled).
- **Assumption:** unlink("data/wb") over symlinks believed safe (lstat); confirm on main's upstream.
- **Cosmetic:** synthetic fu shows adjusted*, raw_head/raw_all unscaled, G_aet is the real fu AET.
- **Scope:** merging stales every stamp until the rescore; wb_output.R, segment_output.R, discharge_publish.R, pcic_routed_lib.R (so both vignette data scripts) and wb_share_snow.R refuse until then.

## Disposition

| finding | action |
|---|---|
| real report changes in substance | accepted: findings, research and PR say so |
| (d) stricter against post-selection cfu | accepted: disclosed in rule text and research |
| #81 numbers drift | accepted: marked as under cgiar as incumbent |
| re-stamp check vacuity | verified separately: rerun with mtime stamp and report diff |
| source currency | accepted: asserted on m4 |
| old-code real reproduction | accepted: run after the chain |
| fu40 fallback | pre-declared in findings before results |
| unlink over symlinks | checked 16:19 UTC after two harness re-runs: main upstream 25 entries, _complete present |
| scope gap | PR body lists the refusing scripts; rescore stays owed per the issue |
