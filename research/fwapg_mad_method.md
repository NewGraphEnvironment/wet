# fwapg mean annual discharge: method, parity and sampling sensitivity

**Verified:** 2026-09-25; accumulation and Fraser sections 2026-09-26 · **Issues:** #1, #2 (found), #3 (uses it); fresh#114 (consumer) · **Produced by:** `scripts/mad_parity.R SALR`, `scripts/upstream_area_check.R 100`, `scripts/mad_basin.R 100`, and against local fwapg (the `fresh-db` container); reading of fwapg `extras/discharge/` (`discharge.sh`, `sql/discharge0{2,3}_*.sql`, `sql/discharge.sql`).

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

A worked version of the parity and the sampling sensitivity on SALR, with figures, is the vignette `vignettes/segment-discharge.Rmd` (#28).

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

## Join-free upstream accumulation (#2)

fwapg, bcfishpass and fresh all compute upstream aggregates with the pairwise `FWA_Upstream` join, one watershed group at a time. fwapg skips order ≥ 8 mainstems to keep that tractable. `wet_upstream_sums()` computes the same sets without any pairs:

- **Code structure.** FWA codes have fixed-width labels (3 digits at the root, 6 below), so ltree order equals C-locale byte order.
- **Two ranges.** The `FWA_Upstream` set of watershed `(W, L)` is at most two contiguous ranges of the `(wscode, localcode)`-sorted polygons:
  - `W = L`: `[W, W/)`;
  - otherwise: `wscode = W ∧ localcode ≥ L` ∪ `wscode ∈ [L/, W/)`.
- **Range sums.** Computed with a segment tree, so there is no cancellation against basin-scale totals.
- **Irregular polygons.** 204 polygons in the Fraser (1,457 province-wide) have a localcode not under their wscode. `FWA_Upstream`'s localcode guards treat them differently, so they are corrected with exact SQL pairs (`wet_upstream_irregular()`).
- **Exactness.** Matches a brute-force transcription of `whse_basemapping.fwa_upstream(ltree×4)` on 1,540 random trees.
- **Scale.** The whole Fraser (644,710 polygons) takes 13 s: fetch 1.5 s, pairs 1.2 s, sums 4.2 s, 2.1 GB peak. That is the first build to cover order ≥ 8 mainstems.

**fwapg's stored `fwa_watersheds_upstream_area` is a stale snapshot.**
- It disagrees with accumulated area on 1,731 Fraser polygons. A live `FWA_Upstream` re-check of **all 1,731** found wet = live on every one (maximum relative difference 3.6e-14, including the basin mouth) and stored = live on none (`data/checks/upstream_area_100_full.txt`; 3.1 h, `WET_LIVE_MAX=5000 Rscript scripts/upstream_area_check.R 100`). A 401-polygon sample gives the same result in minutes (`data/checks/upstream_area_100_sample.txt`).
- It even contradicts itself: polygons sharing a code pair have different stored areas (9633006: 50,837 m² vs 7949160: 12,738,815 m²).
- Parity with fwapg's discharge must therefore divide by the stored table, because that is what fwapg did. Every other use should take accumulated area.

## Fraser parity (#2): `scripts/mad_basin.R 100`

PCIC historical, 1981–2010, fetched one year at a time: 60 files, 24 min, cached. The subset has 21,648 cells; the 6,694 NA cells lie outside the PCIC model domain (NA on every day).

| Check | Result |
|---|---|
| Segments | 1,012,100; fwapg has a value on 1,002,468, wet on 1,011,997 |
| Match fwapg within tolerance (½ unit of the 5th decimal + 1e-7 relative, on `mad_mm` and `mad_m3s`) | **99.782 %**; 56 of 69 groups at 100 % (incl. SALR, LSAL, BOWR, LFRA, FRCN) |
| Segments fwapg lacks that wet values | 9,529 (7,720 of order ≥ 8; max order 10) |
| Runtime and memory | 3.4 min from cache (area sampling 2.1 min, accumulation 7 s per build); ~3.2–3.4 GB peak RSS across runs |

**Tolerance.** Segments that pass differ by at most 1.8e-8 relative beyond rounding; those that fail start at 5.7e-6. There is nothing between 2e-8 and 1e-6, so any threshold in that gap gives the same count. The ~1e-8 relative difference, 1e-5 mm on headwaters of 1,000+ mm, is float noise in one of the two raster paths and is enough to flip 5th-decimal rounding.

**Every one of the 2,189 remaining differences is attributed.** A cause counts as reproduced only when rebuilding with it applied makes the segment match within tolerance:

| Cause | Segments | Watersheds | How it is shown |
|---|---|---|---|
| fwapg's centroid of a polygon fell in the next cell | 1,197 | 751 | **5** centroids lie 0.020–0.431 m from a cell edge (466 centroids in the basin are within 1 m). Flipping just those 5 to the neighbouring cell reproduces every one of these segments and breaks no segment that matched before (checked, 0). The sources are in USHU, UFRA and NICL (order 1) and LNTH and STHM (order 5). **Mechanism not established.** It is not the sampler: PostGIS `ST_Value` and terra agree on all 466 near-edge centroids. It is not a uniform grid offset: near-edge centroids closer than 0.431 m match fwapg unflipped (count in the report). The 5 sources' stored areas are unchanged, which argues against a geometry edit at those polygons. A different PROJ pipeline on fwapg's build machine remains possible but untested. The script checks that none of the 5 has a stale stored area. PostGIS `ST_Value` on the exact PCIC grid agrees with terra's cell on all 644,710 current centroids, and the download grid is exact (origin −140, 64; pixel 0.0625), so neither the grid nor the sampler is the cause; that check used a raster rebuilt on the PCIC grid, since fwapg's own raster is not in the local DB. |
| Group fwapg never valued | 196 | 102 | fwapg's group list comes from `fwa_assessment_watersheds_poly` and misses LDEN, which has 1 polygon coded to the Fraser. Zeroing it reproduces these, e.g. UEUT 7791959, where fwapg reads 0.49 × wet. |
| fwapg's segment-to-watershed lookup was older | 10 | 1 | fwapg's value equals, on both `mad_mm` and `mad_m3s`, wet's value for another watershed on the same stream: LILL 7837044 against 7608754. (Matching mm alone gave 3 coincidental hits on long mainstems.) |
| fwapg's stored upstream area is stale | 786 | 502 | **Not reproduced.** These are exactly the watersheds where fwapg's own stored area disagrees with the live polygons: consistent with a build on older polygons, but a necessary condition, not proof. |
| Unexplained | 0 | 0 | |

So the flip, never-valued and lookup causes (1,403 segments) are shown to be fwapg-side artefacts. The stale-area cause (786 segments) is consistent with one but not demonstrated.

**Sanity check at Fraser River at Hope (HYDAT 08MF005).**
- Accumulated upstream area is 216,659 km², against a gross drainage of 217,000 km².
- wet gives 2,476 m³/s (centroid) or 2,477 m³/s (area-weighted), against HYDAT's 1981–2010 mean of 2,664 m³/s: **−7 %**. That is plausible for unrouted VIC-GL with no regulation correction. Station bias belongs to #6.
- fwapg has no value here (order ≥ 8).

**Sensitivity at basin scale** (per segment, vs the live centroid/total build):

| Variant | 1st–99th percentile | Share with change > 5 % |
|---|---|---|
| Area-weighted sampling | −13.6 % to +24.1 % | 10.2 % |

- **Covered denominator:** negligible for most segments, but **54 change by more than 5 %, up to +716 %** (LFRA, DRIR). That is ground outside the PCIC domain, where the total denominator reads low and the covered one does not.
- **Area coverage:** 12,723 segments have area coverage < 1, 162 of them below 0.9.
- 29 segments are NA under area sampling only.
