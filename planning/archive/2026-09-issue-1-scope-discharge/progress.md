# Progress — Scope: monthly, seasonal and scenario discharge per FWA segment (#1)

## Session 2026-09-25

- Plan-mode exploration — phases approved by user
- Created branch `1-scope-monthly-seasonal-and-scenario-disc` off main
- Scaffolded PWF baseline from issue #1 with approved phases
- Next: start Phase 1

### Phase 1 — Product inventory (done)
- PCIC moved from data.→services.pacificclimate.org (301). fwapg `discharge.sh` curl lacks `-L`.
- Parsed `hydro_model_out` catalog: historical PNWNAmet (1945–2012, VICGL-RGM) + 12 CMIP5 runs (6 GCM × RCP4.5/8.5, VICGL, 1945–2099). No CMIP6 hydrology.
- Found PCIC VIC-GL→Raven CMIP6 vector-routed streamflow + water temperature (coastal + Fraser), "near completion", unreleased. Biggest scope risk.
- Started local fwapg (`fresh-db` container): discharge table 2,716,652 rows / 2,003,189 with mad_m3s.

### Phase 2 — Decisions (proposed)
- User said "go all phases to pr", so the decisions are recorded as proposals for PR review, not as user-approved.
- D1 R package; D2 compute per watershed, publish per segment; D3 parity mode + area-weighted/covered-area default, no order-8 skip; D4 Hive parquet + STAC Collection with table ext, `wet_db_load()` for fresh#114. Bucket and PCIC redistribution are left open.

### Phase 3 — Scaffold (done)
- R package, `wet_*` prefix, MIT, testthat 3e; CLAUDE.md project section.

### Phase 4 — MAD parity prototype (done)
- Headwater group SALR; 8 exported functions; `scripts/mad_parity.R`.
- Parity: all 9,000 segments identical to fwapg after 5-decimal rounding.
- Sensitivity: area-weighted sampling moves watersheds < 10 km² by up to ±20 % (1st–99th percentile) and > 100 km² by < 3 %. Covered denominator untestable in SALR (full coverage).
- /code-check: 4 rounds, ended on an enumeration (see findings).
- Next: Phase 5 close-out (issues, comment, PR).

### Phase 5 — Close-out
- Posted the decision record on #1; opened #2–#7.
- fwapg issue drafted in findings.md and left for the user (fork vs upstream).
