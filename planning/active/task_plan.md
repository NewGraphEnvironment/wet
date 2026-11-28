# Task: Backlog move 12: Research files around the current state (#189)

**If we do it:** research notes that grew one section per issue read as what is true now, each number checked against its
report, and the revise-in-place rule #181 tests is refined over the files. **If we never do:** readers replay
issue-ordered histories to learn what ships today, and `research/station_flow_departure.md` keeps statements last checked
on 2026-09-28.

Batch 14 of `planning/backlog.md`: #181, #183, #184 (the umbrella body's table) and #206 (the backlog's batch 14 adds it;
the body's table lacks it).

## Decided at the gate

No gate in the planning pane: parked for the coordinator's plan gate. Mechanism, decided while planning:

- **One commit per file** (the two departure files share one). The diff touches no code. Whether
  `water_balance_method.md` stays in this pull request is the open decision below. If a file cannot be finished, it is
  filed as its own issue naming move 12 and left out of `planning/backlog.md` (that file's header rule).
- **No file is split, and the cited anchors stay.** In `research/water_balance_method.md` the headings `## 0.` and `## 7.`
  with their numbered items, and the subsection name "Accepting the next refit", stay. `scripts/wb_cv_lib.R`,
  `scripts/wb_gate_rule.R` and `scripts/wb_aet_compare.R` are hashed by `scripts/wb_score_md5.R` and cite section 0 or
  "section 7 item 3" (the latter also printed into a report); `scripts/wb_fit_accept.R`'s header cites "Accepting the next
  refit". **No file under `R/`, `scripts/`, `inst/`, `data/` or `data-raw/` is edited.**
- **soul's `research_check.sh` is a measure, not a target.** The aim is no `sections` flag and no `age` flag on a file whose
  claims were re-read. The `words` line (3,000) may stay flagged: sections 1–7 of `water_balance_method.md` alone were
  3,578 prose words on 2026-11-27 (a count of every non-table word). Known facts are not dropped to clear it. What the
  five files say about that threshold goes in the archive README (#181 asks for the record that refines the rule).
- **No rerun and no PCIC request.** Claims are checked against tracked reports, committed logs, tracked bundles, code as
  it stands, and read-only reads that write no repo file (a HYDAT or fwapg query, an anonymous GET of wet's own bucket or
  water-temp-bc's). A claim only a rerun can check says it was not re-run and keeps its old date (#206's rule, applied to
  all five). **Do not run** `scripts/mad_parity.R` or `scripts/mad_basin.R` (they call PCIC fetch functions, which request
  on a cache miss, and PCIC's robots.txt disallows the data path), nor `scripts/discharge_publish.R`, any
  `scripts/departure_*` or `scripts/station_departure.R`, or any `data-raw/` script (they write reports, bundles or
  published output).
- **Dates stay per section.** A section whose claims were not all re-read (the paper in sections 1-7, database timings,
  the parity tables) carries its own older **Verified:** line, and the file's header says what the new date covers.
  `research_check.sh` reads only the first date on the first `**Verified:**` line.
- **At most two headings per file may name an issue** (three or more is the `sections` flag). In
  `water_balance_method.md` those are `## 0. As built in wet (#11)...` and "Reproducing #15 and #18"
  (`station_snap.md` cites it); "Accepting the next refit" and every other heading drop their numbers.
- **Where moved narrative goes.** To the `README.md` of the archive of the issue it came from (an issue carried by a move's
  PR goes to that PR's archive; where an issue has two directories, as #7 and #27 do, the one whose README covers the
  moved text, named in `findings.md`). Text goes under `## From research/<file>.md (moved by #189)`, verbatim, and only
  what the archive does not already say. Relative links inside a moved block may be re-pathed; old section names quoted in
  archive history or in moved blocks are not rewritten. Only archive `README.md` files are edited; dated review files, plans and findings stay as written.
- **One home per fact between the departure files (#184).** `station_flow_departure.md` holds the method (sources, what a
  departure rests on, windows and periods, the extension and carry rules and their held-out scores, the snow
  specification, and the pilot's held-out scores and record-size facts, which `station_sources.md` relies on).
  `chinook_sites.md` holds per-site results. Each points at the other. **#120's inverse-distance Maxan results are not
  superseded**: `vignettes/short-record-flow.Rmd` still publishes them and links `station_flow_departure.md`. They stay
  in one labelled place in `chinook_sites.md`, beside the shipped `covariance_pick` ones, and
  `station_flow_departure.md` points there where the article's reader lands.
- **How a file is checked.** Two tables in `findings.md`, and the script only helps them. (1) A claim-by-source row for
  **every number the new file keeps, unchanged ones included**: the claim, the report line (or query), the build or
  commit that source names, agrees or disagrees. A stale number carried over unchanged is what this catches. (2) A
  ledger of every paragraph and bullet of the old file, numbers or not: kept, moved to X, already in X (quote the line),
  or dropped with the reason. A verdict, limit or attribution is lost without any number leaving.

## Open decisions

- **Does `research/water_balance_method.md` stay in this pull request?** Its section 0 is about 12,500 words, and the Plan
  review found present-tense numbers in it that already disagree with the current report (the 32.5 % nested selection,
  now 30.7 % in `data/checks/wb_aet_compare_20260717.txt`), so it needs re-verifying and not only reordering. The move's
  model is Sonnet.
  (a) Recommended: land the other four files here, file `water_balance_method.md` as its own issue naming move 12 (left
  out of `planning/backlog.md`), for its own pull request with a stronger builder. #181 and so #189 then stay open:
  Phase 4 is skipped and its boxes are marked as carried by the new issue, and the PR body closes #183, #184 and #206
  only, with #181 and #189 closed or re-scoped as the owner says at the merge.
  (b) Keep all five in one pull request. Phase 4 runs after the departure files among the files, so it can still be split off if it fails.
  Ask before Phase 4.

## Phase 1: the ledger and the baseline
- [ ] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 189 189-backlog-move-12-research-files-around-th --batch 14` (T from `soul_published_tree`). On a non-zero exit or any line but `FREE`, build nothing: write the line under `## Open decisions` and stop. #206 is not in the body's table, so check by hand that it is open and that no open pull request or branch is on it
- [x] Write `planning/active/numbers_check.py`: for one research file, old (`git show origin/main:`) against new, list (a) number tokens that left, compared as multisets, that appear in none of the diff's **added** lines (archive READMEs and the other research files, never a file's old text), and (b) number tokens that are new. Normalise the Unicode minus, thousands separators and percent signs. Restore a known drop (one of two occurrences) and a known invented number in a copy and see both listed. It finds candidates only: it cannot see a stale number carried over unchanged (the clamped-days figure in `discharge_publish.md` is one), so the claim-by-source table is the check, and a token's presence in a report proves nothing
- [x] Record in `findings.md` the baseline per file: prose words and issue-headed sections from `research_check.sh`, the cited reports, and each report's last commit date set beside the file's Verified date
- [x] Add the #206 row to #189's body table

## Phase 2: `research/discharge_publish.md` (#183)
- [x] Before building: the member re-check of Phase 1
- [x] Rewrite in the order: provenance line (short: the last-true date, issues, producer), what is published now (build, parts, sizes), naming and layout, the receipt and fit, how it is checked (the value checks and the routed days folded into one statement each), Postgres load, access, evidence. The build-by-build history in the **Status:** paragraph and the reload timings by date move to their archive READMEs; keep a timing only where a reader still needs it
- [x] Known to disagree on 2026-11-27: the routed-days figures are the build before #163's. `data/checks/segment_daily_output_20260717.txt` lines 21-27 give 1,908,991 segment-months (4.711 %) more than 1e-5 apart, 1,036,583 in February; 14,577,433 days clamped (1.183 %); mid-network 53,610 of 99,306,645 (0.054 %); worst day 16 May, 944. The fwapg clamp shares beside them need a read-only query on the 5d50cc1 tables, or a date and build label. Recheck the "outside February only by rounding" sentence too. The per-dataset sizes summing to 33.23 GB are build b4bbc50's, not the current 33.36 GB build's
- [x] Check each kept number against `data/checks/discharge_publish_20260717.txt`, `data/checks/segment_daily_output_20260717.txt`, the live manifest (anonymous GET) and the code (`scripts/discharge_publish.R`, `R/wet_db_load.R`, `R/wet_catalog.R`). The value-check table must match the tracked report row by row. A database timing that cannot be re-read keeps its measurement date
- [x] Keep what other files cite: the identifier rule and the v2 `pick` decision (`NEWS.md`), the layout and keys (`scripts/discharge_publish.R`, `scripts/discharge_publish_lib.R`), the daily layout and checks (`water_balance_method.md`), the `fit` entry (`segment_group.md`)
- [x] Run `numbers_check.py`, account for every listed token, commit with the archive README additions

## Phase 3: `research/station_flow_departure.md` (#184) and `research/chinook_sites.md` (#181), one commit
They trade facts, so they are rewritten together and `numbers_check.py` runs on the two as one set. Write the table of
which facts live where first.
- [ ] Before building: the member re-check of Phase 1
- [ ] `station_flow_departure.md` in the order #184 gives: sources and where they meet, what a departure rests on, known residuals, method choices, current windows and periods (2016–2025 against 1981–2010), the ungauged-site method as it ships now (#120 and #121, with #122's `covariance_pick` pointed at `pcic_hydrology.md`), what is open. The 2022–2026 and first-pass window results move to the #27 archive
- [ ] Re-read every statement against the code (`R/wet_station_daily.R`, `R/wet_window_stats.R`, `R/wet_window_extend.R`, `R/wet_departure_carry.R`, `scripts/station_departure.R`, the two site scripts, read only) and the tracked reports (`data/checks/departure_*`, `station_departure_report.txt`). "Sources and where they meet" names three sources, while `wet_station_daily()` also reads the provincial, BC Water Tool and Hakai records: state what is true and point at `station_sources.md`. The upstream ask to unify the archive's `historic/` files, which the old-HYDAT hole sentence waits on, was closed on 2026-09-30: test with a public S3 read whether the hole is filled, or date the claim
- [ ] Refresh the state of every upstream item the file cites (`gh api`, read only): several read closed on 2026-11-27 and one is open
- [ ] Known to disagree: the ice share says 7,885 of 18,193 days for 08EE013; HYDAT 20260717 gives 8,101 `B` of 18,620 days (43.5 %), a read-only query on 2026-11-27. "Every year 2023–2026" is wider than `station_departure_report.txt`, which has no September 2026 row (check each station and window, August 2025 at 08EE003 included)
- [ ] Not seen in the `departure_*` reports the review read: the ice counts, the August monthly means and the 0.212 rank, the provisional winter flows, and the 2016–2025 window changes, whose inputs are `inst/vignette-data/station_daily.rds` and `vignettes/flow-departure-normal.Rmd`. Recompute read-only or date them
- [ ] The 2023–2026 result block comes from `station_departure_report.txt` (run 2026-09-28): keep it only as that report's, dated, or move it with the other superseded windows. Say which in `findings.md`
- [ ] Verify the Maxan and snow numbers against `departure_pilot_20260717.txt` and `departure_snow_20260717.txt`, which the Maxan site reports reproduce
- [ ] `chinook_sites.md` around the current state: which streams and why; the method as shipped per site (distance or `covariance_pick`); one current table of change, 1951–1980 to 2016–2025, on the shipped borrowed route, with the extended route, Swift's row included, and each site's own windows; snow; held-out skill; Gosnell's normal; natural stations outside HYDAT as donors (the registered rule and its result); Maxan's inverse-distance results, labelled. The 2011–2025 against pre-1981 table and the superseded distance-route rows at Naver and Gosnell move to the #126, #152 and #167 archives, with one "until #147, X" line only where a reader needs it
- [ ] **Re-derive every comparative sentence** from the new table and each site report's section 6; do not carry the old prose across. Under `covariance_pick` these old statements are false: the spawning drop largest at Maxan and Naver (Maxan -66, Naver -35, Gosnell -29); the carried range clearing no change at Naver (-58..+2); no clear migration change at any site (Maxan -30, -49..-4); the spawning seven-day minimum clear only at Maxan (Gosnell -37, -56..-15); nothing clear on Gosnell's Morice rows (migration min7 -47, -66..-19). The carried snow-regression R² and the "below 0.5 in every box" held-out lines are distance results too (snow report section 6 has the others). Check against `vignettes/articles/flow-change-sparse-gauges.Rmd`. "The drop holds at Swift" (distance ships) and the extended-route and OLS/ratio results are unaffected
- [ ] Known to disagree: the held-out "from X to Y" pairs mix pools (Maxan spawning 0.49 and Gosnell 0.45 are section 3's all-donor pool; section 6's covered pool is 0.50 to 0.66 and 0.49 to 0.71). "20–30 years on every other route" fails for Naver's spawning `cov_day` under `covariance_pick` (18)
- [ ] Check every kept number against `data/checks/departure_site[_snow]_*`, `chinook_sites_use.txt`, `departure_interval_coverage.txt`, `departure_donors_20260717_20261028.txt`. For window claims: `data-raw/life_history_data.R`, `inst/vignette-data/life_history_*.csv` and `tests/testthat/test-life_history_pin.R` (`data-raw/chinook_sites_data.R` holds the checks the article's numbers pass, not the numbers)
- [ ] Keep the heading "Natural stations outside HYDAT as donors" (`station_sources.md` cites it). Check that the short-record article's link still leads to its numbers
- [ ] Run `numbers_check.py` on both, complete the two tables, commit with the archive README additions

## Phase 4: `research/water_balance_method.md` (#181, second file; see Open decisions)
- [ ] Before building: the member re-check of Phase 1
- [ ] Section 0 around what ships, in this order: the provenance line (short); inputs; stations; method choices; the AET and how it is chosen (the incumbent rule, decision files); the gate; pooled zones; monthly shares (snow predictors, donor); the daily shape; skill of the shipped fit (HYDAT 2026-07-17); accepting the next refit; routed PCIC against the balance and the segment pick; the dry-interior diagnosis (#45, #50, #53 as one verdict with what remains open); reproducing #15 and #18; what it says about the BC Water Tools; follow-ups
- [ ] Known to disagree: the nested selection reads 32.5 % against 30.7 % shipped for stage 1, stage 2, "`cfu` alone" and the rescore on the shipped fit, and the BC Water Tools verdict builds on it. `data/checks/wb_aet_compare_20260717.txt` lines 29, 40, 47 and 48 give 30.7 for all, since #47's gate. Quote the current report; keep 32.5 only where dated as before #47 (a registered rule's disclosure). "`cfu` is the only variant kept by the override" is retired too. "The selected number is optimistic by about a point" and "32.3 % is the honest estimate" are the 2025-10-14 fit's: do not carry them as current
- [ ] Give every bullet under the #11 heading its own destination before moving anything. Current facts there: "Zone steps" (section 7 item 9, #199, `wb_runoff_annual.png`), "No output" (22,041 watersheds, `wb_output_20260717.txt`), the definition of pooled zones, Chapman's published figures. "Large rivers are good" is 2025-fit text: rewrite from the shipped report or move it
- [ ] **Keep PCIC's gridded run through fwapg in section 0** (the older-annual-table comparison at the 178 gauges). `scripts/pcic_coverage.R`, `data/checks/pcic_coverage_20260717.txt` and `pcic_scenarios.md` say section 0 is its only record: it is not a superseded comparison
- [ ] The routed-PCIC and per-segment-pick statements sit today under "Skill with CGIAR AET, as built in #11", a superseded heading: give them their own subsection before the #11 table and its commentary move to the #11 archive README
- [ ] Superseded results move to their archives: the #11 skill table, the 2025-10-14 fit's figures, the fold counts from before #89, the 1951–2012 and fwapg 7c30f58 comparisons, the retired override. A registered rule's text, a verdict and a disclosed limit stay
- [ ] Check every kept number against its tracked report (`data/checks/wb_*.txt`, `stations_wb.txt`, `climr_eccc.txt`, `pcic_routed_compare_20260717.txt`, `segment_output_20260717.txt`). Read the shipped fit's reports, not the unsuffixed 2025-10-14 ones, for any present-tense claim. A number with no tracked report (the #58 Prince George gauges, the #89 sandbox, side-channel sample counts, reprojection errors) names the commit or archive that made it, or moves there
- [ ] Re-read each follow-up against its issue's state (on 2026-11-27: #14, #76 and #199 open, #85 and #176 closed; #76 reads done in code while open, so say that and do not call it closed) and `monthly_error.md`'s current small-basin verdict
- [ ] Sections 1–7 (the paper read against the build) keep their numbering. Revise only statements about what wet does that are no longer true, and say in the header what was and was not re-read: the paper itself is re-read only where a claim is in doubt
- [ ] For each citation of this file by a script, report or article, confirm the cited **claim** is still under that anchor: `scripts/wb_cv_lib.R`, `wb_fit_accept.R`, `wb_gate_rule.R`, `wb_aet_compare.R` (section 7 item 3), `departure_pcic.R` (PCIC's calibration gauges unpublished), `pcic_coverage.R`, `discharge_publish_lib.R`, the interior-plateau comment in `vignettes/segment-discharge.Rmd`
- [ ] Run `numbers_check.py`, complete the two tables, commit

## Phase 5: `research/fwapg_mad_method.md` (#206)
- [ ] Before building: the member re-check of Phase 1
- [ ] Read fwapg's current `extras/discharge/` (`discharge.sh`, `sql/*.sql`) from `main` of both `smnorris/fwapg` and the NewGraphEnvironment fork (read only), naming the commits read, and re-read each method claim against them. `pcic_hydrology.md` records that `discharge.sh` still requests PCIC's old host without `-L`, so as written it saves the redirect page: state it or point there
- [ ] Re-read each wet claim against `scripts/mad_parity.R`, `scripts/mad_basin.R`, `scripts/upstream_area_check.R` (read only) and the functions they call, listing what changed since 2026-09-26 (#76's fetch order and summation, #169's PCIC fetch)
- [ ] Sources: the upstream-area numbers are in `data/checks/upstream_area_100_full.txt` and `_sample.txt`, cited correctly today. The Fraser tables (99.782 %, 2,189 differences and their causes, groups at 100 %, the flips, the basin sensitivity, Hope) are in the tracked `data/basin/100_report.txt` with `100_run.log`. The SALR parity and sampling tables are in `planning/archive/2026-09-issue-1-scope-discharge/` (`findings.md`, `README.md`). The review did not find "60 files, 24 min" or 1,457 irregular polygons in the Fraser report: trace them. All of it is a record of a run from before #76 and #169: say it was not re-run and give its date
- [ ] Run `numbers_check.py`, complete the two tables, commit

## Phase 6: links, index and record
- [ ] Before building: the member re-check of Phase 1
- [ ] For every heading removed or renamed in the five files, grep all tracked files for the old name and for `research/<file>.md`; fix `CLAUDE.md` (above the soul marker only), the other `research/` files, articles and archive `README.md` files. A script that cites a section keeps resolving without an edit
- [ ] Re-run the cross-pointer and anchor check across all five after every file is done (`discharge_publish.md` and `water_balance_method.md` point at each other's daily-layout text)
- [ ] Revise the five rows of `research/README.md` to what each file now holds
- [ ] Run `research_check.sh` over the five and `--added origin/main`; record words before and after, sections merged, numbers checked, each number that disagreed with its report (with whose error it was), and what the pass says about the rule and its thresholds, in `findings.md` for the archive README
- [ ] `git diff --name-only origin/main` lists only `research/`, `planning/`, `CLAUDE.md` and any article link fix

## Validation

- [ ] Tests pass (`devtools::test()`; no code changes, so this shows nothing read a moved file)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`), briefed to look for facts dropped without an archive home, numbers that disagree with their report, and broken anchors
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

**Verification.** Per file: `numbers_check.py` with every candidate accounted for; a claim-by-source table in
`findings.md` and the paragraph ledger; for each anchor a script, report or article cites, the cited claim read under it
(a grep that the heading exists, and passing tests, would both pass on an emptied section). The PR body's `Closes` lines
follow what landed: #183, #184 and #206 for their files; #181 only when both of its files landed, and #189 only when every
member did.
