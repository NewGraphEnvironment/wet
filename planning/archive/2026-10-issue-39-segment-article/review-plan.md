# Plan review — #39 (Plan agent, 2026-10-06)

Findings returned in the reply text (Plan agents cannot write files) and recorded here.
Disposition in brackets.

## Blocker
- B1 Coverage assertion `identical(!is.na(fwapg_mm), in coverage)` fails: fwapg skips order >= 8 mainstems and leaves NULL rows. [Fixed before the review landed: probe found 36 in-coverage gauges without a value; coverage now = groups with a non-null value; assertion one-directional; `in_pcic` column.]
- B2 test-vignette_data.R:64 pins nrow(parity). [Fix with data commit.]
- B3 vignette reads full parity frame; n_match5 unguarded. [Data script asserts n_match5 == n_segments; vignette shim with data commit.]
- B4 keep `parity` registry rows: sampling and skill plots use pal_par. [Keep.]
- B5 map test pins layer names. [Fix with data commit.]
- B6 places filtered to groups; Prince George and Fort St. James lost. [Fixed: places in BULK or SALR context box.]

## Gap
- G1 segment values are the full fit; gauge fills are held out. [Say so in prose; worked example shows both.]
- G2 worked example needs the gauge's segment. [skill$linear_feature_id added.]
- G3 SALR-panel gauges on streams not drawn. [context_streams/lakes layers.]
- G4 dry zone needs a zone layer. [zones layer added.]
- G5 two panels tight. [Layout decided at render.]
- G6 on-map check must test containment in the frame. [Do so.]
- G7 coverage defined twice. [Test: every gauge with a fwapg value lies inside the outline.]

## fwapg matching
- M1 key correct; M2 compare in mm; M3 optional cross-check at snapped segment [not done]; M4 name fwapg artefacts (stale area, LDEN, domain-edge NULLs). [Name in limits.]

## Assumption
- A1 same obs, same period. A2 subset drops large mainstems where the balance does best: report n dropped and why. A3 "out of sample, mildly optimistic". A4 rule may fire; report median, share within ±20 %, split by basin. A5 "everywhere" overstates; attribute disagreements. A6 numbers.

## Ordering
- O1 rule outcome as an explicit checkpoint in findings before Phase 2. O2 data + tests + vignette shim in one commit. O3 commit before running. O4 fit-key files untouched.

## Scope / Acceptance
- S1 budget. S2 keep the zone-outlier check behind the text; fix "the parity above" wording.
- AC1 tests for fwapg_mm, in_pcic, gauges_salr lon/lat, n_match5. AC2 research keeps SALR detail. AC3 record rule outcome. AC4 word cap.
