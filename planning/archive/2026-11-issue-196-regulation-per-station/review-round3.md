# Code-check round 3 (#196): findings and mechanism enumeration

Reviewed HEAD a06b54b3 against 0e56d60e. Probes ran in a detached worktree of HEAD (scratchpad `wt3`) with
a **copy** of `data/station_regulation/` (not a symlink), so nothing was written to the main tree. The
script, run there from the copied caches (WET_HYDAT_RELEASE=20260717, WET_PGHOST=127.0.0.1), wrote
the status file and the report byte for byte (`git status` clean after the run), and its in-memory
state was saved for the probes below. Every database query ran under
`SET default_transaction_read_only = on`. No licence number, POD number, SYSID or source name is
written here.

## Checklist read

- **code-check.md**: every H3 under `## Mechanisms` read in prose (tables and evidence blocks skipped):
  A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the
  property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix
  lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared
  working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty,
  and unset are three different things; The probe is broken before the world is; Written data outlives
  the fix; Serialization loses meaning silently; One fact derived twice (14 read). Rules that stand
  alone, Security, Spreadsheets: not read (none applies to the diff's tools); about 30 headings unread.
- **code-check-spatial.md**: read in full: A name is not a key; The BC WFS caps an un-paged GetFeature;
  BC's water rights licence view repeats a row per licensee; A Freshwater Atlas main stem's downstream
  end; FWA `upstream_route_measure` misses the next segment's start; FWA main flow is not edge type
  1000 alone; FWA lookup area follows watershed codes; A relation between FWA watershed codes is not a
  place (8 read). About 100 not read (terra, GDAL, QGIS, raster and KML rules the diff does not touch).
- **code-check-r.md**: read in full: A database driver's value is not a base R type; A value compared
  as `::text`; `match()` treats NA as a matchable VALUE; Postgres row order is never fixed (4 read); the
  rest read at index level only (about 150 unread in full).
- **code-check-shell.md**: index only; the diff holds no shell (all unread in full).

## Findings

- **[severity: bug]** scripts/station_regulation_lib.R:188-193 (`rg_sql_own`) and :202
  (`rg_upstream_pairs()`'s `below`) — the own-reach stream-position test compares the gauge's measure
  with the point's at fwapg's default 1 mm tolerance, so **a tie, and any point within the two
  coordinates' error below the gauge, is dropped as "below", and the station reads natural**.
  Measured on the shipped run:
  - **08NK0006** (West Line Creek, LC_WLC) is natural. A Current consumptive licence worth **36.2 % of
    its mean annual flow** and a no-volume licence sit 23 m from the gauge and index to **exactly the
    gauge's measure** (358.171775916 m both; difference 0.000000 m). `fwa_upstream()` needs the point
    above the gauge by more than 0.001 m, so both drop as below. Counted the other way, the station is
    regulated (L 36.2 %), and unknown under Amendment 2 even without the share.
  - **08HC0004** (Ginnard Creek at V-Notch Weir, Meares Island) is natural. The regulating Ginnard Creek
    Dam is 91 m from the gauge and indexes **43.8 m below** it. The gauge snapped 74 m off-line onto a
    lake construction line (edge 1200), so the separation is smaller than the snap distance.
    Licences worth about 7 % sit 55 m below.
  - **08LE0001** (John Frank Creek at John Frank Lake Outlet) is natural. The regulating John Frank Lake
    Dam indexes **212.6 m below** the gauge, and a no-volume licence 230.9 m below.
  At the other natural stations, the points dropped as below are one no-volume licence 702 m below
  08HB0034, and counted licences that add at most 0.085 of flow per station (08NH0001 89 m below,
  08HA0005 1.6 km below; every other station adds 0.02 or less). Against the 77 natural stations,
  no other regulating dam lies within 500 m of an upstream stream without being counted: the only
  ones are Linley Valley and Hugh Lakes, each placed in another watershed, with no stream within 500 m.
  The rule says "the stream-position test, as #53", which leaves both the tie and a separation inside
  the coordinates' error to fall toward natural. This is the owner's decision (an amendment): for
  example, count a tie as upstream, or call a station unknown when a regulating dam or a licence
  sits within a stated distance below it on its own reach.
  - **Rule:** code-check-spatial.md "FWA `upstream_route_measure` misses the next segment's start";
    code-check.md "A guard that fails toward pass"

- **[severity: fragile]** scripts/station_regulation_lib.R:128-129, 137, 139-140 (`located` in
  candidate, power and novol); scripts/station_regulation.R:170 and :341-343 — **a Current surface
  licence with no location enters none of L, S, power or no-volume, and no report line counts it.**
  128 such rows are kept, not repeats and not rediversions: 95 consumptive with a volume, 27
  consumptive with none, 4 storage and 2 power. Amendment 2's reason is that a licence the shares
  cannot see leaves a station's use unknown. That reason applies equally to a licence the placement
  cannot see, yet these rows fall silently toward natural. Measured exposure: 119 of the 128 name a
  source, and none of those names is the snapped stream of any of the 77 natural stations. A source
  that is a tributary is not tested. A rule question (an amendment). At least the report's
  licence-row line should give the count.
  - **Rule:** code-check.md "A guard that fails toward pass" (enumerate the complement)

- **[severity: fragile]** scripts/station_regulation.R:176-177 with scripts/station_regulation_lib.R:184-187
  vs :211-233 — **one fact derived twice.** The upstream test for points uses the lookup watershed's
  codes (`gauges$wscode, localcode`). The border and man-made tests use the snapped segment's codes
  (`seg_wscode, seg_localcode`). At **16 of 204** snapped stations the two localcodes differ, and in
  all 16 the segment lies above its polygon. The point test therefore takes in 2 to 35 more polygons,
  all below the station. At 6 stations those polygons change the evidence: 08MB0001's only counted
  licence, 9 no-volume licences at 08NK0012, 3 at 08NK0003, and counted licences at 08NM0009,
  08NM0019 and 08NM0060 all lie below the gauge by segment codes. Today this moves no status, since
  every effect points toward regulated or unknown. 6 of the 16 are natural (08JC0018, 08JC0020,
  08LF0011, 08NM0004, 08NM0065, HRB2634), and at none of them does a counted, dam, power or
  no-volume point depend on it.
  - **Rule:** code-check-spatial.md "FWA lookup area follows watershed codes, so side channels get the
    river's"; code-check.md "One fact derived twice"

- **[severity: fragile]** scripts/station_regulation.R:160-164, 176-177 — **NA codes on a snapped
  station are not refused.** A snapped station whose watershed codes are NA gets no upstream pairs
  (`p.wscode <@ NULL`). One whose segment codes are NA gets no border row. Either way it reads
  natural. `rg_snap_pick()` requires `watershed_feature_id` and an upstream area, but `wscode` and
  `localcode` come from a third join, `fwa_watersheds_poly`. `pl$n_gm` guards only the measure.
  Measured: 0 of 204 snapped stations have an NA in wscode, localcode, seg_wscode, seg_localcode,
  blue_line_key or measure, so this is unguarded rather than wrong today.
  - **Rule:** code-check.md "A guard that fails toward pass"

- **[severity: fragile]** scripts/station_regulation.R:341-343 — the report's "power PODs 1043" is
  `sum(lic$power)`, which counts licence rows, licensee repeats included (198 of them). The kept PODs
  number 845, and the report's "counted" and "no volume" figures are both over kept rows. So three
  counts on one line cover two populations under one noun. Research does not cite the figure.
  - **Rule:** code-check.md "One fact derived twice"

## Mechanism

**(B) is confirmed, and it is the mechanism behind round 1's groundwater PODs, round 1's dropped
no-volume licences, round 2's unplaced points and round 2's subtype and NA-purpose gaps, as well as
findings 1, 2 and 4 above.** Stated exactly: `rg_status()`'s natural is its residual `else` arm. A
station is natural when no evidence row reaches it, not when each check has positively run and found
nothing. Every evidence filter is an inclusion test, so its complement silently becomes "no evidence":
`located`, `POD_SUBTYPE %in% "POD"`, `v > 0`, a point inside a watershed, `fwa_upstream() %in% TRUE`
past a 1 mm tolerance, a stream crossing one of three border lines, and a non-NA code. Each unknown
arm (not snapped, outside BC, power, no volume, no flow) was added one at a time, for the cause in
front of it. The code-check remedy is to enumerate the complement: for each filter, count the rows it
excludes, and make each excluded class either a stated non-evidence (reported with a count) or an
unknown arm. The table below does this for every filter.

**(A) is confirmed as a mechanism, but measured it holds today.** The branches are restated in 18
places, and every one agrees with `rg_status()` / `rg_licence_rows()` except one count label (finding
5) and one tense in the exported docs (A11). Round 2's roxygen omission was an instance of A. This
round found no new one. The two-lists-that-agree spots are: "surface" applied in the lib for power and
no-volume but in the script for L and S; the why strings in `rg_status()` against the report's regexes;
and the test's name regex against `regulation_of()`. All three agree today, and none is held equal by
a test.

## Enumeration

Mechanism A: each place a rule branch is stated, against `rg_status()` (rule.R:215-260) and
`rg_licence_rows()` (lib.R:87-142) as the source of truth.

| # | place | branch(es) | verdict | evidence |
|---|---|---|---|---|
| A1 | rule.R:42-57 header Status, :99-106 Amendment 2 | all | agrees | order name, not snapped, dam, L/S, outside, power, no volume (Amendment 2), no flow, natural is rg_status's `if` order at 234-255 |
| A2 | rg_status why strings vs script.R:376-385 report regexes | all why | agrees | 11 distinct why pieces in the CSV (`#` for numbers), each mapped; the natural string is matched before the split |
| A3 | lib.R:128-129, 137, 139-140 vs rule header "Licences counted" + Amendment 2 | L, S, power, novol | agrees | candidate = located, cons/storage, kept, v>0, not redivert; novol = the same with v NA/<=0 plus surface; measured 1646 = 880 Total Flow + 766 zero/missing (`r3/a.R`) |
| A4 | script.R:244-245 cons/stor surface mask vs header "surface (POD_SUBTYPE POD)" | L, S | agrees | report "counted" 58081 = `sum(candidate & surface)`, re-derived |
| A5 | script.R:251-252 power_up/novol_up vs lib surface inside power/novol | power, novol | agrees | both masks carry `surface`, lib.R:137, :139 |
| A6 | report count line script.R:341-343 | counts | **differs** (power) | "power PODs 1043" counts rows; kept 845, repeats 198 (finding 5); counted and no volume agree |
| A7 | report "not placed" classes script.R:346-350 | counted/power/novol | agrees | the same predicates as the masks; 5 not placed (4 counted, 1 dam) |
| A8 | status CSV columns script.R:283-291 | every branch | agrees | dams_up, L_share, S_share, outside_bc, power_up, novol_up; name, no snap and no flow appear in `why` only |
| A9 | R/wet_station_list.R `wet_regulation_vocab` vs rule.R `rg_vocab` | vocabulary | agrees | identical three strings |
| A10 | R/wet_station_list.R roxygen and man/wet_station_list.Rd | every branch | agrees | each arm named, Amendment 2 included; the man page matches the roxygen line for line |
| A11 | roxygen "A natural station can serve as a donor" vs research Donors bullets and CLAUDE.md (#202) | donor use | differs (tense) | research: records and held-out tests until a pool reads the status; no wet function reads it yet |
| A12 | R/wet_station_daily.R, R/wet_station_select.R roxygen | pointer | agrees | both point to `wet_station_list()`'s `regulation` |
| A13 | research/station_sources.md "Regulation per non-HYDAT station" | rule + numbers | agrees | snap 204/119/73/12, not 43/8/2; status 77/108/72; 89/52/44/11; 49/18/4/2 (report). Amendment 2 effect re-derived: 92 natural under Amendment 1 with groundwater, 17 of them unknown now, 2 regulated now natural (`r3/m.R`) |
| A14 | research Donors bullets (provincial and Tool sections) | counts | agrees | 54/99/58 and 23/9/14 = report "Status by source" |
| A15 | CLAUDE.md Regulation bullet | every branch | agrees | the branches as listed; "area-only leg otherwise" is the no-named-candidate case |
| A16 | tests: test-station_regulation_rule.R, test-station_regulation_lib.R, test-wet_station_list.R | every arm | agrees | each rg_status arm, Amendment 2's novol, power and surface pinned; the natural-row test reads every column; the name regex is verbatim `regulation_of()`'s |
| A17 | rule.R:85 "A code outside a known set stops the script" | code sets | agrees in effect, wider in words | stops on LICENCE_STATUS, POD_SUBTYPE, 3 dam codes and NA purpose on located surface rows; PURPOSE_USE_CODE, QUANTITY_FLAG, QUANTITY_UNITS and REDIVERSION_IND are open. A new purpose is consumptive (counts), a new unit is NA (no volume, unknown) and NA rediversion counts: none falls toward natural |
| A18 | script.R:30 `rule_commit`, report "registered at 2d93787f" | provenance | agrees | the md5 check passed and the run reproduced the tracked bytes |

Mechanism B: every input value that can take a row out of the evidence, with the direction it falls.

| # | input | where | source of truth | verdict | evidence |
|---|---|---|---|---|---|
| B1 | LICENCE_STATUS outside set or NA | lib.R:88 | rule.R:123 | agrees (stops) | `rg_codes_check`; tested |
| B2 | POD_SUBTYPE outside set or NA | lib.R:92 | snapshot | agrees (stops) | PG 2459, POD 80793, PWD 12170, NA 0 |
| B3 | NA purpose on a located surface row | lib.R:93-95 | rule | agrees (stops) | NA purpose: 6 Current rows, none located surface |
| B4 | new purpose code | rule.R:155-159 | #53 classes | falls toward regulated | every Current code checked by description; 12A storage and 07A-C power are as #53 had them |
| B5 | units outside the three, or NA | lib.R:97-98 | rule | falls toward unknown | 6 NA-unit rows, none located surface; Total Flow 1352 rows |
| B6 | quantity 0 or NA | lib.R:139-140 | Amendment 2 | agrees (unknown) | 766 rows |
| B7 | REDIVERSION_IND NA | lib.R:102 | #53 | falls toward regulated (counts) | 15 rows |
| B8 | SHAPE missing (licence) | lib.R:128, 137, 139 | rule "located" | **differs: silent, toward natural** | 128 kept surface cons/storage/power rows, no report line (finding 2) |
| B9 | point in no FWA watershed | script.R:344-353 | accepted tradeoff | agrees (reported) | 5 of 72028 (4 counted, 1 dam: Tucker Creek); round 2: none upstream of a natural station |
| B10 | dam GEOMETRY missing | script.R:171, 339-340 | rule | agrees (reported) | 1838 of 1838 regulating located |
| B11 | dam codes outside set or NA | rule.R:141-146 | snapshot | agrees (stops) | tested, en dash included |
| B12 | own-reach point not indexed within 100 m | lib.R:202 | #53 | falls toward regulated (kept) | 266 of 1073 own-reach pairs |
| B13 | own-reach point at the gauge's exact measure | lib.R:188-193, 202 | fwapg tolerance 0.001 | **differs: tie falls toward natural** | 08NK0006: a 36.2 % licence and a no-volume licence, difference 0.000000 m (finding 1) |
| B14 | own-reach point within coordinate error below the gauge | lib.R:202 | rule ("as #53") | **differs: toward natural** | 08HC0004 dam 43.8 m, gauge 74 m off-line; 08LE0001 dam 212.6 m (finding 1) |
| B15 | segment codes ≠ watershed codes | script.R:176-177; lib.R:184-187 vs 211-233 | one station position | differs; toward regulated | 16 of 204; 6 with evidence moved; no status change (finding 3) |
| B16 | upstream outside BC not crossing a listed line | lib.R:211-222 | rule.R:115 | agrees on today's data | nearest natural station's upstream to a line: 1.75 km (08MH0034, Fergus Creek, Surrey, BC-only); 4 outside_bc stations touch AB_120 at 0 m. FWA holds no stream outside BC at those 4 (the `fwa_bcboundary` probe found 0 outside segments there), so no stream test can see past a line; the Alaska boundary is not in `fwa_approx_borders` |
| B17 | snap candidate with NA watershed or area | rule.R:182-184 | rule | falls toward unknown | not snapped |
| B18 | no published flow, or flow <= 0 | script.R:227-231, 256 | rule | falls toward unknown | 0 of 204 snapped today |
| B19 | NA dams/border/power/novol on a snapped station | rule.R:223-225 | rule | agrees (stops) | tested |
| B20 | a shared group's split over an uncounted POD | lib.R:132-136 | Amendment 1 | agrees (stops) | tested with #53's split restored |
| B21 | station name NA | rule.R:166-168 | rule | agrees (stops) | — |
| B22 | Tool area "None" or missing | script.R:84 | rule | by rule: name leg only | 93 stations have an area (HYDAT 61, Tool 32) |
| B23 | NA wscode, localcode or segment codes on a snapped station | script.R:160-164, 176-177 | none | **unguarded, toward natural** | 0 of 204 today (finding 4) |
| B24 | own-reach pair with no stream-position row | lib.R:200 | #53 | agrees (stops) | `stopifnot(identical(...))`; tested |
| B25 | regulating dam placed in another watershed near a natural station | placement | the register | agrees | within 500 m of a natural station's upstream streams: Linley Valley (404 m, watershed 920.418129) and Hugh Lakes (419 m, another 100.190442 branch), both on no stream within 500 m; the other two are B14's |

Probe scripts (scratchpad `r3/`): a.R (licence sets), c.R (snapped NA and code mismatch), d.R and e.R
(segment against watershed codes), f.R (unlocated exposure), g2.R and h.R (border), i.R, j.R, l.R,
n.R and o.R (own-reach drops and ties), m.R (Amendment 2 re-derivation), p.R and q.R (dams near
natural stations).
