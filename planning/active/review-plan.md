# Plan review — #122 (Plan agent, 2026-10-26, read-only; findings returned in its reply and written here)

Reviewed the draft plan against the bodies of #122, #118 and fwapg#42 and the code at main (fa9b31f). Every item below is folded into `task_plan.md`, which cites the codes.

## Answers to the six questions put to it

**1. Does the two-stage rule leave choices after scores are seen?** Yes:

- Candidate year sets differ, and the header does not say all candidates are scored on the same years. `pcic` has every year (62 modelled); `donors` has only the years at least one of the k donors has a value (`R/wet_departure_carry.R:94-100`). Province-wide, the 5 nearest donors of a 1950s gauge often lack the 1950s. #120's Q1 fixed this ("over the years every candidate has a value for", `scripts/departure_pilot.R:133-134`); Q2 had one candidate. Stage 2 needs it. → B1
- Stage 2 when both `pcic` and `blend` beat `donors`: which ships is not said. #120's `decide()` took `which.max` in listed order (`departure_pilot.R:460-465`). → G2
- Stage 1 ties likewise. → G2
- The predictor scaling table: `wet_station_space()` scales over the rows it is given (`R/wet_window_extend.R:205-209`); `wet_departure_carry()` refuses a target with no row. The short-record targets must be in `stations`; one table for every run, or scaling differs per call. #120's box pool included its short-record gauges. → G7
- Per-statistic pools: `wet_departure_carry()` refuses a donor with < 10 baseline years of the statistic carried (`R/wet_departure_carry.R:88-90`), so the sensitivities stop the script unless the pool is per (variable, period) as `dep_pool_of()` (`departure_pilot.R:617-621`). → G4
- `covariance_pick` when all 15 have r ≤ 0, or r is NA (a constant modelled series, which happens at segments routed to 0). → G6
- Blend in a year one component lacks. → G3
- r per statistic or on the migration mean for all: say it. → G1
- "Routed flow on the segment": the compare report defined the 290 by a `pcic.discharge_monthly` row; the plan's route defines it by a `segment_weights` row. Same set today; name one.

**2. Centring, baseline, year set, blend.**

- The baseline years are irrelevant to the score: centring removes any constant, so neither PCIC's bias nor its 1981-2010 mean affects its score. Fair; state it.
- The year set is where PCIC is advantaged if each candidate is scored on its own years. Score all three on the intersection. → B1
- The blend is structurally favoured under NSE: averaging two centred, imperfectly correlated predictors reduces error variance, so `blend` beats the better component whenever their errors are not strongly correlated; 0.01 is small against that. Say the interesting outcome is whether `pcic` alone clears `donors`. → A2
- Blend undefined where a year has donors but no PCIC (a modelled window-year ≤ 0, dropped) or PCIC but no donors. Make the year missing from `blend`; with the common-years rule the candidates stay comparable. → G3
- Amplitude is not normalised by centring: a candidate that tracks sign with the wrong spread scores below its correlation. Symmetric; note it when correlation is reported beside NSE.

**3. Covariance weighting.**

- r from modelled window departures is the right quantity, per (variable, period).
- "always 62 here" is false: five calibration gauges route to ~0 (`data/checks/pcic_routed_compare_20260717.txt:34-44`: 08JA015 routed 0 vs 2046 mm observed, 08JA016, 08JA014, 08JA028, 08DB013) and 11 carry < 20 % of observed, so modelled window values can be 0 in many or all years, log departures are dropped, and r rests on fewer years or is NA. Need a minimum number of years for r (say 30) and NA → treated as r ≤ 0. → G1
- Province-wide `covariance_pick`: with 62 years r's sampling SD is about 0.13; picking the top 5 of 15 by r selects on noise (expected inflation roughly +0.2); PNWNAmet forcing is shared across a region, so modelled r among nearby segments is high and flat (0.8–0.95), so `covariance` ≈ `distance` and `covariance_pick` chooses among near-ties. State this as the expected null; it predicts a null result and explains why a win must clear the leak-free pool. In sparse regions the 15 nearest can span hundreds of km; report the median distance of picked donors. → A1
- A co-located donor (distance 0) takes all the weight in `wet_donor_mean()` (`R/wet_donor_mean.R:15`); one accepted pair in the stations rds shares a segment (1 duplicate `linear_feature_id` among accepted stations), so their modelled series are identical and r = 1. Leak-free removes that pair (same codes → `wet_fwa_upstream()` TRUE); LOGO does not. Count it.

