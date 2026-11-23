# Code-check round 3: #168 channel-scale pilot (branch diff eaa12d9d...HEAD)

## Checklist read

- code-check.md: I read the prose of every H3 under `## Mechanisms`. I read in full: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it. I skimmed the rest of the Mechanisms prose: A wrapper's exit is not the work; Zero-length, empty, and unset; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. I did not read 24 of the 38 headings (the stand-alone rules, Security, Spreadsheets).
- code-check-r.md: I read `system2(stdout = TRUE)` warns on a non-zero exit; Postgres row order is never fixed unless the query fixes it. From the index lines only: `paste()` with a zero-length argument; `strsplit()` drops a trailing empty field (checked: `strsplit("", ",")` gives `character(0)`, so an empty `upstream_subids` gives `int(0)`); `match()` treats NA as a matchable VALUE; `ifelse()` with an all-NA test; `read.delim()` quotes by default; `on.exit()` at a script's top level; `sprintf("%g", x)` writes `Inf`/`NA` into SQL; Inside a dplyr verb, a column named like a local variable wins. I did not read 120 of 130.
- code-check-shell.md: from the index line only, `curl -o` without `-L` (`followlocation = TRUE` is set). I did not read 72 of 73.
- code-check-spatial.md: I read FWA `upstream_route_measure` misses the next segment's start; FWA main flow is not edge type 1000 alone; FWA lookup area follows watershed codes; A relation between FWA watershed codes is not a place; A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline (its second paragraph covers the shared node at distance 0). I did not read 91 of 96.

## Findings

- **[severity: bug]** scripts/channel_scale_pilot.R:59-66 (registered rule) and :571-580 (`steps`); report lines 219-220; research/pcic_channel_scale.md:46; the `name` cell of scripts/channel_scale_sites.csv's confluence row. The confluence test does not measure what its label says. The test is "upper minus the next segment up more than half the joining line's flow", and it is meant to find "June's step lands on the segment above the junction". FWA segments break at every confluence, so the segment above the junction usually ends where another line joins. The upper segment's flow then includes that other line, and the next segment up does not, so the test fires on an ordinary confluence at the upper segment's top.
  - Measured read-only on the same fwapg run with the same SQL: of the 110 junctions the report counts, 103 have another blue line joining at the top of the upper segment. At 94 of them, that line's June flow accounts for the step (step minus that flow is at most half the joining line's flow).
  - The confluence is one of these. Groundhog Creek (blue line 356353136, June 6.557 m3/s) joins Big Creek at measure 72786, the bottom of 700353187. The upper segment's top, 75185.48, is where Nadila Creek (blue line 356355602) joins, and Nadila carries 7.961 m3/s in June: 22.856 − 14.883 = 7.97.
  - PCIC's network routes Groundhog's outlets (4004878 and above) to 4004864, not through the outlet on the segment. That outlet, 4009311, has children 4004894 (Nadila Creek) and 4004895 (Big Creek above). Groundhog's lowest segment has share 0 under subid 4004864.
  - So the write-up's sentence "There the step is PCIC's own: the outlet placed on that segment carries the tributary in PCIC's network" is wrong, and the report's label "110 junctions where June's step lands above" names a count that is mostly ordinary confluences. The verdict does not move, since sites decide nothing.
  - Fix: the rule block stays as registered. Add an amendment note saying the test also fires where another line joins at the upper segment's top (94 of 110) and that the pick is one of those. Relabel the report line, and correct the write-up's confluence bullet and the site's name. A test that would find a real step: the flow just below the junction minus the upper segment's flow is less than half the joining line's flow, or the upper segment's step net of the lines joining at its top.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: bug]** research/pcic_channel_scale.md:3. "One amendment was made after the numbers were seen: rule 3's CMIP6 listing check, below." The script's amendment section (scripts/channel_scale_pilot.R:111-126) has three bullets, and the second is a rule-3 reading: "the domain's outlets" is read at the scored gauges' outlets only. Nothing below line 3 describes the amendment. Neither the verdict table nor its bullets say that the Coast's "CMIP6 routed" depends on it: under the code as first registered (7d6c7b1 to ee3ebdc) the Coast came out "none". The research file is the durable record of a pre-registered verdict, so the reader needs that dependence. Fix: give the count the script gives (or say "two rule readings"), and state in the verdict section that the Coast verdict rests on the amended reading.
  - **Rule:** none

