# Progress — Station source survey (#123)

## Session 2026-10-28

- Plan-mode exploration — phases approved by user (scope five + also-found; committed probe script; record every source and asset, accessed or not, so the bar can be revisited)
- Created branch `123-station-source-survey-which-networks-bey` off main
- Scaffolded PWF baseline from issue #123 with approved phases
- Next: start Phase 1
- Plan review (Plan agent) delivered; checked against the code and folded (1c41ae4); `review-plan.md`
- User, mid-run: BC Hydro releases data only by request. Filed wet#140
- Phase 1 done: no NGE package or org code fetches any candidate; research file skeleton with the bar written before any source is checked
- Phase 2 done: agents A and B wrote `sources-a.md` and `sources-b.md` (spot-checked); the probe respects robots.txt (Water Hub `/api/`, DataStream, Hakai ERDDAP queries not fetched)
- Phase 3 probe done: `scripts/station_sources_probe.R` → `data/checks/station_sources_20260717.txt`, identical across two runs; NaN hours dropped, `l/s` converted, the province's impossible values and the 2021–2026 Tool/province split reported
- Scrubbed private-repo pointers from the unpushed Phase 1 commit (amended to 3e14885)
- Phase 3–4 done: `research/station_sources.md` filled from the report (answer, inventory with verdicts, also-found, lower bars, robots.txt per host, publishers' defects); README index row and CLAUDE.md Data Sources line; filed wet#142 (provincial harvester, the one harvest verdict); #118's body states the result and lists #142. No issue for test-only sources: none is needed until a test reads them (named in wet#142). Every URL in the file answers 200 except BC Hydro's page (403 to curl, noted)
- Next: `/code-check branch`, `/planning-archive`, `/gh-pr-push`
- `/code-check branch` round 1 (`review-round1.md`): 7 findings, all real. Fixed: lower-bar counts split daily/proxy (250/238 daily, not 360/323); the Tool's 35 includes 6 at sites passing provincially (29 beyond); regulation counted per source; CSV count (389 + 2 HTTP 500); locale-free sorting (report identical under LC_COLLATE=C); near misses now a recorded 3 km sensitivity (4 of 147 drop: 08HA0024, 08LC0006, 08MG0002, 08NM0006); grades and years on impossible-value lines; the Tool's 17 provincial stations under "Regulator"; findings.md private repo names and a local path. wet#142 and #118 bodies updated
- Round 2 (`review-round2.md`): 4 findings, all real, 3 inside round 1's fixes. Fixed: the proxy lower bar counted 15 provincial no-complete-day stations as listed-period (95 Water Hub, not 110); wet#142's overlap wording for 08NM0006 (3 of 8 years); the Regulator listing's regions (08LG0019, 08NJ0001); private repo names quoted in the review files and task_plan (round 1's file amended before any push)
- Round 3 (`review-round3.md`), asked for the mechanism and an enumeration: prose numbers copied from a report line whose selector covers another population (broad flags, default branches, unstated parameters, quantifiers from labels). Its ~150-row table over the research file, README row, CLAUDE.md line, #142 and #118 found 17 wrong rows (10 findings), all fixed: 20 Water Hub datasets carry only a Discharge tag and now count as no discharge (76 with a parameter; 29 pass on the proxy, not 39); UNBC's two Kiskatinaw series; leads named in the summaries; 0.5 km site grouping stated; BC Hydro and BC ENV qualifiers; "every year" 1998–2020 has no 2004–2005; #142's network list and its two-files claim (0 station-hours in two files, re-measured). New Water Hub numbers re-derived mechanically from the report's per-network rows. Loop ended on that enumeration. Report identical under LC_COLLATE=C
- Archived (`/planning-archive`); next `/gh-pr-push`
