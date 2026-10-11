# Findings — Per-segment flow from either source: routed PCIC where placed, open balance elsewhere (#57)

## Issue context

**If we do it:** each segment carries the best estimate available there (PCIC's routed flow where an outlet is placed, our open water balance elsewhere), labelled with its source, and a report can switch sources or take PCIC's projections without a new pipeline. **If we never do:** the per-segment product publishes only the balance, which is the less accurate estimate on the 69 % of segments PCIC's routed flow already covers, or each report picks a source ad hoc.

## Why now

NewGraphEnvironment/fwapg#6 places PCIC hydromosaic's ~48,700 Raven-routed outlets on the FWA. It writes monthly flow (1951–2012, observed weather) for about 3.38 M of 4.91 M FWA segments in `whse_basemapping.fwa_stream_networks_discharge_monthly` (fwapg#14's build, published by fwapg#9).

#58 scored it at the shipped fit's calibration gauges. The scores, their caveats and the coverage edge are in [`research/water_balance_method.md` §0](https://github.com/NewGraphEnvironment/wet/blob/main/research/water_balance_method.md) ("Routed PCIC is closer than the balance…"), from `scripts/pcic_routed_compare.R` → `data/checks/pcic_routed_compare_20260717.txt`. In short:
- routed PCIC is closer than the held-out balance at the 290 gauges it covers, overall and on median in every basin; by mean error the balance is slightly closer in the Peace and the Fraser;
- where fwapg's older annual table also had values, the two PCIC products tie once seven far-low gauges are set aside; what routed adds over that table is coverage (the coast and the largest rivers);
- 11 gauges carry under 20 % of observed flow on their snapped segment. Judged by fwapg's older unrouted table: six are placement or the gauge's snap (side channels, Nechako reservoir lakes), one (08NE039) is PCIC's runoff, and four are unresolved. The default pick needs a rule for the placement cases.

Two caveats favour PCIC: its numbers are partly in sample (PCIC calibrated at gauges it does not publish), and the periods differ (1951–2012 against 1981–2010). The uncovered gauges are mostly the Liard (10A–10C).

## Proposed

- **One per-segment table, with a source column.** Add `source` (`pcic_routed` or `wet_balance`) to #7's columns, next to `scenario` and `period`. Both sources can be stored for the same segment, so a consumer can filter.
- **The default pick:** routed PCIC where fwapg#6 placed an outlet and its flow is accumulated; the balance everywhere else. Revisit per watershed group where #5's disagreement log shows PCIC is wrong (e.g. fwapg#6's 34 gauge disagreements: Nechako reservoir lakes, Quesnel near Quesnel, Taku), and where #58's report lists a gauge's segment carrying under 20 % of observed flow.
- **Baselines.** Within one comparison, both sources use the same period. Where a default-pick segment needs 1981–2010, decide between recomputing PCIC over 1981–2010 from the daily series (preferred if hydromosaic serves the days) and stating the period per row.
- **Projections through either source.** Per #4, a projected change is taken within each run: future period over the run's own 1981–2010. That ratio can be applied to whichever baseline the segment uses, so the balance gets PCIC's scenarios wherever PCIC has them. Outside PCIC's area, no projections.
  - **Check first:** whether hydromosaic serves projection runs on the same `subid` network. If it does, fwapg#6's crosswalk carries them unchanged.
  - Otherwise use the CMIP6 channel-scale runs (#9) or the gridded CMIP5 runs (#4).
- **Keep scoring both** at the same gauges, in `research/water_balance_method.md`. That is what tells us when the default pick is wrong.
- **No selector function yet.** Add projection rows when a report needs them.

## Decision needed

wet's CLAUDE.md, "Own estimates first; other groups' products are references" (2026-09-26), says PCIC is a yardstick, not an input to publish. #7 already settled that publishing derived PCIC values, cited, is acceptable (2026-10-07). Taking PCIC as the default where it is better changes the first rule. Edit that CLAUDE.md section when this is built: the balance stays the independent estimate everything is scored against, and stops being the only one published.

Relates to #7, #4, #5, #9, NewGraphEnvironment/fwapg#6.

## Plan-mode exploration (2026-10-11, m1)

#58 showed routed PCIC (fwapg#6's `whse_basemapping.fwa_stream_networks_discharge_monthly`) beats the held-out balance at the 290 gauges it covers. #57 builds one per-segment table carrying both estimates, labelled by `source`, with a default pick. It also edits CLAUDE.md's "Own estimates first" rule: the balance stays the independent yardstick, but stops being the only estimate we publish. Publishing (S3, STAC, `wet_db_load()`) stays #7's job.

### What exploration found (measured 2026-10-11 on m1)

- **Keys differ.** The balance output is per fundamental watershed (`scripts/wb_output.R` → `data/wb/<key>/fit_<rel>/output/<CODE>.parquet`, columns `watershed_feature_id, month, runoff_mm, discharge_m3s, coverage, bc_fraction`). Routed is per segment (`linear_feature_id, month, q_m3s`).
  - The balance reaches segments through `fwa_streams_watersheds_lut`, as the vignette already does (`data-raw/segment_vignette_data.R:253`).
  - Of 4,907,441 segments, 4,538,224 have a lut row. The 369,217 without one, mostly edge types 1400/1450, plus 50,280 of type 1100, get **no value from either source**.
  - Routed exists only where the lut does: 3,377,037 segments.
- **Far-low routed flow is systematic, not 11 gauges.** In the Fraser (basin 100), routed annual flow is under 0.2 × the balance on 123,394 of 1.01 M segments (12.3 %), and under 1 % of it on 83,462. 99.7 % of these lie on their own watershed's stream, so the lut mapping is not the cause.
  - 73 % of the near-zero segments are in LEUT, UEUT, UNRS and LNRS (Nechako Reservoir), where routed is about 0 on 97–100 % of segments.
- **Rule at the gauges.** "Routed unless < 0.2 × balance" flags 10 of the 290. The balance is closer at 9 of them, and mean absolute error drops from 24.1 % to 22.2 %. 08EE028 and 08NE039 are not caught.
- **Projections (the issue's "check first").** Hydromosaic (`beehive.pacificclimate.org/hydromosaic`, openapi) serves on the same `subid` network:
  - streamflow from PNWNAmet historical, daily 1950–2012;
  - 9 CMIP6 GCMs × `historical, ssp245` / `historical, ssp585`, daily 1950–2100 (57 series at outlet 4008184, water temperature and DO saturation included).
  - So fwapg#6's crosswalk carries them unchanged. The 1981–2010 routed recompute is also possible from the daily series.
- The full balance output (all basins, 13 months) is on m4. m1 holds 100/400, month 0 only. The routed table at fwapg 341b078 is on m1.

### Decisions (user, 2026-10-11)

1. **Pick:** per segment, routed unless its annual flow is under 0.2 × the balance's (`routed_far_low`); then the balance. Routed is picked where the balance is NA, and the balance where routed is NA.
2. **Storage:** both sources' rows, plus a logical `pick` that is TRUE on exactly one source per segment.
3. **Period:** a `period` column (routed `1951-2012`, balance `1981-2010`), and an fwapg issue for a 1981–2010 routed build.

## Nechako Reservoir: why routed is about zero (2026-10-11)

Attribution: **theirs, placement in fwapg#6's crosswalk** (filed as fwapg#24).
- PCIC has 487 outlets in LEUT/UEUT/UNRS/LNRS (`fwapg.pcic_outlets` ∩ group polygons). 4 are placed (3 LNRS, 1 UNRS); the rest are `broken_chain` (UEUT also has `no_candidate`).
- PCIC's tree takes the 386 outlets of LEUT/UEUT/UNRS to root 4009421 (Fraser mouth, LFRA), with `anchor_subid` in CHES. That fits PCIC routing the reservoir through the Skins Lake spillway and the Cheslatta, while the FWA drains it another way. Their runoff goes to the Cheslatta anchor, and the FWA reservoir segments get almost none.
- fwapg's README already names the Cheslatta's regulated flow as tripping the drainage check.

## Routed table may move schema

fwapg#23 (open) proposes moving `fwa_stream_networks_discharge_monthly` and `pcic_fwa_crosswalk` out of `whse_basemapping`. `scripts/pcic_routed_lib.R`'s `routed_table` is the one place wet names it.

## 1981–2010 and projections

Filed as fwapg#25: model, scenario and period parameters for the crosswalk build. Hydromosaic serves daily PNWNAmet from 1950 to 2012, and 9 CMIP6 GCMs × ssp245/ssp585 from 1950 to 2100, on the same `subid`s.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `segment_output.R` stopped at basin 800: `aggregate()` "no rows to aggregate" (a basin with no routed segment, the Yukon headwaters) | Guarded: an empty routed set gives no routed rows; `data.frame()` with scalar columns is built only when rows exist |
