## Outcome

Replaced the pairwise `FWA_Upstream` join with exact join-free range sums (`wet_upstream_sums()`). FWA codes sort in C byte order, so each watershed's upstream set is at most two contiguous ranges; range sums use a segment tree; the few irregularly coded polygons are corrected with exact SQL pairs. The discharge chain (`wet_upstream_mean()`, `wet_pcic_annual()`, point sampling) now runs a whole basin, and `scripts/mad_basin.R` builds the Fraser with no order ≥ 8 skip. What was learned:
- fwapg's stored upstream-area table is a stale snapshot.
- Every difference from fwapg's discharge can be reproduced as an fwapg-side artefact, except those on stale-area watersheds, which are consistent with one but not demonstrated.
- Durable facts: [`research/fwapg_mad_method.md`](../../../research/fwapg_mad_method.md), sections "Join-free upstream accumulation (#2)" and "Fraser parity (#2)".

## Measurement

- **Topology:** Fraser, 644,710 polygons, in 13 s at a 2.1 GB peak. Exact against a brute-force `fwa_upstream` transcription on 1,540 random trees. Accumulated area equals the live `FWA_Upstream` join on all 1,731 polygons where fwapg's stored table disagrees (max relative difference 3.6e-14); the stored table equals live on none.
- **Discharge:** Fraser, 1,012,100 segments, 3.4 min from cache (24 min for the first PCIC fetch), ~3.2 GB peak.
  - 99.782 % match fwapg within rounding. The tolerance has a clean gap between 2e-8 and 1e-6 relative.
  - 9,529 segments newly valued (7,720 of order ≥ 8).
  - The 2,189 differences: 1,197 from 5 centroid flips (reproduced), 196 from LDEN never valued (reproduced), 10 from an older lookup (reproduced), 786 from stale stored area (not reproduced), 0 unexplained.
- **Hope:** −7 % vs HYDAT 08MF005.
- **Sensitivity:** area-weighted sampling −13.6 % to +24.1 % (1st–99th percentile); the covered denominator moves 54 segments by more than 5 %.
- **Wrong turns:**
  - "Identical after rounding" on `mad_mm` gave 86.6 % (float noise at 1e-8 crossing 5th-decimal boundaries).
  - An absolute mm tolerance left 22,528 mismatches.
  - Attribution by edge proximity labelled 752 watersheds as "tie-breaks". Code check showed that to be a necessary condition only; the flips are not ties.
  - A mm-only lookup test gave 3 coincidental matches.
  - "Covered denominator changes nothing" was false.
  - Each was replaced by a rebuild-and-compare reproduction.
- **Code check:** two loops (Phases 1–3 and Phase 4), each with a round that found a defect inside the previous fix, and each ended on an enumeration. See `review-round*.md` and `review-p4-round*.md`.
- **The first full live re-check was lost** after 3.2 h: its script was edited while Rscript was still reading it. It was rerun from a frozen copy (3.1 h).

## Evidence

- `data/basin/100_report.txt` and `data/basin/100_run.log` (regenerate with `/usr/bin/time -l Rscript scripts/mad_basin.R 100`).
- `data/checks/upstream_area_100_sample.txt` and `data/checks/upstream_area_100_full.txt` (regenerate with `WET_LIVE_MAX=400` or `5000` `Rscript scripts/upstream_area_check.R 100`).

Closed by: PR (branch `2-province-scale-upstream-accumulation-wit`)
