# Plan review: #195, backlog move 13 (second sources for the provincial stations), 2026-11-23

Blockers raised: 2
Owner forks: 3

A `Plan` agent read the drafted plan against #195, #144, #190, #192, #179, `planning/backlog.md`, the code it names and the survey's raw Tool copy (read-only). Each finding below was probed before it was folded; the probes that reproduced it are named. Everything is folded into `task_plan.md` and marked "(review)" there.

## Blockers

- **B1. The rule for choosing listings would read the Tool's 17 copies of provincial stations, filed under "Regulator – BC Oil and Gas Commission", and the registry check would stop the build.** Reproduced: of 120 third-party listings after the survey's filters and `nid` dedup, 17 have a `nid` the provincial registry holds, all in that network. Folded: drop by `nid` against the provincial registry as the probe's `wt_own` did; the refusal stays as a last check.
- **B2. Tier (i) could not reproduce the survey's Tool rows from a pin holding only the stations read.** The survey's third-party rows and "Per network" lines count stage-only and shared-site listings. Folded: the manifest lists all 391 entries and the geojson; the reader has an internal survey mode; tier (i) is restated as four checks (AC1). How much is cached and backed up went to the owner (S3).

## Ordering

- **O1. The bound would be applied by the pinning run before it was registered.** Folded: registration is the phase's second step.
- **O2. The pinning step as placed would stop in a worktree, or re-upload ~740 MB of provincial files.** Folded: a separate `data-raw/station_sources_bcwatertool.R` with an absolute `WET_BCWATERTOOL_RAW`.
- **O3. Decision 2's facts wrong (see A1).** Folded.
- **O4. Existing `test-wet_station_list.R` lines hold the default to the provincial source.** Folded: named in the tests-first step.

## Gaps

- **G1. The shared-site rule was undefined.** Folded: the probe's 0.5 km same-stream rule against the whole provincial registry, copied into `scripts/station_sources_lib.R`, held to the survey's seven.
- **G2. No daily-row check in the Tool tier.** Folded: the probe's `read_wt()` parse copied verbatim and compared with the survey mode.
- **G3. No run-time refusal of a number in both registries.** Folded.
- **G4. What can be shared.** Folded: `wet_bcenv_check()` shared; a Tool manifest validator; a parent unavailable class.
- **G5. `HRB5454` is two stations.** Folded: the dropped listing is reported.
- **G6. The backup path belongs in `CLAUDE.md` and the R comments, as #142 did, not memory only.** Folded.
- **G7. The park was not yet resumable (no Resume block, branch not on origin, planning files untracked).** Not a plan defect: the draft was reviewed before the baseline commit, which writes, commits and pushes all three.
- **G8. The `planning/backlog.md` edits were not all named.** Folded.
- **G9. Records-not-donors and `\u` escapes.** Folded.
- **G10. Names and coordinates from the station list, untrimmed.** Folded.

## Assumptions

- **A1. Seven Tool listings sit at provincial sites, not six (4603, Tsolum River, too); three BCCF sites lose 2012–2015; Tofino's Tool records run to 2016 and start a day earlier.** Reproduced: the survey report's line 381 gives 4603 the provincial same-site column. Folded into open decision 1.
- **A2. The "provincial rule" bound gives every Tool station the province-wide 2,490.71.** Read in `R/wet_bcenv_daily.R`'s `wet_bcenv_ratio()`: no read `nid` gives a sub-drainage with its own bound. Folded into open decision 2 with a location-based alternative recommended.
- **A3. No Tool CSV carries l/s.** Reproduced: every "Preliminary Discharge" row's unit is `m3/s`. Folded: conversion dropped.
- **A4. 389 CSVs and 2 `.status` files; both HTTP-500 ids are provincial listings.** Folded.
- **A5. The BC ENV network name uses an ASCII hyphen.** Folded.
- **A6. Example `nid`s that will not be read.** Folded.
- **A7. "#190 does not block #144" holds only under decisions on the shared sites and the BC ENV pair.** Folded: stated as conditional.

## Scope

- **S1. The split of #190 and #192 is the plan's call under `planning/backlog.md`'s header, not an owner fork.** Agreed and folded: decided by the plan, each owner question moved into its split issue's body.
- **S2. 46 stations are read, not 35.** Reproduced: 53 third-party listings hold discharge once the provincial copies are out; less the 7 at provincial sites, 46. Folded into the plan, the tests and NEWS.
- **S3 (owner fork). How much of the snapshot is cached and backed up**, given DFO's non-commercial header and #190's use for the Tool's provincial copy. Open decision 4.
- **S4 (owner fork). Decision 1 (shared sites) re-put with correct facts and option (c), a `bcenv_site` column.** Open decision 1.
- **S5 (owner fork). Decision 2 (bound) re-put with correct facts.** Open decision 2.

## Acceptance

- **AC1. Tier (i) as four checks** (daily rows, 103 station rows, 13 network lines, the passing and shared-site sets). Folded.
- **AC2. Expected counts fixed before the run, every left-out listing reported with its reason.** Folded.
- **AC3. Tests for the Tool validator, the parent class, and registries not opened when not needed.** Folded.

## Files the plan names

planning/backlog.md
R/wet_bcwatertool.R
R/wet_station_daily.R
R/wet_station_list.R
R/wet_bcenv.R
R/wet_bcenv_daily.R
data-raw/station_sources_bcwatertool.R
data-raw/station_sources_snapshot.R
inst/extdata/station_sources/
scripts/station_sources_harvest.R
scripts/station_sources_lib.R
scripts/station_sources_probe.R
data/checks/station_sources_20260717.txt
data/checks/station_sources_harvest_20261028.txt
research/station_sources.md
tests/testthat/test-wet_bcwatertool.R
tests/testthat/helper-bcwatertool.R
tests/testthat/test-wet_bcenv.R
tests/testthat/test-wet_station_daily.R
tests/testthat/test-wet_station_list.R
CLAUDE.md
NEWS.md
_pkgdown.yml
