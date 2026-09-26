## Outcome

Scoped per-segment monthly, seasonal and scenario discharge for the FWA, and proved the base method.

- **Inventory:** PCIC's gridded VIC-GL has a historical PNWNAmet run plus 12 CMIP5 runs, covering Peace, Fraser and Columbia only. There is no CMIP6 hydrology on the portal. The host moved to `services.pacificclimate.org`, which breaks fwapg's curl.
- **Scope risk:** PCIC's unreleased VIC-GL → Raven CMIP6 routed streamflow and temperature product (coastal domain + Fraser).
- **Decisions, all proposed for PR review (not user-approved):** an R package; compute per watershed and publish per segment; area-weighted sampling with covered-area normalisation; versioned parquet + STAC + a fwapg load for fresh#114.
- **Parity:** the `wet_*` chain reproduces fwapg's `fwa_stream_networks_discharge` exactly after rounding on SALR.
- **Follow-ups:** #2–#7. The fwapg metadata/curl issue was drafted in `findings.md`, not filed.
- **Durable facts:** [`research/pcic_hydrology.md`](../../../research/pcic_hydrology.md).

## Measurement

Distilled in [`research/fwapg_mad_method.md`](../../../research/fwapg_mad_method.md).

- **Parity on SALR:** 9,000 of 9,000 segments identical after 5-decimal rounding. Max relative difference 0.045 % for flows ≥ 0.01 m³/s.
- **Area-weighted vs centroid sampling:**
  - −10.75 % to +19.85 % (1st–99th percentile) across all watersheds.
  - −0.3 % to +2.8 % above 100 km².
  - +0.09 % at the outlet.
- **Covered-area denominator:** not measurable in SALR (fully covered).
- **Wrong turns:**
  - The first run stopped because two LSAL polygons sit upstream of SALR.
  - The planned "≥ 99 % within 0.1 % relative" threshold failed at 75.3 %, purely from fwapg's 5-decimal rounding of tiny flows. The test was replaced by "identical after rounding".
- **Code check:** 4 review rounds found 5 defects (none changed a SALR number). The loop ended on an enumeration; see `review-round*.md`.

## Evidence

`data/parity/SALR_*` (gitignored; regenerate with `Rscript scripts/mad_parity.R SALR`, ~8 s warm, ~1.5 min cold).

Closed by: PR (this branch, `1-scope-monthly-seasonal-and-scenario-disc`)
