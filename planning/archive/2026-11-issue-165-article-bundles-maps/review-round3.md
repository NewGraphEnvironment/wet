# Code-check round 3: #165 branch (c801b46...ac7cb74)

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms` (table rows skipped), the tails of the last five skimmed. Not read: the 24 H3s under "Rules that stand alone", Security, and Spreadsheets and PDFs.
- code-check-r.md, 4 read: "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"; "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"; "`identical()` on two reader results tests the reader, not the file" (its paragraph on `[` keeping `row.names`); "Regenerated binaries churn git even when nothing changed". 117 not read.
- code-check-spatial.md, 5 read: "Canonicalize geometry before hashing it — ring order and orientation are not fixed by topology"; "`sf::st_as_binary()` returns a LIST of raw vectors, so `is.raw()` on it is FALSE"; "`sf::st_make_valid()` rewrites geometry that was already valid"; "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline, not at the confluence"; "The BC WFS caps an un-paged `GetFeature` at 10,000 features and still answers HTTP 200". 89 not read.
- code-check-shell.md: none read (71 not read). The diff has no shell code.

## Mechanism

**The shared assumption:** a step whose output order or form its contract leaves open was trusted to come back the same, because before `vm_write()` only the content of the result mattered. That covers SQL rows and grouped aggregates with no `ORDER BY`, WFS and SQLite rows, a sort collated by the locale, a PostGIS simplification under GEOS 3.9, and the row names a reorder leaves behind. `vm_write()` compares with `identical()`, which makes row order, row names, ring and vertex order, and the order of named vectors in provenance all part of the output. Rounds 1 and 2 were two cases: rows from a `GROUP BY` with no `ORDER BY`, and names sorted by `order()` in the locale.

**Everywhere it reaches, and whether order or form is fixed** (from reading the code; anything measured is marked):

`scripts/vignette_map_lib.R`
- `vm_stations()`: the HYDAT query has no `ORDER BY`. `match()` fixes the row order. The **row names do not get fixed**: they are SQLite's return positions, and they reach the `stations` layers (finding 2).
- `vm_simplify()`: simplifies in sf's GEOS. Fixed (60 of 60, per the branch).
- `vm_catchments()`: snap ties are broken in R on numeric keys and end on `linear_feature_id`. The character `station_number` in that `order()` only groups the rows, so locale does not matter. `ST_Normalize` comes before the sf simplify. Fixed. One leftover: on a database without fwapg#41, an exact vertex tie inside one stream falls to row order. The second `fwa_indexpoint()` call could then return the other segment and select 0 rows, but `stopifnot(nrow(catch) == nrow(st))` stops loudly. The geometry would not change, because it is cut at the same measure.
- `vm_extent()`: sf union of catchments that are already in a fixed order. Fixed.
- `vm_streams()`: fresh returns segments ordered by id. The R `order()` is on numeric keys. Union, merge and simplify happen in sf, in id order. `gnis_name` is the last name under a radix sort. Fixed.
- `vm_lakes()`: fresh returns lakes ordered by `waterbody_poly_id`, then sf simplifies. Fixed.
- `vm_bc()`: `ST_Union ... ORDER BY bcboundary_id`, `ST_Collect ... ORDER BY` area, xmin and ymin, then `ST_Normalize` and the sf simplify. Fixed. **Measured:** the PostGIS query's WKB md5 was identical in 5 of 5 runs on one connection (GEOS 3.9.0).
- `vm_into()`: uses `max`/`min` aggregates, `ORDER BY up.n`, and `DISTINCT ON` ordered by measure, which is unique within a blue line. The `LIMIT 1` in `system` has no `ORDER BY`, but every row it can choose has the same `wscode_ltree` (main-line rows of one blue line), so the content fixes it. `merge()` sorts on the numeric `n`. Fixed.
- `vm_places()`: radix sort on name, x and y. Fixed. Rows only tie if one name sits twice at the same point, and every caller either removes duplicates or asserts the row count.
- `vm_layers()` provenance: the `postgis_full_version()` string and sf's GEOS. Fixed for a given machine; on this database the string holds no per-session text.
- `vm_compare()` / `vm_write()`: radix sorts, and WKB of normalised geometry. Fixed.

`data-raw/segment_vignette_map.R`
- The pick read: row order does not matter, because the rows go into a temp table that is only joined. Fixed.
- `n_cls`: `ORDER BY 1` (the round-1 fix). The classes are lowercase ASCII starting with different letters, so any collation gives one order. Fixed.
- `rivers`: `ORDER BY order_band, blue_line_key, class`, with the key's uniqueness asserted; the union input is ordered and `ST_Normalize` runs. Fixed. The lines are simplified in PostGIS; that was accepted, at 15 of 15.
- `regions`: `ST_Union(geom ORDER BY watershed_group_code)` then `ST_PointOnSurface`. Fixed. **Measured:** the point and the union's WKB md5 were identical in 3 of 3 runs on one connection. `liard_ws` uses `ORDER BY ... LIMIT 1`, already accepted.
- `zones`: `tapply()` sets factor levels with a locale-collated `sort()`, but on zero-padded two-digit codes, so the content fixes the order. Each zone takes its first feature's name, which follows the order in the file. Fixed.

`data-raw/station_vignette_map.R`
- `towns`: radix (the round-2 fix). Fixed.
- `mouths`: built from `vm_into()`. Fixed.
- `stations`: row names come from `vm_stations()`. Not fixed by contract (finding 2).

`data-raw/monthly_vignette_map.R`
- `stations`: row names. Not fixed by contract (finding 2). Every other layer comes from the lib, as above.

`data-raw/short_record_vignette_map.R`
- `stations`: row names, carried through `cbind()`. Not fixed by contract (finding 2).

`data-raw/chinook_sites_map.R`
- `places`: radix (the round-2 fix). Fixed.
- `clip()`: `st_intersection` and `st_make_valid` on invalid rows only, both in sf, on input in a fixed order. Fixed.
- `maps`: in order of first appearance in the committed values bundle. Fixed.
- `gauges`: `merge()` sorts by the character key with the locale's collation, and the `order()` on line 56 runs on character columns without `method = "radix"`. **Not fixed** (finding 1).

## Findings

- **[severity: fragile]** data-raw/chinook_sites_map.R:54–56 — `gauges` is ordered by `order(gauges$site_id, gauges$role, gauges$station_number)` without `method = "radix"`. Before that, `merge(..., by = "station_number")` sorts rows by the character key with the locale's collation, and the row names it assigns survive line 56's reorder into the compared layer. The committed layer's row names are `1,2,3,9,11,4,7,10,...`, which is merge's order. This is the assumption round 2 fixed for `towns` and `places`, at the next sort in the same script. It is latent today: for the current keys (`maxan`, `swift`, `naver`, `gosnell`; the two role strings; station numbers in digits and capitals), the radix order and the en_US.UTF-8 order are `identical()`. A site id with capitals, an underscore or a space, or a run under another `LC_COLLATE`, would reorder rows or rename them. `vm_compare()` would then report "identical after sorting" and `vm_write()` would rewrite a file whose content has not changed. Fix: `method = "radix"` on line 56, and `rownames(gauges) <- NULL` after the reorder.
  - **Rule:** code-check-r.md "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent" ; code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** scripts/vignette_map_lib.R:24–30 (`vm_stations()`) — the HYDAT query has no `ORDER BY`. `st[match(stations, st$station_number), ]` fixes the row order but keeps the row names `dbGetQuery()` gave in SQLite's return order. `vm_points()` (`st_as_sf`) keeps them, so they reach the compared `stations` layers of all four station-based maps. The committed row names are `2,1` (station_map), `3,1,2` (monthly_map) and `5,1,4,2,3,6,7` (short_record_map), and the chinook gauges inherit theirs through `merge()`. `identical()` in `vm_compare()` compares `row.names`. Today the names repeat only because SQLite walks the `IN` list on the primary-key index, which no contract promises. If they moved, the verdict would be "identical after sorting" and `vm_write()` would rewrite the file. That is the noisy direction, not a silent wrong drawing, but it defeats the branch's claim that "a rerun that changes nothing changes no bytes" for a reason unrelated to the FWA. Fix: `rownames(st) <- NULL` after the `match()` (the next rebuild then changes these layers once, from `2,1` to `1,2` and so on), or `ORDER BY STATION_NUMBER` together with resetting the row names.
  - **Rule:** code-check-r.md "`identical()` on two reader results tests the reader, not the file" ; code-check-r.md "Regenerated binaries churn git even when nothing changed"

Rest of the diff: no other issues found.
- The `read-group` recipe check (its chunk extraction, its environment, its digest gate, the part-by-part read, `by_id`) is sound.
- `vd_receipt()` and the receipt checks in the tests and the article are sound.
- `vm_compare()` and `vm_write()` are sound, including the zones element and a layer present on only one side.
- The Nechako removal leaves no reader behind: none in `vignettes/`, `data-raw/readme_figure.R`, the tests or the README.
- The README links all answer HTTP 200, and `.github/workflows/R-CMD-check.yaml` exists for the new badge.
- `fresh` is used only under `scripts/`, which `.Rbuildignore` excludes.
