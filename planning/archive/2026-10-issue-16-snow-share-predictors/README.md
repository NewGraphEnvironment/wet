## Outcome

Added cd's ERA5-Land 1981–2010 `snowmelt_doy_50` and `swe_max` as static predictors of the monthly-share regressions (`wet_snow_normals()`, new province layers, `wb_province.R` run `e675918817`). Kept by a rule fixed before any snow score: blocked-CV median share NSE up by at least 0.01. Stored the held-out monthly balance with each fit (#68: `cv_share`, `cv_shares`, `obs_share`, `zone`, `lake` in `cv_aet-<AET>.rds`), so `scripts/wb_share_snow.R` breaks the comparison down from stored months.

Two things learned on the way:
- **Glacier snow.** ERA5-Land's glacier points carry 5,000–10,000 mm of perennial "snow". The user capped `swe_max` at 3,000 mm after a probe of the predictors and before scoring.
- **Province runs are not bit-reproducible.** Across database states the rows come back in another order, because `wet_ws_fetch()` has no `ORDER BY` (#76). The run-to-run identity gate therefore matches rows and allows rounding.

The upload and the vignette data are #77, along with switching `data-raw/monthly_vignette_data.R` to the stored months. #68 stays open for that last part. The durable write-up is `research/water_balance_method.md`, "Snow predictors for the monthly shares (#16)".

## Measurement

**Rule outcome, kept on both fits.** Median share NSE, base → snow:

| fit | gauges | base | snow | gain |
|---|---|---|---|---|
| shipped 2026-07-17 | 315 | 0.8558 | 0.8735 | +0.0177 |
| 2025-10-14 | 290 | 0.8659 | 0.8803 | +0.0144 |

The melt date alone (not deciding) gives 0.8593.

Breakdown on the shipped fit:
- **Monthly-flow NSE:** 0.708 → 0.727.
- **Zones 27–29:** share NSE 0.673 → 0.717. Zone 27 alone gets worse, 0.622 → 0.511 (12 gauges; 0.635 → 0.448 on 2025-10-14).
- **May–June peak gauges:** below the gauge in the peak month at 70.1 % → 66.4 % of them; median peak-month error −14.8 % → −12.7 %.
- **Liard (WSC area 10):** January median error −76 % → −16 %.
- **Zero-flow gauge-months:** 123 → 70 of 3,780.
- **January–April median monthly error:** +8 to +16 % → 0 to +11 %.

**Annual balance unchanged.**
- Non-snow upstream means agree with the run set aside to a relative 6.6e-14, over 24 basins and 3,245,453 watersheds.
- The held-out annual agrees to 5e-15 for every AET variant.
- All annual metrics are identical in the 13 validation reports, and `wb_aet_compare.R` reproduces #15 (cfu).
- In the output, segment and routed reports only the header lines changed, so the picks are unchanged.

**Publish BUILD, not uploaded.**
- Every value cross-check shows 0 differing.
- 6 of 67 parts are byte-identical to the live 7c62b9e.

**Inputs.**
- 584 ERA5-Land cells capped.
- 45,879 mask cells per layer filled in 36 passes.
- The per-cell baseline matches `cd_baseline(cd_extract())` within 0.2–1.7 % on two boxes (`findings.md`).

**Wrong turns kept in `findings.md`.**
- The first identity gate compared with `identical()` after a subset that drops an attribute, so it could never pass (code-check round 2).
- Its first real run then failed on row order, which became #76.
- The tolerant replacement was blind to non-finite values (round 4).
- Separately, the first snow test fixture had a year span symmetric about the baseline years, so a mutation that averaged every band passed it.

## Evidence

- Tracked reports: `data/checks/wb_share_snow*.txt`, `wb_upstream_identity.txt`, `wb_validation*.txt`, `wb_aet_compare.txt`, `wb_inputs.txt`, `wb_province_run.txt`, `wb_output_20260717.txt`, `pcic_routed_compare_20260717.txt`, `segment_output_20260717.txt`, `discharge_publish_20260717.txt`.
- Run logs on the machine with the full province run: `data/logs/16/*` in the #16 worktree, gitignored.
- Reviews: `review-plan.md` and `review-round{1..4}.md` in this directory.

Closed by: PR (see `progress.md`); relates to #68, #76, #77
