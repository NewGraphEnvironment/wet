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
