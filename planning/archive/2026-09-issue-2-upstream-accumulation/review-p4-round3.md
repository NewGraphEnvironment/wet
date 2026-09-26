# Review: Phase 4 (`scripts/mad_basin.R`, research write-up), round 3

Verified against `data/basin/100_report.txt`, `100_run.log`, `100_segments.parquet` and `100_mad_cell.tif`, the round-2 attribution state (`r2state.rds`, whose flip step is identical to the staged script's), light fwapg queries, and fwapg's `extras/discharge/` source. The scratch R code is `r3a.R` to `r3h.R` in the session scratchpad.

## Findings

- **[bug: wrong claim] research/fwapg_mad_method.md:63: "It disagrees with the live `FWA_Upstream` join on 1,731 Fraser polygons" states as measured something that was only checked on a sample, and the output for that sample is no longer on disk.**
  - 1,731 is the count of **stored ≠ accumulated** (`data/checks/upstream_area_100.txt`: "mismatches > 1e-9: 1731"). Stored ≠ live was measured on only 401 polygons (400 sampled plus the basin mouth; `planning/active/findings.md:69`). The sentence reaches 1,731 by inference: stored ≠ accumulated on all of them, and accumulated = live on the sample.
  - The evidence for "every one checked (maximum relative difference 3.6e-14, including the basin mouth)" is not in any output file. `data/checks/upstream_area_100.txt` (written 01:16) has no live re-check section, because the full re-check (`upstream_area_check.R 100`, PID 90259, started 01:16) is still running and has overwritten the earlier run's output. The number exists only in findings.md.
  - **Fix:** say "stored ≠ accumulated on 1,731; accumulated = live on all 401 checked (400 sampled plus the mouth, within 3.6e-14), stored = live on none", or wait for the full re-check and quote its file.

- **[fragile] scripts/mad_basin.R:167-210: the "breaks no prior match" guard is one-sided. It cannot see a spurious flip triggered at a stale watershed.**
  - The flip loop runs over every open watershed, including the stale ones: step (4) labels stale only afterwards.
  - Suppose a near-edge polygon's delta happens to fit a stale watershed's gap within `tn`. Its downstream compared segments are then typically all stale too, and therefore already mismatched. So `broke2 = sum(same & !ok2)` stays 0, and the stale segments are relabelled "centroid flipped … (reproduced)".
  - **This run is unaffected.** Each of the 5 flips was triggered at its own polygon (trigger = flip source, with exactly 1 candidate inside tolerance each time). None of the 5 is stale, and no near-edge candidate is itself a stale open watershed (0 of 466).
  - The research sentence "None of the 5 has a stale stored area" (line 84) is true (checked: `stale[flip]` all FALSE), but the script neither prints nor enforces it. For another `WSCODE` the guard would not catch this case.
  - **Fix:** exclude stale watersheds as flip triggers, or print the trigger watershed and stale flag for each flip.

- **[minor, wrong claim] research/fwapg_mad_method.md:84: the evidence placed under "Likely mechanism" partly argues against it, and the grid elimination rests on a check that does not test fwapg's raster.**
  - **Stale areas.** "None of the 5 has a stale stored area" is written as support for "different FWA geometry version". It is evidence against it: the three order-1 sources' upstream area is their own area, and it equals the live polygon to 1e-9. Round 2 noted this; the fix kept the sentence in a supporting position.
  - **Grid.** "So neither the grid nor the sampler is the cause" is argued from a raster rebuilt on the PCIC grid, which is not fwapg's `cdo` → `raster2pgsql` raster, as the text admits.
  - The run holds better evidence for the grid half. A uniform grid offset would flip every centroid on the same side of an edge at a smaller distance. Instead, 84 same-side near-edge centroids closer than 0.431 m match fwapg **unflipped**, 3 of them within 0.02 m. So a uniform offset is refuted.
  - A spatially smooth PROJ field is not refuted: the nearest such counter-example to each flip is 67–152 km away.
  - **Sampler.** I checked this part: PostGIS `ST_WorldToRasterCoord` on the exact grid and terra agree on the cell for all 466 near-edge centroids (the only ones that could differ).

- **[minor, wrong claim] scripts/mad_basin.R:108-110 and 138-139: comments still state as fact the two mechanisms that rounds 1 and 2 had the research text hedge.**
  - Line 108 says fwapg's "raster path carries ~1e-8 relative float noise". The research now says "one of the two raster paths".
  - Line 138 says "Its centroids came from another FWA geometry version or PROJ pipeline". The research now says "likely, not tested".

- **[minor, mismatch] planning/active/findings.md:100: "3.35 GB peak" is from an earlier run.**
  - The run log (`data/basin/100_run.log`) shows 3,214,934,016 B maximum RSS (3.21 GB).
  - The research's "~3.2–3.4 GB across runs" is correct.

## Mechanism enumeration

**Mechanism.** In each case a claim was accepted on a test that establishes a weaker proposition than the one written. The test was:
- **necessary**, as with edge proximity and stale area;
- **one-sided**, a guard that can only fire when something downstream already matched;
- **sampled**, 401 generalised to 1,731;
- **in-sample**, a fitted parameter "reproducing" the watershed it was fitted on;
- **a single column**, mm matched without m³/s.

Or a number was carried from an earlier run or a session check rather than read from the committed run's output. The write-up then states the stronger proposition, or the carried number. Round 3's instances are the sampled→full inference (finding 1), the one-sided guard (finding 2), evidence placed as support that cuts the other way (finding 3), and numbers from outputs that no longer exist or come from earlier runs (findings 1 and 5).

### Cause assignments in `scripts/mad_basin.R`

| # | Cause | Acceptance criterion | Sufficient? | Count vs run |
|---|---|---|---|---|
| 1 | group fwapg never valued (reproduced) | Rebuild with non-`fw_groups` polygons NA (LDEN) makes the segment match on both columns; `broke1` = 0 | **Yes.** A single unfitted hypothesis taken from fwapg's `discharge.sh` group query, reproduced out of sample; LDEN is the only group missing, with 1 polygon | 196 / 102 ✓ report and parquet |
| 2 | centroid flipped to the next cell (reproduced) | Greedy fit of flips (candidate delta within `tn` of the gap), rebuild, segment matches; `broke2` = 0 | **Yes for this run.** 5 flips; each was fitted at its own polygon with a unique candidate. Of 1,197 segments / 751 watersheds, only 8 / 5 are the fitting watersheds (in-sample); 1,189 / 746 reproduce out of sample. The guard is one-sided (finding 2) | 1,197 / 751 ✓ |
| 3 | fwapg segment-to-watershed lookup older (reproduced) | Another watershed on the same `blue_line_key` matches fwapg on **both** mm and m³/s within tolerance | **Yes for value equality.** In fwapg mode, both columns means equal mm and equal implied stored area (to ~3e-7 relative at 18.8 m³/s). "Older" is inferred, but supported: fwapg's implied area equals the current stored table on all 776 stale segments with m³/s ≥ 0.1, so the stored table did not change after the build. 7837044's stored 685.23 km² therefore rules out it having been valued itself, which leaves the lookup | 10 / 1 ✓ |
| 4 | fwapg stored area stale (not reproduced) | Segment's own watershed has stored ≠ accumulated area | **No, and labelled so** (accepted tradeoff). Every compared segment on a stale watershed mismatches (786 of 786, 0 match) | 786 / 502 ✓ |
| 5 | unexplained | remainder | n/a | 0 ✓ |

### Printed summaries (report vs recomputation)

- segments 1,012,100; fwapg 1,002,468; wet 1,011,997; compared 1,002,468: ✓ parquet.
- 99.782 %, 2,189 differ; 69 groups, 56 at 100 %; the five named groups at 100 %: ✓.
- NA cells 6,694 of 21,648 (all NA on every day, r1): ✓.
- "centroids within 1 m of a cell edge: 466": ✓. Printed after the `ok_c` filter, but the filter removes none (466 before and after).
- flip distances 0.020, 0.069, 0.103, 0.117, 0.431 m; groups USHU UFRA NICL LNTH STHM: ✓ (ids 10395424, 8460328, 10099666, 8936758, 8546788; 4 on x edges, 1 on a y edge).
- broke1 = 0, broke2 = 0: ✓ (sufficiency caveat: finding 2).
- cause table: ✓ parquet.
- 9,529 new / 7,720 order ≥ 8 / max order 10: ✓.
- "segments whose mad_mm changes" 786: equals the stale-labelled set ✓.
- Sensitivity: −13.56/+24.11 %, 10.178 %, 29 NA; covered 54 segments, +716 %, LFRA DRIR; coverage 12,723 / 162: ✓ report (54 and 716 recomputed in r1).
- Hope: 2,664 m³/s over 10,957 days, 217,000 km²; segment 701253017 at 146 m; 216,659 km²; 2,476 / 2,477 m³/s; fwapg no value: ✓ report.
- Timing 3.4 min; area sampling 2.1 min; 7.2 s/build: ✓ report and log.

### research/fwapg_mad_method.md: "Join-free upstream accumulation (#2)"

- **fwapg skips order ≥ 8 mainstems:** ✓ `discharge03_wsd.sql` (`order8rivs`).
- **Fixed-width labels ⇒ ltree order = C byte order; two ranges; segment tree:** structural; covered by the tests and the fuzz below.
- **204 irregular polygons (Fraser):** ✓ (`length(unique(irr$id_up))`, with 676,496 pairs). **1,457 province-wide:** from review-round2 (not re-run).
- **1,540 random trees:** 40 in `test-wet_upstream_sums.R` plus 1,500 adversarial trees from code-check round 1 (`adv.R`, 0 mismatches). The provenance is in findings.md:64 ✓.
- **13 s; fetch 1.5 / pairs 1.2 / sums 4.2 s:** ✓ upstream_area_100.txt. **2.1 GB peak:** from an earlier run's log (findings.md:68); no file holds it.
- **1,731 mismatches:** ✓ as stored vs accumulated. **"with the live join"** and **"3.6e-14 … every one checked"**: finding 1.
- **9633006 stored 50,837 m² vs 7949160 stored 12,738,815 m², same code pair (W = L):** ✓ DB. Identical `FWA_Upstream` sets, so the stored areas must be equal; they are not. Sufficient.
- **"Parity … must divide by the stored table, because that is what fwapg did":** ✓ `discharge03_wsd.sql` uses `ua.upstream_area_ha`. Also, the implied area equals the stored table on all 776 stale segments with m³/s ≥ 0.1.

### research/fwapg_mad_method.md: "Fraser parity (#2)"

- **60 files, 24 min:** ✓. The current bbox set (`y120-242_x192-367`) has 60 files, with mtimes 01:21–01:45. A second 60-file set (`y120-243_x192-368`) is also cached but unused.
- **21,648 cells; 6,694 NA outside domain:** ✓.
- **Segments table row, 99.782 %, 56 of 69, 9,529 / 7,720 / 10:** ✓.
- **Runtime 3.4 min, 2.1 min, 7 s; ~3.2–3.4 GB:** ✓ (3.21 GB this run).
- **Tolerance:** 1.8e-8 pass maximum; 5.7e-6 fail minimum; gap 2e-8 to 1e-6: ✓ r1. "Float noise in one of the two raster paths" is hedged, OK.
- **Wrong-turn numbers (findings.md):** 86.6 % after rounding and 22,528 at absolute 1e-5: ✓ recomputed from the parquet (0.8665; 22,528).
- **Centroid-flip row:**
  - 1,197 / 751, 0.020–0.431 m, 466, "breaks … 0", and the order-1 and order-5 source groups: ✓.
  - "None of the 5 stale": ✓, but not script output (finding 2).
  - The mechanism is hedged, but its supporting evidence is misplaced (finding 3).
  - "ST_Value agrees … on all 644,710": not re-run in full. The cell index agrees on all 466 near-edge centroids (r3g.R), which are the only ones where it could differ.
  - "Origin −140, 64; pixel 0.0625": consistent with the subset's GDAL geotransform: xmin −128 = −140 + 192·0.0625, pixel 0.0625, and the coordinate variables are exact doubles.
- **Never-valued row:** LDEN 1 polygon; UEUT 7791959 at 0.4866 × wet: ✓.
- **Lookup row:** LILL 7837044 vs 7608754 on both columns ✓. DB: 7837044 is W = L (upstream 685.23 km²); 7608753/7608754 have localcode `.141581` (648.26 km²). All 34 segments mapped to the three watersheds carry 18.79643.
- **Stale row:** 786 / 502 ✓, labelled "not reproduced" ✓.
- **"1,403 segments shown to be fwapg-side":** 1,197 + 196 + 10 ✓. Sufficient for "not a wet error", given that the sampler and wet's centroid SQL (`ST_Transform(ST_Centroid(geom), 4326)`, the same as `discharge02_load.sql`) are checked.
- **Hope bullets:** ✓ report. **Sensitivity table and bullets:** ✓ report. "Ground outside the PCIC domain" is true by construction: with centroid sampling, cover < 1 only where a centroid sits on an out-of-domain NA cell.

### CLAUDE.md architecture paragraph

- All named functions exist and are exported (`wet_pcic_annual`, `wet_ws_fetch`, `wet_ws_geom`, `wet_upstream_irregular`, `wet_upstream_sums`); `wet_upstream_mean()` calls `wet_upstream_sums()`; `wet_pcic_annual()` uses `wet_runoff_annual()`: ✓.
- `mad_parity.R` calls `wet_upstream_pairs()` (line 100): ✓.
- "Fraser in about 3 min from cache": ✓ (3.4 min).
- "attributes every difference": 786 of 2,189 are labelled by a necessary condition only. The research qualifies this; CLAUDE.md does not. It is a pointer, so no separate finding.
- "Stored upstream area is a stale snapshot": supported by the self-contradicting code pair and the 401 live checks.
