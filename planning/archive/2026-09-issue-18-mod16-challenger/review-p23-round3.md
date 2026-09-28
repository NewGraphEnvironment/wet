# Review p23 round 3 (#18: MOD16 challenger, staged diff)

## Mechanism

All three earlier defects had the same cause. A label or sentence was written from another document (an earlier label, the plan, an earlier run) instead of from the expression or data it describes. The enumeration's "Computed from" column has the same weakness in one row. For "Disclosed" it cites `task_plan disclosures`, which checks a restatement against the document it was restated from. That row therefore could never fail, and it hides the finding below.

## Findings

- **[severity: fragile, doc in a tracked report]** scripts/wb_aet_compare.R:254 (and planning/active/task_plan.md:28-29, where it comes from). The report says "Disclosed: MOD16 is 2001-2020, the rest 1981-2010 normals". That is false for CGIAR. The Soil-Water Balance v3 AET is WorldClim-based:
  - research/runoff_prior_art.md:37 says "climatology (WorldClim-based)".
  - research/water_balance_method.md:327 gives the WorldClim periods: 1950-2000 for v1, and 1970-2000 for the v3 family.
  - Nothing in the repo puts CGIAR on 1981-2010.

  So `cgiar`, `lc` (CGIAR × ratio), the CGIAR half of `cfu` = max(CGIAR, fu), and `cmod16` = max(CGIAR, mod16) all carry a non-1981-2010 period. So do MOD16's gap cells, which take `cfu`. Only climr (P and T, so `fu`) and TerraClimate are 1981-2010. The disclosure says the period mismatch is unique to MOD16. It understates the mixing on the incumbent's side, and the incumbent's side is exactly what the comparison weighs. The task_plan's "Gap cells also mix periods (1981-2010 there, 2001-2020 elsewhere)" has the same error. This line goes into data/checks/wb_aet_compare.txt and into research §0 in Phase 4. It should say, for example, "MOD16 is 2001-2020; CGIAR is a WorldClim climatology; climr and TerraClimate are 1981-2010 normals". Confirm the exact v3 period from the figshare record before writing a year range. The enumeration's "Disclosed" row should say "not OK".

- **[severity: doc, provenance]** planning/active/findings.md:40. The smoke bullet says `ex_filled_cells.txt` "adds the MOD16 counts ...: `mod16_whole` 2,124,695 cells ...". The smoke-run code wrote three lines, full/partial/gap (review-p23-round1.md:5). It had no whole-MOD16 count. The 2,124,695 is round 1's own measurement of the smoke run's layers.tif. The italic note ("The smoke run labelled these 'full/partial/gap'") reads as a one-to-one relabelling of four counts. That smoke key (data/wb/711a9d102f) no longer exists: data/wb holds only 495b33ec47. So the number can no longer be re-derived from the file the bullet names. The fix is to attribute `mod16_whole` to the layers.tif measurement, or to take it from the full run's file once that exists.

## Enumeration checked against the dry run (compare_dry2.txt) and the script

- Every printed line of the dry run maps to an enumeration row. The rows the enumeration leaves out carry no computed claim: the title, the section headings, the table header and the blank lines. The "## Stage 1 (#15): cgiar against lc, tc, fu, cfu" heading is a literal, but it equals `eligible`.
- The dry run exercised only the stage-2 fail path (challengers = cfu), and it injected `frac_mod16 = 1` and the four count lines. The following are therefore correct by reading, not by the dry run:
  - the "Upstream MOD16 share" and ">= 80 % MOD16 (n = 218)" rows (n = 218 is simply every headwater station when frac is 1);
  - the MOD16 cover line;
  - every winner != inc branch.

  I read each of these against its expression and found them correct:
  - `hi16 & obs >= 10` is used for both n and the mean;
  - the quantiles are over `nrow(cal)`;
  - `sub("^aet_mod16 ", ...)` gives the relabelled counts;
  - `winner` needs both `winner_top2 != inc` and `pass_d2`.
- findings.md's new "Compare dry run" section restates 32.3/28.6/17.3/70.8, fu 6 / cfu 87, 33.2 vs 31.2 and cfu 93. Each number matches compare_dry2.txt.
- The count semantics are exact. `frac_mod16` is a block mean of `fact^2` = 16 booleans (wet_mod16_aet.R:224), so it is k/16 and `fr == 1` / `fr == 0` are exact tests. `cfu_cell_equivalents` 208,815.4 = 137,890 + 70,925.4 over 179,665 partial cells, which is consistent.
- The manifest granule row cannot silently undercount. `sort()` would drop an NA path, but `wet_mod16_check()` stops on any missing tile × year, and `wet_mod16_aet()` runs first.
- A smaller point, not flagged: the same Disclosed line gives the gaps as "codes 65529-65535". Pixels with fewer than `min_years` (10) valid years out of 20 are gaps too (wet_mod16_aet.R:215). Such a pixel is coded in most of its years, and min_years is frozen in the plan, so the description is essentially right.
- Out of scope, and already in the plan: wb_map.R:47's "1981-2010" legend (Phase 4 revisits it if the winner changes).
