# Code-check round 3 — branch 70-sub-monthly-flow-per-segment-a-daily-cli

Reviewed against merge-base 80ab129 (commits 18c94a6..33ba0c5). Probes ran read-only from the
scratchpad against `data/wb/e675918817/fit_20260717/cv_shape_daily.rds` and `shape_daily.rds`
(the artifacts the tracked report was written from); nothing in the repo was touched except
this file.

## The mechanism

Every round-2 finding, and every finding below, has one shape: **a sentence states a quantity
that the code never computes under that sentence's definition.** Two sub-forms:

1. **Prose derived by eye from the 3-decimal report.** "Donor leads in N zones", "basis leads
   in zone 17", "zones 27–29 gain most", "the others are within 0.016" are counts, leaders,
   rankings and bounds that `scripts/wb_shape_daily.R` does not print. Someone read the
   rounded zone table and wrote the verdicts down. A tie at 3 dp (zone 09, spline 0.988 /
   donor 0.988) and a near-tie (zone 17, spline 0.952 / basis 0.951) were resolved by hand, and
   a ranking ("gain most") was asserted without being computed. The same text was then copied
   into `planning/active/findings.md`, so the two agree with each other and not with the
   artifact.
2. **A report label or header literal beside code that computes something adjacent.** The
   `flatbk` footnote says "held-out gauge-months" while the spline's cell counts the
   observed-months spline; "08EE003 is not a calibration gauge", "k = 5" in the free-curve
   heading, and "the shipped shares' static predictors" in the header are literals that
   happen to agree with `match()`, `order(dist)[1:5]` and `share_static$snow` on this fit only.

Remedy for the class: have the script print the per-group leader, the donor−flat gain ranked,
and the spline fallback count in both settings, so every number the prose cites is a line in
the tracked report, and guard the literals (`stopifnot(identical(fits$share_spec, "snow"))`,
`!"08EE003" %in% cal$station_number`).

## Findings

- **[bug, prose]** `research/water_balance_method.md` §"Daily shape within the month (#70)",
  bullet "Where donor does not lead", and the identical sentence in
  `planning/active/findings.md` "Groups:" — **"donor has the highest median in 20 of the 29
  zones"** is 19. Zone 09 is spline 0.988097 against donor 0.988005 (the report prints both as
  0.988, a tie, which is not "highest"). Measured from `cv_shape_daily.rds$nse_obs` over
  `scored`, medians per `zone`: spline leads 01, 04, 09, 11, 13, 14, 15, 17, 26 (9), basis
  leads 16 (1), donor 19.

- **[bug, prose]** same two places — **"basis in zones 16 and 17 (by 0.001 and 0.027)"**: in
  zone 17 spline leads (0.952050), basis is second (0.951275), donor 0.923959. This is visible
  in the tracked report itself (`zone 17 ... spline 0.952 donor 0.924 basis 0.951`); round 2's
  review listed it as "17 (0.952, 0.951 > 0.924)" and the fix wrote the wrong leader down.
  Zone 16 is basis by 0.0003 (0.984689 vs 0.984390), which "0.001" rounds from the report.

- **[bug, prose]** same two places — **"the others are within 0.016"** (spline's lead over
  donor outside zone 11) does not hold once the spline list is corrected: zone 17 is 0.028
  (0.952050 − 0.923959). The six zones the sentence currently names are within 0.016
  (01 .0113, 04 .0159, 13 .0018, 14 .0096, 15 .0032, 26 .0140); 09 adds .0001.

- **[bug, prose]** same two places — **"Zones 27–29 gain most from donor: 0.716 → 0.842,
  0.761 → 0.923, 0.644 → 0.855 over flat"**. The three values are right; the superlative is
  not. Donor − flat by zone, ranked: 29 +0.2116, 28 +0.1618, **06 +0.1565**, 27 +0.1265,
  02 +0.1210, 07 +0.1159. Zone 06 (3 gauges, 0.768 → 0.925 in the report) gains more than
  zone 27. Either "zones 29, 28 and 06" or "the dry interior zones 27–29 gain 0.13–0.21".

