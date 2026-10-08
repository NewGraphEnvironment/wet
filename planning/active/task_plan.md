# Task: Dry-interior runoff: rescore zones 23/24 without regulated or diverted gauges (#53)

- #45 found no single climate term off in zones 15/17/23/24.
- #50 then scored climr against plateau-elevation gauges and snow courses. climr runs only about 9 % high there relative to the interior (D 1.09, not decided), and part of #45's climr–PNWNAmet gap is PNWNAmet's.
- A P error of a few percent cannot produce zone 24's overshoot (+93 % held out on the shipped fit).
- #45 left "gauge side (withdrawals or groundwater)" unresolved. Many Okanagan and Thompson plateau creeks carry irrigation diversions and storage above their gauges. A depleted gauge reads low, and the balance then looks like it overpredicts.

**Scope (plan gate, 2026-10-07):** flag, rescore the existing held-out predictions, decide. A refit without the flagged gauges is the follow-up if the verdict is "gauge side". The user said "go all phases": run to the open PR.

## Context

- #45 named no single climate term for the dry interior's overshoot.
- #50 then found climr at most modestly high at plateau elevation (D 1.09, not decided). Part of #45's climr–PNWNAmet gap is PNWNAmet's.
- That leaves zone 24 (Southern Thompson Plateau) at +93 % held-out error, with the gauge side as the remaining candidate. Many Okanagan and Thompson plateau creeks have diversions and storage above their gauges. A depleted gauge reads low, so the balance looks like it overpredicts.
- #53 flags those gauges under a rule fixed in advance, rescores the shipped fit (fit_20260717) without them, and decides.

## What exploration settled

- **The baseline reproduces from what m1 already holds.** I sourced `scripts/wb_cv_lib.R` (`cal`, zones, `mae()`) and joined `fit_20260717/cv_aet-cfu.rds` (`cv_ann`, `obs`). Results:

  | group | gauges | held-out MAE |
  |---|---|---|
  | dry zones | 40 | 42.8 % |
  | zone 15 | 19 | 23.3 % |
  | zone 17 | 4 | 47.5 % |
  | zone 23 | 8 | 30.7 % |
  | zone 24 | 9 | 92.8 % |
  | all | 315 | 27.5 % |

  No refit and no scoring-code change, so no fit goes stale and nothing needs m4.
- **HYDAT's regulation flag is empty here by construction.** `wet_station_select()` (`R/wet_station_select.R`) keeps only `STN_REGULATION.REGULATED = 0`, so every calibration gauge is already "natural" to HYDAT. HYDAT's `STN_REMARKS` for the dry gauges are operational (ice, missing record) and say nothing about diversions. The flag therefore has to come from water rights. HYDAT regulation is reported as 0 of n, with the reason.
- **Water rights:** bcdata `WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV` has 117,945 points of diversion (12 WFS pages). Its fields include `LICENCE_NUMBER`, `LICENCE_STATUS`, `POD_SUBTYPE` (surface or ground), `PURPOSE_USE`, `QUANTITY`, `QUANTITY_UNITS`, `QUANTITY_FLAG`, `PRIORITY_DATE` and `HYDRAULIC_CONNECTIVITY`.
  - Licensed quantities are entitlements, not use.
  - A licence can repeat across PODs (`QUANTITY_FLAG`), so quantities are deduplicated per licence and purpose.
- **Storage:** dams come from the BC dams layer (`WHSE_WATER_MANAGEMENT.WRIS_DAMS_PUBLIC_SVW`), with `cabd.dams` in local fwapg as a cross-check. Licensed storage comes from licences with a storage purpose.
- **Upstream test:** local fwapg has `whse_basemapping.fwa_upstream()` (by ltree code, and by blue line and measure) and `fwa_indexpoint()`.
  - PODs are placed by fundamental watershed against each gauge's `wscode`/`localcode`.
  - A POD in the gauge's own polygon is resolved by stream position, so a diversion just below a gauge is not counted.
