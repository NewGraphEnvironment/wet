# Task: Backlog move 18: Natural non-HYDAT stations as donors (#211)

**If we do it:** departures at an ungauged or short-record site can borrow from the natural stations outside HYDAT, the province's non-integrated network and the BC Water Tool's gauges, where HYDAT's natural gauges are few or far. **If we never do:** those stations stay records and held-out tests, and every donor box draws on HYDAT alone.

One batch (20), one member (#202), one phase in three steps, one PR. A design-first move: every departure route was registered before it ran.

## What exploration found (2026-11-25), which shapes every step

Measured with `wet_station_list()`, `wet_station_daily()` and `wet_window_stats()` on the pinned snapshots (20261028) and HYDAT 20260717; details and the proxy's definition in `findings.md`.

- **No natural non-HYDAT station has a baseline.** Of the 75 natural stations (52 provincial, 23 Water Tool), 71 have no complete migration window-year in 1981–2010 and none has 10; the most any has in all years is 9. `wet_departure_carry()` takes each donor's departure from its own 1981–2010 mean over at least 10 years, and the site script's extension pool needs 30 years. So under the rules as registered these stations supply no donor anywhere in the province, whatever selector they enter through. The gate question "where they enter" is not what binds; the baseline is.
- **What they do hold:** 185 complete migration window-years, 179 of them in 2010 or later; 36 stations with at least 3, 8 with at least 5. Through 2024, the last year HYDAT's approved record is broadly complete, 33 have at least 3 and 5 have at least 5. 43 of the 75 have no complete calendar year, so `wet_station_select()`'s 12-month rule would drop most.
- **At the four chinook boxes:** Maxan and Gosnell hold 2 natural stations with 2 window-years each, Swift none, Naver 6 (four with 3 window-years). Whatever this move decides moves nothing at Maxan, Swift or Gosnell.
- **A held-out test is possible province-wide.** By a proxy (May–July days in HYDAT), 274 natural HYDAT gauges have a 1981–2010 baseline and at least 3 years since 2011; 44 of them have a natural non-HYDAT station with at least 3 window-years among their 5 nearest, 39 with at least 3 shared years.
- **Day status:** of the 185 window-years, 116 are provisional throughout, 58 unchecked throughout, 11 mixed.
- **Same-site continuation is small.** 16 natural stations sit at a HYDAT site; at 2 of them a natural HYDAT gauge with a baseline gains years it lacks (08JC017 from 08JC0002, 08NJ168 from 08NH0001).

So the only way these stations can be donors now is with an **estimated baseline**: each is extended into 1981–2010 from HYDAT gauges the way #120 extends a short-record target, and its observed years then depart from that estimated mean. Whether that helps or hurts is a held-out question, and this PR asks it under a rule registered first.

**What the Plan review added to that picture:** an OLS fit's residuals sum to zero over the years it is fitted on, so a station's average level over its own years is its extension gauge's, scaled by a slope fitted on 3 to 9 points. Only the year-to-year part around that line is the station's own: one degree of freedom at 3 years, two at 4. Most of the 33 stations are at 3 or 4, so no gain is the likely result today, and the test's worth is a measured answer and a script that can be rerun as records lengthen.

## Decided at the gate

No plan gate ran in this pane (parked for the coordinator's plan gate). These are mechanism, decided in the plan on 2026-11-25, each with its reason; the scope and the bar the owner answered at the coordinator's gate, below.

- **A registered rule comes before any shipped number.** Every departure route (#120, #122, #126, #147, #152) was registered before it ran; this one is too, in a commit of its own before the scoring script exists, as #196 registered its rule.
- **Where they enter: nowhere in shipped code in this PR.** The test builds its combined pool in a new script from `wet_station_list()`'s `regulation`. `wet_window_extend()` and `wet_departure_carry()` take `stations` and `x` as plain data frames and need no change, given the fit years the rule now defines (the review's blocker); `wet_station_select()` and the site script's box query stay HYDAT-only. If the rule ships, the entry point (a selector beside `wet_station_select()`, the shipped drainage areas it needs, a site-script section) is a follow-up issue naming move 18, with its stored-data choices at that gate. Reason: at the four sites nothing would move, and a selector nobody calls is speculative until the test says the route works.
- **A usable year is a complete window-year**, `wet_window_stats()` at `min_frac = 0.8`, the definition #120 uses for HYDAT; a station needs at least 3. Not `wet_station_select()`'s 12-month year, which a seasonal gauge never meets.
- **Provisional and unchecked days enter alike in the primary test**, as `wet_station_daily()` returns them (the plausibility bound is applied on read), with a registered sensitivity that drops every window-year holding an unchecked day. Reason: a third of the window-years are unchecked throughout, and the held-out score is the test of whether they are good enough.
- **The population is `regulation == "natural"` as registered in #196**, including the stations at a site whose HYDAT gauge HYDAT flags regulated (4) or that duplicate a HYDAT gauge's river (12); a registered sensitivity leaves both kinds out, and the report lists them. Reason: #196's rule is the owner's, and its comparison with HYDAT's flag decides nothing there either.
- **Scored province-wide, not per site**, in a box of #126's size centred on each held-out HYDAT gauge, so each gauge is scored as a site run there would treat it. A per-site section cannot be scored: no box holds enough of these stations.
- **A station's drainage area is fwapg's upstream area at the segment the regulation run placed it on**, for every station, one source. Reason: the stated areas live only in that run's memory and the Water Tool's pinned files; where one exists the placement already holds the two within 10 %, far inside what a log-area predictor can tell apart.
- **Inverse distance only.** `covariance_pick` is not tested with these stations: it needs each one's modelled years on a PCIC-covered segment, a second question.
- **Same-site continuation is not built here.** Joining a provincial station's days to the HYDAT gauge at its site changes what `wet_station_daily()` returns (stored data, and `wet_station_list()` documents that the two are never joined) for 2 gauges. Step 3 files it as its own issue naming move 18.
- **The PR closes #202 and #211 on either verdict** (`Fixes #202`, `Fixes #211`). #202's four questions are answered in the research section; on a pass what remains is a build, which the follow-up issue carries.
- **The verdict's home is `research/chinook_sites.md`** (the file #211 names), in a section of its own, with the sentences in `research/station_sources.md` that it supersedes revised.
- **#211's Touches list shrinks.** `R/wet_window_extend.R`, `scripts/departure_site.R`, `scripts/departure_site_lib.R` and `tests/testthat/test-wet_station_select.R` are read, not edited; `R/wet_station_select.R` and `R/wet_station_list.R` change in their help text only.
- **No comment on #211 or #202 asks for anything** (the one comment on #211 is the claim notice).
- **Scope (the owner, 2026-11-25, at the coordinator's plan gate; recorded in #211's body): test the stations as donors** with an estimated baseline, held out province-wide under the rule registered before any score (option a).
- **The bar (the owner, same gate): the verdict as drafted** (median paired difference at most −0.01 under leave-one-gauge-out and leak-free, at least 10 gauges scored under each), with the three extra lines (every 2011–2025 year, a bootstrap interval on the median, the distinct stations behind the scored gauges) reported beside it, deciding nothing.

## Phase 1 (batch 20): the rule, the test and the verdict

- [x] Before building: `bash "$T/skills/_shared/members_check.sh" "$(git remote get-url origin)" 211 211-backlog-move-18-natural-non-hydat-statio --batch 20` (T from `soul_published_tree`). On a non-zero exit, or any line but `FREE`, build nothing of this batch: write the line under **Open decisions** and stop.
- [x] Ask the owner Open decisions 1 and 2 and record the answers under "Decided at the gate"; on (b) or (c), or another bar, revise the steps below before any commit and say so in `progress.md`.
- [x] Re-read #211 and #202 (bodies and comments) and diff against `findings.md`'s copy.

### Step 1: register the rule, before any score exists

The review moved the per-gauge computation into the rule file and added an end-to-end test, so the rule meets both real functions before it is registered; and it added the fit years, the tables, the reasons a station is not eligible and the amendment protocol to the rule's text.

- [x] Tests first, failing: `tests/testthat/test-departure_donors_rule.R`, sourcing `scripts/departure_donors_rule.R` as `tests/testthat/test-departure_site_rule.R` sources its library (skipped where `scripts/` is not installed). Cases:
  - `dd_box()`: the centre rounded to 2 decimals, ±1.9° and ±1.1°; 08KA012's coordinates (−119.2667, 52.83833) give Swift's row of `scripts/departure_sites.csv` (−121.17, −117.37, 51.74, 53.94).
  - `dd_candidate()`: natural only; at least `dd_min_years` (3) migration-mean window-years; a positive finite area; inside the box; `hydat_site` not the held-out gauge; `NA` in any of them is not a candidate.
  - `dd_fit_years()`: a station's usable values (not `NA`; above 0 unless the statistic is `*_cov_day`) in years no later than `dd_fit_last` (2024); a 2025 or 2026 year is never a fit year.
  - `dd_baseline_rows()`: from one station's observed rows and its `wet_window_extend()` result, keeps every observed row (2025 and 2026 included) and the extended rows inside the baseline only; an extended row outside the baseline is dropped, and the test fails if that filter is removed; fewer than `dd_min_baseline` (10) baseline values returns no rows; no station-year appears twice.
  - `dd_scored_years()`: the years in `dd_test_years` (2011–2025) where the gauge has an observed window-year, both carries return a departure, and the carry with the stations names at least one of them in `donors`; zero-length inputs return `integer(0)`.
  - `dd_rmse()`: root mean square of observed minus carried; fewer than `dd_min_scored_years` (3) years is `NA`.
  - `dd_ship()`: ships only when the median paired difference is at most `-dd_margin` (0.01, `1e-9` allowed) in both pools and each pool scores at least `dd_min_gauges` (10); checks in `site_carry_ship()`'s order (counts, an `NA` median, leave-one-out, leak-free) and returns the first that failed.
  - `dd_gauge()` end to end, through the real `wet_window_extend()` and `wet_departure_carry()`: three long gauges ending 2024 and one station with years 2016–2026 return both carries, with the station's 2025 value carried as observed; a box with no candidate returns identical carries; a station at the held-out gauge's own site is left out; a held-out gauge whose HYDAT donors are all removed is returned as not scored, with its reason, without an error; a station no gauge covers is not eligible, with its reason; any other error from either function propagates.
- [x] `scripts/departure_donors_rule.R`: the rule below as its header, then the constants and the functions the tests name. No database, no download.
- [x] `research/chinook_sites.md`: a section "Natural stations outside HYDAT as donors" stating the rule as registered and the counts as seen on 2026-11-25, dated and marked as seen before any score. Add #211 and #202 to the header's issues.
- [x] Commit the rule file, its tests and the research section alone, before `scripts/departure_donors.R` exists. Note the sha in `progress.md`.

#### The rule to register (the header of `scripts/departure_donors_rule.R`)

**Question.** Does adding the natural stations outside HYDAT, each on an estimated 1981–2010 baseline, bring a carried departure closer to the observed one in the years those stations have records?

**Population.** HYDAT 20260717: natural BC gauges (`REGULATED = 0`) with coordinates and a gross drainage area, approved days only (`wet_station_daily(sources = "hydat")`). Outside HYDAT: every `wet_station_list()` row of snapshot 20261028 whose `regulation` is `"natural"`, its days from `wet_station_daily(sources = c("bcenv", "bcwatertool"), to = NULL)`, provisional and unchecked alike. A station's drainage area and watershed codes come from the segment the regulation run placed it on (`regulation_20261028.csv`'s `linear_feature_id`), through `fwa_streams_watersheds_lut` to `fwa_watersheds_poly` (`wscode_ltree`, `localcode_ltree`) and `fwa_watersheds_upstream_area` (`upstream_area_ha / 100`), the joins of `rg_sql_snap` in `scripts/station_regulation_lib.R`. A station with no upstream area is not a candidate.

**Windows and statistics.** The Bulkley chinook migration and spawning windows (`inst/vignette-data/life_history_bulk.csv`); mean, min7 and cov_day scored, max reported; a complete window-year at `min_frac = 0.8`; baseline 1981–2010; the log-ratio scale (days for cov_day). All #120's.

**Held-out gauges.** Per statistic and window, every natural BC HYDAT gauge with at least 10 baseline window-years of that statistic (its departure pool, province-wide), held out one at a time.

**Per held-out gauge g:**

- **The box** is 3.8° by 2.2° centred on g's HYDAT longitude and latitude rounded to 2 decimals, bounds inclusive, as #126 centres a site's box. Its HYDAT box pool (at least 3 migration-mean window-years), extension pool (at least 30 and a 5-year run) and departure pools (at least 10 baseline window-years, per statistic and window) are computed as `scripts/departure_site.R` computes them.
- **Candidates:** the stations outside HYDAT that are natural, lie in the box, have an upstream area, have at least 3 migration-mean window-years, and are not at g's own site (`hydat_site` is not g).
- **One station table per g:** the box pool plus every candidate. It is the `stations` of every extension and of the carry with the stations, for every statistic and both pools, so the predictor SDs do not depend on which extensions succeed.
- **Without** (#120's carry): `wet_departure_carry()`, inverse distance, k = 5, baseline 1981–2010; `x` the departure pool's rows less g's; `stations` the box pool. A gauge with no HYDAT donor left is not scored, and is counted.
- **Eligible, per statistic and window,** a candidate whose every test below passes, each checked before the call and counted under its own reason when it fails:
  - its fit years, the usable values (not `NA`; above 0 unless cov_day) in years through 2024, number at least 3. 2024 is the last year HYDAT 20260717's approved record is broadly complete (272 natural BC gauges hold May–July 2024, 120 hold 2025, none 2026);
  - at least one gauge of the extension pool less g holds a value in every fit year;
  - `wet_window_extend(method = "ols", k = 5)`, with `x` the station's fit-year rows and the extension pool's rows less g's, returns a value in at least 10 baseline years. A donor whose values do not vary over the fit years is a reason of its own. Any other error stops the run.
- **With:** the same carry, `x` joined by each eligible station's rows: all its usable observed window-years, 2025 and 2026 included, plus its extended values in the baseline years it did not observe. Outside the baseline only observed values enter. `stations` the table above.
- **Scored years:** the 2011–2025 years in which g has an observed window-year, both carries return a departure, and the carry with the stations names at least one of them among its donors. Both carries are scored on the same years. A gauge with fewer than 3 is not scored.
- **Score:** the RMSE, over the scored years, of g's observed departure (from its own 1981–2010 mean) minus the carried one, for each carry. The paired difference is with minus without.
- **Leak-free pool:** every gauge or station upstream or downstream of g (`wet:::wet_fwa_upstream()` on the watershed codes: `wet_station_snap()`'s for a HYDAT gauge, the lookup above for a station) is dropped from g's donors and from the extension donors, in both carries; the station tables keep their rows. A HYDAT gauge whose snap is not accepted keeps every donor, as the site script's section 3 does.

**Verdict,** on the migration-window mean: the estimated-baseline route ships if the median over scored gauges of the paired difference is at most −0.01 under leave-one-gauge-out and in the leak-free pool, with at least 10 gauges scored under each. Otherwise the donor pool stays HYDAT-only. One verdict, holding for every statistic and window.

**Reported, deciding nothing:**

- n, quartiles and median of each carry's RMSE and of the paired difference, per statistic and window, both pools; how many gauges are better and how many worse; an interval on the median from 2,000 resamples of the gauges under `set.seed(211)`.
- The paired difference over every 2011–2025 year both carries return, at the gauges with a station among their 5 nearest, split into the years a station is among the donors and the years none is.
- Each carry's mean signed error; section 3's centred log NSE on the scored years.
- The distinct stations behind the scored gauges, and the median paired difference by station (each gauge under the station it weighted most).
- Each eligible station's fit years, slope and extension chain; the stations not eligible, by reason; the stations at a HYDAT site, with HYDAT's flag there.
- The gauge-years in which the HYDAT donors of the carry with the stations are not among the carry without's (the SDs differ between the two tables, so the fifth and sixth nearest can swap).
- Sensitivities, each a rerun of the whole test: stations with at least 5 fit years of the statistic only; window-years with no unchecked day only (a station's window-year is dropped when any of its days with a value inside the window is `"unchecked"`, read from the daily rows); the carry's k at 3 and at 8, the extension's staying 5; without the stations at a HYDAT site whose gauge is in the box pool or flagged regulated by HYDAT.

**As seen before registration (2026-11-25, throwaway probes; the report's section 1 is their tracked producer, and a count that differs is named there, not corrected here):** 75 natural stations; 36 with at least 3 migration window-years, 33 through 2024; none with 10 baseline years; 185 window-years, 58 unchecked throughout; by a proxy, 44 of 274 HYDAT gauges with a station among their 5 nearest. No carried departure with these stations had been computed.

**Amendments.** Any change to this file after its registering commit is an amendment: dated, appended below the rule with its reason and what had been seen, never an edit of the text above; the script's `rule_commit` moves to it; and the report gives the verdict under each version since the first score existed.

**What it does not decide:** any site report, article number or shipped function. A pass files the follow-up that builds the entry point, which must carry a station's observed years only: its extended values set its baseline mean and nothing else.

### Step 2: the scoring script and its run

The review replaced one invariant that real data would have broken, added the leak assertion and the parity gate against two site reports, and made the final run start from an empty cache.

- [x] `scripts/departure_donors.R`: sources the rule file and refuses to run when it differs from its registering commit (the guard at lines 30–43 of `scripts/station_regulation.R`, `rule_commit` and md5). Refuses a HYDAT release other than 20260717 and a station snapshot other than 20261028. Reads fwapg through the `WET_PG*` variables, as `scripts/station_regulation.R` does (the site script reads bare `PG*`), probing first with `connect_timeout = 10`; without fwapg it stops.
- [x] One process loops over the gauges, calling the rule file's `dd_gauge()`. Daily flows and window statistics for all natural BC HYDAT gauges and the natural stations outside HYDAT are read once and cached under `<WET_DATA_ROOT>/departure_donors/` (default `data/`), keyed on the release, the snapshot and the rule file's md5. Extensions are fitted per held-out gauge, never cached per station.
- [x] Asserted, the run stopping otherwise:
  - in every scored year each value of a station outside HYDAT is observed, never extended;
  - a gauge whose box holds no candidate gives identical departures from both carries;
  - neither g, nor in the leak-free pool any gauge or station related to g, appears in an extension chain (`attr(e, "donors")`) or in a `donors` string used for g;
  - the pools at Swift's and Naver's targets (08KA012, 08KE014) equal the counts line of `data/checks/departure_site_swift_bulk_20260717.txt` and `data/checks/departure_site_naver_bulk_20260717.txt` (box pool, extension pool, departure pool: 30, 11, 13 and 58, 17, 24), so the box and the pools are the site script's.
- [x] The report `data/checks/departure_donors_20260717_20261028.txt`: no timestamp; rows ordered on station number with `method = "radix"`; section 1 restates the population counts of "What exploration found" from the script's own data, naming any that differs from the rule header's; then the rule's commit and md5, the scores, the verdict with its reason, everything the rule lists under "Reported", the scored gauges with the stations each drew on.
- [x] Run it from a frozen copy (`cp scripts/departure_donors.R "$TMPDIR/d.R" && Rscript "$TMPDIR/d.R"`) with the cache directory removed first; log under `data/logs/211/`. Touch nothing it reads while it runs.
- [x] Prove the guards: in a `git worktree` copy, a one-character edit to the rule file makes the script refuse, and removing `dd_baseline_rows()`'s baseline filter fails its test. A second run, from the cache, writes the report byte for byte (`cmp`).
- [x] Commit the script and the tracked report.

### Step 3: the verdict, in the text a reader meets

The review found the superseded sentences are several, not one, and asked that the continuation piece be filed.

- [x] `research/chinook_sites.md`: the section gains the result: the verdict, the medians, the level error, what the sensitivities show, attribution of a loss (the estimated baseline, the day status or the short records), and what each chinook box holds; its counts are reconciled to the report's section 1 (the rule header's copy stays as seen). Revise line 95's sentence on the stations beyond HYDAT. `research/station_sources.md`: revise each sentence the result supersedes (lines 87–92, 137, 138, 152, 153 at the park's tree; grep "donor"). `research/README.md`: the row for `chinook_sites.md`.
- [x] Help text by the result: `R/wet_station_list.R` ("A natural station can serve as a donor where a natural record is needed") and `R/wet_station_select.R`'s pointer say what the test found: that these stations have no 1981–2010 baseline, and whether the estimated-baseline route ships. `devtools::document()`.
- [x] `NEWS.md`: one bullet under a development heading, no version change; the PR body carries `Bump: patch`, `Fixes #202` and `Fixes #211`.
- [x] `CLAUDE.md` above the marker: the script, its rule file, its report and the finding, in the "Chinook pilots" paragraph; the "Regulation per non-HYDAT station" paragraph's last sentence ("a donor pool of the natural non-HYDAT stations is #202") says what #202 found.
- [x] File the same-site continuation as its own issue naming move 18 (2 gauges, what it changes in `wet_station_daily()`), left out of `planning/backlog.md`. If the rule ships, file the follow-up too (the selector beside `wet_station_select()`, the shipped areas, a site-script section, observed years only). If it does not, no follow-up.
- [x] `planning/backlog.md`: nothing by hand (the sweep and the merge tick it).

## Owed at the end (reported, done after merge)

- [ ] Before this worktree is removed, move its `data/logs/211/` and `data/departure_donors/` into the main checkout's `data/`.

## Validation

- [x] Tests pass (`devtools::test()`; `NOT_CRAN=true` on any single-file rerun)
- [x] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- **The rule preceded the scores:** `git log --format='%h %s' -- scripts/departure_donors_rule.R scripts/departure_donors.R` shows the rule's commit before the script's, and the report prints that commit and the rule file's md5.
- **The rule's functions:** `tests/testthat/test-departure_donors_rule.R`, the end-to-end case included, with the baseline filter's test shown to fail when the filter is removed.
- **The script:** its four asserted invariants, the parity with two site reports among them; the byte-identical second run after a first from an empty cache; the guard refusing an edited rule file.
- **The numbers in prose:** every count in the research section, the help text, NEWS and `CLAUDE.md` is a line of the tracked report; grep each before the PR.
- **Nothing shipped moved:** `git diff origin/main --stat -- data/checks/departure_site_* inst/vignette-data vignettes` is empty; `git diff origin/main -- R/` shows roxygen lines only, in `R/wet_station_list.R` and `R/wet_station_select.R`; `lintr` compared per file and line against `origin/main` in a worktree; `pkgdown::check_pkgdown()` (no export added).
- **Public text:** no host, cache path or other repository's issue number in the branch (`push_refs_check.sh` at the push).
