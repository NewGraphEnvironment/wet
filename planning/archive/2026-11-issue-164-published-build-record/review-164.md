# Plan review — #164 (Plan agent, spawned 2026-11-15 19:37Z, delivered while Phase 3 was uncommitted)

Condensed from the reviewer's reply; disposition in brackets. Probed: B1 (replayed the BUILD's code check: `R/wet_segment_daily.R` trips it) and G2 (a row subset keeps `fit`) reproduce.

## Blockers
- B1. BUILD's "code changed" checks (discharge_publish.R:201-212, 242-246) trip on Phase 1's `R/wet_segment_daily.R` and would on `scripts/segment_group.R`. [fix: add both to `publish_own`; both are readers no table script calls]
- B2. PUBLISH's skip/upload loop indexes `cat_local` rows; fit/receipt would keep local hrefs, verify ok, never upload. [fix: separate loop over `wet_catalog_files()` minus parts, hrefs rewritten, uploaded before the manifest]
- B3. `publish_report_live()` checks `setequal(verified$key, cat_pub$key)`. [fix: verify all files, pass the parts' rows to it; fit/receipt verified anonymously before it]
- B4. `fit/` parquet listed as parts. [already fixed in Phase 3]

## Gaps
- G1. Digest over the receipt would move every BUILD. [already decided: digest parts-only; fit and receipt get their own BUILD line, recipe_id names the receipt]
- G2. Row subsets keep attributes; the comment above `wet_catalog_files()` is wrong. [fix comment; `wet_catalog_verify()` stays over the rows it is given]
- G3. Inputs one id each; fit as one version_id string; name the daily fingerprint; `shape_daily.rds` covered by the fit only implicitly. [document in the yaml]
- G4. dirty check lacks `inst/receipt`; crate needs a 40-char commit. [fix]
- G5. segment_group.R published mode: wb_key_dir(), fit_dir, aet_winner.txt, out_dir, layers for unsampled groups, WET_WB_RESAMPLE; both modes write one report. [fix all; separate report path]
- G6. `wet_part_fetch()` builds its path from `dataset`. [give fit rows a dataset of `<id>/fit`]
- G7. Keep the shared fixture receipt-free. [already so]

## Ordering
- O1. fit files → receipt → manifest.pending → checks → rename. [as built]
- O2. PUBLISH: parts → fit → receipt (no-cache) → manifest → stale delete with fit/receipt kept → verify all. [fix]
- O3. Three passes over 33 GB. [record time]

## Assumptions
- A1. Byte identity needs arrow 25.0.1, duckdb 1.5.6, crate 0.16.0 release on m4. [probe before BUILD]
- A2. Reloading m4's `discharge` rewrites the comment link reads. [Phase 5 loads into a throwaway schema instead]
- A3. Prove an older wet reads the new manifest with wet 0.4.35 installed. [m1 has 0.4.30 installed: run it there]
- A4. The fit entry carries no attribution for climr/CGIAR/ERA5-Land. [add `description` and `citation` to the fit entry]

## Scope
- S1. Departure reports' digest already stale (0f4f8caa vs live d554e3); not new. [note]
- S2. #164 body names `R/wet_manifest_write.R` and crate in Imports. [fix in Phase 5 body edits]

## Acceptance
- AC1. Failed-load test fails before the record; move record before the checks and assert it in the picked-rows test. [fix]
- AC2. Comment test is a regex; make it exact. [fix]
- AC3. "Identical" via crt_receipt_compare. [as built]
- AC4. Run published mode from a checkout with no data/wb. [Phase 5]
- AC5. Keep the live line's format; fit/receipt as separate BUILD-time lines. [as planned]
