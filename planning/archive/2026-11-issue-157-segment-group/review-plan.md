# Plan review — #157 (Plan agent, 2026-11-04, read-only, against HEAD 8ad7d6b)

Findings as returned, with what the plan did about each.

## Blocker

- **B1. One part per drainage, 54 groups span several.** LFRA's polygons lie under `100, 900, 905, 970`; the publish writes one part per top-level code for both datasets (`discharge_publish.R:300-301, 325-326`). → Phase 2 reads every part whose `code` is among the closure's drainage codes; `wet_ws_closure()` carries a `codes` attribute.
- **B2. Watershed rows with NA `q_m3s` are dropped by the publish** (`discharge_publish.R:334-336`), kept by `wb_output.R`. → The group build drops and counts them before comparing.

## Gap

- **G1. Reread-during-publish hazard.** Parts can change under a publish; the vignette data scripts verify before and after. `vd_published()` refuses until the next BUILD writes #117's digests. → `wet:::wet_catalog_verify()` on the parts read, before and after.
- **G2. Two reads where one serves.** → One duckdb query over both sources' parts for the group's codes, `hive_partitioning = true`.
- **G3. Fit-currency guard missing.** → The script applies `segment_output.R:69-73`'s guards and prints `code_md5`, `aet`, `share_method`.
- **G4. The crop extent SQL lives outside `sample_group()`** (`wb_province.R:181-186`); the zone list depends on it. → Included verbatim.
- **G5. Sample parity should degrade, not refuse** (terra/GDAL upgrades since the run). → `identical()`, else max difference per column, reported.
- **G6. Zone columns are a subset in another order**; values unaffected. → Said in the script; no zone column written.

## Ordering

- **O1. The exported sampler is the weakest piece.** → Kept as a script-local copy; the package extraction goes with the fold-in owed at the next province run.
- **O2. One run per group**, resample then proceed with the province samples. → Taken.

## Assumption

- **A1. The closure claim is correct** (both `FWA_Upstream` branches need `Wb` under `Wa`; the irregular join is on `@>`; per-root pair sets cover the closure and do not overlap; only association differs). → Test uses `expect_equal`.
- **A2. 1e-9 relative is safe except at a donor near-tie** (`wet_donor_mean()` orders by distance; a last-bit move can flip the k-th donor). → Rows beyond tolerance are listed and attributed, not hidden.
- **A3. The code-hash constraint is real but deferred** for `code_files` (next province run), immediate for `score_files`; the count is 13 `R/` files, not 14. → Corrected.
- **A4. The rerun owed before the next publish already exists** (21 files since 28105a3).
- **A5. A segment's own group equals its lut watershed's group** (0 differ), so filtering on either coincides.
- **A6. Publishing the fit is not "one object"**: the manifest lists `part-<code>.parquet` keys only. → Named in the follow-up issue.

## Scope

- **S1.** Deferring the fit's publication is defensible; the plan says how the issue closes.
- **S2.** `research/segment_group.md` states honestly what the build buys and does not.

## Acceptance

- Pure-R closure test with irregular codes and `brute_upstream()` pairs filtered to the closure's `id_up`, `expect_equal`.
- Live test: basin `925` (three groups: VICT, COWN, PARK) for the sums identity, BULK for the groups spanned.
- Report columns per comparison: compared, differing, `max_abs_diff`, NA rows dropped, drainage codes read, manifest build and verify results, fit identity, sample parity.
- The deliberate break removes MORR from `wet_ws_closure()`'s result, not from the sample list, so the irregular "no pairs" check cannot mask the comparison.
