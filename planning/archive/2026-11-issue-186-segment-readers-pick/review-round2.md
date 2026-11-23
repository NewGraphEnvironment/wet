## Checklist read
code-check.md Mechanisms: "A guard that fails toward pass", "A guard's scope, escape hatches, and remedies", "Verification that reads its own output", "Restore the bug and prove the guard fires"; code-check-shell.md git pathspec excludes (long form).

## Findings

1. Low, test only (Restore the bug and prove the guard fires). tests/testthat/test-publish_own.R "assign none of their own" greps `^publish_own <-` per script. A daily script that reassigns after the source() with `publish_own = c(...)`, an indented `publish_own <- setdiff(...)`, or `assign()` passes every assertion, and the daily guard's exclusions would then differ from the BUILD's. The `own <- c(...)` literal check also would not notice `own` being reassigned before the diff call. Suggest `^\s*publish_own\s*(<-|=)` or `grepl("publish_own\\s*(<-|=)|assign\\(")` over all non-comment lines, and `sum(grepl("^\\s*own\\s*(<-|=)", lines)) == 1`. No present defect: both scripts currently only source the list.

Probed and found sound:
- Entry vs inputs: every `wet_*` function called by segment_output.R, wb_output.R and segment_daily_output.R (wet_doy_*, wet_month_days, wet_routed_*, wet_shape_*, wet_share_predict, wet_source_pick, wet_wb_adjust/raw, wet_hydat_connect, wet_station_snap) lives in an R/ file not on the list (wet_station_snap and the wet_segment_sources route via R/wet_segment_monthly.R are the accepted decisions). The R/ entries (wet_catalog, wet_db_load, wet_values_compare, wet_segment_daily, wet_departure_carry, wet_pcic_years) are not called by the three table scripts, wb_fit_lib.R or pcic_routed_lib.R (routed_years_dir/wet_pcic_years is not used by segment_output.R, wb_output.R or segment_daily_output.R). The scripts entries are sourced by none of them.
- Spelling: all 20 entries are tracked paths (`git ls-files --error-unmatch` clean); long-form `:(exclude)` is used; a missing path would not fail the pathspec anyway.
- Ordering/cwd: source("scripts/discharge_publish_own.R") precedes both uses in discharge_publish.R (line 222 vs 228, 262) and in segment_daily_output.R (81 vs 83); both already rely on repo-root cwd (source("scripts/wb_score_md5.R"), git pathspecs).
- Daily script stays visible to the BUILD's daily check (publish_own lacks it; daily_own is only in the monthly check), and is in the daily script's own list, as intended.
