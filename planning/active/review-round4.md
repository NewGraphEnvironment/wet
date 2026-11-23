# Code-check round 4: #168 channel-scale pilot (round-3 fixes 0eee97b, 47281a0)

## Checklist read

- code-check.md: I read the prose of every H3 under `## Mechanisms`, all fourteen. I read in full: A proxy is not the property; One fact derived twice; A guard's scope, escape hatches, and remedies; Verification that reads its own output. I did not read the stand-alone rules, Security or Spreadsheets.
- code-check-r.md: I read in full "Postgres row order is never fixed unless the query fixes it". From the index line only: "Inside a dplyr verb, a column named like a local variable wins". Not relevant: there is no dplyr here, and the `<<-` closure in `bulk()` was checked directly.
- code-check-spatial.md: I read in full "FWA `upstream_route_measure` misses the next segment's start", "FWA main flow is not edge type 1000 alone", "FWA lookup area follows watershed codes, so side channels get the river's" (its sentence on a segment with no row applies to finding 1), "A relation between FWA watershed codes is not a place", and "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline".
- code-check-shell.md: nothing here; the diff has no shell code.

## Findings

### 1. [bug] The report's 104 and 94 and the write-up's 94 undercount

Places: scripts/channel_scale_pilot.R:591-601 (the `tops` CTE); report line 220 ("at 104 another line joins at the upper segment's top, and at 94…"); research/pcic_channel_scale.md:46 ("at 94 of them").

What the code does: `tops` takes each top-joining line's June flow from the line's lowest segment (`LATERAL … ORDER BY downstream_route_measure LIMIT 1`), then inner-joins the routed table.

What goes wrong: at 3 of the upper segments, the lowest segment of the line joining at the top is an edge-1450 connector with no routed row. The line therefore drops out of `tops`. The comment above `steps_sql()` says the line counts: "any other line whose mouth is at the upper segment's top".

Measured read-only, running the script's own `steps_sql()` against the local fwapg:
- All 110 steps have distinct upper segments.
- 107 of them have exactly one other line joining at the top, not 104.
- The 3 dropped lines:

| line | at upper segment | June step | line's first segment with flow | its June flow | explains the step? |
|---|---|---|---|---|---|
| South Thompson River, 356361760 (lowest segment 703314561 has no rows) | 703314576 | 744.037 | 703042447 | 744.064 | yes |
| 355997521 | 700575649 | 1.111 | 700575688 | 2.344 | yes |
| 355994730 | 701599993 | 2.672 | 701599795 | 0 | no |

- So the true count is 96, not 94. It is the same 96 under both readings, "at least half the step" and "step net of that line is at most half the joining line's flow". On the 104 lines that have flow, the two readings agree exactly at 94, so the report's wording "at least half the step … an ordinary confluence the test misreads" holds.
- The case the code misses is the clearest ordinary confluence in the set: the South Thompson joins at the top of the segment the North Thompson junction sits on.

What does not move: the verdict and the pick. At the pick, one line (356355602) joins at the top, with flow.

Fix: take the line's flow from its lowest segment that has a routed row. Or LEFT JOIN, and count separately the lines that have no routed flow at their mouth. Then correct "104" and "94" in the report, and "94" in the write-up.

**Rule:** code-check.md "A proxy is not the property". The lowest segment stands for the line's flow. See also code-check-spatial.md "FWA lookup area follows watershed codes…" on segments with no row.

### 2. [bug] The write-up misdescribes routed flow at the other 39 scored gauges

Place: research/pcic_channel_scale.md:16, the parenthetical added in round 3: "(at the other 39 scored gauges routed flow is fwapg's share of a sub-basin's runoff)".

Neither the code nor the report supports this. The script's rule 1 states the interior value as sum raw(upstream_subids) + (raw(subid) − sum raw(placed outlets first reached)) × share.

Measured on `pcic.segment_weights` for the 39 gauges with no outlet on their segment:
- 28 have upstream outlets (`upstream_subids` not empty).
- 8 have share 1.
- Examples: 08JB002 has share 1.0 and 15 upstream outlets; 08MA002 has share 1.0 and 14.

At most of these gauges, routed flow is mostly PCIC's own outflow from the upstream outlets plus an area share of the remaining local flow. It is not "a share of a sub-basin's runoff". This is the same label-versus-computation mechanism, inside a round-3 fix.

Fix: state it as the rule does: "the upstream outlets' series plus fwapg's area share of the sub-basin's remaining flow".

**Rule:** none.

### 3. [fragile] `q_top` and `top_blk` can come from different lines

