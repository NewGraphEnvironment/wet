# Code-check round 4 (#196): round 3's fixes, and the mechanism-B enumeration re-walked

Reviewed HEAD 71bea115 against 0e56d60e, with round 3's fixes (6c9cb1e5, 71bea115) read line by line.
Probes ran in a detached worktree of HEAD (scratchpad `wt4`, `data/station_regulation` symlinked for the
caches). The script, run there from the caches (WET_HYDAT_RELEASE=20260717, WET_PGHOST=127.0.0.1), wrote
the status file and the report byte for byte (`git status` clean) and made no new cache file; its
in-memory state was saved for the probes. Database queries were read-only (session READ ONLY, no temp
tables). No licence number, POD number, SYSID or source name is written here.

## Checklist read

- **code-check.md**: the prose of every H3 under `## Mechanisms` (A guard that fails toward pass; A
  fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own
  output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a
  harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in
  it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe
  is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One
  fact derived twice), table rows and evidence blocks skipped. Rules that stand alone: Documentation
  Staleness from its index line only.
- **code-check-spatial.md**, read in full: FWA `upstream_route_measure` misses the next segment's start;
  FWA lookup area follows watershed codes, so side channels get the river's; A relation between FWA
  watershed codes is not a place; A Freshwater Atlas main stem's downstream end lies on the receiving
  river's centreline; The BC WFS caps an un-paged `GetFeature`; BC's water rights licence view repeats a
  row per licensee. Index lines only for the rest (terra, GDAL, QGIS, raster rules the diff does not touch).
- **code-check-r.md**, read in full: `match()` treats NA as a matchable VALUE; Postgres row order is never
  fixed unless the query fixes it; A database driver's value is not a base R type; A value compared as
  `::text` in SQL; `ifelse()` with an all-NA test returns a logical vector. Index lines only for the rest.
- **code-check-shell.md**: index only (the diff holds no shell).

## Findings

- **[severity: fragile]** scripts/station_regulation.R:327-333 (the report's "== The rule as registered"
  section) and data/checks/station_regulation_20261028.txt:4-9 — **the report names Amendments 1 and 2
  and not Amendment 3, and does not give the statuses under both versions that the rule requires for an
  amendment made after stations were placed.** The rule header (scripts/station_regulation_rule.R:83-84)
  says: "A change after any station is placed is dated and appended below this header, with its reason;
  the script's report then gives the statuses under both versions." Stations were snapped, placed and
  scored at c74e7382, and a status report (77 natural, 108 regulated, 72 unknown) was committed at
  6c1194e1 and a06b54b3, under the rule at 0c6d31ff. Amendment 3 (6c9cb1e5) came after that. The
  report run under it reads "run under 6c9cb1e5…, with Amendment 1 (…) and Amendment 2 (…)". It has no
  Amendment 3 line and no table of the statuses under the version before it (2 stations moved, 08NK0006
  and 08HC0004, natural to regulated). Both facts are in research/station_sources.md and the commit
  message, but not in the report the rule names. This is round 2's class ("docs omitting Amendment 2")
  one amendment later. Its cause is that the report's amendment list is a hand-typed string literal
  (script.R:329-332) and nothing ties it to the rule file's `---- Amendment N` headers. Deriving the
  list from those headers, or a test that counts them against the report, would end the class. The
  rule's "both versions" clause also needs the earlier version's statuses printed: rg_own_below() with
  the margin off reproduces them from the same placement cache, so no re-placement is needed.
  - **Rule:** code-check.md "A guard that fails toward pass" ("A rule stated in a comment is not an
    enforced rule"); code-check.md "Documentation Staleness"

No defect found inside Amendment 3's code. Checked:

- **NA handling in rg_own_below().** `same_line` is NA only when the point is not indexed (266 of 1,073
  own-reach pairs; `indexed` FALSE, so it is kept). `below_m` is NA only if the station's measure or the
  indexed measure is NULL. The station's is held non-NULL by `stopifnot(pl$n_gm == nrow(gauges))`
  (script.R:208), and fwa_indexpoint() returns a measure whenever it returns a row. Measured: 0 of 807
  indexed pairs have an NA `same_line`, `below_m` or `upstream`. The one NA combination that would drop
  toward natural (indexed, same line, `below_m` NA) cannot be reached.
- **Sign of below_m.** `m.measure - i.downstream_route_measure` is positive below the station.
  Measured: every same-line pair that fwa_upstream() calls not upstream has `below_m` >= 0 (243 pairs,
  min 0.000, two exact ties of 0, the 08NK0006 pair). Every same-line pair it calls upstream on the
  measure branch has `below_m` < 0. The 34 exceptions (same line, upstream TRUE, `below_m` up to 9.1 km)
  all sit at the code-mismatch stations, where the polygon's localcode is below the segment's. There
  fwa_upstream()'s side-channel branch answers TRUE (kept, toward regulated: B15's accepted tradeoff).
