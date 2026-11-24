# Code-check round 1 (#196, branch diff against 0e56d60e)

## Checklist read

- code-check.md: every H3 under `## Mechanisms`, prose only (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; and the rest from the index). Rules that stand alone, Security and Spreadsheets were not read: 20 headings.
- code-check-spatial.md, read: BC's water rights licence view repeats a row per licensee; FWA lookup area follows watershed codes; A relation between FWA watershed codes is not a place; The BC WFS caps an un-paged `GetFeature` at 10,000 features. Not read: about 95.
- code-check-r.md, read: Postgres row order is never fixed unless the query fixes it; `system2(stdout = TRUE)` warns on a non-zero exit. Checked against the index line only: `nzchar(NA)` is TRUE; `sort()` and `order()` collate by `LC_COLLATE`; `on.exit()` at a script's top level; `match()` treats NA as a matchable VALUE; A `function(...)` mock hides arguments. Not read: about 120.
- code-check-shell.md: none read (the diff has no shell code). Not read: about 110.

## How it was checked

I made a detached worktree of HEAD under the scratchpad, copied `data/station_regulation/` into it and ran a copy of `scripts/station_regulation.R` there, with probes added at the end (WET_HYDAT_RELEASE=20260717, local fwapg, live manifest). The run rebuilt both tracked outputs byte for byte (`git status` was clean in the copy). Then I deleted the worktree. Nothing in the repo was written apart from this file. The fwapg queries ran read-only.

## Findings

- **[bug]** scripts/station_regulation.R:243-244, which use scripts/station_regulation_lib.R:121-122: L and S count groundwater wells, but the rule counts surface PODs only.
  - The rule header (scripts/station_regulation_rule.R:63) counts licences that are "located, surface (POD_SUBTYPE "POD"), not a rediversion, quantity > 0". #53 applies that filter in its per-gauge mask, `base_mask <- u$surface & !u$replaced` (scripts/wb_gauge_diversion.R:284).
  - `rg_licence_rows()` copies `lic$candidate` from #53, which has no surface test. The script then sums `cons <- u_lic$candidate & u_lic$class == "consumptive"` and `stor` with no `surface` either. So PG and PWD (well) PODs count toward L and S: 9,420 of the 67,501 candidate rows (PG 1,025, PWD 8,395), and 4,840 station-point pairs upstream.
  - Measured on the cached run:
    - 08GA0005 is regulated with L 44.5 %; surface only it is 3.8 %, so natural.
    - 08HA0027 is regulated with L 18.3 % and S 0.7 %; surface only it is 9.1 % and 0.4 %, so natural.
    - No other station changes.
  - The report's line "counted (located, surface, ...) 58081" (station_regulation.R:336-337) counts `candidate & surface`. So it describes a set the statuses did not use.
  - Errors in this direction are false regulated, never false natural. But the shipped statuses, the report, and the counts in research/station_sources.md and CLAUDE.md ("55 licensed use of at least 10 %", "110 regulated") are not the registered rule's.
  - Fix: add `& u_lic$surface` to `cons` and `stor` (and to `n_cons` and `n_stor` through them), or add `surface` to `candidate`. Check that the shared-group stop at lib:125-128 still holds, then rerun.
  - **Rule:** none

- **[security]** A licence record from the "Access Only" layer appears in tracked files in a public repo (`gh repo view` reports PUBLIC):
  - scripts/station_regulation_rule.R:92-94 gives a licence number, its purposes, flag, its two POD numbers, the rediversion flag and its quantities [redacted by the session before commit: the layer is Access Only].
  - The same licence number is in:
    - research/station_sources.md:195
    - the report data/checks/station_regulation_20261028.txt:7 (written by scripts/station_regulation.R:321)
    - tests/testthat/test-station_regulation_lib.R:69 and :82
    - tests/testthat/test-station_regulation_rule.R:109, which also has the POD numbers
  - Decision 5 says only computed values ship, "never a licence record (number, POD, quantity, location)".
  - The rule file cannot be edited without moving the registered commit. Re-registering it (a new commit with the record removed, `rule_commit` updated, and the report saying why) is the owner's call.
  - The other five places can be reworded freely, for example "a licence whose shared quantity covers one diversion POD and one rediversion POD".
  - The text is already in the branch's git history. If the branch has been pushed, it is public there too.
  - **Rule:** none

- **[bug, a gap in the rule: the owner's call]** scripts/station_regulation_lib.R:90-91 and :121-122 (from #53's `# NA: no volume`): a Current, located, surface, consumptive or storage licence with no volume is dropped without a trace, so a station can come out natural with licensed use upstream of unknown size.
  - The no-volume rows are units "Total Flow" (the licence takes the whole flow of its source), or a quantity that is NA or 0.
  - They get `m3yr` NA, so `v` NA, so `candidate` FALSE. They are never placed, never counted and never reported.
  - In the snapshot: 1,646 such surface rows. 880 are "Total Flow" (861 consumptive, 19 storage), and the rest have a missing or zero quantity.
  - I placed them with the script's polygon join and tested them upstream on codes only. The script's own-reach position test was not applied, so a few may be below their station.
  - 20 of the 92 natural stations have at least one such POD upstream, most of them "Total Flow":
    - 08HB0018, 08HB0034
    - 08LB0001, 08LB0002, 08LB0003
    - 08LE0001
    - 08MB0003
    - 08MH0014, 08MH0022, 08MH0027, 08MH0048, 08MH0049, 08MH0051, 08MH0054, 08MH0057
    - 08NK0001, 08NK0005, 08NK0006
    - 61002, 61006
  - The rule as registered allows this: it counts only "quantity > 0". But it means "natural" is reached while L cannot be formed, which is the "unsure" case the rule sends to unknown when there is no published flow.
  - Possible fixes are an amendment (for example, unknown when a no-volume consumptive or storage surface POD sits upstream and nothing regulates), or at least a column and a report line counting them.
  - **Rule:** code-check.md "A guard that fails toward pass"

## Checked and found sound (not findings)

- Own-reach handling: in all 16 snapped stations whose watershed codes differ from their segment's, the watershed's localcode lies downstream of the segment's. So the upstream test can only count more, which means false regulated, never false natural.
- Border lines: fwa_approx_borders holds only AB_120, USA_49 and YTNWT_60. Known cross-border rivers intersect them: Kootenay, Kettle, Columbia, Okanagan, Similkameen, Flathead, Moyie, Yahk, Liard and Petitot. The Rockies part of the Alberta border and the Alaska border are absent; no inflow to BC crosses either.
- 5 of the 70,382 points are not placed. One is a regulating dam, D1362 (Tucker Creek Dam, PARK group, 17.6 m off a coastal polygon). No station has codes under 905.361472, so nothing is lost now. The report prints the count, but an unplaced dam is otherwise dropped without a trace.
- The rerun from cache is byte-identical. All Postgres fetches used for sums are ordered in R before they are summed.
