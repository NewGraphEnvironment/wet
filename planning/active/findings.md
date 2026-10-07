# Findings — Dry-interior runoff: find which term is off, then fix that one (#45)

## Issue context

**If we do it:** we learn whether the weak semi-arid interior is a precipitation problem or an evapotranspiration problem, and test a fix for the right one. **If we never do:** zone 24 (Southern Thompson Plateau) stays at 102 % held-out error, and zones 15, 17 and 23 near 30–47 %. These remain the main limit the article names, after two AET experiments (#15, #18) that did not close the gap.

## Problem

- In the semi-arid interior, runoff is a small remainder of precipitation, so a small error in either term is a large one in runoff.
- #15 and #18 tried alternative AET products. Neither tested the precipitation side, ERA5-Land evaporation, or a diagnosis of which term is off.
- PCIC's VIC-GL output includes PREC and EVAP (`research/pcic_hydrology.md`). Inside its domain it gives an independent split to compare against, used as a reference, not an input (CLAUDE.md, "Own estimates first").

## Proposed Solution

1. **Diagnose.**
   - Per zone, inside PCIC's domain: our P (climr) and AET (cfu) against PCIC's PREC and EVAP, and against the gauge-implied AET (P − observed runoff) at the calibration gauges.
   - Attribute each zone's gap: ours, theirs or unresolved.
   - Also extend #5 with the gauge-level PCIC score from #39: 25.5 % against 30.5 % MAE at 168 gauges, Columbia 25.4 against 34.7.
2. **Pick the lever** the diagnosis points to, before scoring:
   - **P side:** a precipitation correction where climr departs from gauge-implied totals.
   - **AET side:** ERA5-Land total evaporation through cd. cd's catalogue has `total_precipitation` but no evaporation yet, which is a cd issue to file if this branch is taken.
3. **Pre-register and score** under a rule in the style of #15, against the #43 baseline.

Order: phase 1 can start now on the current fit; phases 2–3 after #43.

Relates to #5, #15, #18


## Pre-registered attribution rule (fixed 2026-10-07, before any PCIC PREC/EVAP value was computed)

Committed before `scripts/wb_term_diagnose.R` existed. Nothing below may change after the first PCIC PREC or EVAP number is seen. A change after that point is reported as a deviation, with the as-registered verdict alongside.

**Per gauge** (calibration gauges of fit_20260717, as `scripts/wb_cv_lib.R` builds `cal`; upstream area-weighted means, mm/yr, 1981–2010):
- Q = observed runoff (`cal$obs`).
- Ours: P_o = `p_yr` (climr), A_o = `aet_cfu` (shipped), PET = `pet_yr` (Hargreaves), R_o = P_o − A_o (raw, no zone adjustment).
- PCIC (TPS_gridded_obs_init): P_c = PREC, E_c = EVAP, R_c = RUNOFF + BASEFLOW.
- A gauge is in the diagnosis only if PCIC has a value over ≥ 95 % of its basin area.
- Zone = the gauge's dominant hydrologic zone (`cal$zone`).

**Per zone**, over its gauges in the diagnosis, in this order:

1. **Material gap.** Our median log(R_o / Q) ≥ 0.10. Otherwise the verdict is "no material gap".
2. **Gauge side.** PCIC also overshoots: median log(R_c / Q) ≥ 0.10 and ≥ half of ours. Then the verdict is "gauge side (unresolved: withdrawals, groundwater or a shared P bias)". Two models with independent P and ET both running high at the same gauges point at the gauge, or at something both share.
3. **Reference usable.** PCIC's median |log(R_c / Q)| ≤ 0.25, and its median closure |P_c − E_c − R_c| / P_c ≤ 0.10. Otherwise "unresolved: PCIC not a usable reference here".
4. **Decompose** the gap against PCIC, summed over the zone's gauges so the terms add: G = Σ[(P_o − A_o) − (P_c − E_c)] = ΣΔP − ΣΔA, with ΔP = P_o − P_c and ΔA = A_o − E_c.
   - **P side (ours)** if ΣΔP ≥ ⅔·G, and at least one independent test agrees:
     - (i) the implied AET under our P, P_o − Q, exceeds PET at ≥ half the zone's gauges (physically impossible unless P is high or the gauge loses water);
     - (ii) the median climr / ECCC MAP ratio at ECCC 1981–2010 normal stations in the zone (any normal code) is ≥ 1.10.
   - **AET side (ours)** if −ΣΔA ≥ ⅔·G and P_o − Q ≤ PET at ≥ half the zone's gauges (the larger AET the gauges imply is physically possible).
   - **Mixed** if both shares are < ⅔. Name the larger term.
   - A share test that passes while its corroboration fails is reported as "unresolved: <term> by decomposition, not corroborated".
5. **Disagreement with PCIC** (the CLAUDE.md attribution): in each zone, whichever of R_o and R_c has the larger median |log(R / Q)| is the one that is off. That is ours or theirs, and it is reported alongside the verdict.

**Lever (phase 2), mapped from the verdicts in zones 17, 23 and 24:**
- The lever is the term (P or AET) that is the verdict in the majority of the three. If there is no majority, zone 24's verdict decides (largest error).
- If the majority is gauge side, unresolved or mixed without a majority term, there is no lever. Phase 2 then names the evidence that would decide it.
- Zone 15 (the balance is already near PCIC there) and the wet zones are contrast only.

## Amendment 1 to the rule (2026-10-07, before any PCIC value was seen)

**Why.** A plan review found three holes in the rule:
- a P bias shared with PCIC could never come out as "P side";
- test (i) almost never passes in these zones, while the AET-side check almost always does;
- the gauge-side test ran before the usability test.

**Firewall.** A first run had started, using a frozen copy of the draft script. It cached the Fraser PCIC layers and was stopped during the Peace fetch, before it wrote any report or printed any value. Its per-basin caches were deleted unread. The per-year downloads in `data/pcic/` are kept: they are raw daily files, and no annual value was looked at.

**Disclosure.** Before this amendment the reviewer computed, from local non-PCIC files, these per-zone medians for zones 15, 17, 23 and 24 (raw log error +0.48 / +0.39 / +0.04 / +0.31):
- `ppt_tc / p_yr`: 0.80 / 1.14 / 0.91 / 0.76;
- `aet_mod16 / aet_cfu`: 0.87 / 0.95 / 0.82 / 0.80;
- `P_o − Q > PET`: at 26 / 0 / 12 / 22 % of each zone's gauges.

Two of the corroborations added below therefore had values known when they were registered.

The rule above stands except where amended here. Where they conflict, this section wins.

**Units.**
- One row per distinct basin: gauges that share a `watershed_feature_id` are averaged (08NM240 and 08NM241).
- A zone needs ≥ 4 distinct basins with PCIC over ≥ 95 % of the basin; otherwise "too few".
- A pooled dry-interior stratum (zones 15, 17, 23 and 24 together) gets the same verdict as a secondary result.

**Order of tests, replacing steps 1–4:**

1. **Material gap:** our median log(R_o / Q) ≥ 0.10. Otherwise "no material gap".
2. **PCIC usable:**
   - median |log(R_c / Q)| ≤ 0.25;
   - median |P_c − E_c − R_c| / R_c ≤ 0.25 (closure scaled to runoff, not P).

   Otherwise "unresolved: PCIC not a usable reference".
3. **Shared overshoot.** PCIC's median log(R_c / Q) ≥ 0.10 and ≥ ⅔ of ours.
   - If the independent P (TerraClimate `ppt_tc`, WorldClim lineage) has a zone median `ppt_tc / p_yr` ≤ 0.90 **and** `ppt_tc / P_c` ≤ 0.90, the verdict is "**P side, shared (ours and theirs)**".
   - Otherwise it is "gauge side (unresolved: withdrawals or groundwater)".

   Either way, the remainder is still decomposed (step 4) and reported.
4. **Decompose** G = ΣΔP − ΣΔA over distinct basins, as before.
   - G ≤ 0: "decomposition undefined (our P − AET is not above PCIC's)".
   - **P side (ours)** if ⅔ ≤ ΣΔP / G ≤ 1.5, and at least one P corroboration holds:
     - (i′) implied Fu ω under our P (P_o, P_o − Q) is > 5, or there is no solution (P_o − Q ≥ min(P_o, PET)), at ≥ half the basins **under both** Hargreaves `pet_yr` and PCIC `PET_NATVEG`;
     - (ii′) ECCC 1981–2010 MAP normals (any code) at stations in the zone no more than 500 m below the zone's median gauge-basin elevation: median climr / ECCC ≥ 1.10, from at least 3 stations; with fewer, the test is "unavailable", not failed;
     - (iii) independent P: median `ppt_tc / p_yr` ≤ 0.90.
   - **AET side (ours)** if ⅔ ≤ −ΣΔA / G ≤ 1.5, and **both** of these hold:
     - implied ω under our P is ≤ 5 at > half the basins under both PETs;
     - the P-independent ET agrees: median `aet_mod16 / aet_cfu` ≥ 1.00.
   - A share above 1.5: "compensating (the other term offsets more than half)".
   - Both shares below ⅔: "mixed".
   - A share test that passes without its corroboration: "unresolved: <term> by decomposition, not corroborated".
5. **Disagreement with PCIC:** as before.
6. **Stability:** the zone verdict is recomputed leaving out each basin in turn. If any leave-one-out verdict differs, the zone's verdict is reported as "unstable (<verdict>)".

**Lever (replaces the mapping above):**
- Voting zones: **15, 17, 23 and 24.** Zone 15 has the largest raw gap.
- Only "P side (ours)", "P side, shared" and "AET side (ours)" are terms. Every other verdict casts no vote, including "unstable".
- The lever is the term with more votes, if it has at least 2 votes **and** the pooled stratum's verdict is not the other term. Otherwise there is no lever.

**Reported, not deciding:**
- PCIC RO+BF against fwapg's stored MAD at each gauge's own `linear_feature_id` (a plumbing check; area-weighted against centroid sampling differs by up to about 20 % on small basins);
- R_o − Q, our total overshoot;
- a Fu counterfactual on Fu-dominated basins (cfu = Fu): P term = [P_o − Fu(P_o)] − [P_c − Fu(P_c)] with our PET, and model term = Fu(P_c) − E_c;
- the verdict on basins ≥ 100 km² only (PCIC cells are about 31 km²);
- the count of gauges with < 20 years of record.

**Implementation readings (2026-10-07, still before any PCIC value; from code-check round 1):**
- **Leave-one-out stability** applies the 4-basin minimum to the zone only, not to each leave-one-out subset. Otherwise every 4-basin zone would always read "unstable".
- **"Under both PETs" is read per basin.** A basin counts only when its test holds under Hargreaves and under PCIC PET_NATVEG. This is the stricter of the two readings, and it applies to the P-side test (i′) and to the AET-side ω check alike. From code-check round 2.
- **An unstable pooled verdict does not veto.** "Unstable" casts no vote, and the veto fires only when the pooled verdict is the other term, so an unstable pooled verdict is not a term. From code-check round 3.
- **A basin with P_o − Q ≤ 0** (implied ω undefined) fails both ω tests and stays in both denominators.

**Known limits, recorded as assumptions, not tested here:**
- Whether PNWNAmet and climr's reference map share a PRISM lineage. That is the reason (iii) exists.
- Whether VIC-GL was calibrated at these gauges. Its calibration gauges are not published; if it was, R_c ≈ Q is in-sample for PCIC.
- Whether `GLAC_OUTFLOW` is inside RUNOFF. This matters only for glaciated contrast zones.
- The step-1 and step-3 thresholds were set knowing our raw errors and fwapg's zone errors.
- In zones 17, 23 and 24, held-out equals raw: they are pooled to "none" in every fold, though the shipped all-station fit adjusts 23 and 24.

## Result (2026-10-07; `data/checks/wb_term_diagnose_20260717.txt`)

**Run.** 3fecb5e, with the rule as amended.
- It ran on m4, because m1 lacked climr then.
- With climr installed, m1 then reproduced the report byte-identical, and the ECCC table was `all.equal`.
- Logs: `data/logs/45/20261007_0{3,4}_*` (gitignored on m1).

**PCIC is sound as a reference:**
- Its RO+BF against fwapg's stored MAD has a median of 1.00 (p10–p90 0.99–1.01) at 174 basins.
- Closure is −0.01.
- The diagnosis covers 193 calibration gauges in 192 distinct basins.

**Registered verdicts:**

| zone | n | verdict |
|---|---|---|
| 15 | 17 | compensating: ΣΔP/G = 2.74 |
| 17 | 4 | PCIC not usable: PCIC runs −31 % there |
| 23 | 8 | no material gap: ours +4 % raw |
| 24 | 8 | compensating: ΣΔP/G = 2.97 |
| pooled dry | 37 | compensating |

**Lever: none.** P has 0 votes and AET 0.

**What "compensating" means here** (medians per basin, mm/yr, from `diagnose_20260717.rds`):

| group | climr P / PCIC P | TerraClimate P / PCIC P | our AET / EVAP | ΔP | ΔA | gap G | R_o − Q |
|---|---|---|---|---|---|---|---|
| 15 | 1.43 | 1.20 | 1.48 | 152 | 138 | 52 | 56 |
| 17 | 1.46 | 1.68 | 1.44 | 147 | 116 | 28 | 26 |
| 23 | 1.36 | 1.15 | 1.63 | 216 | 201 | 14 | 8 |
| 24 | 1.61 | 1.15 | 1.65 | 302 | 199 | 131 | 122 |
| other zones (155) | 1.15 | 0.93 | 1.63 | 135 | 203 | −25 | −94 |

Our P exceeds PCIC's by more than twice our runoff gap, and our AET exceeds EVAP by most of the same amount. The two models reach similar runoff with very different splits, so the rule's decomposition cannot name one term.

**Post hoc. Not registered, does not decide anything:**
- **What sets the dry zones apart is the P ratio, not the AET ratio.**
  - Our AET / EVAP is 1.44–1.65 in the dry zones and 1.63 elsewhere.
  - climr P / PCIC P is 1.36–1.61 in the dry zones against 1.15 elsewhere.
  - Across the 37 dry basins, our log runoff error correlates with ΔP / P_o at r = 0.32, and with ΔA / P_o at r = −0.04.
- **The three P products order the same way on the plateaus:** climr > TerraClimate > PNWNAmet. In zone 24, TerraClimate is 0.75 of climr.
- **Corroboration (i′), implied ω > 5 under both PETs, holds in zone 24** at 4 of 8 basins: Beak, Whipsaw, Camp and Greata (ω 20.6 and 13.6). It fails elsewhere.
- **The Fu counterfactual** on zone 24's 8 Fu-dominated basins puts the P term at 1,477 mm against a model term of 721 mm.
- **ECCC cannot test plateau P.** Every ECCC station in the dry zones sits 200–1,300 m below the gauge basins (median basin elevation 1,345–1,553 m), so (ii′) is "unavailable" in all four zones.
  - At the valley stations climr runs high in places: Princeton 1.37, Spences Bridge 1.26, Beaverdell North 1.18, Hedley 1.17.
  - The pooled-stratum median over 5 stations is 1.10.

**Reading.** The weight of evidence leans to precipitation: climr's plateau P is high relative to two other gridded products, and the dry zones differ from the rest in P, not in AET. The registered rule does not reach a P verdict, because our AET model offsets more than half of the P difference. A P lever is therefore plausible, but **not established**.

What would decide it: precipitation observed **at plateau elevation**, which neither ECCC normals nor the gauges supply. That means the BC River Forecast Centre's automated snow weather stations (ASWS) and snow courses on the Thompson, Okanagan and Fraser plateaus, scored against climr, PNWNAmet and TerraClimate.

**Attribution of the disagreement with PCIC** (CLAUDE.md, ours/theirs):
- **Ours:** zones 15 and 24.
- **Theirs:** zones 17 and 23, where PCIC is further from the gauges.

**Held-out baseline for the follow-up** (fit_20260717, as shipped):
- dry zones, 40 gauges: MAE 42.8 %, mean signed +31.7 %;
- by zone: 15 23.3 %, 17 47.5 %, 23 30.7 %, 24 92.8 %;
- all gauges 27.5 %, headwater 30.7 %, nested 17.6 %.

The issue's 102 % for zone 24 was the 2025-10-14 fit's.

## Phase 2: the lever, and the rule a lever would be scored under (pre-registered 2026-10-07)

**Mapping.** No lever. The majority verdict is no term, because 0 zones vote. Per the plan, no ERA5-Land cd issue is filed, since the AET branch was not taken.

**Next step.** Score climr, PNWNAmet (PCIC PREC) and TerraClimate against plateau-elevation precipitation: ASWS precipitation gauges and snow-course SWE as a lower bound on winter P, in zones 15, 17, 23 and 24. Only if climr is high there does a P correction get built.

**Scoring rule for any P correction built after that, fixed now and in the style of #15** (the baseline is fit_20260717 as shipped, scored under the same blocked CV):

*Independence.* The correction must come from precipitation observations or another P product. If it is fitted to gauge runoff, the fitting must sit inside the blocked CV. It must not be fitted to the gauges it is scored on.

*The candidate ships only if all five hold:*
- **(a)** Dry-zone (15/17/23/24) MAE at least 10 points below 42.8 %, on the same gauges.
- **(b)** All-station MAE no higher than 27.5 %.
- **(c)** Headwater MAE at most 0.5 point above 30.7 %. Nested MAE at most 1.0 point above 17.6 %, and nested within ±20 % at most 3 points lower.
- **(d)** At each of the seven major-river mouths in `wb_output`, the modelled/observed ratio moves toward 1, or away from it by no more than 0.03.
- **(e)** A fully nested selection beats the baseline's dry-zone MAE. In it, each outer fold chooses between the candidate and the baseline by (a)–(c) on an inner CV.

## Zone names

The zones shapefile (`HYDZN_NAME`): 15 Fraser Plateau, 17 Northern Thompson Plateau, 23 Okanagan Highland, 24 Southern Thompson Plateau. `research/water_balance_method.md` §0 calls zone 24 "Okanagan Highland" in two places (the #15 "Still unresolved" list and Follow-ups). It is fixed with this issue's research update.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `Rscript -e` with `"\\.shp$"` inside single quotes: unrecognized escape | Probe from a script file with `"[.]shp$"` |
| First run: `$TMPDIR` unset in the Bash tool, so `> $TMPDIR/msg.txt` wrote to `/` | Use the session scratchpad path |
