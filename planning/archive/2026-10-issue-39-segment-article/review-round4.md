# Code-check round 4 (#39): staged diff, data-raw/segment_vignette_{data,map}.R, test-vignette_data.R

Probes run on 2026-10-06 against the local fwapg, the working-tree `inst/vignette-data/segment_map.rds`
(built from the staged map script), the committed `segment_values.rds` (old build) and
`data/wb/stations.rds` (309 accepted gauges, a superset of the 290). Nothing in the repo was edited.
Scratch probe: `$TMPDIR/.../scratchpad/p4.R`.

## (a) The round-3 fixes themselves

- **cov_share rule.** The R rule (`n_values >= 0.5 * n_rows`, data.R:125) and the SQL rule
  (`HAVING count(mad_mm) >= 0.500000 * count(*)`, map.R:124) are the same expression and select the
  same 112 of 150 discharge groups. The discharge table's `watershed_group_code` agrees with
  `fwa_stream_networks_sp` on every row (0 mismatches), so grouping by either is the same.
  Groups below 1 and at or above 0.5: MILL 0.774 and LFRA 0.964. Below 0.5 with any value:
  the 11 Liard groups (FONT through USIK, 0.000 to 0.236).
  - For all 309 accepted gauges, `in_pcic` matches point-in-outline in **both** directions:
    198/0 and 0/111. The only gauge outside coverage that has a value is 10CB001 (USIK).
  - In-coverage gauges fall in HYDAT regions 07E, 07F, 08J, 08K, 08L, 08M and 08N: Peace, Fraser and
    Columbia, and nothing else. Under the rejected count > 0 rule, four 10C gauges join them.
  - Coverage area: 463,209 km² (506,496 under the old rule, a difference of 43,288 km², as round 3 said).
- **gauge_blk.** `stations.rds` has no NA `linear_feature_id` among accepted gauges, and the numeric
  ids paste exactly (max about 8.7e8). `stations.rds` is part of the m1 bundle (memory note), so the
  map script runs there.
  - The built layer holds orders 1 to 9: 597 features below order 6, which are the gauges' own blue
    lines.
  - Distance from each `gauges_salr` gauge to its nearest drawn line:

    | gauge | distance |
    |---|---|
    | 07ED001 | 65 m |
    | 08JE001 | 29 m |
    | 08JE004 | 86 m |
    | 08KC001 | 37 m |
    | 08KC003 | **184 m** |

    08KC003 is 184 m because of its 147 m HYDAT snap distance plus the 100 m simplify. That leaves 16 m
    of margin under the test's 200 m, and a breach would fail loudly, so this is a note, not a defect.
  - All 12 accepted gauges in the box are within 200 m of a drawn line (08KB001 is 172 m).
- **fwapg_mm.** Looking fwapg up by the gauge's **watershed** (fw_sk) gives the same answer as
  looking it up by the gauge's own **segment** (the new `linear_feature_id`):
  - It has a value at 180 of the 309 accepted gauges and at 0 of the others.
  - Where both have a value, 0 differ.
  - No watershed borrows a tributary's value for a mainstem that has no row.
- **Budget.** Old values plus the new map come to 522,692 B, over the 512,000 B test limit. The
  rebuilt values replace the 9,000-row parity frame with one row. Simulating that brings values to
  175 KB, about 467 KB in all, so the test passes after the rebuild.

## (b) Every layer and derived value: purpose, and whether a guard checks it