- **[bug, report]** `data/checks/wb_shape_daily_20260717.txt` row `spline ... flatbk 0`,
  under the footnote **"flatbk: held-out gauge-months whose reconstruction fell back to
  flat"**, and `scripts/wb_shape_daily.R:208` (`n_fallback[["spline"]] <- sum(attr(held$spline,
  "flat"))`). `held$spline` is the spline through the *observed* months (the rule's setting),
  whose fallback count is 0. The held-out setting is `spline_cv` (`wet_shape_spline(q_m_cv)`,
  line 209), and `sum(attr(cv_shape_daily.rds$spline_cv, "flat"))` is **1** (08NB015, January,
  where `cv_share` is 0 with 0 neighbours). So the one number the round-2 fix added sits under
  a label that describes a different quantity, and the label's quantity is not 0. No decision
  rests on it (spline did not ship). Fix: count `spline_cv` for that column, or print both and
  say which (`flatbk_obs` / `flatbk_cv`), and keep the registered header's "is counted" true for
  the setting the product would use.

- **[fragile, header]** `scripts/wb_shape_daily.R:46-48` (registered header): donor's
  predictors are "elev, e_km, n_km, snowmelt_doy_50, swe_max (**the shipped shares' static
  predictors**, #16)"; line 164 sets `static <- share_static$snow` unconditionally. The
  parenthetical is true only because `fits$share_spec == "snow"` on fit_20260717 (verified).
  On a release where #16's rule ships `base`, the report would describe the shape as built on
  the shipped shares' predictors while using two the shares do not. The five names are the
  registered fixed setting, so the code is right and the gloss is the fragile part: assert
  `identical(fits$share_spec, "snow")` beside the other refusals so the sentence cannot go
  silently false.

- **[fragile, report]** `scripts/wb_shape_daily.R:391` prints the literal "08EE003 is not a
  calibration gauge: record only" and line 96 of the header says 08EE013 and 08EE004 are
  "(calibration gauges)"; the code decides all three by `match(st, cal$station_number)` (line
  305) and prints NA where it misses. On another release the literal and the NA pattern can
  disagree with no error. Guard: `stopifnot(c("08EE013", "08EE004") %in% cal$station_number,
  !"08EE003" %in% cal$station_number)`.

- **[fragile, report]** `scripts/wb_shape_daily.R:378` heading "(donor mean of doy shares,
  **k = 5**, no month constraint)" and line 232 `order(dist)[1:5]`: two hard-coded 5s that
  agree with `settings$donor$k` by coincidence. Derive the loop's k and the heading from
  `settings$donor$k`. (Also, the free curve has no distance-0 branch, unlike
  `wet_shape_predict()`; the header's "the same distance" is about the metric, so this is a
  note, not a defect.)

- **[fragile, prose]** `planning/active/findings.md`, "Outcome" last bullet: "the shape-code
  md5 line is the only line a code edit moves". Commit b8b402c moved the spline `flatbk` cell
  as well (the caller's own account of that rerun). The sentence states a property the code
  does not have (any edit to what is counted moves a report line); say "a code edit that
  changes no number moves only the md5 line".

## Every quantity checked against the report and the artifact (matches, for the record)

`CLAUDE.md` bullet: 365-day year, 29 Feb folded; same complete years as
`wet_station_monthly()` (asserted via `n_years`, line 150); weights sum to 1 per month;
`q[d] = Q[m] · n[m] · w[d]`; rule registered at 44ce054 (`git diff 44ce054 HEAD` on the script
changes only the placeholder `stop()`); donor k = 5 ships (`shape_daily.rds$method`, `$fit$k`);
artifacts named; report path; hashes none of `score_files_for()`'s files (the five
`shape_files` are disjoint from that list); `code_md5` and `shape_code_md5` carried; waits on
fwapg#25.

`research/water_balance_method.md` §Daily shape: 27 % (report 26.8 at 08EE013); fry window
Jul 15 – Sep 7 (`life_history_bulk.csv`); five static predictors; 6 components; 12 shares;
315 gauges, 94 folds; medians 0.899/0.977/0.982/0.971 (0.8994/0.9768/0.9824/0.9708); gain
+0.083; held-out 0.777/0.832/0.849/0.836; weights 0.795/0.752/0.680; fit on all 315
(`fit_of(..., seq_len(n))`, `$fit$n == 315`); leak 0.9824 → 0.9818, basis 0.9708 both; zone 11
0.933 vs 0.807 on 2 gauges; lake outlets 0.994 vs 0.979 on 19; peak-other 0.933 vs 0.927 on 74;
k = 8 0.9829, k = 3 0.9812, c4/c8 0.9715/0.9700, static+PT 0.9736, gain over k = 5 0.0005;
Chinook 26.8 → 16.8, 5.6 → −2.9, 3.0 → 5.5, −0.5 → −2.3, migration −0.1/−0.0; shape_b +150 to
+178 and −13 to −22; free curve 0.909 / 0.939 / 0.874; header Verified/Issues/Produced-by
lines; open-items bullet. All match except the four sentences above.

`research/discharge_publish.md` bullet: doy 1–365, 29 Feb folded; the identity; 366 → 365 for
routed; derived on read; header lines. Design statements, consistent with the code.

`planning/active/findings.md` Outcome: same numbers as the research text (match), plus "0
gauge-days interpolated; 0 observed gauge-months with no flow; 0 basis fallbacks" (report
line 5 and the basis row); the three sentences flagged above.

Script header vs body: `obs_sh / wet_month_days()` (line 162); `wet_nse(obs, mod)` scaled by
own means (lines 252–253); `cal$obs >= 10` (line 256), least 19.9 mm (findings); median over
`all_scored`; `which.max` over the four shippable names; `gain >= 0.01 - 1e-9`; method "flat"
recorded when nothing ships; blocked folds from `cal$fold` = `wet_cv_folds()` sub-sub-drainage;
leak via `wet_fwa_upstream()` recomputed, symmetric `related`; no timestamp in the report
(`stamp()` goes to `message()`); `n_years` refusal; 1e-12 means check; `s$years` is 1981:2010
and the stations rds has no `"years"` attribute (verified by reading it).

Report text vs code: "scored %d ... every candidate scored" = `sum(all_scored)`; "(flat = 0)"
for the weights column is an identity (`w_obs * nd[m]` has mean 1 in every month, so NSE of
the constant 1 is exactly 0; printed 0.0000); leak "(%d gauges)" = `sum(all_scored)`;
"within-month %s on held-out months" uses `ship`; Chinook heading derives its years from
`s$years` (round-2 fix verified at line 384–385); shape_a/shape_b definitions match lines
307–310.

## Checklist items exercised and cleared

`aggregate()` (formula interface): no NA rows reach either call in `wet_station_doy()` (`ok`
filter) and the Chinook `om` call is guarded by `if (!length(yr)) return(NULL)` so the
empty-subset abort cannot fire; the by-month result is re-indexed with `match(1:12, om$month)`
so dropped groups come back as NA and are asserted away for calibration gauges. `[[` on a
list (`years[[s]]`, `settings[[ship]]`, `held[[ship]]`) returns NULL for a missing key where
that is relied on (`settings[["flat"]]`); `n_fallback[[k]]` is only read for `names(settings)`
and the appended `"spline"`. `match()` NA: `x$md` has no NA (invalid dates removed by `ok`).
`paste()` zero-length: not reachable (`shippable` and `names(settings)` are non-empty
literals). `sort(Sys.glob("R/wet_shape_*.R"))`: the three names differ at an ASCII letter
after a common prefix, so collation order is locale-free today. `tolerance` in tests: 1e-12
and 1e-8 where used, both relative and tight enough for the claim. `expect_error(..., "years")`
and `"min_days"` match literal words in the messages, not interpolated values. `on.exit()`
is inside functions only. `system.file()` under `devtools::load_all()` resolves through
pkgload's shim (the run succeeded). `as.Date(optional = TRUE)` picks the format from the first
element, which is always a valid day 1. One-row `apply()` results are reshaped with
`matrix(..., nrow = )` in every place (`wet_shape_within`, `wet_shape_daily`,
`wet_shape_predict`, `wet_shape_spline`). The spline's periodic `splinefun` gets `y[1] == y[13]`
by construction and wraps days 1–15 before the first knot (test "continuous across the new
year" covers it).
