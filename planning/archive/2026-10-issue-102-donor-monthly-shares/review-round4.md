## Checklist read

- `index_code-check.md` and `index_code-check-r.md` (both in full).
- `code-check.md`, every H3 under `## Mechanisms` read in prose (table rows skipped), with "A proxy is not the property", "A guard that fails toward pass", "A guard's scope, escape hatches, and remedies" and "Verification that reads its own output" applied to the vignette's `stopifnot()`s.
- Also applied: every number a vignette quotes needs a `stopifnot` in the chunk that computes it; describe a set by the code's definition; check every quantifier against the data.

Method: rendered `vignettes/monthly-flow.Rmd` after `devtools::load_all()` into the scratchpad (`r4/`). It rendered with no error. I saved the chunk environment and read every interpolated value and guard input from it. I checked each research, `discharge_publish.md` and `CLAUDE.md` claim against `data/checks/wb_share_donor_20260717.txt`, `wb_validation*_20260717.txt` (all ten variants), `wb_shape_daily_20260717.txt` (current, and the copy at 8745010), `discharge_publish_20260717.txt`, the live-build parts in the bundle's provenance, `R/wet_donor_mean.R`, `scripts/wb_validate.R`, `scripts/wb_shape_daily.R`, and the local `fit_20260717/fits.rds` and `cv_aet-cfu.rds`.

## Findings

### 1. "At a calibration gauge the donor publishes the gauge's own shares" is false at one pair of gauges (medium)

Where:
- `CLAUDE.md`, the `wb_validate.R` paragraph: "at a calibration gauge it publishes the gauge's own observed shares".
- `research/water_balance_method.md`, #102, "What a donor publishes": "At a calibration gauge, the donor's nearest match is the gauge itself at distance 0, so the published months there are the gauge's own observed shares".
- `vignettes/monthly-flow.Rmd`, the first Limits bullet: "On a calibration gauge's own segment … its months are the gauge's own monthly pattern".

What is wrong: two calibration gauges, 08NM240 and 08NM241 (Two Forty and Two Forty-One Creeks near Penticton), snap to the same segment, `linear_feature_id` 707348241. They share `wscode`/`localcode`, an area of 5.35 km², and identical scaled static predictors. In `fits.rds$share$x` they are rows 284 and 285, and theirs is the only zero-distance pair among the 315.

`wet_donor_mean()` gives every donor at distance 0 the weight (`as.numeric(dd == 0)`). So on that segment the published shares are the plain mean of the two gauges' shares, and neither gauge gets its own. The two patterns differ materially: April is 0.053 at one and 0.096 at the other, May 0.465 against 0.496, June 0.294 against 0.241.

The vignette's guard checks the claim only at 08EE013 and 08EE004 (`diff(range(ratio_of(s))) < 0.02`), which is a sample standing in for "every". The tracked `wb_validation_20260717.txt` makes the same claim in its in-sample heading ("the donor shares draw on each gauge's own").

Fix: say "its own shares, or the mean of co-located gauges' where two share a watershed (08NM240/08NM241)". Or make the claim mechanical: count the zero-distance pairs in `fits.rds$share$x` and state the count.

### 2. The #70 section quotes numbers that its cited report no longer contains (medium)

`research/water_balance_method.md`, "Daily shape within the month (#70)", cites `data/checks/wb_shape_daily_20260717.txt`. This branch reran that script and overwrote the report. The diff edited the section's last bullet but left the stale numbers in place. Measured against the tracked report:

| the section says | the tracked report now says |
|---|---|
| observed months: basis 0.971 | basis 0.9796 |
| held-out months: flat 0.777, spline 0.832, donor 0.849, basis 0.836 | 0.8332, 0.8955, 0.9091, 0.9066 |
| weights alone: basis 0.680 | 0.7410 |
| donor leads 19 of 29 zones, basis 1 (zone 16, by 0.0003); zone 17 to spline by 0.0008 | donor 17, spline 9, basis 3 (zone 16 by 0.0010, zone 19 by 0.0021, zone 27 by 0.0052); zone 17 to spline by 0.0027 |
| basis with 4 or 8 components 0.9715 and 0.9700 | 0.9789 and 0.9799 |
| held-out balance in the windows: Buck Creek +150 to +178 % in the low-flow windows, Quick −13 to −22 % | Buck Creek +208 % (fry) and +242 % (spawning), migration −29 %; Quick −10 to −18 % |

The free-curve bullet also still calls the regression's 0.874 "the shipped held-out shares (`cv_share`)". `cv_share` is now the donor's, at 0.9389.

Separately, the #16 section's last bullet ("`cv_share` (the shipped specification)") no longer describes `cv_share`.

