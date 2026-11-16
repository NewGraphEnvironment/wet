# Code check, round 2 (branch 165, `git diff c801b46...HEAD`)

## Checklist read

- **code-check.md** (38 H3): read the prose of every H3 under `## Mechanisms` (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice), table rows skipped. Standalone and security sections: index lines only. About 24 not read in full.
- **code-check-r.md** (121 H3): read Postgres row order is never fixed unless the query fixes it...; `sort()` and `order()` collate by `LC_COLLATE`...; Regenerated binaries churn git even when nothing changed; `identical()` on two reader results tests the reader, not the file; `normalizePath()` renames through a symlink...; plus the index lines of A database driver's value is not a base R type; `$` on a list partial-matches; A data-raw/ script must load the source tree. About 115 not read in full.
- **code-check-shell.md** (71 H3): none read in full (no shell code in the diff); 71 not read.
- **code-check-spatial.md** (94 H3): index lines of Canonicalize geometry before hashing it; `sf::st_as_binary()` returns a LIST; `sf::st_make_valid()` rewrites geometry that was already valid; `sf::st_read()` promotes a mixed POLYGON/MULTIPOLYGON layer; A GDAL failure partway through `sf::st_read()`; The BC WFS caps an un-paged `GetFeature` at 10,000 features; bcdata: `filter()` translates the calls inside it; FWA main flow is not edge type 1000 alone. About 94 not read in full.

## Probes run (read-only)

- Round 1's fix: `n_cls` now `GROUP BY 1 ORDER BY 1` on three distinct ASCII class names, so `drawn`'s element order is fixed. The committed `segment_map.rds` carries `drawn` as none, pcic_routed, wet_balance.
- fresh 0.53.0: `frs_stream_fetch()` and `frs_lake_fetch()` end in `ORDER BY linear_feature_id` / `waterbody_poly_id`; lakes come back unsimplified (no `simplify_m`), and `fwa_lakes_poly` is 2-D MULTIPOLYGON, so no Z reaches `vm_simplify()`.
- `vm_streams()` types: `linear_feature_id` arrives as integer64, `blue_line_key` and `stream_order` as integer. A shuffled fetch re-ordered by `order(blue_line_key, linear_feature_id)` gives back fresh's order exactly (bit64's `xtfrm` is used), so the per-key union input is fixed.
- `fwa_watershedatmeasure()` (catchments) collects its pieces through a `UNION` and `ST_Buffer(ST_Collect(...))` with no order. Called 6 times in one session for Buck Creek, it gave one `md5(ST_AsBinary(ST_Normalize(...)))` (6,880 points), so in this database the catchment did not vary.
- `fwa_bcboundary.bcboundary_id` is unique (28,001 of 28,001), so `ST_Union(geom ORDER BY bcboundary_id)` is a total order. An aggregate with `ORDER BY` also can't be run as a parallel partial aggregate.
- `liard_ws` (`ORDER BY downstream_route_measure LIMIT 1`): exactly one 'Liard River' row has the minimum measure, so there is no tie.
- `vm_places()` sorts on name, then x and y (radix). A tie that survives (same name, same point) can only be two rows that are identical in name, feature_type and geom, so the order is invisible in the layer.
- No reader of the removed Nechako region is left (Rmd, data-raw, tests).
- The `read-group` chunk parse (`to` index), the recipe's `rec_env$cat` and `rec_env$duck`, the `own` read and `by_id()`: sound, as round 1 found.

## Considered, not findings

- `data-raw/chinook_sites_map.R:89` and `data-raw/station_vignette_map.R:65` sort places with a bare `order(name, ...)`, which collates by `LC_COLLATE`, and the order reaches a layer that `vm_write()` compares. These lines predate the branch. For the names in use (Houston, Smithers, Topley, Hixon, McBride, Prince George, Quesnel, Valemount, Hazelton), C and en_US give the same order, so nothing fails today. A future place name that differs only by case or punctuation could make a run under another locale rewrite the file. That rewrite would be shown as "identical after sorting", so it can't go unnoticed.
- `WET_MAP_OUT_DIR` set to an empty string resolves to `/` and fails loudly on permissions. That is not data loss.

## Clean

No issues found.