- **[severity: bug]** CLAUDE.md (PCIC channel-scale line: "hydromosaic lists CMIP6 (9 GCMs, 8 on the coast, no TaiESM1) in every domain") and research/pcic_hydrology.md:45 ("hydromosaic lists CMIP6 streamflow in the Peace and Columbia too, and has no TaiESM1 series on the coast"). These state as facts about whole domains what the code read at the scored gauges' outlets only. That is 27 to 74 outlets per domain, against 10,691 to 14,605 outlets per domain in the report's flag table, as the script's own amendment note says ("not at every outlet of the domain"). research/pcic_channel_scale.md:25-26 and :71 scope it correctly ("at every scored outlet", "at any of the 74 outlets scored"). This is the same scope mechanism round 2 found in the amendment note, now in two other files.
  - **Rule:** none

- **[severity: bug]** research/pcic_channel_scale.md:16. "This settles what monthly_error.md's check 1 rested on: the scores of routed PCIC are scores of PCIC's own outflow." The pilot shows this at the 244 scored gauges with an outlet on their segment. The scores it refers to are taken at 283 gauges. At the other 39, routed PCIC is fwapg's interpolation by upstream sums and area share, not an outlet's series, as report line 27 and monthly_error.md's check 1 both say. Scope the sentence to the 244. monthly_error.md:67's "routed's errors here" is scoped by its paragraph and holds.
  - **Rule:** none

- **[severity: fragile]** scripts/channel_scale_pilot.R:408 (`files = list.files(dir, pattern = "\\.nc$", ...)`), used at :877-881 and in report lines 12 and 314-316. Two report lines treat every `.nc` file in the run's directory as a file this run read:
  - the provenance line "hydromosaic: N NetCDF files, md5 of their md5s";
  - the cost lines (`okb` keeps every logged 200 whose file is in `used`).

  `get_batch()` reads only its own batches. A batch fetched for another id set stays in the directory and gets counted, for example after any change to the sites (`ids_s`, `extra`) or the scored set. Today the counts are right: 346 files equal the 346 logged 200s, with no orphans. Return the files `get_batch()` actually read instead of the directory listing.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: fragile]** scripts/channel_scale_pilot.R:767-770 and the report legend at 922-923. The "CMIP6 GCMs" column is `min(n_gcm)` over the domain's outlets, while the legend says "listed under both SSPs at every gauge outlet of the domain". That is the size of the intersection. The two differ as soon as two outlets each lack a different GCM, so the column would read 8 when only 7 are listed everywhere. Today they agree: every one of the 74 coast listings lacks TaiESM1 under both SSPs and lists the other 8, and Fraser, Columbia and Peace list all 9.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: fragile]** scripts/channel_scale_pilot.R:582, 586 and report line 220 ("%.0f m from scored gauge"). `ST_Distance(s.geom, g.geom)` measures to the scored gauge's whole segment, not to the gauge as the rule says ("nearest, in BC Albers, to a scored gauge"). Every upper segment that touches any scored gauge's segment ties at 0 m, and `upper_lfid` then breaks the tie, not nearness. The pick is unchanged here: it is 08MB006's own segment, and any segment at 0 with a smaller lfid would have been picked first. But the "0 m from scored gauge" label means "0 m from the gauge's segment".
  - **Rule:** code-check-spatial.md "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline, not at the confluence"

- **[severity: fragile]** planning/active/task_plan.md, Phase 4's ticked box "Rules 1 and 2 at every site and scored gauge, with the mismatch type named where rule 1 fails: outlet placed on another segment, a lake outlet, a tributary landing on the segment above, an area-share interior segment, a series revised since fwapg's build, or a missing outlet". The code scores rule 2 only at scored gauges, so not at the headwater or at Hope (08MF005 is not in the scored set). It names the registered types instead: no series, networks disagree, lake outlet, hosts differ, unresolved. The box describes work that was not built.
  - **Rule:** none

