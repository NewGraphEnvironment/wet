# Review round 1: #166 branch (gauge_monthly_compare.R, routed_years_check(), research/monthly_error.md)

## Checklist read

- code-check-r.md (read by heading): "`stats::aggregate()` has three separate silent behaviours, and each fails in a different direction"; "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"; "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are". Index lines read for the rest; about 140 headings not read in full.
- code-check.md: `## Mechanisms` prose of "A guard that fails toward pass" and "A fixture that cannot reach the failure mode" in full; the other twelve Mechanisms H3s by their index lines only. "Rules that stand alone", Security and Spreadsheets sections not read (about 25 headings).
- code-check-shell.md, code-check-spatial.md: index lines only. No shell code in the diff, and the one spatial read (sf::st_read of a shapefile unzipped from a zip, attributes only) matches no heading's failure. About 110 + 130 headings not read in full.

Verified without a finding:
- The report is byte-identical to `data/logs/166/report_run1.txt` and `report_run2.txt`. `gmc_frozen.R` equals the committed script. Neither script changed between ba29835 (the commit the report names) and HEAD. The header's rules (lines 32-68) are unchanged since 520b9ca apart from the one input line.
- `routed_years_check()` is a faithful copy of `departure_pcic.R`'s inline per-year and bin checks.
- Check 1's tree walk (`kids_pcic` on dowsubid, `kids_fwa` on the placed outlets' fwa_parent_subid) matches fwapg README step 5. The crosswalk ids are `integer` in fwapg, so the `as.character()` names line up.
- Check 2's local share matches README step 6. At an outlet segment, upstream_subids are the placed children and share is 1, so the local share is q_local / q_acc.
- Every number in research/monthly_error.md was traced to the report except the ones below. That covers the zone lists, size-class ranges, check 1-3 values, the DFO table rows and "245 such gauge segments" (243 y + 2 n in the per-gauge table).
- No Fraser gauges share a segment.

## Findings

- **[severity: fragile]** scripts/gauge_monthly_compare.R:478-484 — check 1's "ours" branch does not implement the registered rule. The header (lines 46-49) says "ours (the crosswalk) if **neither** holds there while both hold at the other shared gauges". `!shape_holds(i_ag)` is true when either condition fails ("not both"). So a result with March-April at or below -5 % but July-August under +5 % at the agreeing gauges, with both holding elsewhere, would be reported as "ours" when the registered rule says "unresolved". This run took the first branch ("theirs"), so the tracked report is not affected. The second branch is still not the registered rule. A strict version would require `med_err(ratio_s(rt_w, i_ag, 3:4)) > -5 && med_err(ratio_s(rt_w, i_ag, 7:8)) < 5`.
  - **Rule:** none

- **[severity: fragile]** scripts/gauge_monthly_compare.R:595-597 — the per-year parity is registered (header lines 65-68) as "within 1e-3 relative at every gauge-month". The code divides by `pmax(pm$q_m3s_pub, 1e-3)`. A gauge-month with published flow below 1e-3 m3/s is therefore held only to 1e-6 m3/s absolute. A published month clamped to zero would get an infinite relative difference under the written rule and passes under the code. In this run no shared Fraser gauge-month is below about 0.006 m3/s, so the floor never applied. The only clamped-zero Fraser months (08KH006, April-June) are at a gauge that is not shared. The tracked report is unaffected, but the code is looser than the rule it states, and in the passing direction.
  - **Rule:** code-check.md "A guard that fails toward pass"

- **[severity: bug, doc]** research/README.md (new monthly_error.md row) — "routed PCIC −17 % in March–May and +17 % in July–August across basins and zones" is false as written. Those are the province medians (report: MAM −16.7, Jul-Aug +17.3). By major basin, the Fraser's July-August is +6.3. By hydrologic zone, July-August is negative in zones 02, 05, 13, 16, 17, 24 and 29 (for example 17: −39.6, 24: −21.6, 29: −29.3), and March-May is positive in 17, 24, 28 and 29. research/monthly_error.md line 9 says "across the province", which the medians support. The README row needs the same wording, for example "province medians".
  - **Rule:** none

- **[severity: bug, doc]** research/monthly_error.md:97 — two problems:
  - "1 to 3 gauges a month have a dry lowest year" is false for April, May and June. The report's dry list ("January 2, February 2, March 2, July 1, August 3, September 2, October 2, November 2, December 2, Winter 1, Autumn 1") has none in those three months, so the correct statement is 0 to 3.
  - "Routed does not reach the dry years at small Fraser streams" has no number behind it in the report or the script. The script only drops gauges whose *observed* lowest year is zero from the percent statistics (`k <- obs > 0`). It never measures whether routed's lowest year is near zero there, and never checks that those gauges are small.
  - **Rule:** none

- **[severity: fragile, doc]** research/monthly_error.md:59 — "Spearman 0.997 with area" has no producer. It is not in the report or the script, and no committed log, findings.md or progress.md entry on the branch records it. findings.md A2 says only "cos(lat) barely varies". The research header names the script and report as what produced the file's numbers, and this one cannot be re-derived from either.
  - **Rule:** none
