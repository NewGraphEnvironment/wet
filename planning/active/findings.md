# Findings — Segment-discharge vignette: lead with the published product and read it from the manifest (#64)

## Issue context

**If we do it:** the segment-discharge article becomes the page that introduces the published product: what the table holds, where to get it, how to load it, what was done to make it, and how its numbers line up against the gauges, with every number read from the published copy. Accuracy, not advice. **If we never do:** the public page for the product never says where the data is, its numbers come from a one-off `.rds` that nothing checks against the published parts, and readers wade through a parity check, map-labelling code and guidance prose to reach the numbers.

## Problem

`vignettes/segment-discharge.Rmd` (880 lines, six sections) predates the publish in #7:

- **It never reads the published product.** It reads `inst/vignette-data/segment_values.rds`, built on 2026-10-11 by `data-raw/segment_vignette_data.R` from the fit outputs and fwapg's tables. Nothing in it reads the manifest (`https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`), the parquet parts or `discharge.fwa_v1_segment_monthly`. The inputs are the same as the product's, but nothing checks the vignette's values against the published ones.
- **It never says where the data is**, or how to get it (`wet_catalog()`, `wet_db_load()`, `month = 0 AND pick`).
- **It buries the point.** "How it is built" opens with wet's match to fwapg's old unrouted annual table on the Salmon River (to five decimals), then a centroid-versus-area sampling scatter. Both are checks on wet's code, not on the product, and they read as unexplained to anyone who did not do that work. Much of the source is label placement and frame guards for two worked-basin maps.

## Proposal

1. **Lead with the product:** what `segment_monthly` and `watershed_monthly` hold, the two sources (`pcic_routed`, `wet_balance`), what `pick` means, the manifest URL, and a short read example with `wet_catalog()` and `wet_db_load()` (and plain arrow or duckdb on the URLs).
2. **Read the vignette's segment values from the published parts** through `wet_catalog()`, in `data-raw/segment_vignette_data.R`. At minimum, refuse to build when the bundled values differ from the published rows for the same segments.
3. **Check the published values against their sources, value by value.** `scripts/discharge_publish.R`'s cross-checks today compare row and `pick` counts only (`routed_rows`, `balance_rows`, `picked_routed`, `picked_balance`, `hive_read` in `data/checks/discharge_publish_20260717.txt`), never a flow value. The counts do line up: the published `pcic_routed` rows, 43,901,481, are fwapg's 3,377,037 segments × 13 months (0–12), against the 40,524,444 rows (× 12 months) in `whse_basemapping.fwa_stream_networks_discharge_monthly`. Add, in BUILD:
   - `pcic_routed`, months 1–12: every `q_m3s` equals fwapg's `fwa_stream_networks_discharge_monthly` value for the same segment and month (within storage precision), and the total equals the report's table fingerprint (178,035,348.248310 m³/s).
   - `pcic_routed`, month 0: equals the annual value the segment table derives from those months.
   - `wet_balance`: every value equals the shipped fit's `output/` (and the #57 segment table) for the same segment and month.
   - The vignette's `segment_values.rds` values equal the published rows for the same segments; the vignette build refuses otherwise.
   Report the count compared, the count differing and the largest difference for each, so a mismatch is attributed rather than averaged away.