## Mechanism and enumeration

**Mechanism.** A label or sentence names one object while the code computes the value at an adjacent object, chosen because it was available. All five earlier findings share this:

- the sub-basin outlet standing for the site;
- the scored gauges' outlets standing for the domain;
- a published column named in a label it did not fill;
- a cell nobody checked standing for "the rules' picks";
- a pre-reorder index standing for the reordered rows.

This round's main instance is the junction step standing for "this tributary's flow". Every place below was checked by comparing the label or sentence with the computation, on the data where it was cheap.

Report lines (data/checks/channel_scale_pilot_20260717.txt):
- L4 "rules: registered at" is the first commit whose rule-block md5 equals the run's. Holds.
- L5 "first fetch (after the registration)" is min(utc) over every fetch-log row, and the script stops otherwise. Holds.
- L6 "script ... at" is HEAD, with R/, scripts/, data-raw/ and inst/vignette-data clean. Holds.
- L7-8 routed line and fingerprint: held to the tracked routed report and pcic.runs. Hold.
- L9 "published: 512 parts, live parts md5" is `nrow(wet_catalog())` and `wet_catalog_digest()`. It equals the publish report (512 of 512, live parts md5 d554e3aa…). Holds.
- L10 "routed as published equals fwapg's table": compared on months 1-12, plus the NA pattern on all 13 rows. Holds.
- L11 "scored gauges ... (283)": the article's set. Holds.
- L12 "hydromosaic: 346 NetCDF files" is a directory listing, not the files read. Right today; fragile (finding 5).
- L13 gridded cell count. Holds.
- L16-17 portal: substring counts in the bundle. Holds.
- L20-24 domain table. "gauges" is the domain of the segment's sub-basin, summing to 283. "with outlet" and "rule1 n" are r1_n, summing to 244. "CMIP6 GCMs" is a min standing for an intersection: right today, fragile (finding 6). Pass %, rule medians and verdicts are as coded. Holds.
- L25-26 legend. Holds, except for the GCMs wording (finding 6).
- L27 "no outlet on their segment: 39": the DB shows 38 segments with no placed outlet plus one gauge sharing a segment. Holds. 61 gauges have two placed outlets on their segment, and the scored one is the segment-weights subid, which is what the published value is.
- L28-32 "GCMs with no series at the domain's gauge outlets" is ssp245 bulk-missing per domain. Holds.
- L33 "among fetched outlets" excludes the headwater's `extra` outlets fetched for PNWNAmet. Wording is loose; no number is affected (no PNWNAmet series is missing).
- L36-41 flag shares: every crosswalk flag is in the factor levels, and 48,716 equals the crosswalk's row count. Holds.
- L44-52 rule 1 counts, ratio range, types, beehive line, not-exact rows (agree n at both). Hold.
- L55-209 rule 2 counts, domain medians and p90, failing list. Hold. The coast medians are over 8 GCMs, as amended.
- L212-218 sites table. Hold. For the headwater, the subid, flag, dist and rank columns are its outlet's crosswalk row, and own=n shows that.
- L219 "headwater: 19389 candidates" holds. "110 junctions where June's step lands above" is wrong in meaning (finding 1).
- L220 "0 m from scored gauge" is distance to the gauge's segment (finding 7). The station cell is now checked.
- L222-231 annual table: the interior site is rebuilt and marked as rebuilt. Holds.
- L232 pre-2015 difference "at the sites" includes the headwater's outlet. The line is unlabelled by site, so acceptable.
- L233-240 base ratios: starred, with the note, and "over the 9" holds (all six sites are in the Fraser).
- L243-294 change signals: starred, against the same scenario's 1981-2010. Hold.
- L297-311 water temperature: starred rows, and water-temp-bc at the five gauged sites. Hold.
- L314-316 cost: "requests" counts the successful requests whose files are kept. The 422s are excluded; they cost about 62 s on first occurrence across all runs, which is immaterial. Hold. The whole-run projection holds (48,688 = 48,716 − 28 no_series).