- **A point on the station's line but on another reach.** `same_line` compares blue line keys, so such
  a point is decided by its measure, which is right on one blue line. The margin reaches only 100 m
  below the station's own measure, and fwa_indexpoint()'s 100 m tolerance bounds the point to that
  stretch of line. Points on the line within 100 m below but in another polygon are not "own" and are
  decided by codes with no margin (B28 below): measured, none is near a natural station.
- **Cache key.** `place_key` (script.R:185) hashes `rg_sql_own`, whose text gained `same_line` and
  `below_m`. A fresh `placement_0279b8a7fc.rds` was written at 08:00 and reproduced here.
  `rg_own_margin_m` is applied in R after the cache, so it need not be keyed.
- **Report lines.** "power PODs 845" = `sum(lic$power & !lic$dup_pod)`, kept rows, re-derived. The
  unlocated line's 128 = 95 + 27 + 2 + 2 + 2 equals round 3's 128 (95 consumptive with a volume, 27
  without, 4 storage, 2 power), over `!located & surface & !dup_pod & !redivert`, which is the set
  `candidate`, `power` and `novol` would take if located. 0 unlocated surface rediversions are missed.
- **NA-code stop** (script.R:167-172): `anyNA()` over the six columns rg_sql_up, rg_sql_own, the border
  and man-made tests read from `sn`; `linear_feature_id` is non-NA by `accepted`.

## Enumeration

Mechanism B: every evidence filter, what its complement is, and where it goes now. "Counted" = a
report line gives the excluded set's size; "routed" = the station goes to unknown (or regulated);
"stopped" = the script stops; "measured" = the exposure at the natural stations was measured and the
choice is the registered rule's, or the owner's, or an accepted tradeoff.

