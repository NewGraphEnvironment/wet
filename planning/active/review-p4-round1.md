# Review: Phase 4 (`scripts/mad_basin.R`, research write-up), round 1

Verified against `data/basin/100_segments.parquet`, `100_mad_cell.tif`, `100_report.txt` and `100_run.log`, plus light fwapg queries. The scratch R code is in the session scratchpad (`r1.R` to `r14.R`).

## Findings

- **[bug] scripts/mad_basin.R:132-140: the edge test is too weak to support attribution, and it already hides one non-tie-break difference.**
  - `edg > 0` ("any centroid within 1e-3 cell of an edge upstream") is true for 13 % of watersheds but for 36 % of order-4, 79 % of order-5, 99.3 % of order-6 and 100 % of order ≥7 compared segments.
  - For any mid-size or large river that is not stale or downstream of LDEN, the chain can therefore never return `"unexplained"`. A real `wet` regression there would be reported as a tie-break.
  - This already happens in the current run. LILL watershed 7837044 (10 segments, order 6) is labelled tie-break, but no edge flip explains it:
    - fwapg gives 914.3964 mm and 18.79643 m³/s; wet gives 908.6331 mm and 19.74328 m³/s (−4.8 % in m³/s).
    - fwapg's implied denominator, `mad_m3s·31,536e6/mad_mm`, is 648.26 km². The stored and accumulated area are both 685.23 km².
    - fwapg's values on these 10 segments equal, to the last digit, those of watersheds 7608753/7608754 on the same stream (localcode `…415280.141581`, stored area 648.26 km²).
    - So fwapg's build-time stream-to-watershed lookup mapped these segments to a different watershed. That is a different kind of fwapg staleness, not a cell tie.
    - It is the only segment set of the 172,397 with m³/s ≥ 0.1 whose implied denominator disagrees with the stored table.
  - **Suggested fix:** attribute flips quantitatively. Take the numerator gap `D = (mad_mm − wet_mm)·stored_area`. Flag an edge polygon as flipped only when its own `area·(v_neighbour − v)` accounts for the gap. Accumulate the flipped deltas with `wet_upstream_sums()` and require the residual to sit within tolerance before assigning the label.
  - Done by hand, that method explains 751 of the 752 edge-labelled watersheds exactly with 5 flipped polygons, and leaves only LILL 7837044.
  - The same necessary-condition weakness applies to `"fwapg polygons stale"`. Its segment set equals exactly the 786 segments where stored ≠ accumulated area, but the gap was never checked against size: the m³/s gap is 0.95–5.1 × `(stored − acc)·mean mm`.
  - By contrast, `"upstream group fwapg never valued"` checks out exactly: after removing LDEN ground the residual is ≤ 5.0e-6 mm on all 196 segments.

- **[bug: wrong claim] research/fwapg_mad_method.md:78, 82: the mechanism and counts in the tie-break row are wrong.**
  - **Not a tie-break.** None of the flipped centroids lies on a cell edge. The 5 that flipped are 2.9e-6 to 9.8e-5 cell from an edge (about 1 cm to 0.6 m). Many centroids closer to an edge did not flip, for example:
    - 9305214 at 2.8e-7 cell, with a 115 mm neighbour difference;
    - 7797755 at 1.2e-6 cell, with 333 mm.

    The x-edge flips all lie in columns 127–146 and all sit on the same side of the edge (fx small and positive). That pattern fits a small georeferencing difference between fwapg's full-domain raster (cdo, then raster2pgsql) and the OPeNDAP subset terra reads, growing eastward. It does not fit terra and ST_Value breaking a tie differently. The script comment at lines 128–131 makes the same claim.
  - **5 sources, not 3.** Besides the 3 order-1 sources (NICL 10099666, UFRA 8460328, USHU 10395424; each checked, fwapg's value equals the neighbouring cell's), two order-5 edge polygons also flipped: LNTH 8936758 and STHM 8546788. They account for 73 of the 752 labelled watersheds, which the text leaves unexplained. "679 downstream of those 3" is correct.
  - **Counts.** The row's 1,207 segments / 752 watersheds include LILL 7837044 (10 segments / 1 watershed), which is fwapg lookup staleness, not an edge flip.
  - **"None is a `wet` error."** After the checks above this holds, but the script does not prove it: it assigns labels from necessary conditions only. The text should say the attribution was verified by hand, and how.

