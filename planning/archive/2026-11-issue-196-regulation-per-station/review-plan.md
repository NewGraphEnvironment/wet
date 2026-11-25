# Plan review for #196 (Backlog move 14: Regulation per non-HYDAT station), 2026-11-23

Blockers raised: 2
Owner forks: 4

Reviewer: Plan agent, read-only, against the issue (#196, #191), `planning/backlog.md` move 14 / batch 16, and the code the plan names. Each finding was probed before it was folded; verdicts below.

## Findings and verdicts

- **B1 (Blocker): the script took its population and name test from `wet_station_list()`, whose `regulation` column the plan makes it write.** Confirmed by reading `R/wet_station_list.R:56-88`. Folded: the script never calls `wet_station_list()`; population from the two registry readers, folded as `wet_station_list()` does; name test from `regulation_of()`.
- **B2 (Blocker): the dam code was written with an en dash; the register writes `Regulated - Part 3 Exempt` with an ASCII hyphen (290 dams).** Confirmed on the cached #53 snapshot (table printed during exploration). Folded: exact strings in the rule, and a stop on any value outside the known code sets.
- **G1 (Gap): no snap query; `wet_station_snap()` does not select `gnis_name`.** Confirmed at `R/wet_station_snap.R:50-67`. Folded into the lib.
- **G2 (Gap): "gnis_name appears in the name" matches two streams in names like "Unuk River upstream of Sulphurets Creek", none in "Brucejack Lake Outflow".** Accepted. Folded: match on `stream_of()` (`scripts/station_sources_lib.R:35-53`), ties by distance then id; an area-only leg offered to the owner in open decision 1.
- **G3 (Gap): no branch for a segment without published flow.** Accepted; folded as an unknown branch.
- **G4 (Gap): power licences and upstream area outside BC are invisible to the registers.** Accepted; folded into open decision 1 as unknown branches.
- **G5 (Gap): "in force on the snapshot date" undefined.** Accepted; folded: `LICENCE_STATUS == "Current"`, any `POD_STATUS`, `split` straddle.
- **G6 (Gap): the registers' licence recorded only in planning.** Accepted; folded into research, report, status file and docs.
- **G7 (Gap): no follow-up issue for the deferred donor pool.** Accepted; Phase 4 files it.
- **G8 (Gap): status file not tied to the registries.** Accepted (mechanism); folded: both snapshots and registry md5s stored and checked; missing status file is an error.
- **G9 (Gap): mocked-registry tests would break.** Confirmed at `tests/testthat/test-wet_station_list.R:54-73` and `tests/testthat/test-wet_station_daily.R:477,487`. Folded: internal `wet_station_regulation()` mocked there.
- **G10 (Gap): docs that say these stations are not donors.** Confirmed at `R/wet_station_daily.R:22-25`, `research/station_sources.md:35`, `CLAUDE.md:80-81`. Folded into Phases 3 and 4.
- **G11 (Gap): Tool areas come from `wet_bcwatertool_read()$meta`, not `wet_bcwatertool()`.** Accepted; folded.
- **G12 (Gap): 58 provincial stations at a HYDAT site go unused.** Accepted; folded as the rule's reported outside check, and HYDAT's area offered for the snap's area test.
- **G13 (Gap): no amendment protocol.** Accepted; folded.
- **O1 (Ordering): rule function tested after it is applied.** Accepted; the rule file and its tests are Phase 1, before the script exists.
- **O2 (Ordering): open decision 2 assumed a period-of-use field.** Confirmed false: `DescribeFeatureType` for `WLS_WATER_RIGHTS_LICENCES_SV` (read 2026-11-23) has no such field. Open decision 2 rewritten.
- **A1 (Assumption): the Tool's drainage-area unit is not stated.** Accepted; Phase 1 checks it before registering.
- **A2 (Assumption): `DAM_REGULATED_CODE` is a dam-safety class.** Accepted; the rule says so.
- **A3 (Assumption): #53's shared-group assertion held by data.** Accepted; kept as a stop.
- **A4 (Assumption): `wet_segment_monthly()` does not verify parts.** Accepted; `wet_catalog_verify()` and the digest added.
- **S1 (Scope): reservoirs were decided in the plan though "which registers enter" is the owner's.** Accepted; moved into open decision 1.
- **S2 (Scope): one PR only under decisions 3 and 4 as recommended.** Accepted; stated in decision 4 and the frame.
- **S3 (Scope): a test of a doc change.** Accepted; dropped, reason given in decision 3.
- **AC1 (Acceptance): "rule commit precedes placement" is uncheckable, since placements commit nothing.** Accepted; the report names the rule's sha and the script refuses any other.
- **AC2 (Acceptance): byte-identical rerun needs every input cached.** Accepted; folded.
- **AC3 (Acceptance): guard proofs covered only the reader.** Accepted; script defects added.

## Files the plan names

R/wet_station_list.R
R/wet_station_select.R
R/wet_station_daily.R
R/wet_bcwatertool.R
R/wet_station_snap.R
R/wet_segment_monthly.R
R/wet_window_extend.R
scripts/wb_gauge_diversion.R
scripts/wb_small_basin_rule.R
scripts/station_sources_lib.R
scripts/station_sources_harvest.R
scripts/segment_group.R
scripts/departure_site.R
scripts/station_regulation_rule.R
scripts/station_regulation_lib.R
scripts/station_regulation.R
data-raw/station_sources_snapshot.R
data-raw/station_sources_bcwatertool.R
inst/extdata/station_sources/
research/station_sources.md
tests/testthat/test-wet_station_list.R
tests/testthat/test-wet_station_daily.R
tests/testthat/test-wet_station_select.R
tests/testthat/test-wb_small_basin_rule.R
tests/testthat/test-station_regulation_rule.R
CLAUDE.md
NEWS.md
planning/backlog.md
