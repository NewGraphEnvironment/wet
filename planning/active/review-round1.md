# Review round 1: staged diff, scripts/wb_gauge_diversion.R (#53)

Reviewer: code-check subagent, 2026-10-07. Probes ran on copies in the session scratchpad. The only repo file written is this one.

## Findings

- **[bug] scripts/wb_gauge_diversion.R:129-145 (T, D and P rows): the snapshot repeats a licence-purpose's POD row, and each repeat counts its full quantity.** The rule assumes "one row = one POD of one licence-purpose", and the snapshot breaks that. Of 78,830 T rows ("total demand for purpose, one POD"), 17,378 duplicate an earlier row on (LICENCE_NUMBER, PURPOSE_USE_CODE, POD_NUMBER). 17,358 of them match it on every requested non-id column (quantity, units, status, dates, SHAPE). They look like one row per licensee from the view's join. The same holds for 203 D/P rows. Example: `063386|11A` at PD38899 appears 3 times with 27,136.56 m3/year. `dup_pod` removes repeats only for `shared` groups (M, none, repeating D/P). T rows, and D/P groups that do not repeat one quantity, are counted once per row.
  - Measured on the saved `gauges_20260717.rds`: 11,603 of 48,525 non-shared upstream (gauge, row) pairs are such repeats.
  - Removing them (keeping the first row per gauge × licence-purpose × POD) lowers dry-zone L. Examples: 08LA027 6.09 → 4.18 (5.70 → 3.79 together with the next finding), 08LB012 3.37 → 2.21, 08FC003 1.83 → 1.39, 08MC045 6.38 → 5.27.
  - Storage S also falls: 08LG016 0.041 → 0.025, 08FC003 0.0078 → 0.0040.
  - Flag counts change at the 0.05 threshold. The dry D-flagged count goes from 4 to 3 (08LA027 drops out), and the province count from 7 to 4 (07FD004 and 08LC040 also drop out). Flags at 0.10 and 0.20 are unchanged, and so are the S flags.
  - **The verdict does not change.** The error inflates L, which pushes toward "gauge side", and the verdict is "not gauge side" with a naturalized fall of 0.6 at f 1 against the 23.2 needed. Even so, the per-gauge L, L/obs and S columns, the 0.05-threshold sensitivity line and `n_cons`/`n_stor` are overstated in the tracked report.
  - Fix: drop repeat rows per (grp, POD_NUMBER) for every flag, not only shared ones. Under the rule's Ordering clause this is a deviation, to be reported beside the as-amended verdict.

- **[bug] scripts/wb_gauge_diversion.R:134-141 (mixed-flag groups): a none-flag row in a group that also has a T row gets the T row's quantity, so that quantity is counted twice.** `g_max` is taken over every row of the licence-purpose (line 135), but `g_npod` counts only the shared PODs (line 138).
  - The snapshot has 844 none+T groups. In all 1,391 of their none-flag rows QUANTITY is 0, so those PODs carry nothing for the purpose. Each still gets `v = max(T quantity) / n_none_pods`. Example: `C119198|01A`, where PD42101 (T) has 2.27 m3/day and PD42103 (none) has 0. PD42103 is counted at 2.27 m3/day as well.
  - 1,153 of those rows are located surface rows. In the run, 932 upstream rows have a `v` that changes when `g_max` is taken over the shared rows only (08LA027 6.09 → 5.70, 08KE016 1.54 → 1.48).
  - M+none groups (135) behave the same way: the M quantity is spread onto zero-quantity PODs. That matches the rule's literal wording ("M, or none … split equally over its located PODs") but moves volume to PODs that carry none.
  - The verdict does not change, for the same direction-of-bias reason as above.

- **[fragile] scripts/wb_gauge_diversion.R:256-257 (`straddle = "full"`): the "first row" of a straddling group is chosen over all of `u`, ignoring the mask.** If that first row is outside `base_mask` (a groundwater POD, or a replaced row), the whole group counts 0 in the "full" variant instead of its full quantity, which biases the split-sensitive (X) flag.
  - The snapshot has 301 licence-purposes that mix surface and groundwater PODs, and 27 that mix replaced and non-replaced rows.
  - X is 0 for every dry gauge in this run, so nothing reported changes. Fix: compute `first` over `mask & u$class == cls & u$straddle`.

- **[fragile, report label] scripts/wb_gauge_diversion.R:501: "no volume (Total Flow, Hectares, Select, none)" reports 11,152 rows, but those units cover only 1,749.** The other 9,551 rows have a volume unit and an empty QUANTITY. The count is right; it is attributed to the wrong cause.

- **[spec gap, reported-only] Pre-registered rule, "Per gauge": "dams upstream: count, by function and regulation class (reported)".** The report prints only `n_dams`. DAM_FUNCTION and DAM_REGULATED_CODE are fetched but never tabulated.

- **[spec reading, no effect] scripts/wb_gauge_diversion.R:410-411: Amendment 1 item 17 says "Threshold-dependent" applies if gauge side holds only at 0.10.** The code labels it if either 0.05 or 0.20 is not "gauge side" (OR, where the rule says "only at 0.10", which reads as both failing). This cannot fire with the current verdict.

## Checked and found consistent with the spec

- Units and the conversion factors.
- The in-force weight over each gauge's own complete years. It equals the rule's max/min form because the years lie in 1981–2010, and the years attribute matches `n_years`.
- Replaced and rediversion handling. REDIVERSION_IND has only N or empty values, so the count of 0 is real.
- Purpose classes.
- Own-reach placement by exact codes, with the 8-argument `fwa_upstream()` on the indexed point.
- 4-argument `fwa_upstream()` returns TRUE for equal codes in both the wscode = localcode and wscode ≠ localcode cases, so every own-reach point reaches `gd_own`.
- The gauge measure matches `fwa_indexpoint()`'s own construction.
- Dams at the midpoint of the longest crest part. All 2,490 are LINESTRING or MULTILINESTRING.
- The obs-matched stratified null, the minimum attainable p, step 1 and step 2 logic, the verdict mapping, the stability string comparison (the inner ": " in the unresolved verdict survives the `sub()`), the sensitivities, capacity and replication.
- The `sample.int()` edge cases (n = 1, k = 0), `set.seed()` placement, and integer64 counts coerced with `as.integer()` (bit64 loaded by RPostgres).
- WFS paging held to the server count, with `sprintf("%d")` for startIndex.
