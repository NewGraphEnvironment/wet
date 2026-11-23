## Checklist read

- code-check.md: all 14 H3s under `## Mechanisms`, prose read with the `|` rows skipped (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work, index line only; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice, index line only). Rules that stand alone, Security, Spreadsheets and PDFs: none read (no heading names a tool or shape in this diff). Not read: 24.
- code-check-r.md: read in full "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it" and "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; used from the index: "`on.exit()` at a script's top level never fires", "`match()` treats NA as a matchable VALUE ...", "A `skip_if_not()` skips only its own `test_that()` block", "Rscript reads a script as it runs ...". About 135 not read.
- code-check-spatial.md: from the index, "A relation between FWA watershed codes is not a place" (glacier upstream test; round 2 measured 1.2 km2 at irregular codes). Others not read (about 120).
- code-check-shell.md: none (the diff has no shell). All not read.

Probes (read-only): the header of scripts/wb_small_basin.R and scripts/wb_small_basin_rule.R and the test file are unchanged since 9f5a0da except the amendment list; the #45 cache's column types (zone, nesting character; the rest numeric; 192 rows; no NA in ppt_tc or aet_mod16); the 11 WALLY stations labelled "under 95 % in BC or on the grid" all have bc_fraction or coverage under 0.95 in `st` (none dropped for a missing obs or upstream row); the #45 cache mtime (2026-11-13 09:17 -0700) is after the last commit to scripts/wb_term_diagnose.R (ed8f459, 00:48 -0700) and matches its tracked report's commit (1bdc3ce, 09:17:38).

## Mechanism

One shared assumption produced all three code findings: **an input named for one key (its release, its path, its sha) is taken to stand for everything it was made from, and each guard written then holds it to one list that happens to agree today.** The #45 cache is named for its release, so R1 held `cv_ann`, R2 held the fit's columns, and what it is also made from (#45's own code: `verdict()`, `lerr()`, `omega_implied()`, the derived columns and the ECCC table) is held by nothing but a comparison with the cache's own stored verdicts. The prose findings are the same assumption in sentences: a sentence written for one set (the 25 zone classes; the sections of one report; "the gauges") keeps reading as true after its neighbour or its set changes, because nothing ties the sentence to the set it quantifies over.

## Enumeration

Inputs of scripts/wb_small_basin.R and what ties each to the fit, release or commit:

- WET_HYDAT_RELEASE / `release`: wb_release(), refuses a malformed value. Covered.
- province run `key_dir`: wb_key_dir(), the one complete run. Covered.
- stations file: wb_cv_lib.R holds `s$release` to `release`. Covered.
- `cal` and `cal$fold`: rebuilt from the run and stations by wb_cv_lib.R and wet_cv_folds(), which are in score_files. Covered.
- `cv_aet-cfu.rds`: in the run's fit dir; station order, `obs`, `code_md5 == score_code_md5`, and the four registered medians (84 small). Covered.
- glacier cache `data/wb_small_basin/glacier_ws_<key>.rds`: keyed on the query text, the glacier table's count and total area. The joined `fwa_watersheds_poly` is not in the key. Not raised: the gauges' codes come from the stations file, so a reloaded FWA would break the stations snap before this cache. Uncovered, outside this branch.
- glacier per-watershed sum: SQL `sum()` with no ordered input (GROUP BY, no ORDER BY inside the aggregate). It differs only in the last bits on a rebuild; the cache freezes it, and the printed precision absorbs it. Not raised.
- #45 cache `data/wb_term/diagnose_<release>.rds`, fit-derived columns (`cols_g` plus `cv_ann`, merged row averaged): covered by f8ff320.
- #45 cache, its row set: a gauge added at a new PCIC-covered watershed would be missing from `b`. Covered transitively: any change to `cal` changes the held-out `cv_ann` of the rows that remain, and the guard holds every one of them.
- #45 cache, PCIC columns (`p_c`, `e_c`, `ro_c`, `bf_c`, `pet_c`, `pcic_cover`): not from the fit, and keyed by #45's `pcic_key` when #45 built them. They are not held here. Covered for "which fit"; their code is part of the next item.
- #45 cache, derived columns that verdict() reads (`le_o`, `le_c`, `closure`, `dp`, `da`, `gap`, `w_harg`, `w_pcic`, `r_o`), `tm$eccc`, and the copied `verdict()` itself: tied to #45's code by nothing. **Finding 1.**
- scripts/wb_small_basin_rule.R: sourced from the tree, registered at 9f5a0da, tested. Covered.
- WET_SB_INSAMPLE: writes to tempdir(). Covered.

Inputs of scripts/wally_compare.R:

- WALLY raw files: sha-named directory, md5s printed. Accepted.
- scripts/wally_zone_scores.csv: held to Table 1's Count and Average rows. Covered.
- `cv_aet-cfu.rds`: `release`, plus `obs`, `cv_ann` and `zone` equal to the article bundle. There is no `code_md5` check, but equality with the published bundle ties it to the published fit. Covered.
- `inst/vignette-data/monthly_values.rds` (`routed_mm`, `area_km2`): the article bundle, guarded where it is built; `sum(shared) == 283`. Covered.
- stations file: path named by release; `s$release` is not checked here, but wb_cv_lib.R checks it for the same file. Covered.
- HYDAT: wb_hydat() and then wet_hydat(), which refuses another VERSION. Covered.

Printed orders and values that could depend on the environment or on row order:

- wally_compare.R `table(why)` and `table(why_ours)`: fixed factor levels (R2). Covered.
- wally_compare.R `cols_pred[order(-used)]`: no ties (16, 15, 14, 13, 12, 8, 2), and order() is stable. Covered.
- wally_compare.R zone rows, md5 lines and Table 1 rows: in the order of the CSV and the file list. Covered.
- wb_small_basin.R zone classes `sort(unique(zone))` and `c_zones`: two-digit strings, which collate the same in every locale. Covered.
- wb_small_basin.R `again` loop: in `tm$zones` order. Covered.
- wb_small_basin.R bootstrap: `set.seed(188)` in each `score_b()` call, folds drawn from `unique(d$fold)` in `cal`'s merge order (by station_number). Covered.
- wb_small_basin.R lm and Spearman: BLAS last bits only, below the printed precision. Covered.
- wet_fwa_upstream(): sets C collation itself. Covered.
- glacier SQL sum: listed above. Not raised.

Prose whose subject or scope depends on a neighbour or on a set it does not name:

- research/monthly_error.md:12, "Routed PCIC's small-basin loss": named (R2). Covered.
- research/monthly_error.md:5, "Each statement's issue number names the section of data/checks/gauge_monthly_compare_20260717.txt it is read from": false for the (#176) statements. **Finding 2.**
- research/monthly_error.md:33, "That bias": refers to the bullet before it, the balance under 100 km2. Covered.
- research/monthly_error.md:34, "the raw contrast ... On the 48 small basins": the set is named. Covered.
- research/monthly_error.md:37, the size-class NSE: routed is scored only at shared gauges, so its set is implied by the source. Covered.
- research/monthly_error.md:51, "Routed is low ... at 64 % of the gauges": the 283 of the bullet before it. Covered.
- research/wally.md:11: fixed in R1. Covered.
- research/wally.md:46–51: the lead-in scopes the list to "the 25 zone classes", and routed's RMSE/STEYX ratio (1.8) is over 23. **Finding 3.**
- research/README.md, the wally row "against the balance's held-out 60 % and routed PCIC's 74 %": two sets (25 and 23) in parallel, unnamed, though it does not claim they are the same. Included in finding 3.
- data/checks/wally_compare_20260717.txt, "RMSE over STEYX, median: balance 2.16, routed PCIC 1.82" (scripts/wally_compare.R:278): the line names neither set; the sentence before it names routed's 23. Included in finding 3.
- research/water_balance_method.md, the small-basins bullet: points to monthly_error.md for the population. Covered.
- CLAUDE.md, the wb_small_basin line: the scope of every claim it makes holds (it does not mention the cache guard, and says nothing false). Covered.
- The amendment 2 text, "rebuilds every column the cache takes from the fit": accurate to the code. Covered.

## Findings

- **[severity: fragile]** scripts/wb_small_basin.R:266-343. Check C's verdict reads columns that #45's code derived (`le_o`, `le_c`, `closure`, `dp`, `da`, `gap`, `w_harg`, `w_pcic`; `r_o` for the printed raw error) and `tm$eccc` from the cache. Its rule is a verbatim copy of `verdict()`. Nothing ties either to the current scripts/wb_term_diagnose.R. The only check, `again` (line 337), recomputes the zone verdicts from the cache's derived columns and compares them with the cache's own stored verdicts, so it agrees by construction whenever cache and copy are from one era. Two cases go unnoticed:
  - a later edit to #45's `lerr()`, `omega_implied()`, its ECCC filter or its `verdict()` without a rerun, which leaves the cache stale against the code;
  - a rerun after such an edit that leaves the 21 zone verdicts unchanged while this script's copy differs from the new `verdict()`, which leaves the copy stale against the code.

  No number is wrong today: the cache was written after the script's last commit, together with #45's tracked report, and round 2 found the copy byte-identical. Possible fixes:
  - `parse()` scripts/wb_term_diagnose.R, take the `verdict <- function...` expression, and refuse unless it deparses identical to the copy (or evaluate that expression instead of copying it);
  - refuse a cache older than the last commit touching scripts/wb_term_diagnose.R, or recompute the derived columns from the cache's base and PCIC columns with #45's lines 147-170, parsed the same way.
  - **Rule:** code-check.md "Verification that reads its own output"

- **[severity: bug, prose]** research/monthly_error.md:5. "Each statement's issue number names the section of `data/checks/gauge_monthly_compare_20260717.txt` it is read from." The three bullets tagged (#176) at lines 33-35 are read from `data/checks/wb_small_basin_20260717.txt`, a different report. gauge_monthly_compare_20260717.txt has sections for #6, #67 and #162 only. The sentence was written by #185 for the file before the #176 bullets were added, and now sends a reader to a report that does not hold those numbers. Fix: name both reports ("... of gauge_monthly_compare_20260717.txt, or for #176 of wb_small_basin_20260717.txt").
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug, prose]** research/wally.md:46-51. The lead-in says "Ours are scored in WALLY's metric over the 25 zone classes holding 5 or more of our gauges", and the last bullet gives "the median ratio of our RMSE to WALLY's STEYX is 2.2 for the balance and 1.8 for routed PCIC". Routed's 1.8 is the median over `rr`, the 23 classes with 5 or more shared gauges (scripts/wally_compare.R:270, 279). The bullet above it restates 23 for routed's R2 alone, so the ratio bullet reads as over the lead-in's 25. This is R1's wally.md:11 defect one bullet down. Two more places carry the same unnamed pair of sets:
  - the report line it comes from, data/checks/wally_compare_20260717.txt "RMSE over STEYX, median: balance 2.16, routed PCIC 1.82" (scripts/wally_compare.R:278);
  - the research/README.md wally row's "against the balance's held-out 60 % and routed PCIC's 74 %".

  Fix: "1.8 for routed PCIC over its 23 classes", and the same words in the report line and the README row.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