- **No NGE package fetches water licences.** `trap` is a field-capture store and not this. Following #50's pattern, the raw snapshot is cached under `data/` (gitignored), with its md5 and row count reported, and the WFS read is held to the server's count.
- **Rescore means the held-out predictions already made.** The unflagged gauges' predictions were trained with the flagged gauges in the pool, so the raw P − AET error (independent of training) is reported beside them. A refit without flagged gauges is a station-selection change. It is the follow-up if the verdict is "gauge side".
- **Disclosure for the rule.** Per-gauge held-out errors in the dry zones are already public (#45's report) and were seen in this exploration. No licence or dam value has been joined to any gauge. The rule is fixed before that happens.

## Phase 1: Pre-register the flag and decision rule (before any licence or dam value is joined to a gauge)

- [x] Write the rule in `findings.md` and commit it before `scripts/wb_gauge_diversion.R` joins any licence or dam to a gauge. Thresholds are fixed there. The skeleton is below.
- [x] Plan-agent review of the rule, run blind (no values). Amend, commit the amendment, and record the disclosure above.

**Rule skeleton:**

*Licences counted:*
- current surface-water licences (`POD_SUBTYPE` POD) with priority date ≤ 2010-12-31, the end of the observation window;
- quantities converted to m³/yr, with unknown units counted and reported;
- deduplicated per licence and purpose. A licence whose PODs straddle the basin is split by the share of its PODs that are upstream;
- consumptive purposes only. Power, conservation and other instream purposes are excluded; storage is counted separately.

*Flags, per calibration gauge:*
- **diverted:** licensed consumptive depth L (mm/yr over the basin) ≥ 10 % of observed runoff;
- **storage:** licensed storage plus dam reservoir storage upstream ≥ 10 % of the mean annual runoff volume;
- **HYDAT regulated:** reported, expected 0 by selection;
- flagged = diverted or storage.

*Decision* (dry zones 15/17/23/24, held-out MAE on unflagged gauges against all gauges):
- **Gauge side** needs all three of:
  - the dry-zone MAE falls by ≥ 10 points (the #45 dry criterion);
  - zone 24's MAE falls by at least half, with ≥ 3 zone-24 gauges kept;
  - the fall beats the 95th percentile of removing the same number of randomly chosen dry gauges, stratified by zone, with a fixed seed.
- **Corroboration (capacity):** at the flagged zone-24 gauges, licensed consumptive depth is ≥ ½ the overshoot (held-out prediction − obs, in mm) at ≥ half of them. If the drop passes and capacity fails, the verdict is "flags select the bad gauges, but licensed water cannot account for the overshoot: unresolved".
- **Not gauge side:** the dry-zone fall is < 5 points and zone 24 does not improve by a quarter.
- **Inconclusive:** between those two. **Too few:** < 3 zone-24 gauges kept.

*Reported, not deciding:*
- the raw (P − AET) error with and without the flagged gauges;
- Spearman correlation between L / obs and the log error across dry gauges;
- a sensitivity at a 50 % consumptive fraction;
- the same flags and MAE change in every other zone, as context for a province-wide station rule;
- gauges kept per zone;
- inter-basin imports, which cannot be detected from PODs, named as a limit.

## Phase 2: Flags (no scores)

- [x] `scripts/wb_gauge_diversion.R` stage 1: fetch and cache the licence and dam snapshots under `data/gauge_div/raw/` (md5 and row count held to the WFS count). The cache is keyed on the snapshot md5 and the script.
- [x] Place PODs and dams in FWA fundamental watersheds; upstream of each calibration gauge via `fwa_upstream()`, with own-polygon cases resolved by `fwa_indexpoint()` measure. Counts are reported for each placement path.
- [x] Per gauge: L (mm/yr), storage ratio, flags; flag inventory section of the report (per zone: n, flagged, by reason; the licences behind each dry-zone flag).

## Phase 3: Rescore and decide

- [x] Join the flags to `cv_aet-cfu.rds` (asserting `aet`, `release` and `code_md5` as `wb_term_diagnose.R` does). Compute the decision, the random-removal null, capacity and the reported-only lines.
- [x] Write `data/checks/wb_gauge_diversion_20260717.txt` via `wb_report()` (tracked) and the per-gauge rds under `data/gauge_div/`. Confirm a second run from cache is byte-identical.

## Phase 4: Write-up

- [ ] `research/water_balance_method.md` §0: new subsection "Gauge side in the dry interior (#53)" with a provenance header. Update #50's "What would decide it", the Follow-ups list and the zone 24 line.
- [ ] Edit #53's body to the outcome.
- [ ] If the verdict is "gauge side": draft the station-selection follow-up issue (a licence-based exclusion in `wb_stations.R`, a refit on m4 under #43's acceptance), show it, and file it on OK. Otherwise, name what is next.

## Validation

- [ ] Tests pass (no package code changes)
- [x] `/code-check` on the script commit: 3 rounds, ended by round 3's enumeration of 42 derived quantities (2 report-only fixes); Deviation 1 recorded
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Critical files

- New: `scripts/wb_gauge_diversion.R`, `data/checks/wb_gauge_diversion_20260717.txt`.
- Reused: `scripts/wb_cv_lib.R` (`cal`, `mae`), `scripts/wb_fit_lib.R` (`wb_report`, `wb_release`), and the `save_atomic`/connection/key patterns in `scripts/wb_term_diagnose.R` and `scripts/wb_plateau_p.R`.
- Edited: `research/water_balance_method.md`; the CLAUDE.md script list gets one line.

## Verification

- The baseline lines in the report must equal 42.8 / 92.8 / 27.5 % (asserted in the script).
- Licence rows read = WFS count.
- A rerun from cache reproduces the report byte-identically.
- `devtools::test()` passes.