| # | filter (complement) | where | verdict | evidence |
|---|---|---|---|---|
| B1 | LICENCE_STATUS outside the set or NA | lib.R:88 | stopped | `rg_codes_check`; tested |
| B2 | LICENCE_STATUS not "Current" | lib.R:89 | by rule | rule.R:59; counted (report: 95,422 of 118,717 Current) |
| B3 | POD_SUBTYPE outside {PG, POD, PWD} or NA | lib.R:92 | stopped | round 2's fix; snapshot PG 2459, POD 80793, PWD 12170 |
| B4 | groundwater POD (PG, PWD) | lib.R:101; script.R:250-251 | by rule ("surface") | counted in the "not placed" classes only; no status reads it (round 1) |
| B5 | NA purpose on a located surface row | lib.R:93-95 | stopped | 6 Current NA-purpose rows, none located surface |
| B6 | purpose code not in the storage or instream sets | rule.R:171-176 | routed toward regulated | a new code is consumptive and counts |
| B7 | instream non-power purposes (02E, 02I26, 02I38, 08B, 11B, 11C) | rule.R:136; lib.R:128 | by rule (#53's classes) | 1,141 kept located surface rows; not evidence of regulation under the registered rule |
| B8 | units outside the three, or NA | lib.R:97-98 | routed to unknown (novol) | 6 NA-unit rows, none located surface |
| B9 | quantity 0, NA or Total Flow | lib.R:139-140 | routed to unknown (Amendment 2) | 1,646 rows (880 + 766); counted |
| B10 | REDIVERSION_IND "Y" | lib.R:129, 140 | by rule (#53, Amendment 1) | 2 Current located surface consumptive or storage kept rows; placed and tested this round: neither is upstream of a natural station |
| B11 | REDIVERSION_IND NA | lib.R:102 | routed toward regulated (counts) | 15 rows |
| B12 | licensee repeat (`dup_pod`) | lib.R:106-112 | by rule (#53 Deviation 1) | its group's largest quantity is carried by the kept row |
| B13 | SHAPE missing (licence) | lib.R:128, 137, 139 | counted (round 3 fix) | report: 95 + 27 + 2 + 2 + 2 = 128; round 3: none of the 119 named sources is a natural station's snapped stream (accepted tradeoff) |
| B14 | dam not "Active" or not in the regulated classes | rule.R:158-163 | by rule | 235 Active dams are "Non-Regulated - Including Minor Dam"; counted (1838 of 2485 regulating) |
| B15 | dam codes outside the sets or NA | rule.R:159-161 | stopped | tested |
| B16 | dam GEOMETRY missing | script.R:177 | counted | 1838 of 1838 regulating are located |
| B17 | point in no FWA watershed | script.R:360-370 | counted by class (accepted tradeoff) | 5 of 72028: 4 counted PODs, Tucker Creek Dam; round 2: none upstream of a natural station |
| B18 | point inside two polygons | lib.R:172-175 | deterministic pick | `DISTINCT ON (pid) … ORDER BY pid, watershed_feature_id`; method as #53 |
| B19 | polygon with NULL codes | lib.R:184-187 | none exist | 0 of `fwa_watersheds_poly` (measured) |
| B20 | point not upstream by polygon codes (incl. watershed vs segment codes) | lib.R:184-187 | measured (accepted tradeoff) | round 3: 16 of 204 stations differ, every effect toward regulated |
| B21 | own-reach point not indexed within 100 m | lib.R:194; rule.R:153-155 | kept (toward regulated) | 266 of 1,073 own-reach pairs |
| B22 | own-reach point exactly at the gauge's measure | rule.R:153-155 | kept (Amendment 3) | 2 ties at 0.000 m, both at 08NK0006, now counted; 08NK0006 regulated |
| B23 | own-reach point on the station's line 0-100 m below | rule.R:153-155 | kept (Amendment 3) | 50 such pairs now kept (B22's 2 ties included); 08HC0004 (dam 43.8 m below) regulated |
| B24 | own-reach point on the station's line more than 100 m below | rule.R:153-155 | measured, the owner's margin | at natural stations: the regulating John Frank Lake Dam 212.6 m and a no-volume licence 230.9 m below 08LE0001; a no-volume licence 702 m below 08HB0034; counted points add at most 0.015 of flow (08HB0031). Round 3 reported 08LE0001's 212.6 m before the owner chose 100 m; no tracked text names it |
| B25 | own-reach point indexed onto another blue line (#53's 1 mm test, no margin) | rule.R:153-155 | measured | 31 pairs dropped; at natural stations 3 counted points, adding 0.073 of flow at most (08HA0005, use and storage from 0.9 % to 8.2 %, under 10 %; the point is 291 m from the gauge and 70 m from its stream), no dam, power or no-volume point. 328,961 of 4,907,441 FWA segments have a NULL localcode, which leaves fwa_upstream()'s side-channel branch unevaluated; 0 NA `upstream` among the 807 indexed pairs |
| B26 | indexed, same line, `below_m` NA | rule.R:154 | unreachable | dropped if it occurred; the station's measure is held by script.R:208 and fwa_indexpoint() returns a measure with every row; 0 of 807 |
| B27 | point within 100 m below the gauge on its line but in the next polygon down (not "own") | lib.R:184-187 | measured | evidence points within 300 m of a gauge that the pairs do not keep: 0 at natural stations in this class (72 at regulated, 1 at unknown); the 10 at natural stations are all B24/B25 |
| B28 | same line, upstream TRUE although below by measure | lib.R:188-194 | kept (toward regulated) | 34 pairs at 7 stations, all code-mismatch stations (B20) |
| B29 | upstream area outside BC across a line not in `rg_borders` (`fwa_approx_borders` holds AB_120, USA_49, YTNWT_60; no Alaska line) | lib.R:215-226 | measured | the 4 natural stations west of 128°W (61003, 61004, 61005, 61007) have every upstream FWA stream inside `fwa_bcboundary`, the nearest 24 km from its edge (61004, Sulphurets Creek); round 3: the nearest natural station's upstream to a listed line is 1.75 km (08MH0034) |
| B30 | snap candidate with NA watershed or area | rule.R:199-200 | routed to unknown | not snapped |
| B31 | snapped station with NA codes or measure | script.R:167-172 | stopped (round 3 fix) | 0 of 204 |
| B32 | NA dams/border/power/novol on a snapped station | rule.R:240-242 | stopped | tested |
| B33 | own-reach pair with no stream-position row | lib.R:201-203 | stopped | `stopifnot(identical(...))`; tested |
| B34 | shared group's split over an uncounted POD | lib.R:130-136 | stopped | Amendment 1; tested |
| B35 | station name NA | rule.R:183-185 | stopped | |
| B36 | no drainage area ("None", missing) | script.R:84 | by rule (name leg only) | 93 of 257 have an area |
| B37 | no published flow, flow <= 0, no `pick` row, or NA watershed group | script.R:216, 233-237, 262 | routed to unknown | `sort(unique())` drops an NA group, so its segment gets no flow; 0 of 204 snapped have no flow today |

Every row's complement is counted, routed, stopped, unreachable, or measured under the registered rule,
the owner's amendment or an accepted tradeoff. No row is open. The one finding above concerns the
report's record of the rule, not a filter.

Probe scripts (scratchpad): `run4.R` (the run, state saved), `p1.R` (own-reach classes, the sign of
`below_m`, dropped pairs), `p2.R` (evidence points within 400 m of each gauge, indexed and classed),
`p3.R`/`p4.R` (rediversions, instream and dam complements; NULL polygon codes), `p6.R` (natural stations
west of 128°W against `fwa_bcboundary`). An earlier border probe over all 75 natural stations at once ran
the database's temp space out ("No space left on device") and failed. The temp file was freed: 48 GB
were free afterwards.