**4. The fwapg#42 interface.** Not sufficient as written:

- `doy` is ambiguous: fwapg#42's probe uses `%j`, a shifting index; `pcic.subbasin_daily`'s bins are month-day (`cdo ydaymean`; `n_days` for Feb 29 is the leap-year count). The parity check needs (year, month, day). → B3
- The 1e-6 absolute tolerance conflicts with fwapg#42's float32 recommendation: float32 resolution at 1,000 m³/s is about 6e-5 and at 10,000 about 1e-3, so a 62-year mean of float32 days cannot match the float64 climatology within 1e-6 on large rivers. Either float64 (10.3 GB) or a relative tolerance. Cross-repo; settle before the header is committed. → B2
- `n_days` is not needed per year, but `wet_routed_years()` will call `wet_routed_raw()` with a fold-shaped list, bypassing `wet_routed_fold()`'s checks (every sub-basin has every day, no NA); re-implement them for the per-year shape.
- Clamping does not commute with averaging over years: the sub-basin-level parity holds (accumulation is linear), but the mean over years of per-day clamped routed flow is not the climatology's routed day at mid-network segments. Nothing should claim the routed series averages to `segment_daily`. Rounding to 5 decimals per day then averaging is not the climatology's rounding; parity must be on unrounded values. → A4
- 1950: reading 1951–2012 is right; the product has 22,646 days per sub-basin for 1951–2012 (62 × 365 + 16). State that count as the completeness check.
- Two fwapg commits: `WET_FWAPG_COMMIT` names the commit that built the Postgres tables (`pcic_routed_lib.R:27-35`; 7c30f58 in the compare report); the per-year product is built by fwapg#42's code at a later commit. The product should carry its own commit in its metadata; the report prints both. → G8

**5. Where the weighting lives.** Adding `weights=`/`modelled=` to `wet_departure_carry()` is defensible: it already departs from `wet_donor_mean()`'s contract (identity trick, per-year renormalisation), and `wet_donor_mean()` stays untouched, so #70 and #102 are unaffected. Two cautions: (a) `covariance_pick` needs "15 nearest, then top-k by r", which the identity trick cannot express, so factor the r computation and the three weightings into an internal `wet_donor_weights(space, target, donors, k, modelled, method)` that the exported function calls, so each rule is a unit test of a pure function; (b) "`donors` string gains `:r`" must apply only under the covariance options, or the default is not byte-for-byte (the string lands in the rds `departure_snow.R` reads). → Q5, G9

**6. Cannot be verified as written / already exists.**

- `routed_daily_fingerprint()` and `routed_where` are fixed to the 1981-2010 run (`pcic_routed_lib.R:15-24,150-170`, via `wet_segment_sources()`); the parity check against the 1951-2012 run needs a `period` argument. `routed_report_line()` would name `pcic.discharge_monthly 1981-2010`, which is not what this report scores. → G5
- `routed_daily_inputs()` reads the whole 1981-2010 fold (~1 GB) to get weights; the script needs only the weights query. → S4
- "`departure_pilot.R` regenerates byte-identical" needs the fwapg database through bare `PG*` (`departure_pilot.R:343`; CLAUDE.md), because the committed report's leak-free lines were produced with a database. State the precondition. → AC1
- "08EE018 is reported by name if present": it is not present in either stations rds set (selected on years inside 1981-2010; Maxan ran 1975–1979). Add it from the #120 box set with its snap, or say the test set excludes it. → S2 (folded: the box set is added)
- The parity scan's scope is unspecified (all 37,667 sub-basins, or those read). The mutation test "parity broken by one perturbed bin" is only meaningful if the perturbed bin is one the check reads. → AC2
- The fixture "≤ 102 rows per day over 1951–2012" is ~2.3 M rows, 5–15 MB; R CMD check notes data over 5 MB. Choose a segment with 3–5 sub-basins so the fixture stays under 1 MB. → S3
- Already exists: `wet_segment_daily()` has the duckdb-over-parquet reading pattern `wet_routed_years()` should copy; `cal$nesting` and `area_class` come from `wb_cv_lib.R:69-79`; `routed_basin()` exists.