| item | purpose | guard (script / test) | checks purpose? |
|---|---|---|---|
| segments | order >= 3 segments of SALR and BULK, joined to values by id | per-group count = source, unique, non-empty (map.R:65); test: id set = values' ids | yes |
| groups | the two outlines, with true area | setequal codes; validity | yes (area is pre-simplify by construction) |
| lakes | lakes of at least 100 ha as a backdrop | validity; test nrow > 0 | existence only; it is a backdrop, so the threshold is a content choice |
| places | towns that orient BULK and SALR's context | unique names; setequal frames | existence; content checked in round 3 |
| context | the box holding gauges_salr | test: every gauges_salr point is `st_within` it | yes |
| context_streams | each gauge off SALR sits on a drawn river | script: nrow > 0, gauge_blk non-empty; test: each gauges_salr point within 200 m of SALR segments or context_streams | yes (in the test); 16 m margin |
| context_lakes | lakes of at least 1,000 ha in the box | validity, nrow > 0 | existence; round 3 measured that lake-arm reaches lie inside them |
| coverage | where fwapg is scored, the same set as `in_pcic` | test: every in_pcic gauge is inside it | **half**: subset only. Nothing checks the reverse or the domain. Finding 1 |
| zones | the zones the fit adjusts by, keyed by the stations' code | unique, non-empty, valid; test: every skill zone is drawn | yes |
| fw_sk / fwapg_mm | fwapg's value at the gauge | per-watershed uniqueness; test: > 0, and more than 75 % of in_pcic gauges have one | yes; probe agrees with the per-segment lookup |
| fwapg_groups / in_pcic | the groups fwapg is scored in | data.R:193 holds by construction; test thresholds of 0.75 and < 5 | **no**: both thresholds pass under round 3's rejected rule. Finding 1 |
| fwapg_cov_rows | rows and values in covered groups | test checks the name only | by construction; nothing to guard |
| fwapg_max_order | the highest order with a value against the highest order in coverage | test checks the name only | **no**: the two scopes differ and nothing asserts the ordering. Finding 2 |
| outlet | smallest gauge holding at least 99 % of SALR | length == 1; test: sum(holds_salr) == 1 | yes |
| near / gauges_salr | the gauges that arbitrate on SALR | `!anyNA(fwapg_mm)`; `nrow > 0` (vacuous, since the outlet is always in); test: lon/lat/fwapg present, in context, on a river | yes |
| parity | summary of wet against fwapg on SALR | nrow == n_fwapg; n_match5 == n; test repeats both | yes |
| n_fwapg | discharge rows per group | equality with the parity nrow | yes |
| sampling | centroid vs area-weighted runoff | row count, no NA | yes |
| segments (values) | wb and pcic per segment | NA pattern equals lut gaps; wb coverage >= 0.99; SALR pcic complete | yes |
| provenance (hydat_release, upstream_area_100, wet_commit, fwapg_groups, cov_share) | the quoted numbers | parse checks for not-NA and length 1; test checks names only | adequate. fwapg_cov_share is stored, but the map layer does not store its own copy (Finding 1) |
| budget | under 500 KB per vignette | script and test | yes; about 467 KB after the rebuild |

Not findings:
- The test calls `sf::sf_use_s2(FALSE)` globally (test-vignette_data.R:97) and never restores it. No
  other test or R/ file uses sf, so it affects nothing today.
- data.R:193 is a tautology. Round 1 noted it.

## Findings

- **[severity: fragile]** tests/testthat/test-vignette_data.R:69-71 and 95-100;
  data-raw/segment_vignette_data.R:121-125; data-raw/segment_vignette_map.R:42 and 124. The round-3
  coverage fix has no guard that would catch its own regression.
  - The test asserts only `in_pcic ⊆ outline`. The two thresholds, more than 75 % of in_pcic gauges
    valued and fewer than 5 valued outside, both pass under the count > 0 rule that round 3 rejected.
    Measured on the 309 accepted gauges: 180/202 = 0.89 valued, and 0 outside.
  - So three regressions go green:
    - the map's `cov_share` loosened alone (the outline grows into the Liard; the subset test still holds);
    - both scripts reverting;
    - the constant drifting between the two scripts. It is held in two places, linked only by a
      "# as in" comment.
  - Cheap guards that discriminate, both measured true today and false under the old rule:
    - the reverse containment, `!in_pcic` gauges outside the outline (0 of 111 inside today);
    - a domain check, `!any(startsWith(v$skill$station_number[v$skill$in_pcic], "10"))`. In-coverage
      gauges are only 07E/07F/08J/08K/08L/08M/08N; the old rule adds four 10C gauges.
  - Also put `cov_share` on the `coverage` layer, as a column, and test it equals
    `v$provenance$fwapg_cov_share`.

- **[severity: fragile]** data-raw/segment_vignette_data.R:127-132 and 264-268. `fwapg_max_order`
  is meant to be "in the groups fwapg covers", per the comment at :264-265. The `valued` half is taken
  over **every** discharge group, which includes FONT and FROG; both are out of coverage and both reach
  order 8. The `streams` half is taken over `fwapg_groups` only.
  - The numbers agree today: 8 in either scope, against 10 for the streams. So nothing published is
    wrong yet.
  - Nothing asserts `valued < streams`, which is the claim the field exists to support ("the largest
    rivers have no row").
  - Fix: restrict the valued query to `fwapg_groups`, and `stopifnot(fwapg_max_order < fwapg_max_order_all)`.

- **[severity: fragile]** data-raw/segment_vignette_map.R:31-32. The header still says the map is
  "Separate from the values so a cartographic refresh does not need the PCIC or water-balance runs".
  Since round 3 it reads `data/wb/stations.rds` (scripts/wb_stations.R, map.R:92), so a refresh on a
  machine without `data/wb/` now stops at `readRDS`. It fails loudly, but the header tells the next
  reader the dependency is not there. Name it in the header.
