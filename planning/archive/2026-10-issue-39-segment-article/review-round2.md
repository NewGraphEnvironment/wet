# Code-check round 2 (#39) — staged diff, data-raw/segment_vignette_{data,map}.R

## Findings

- **[severity: bug]** data-raw/segment_vignette_map.R:87-91 (context_streams query): the
  `edge_type IN (1000, 1100, 2000, 2300)` filter drops every large river in the SALR context
  box, so the layer cannot do what the header says ("so a gauge off the group sits on its
  river"). Double-line rivers carry their flow line as edge_type 1250 ("Construction line,
  double line river, main flow"), lake reaches as 1200, wetland reaches as 1050, connections as
  1450. Measured against fwapg with the shipped box (1064272 973952 1242738 1178867): of the
  order >= 6 network outside SALR, order 7 is only 1200/1250/1450 (Stuart, Nation, Crooked,
  Parsnip, Salmon, Stellako: ~715 km), order 8 is 1250/1200/1450 (Fraser, Nechako, Pack:
  ~362 km) and order 9 is 1250/1475 (Fraser), so none of it survives. The shipped
  segment_map.rds confirms it: context_streams is 462 features, **all stream_order 6**, 221 km
  in total, broken wherever an order-6 stream runs through a wetland (1050, 77 km), a lake
  (1200, 115 km) or a double-line reach (1250, 534 km). Four of the five gauges in
  gauges_salr sit on rivers the layer omits (07ED001 Nation, 08JE001 Stuart, 08KC001 Salmon
  near Prince George — the outlet gauge — and 08JE004 Tsilcoh, a 1050/1250 stream). The
  `nrow(context_streams) > 0` check passes on the fragments, so nothing fails. Fix: include
  the main-flow types (at least 1000, 1050, 1200, 1250, plus 2000), or select by
  `edge_type NOT IN` the bank/shoreline/boundary codes.

- **[severity: fragile]** data-raw/segment_vignette_map.R:92-96 (context_lakes query): simplify
  at 200 m plus 1 m snap produces invalid polygons, and nothing checks. In the shipped rds 3 of
  18 context_lakes are invalid, "Hole lies outside shell" (Inzana, François, Trembleur lakes).
  Drawn by geom_sf the stray hole renders as an extra filled patch, and any GEOS operation on
  the layer in the vignette (st_crop/st_intersection to the box, st_union) raises a
  TopologyException. The `coverage` query (simplify 4 km, snap 100 m) has the same exposure;
  it is valid today but unchecked. `zones` is the only layer with a validity repair. Wrap the
  SQL geometry in ST_MakeValid (then ST_CollectionExtract(…, 3)) or repair in R, and assert
  `all(sf::st_is_valid(.))` for context_lakes and coverage as zones does.

## Checked and found sound

- Zone pipeline, re-run in a scratch session on data/hydz/bc_hydrologic_zones.zip: all 29
  codes come out, none dropped, all MULTIPOLYGON, all valid, EPSG 3005; area after
  clip/simplify/round is 0.982-1.023 of the clipped source per zone; codes `%02d` match the
  `z%02d` columns the calibration stations' `zone` comes from (scripts/wb_province.R:186);
  `st_as_binary(precision = 0.01)` is round(x*0.01)/0.01, i.e. 100 m, as the comment says.
  Ten zones needed make_valid after rounding and all recovered. The only noise is an
  "x is already of type POLYGON" warning from st_collection_extract per zone (harmless).
- Zone 28's names: feature order gives "EASTERN VANCOUVER ISLAND" (feature 19) ahead of
  "WESTERN SOUTH COAST MOUNTAINS" (feature 36, which duplicates zone 27's name), so `[`, 1
  picks the right one for this zip; order-dependent but deterministic for the cached file.
- Coverage outline vs fwapg_groups: same rule (group has count(mad_mm) > 0). For all 309
  accepted stations (superset of the 290), in_pcic by watershed group and point-in-outline
  agree exactly (202/107, no disagreements), so the 4 km simplification moves no gauge across
  the boundary.
- Places: frames BULK and SALR's context box are disjoint; bbox query small; group
  assignment correct in the shipped rds (5 SALR-frame, 4 BULK).
- Data script: linear_feature_id is numeric in data/wb/stations.rds (max 868,144,457), so
  as.integer is exact; no integer64. fw_sk filters NULL mad_mm before the duplicate check;
  the five near gauges all had values in the prior build, so `!anyNA(near$fwapg_mm)` holds.
  No zero mad_m3s_fwapg in SALR_parity.csv, so max_rel_diff is finite.
