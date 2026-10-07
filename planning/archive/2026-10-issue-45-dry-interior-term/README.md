## Outcome

The question was whether the open water balance's overshoot in the semi-arid interior (hydrologic zones 15, 17, 23 and 24) comes from climr's precipitation or from the cfu AET. Our terms were compared with PCIC VIC-GL's PREC and EVAP split at the shipped fit's calibration gauges (`scripts/wb_term_diagnose.R`).

The attribution rule was fixed before any PCIC value was computed, then amended, still blind, after a plan review found three holes:
- a P bias shared with PCIC could never read as "P side";
- the corroborating tests were lopsided;
- the gauge-side test ran before the usability test.

Three code-check rounds then fixed the script, ending in an enumeration of its caches.

**Result.**
- Under the registered rule no single term is named, and no lever is chosen.
  - Zones 15 and 24 read "compensating": our P exceeds PCIC's by 2–3 times the runoff gap, and our AET offsets most of it.
  - Zone 17 has no usable PCIC reference, and zone 23 no material gap.
- Post hoc, the evidence leans to precipitation:
  - the dry zones differ from the rest in the P ratio, not in AET;
  - in zone 24 the implied Budyko ω is implausibly high at half the basins.
- The deciding evidence is precipitation observed at plateau elevation. A follow-up issue was drafted for it.
- The scoring rule any P correction would face is fixed in `findings.md` and in `research/water_balance_method.md` §0, "Which term is off in the dry interior (#45)".

Also on this branch: README and DESCRIPTION brought up to what wet does (the water-temperature path; seasonal and scenario output dropped, since no script builds them). #5's PCIC line was refreshed to the shipped fit, and the research file's zone 24 name corrected (Southern Thompson Plateau).

## Measurement

**PCIC as a reference** (193 gauges, 192 distinct basins with PCIC over ≥ 95 % of the basin):
- RUNOFF + BASEFLOW against fwapg's stored MAD: median 1.00 (p10–p90 0.99–1.01).
- Closure: −1 %.

**P and AET against PCIC** (medians per basin):

| group | climr P / PCIC P | our AET / EVAP | ΔP (mm/yr) | ΔA (mm/yr) | runoff gap (mm/yr) |
|---|---|---|---|---|---|
| zone 15 | 1.43 | 1.48 | 152 | 138 | 52 |
| zone 24 | 1.61 | 1.65 | 302 | 199 | 131 |
| other zones | 1.15 | 1.63 | 135 | 203 | −25 |

- Across the dry basins, our log runoff error correlates with ΔP / P at r = 0.32, and with ΔA / P at r = −0.04.
- TerraClimate P sits between climr and PNWNAmet in the dry zones (0.75–0.90 of climr; 1.15–1.20 of PCIC, 1.68 in zone 17).
- MOD16 runs 0.80–0.94 of cfu.

**Shipped held-out baseline for the follow-up:**
- dry zones (40 gauges): MAE 42.8 %;
- zone 24: 92.8 %;
- all gauges: 27.5 %; headwater 30.7 %; nested 17.6 %.

**What changed because of it.** The zone 24 residual is no longer an open list of three candidates. The ET side is the least likely: three AET products and the PCIC comparison all fail to explain it. The P side is the leading candidate, testable only at elevation.

**Wrong turns, kept:**
- The first run was stopped by hand after the review, before any value was seen.
- A second run, from a pre-fix copy, was stopped once code-check found it would fail in stage 3.
- m1 lacked climr, so the third run went to m4. After climr was installed (user OK), m1 reproduced the report byte-identical.

## Evidence

- Report: `data/checks/wb_term_diagnose_20260717.txt` (tracked).
- Run logs: `data/logs/45/20261007_*` on m1 (gitignored).
- Per-basin data: `data/wb_term/diagnose_20260717.rds` on m1.
- Reviews: `review-round{1,2,3}.md` in this directory.

Open at archive: filing the plateau-precipitation follow-up issue, which waits for the user's OK on the draft.

Closed by: PR (this branch); #45 stays open until the follow-up is filed (`Relates to #45`).
