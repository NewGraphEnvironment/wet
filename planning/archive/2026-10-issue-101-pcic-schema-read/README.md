## Outcome

wet reads PCIC's routed monthly flow from fwapg's `pcic.discharge_monthly`, filtered on the run `(PNWNAmet, historical, 1951-2012)`. The table and the run are named once, in `wet_segment_sources()`. `scripts/pcic_routed_lib.R` takes both from there, filters every read on the run, writes the report's `routed:` line in one place (`routed_report_line()`), and refuses a fingerprint that differs from the run's row in `pcic.runs`. For #103, the period is the one value to change. The values read are the frozen `whse_basemapping` table's, row for row.

Review found something the issue had not expected. The live parts' routed month 0, the mean of twelve months, took its last bits from the order the old table's rows were stored in. No read of the new table can reproduce those bits. The user decided: sum the months in month order (in `segment_output.R` and in `wet_segment_monthly(from = "fwapg")`), upload nothing, and let #103 republish. The vignette data guard needs every part identical to the live build, so the bundles stand as built against acb820f until then.

The same class stands in wet#76 and in link (link#356, filed here). No soul convention covers it yet.

## Measurement

- The 1951–2012 run against the frozen table, on `(linear_feature_id, watershed_group_code, month, q_m3s)` with `EXCEPT ALL` both ways: 0 and 0 on m1 and on m4. Both machines' `pcic.runs` read 40524444 rows, 3377037 segments, total 178035348.248310.
- `pcic_routed_compare.R`: the report differs only in the wet commit and `routed:` lines. Scores and the `table:` fingerprint are unchanged.
- `segment_output.R` on m4: routed month 0 moved in 384,680 of 3,377,037 segments (11.4 %), by at most 1.81 ulp. Every other value, key and column is identical, and 14 of 23 parts are byte-identical. Round 1 first said "about 15 %" and the docs then said "8 %", the Fraser's rate (82,681 of 1,010,776); the rebuild measured 11.4 %.
- `discharge_publish.R` BUILD on m4: every check ok, 555,857,796 values compared, 0 differing; 58 of 67 parts identical to acb820f. Nothing was uploaded.

## Evidence

m4: `~/Projects/repo/wet/data/logs/101/` (segment and BUILD logs, part md5s before and after, `segcmp.*`). m1: `data/logs/101/`. Reports: `data/checks/{pcic_routed_compare,segment_output,discharge_publish}_20260717.txt`.

Closed by: PR (this branch, `101-read-routed-pcic-from-fwapg-s-pcic-schem`)
