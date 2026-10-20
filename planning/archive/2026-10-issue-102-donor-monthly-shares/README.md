## Outcome

The balance's monthly shares now come from donor gauges: each watershed takes the inverse-distance mean of the observed monthly shares of the five calibration gauges most like it in elevation, location, snowmelt timing and peak SWE. They replace #16's twelve regressions, and they are published (live build 8ca2dee, uploaded by the user 2026-10-19).

The rule, with every candidate setting fixed, was committed in `scripts/wb_validate.R`'s header (a8ca570) before any candidate code existed. Two choices were made at the plan gate: replace the months only (the daily curve later, in #99), and a symmetric leak test.

- **Code:** `wet_share_fit(method = "regression" | "donor" | "blend")`, and `wet_donor_mean()`, shared with #70's daily shape (identical output, tested).
- **Scoring:** `cv_share_methods()` and `share_related()` in `scripts/wb_cv_lib.R`; the rule and `share_method` in `scripts/wb_validate.R`.
- **Breakdowns:** the new `scripts/wb_share_donor.R`.
- **Downstream:** consumers updated (output NA counts, the publish description, the daily-shape check, the vignette data guard). The monthly-flow article was rewritten on the new build.
- **What was learned:**
  - At the monthly scale, nearest-gauge shares beat a province-wide regression decisively, most where the regression was weakest (non-freshet regimes, the Liard winter, zones 27–29).
  - Once the months are right, #70's within-month shape matches the free day-of-year curve. "Daily later" therefore has nothing left to gain from the curve.
  - The cost: a calibration gauge's segment now publishes that gauge's own pattern.
  - 08EE003, an ungauged seasonal site, gets far too much late-summer flow.

## Measurement

- **Rule outcome** (315 calibration gauges, median per-gauge share NSE): regression 0.8735, donor 0.9389, blend 0.9187 under blocked CV; leak-free 0.8735 / 0.9353 / 0.9209. Donor passes both pools by +0.065 / +0.062 and ships.
- **Independent check:** on 110 short-record test gauges that no fit uses, 0.772 / 0.837 / 0.812.
- **Monthly-flow NSE:** 0.727 to 0.813.
- **The read-only probe on m1:** run after the rule's commit and before m4, it gave the same numbers. The rebuilt regression differed from m4's stored shares by 1.9e-16 across machines, and was identical on one machine.
- **Annual untouched:** the held-out annual is identical in all ten AET variants, and #16's median reproduces exactly (0.873517978845096). Month 0 is byte-identical in all 24 basins and no pick moved; 38.3 M of 38.9 M watershed-months changed.
- **Freshet:** at the 241 May–June peak gauges, below the gauge in the peak month 66.4 % → 57.7 %, median error −12.7 % → −6.2 %.
- **Liard:** February and March go from −74 % and −80 % to within 4 %.
- **Where the regression stays higher:** zones 17, 06, 16 and 26.
- **Daily shape on the new months:** the within-month donor on held-out months goes 0.849 → 0.909, equal to the free curve (0.9091). Held out, Buck Creek's late-summer window error grew: +150 / +178 % became +208 / +242 %.
- **Publish:** BUILD 20 of 67 parts identical to 94deeb5 (the routed parts), 555,857,796 values compared, 0 differing. After the upload, 67 of 67 identical to 8ca2dee.
- **Article:** 12 checks failed on the donor bundle, and the passages they guard were rewritten.
- **Durations on m4:** ten variants plus the compare, 6 min; ship through BUILD, 22 min.
- **Durable verdict:** `research/water_balance_method.md` §0, "Monthly shares from donor gauges (#102)", with the #70 section revised to the rerun. Also `research/discharge_publish.md` (status).

**Review:** the plan review (`review-plan.md`) and four code-check rounds (`review-round*.md`).
- Round 1 found one false report sentence in a hashed file.
- Round 2 found three fragile spots, one inside a plan-review fix.
- Round 3 was clean, with an enumeration of the 14 branches on the share method.
- Round 4 found five stale or over-quantified prose claims. One was a co-located gauge pair (08NM240/08NM241) that does not publish its own shares. Round 4's enumeration of every prose claim ends the loop.
- Six reviewer agents in all, including the plan review.

## Evidence

- m4 logs: `data/logs/102/` in the `wet-102` worktree (chain scripts, `check_scores.log`, `check_output.log`, per-step logs), to be moved into the main checkout before the worktree is removed.
- m1 probe scripts: in the session scratchpad, not kept. Their result is in `findings.md`.
- Reports: `data/checks/*_20260717.txt` (tracked).

## Owed

- m4: remove the worktree after moving `data/logs/102/` into the main checkout; update the m4 and m1 memories (fit md5, live build).
- #99's body: the daily decision it now owns (the donor's free curve against #70's shape on the new months), with the numbers from the rerun.

Closed by: PR (branch 102-monthly-shares-from-donor-gauges-day-of)