One result is recorded nowhere: under the donor, the held-out balance at Buck Creek in the late-summer windows got worse, from +150/+178 % to +208/+242 %. This is the same direction as the 08EE003 result. The #102 section reports only 08EE003 and the in-sample Bulkley gauges.

Fix: label the #70 numbers as measured on the regression's months (the report at 8745010), or update them. Add the held-out Buck Creek late-summer result to #102.

### 3. "Zones 27–29, where the snow regression was weakest" is not what the data show (low)

`research/water_balance_method.md`, #102, "Where it helps most". The regression's median share NSE by zone (`wb_share_donor_20260717.txt`) is 27 at 0.511, 11 at 0.649, 10 at 0.670, 28 at 0.701, 29 at 0.743 and 04 at 0.761. Zone 27 is the weakest, but zones 11 and 10 are weaker than 28 and 29, so "zones 27–29" are not "where it was weakest".

Fix: "Zone 27, the snow regression's weakest zone, goes from 0.511 to 0.942; 28 and 29 gain 0.18 and 0.14."

### 4. The Buck Creek window guard does not test the sentence beside it (low)

`vignettes/monthly-flow.Rmd`, the `windows` chunk, line 341, and the prose at lines 369–371. The prose says: "At Buck Creek the balance carries the gauge's own months, so its window error is the approximation's and its annual error's." The guard is `all(abs(err_of("balance")[win$station_number == "08EE013"]) < 15)`.

That guard would pass if the balance's window errors had nothing to do with the approximation, for example −14 % in every window. So it is a proxy for the claim, not a check of it.

Measured, (1 + approx)(1 + `wb_off`) − 1 gives −11.6 / −8.94 / +12.09 against actual −10.8 / −8.94 / +12.09. The claim holds, to within about 1 point in the migration window, where the window's years differ from the calibration years.

Fix: guard the composition, e.g. `abs(err_of("balance") - (100 * ((1 + approx_err / 100) * (1 + wb_off[["08EE013"]] / 100) - 1)))[win$station_number == "08EE013"] < 2`. `wb_off` is already computed in the earlier chunk.

### 5. "Lake outlets … stay the weakest group" holds only if zones are left out (low)

`research/water_balance_method.md`, #102, "Where it does not". Under the donor, lake outlets score 0.867. That is the lowest of the report's non-zone groups (the next is "peak other months" at 0.892). But the same report lists zones as groups, and zone 10 (0.783) and zone 17 (0.824) score lower.

Fix: say "the weakest of the non-zone groups", or name zones 10 and 17.

## Checked and found correct (abbreviated)

- **Vignette numbers and guards:**
  - `wb_off` is −11.6 % and −9.4 %; `ratio_of()` is constant to 4 decimals at both gauges.
  - `q_short` is −23.3 % ("about a quarter").
  - Routed reaches +60 % in the poor window, above the approximation's 26.8 % and 24.3 %.
  - `b003` is +379 % and +470 %; the 08EE003 migration window is −24 %.
  - `wb_med` stays within ±7.02 %, with April the maximum.
  - `un_winter` is −8.5, −2.0 and −2.7; November and December, not guarded, are −3.8 and −8.7.
  - `within` is at most 47.3 %.
  - `r_closer` is May, June, August and September (April is an exact tie at 34.77 %, correctly excluded by `>`).
  - Group NSEs: under 1,000 km² the balance is ahead (0.61 against 0.43, and 0.82 against 0.80); over it routed is ahead (0.92 against 0.87, and 0.95 against 0.93); at lake outlets routed 0.92 against the balance's 0.73.
  - `n_zero_wb` is 0; the held-out NSE is 0.813.
- **Research #102 against the reports:**
  - The rule table, the leak cost (0.0036), the four zones where the regression leads, and zones 01 and 02 gaining under 0.005.
  - The Liard: 0.785 to 0.911, and February and March at −73.6 % and −80.4 % moving to within 4 %.
  - The freshet: 241 gauges, 57.7 % below, −6.2 %, 85.9 % with the same peak month.
  - The short-record gauges at 0.772, 0.837 and 0.812.
  - The daily shape: 0.9824, 0.909 against 0.849, and the free curve at 0.9091.
  - The free curve has no exact-match branch, as stated.
  - All ten AET variants give "donor SHIPS".
  - a8ca570 precedes the candidate code (3fe75bf).
- **`discharge_publish.md`:**
  - The parts are 1.88 GB (decimal), split 20 routed against 23 + 24 balance.
  - 555,857,796 values compared, which matches the sum in the report.
  - BUILD rerun at 45c6c12, segment table 2fe90c6, manifest 22:34:16Z.
- **`CLAUDE.md`:** the `cv_share_methods`/`_leakfree` names, `fits.rds$share_method`, and `wet_donor_mean()` shared by both donors. Apart from finding 1, these are correct.
