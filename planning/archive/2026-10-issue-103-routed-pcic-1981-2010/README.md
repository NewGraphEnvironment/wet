## Outcome

Routed PCIC flow on every FWA segment now describes 1981–2010, the period the balance and the gauge scores use. The run pin in `wet_segment_sources()` moved from `1951-2012` to `1981-2010`, and the chain was rerun: `pcic_routed_compare.R`, `segment_output.R` and the BUILD on m4, the upload (run by the user, since auto mode refuses a production write), a BUILD after it to confirm the live tree, then the vignette data, the segment map and the README figure on m1. The monthly article lost its period section, because there is no longer a period difference to bound. #103 published alone, ahead of #102.

The period test for #67: routed's spring-low, summer-high shape survives on 1981–2010, so the period does not cause it. The period accounted for about 40 % of the March–April shortfall and about 15 % of the July–August excess. What remains is attributed to PCIC's model. The PCIC draft in #67 was rewritten on the 1981–2010 numbers and has not been sent.

Review: 3 rounds, 3 reviewer agents, ended by enumeration (`review-plan.md`). Round 3 named the mechanism. The sentences to update came from a planning-time list of lines, not from a grep for the values that changed, and the grep then found two more sentences outside the diff.

## Measurement

- Routed table: fingerprint 178918222.786650, equal to the 1981–2010 row in `pcic.runs` (fwapg 7c30f58). It has the same 40,524,444 rows and 3,377,037 segments as the 1951–2012 run. 36,700,180 monthly values changed. The other 3,824,264 are equal in both runs, and 1,368,632 of those are zeros.
- Annual routed error at 290 gauges barely moved: mean abs 24.1 → 24.2 %, bias +0.2 → +1.4 %, routed closer 59 → 58 %. The Columbia's bias rose by 3.8 points and the Peace's fell by 3.9.
- By month, median error at 279 gauges: March–April −19.5 → −11.5 %, July–August +18.7 → +15.8 %. The share of gauges low in spring fell from 69 % to 61 %; the share high in summer went from 69 % to 68 %. Routed is closer than the balance in 10 of 12 months.
- Picks: 4,733 moved, 3,013 to routed and 1,720 to the balance (0.10 % of segments with a value). Routed is now picked on 3,154,131 segments and the balance on 1,378,712, of which 222,906 are under the 0.2 cut.
- BUILD at 94deeb5: 555,857,796 values compared, 0 differing; 35 of 67 parts were identical to the acb820f upload. After the upload, the BUILD at 00a3805 found 67 of 67 identical to the live 94deeb5 build. The upload took about 5 min.
- m4's `discharge.*` tables, reloaded from 94deeb5: segments took 100.6 min and watersheds 47.6 min, about twice the #77 reload, which itself took twice the first load. Both table comments name 94deeb5, and the picked-row count equals the segment report. Recorded under "Postgres" in `research/discharge_publish.md`.
- `devtools::test()`: 1205 passed, 0 failed, 0 errors.
- One wrong turn: `segment_output.R` stopped at once without `WET_FWAPG_COMMIT`. The plan had named that variable only for `pcic_routed_compare.R`.

Durable record: `research/discharge_publish.md` (Status, manifest, Postgres) and `research/water_balance_method.md` (routed against the balance, the period test).

## Evidence

- m4: `~/Projects/repo/wet/data/logs/103/` (segment_output, the BUILD before and after the upload, the reload, `pickmove.*`, part md5s before).
- m1: `data/logs/103/` (pcic_routed_compare, the vignette data, map and figure scripts, the full test run).
- Probes: `evidence/` in this archive.
- Reports: `data/checks/{pcic_routed_compare,segment_output,discharge_publish}_20260717.txt`.

Closed by: PR (this branch, `103-routed-pcic-over-1981-2010-switch-the-pc`)