## Categorised findings

**Blocker**
- B1. Candidate year sets not held common across `donors`/`pcic`/`blend`; stage-2 medians not comparable without it.
- B2. Parity tolerance 1e-6 absolute vs fwapg#42's float32 recommendation; settle across repos before the header is committed or the registered refusal is unachievable.
- B3. `doy` semantics undefined against month-day bins.

**Gap**
- G1. "always 62" for r fails at zero-routed segments; r minimum years and NA handling unfixed.
- G2. Stage-2 and stage-1 tie rules absent.
- G3. Blend with a missing component year undefined.
- G4. Pool per (variable, period) needed for sensitivities, or `wet_departure_carry()` refuses.
- G5. `routed_daily_fingerprint()`/`routed_where` fixed to 1981-2010; needs a period-parameterised variant.
- G6. `covariance_pick` fallback/NA/tie unspecified.
- G7. Predictor-scaling table unspecified for the short-record targets.
- G8. Two fwapg commits conflated under `WET_FWAPG_COMMIT`.
- G9. `:r` in the `donors` string must be conditional to keep the default byte-identical.

**Ordering**
- O1. Phase 1 registers the fwapg#42 interface before fwapg#42's gate chooses the store. Settle the interface (type, tolerance, date keying) with fwapg#42 first, or mark the interface section of the header as "what wet consumes", amendable by fwapg#42's gate, with the scoring rule alone frozen.
- O2. Phase 3's fixture is "cut from the real product", so the package tests cannot be written until fwapg#42 completes; test the function on a synthetic per-year fixture first, with the real cut replacing it later.

**Assumption**
- A1. Modelled r is informative beyond distance: shared PNWNAmet forcing makes regional r high and flat, so `covariance` ≈ `distance` is the likely null; the header should say so.
- A2. The blend's expected advantage under centred NSE is variance reduction; a `blend` win says little about PCIC's skill on its own.
- A3. "This machine" holds the fit bundle and `key_dir/upstream/*.rds` that `wb_cv_lib.R:32-35` reads; stated, not checked by the plan's verification.
- A4. 1e-9 tolerance on the 0.01 margin and 5-decimal rounding of per-day modelled values are inherited from #120 and fwapg; the rounding should not be applied before the sub-basin parity check.

**Scope**
- S1. Issue #122 says "scored under blocked CV and in a leak-free pool … as #102 did"; the plan uses leave-one-gauge-out plus leak-free. Defensible (blocked folds would remove most nearest donors), but it departs from the issue sentence and must be justified in the header.
- S2. 08EE018 is absent from the stations rds `test` set, so the #118 pilot site is not in the short-record test by construction.
- S3. The fixture size may exceed package norms; pick a small segment.
- S4. `routed_daily_inputs()` reading the full 1981-2010 fold for weights alone is a cost the script need not pay.

**Acceptance**
- AC1. Byte-identity of `departure_pilot_20260717.txt` is conditional on `PG*` reaching fwapg; the verification must set it or the test is wrong.
- AC2. "One-bin perturbation makes the script refuse" needs the parity scan's scope fixed (all sub-basins or those read).
- AC3. The compare script refuses a dirty `R/`/`scripts/` tree (`pcic_routed_compare.R:28-30`); this script should copy that guard.
- AC4. Add to verification: the three stage-2 candidates report the same `n` gauges and the same years per gauge; the number of gauges whose r rests on fewer than 62 years; the count where `covariance` fell back to `distance`.

## Disposition

Every item above is in `task_plan.md`: B1 → "Scoring, on common years"; B2, B3, O1, G8 → gate item 6 (the interface, amendable, float64, (year, month, day), two commits); G1, G6 → the `covariance` and `covariance_pick` definitions; G2 → tie rules in both stages; G3 → blend; G4, G7 → the pool; G5, S4 → Phase 2's lib change; G9, Q5 → Phase 2's carry change; O2, S3 → the synthetic fixture first; A1, A2 → stated in the header; S1 → gate item 5; S2 → the box set in the test set; AC1–AC4 → Validation and the refusals. A3: the plan's Phase 4 reads the bundle through `shipped_heldout()`'s guards, which is the check.
