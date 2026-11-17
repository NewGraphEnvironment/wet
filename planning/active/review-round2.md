# Review round 2: #166 branch (gauge_monthly_compare.R, routed_years_check(), research/monthly_error.md)

## Checklist read

- code-check-r.md (read by heading). Read in full:
  - "`stats::aggregate()` has three separate silent behaviours, and each fails in a different direction"
  - "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"
  - "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are"
  - "`match()` treats NA as a matchable VALUE, so two unknowns join to each other"
  - "`sprintf("%g", x)` writes `Inf` and `NA` into SQL as bare words, which Postgres reads as column names"
  - "duckdb in R: the query that autoloads `icu` binds unreliably, so `LOAD icu` before it"
  - "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires"
  - "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "A range total taken as the difference of two large running totals loses the small ranges"
  - "`unlist()` prefixes a `split()` group's name, so reassembling by name silently yields all-NA"
  - The rest (about 135 headings) by index line only.
- code-check.md: the prose under `## Mechanisms` of "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output" and "A guard's scope, escape hatches, and remedies" in full. The other nine Mechanisms H3s, "Rules that stand alone", Security and Spreadsheets were read by index line only (about 35 headings).
- code-check-shell.md and code-check-spatial.md: index lines only. There is no shell code in the diff, and the one sf read (attributes of a zipped shapefile) matches no heading's failure. About 110 + 130 headings not read in full.

Verified without a finding:
- **Round-1 fix 1** (check 1's "ours" branch): it now reads MA > -5 && JA < 5 at the agreeing gauges and shape_holds() at the rest. That is exactly the header's "neither holds there while both hold at the other shared gauges". The "theirs" branch also matches the rule (MA ≤ -5 and JA ≥ +5), and this run is theirs (-12.6, +16.7).
- **Round-1 fix 2** (parity) does what its header now states: d ≤ max(1e-3 · pub, 1e-5). The header claims no gauge-month fell under either floor. I checked this against fwapg (read-only SQL) at the 87 shared Fraser segments for 1981-2010: the smallest published month is 0.01196 m3/s (701756246, December) and none is under 0.01. So the 1e-5 floor (active below 0.01 m3/s) never applied, and the reported 3.3e-4 relative passes the bare relative rule. There are no zero months, so excluding them from par_rel changes nothing here.
- **Round-1 fix 3** (README row): province medians MAM -16.7 and Jul-Aug +17.3; zone 24 is -21.6 and zone 29 is -29.3 in Jul-Aug. All as stated.
- **Round-1 fix 4** (dry gauges): the report's dry list has 1 to 3 gauges in nine months and none in April-June. Gauges with a dry lowest year are dropped from MAPE and median APE (`k <- obs > 0`) and from min_ratio (o_min > 0). Both fit "1 to 3 in most months, none in April to June".
- **Round-1 fix 5** (VIC-GL cells): the replacement sentence matches task_plan's definition (area over one 0.0625° cell at its latitude) and gives no number.
- **The report**: byte-identical to data/logs/166/report_run3.txt and report_run4.txt. gmc_frozen.R equals the committed script, which is unchanged between 7a8a5ac and HEAD.
- **Every number in research/monthly_error.md checked against the report**: basin and zone lists, size classes, check 1-3 values, the DFO August table, 37/41 %, 23/24 %, +7/+21 %. "245 such gauge segments" also checks out: 243 y + 2 n, and the one province pair sharing a segment (08NM240/241) has no outlet. The #67 earlier numbers (7c30f58, 279 gauges) are attributed to #67 and logged in progress.md.
- **routed_years_check()**: catalogue ORDER BY year, files reordered to match, the bin count is 366 × subs, and a NaN flow aborts in the BIGINT cast or the `bad` count.

## Findings

- **[severity: bug, doc]** scripts/gauge_monthly_compare.R:398-404 and 527-532; data/checks/gauge_monthly_compare_20260717.txt (check 2 verdict line); research/monthly_error.md:56 and the answer bullet at line 13. Check 2 reports a verdict the registered rule cannot produce.
  - The header rule (lines 55-58, registered at 520b9ca) has two outcomes: "supported (theirs) if the gap … exceeds the gap at the rest by 0.05 or more; otherwise unresolved". Check 3's rule (lines 59-61) is the same shape.
  - `verdict_off()` adds a third arm, "not supported … the opposite of the reading", whenever the difference is ≤ -0.05. It was added in ba29835, after the rules were registered.
  - This run's check 2 difference is -0.10. Under the registered rule its verdict is "unresolved", but the report prints "verdict: not supported" and research/monthly_error.md carries it as "Check 2, PCIC's resolution: not supported." (also "check 2 not supported" in The answer).
  - The research header says the rules for #67's checks "are registered in the script header at 520b9ca, before the numbers they judge". The verdict category the report and research use is not in those rules.
  - This is not about the result being negative (the accepted tradeoff). The measured gap (0.02 against 0.12) is true. The defect is that the verdict label departs from the registered mapping, the same class as round-1 finding 1, which round 1 fixed only for check 1.
  - The fix is either to report "unresolved" (with the gap's direction as a description), or to amend the header and say in research that the third outcome was added after registration.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
  - **Inside a round-1 fix?** no

- **[severity: doc]** scripts/gauge_monthly_compare.R:66-71, 598-603; the report's parity line ("registered bound 1e-03 relative or 1e-05 m3/s"). Round-1 finding 2 said the code's floor was looser than the registered rule, in the passing direction.
  - The fix did not tighten the code. It loosened the floor tenfold: the old effective bound was max(1e-3 · pub, 1e-6 m3/s), the new one is max(1e-3 · pub, 1e-5 m3/s). It then rewrote the header rule to admit the new floor.
  - The header sits under "rules (registered before the numbers they judge)", and the report line calls both parts the "registered bound". The 1e-5 floor was written after the numbers were known (the header paragraph admits this, but the report line a reader sees does not).
  - The floor is physically defensible (two 5-decimal roundings, at most 1e-5), and it changed nothing in this run: the smallest published Fraser shared month is 0.012 m3/s, above the 0.01 m3/s where the floor starts to act.
  - So no number moves. The report's word "registered" for the floor is the only false part. The fix is a report line naming the floor as added after review round 1, or no floor.
  - **Rule:** code-check.md "A guard that fails toward pass"
  - **Inside a round-1 fix?** yes
