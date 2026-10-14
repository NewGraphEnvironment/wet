# Code-check round 3 (#71), branch diff 6be3e11...HEAD

Reviewer: subagent, read-only on the repo (this file excepted). Sources of truth: `R/wet_source_pick.R`, `scripts/pcic_routed_lib.R`, `scripts/vignette_data_lib.R`, `scripts/segment_output.R`, `scripts/discharge_publish.R`, the bundled `.rds` files (current, and 6be3e11's `segment_values.rds` from git), `data/checks/segment_output_20260717.txt`, `data/checks/discharge_publish_20260717.txt`, the fit's `pooled_variant.txt` and `adjust_override.txt`, fwapg's `load/fwa_streams_watersheds_lut.sql`, and local fwapg (127.0.0.1, read-only).

## The mechanism behind rounds 1 and 2

Each earlier finding restated a set or a relation that the code defines, using its most familiar member or a nearby proxy, and the words were never derived from the definition:

- the far-low flips were called "a reservoir or a misplaced outlet", after the Nechako and #58's 11 gauges;
- the no-lut segments were called "first-order streams", after a field default;
- one build was identified by its wet commit, a proxy for the build;
- off-own-line was called "side channels", the best-known member of the set.

Each sentence reads true for the example its writer had in mind. Nothing ties the wording to the definition, and the guards that exist test the example or the proxy, not the set. The test I applied to every sentence below: name the set or relation the code defines, then check whether the sentence covers all of it and only it.

## Findings

- **[severity: bug, low; a research file restates the rule by one member]** research/water_balance_method.md:83, "except where it is under a fifth of the balance on a segment's own line (the Nechako Reservoir)". This line was rewritten on this branch, and it still names the far-low exception by its best-known member.
  - The Nechako Reservoir groups are 26.7 % of the 224,199 flips (data/checks/segment_output_20260717.txt, "their share of all flipped segments").
  - The other 73 % are a 5 to 6 % flip rate spread across edge types and stream orders (same report, and this file's own lines 101-106).
  - This is round 1's first finding in the research file that describes the article. The line says "What the segment-discharge article says", but the article's rule (vignettes/segment-discharge.Rmd:154-159) carries no Nechako parenthetical. Its Nechako sentence (:166-169) is scoped to the four groups and is correct.
  - Fix: drop "(the Nechako Reservoir)", or scope it, for example "(26.7 % of flips are the Nechako Reservoir's, fwapg#24)".

- **[severity: bug, low; a scope claim anchored to the wrong commit]** research/water_balance_method.md:69, "measured by `data-raw/segment_vignette_data.R` at wet 7b83959 … that commit reproduces the numbers, later ones do not". The first half holds: 6be3e11's bundle records `wet_commit` 7b83959, gauge errors +2/+3/+18/+26/+24 %, and a SALR median of 1.2266. "Later ones do not" does not hold. All 32 commits in 7b83959..6be3e11 (main before this branch) still compute `gauges_salr` and SALR in that script (`git show 6be3e11:data-raw/segment_vignette_data.R` has 20 references). The first commit that drops them is a71cf36, on this branch. The anchor is the wrong one: the code stopped computing these numbers at #71, not after 7b83959. Fix: "commits from #71 on do not", or name 6be3e11 as the last commit that does.

No other unsupported claim. Every sentence of the article's new or rewritten prose is supported, in the table below.

## Enumeration

S = supported (by what). C = carried over unchanged, or nearly, from 6be3e11, and this branch's data do not make it wrong (out of scope, checked anyway). U = unsupported (a finding above).

### vignettes/segment-discharge.Rmd, body

| line | claim | verdict |
|---|---|---|
| 100-102 | mean flow per segment, m³/s, each calendar month and the year | S: months 0-12; publish report |
| 102 | public at `s3://fresh-bc/discharge/fwa/v1/` | S: manifest URL guard (:41); publish verifies anonymous reads |
| 102-104 | no listing, so start from the manifest, which lists every part with rows, size, md5 | S: `pub$parts` has key/rows/bytes/md5; the test asserts these columns |
| 104-106 | N parts, GB, built date, wet commit | S: computed from the manifest's `built` and `wet_commit` |
| 108-110 | `segment_monthly`: one row per segment, month and source with a value; row count; month 0 is annual | S: guard `sum(seg_parts$rows) == sum(reader$rows)`, rows/13 integer |
| 111-112 | `watershed_monthly` per fundamental watershed, balance only | S: guard `all(ws_parts$source == "wet_balance")`; "small polygon each segment drains" C |
| 116 | routed 1951–2012 | S: segment report "periods: routed 1951-2012" |
| 116-118 | VIC-GL, 0.0625°, observed climate, Raven, hydromosaic | S: CLAUDE.md data sources (PNWNAmet; grid) |
| 119-121 | fwapg fork places outlets on FWA segments and spreads flow by drainage area | C (6be3e11:156-157) |
| 121 | routed annual = mean of twelve months | S: publish check "routed month 0 = mean of 1-12", 3,377,037 compared, 0 differing |
| 123-127 | balance 1981–2010; P − AET from normals, averaged over upstream area, adjusted per hydrologic zone against HYDAT | C; the zones with no adjustment are stated in Limits (pooled_variant `none`) |
| 130 | covers almost all of BC; code and inputs open | C (6be3e11:168); balance on 4,529,939 of 4,907,441 segments (92 %) |
| 149-150 | 3,374,133 segments have both sources | S: `n_both_src` equals the report's "both sources: 3374133" |
| 150-152 | one row per segment marked by `pick`, chosen once on annual flow, same source every month | S: `wet_source_pick()` on annual flow; segment_output.R:166/181 sets pick on all 13 rows; :191-193 asserts one per segment and month |
| 154 | routed PCIC where it has a value | S: `wet_source_pick()` :31 |
| 155-156 | balance where routed annual < a fifth of the balance's, on its own watershed's line | S: `routed_far_low` 0.2 (guard `prov$far_low == 0.2`); `low` in :30 needs `own_line`; zero balance never flips, consistent with "under a fifth" |
| 156-158 | off that line (side channels; connectors and waterbody connections the lookup gives another line's watershed), routed kept however low | S: `routed_own_line_sql` (blue_line_key ≠ watershed_key, or wscode ≠ the lut watershed's); report: own_line FALSE 72,242 both, 0 flipped |
| 159 | whichever has a value where only one does | S: :31-33 |
| 161-164 | 4,907,441 FWA segments; picks routed 3,152,838, balance 1,380,005, with pcts | S: report, held equal to reader counts and fwapg (data script :182-185) |
| 164 | 224,199 of them because routed flow is far low | S: report "224199 of them under the cut" |
| 165-166 | 374,598 neither, almost all connection lines and secondary channels with no watershed polygon of their own | S: 366,362 no-lut segments of edge types 1100/1150/1300/1350/1400/1450 (97.8 %; guard >0.9). The lut omits them because their FWA code is `999…` (208,189) or has no local code (328,961), which overlap; see the probe below. Undrawn by design |
| 166-167 | the balance takes every segment with a value in the Liard, where routed has none | S: region count 0 routed / 716,213 balance; R2 probe: 0 routed-table segments under the Liard wscode. The guard tests picks, a proxy for values; accepted at R2 |
| 167-169 | 98 % in the four Nechako Reservoir groups, where routed flow is far below the balance's | S: 59,821 / (59,821 + 1,046); report flip rate 97.1–99.1 % per group; region total 67,914 equals the sum of the four groups |
| cap 187-191 | pick on main-flow rivers of order ≥ 5, wider for higher orders; ~6 % of segments; 315 calibration gauges; smaller not drawn, nor the 1,557 with neither | S: `min_order` 5, `main_flow` edge set, `order_width`; `nrow(sk)` 315. The 6 % counts the 1,557 undrawn `none` (accepted: it rounds the same) |
| 216-218 | `scenario`, `forcing`, `source` in the path, read with `hive_partitioning` | S: publish report reader section; CLAUDE.md |
| 218-219 | parts sorted by `watershed_group_code`, so one group opens a few row groups | S: publish report "a read for BULK opens 2 of 507 row groups"; C (6be3e11:148) |
| 228-233 | example query (columns `watershed_group_code`, `pick`, `month`) | S: the data script reads the same columns from the parts |
| 236-240 | `wet_db_load(conn, cat)` → `discharge.fwa_v1_segment_monthly` | S: R2 checked the signature; CLAUDE.md |
| 243-245 | `runoff_mm` is depth over the upstream area, NA for a routed row off its own line; `coverage`; `period` | S: report "routed segments with runoff_mm NA: 72242 off their own line, 0 with no accumulated area"; coverage C |
| 296-301 | both scored on mean annual runoff 1981–2010 at the 315 gauges; balance held out by sub-sub-drainage | C; `wet_cv_folds()` default block = first four characters |
| table caption | PCIC calibration gauges unlisted; 1951–2012 against 1981–2010 | C |
| 312-313 | routed closer at n of 290 | S: computed; guard `n_rt_closer > n_both/2` |
| 315-317 | headwater (no other gauge in its basin) against nested MAE | S: `wet_cv_folds()` nesting = no other station upstream; values from the bundle; guard `mae_nest < mae_head`; C (6be3e11:322) |
| 318-320 | small < 100 km² against large > 1,000 km² | S: computed; guard |
| 321-324 | worst zone (24) and its MAE; runoff a small remainder, so a small ET error is a large runoff error | S for the numbers (zone 24, 92.8 %, only zone > 2× mean 27.5 %); the mechanism sentence is C (6be3e11:486-487) |
| 325-326 | routed has no value at 25 gauges, most in the Liard | S: 19 of 25 are 10AC/10BA/10BB/10BE/10CB/10CC/10CD, all Liard basin; guard prefix "10" > 0.5 |
| 339-340 | besides the Liard, no routed in a few northern and border basins, and only some on the outer islands | S: guard `length(no_rt) > 1` (basins 800, 945, 990 and others with balance parts only); research :74 lists the Hay, Yukon headwaters, Alsek, KUSR and Skagit; C (6be3e11:587) |
| 341-344 | adjustment does not beat raw P−AET on headwaters, kept for larger rivers; zones with too few gauges get none | S: guards `keep_adjust`, `!gate_pass`, `pooled_variant == "none"`; adjust_override.txt gives main stems reading low without it (Peace 0.77, Skeena 0.68, Nass 0.64) |
| 345-347 | of the 374,598 with neither, 369,217 have no watershed in the lookup | S: report |
| 349-350 | link to research/water_balance_method.md on main | S: the file is tracked on main |
| 354-356 | every published value is checked against its source at build; counts in the build report | S: publish report "every published value against what it was built from", all 0 differing; a differing pick or value gives FAIL (discharge_publish.R:418-430, 463), which `vd_published()` refuses |
| 356-358 | the article's routed gauge values and map picks are read from that build's parts; data not written unless the gauge values equal fwapg's | S: both scripts call `vd_published()` and `vd_verify()`; same build guarded by `wet_commit` and `built` (:43-44); data script :156-159 |

### Code comments that state what the data are

| place | claim | verdict |
|---|---|---|
| Rmd :28-31 | values from the parts, checked against their sources; map picks from the same build; both record commits and reports | S |
| Rmd :39-40, :140-143, :273, :288-291, :331-335, :361-368 | guard descriptions | S: each matches its `stopifnot` |
| data script :6-11 | segment values read from the published product and refused unless equal to their source | S: the counts in `segments` come from the report and are described separately at :19-23 |
| data script :19-23 | segments: picks, neither, no lut, connection/secondary of those, far low; from the report, checked against reader counts and fwapg | S. `no_lut_connector` comes from fwapg rather than the report; the claim is still checked against fwapg |
| data script :84-87 | no-lut segments, which no source reaches; edge types, not order | S: the report's "without (no value from either source)"; R1 probe |
| map script :8-17 | rivers by pick class (none where neither), dissolved by blue line, class and band; regions; zones; provenance | S |
| map script :19-25 | the publish report must check every part's pick with none differing (`vd_published()`) | S: the `parts_as_table` check includes pick, and a FAIL is refused |
| map script :38-40, :66-67, :97-98 | main-flow edge set; picked ids in this FWA; Liard label groups | S (`n_known` guard; R1) |

### Other changed prose

| place | claim | verdict |
|---|---|---|
| CLAUDE.md :46 | article structure; map of main-flow order ≥ 5 with Liard and Nechako labelled; 315 and 290 gauges | S |
| CLAUDE.md :46 | data script guards (routed = fwapg mean of 12; pick counts from the report held to reader counts and fwapg; publish report passing, live build, byte-identical; scoring code; routed table; clean tree) | S: `vd_commit`, `vd_routed_check`, `vd_published`, `vd_verify`, `shipped_heldout` |
| CLAUDE.md :46 | the map reads every pick from the same build "under the same guards" | S in substance: `vd_commit`, `vd_published` and `vd_verify`. It does not run `vd_routed_check` or the fit guard, but it reads neither the routed table nor the fit, so nothing it uses goes unguarded |
| README :46 | what the article covers | S |
| discharge_publish.md :25 | `pick` becomes `is_default` at v2, not alone; the reasons | S: a decision record (findings.md, Decided) |
| discharge_publish.md :78 | routed gauge values and every segment's pick read from the parts; data script refuses unless they equal fwapg's; both refuse unless the report names the live build with nothing failed | S |
| fwapg_mad_method.md :19 | #71 removed the link, since the article no longer uses fwapg's annual table | S: 6be3e11:616-618 used it; the new article has no such link or claim |
| water_balance_method.md :69 | measured at 7b83959; that commit reproduces; later ones do not | U for "later ones do not" (finding 2) |
| water_balance_method.md :83 | the rule, with "(the Nechako Reservoir)"; off-line set; balance in the Liard | U for the parenthetical (finding 1); the rest S |

### The probe behind the "no watershed polygon of their own" verdict

`fwa_streams_watersheds_lut` (fwapg `load/fwa_streams_watersheds_lut.sql`) excludes segments whose `fwa_watershed_code` is `999…` or whose `local_watershed_code` is NULL. The 369,217 no-lut segments break down as:

| 999 code | no local code | segments |
|---|---|---|
| yes | yes | 170,773 |
| no | yes | 158,188 |
| yes | no | 37,416 |
| neither (no polygon at the midpoint) | | 2,840 |

So "no watershed polygon of their own" is accurate: FWA assigned them no watershed code.

## Checklist items checked against the diff

- integer64: ids are cast `::int`. The FWA maximum `linear_feature_id` is 868,144,683, under 2^31.
- `$` partial matching: every `$` key the article reads exists exactly in the bundles (`published$built`, `prov$far_low`, `mp$drawn`, `mp$min_order`).
- A guard that fails toward pass: `vd_published()` greps FAIL, and the pick check writes FAIL on any difference.
- A proxy is not the property: two proxies remain. `liard$pcic_routed == 0` stands in for "routed has none", and the "10" prefix stands in for the Liard. Both hold on the current data and were accepted at R2.
- One fact derived twice: the province counts come from the report and are held equal to the reader counts and fwapg.
- Chunk labels are unique. The `gh()` targets are tracked on main.
