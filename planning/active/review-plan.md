# Plan review (#99) — Plan agent, spawned 2026-10-20 13:35 UTC, delivered as reply text

Findings as the reviewer gave them (condensed; file:line refs are the reviewer's), with how each was folded in.

## Blockers
1. **The routed value check can never show 0 differing**: two summation orders over ~1.2 B values put a few on
   opposite sides of a 5-dp rounding boundary (discharge_publish.R:450-456, 515). Fix: compare unrounded values
   within relative 1e-12, and require rounded values equal or 1e-5 apart only where the unrounded value is within
   1e-9 of a tie; report the tie count. *Folded:* Phase 5 check rewritten so; the check also keeps unrounded days.
2. **Phase-1 "every row" reproduction will miss by a few rows**: fwapg averages in float8, routes, then casts to
   numeric (15 significant digits) before rounding half away from zero. Average raw (unclamped) days, weight
   folded Feb 28 by n28+n29, clamp, round by 15-digit emulation, count tie flips. *Folded:* probe defined that way
   (`wet_routed_round()` already emulates the cast; `wet_routed_period()` averages raw days by n_days).
3. **The vignette guard would read a daily hive line as monthly** (vignette_data_lib.R:77-81 `re_seen`). *Verified*
   (the regex has no dataset). *Folded:* the daily hive line names its dataset; `re_seen` anchored to
   segment_monthly.

## Gaps
4. **Inputs are per drainage, not per group** (output/, upstream/*.rds; 999 spans 246 groups). Loop over
   drainages, compute each watershed's days once, write (drainage, group) pieces, assemble per group.
   *Folded* into Phase 4.
5. **`wet_shape_predict()` stops on any NA predictor**; 22,041 watersheds have NA (*verified* in
   data/checks/wb_output_20260717.txt:5). Predict only where the balance has months; assert that set equals the
   complete-predictor set; assert `shape_daily.rds$method == "donor"`. *Folded.*
6. **BUILD has no guards for the daily table**; wb_output.R:32 and segment_output.R:63 do not unlink
   `segment_daily/` (*verified*). *Folded:* daily report commit + own git diff, mtime after the segment table,
   names seg_commit, one part per group, rows = 365 × segments per source; both scripts unlink `segment_daily/`.
7. **`drainage` labels for group codes** (wet_catalog.R:172; `publish_drainage_labels()` stops on a group code).
   *Folded:* group labels from fwa_watershed_groups_poly merged in; catalog docs and research updated.
8. **Reading daily parts without `groups`** would scan ~40 GB. *Folded:* `wet_segment_daily()` without `conn`
   requires `groups`; `wet_db_load()` filters parts by group before fetching.

## Ordering
9. The monthly git-diff guard (discharge_publish.R:180) would force a monthly rerun for a daily-only fix.
   *Folded:* the daily script is excluded from the seg_commit diff and has its own diff from the daily commit.
10. Commit each report before the next step (clean-tree guards). *Folded* into Phase 5's m4 sequence.
11. All R/ and scripts/ edits land before the m4 run, roxygen included. *Folded:* Phases 3 and 5 code (and
    Phase 6's script edits to vignette_data_lib.R) land before the m4 run.

## Assumptions
12. PUBLISH skip on the manifest's md5 can skip a part an interrupted publish left wrong. *Folded:* skip on a HEAD
    ETag equal to the local md5, as `wet_catalog_verify()` reads it.
13. Units: daily `runoff_mm` is mm/day, and February's days sum to 28/28.25 of the monthly mm; only `q_m3s`
    means match the months; month 0 is not the mean of the 365 days. *Folded* into the crate yaml and research.
    A rule for an unexpectedly large per-day clamp: *folded* (set below before measuring).

## Acceptance
14. Define "differs" (tolerance; February needs n_days weights). *Folded.*
15. Make the province reproduction a guard inside the daily script, and assert the routed segments in
    segment_weights match the monthly table's n12 == 12 routed segments. *Folded.*

Checked and fine (reviewer): part regex; `id*512+doy` exact; the fold stays in week 9; verify cost on ~557 parts;
largest group part under 5 GB; `publish_part_prepare()` errors on a missing `month`.