research/pcic_channel_scale.md:
- line 3, provenance: 7d6c7b1 and 01:46:50, 01:47:59, 512 parts, d554e3aa all hold. "Two runs ... byte-identical" holds: report_run8 and report_run9 equal the tracked report. "One amendment ... below" is a miscount and points at nothing (finding 2).
- line 11-14, verdict table: every value is a report line. Holds. The Coast row's dependence on the amendment is unstated (finding 2).
- line 16: 244, 242, 0.12 % and 08LE031 with networks disagreeing all hold. "the scores of routed PCIC are scores of PCIC's own outflow" is over-scoped (finding 4).
- line 17: 7.3, 36, 2.0, 3.3, 1.5 above, 0.036. Holds. "The median of the 9 GCMs" is 8 on the coast, a minor wording point.
- line 18: advice only, no number.
- line 22: portal. Holds.
- line 23: 1950–2012, 1950–2100, MBCn, DO_sat and the standard calendar are pcic_hydrology.md's record and the listings (checked in 2010082.json). The calendar is enforced in `nc_read()` for the files read. Holds.
- line 24: holds as description.
- line 25: "at every scored outlet". Holds. The July 2026 correspondence is pcic_hydrology.md:39.
- line 26: "74 outlets scored; the other 8 GCMs are complete". Holds (ssp245 bulk, both SSPs listed).
- line 27: 720 m3/s and 3.5 %. Hold. The MBCn parenthetical is offered as a possible cause.
- line 31: holds; 08MB006 is "BIG CREEK ABOVE GROUNDHOG CREEK" in HYDAT 20260717.
- line 35-40, sites table: every value is a report line. Holds.
- line 44: "rebuilt exactly" holds at the printed 5 decimals. The share 0.361 holds.
- line 45: 0.014 % and 2.7 %. Hold.
- line 46: "110 junctions where June's step lands on the segment above" and "carries the tributary in PCIC's network" are wrong (finding 1).
- line 52: 3.69 and 0.08. Hold.
- line 53: −0.2 % to +19.8 %, and March–April up, July–September down at every site. Hold.
- line 54: 12.7 to 26.7 °C, all in August; 409 days, 0.50, 3.06. Hold.
- line 62-67, flags: hold. "Almost all ... no_candidate" holds: 94 % in the Columbia, 99 % in the Peace. 150 m is fwapg's.
- line 71: "at every outlet scored". Holds.
- line 72: 2,194, 798 MiB, 35 min, 48,688, 17 GiB, 13 h. Hold. "Three batches" and 1.5 h are fwapg's, as checked in round 1.
- line 73-74: hold.

CLAUDE.md:
- Scripts line: rule 1 "at every scored gauge whose segment holds a placed outlet" is coded as "the segment's weights subid is placed on that segment". These agree on the data: no scored gauge's segment holds a placed outlet that is not its subid. Holds. "refuses unless it holds the rules' picks" holds since round 2.
- Data Sources line: "lists CMIP6 ... 8 on the coast, no TaiESM1 ... in every domain" is over-scoped (finding 3). The verdict sentence holds.

Other research files:
- research/README.md row: 244, 8 GCMs and 0.082 hold. "(8 GCMs)" is scoped by the row's own wording to the rule-2 result; acceptable.
- research/monthly_error.md:67: holds. "within 0.12 %" is accepted.
- research/pcic_hydrology.md:45: "no TaiESM1 series on the coast" and "lists ... in the Peace and Columbia" are over-scoped (finding 3). The rest holds.

Guards:
- Site-table `identical(sites, want)`: covers stations, segments, measures, WSG and regulation, in row order. It holds what it says. It cannot catch that the confluence rule itself mislabels its pick (finding 1).
- `rule_block` md5 against history: holds.
- First fetch after the registration: holds for the log as kept.
- Dirty check: holds for code. data/checks and research are excluded by design.
- Routed report and fingerprint: hold.
- Published equals fwapg: holds.
- Bundle routed_mm equals published month 0: holds.
- `check_days` listing match: holds.
- `stopifnot(share == 1)` at gauge outlets: holds.
- Placed outlet's FWA basin equals its subid's domain: holds.
- `bulk()` "holds other outlets than its batch": holds per file, but the provenance and cost lists bypass it (finding 5).
