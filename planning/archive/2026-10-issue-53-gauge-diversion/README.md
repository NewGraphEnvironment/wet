## Outcome

The question was whether the open water balance overshoots the dry interior (hydrologic zones 15/17/23/24) because the gauges read low: water licensed out of the creeks above them. That was the candidate #45 and #50 left for zone 24 (Southern Thompson Plateau, +92.8 % held out).

HYDAT could not answer it, because station selection keeps only `REGULATED = 0`. So `scripts/wb_gauge_diversion.R` placed BC water rights points of diversion upstream of the shipped fit's 315 calibration gauges on the FWA network, from a paged WFS snapshot without licensee fields.

The rule was fixed before any licence met a gauge, then amended after a blind review:
- The review's main blocker: a flag divided by observed runoff selects low-flow, high-error gauges, so dropping flagged gauges can lower MAE with no diversion effect.
- So the deciding test became a **naturalized rescore**: each gauge is scored against observed runoff plus its licensed use, with a within-zone permutation null. A drop test with an obs-matched null and leave-one-out stability back it up.

**Result: not gauge side**, stable under every leave-one-out run and every sensitivity.
- Licensed consumptive use above the zone-24 gauges is 0–2 mm/yr against overshoots of 26–245 mm.
- One dry gauge is flagged: Ambusten Creek, zone 17.

Written up in `research/water_balance_method.md` §0, "Gauge side in the dry interior (#53)".

## Measurement

**Snapshot.**
- 117,945 licence rows. The view repeats a row per licensee, leaving 93,817 kept PODs after deduplication.
- 2,490 dams, which carry no volume.

**Placement.**
- 85,935 of 85,948 kept points were placed in a fundamental watershed; 53,770 point-gauge pairs are upstream.
- Own-reach points: 684, of which 454 are below the gauge by stream position.
- Checked independently against `fwa_watershedatmeasure()` basins at 6 gauges: the same surface PODs (Hedley Creek differs by 2 non-candidate rows).

**Tests**, against held-out MAE (dry 42.8 %, 40 gauges; zone 24 92.8 %, 9):

| test | zone 24 | dry zones |
|---|---|---|
| drop test: flagged | 0 | 1 |
| drop test: MAE fall | 0.0 points | 0.6 points |
| naturalized fall, f 0.5 | 0.3 points (p 0.44) | 0.7 points (p 0.17) |
| naturalized fall, f 1 | 0.5 points | 1.2 points |

"Cannot" needs a zone-24 fall below 23.2 points at f 1.

**Sensitivities, all "not gauge side":**
- D thresholds 0.05 and 0.20;
- D or S;
- core consumptive purposes;
- without m3/sec;
- Current licences only, and with no replacement removal;
- zone 15 on raw error.

**Elsewhere.** No gauge outside the dry zones is D-flagged; 3 are S-flagged, Greata plus two in zone 28. The semi-blind replication had nothing to test.

**What changed because of it.** The gauge side, as far as licensed water shows, is ruled out for zone 24. What remains:
- P between the ridge-top gauges and the basins they drain;
- how the model partitions P in small basins with very low observed runoff (Greata Creek, 50 mm).

**Wrong turns, kept:**
- The first snapshot tripped its own duplicate-id guard. `paste0()` wrote startIndex 100000 as `1e+05`, which the server answers with page 1. I first took it for a faulty backend node and wrote that into a comment, then corrected it. The sequence check stays.
- The first snapshot lacked `LICENCE_STATUS_DATE`. It was refetched before the rule was fixed.
- **Deviation 1**, three code-check rounds after the flags were seen:
  - R1: repeated licensee rows counted at full quantity, and a T quantity spread over zero-quantity PODs;
  - R2: a defect inside that fix (quantity taken across flags), and report counts over the wrong population;
  - R3: named the mechanism (two row populations) and enumerated 42 derived quantities. Two were wrong, both report-only.
- Each fix lowered L. The verdict never changed.

## Evidence

- Report: `data/checks/wb_gauge_diversion_20260717.txt` (tracked; byte-identical from cache).
- Run logs: `data/logs/53/20261007_*` on m1 (gitignored).
- Snapshot and caches (md5 in the report): `data/gauge_div/` on m1.
- Reviews in this directory: `review-rule.md` (blind rule review) and `review-round{1,2,3}.md` (code-check).

Closed by: PR (this branch), `Fixes #53`.
