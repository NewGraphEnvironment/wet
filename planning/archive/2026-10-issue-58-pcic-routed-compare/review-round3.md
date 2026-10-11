# Review round 3 (#58)

## Mechanism

Prose summaries are written from the headline number or the first list that came to mind, not from the
full table the code produced, so each one drops the condition or the members that the table itself shows.
R1 and R2 were instances: the Bulkley "smallest" basins, every far-low gauge put down to placement,
coverage given as "not the Liard", "ties" without "once seven are set aside". Round 3 enumerated every
count, list, comparison and attribution in the vignette prose and table strings, the research section 0
bullets, the report header, the CLAUDE.md lines and the #57/#58 bodies. Each was checked against the
report's per-gauge table (parsed), the bundle (`inst/vignette-data/segment_values.rds`) or read-only
queries on fwapg. Confirmed as stated: the fingerprint (recomputed live: 40524444 / 3377037 /
178035348.248310), every report-derived figure in research section 0, the 48 zero-coverage groups and
their FWA codes, SKGT 1 of 6,935, the SALR gauge errors and the 1.23 median, the "14–25 % low" for the
annual table at SALR's large gauges, the BULK two-creek claim, the 112 added gauges (94 coast, 18 rivers
of 2,593–55,439 km²), 246 groups, 69 % of 4.91 M segments, and the 1981–2010 / 10-year observed rule.
The four items below are still missing their condition, or are false.

## Findings

- **[fragile: count without its condition]** vignettes/segment-discharge.Rmd:218–220 (also the
  CLAUDE.md data-sources line "cover the … coast", and the Limits bullet at :733–735). The "Where it has
  values" row prints `prov$routed_groups` = **186** watershed groups. That count is the map rule (at least
  half of a group's segments routed), not where routed flow has values. Routed flow has values in **197**
  groups: 186 plus SKGT's single segment, plus 11 outer-coast groups at 11–49 % (PORI 11 %, KTSU 14 %,
  NBNK 19 %, MORI 23 %, KEEC 26 %, NECL 30 %, KUMR 38 %, MBNK 38 %, LRDO 39 %, NASC 45 %, VICT 46 %,
  WORC 49 %; query on `fwa_stream_networks_sp` LEFT JOIN the monthly table, month = 1). The report also
  scores gauge 08OB002 on Moresby Island (MORI), which is outside the 186. Read with the Limits bullet,
  which lists only the Liard, Yukon/Alsek, Hay and Skagit as no-or-almost-none, the row says routed flow
  is complete on the coast. It is not: on the outer islands and inlets it reaches a tenth to a half of
  the segments. Either say "(186 groups where it reaches at least half the segments)" or print 197, and
  name the partial outer coast in Limits.

- **[fragile: comparison without its condition]** research/water_balance_method.md:86–89 (headline
  "Routed PCIC is closer than the balance at the calibration gauges it covers"), the vignette guidance at
  :266–267 ("routed PCIC, which fits gauges more closely"), and #57's "routed PCIC is closer than the
  held-out balance at the 290 gauges it covers". This holds in aggregate, but the report's own basin rows
  reverse it on mean absolute error in two of the four basins:
  - Peace (28): routed 20.5 against the balance's 19.2. No far-low gauges are involved.
  - Fraser (90): 30.8 against 28.4. Routed leads only once the 7 Fraser far-low gauges are dropped (25.3
    against 28.5).

  Routed still wins on median error and on share closer in every basin. #39's section 0 carried the
  per-basin split, which is how the Peace tie was visible then; this revision drops it. #57's default
  pick ("routed PCIC where placed") rests on the headline, so the per-basin condition belongs beside it:
  routed's mean-error lead comes from the Coast and Columbia, and in the Peace and Fraser it is ahead only
  on median and share closer.

- **[false claim]** vignettes/segment-discharge.Rmd:227. The "Time" row says "PCIC serves climate
  projections the same way, not yet placed". CLAUDE.md says PCIC's routed projections (channel-scale
  VIC-GL-Raven CMIP6) cover only Coast + Fraser, on an FWA-derived network of their own, with the Peace
  and Upper Columbia about a year away (#9). #57's body lists as an open "Check first" whether hydromosaic
  serves projection runs on the same `subid` network. So "the same way" is unverified and wrong on
  coverage: routed projections do not yet exist for the Peace or Columbia. Suggested wording: "PCIC's
  routed CMIP6 projections cover the coast and Fraser so far, on their own network (#9)".

- **[false claim / stale pointer]** Issue #57 body ("11 gauges read almost no flow on their snapped
  segment (side channels, Nechako reservoir lakes). The default pick needs a rule for those.") and #58
  body ("It lists the gauges … (side channels, reservoir lakes)"; "The full table is in #57").
  - R1's fix to the far-low attribution reached the research note and the report but not the issue
    bodies. Of the 11, 08NE039 Big Sheep Creek is far low in the unrouted annual table too (97 against
    490 mm), so its shortfall is PCIC's runoff and not placement. A placement rule written from #57's
    wording would mistreat it.
  - Four others (08DB013, 08DB014, 08EE028, 08KH006) are unresolved.
  - Four read 14–17 % of observed, which is not "almost no flow": 08EE028, 08MH141, 08DB014, 08NE039.
  - #58's "The full table is in #57" is now false: #57's body was edited to a pointer at section 0 and
    no longer holds the table.
  - #58's ad hoc numbers (24.4 %, −0.1 %, 58 %) differ from the report's (24.1 %, +0.2 %, 59 %) with
    nothing saying why.

## Code

No defects found in scripts/pcic_routed_lib.R, scripts/pcic_routed_compare.R,
data-raw/segment_vignette_data.R, data-raw/segment_vignette_map.R or tests/testthat/test-vignette_data.R
beyond the accepted tradeoffs:
- The fingerprint recomputed live matches the report and the bundle.
- `routed_annual()`'s `HAVING count(q_m3s) = 12` is consistent with the table (40,524,444 = 12 × 3,377,037).
- The annual-table read is guarded by `!anyDuplicated`.
- The data script's report-match and fingerprint re-check guards fire on a mismatch.