4. **Show what was done and how the numbers line up, not advice.** For each source, a short statement of how it was made (routed PCIC placed on the FWA by fwapg's crosswalk; the open balance fitted and held out at the gauges), then the accuracy: held-out error against HYDAT at the gauges, both sources on the gauges both cover, with plain numbers (bias, spread, share within a band). Cut the strengths-and-limits table and the "which to use" guidance down to the one fact a reader needs: what `pick` selects. At most one worked basin.
5. **Move the fwapg parity match and the sampling plot** to `research/` (or one short "Validation" paragraph that links there).
6. **Drop the code the shorter page no longer needs.**

## Done when

- The article's first screen names the product, its URL and how to load it.
- Every segment value it shows traces to the published manifest's build commit, and the build refuses a mismatch.
- The publish report carries value-level cross-checks against fwapg's routed table and the fit's output, each with compared / differing / largest difference.
- The fwapg parity and sampling material is out of the main flow.
- The page states how each source was made and how it scores at the gauges, and carries no recommendation prose beyond what `pick` does.

Relates to #7, #28, #39, #42.



## Exploration (2026-10-13, plan mode)

- Published manifest (built 2026-10-13T03:28:20Z, wet 7c62b9e, segment table 653fc13): segment parts total about 1.3 GB, of which parts 100 and 400 for both sources are 335 MB. That is why the vignette data reads with httpfs and row-group pruning rather than downloading whole parts.
- On m1, duckdb 1.5.2 has httpfs installed and postgres_scanner absent.
- Routed month 0 in the segment table is R `aggregate(mean)` over the 12 months (`scripts/segment_output.R:154`). The vignette's `routed_annual()` (`scripts/pcic_routed_lib.R:39`) is SQL `avg` with `count = 12`. They should agree to floating-point precision.
- The publish tree on m4 lived in a worktree that has since been removed (`wet-7-upload`), so the rebuild needs a fresh worktree with `data/wb` linked (memory note `m4_discharge_publish_state`).
- BUILD took about 5 min on m4 (#7 archive, `progress.md`: 14:35–14:40 UTC).
- `research/fwapg_mad_method.md` already holds the SALR parity and sampling sections. Its line 19 points at the vignette for the worked version.

## Errors Encountered

| Error | Resolution |
|-------|------------|

## Plan review (Plan agent, 2026-10-13), and what was done with each finding

- **B1 (confirmed by reproduction):** `data.frame(<0-length>, month = 0L, ...)` errors, and codes 800, 945 and 990 have no routed part. The first m4 run was stopped before it reached them. Fixed with `rep(0L, nrow(s12))`, and a missing part now reads as an empty frame of the requested columns.
- **G1:** the segment parts are now compared with the segment table on `q_m3s`, `runoff_mm`, `coverage` and `pick`, each its own report row.
- **G2:** the watershed parts are compared with the fit's `output/`.
- **A2:** the report carries the arrow and duckdb versions.
- **A3:** values copied from a double are compared with `tol = 0`; only the two means of twelve months use 1e-9.
- **A5:** checked on m1: 0 lut ids missing from `fwa_stream_networks_sp`, and the lut has one row per segment (4,538,224). The lut join re-does the segment table's join, so it catches indexing errors, not lut errors. The wording says so.
- **G3, G6:** already met by the Phase 2 code as written: NA source rows dropped, `month = 0L` added, compared before rounding, and `routed_mm` from published `q_m3s`.
- **To do in Phase 2:** G4 (require compared = the expected count), G5 (gauge groups from `fwa_stream_networks_sp`), G11 (bundle the catalog's key, rows, bytes and md5), O3 (refuse unless the committed publish report has no FAIL and its parts are identical to the live build), A1 (read only the parts needed, and measure).
- **To do in Phase 3/4:** G7 (palette: keep `parity/one_to_one`, drop `parity/segment`, `skill_nesting/mae`, `product`, `segment_map/key`; small-streams limit without `sampling`; the limits chunk keeps the keep_adjust, gate and pooled asserts; the no-watershed bullet guarded; `ex` out of the named guard; SALR-only wording in the captions and the CSV label; dead code from the table), G8 (one sentence each: the product's balance is the all-gauge fit while the scores are held out; PCIC's may be partly in sample, and the periods differ), G9 (rows exist only where a source has a value; watershed_monthly is balance only; the periods by source; duckdb needs httpfs and `hive_partitioning`), G10 (`README.md:46`, NEWS line, `research/discharge_publish.md` status line), AC1 (cite the published build and the report commit), AC3 (assert the URL).

## The value-checked BUILD (m4, 2026-10-13)

`data/checks/discharge_publish_20260717.txt` at 032242f: every check is ok. 40,524,444 routed monthly values equal fwapg's exactly. 3,377,037 routed annual values equal the mean of their months within 9.09e-13. 58,889,207 balance values equal the fit's output through the lut exactly. 102,790,688 segment rows equal the segment table on `q_m3s`, `runoff_mm`, `coverage` and `pick`. 41,904,356 watershed rows equal `output/`. All 67 parts are md5-identical to the live 7c62b9e upload.

The BUILD prints a tidyselect deprecation for `read_parquet(col_select = <character vector>)`. It is cosmetic. It is left as is so that the report's commit (032242f) is the code that wrote it.