Places: scripts/channel_scale_pilot.R:592 (`max(qx.q_m3s) AS q_top, min(bp2.blue_line_key) AS top_blk`) and report line 221 ("at the pick a line (blue line %s) joins at the top with %.3f").

The two aggregates run independently over the lines joining at one top. If two lines join at the pick's top, the report would print one line's key beside the other line's flow.

Today every upper segment with a top-joining line has exactly one (107 of 107), so the printed pair, 356355602 with 7.961, is right.

**Rule:** none.

### 4. [fragile] The provenance and cost lines would miss beehive files

Places: scripts/channel_scale_pilot.R:907 (`used <- c(pnw$files, …gcm…, wt$files)`) and report line 12.

The round-3 fix makes `files` the files each call to `bulk()` read. But `bee <- run_clim(recheck, …, host = "beehive")` (line 759) is never added to `used`. If rule 1 ever needs the beehive recheck, the "hydromosaic: N NetCDF files, md5 of their md5s" line would leave out the series that typed the failures.

Today no outlet needs it (report: "beehive: no outlet needed it"), so 346 is right.

**Rule:** none.

## Enumeration

Places the round-3 fixes touched or added:

- `steps_sql()` junctions and steps CTEs: they are fwapg qa.sql's, plus the Fraser filter and the run filter. They match extras/pcic_crosswalk/sql/qa.sql:186-207. Holds.
- The `tops` CTE: its join on `path_blks[1] = main_blk` and the 1 mm measure at the above segment's start correctly finds lines whose mouth is at the upper segment's top. Its lowest-segment flow drops 3 lines. Finding 1.
- `pick_confluence()`, `n_steps` = 110: holds. Rows equal distinct upper segments.
- `n_top` = 104, labelled "another line joins at the upper segment's top": wrong; it is 107. Finding 1.
- `n_top_explains` = 94, labelled "that line's June flow is at least half the step": the criterion matches the label, and it is the same set as the "test no longer fires net of it" reading. The count is 96 once the three lines are counted. Finding 1.
- The pick's top line: 356355602, 7.961 m3/s, and step 7.972. Holds. The aggregate pairing is fragile (finding 3).
- Report line "0 m from scored gauge 08MB006's segment": holds.
- Amendment note, fourth bullet: "fires mostly on ordinary confluences" holds at 94 or 96 of 110, and "the pick is one" holds. It sits below the rule block, and the rule block md5 is unchanged (93530d55…). Holds.
- Site csv name "Big Creek above Groundhog Creek (a confluence)": this is HYDAT's name for 08MB006, and the segment is the one above Groundhog's junction. Holds. The guard does not check `name`, which is acceptable.
- Write-up confluence paragraph: "110" holds and "94" should be 96 (finding 1). "a creek joining at its top carries the step" holds. "its published flow is the outlet's series" holds (rule 1 1.00000 at the confluence). "inflates the count fwapg's sql/qa.sql holds under 1,000" is accepted (fwapg#59).
- Write-up amendments sentence on line 3: it lists four amendments, matching the script's four bullets. Holds.
- `bulk()` returning the files read: the `read <<-` from nested `get_batch()`/`halve()` reaches `bulk()`'s frame. The report's 346 is unchanged and equals the 346 logged 200s. Holds, apart from the beehive omission (finding 4).
- `dom$gcms` intersection: `Reduce(intersect, strsplit(...))` gives 0 for an outlet with no GCMs, and with one outlet it gives that outlet's set. The report shows 9/8/9/9, matching the legend "listed under both SSPs at every gauge outlet". Holds.
- CLAUDE.md channel-scale line: "at the scored gauges' outlets hydromosaic lists CMIP6 in every domain (9 GCMs, 8 on the coast, no TaiESM1)". Holds.
- research/pcic_hydrology.md:45: "At the scored gauges' outlets … no TaiESM1 series at any coast outlet scored". Holds (TaiESM1 missing at 74 of 74 coast outlets).
- Write-up check-1 sentence: scoped to the 244 gauges, which holds. The parenthetical on the 39 is wrong (finding 2).
- task_plan.md Phase 4 box: holds as a description of what was built, but its "as built" list of types leaves out "no series", which the code assigns (r1$type) and no gauge took. This is a planning note and moves no number.
- planning/active/findings.md:72 still describes the pick as "the junction where June's step lands on the segment above". This is pre-round-3 wording that round 3 disproved. It is an append-only planning log, but the archive README should not copy it.
- Report lines that did not change in round 3 (provenance, domains, rules 1 and 2, sites table, annual table, signals, temperature, cost): unchanged except the script sha, and round 3's verdicts stand.

/Users/airvine/Projects/repo/wet-168/planning/active/review-round4.md
