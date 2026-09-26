# fwapg mean annual discharge: method, parity and sampling sensitivity

**Verified:** 2026-09-25 · **Issues:** #1 (found), #2, #3 (use it); fresh#114 (consumer) · **Produced by:** `scripts/mad_parity.R SALR` against local fwapg (the `fresh-db` container); reading of fwapg `extras/discharge/` (`discharge.sh`, `sql/discharge0{2,3}_*.sql`, `sql/discharge.sql`).

## How fwapg builds `fwa_stream_networks_discharge`

1. Download PCIC historical BASEFLOW and RUNOFF (`TPS_gridded_obs_init`, PNWNAmet forcing), time indices 13149–24105 (1981–2010, daily).
2. `cdo -timmean -yearsum` on each, then `cdo add`, giving mean annual mm per cell.
3. **Centroid point sample:** `ST_Value(raster, ST_Transform(ST_Centroid(geom), 4326))` per fundamental watershed. The centroid is taken in BC Albers.
4. **Upstream area weighting:** `mad_mm = Σ_up (ST_Area(u) / upstream_area_ha·1e4) · value_u` over `FWA_Upstream(...)`. `mad_m3s = mad_mm · upstream_area_m2 / 31,536,000,000` (365-day year). Both are rounded to 5 decimals.
   - A watershed counts itself as upstream.
   - A NULL upstream value adds nothing but stays in the denominator, which biases partial-coverage results low.
   - If no upstream polygon has a value, the result is NULL.
5. **Order ≥ 8 mainstems skipped** (runtime).
6. Segments inherit their watershed's value through `fwa_streams_watersheds_lut`.

The forcing is **observed (PNWNAmet), not a CMIP5 scenario**. fwapg's README citation and the `fwa_streams.mad_m3s` column comment say otherwise.

## Coverage ceiling

In SALR, 384 of 9,384 segments (4 %) are absent from `fwa_streams_watersheds_lut`, mostly edge types 1400 and 1100, so they carry no MAD from any method. All 9,000 segments in the lookup have fwapg MAD.

## Parity (`wet` R chain vs fwapg), SALR

SALR is a headwater Fraser group: 4,587 watersheds, maximum order 6, max `upstream_area_ha` = group area. Two small LSAL polygons (wscode `100.591289`) sit upstream of two SALR polygons, because group boundaries cut mainstems, so sampling must cover every upstream polygon, not only the group's own.

| Check | Result |
|---|---|
| Segments compared | 9,000 / 9,000 |
| `mad_m3s` identical after 5-decimal rounding | 100 % |
| `mad_mm` abs diff | ≤ 5.8e-6 mm (the rounding) |
| `mad_m3s` ≥ 0.01 m³/s, max rel diff | 0.045 % |
| Sum runoff+baseflow before vs after averaging | 5.7e-14 mm/yr (equivalent) |

A relative threshold is the wrong parity test for small flows: fwapg's 5-decimal rounding carries up to 25 % error at 2e-5 m³/s.

## Sensitivity: area-weighted cell sampling vs centroid (per watershed, `mad_mm`)

| Upstream area | Watersheds | 1st–99th percentile | Max \|change\| |
|---|---|---|---|
| all | 4,587 | −10.75 % to +19.85 % | |
| > 1 km² | 2,167 | −10.6 % to +18.9 % | 84 % |
| > 10 km² | 827 | −3.7 % to +8.4 % | 13 % |
| > 100 km² | 314 | −0.3 % to +2.8 % | 2.8 % |
| outlet, 1,794 km² | 1 | | +0.09 % |

Centroid sampling gives a small watershed the value of whichever single ~25–30 km² cell its centroid falls in. The covered-area denominator changed nothing in SALR because it is fully covered; it needs a group on the PCIC domain edge to measure.
