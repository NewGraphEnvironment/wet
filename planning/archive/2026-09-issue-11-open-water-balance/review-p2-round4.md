# Review: Phase 2 of #11 (HYDAT stations), round 4

Scope: the round 3 fixes, which are the `wet_snap_lake()` outlet flag, the `subsubdrainage` rename and the HYDAT release read from `VERSION`. I ran everything in a scratch copy of the repo against the local fwapg and HYDAT, read-only.

## Findings

- **[severity: medium, flag means something other than its label (the round 3 mechanism, still present)]** `R/wet_station_snap.R`, the `wet_snap_lake()` EXISTS clause. It is labelled as a lake outlet in the report line (`accepted lake outlets ...: 27`), in the column and in decision 9.
  - What the code computes is: *any lake of at least 100 ha within 3 km of the gauge in a straight line, with at least one segment anywhere upstream on the network.* That lake need not be on the station's own stream, and it need not drain a meaningful share of the station.
  - I re-ran the query and got the same 27 as `stations.rds`. For each lake I compared the lake's own upstream area (the max of `fwa_watersheds_upstream_area` over its segments) with the station's snapped area. **6 of the 27 accepted flagged stations are not lake outlets.**

    | station | name | lake (ha) | lake's area / station's area | why it is flagged |
    |---|---|---|---|---|
    | 09AE003 | Swift River near Swift River | unnamed, 103 | 8.4 / 3,388 km2 = **0.25 %** | small lake on a tributary 640 m away |
    | 10AC006 | Dease River near the mouth | Ten Mile Lake, 115 | 43.7 / 14,553 = **0.3 %** | tributary lake |
    | 08MH001 | Chilliwack River at Vedder Crossing | Cultus Lake, 636 | 75 / 1,232 = **6 %** | tributary lake. Chilliwack Lake is more than 3 km away |
    | 08HD015 | Salmon River above Campbell Lake Diversion | Paterson Lake, 191 | 31.6 / 260.6 = **12 %** | tributary lake |
    | 08NK019 | Grave Creek at the mouth | Grave Lake, 125 | 13 / 81 = **16 %** | lake on a side branch, not on the gauge's blue line |
    | 08GA079 | **Seymour River ABOVE LAKEHEAD** | Seymour Lake, 263 | 123 / 82.4 = **149 %** | an inlet: the lake is downstream |

  - **Why 08GA079 is flagged, which is the part that is not just a threshold choice.**
    - The gauge snaps to blk 360886339 at measure 26,424, where `localcode` is `900.078372.630243` and `wscode` does not equal `localcode`.
    - The Seymour Lake segment 189054727 on the **same** blue line lies downstream, at drm 25,871–25,917. It carries a malformed localcode, `900.078372.657022.093449`, which is larger than the gauge segment's even though the segment is downstream. The segments on either side of it are `.627281` and `.630243`.
    - Blue-line measures would place that segment downstream. `fwa_upstream()` instead returns TRUE through its "capture side channels" branch (`wscode_b = wscode_a AND localcode_b > localcode_a`).
    - So an FWA code anomaly can turn an inlet into an "outlet". The existing test pins one inlet, 08LE077, and still passes, because Shuswap's segments have no such anomaly.
  - **Consequence.** These are 6 of 27, about 22 %, in a tracked count and in an rds column that later phases may use as a covariate or an exclusion. Two thirds of the error comes from tributary lakes, which is the same "the label names a category, the code computes a proxy" defect that round 3 found.
  - **Cheap discriminating fix.** Also require the lake's own upstream area to be a substantial share of the station's snapped area and not larger than it, for example `0.5 <= lake_km2 / upstream_area_km2 <= 1 + max_dev`. `fwa_watersheds_upstream_area` is already joined in the candidate query and can be joined through `fwa_streams_watersheds_lut` on the lake's segments.
    - On this run that leaves 21 flagged and removes exactly the 6 above. It keeps 08OB002 (Mosquito Lake, 76 %) and every textbook outlet: 08JB003, 08LD001, 08KD001, 08FA002, 07EE010 and 08MG013.
    - The upper bound also catches the 08GA079 localcode anomaly without relying on `fwa_upstream`.
    - The alternative is to relabel the column and the report line as "a lake of 100 ha or more nearby and upstream on the network". The report's parenthetical already says roughly that, but the headline word "outlets" and the column name do not.
  - A test on 08GA079 or 09AE003 expecting FALSE would pin the fix.

## Checked, no defect

- **Argument order of the 8-arg `fwa_upstream`.** It is correct: a is the snapped point (blk, measure, segment wscode and localcode from the `fwa_indexpoint` row) and b is the lake segment. The 8-arg form forwards the measure as both the downstream and the upstream measure of a.
- **`include_equivalents = false`.** It excludes only a lake segment whose downstream measure is within 1 mm of the point. I computed the flag both ways for every station and lake pair within 3 km: they are identical for all 352 stations. A same-blue-line lake just upstream is counted, because its segments have drm >= measure.
  - A gauge inside the lake polygon also counts through the lake's segments above the snap. The one case is 08FA002, Wannock River at the outlet of Owikeno Lake, which is correctly TRUE.
- **`match()` between picked and candidates.** No `station_number + linear_feature_id` pair repeats among the 1,638 real candidates. That is expected, because `fwa_indexpoint` returns distinct segments. The pairing is also safe if it did repeat, since blk, measure and the codes come from the same indexpoint row.
  - A station with no pick has `linear_feature_id` NA. That never matches, because candidates always carry an id, so the station gets `lake = NA`.
  - Results are written back by `station_number`, so row order from Postgres does not matter.
- **Types.** `blue_line_key` arrives as R integer (int4) and round-trips as integer. `measure` is double and `seg_wscode`/`seg_localcode` are text, cast back with `::ltree`. There is no integer64 anywhere in the `p` table.
- **Temp tables.** The `wet_snap_` and `wet_lake_` prefixes differ, each name has a random 12-letter suffix, and each table is removed on exit with `temporary = TRUE`. There is no collision between the two calls.
- **Re-run reproducibility.** `wet_station_snap()` on the 352 stations reproduces `lake` in `data/wb/stations.rds` exactly (`identical()` TRUE). It gives 27 accepted TRUE and 3 rejected TRUE.
- **Relabels.** `subsubdrainage = substr(,1,4)`, and the heading "97 sub-sub-drainages in 18 sub-drainages" uses `substr(,1,3)` for the latter, which is correct. HYDAT release `2025-10-14 15:09:54` comes from `VERSION.Date`. The `research/runoff_prior_art.md` wording (`08LB` sub-sub-drainage, `08L` sub-drainage) is correct.
- **Residual, not a defect.** The task_plan line 792 still says "accumulated upstream FWA area". Round 3 measured the stored and accumulated areas as equal for these stations.