- **[bug: wrong claim] research/fwapg_mad_method.md:98: "Covered denominator changes nothing measurable" is false.**
  - The script's own report shows `centroid / covered |change|>5%: 0.005%`.
  - Recomputed: 5,239 segments have centroid coverage < 1 (73 polygons have centroids on NA cells). 54 segments change by more than 5 % (DRIR 26, LFRA 28), up to +716 % in m³/s.
  - The 1st–99th percentile is 0, but the tail is not negligible. That is exactly what the covered denominator is meant to change.

- **[fragile] scripts/mad_basin.R:59-60, 120-122, 139, 158: NA cells are called "missing days", but they are out of domain.**
  - All 6,694 NA cells are NA on every day. Checked on the cached 1981 RUNOFF file: NA on any day = NA on all days = 6,694.
  - So the report line "cells NA here (any missing day): 6694" misdescribes them.
  - The `"upstream cell NA here (missing days)"` branch would put a benign "cdo averages the days it has" label on any mismatch among the 5,239 segments downstream of an out-of-domain centroid, where fwapg is also NULL. It fires on 0 segments today.

- **[fragile, minor] research/fwapg_mad_method.md:76, 86; scripts/mad_basin.R:57: numbers the run does not reproduce.**
  - **Memory.** The write-up gives "3.4 GB peak", but `100_run.log` for this 3.2-min run shows 3.07 GB maximum RSS (peak footprint 1.12 GB).
  - **Noise source.** "fwapg's raster path carries about 1e-8 relative float noise" blames fwapg without evidence. The observed maximum is 1.8e-8, and it could equally come from wet's read.
  - **Saved raster.** `writeRaster` uses the default FLT4S, so `100_mad_cell.tif` holds float32 values (max 4888.430176). Any parity rerun from the saved tif carries about 6e-8 relative extra error, close to the 1e-7 tolerance. The reported numbers use the in-memory double raster, so they are unaffected.

## Checked and fine

- **Tolerance `5e-6 + 1e-7·|x|`: justified, and it hides nothing.** 131,661 segments pass only through the relative term. Their excess over half a unit is at most 1.81e-8 relative (median 2e-9). The failing segments start at 5.67e-6 relative excess. No compared segment lies between 2e-8 and 1e-6, so any tolerance in that gap gives the same 99.782 %.
- **Joins.** `linear_feature_id` is unique in `seg`, so the lookup join does not duplicate rows. The `match()` into `ws` has no NA among fwapg-valued segments (compared = 1,002,468 = fwapg-valued). The sensitivity baselines are consistent.
- **Group list.** The `fw_groups` query reproduces fwapg's `discharge.sh` WSGS exactly (100/200/300 assessment watersheds). LDEN is the only missing group, with 1 polygon.
- **Grid.** The edge geometry matches terra's grid: xmin −128 and ymin 48.5625 are multiples of 0.0625, so the subset is aligned. The mismatch is with fwapg's grid (see above).
- **Hope check.** `postgisftw.fwa_indexpoint(x, y, srid int, tolerance float8, num_features int)` matches its signature. HYDAT covers 10,957 of 10,957 days. The −7 % figure checks out: 2,476 against 2,664.
- **Figures that reproduce.** UEUT 7791959 ratio 0.4865 ("0.49"). 99.782 %, 56/69 groups, 9,529 / 7,720 / order 10, cause counts 786/1,207/196 and 502/752/102, 12,723 / 162 coverage, 29 NA: all match `100_report.txt`.
