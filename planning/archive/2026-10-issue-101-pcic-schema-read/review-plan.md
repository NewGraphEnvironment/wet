# Plan review (Plan agent, 2026-10-18)

Findings relayed from the reviewer's reply; verdicts in findings.md.

- B1 data-raw vignette scripts source pcic_routed_lib.R before load_all(), so wet::: is the installed 0.4.5
- G1 segment_output.R routed query has no ORDER BY; month 0 mean can move in the last bits
- G2 vignette bundles do not record the table; add a field
- G3 first fwapg test errors rather than skips without pcic
- G4 publish_forcing hard-codes "PNWNAmet" (discharge_publish_lib.R:12)
- G5 plan text says routed_line(); code uses routed_report_line()
- O1 segment_output.R unlinks segment/ first: record md5s before
- O2 any R/ or scripts/ edit after the m4 segment run forces a rerun (discharge_publish.R:175-183): land code-check before Phase 5
- O3 reports must move between machines by commit; merge with a merge commit
- A1 run the EXCEPT on m4 too (parts built there)
- A2 part bytes depend on arrow/duckdb/crate versions on m4
- A3 fingerprint now scans ~2x rows
- AC1 EXCEPT should include watershed_group_code
- AC2 list exactly which BUILD report lines may differ
- AC3 vignette bundle values come from published parts; rerun exercises guards
- S3 lookup column `scenario` can be confused with the argument (cosmetic)
