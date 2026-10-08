# Review round 2: staged diff, scripts/wb_gauge_diversion.R (#53), Deviation 1 fixes

Reviewer: code-check subagent, 2026-10-07. I ran probes on copies in the session scratchpad (`r2/`). I also ran a full copy of the repo there, with HYDAT 20260717 and the cached placement. Its report is byte-identical to the staged `data/checks/wb_gauge_diversion_20260717.txt`. The only repo file I wrote is this one.

None of the findings below changes a flag, a test or the verdict. Two of them are numbers the report prints.

## Findings

- **[fragile, report numbers] scripts/wb_gauge_diversion.R:516-541: the reported counts still include the repeat rows that Deviation 1 removed from the accounting.** The dedupe reaches `candidate`, and through it `u`, L, S, `n_cons`/`n_stor` and the straddle counts. Every count in "## Licence rows" except the candidate lines, and every count in "## Placement", still runs over all rows.
  - Measured on the snapshot (repeats = the same licence-purpose and POD_NUMBER, NA POD excluded):
    - "points of diversion 117945" includes 24,134 repeats.
    - "no location, surface, current (not placed) 163" includes 28. This line is the stated limit on undercounting.
    - "surface instream 3606" includes 833.
    - "replaced 1322" includes 140.
    - The status-year minus priority-year distribution covers 94,717 Current rows, 22,935 of them repeats.
    - "placed … 109987 of 110001 points" includes the 24,059 dropped located rows.
    - "point-gauge pairs upstream 69115" includes 15,349 pairs from dropped rows.
    - "own reach 816" includes 132, and "below the gauge 545" includes 91.
  - The Licence-rows section heading says rows, but "points of diversion" and the Placement lines say points. A reader takes these numbers as the deduplicated population that the per-gauge columns use.
  - Fix: count over `!lic$dup_pod` (and over pairs whose pid is not a dropped row), or relabel the lines as rows including licensee repeats.

- **[fragile, no effect in this snapshot] scripts/wb_gauge_diversion.R:134-147: within one licence-purpose and POD, the kept row's flag and units come from the first row by id, but its quantity is the maximum over repeats of any flag.**
  - 5 such keys (3 groups) mix flags, and 4 keys mix units. This is the round-1 mechanism (a quantity moved across flags) reached one axis over, through `m3yr_pod` rather than `g_max`.
  - `C132258|04A`: at PD33727 and PD187255 the first row is no-flag "Total Flow 0" and the repeat is D (527 and 551 m3/yr). So the group becomes shared and counts 551 split over 2 PODs, where D says 527 + 551 = 1,078.
  - `510150|05D`: the T quantity at PD218835 (52,386 m3/yr) enters `g_max` through its no-flag first row. The total comes out right here, but only by coincidence.
  - The units mismatch also feeds the `no_m3sec` mask (`u$units` from the first row). None of the 4 mixed-unit keys involves m3/sec.
  - Impact: C132258 is upstream of no gauge, and 510150 only of 08NE077, at weight 0. Nothing reported moves.
  - Fix, if wanted: take flag, units and quantity from one row, for example the row carrying the maximum. Or refuse a snapshot where a key mixes flags.

- **[fragile, report claim] scripts/wb_gauge_diversion.R:509-510: "The as-amended run's verdict: not gauge side" is a literal, printed whatever the snapshot.**
  - `data/gauge_div/raw/` is gitignored. A run on another machine (m4), or after the raw directory is cleared, takes a new WFS snapshot with a different `raw_key`. The report would then assert an as-amended verdict that was never computed for that snapshot.
  - The baseline asserts pin the release but not the snapshot.
  - Fix: print the line only when `raw_key == "9adbffe764"`, or name that snapshot key in it.

## Checked and found consistent with the spec

- **Dedupe key.**
  - No `|` occurs in LICENCE_NUMBER, POD_NUMBER or PURPOSE_USE_CODE, and no stray whitespace, so `grp` and `pod_key` cannot collide.
  - No located row has an NA POD_NUMBER.
  - Within a key, current, replaced, start, end, class, surface, PRIORITY_DATE, LICENCE_STATUS and redivert never differ. The first-by-id row therefore cannot lose candidacy that a repeat would have had.
- **Lookups.** `tapply()[name]` lookups (`m3yr_pod`, `dp_rep[lic$grp]`, `g_max[lic$grp]`, `g_npod`, `n_up`) match names exactly. A name that is absent gives NA, and NA is handled (`%in% TRUE`, and the shared and non-shared branches).
- **`dp_rep`.** It runs over distinct PODs. All 88 groups have at least 2 distinct POD_NUMBERs, and grouping by POD_NUMBER without the location gives the same 88.
- **Conservation.** For every one of the 8,064 shared groups, the sum of `v` over its kept located PODs equals `g_full`. The only kept rows whose flag differs from a dropped repeat's are the 5 mixed keys above.
- **Mixed groups.**
  - M+T groups: none exist.
  - none+T groups: the no-flag rows are all 0, so `v` is 0 and they are excluded (except the 510150 key above).
  - D-as-M groups with zero-quantity no-flag rows: 21 candidate rows, upstream only of 07FA003, 07FA006 and 08NG065, none of them dry. This is the same shape as the accepted M tradeoff.
- **`straddle` and `g_npod`.** Both count the same population: located, kept, shared, and group-uniform on class, `v` and redivert.
  - I recomputed `split_full` independently (each straddling station-group once, at the first masked row's weight × `g_full`). The largest difference is 3e-14.
  - full ≥ split ≥ zero holds at every gauge, and no straddling group has more than one in-force weight.
- **Labels and dams.**
  - The threshold-dependent label requires both 0.05 and 0.20 to fail.
  - `n_dams` and the dam lines use the same filtered `up`.
- **CV object.** Its fields are accessed with exact names (`cv` is a list, so partial matching was checked).
- **Report.** It reproduces byte-identically from the staged script.
