## Outcome

The open water balance is refit on HYDAT 2026-07-17, and the pipeline now keeps one fit per HYDAT release (`scripts/wb_fit_lib.R`; `WET_HYDAT` is required and checked against the file's release).
- **The 2025-10-14 fit is reproduced exactly** under the new layout and kept as `fit_20251014`, the #15 reproduction.
- **The refit** passes its pre-registered acceptance rule, but #11's headwater gate failed by 0.03 points. The user first chose raw P − AET, then, once the output report showed the main stems 23–36 % low without the adjustment, kept the adjustment through a recorded per-fit override (0.1-point tie tolerance). #47 revisits the gate.
- **The pooled-zone question**, open since #11, was settled on short-record gauges no fit uses, by rules pre-registered and amended (dated) before any scoring. "none" is fixed, which retires the "mildly optimistic" caveat.
- **Learned:**
  - A newer HYDAT revises drainage areas enough to change which gauges snap.
  - The zone adjustment barely matters for headwater basins but carries the main stems.
  - Every silent default in a fit pipeline (release, HYDAT file, AET) was a way to ship something no rule chose. Three code-check rounds found such defaults, each in the previous round's fix, until they were enumerated.

## Measurement

- **Reproduction:** `stations`, `monthly`, held-out predictions for all ten AETs, the #15 comparison and 24 of 24 output basins are identical (monthly-share NSE within 1e-12).
- **HYDAT 2026-07-17:** 336 snapped stations against 309, 315 calibration gauges (29 new, 4 dropped).
- **Acceptance:** headwater blocked-CV MAE on 209 common gauges, 30.90 against 31.18.
- **Gate:** adjusted 30.72 against raw 30.69, fails by 0.03.
- **Main stems:** raw reads Peace 0.77, Skeena 0.68, Nass 0.64 and Fraser at Hope 0.93 of observed; adjusted, 0.93, 0.81, 0.81 and 1.02.
- **Pooled-zone test:** 110 test gauges, 39 decision gauges. "none" 46.5 % against "other" 80.2 % (paired bootstrap of the gap +9 to +62 points). On all test gauges: none 43.5 %, raw 41.6 %.
- **Shipped:** blocked-CV MAE 27.5 % (headwater 30.7 %, nested 17.6 %). Against fwapg at the 183 gauges both cover: 30.3 % against 25.3 %.
- **Wrong turns kept:**
  - "raw" was shipped, then reversed on the river evidence.
  - The first coverage-style default carried a cgiar fallback.
  - The md5 split was found by review after the first fix.
  - A stale-index slip was nearly repeated in the vignette rewrite.

## Evidence

Tracked reports `data/checks/*_20260717.txt`, plus the 20251014 reports' one-line diffs. Run logs `data/logs/43/` on m4 (gitignored). Reviews in this directory: `review-plan.md`, `review-round1..3.md`, `review-enumeration.md`, `review-override.md`, `review-phase5.md`. Durable verdict: `research/water_balance_method.md` §0, "Refit on HYDAT 2026-07-17".

Closed by: PR for branch `43-refit-the-open-water-balance-on-hydat-20` (Fixes #43)
