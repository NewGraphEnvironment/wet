# Task: Backlog move 10: Swift and Naver creeks under their own chinook windows (#187)

**If we do it:** Swift Creek and Naver Creek are scored in their own stocks' cited chinook salmon life history timing windows, beside the Bulkley's, and wet reads the life history table at a commit that holds the upper Fraser and Cottonwood rows. **If we never do:** the two Fraser streams stay under the Bulkley's windows, so a difference in run timing can read as a difference in flow.

Carries #182 (one issue, one PR). `planning/backlog.md` batch 12, move 10; move 12 (#189) waits on it for `research/chinook_sites.md`.

## Decided at the gate

No plan gate ran in this pane: the coordinator dispatched this `park review` (soul#928), so the plan gate is the coordinator's at the resume, on the pushed review. What exploration settled (2026-11-22):

- **The knowledge commit to pin was `4e2d8a0c473c73fafa367ba09794f98e98798db8`** (superseded at the resume by decision 1; 2026-11-18, "#174: UFRA and COTR chinook timing from NuSEDS and the literature"), the commit that added the rows. `data/life_history_timing.csv` at knowledge `main` (b07ce5a, 2026-11-21) is byte-identical to it, so pinning main would read the same table under a sha that names unrelated work.
- **At that commit the BULK and MORR rows differ from `c97c4d0`'s in one note only** (BULK CO migration, a row every reader drops for having no end). Every BULK and MORR start, end and source is unchanged, so `life_history_morr.csv` rebuilds byte-identical and the Maxan parity gate (BULK windows) cannot move. The guard below holds that by code, not by this reading.
- **#180 has merged** (PR, move 5), so #182's "after #180" is met. **#181** (move 12) also rewrites `research/chinook_sites.md` and waits on this move, so this PR revises the file and #181 folds it in later.
- **The site scripts already loop over each site's window sets** (`site_windows()`, `scripts/departure_site.R:412`, `scripts/departure_site_snow.R:120`) and name reports `departure_site[_snow]_<site>_<group>_<release>.txt`; `data-raw/chinook_sites_data.R:130` loops the same way. The work is the table, the runs, and the article's assertions written for one non-BULK window set (the review found the bundle script needs no logic change).
- Knowledge's open timing work: knowledge#241 (Skeena), knowledge#242 (Fraser and Thompson) and knowledge#243 (every group) review the timing rows against NuSEDS and the literature; knowledge#256 sets how NuSEDS spawning dates are read (what a record can bound). #242 and #256 may revise the UFRA and COTR rows. See Open decisions.

## Decisions (owner, 2026-11-25, at the resume)

1. **Adopt the UFRA and COTR windows now, pinned at knowledge `a475dfe7b6d8923bdcfd67506f9f1c5573ffcde7`** (2026-11-24, #256 code-check round 4), not `4e2d8a0c`. The owner: "Knowledge is done. Make sure this issue is [not] dealt with elsewhere." Measured at the resume: knowledge#256 closed 2026-11-24; its four commits to `data/life_history_timing.csv` (5b0bb27 to a475dfe) rewrite only the UFRA and COTR chinook `note`s, which now say NuSEDS's start and end dates are estimates; no start, end or source moved, and knowledge `main` (f0a6cbd) is byte-identical to a475dfe for the file. knowledge#242 stays open but says "UFRA and COTR's chinook rows (#96) stay unless the review finds otherwise". No open wet or knowledge issue or PR other than #182 and #187 carries this work. The article's limit and `research/chinook_sites.md` still say the edges are NuSEDS estimates; the follow-up issue re-pins only if #242 revises the rows.
2. **Move only `data-raw/life_history_data.R`'s pin**, with the guard that its BULK chinook rows equal `life_history_bulk.csv`; `data-raw/station_vignette_data.R` stays at `c97c4d0`.
3. **Leave both site scripts unchanged**: swift and naver reruns only; the UFRA/COTR report headers name the migration row's source only, and the spawning sources and the caveat go in the article and the research note.

## Open decisions

None.

## Phase 1: the UFRA and COTR windows

Review: the guard's set was corrected (MORR compared in every column, notes included, since `life_history_morr.csv` writes them; BULK's guard protects the cited table, not the parity gate, which reads `life_history_bulk.csv`), the source assertion made per row, and the restored-defect test given a way in.

- [x] `data-raw/life_history_data.R`: `groups <- c("MORR", "UFRA", "COTR")`; pin knowledge `a475dfe7b6d8923bdcfd67506f9f1c5573ffcde7` (decision 1); also read the table at `c97c4d0` and stop unless MORR's rows are equal at both commits in every column, BULK's in every column but `note`, and the BULK chinook migration and spawning rows equal `inst/vignette-data/life_history_bulk.csv`'s. Put the comparison in a function taking the two tables, so the restored-defect test can hand it a doctored copy without `gh api`. Fix the comment "# as data-raw/station_vignette_data.R" on the pin (false once the pins differ).
- [x] Assert each new chinook row's start, end and exact `source` string: UFRA migration 04-01..08-10 `bradford_taylor2023Diversityfreshwater; cosewic2018COSEWICAssessment; fisheriesandoceanscanadaNuSEDSNewSalmon`; UFRA spawning 08-11..09-05 `fisheriesandoceanscanadaNuSEDSNewSalmon; candy_etal2002discussionpaper`; COTR migration 04-01..08-09 `candy_etal2002discussionpaper; fisheriesandoceanscanadaNuSEDSNewSalmon`; COTR spawning 08-10..09-06 `fisheriesandoceanscanadaNuSEDSNewSalmon; candy_etal2002discussionpaper`.
- [x] Update the header comment (groups, sources, pin and the guard). Run it: `inst/vignette-data/life_history_ufra.csv` and `life_history_cotr.csv` written (two CH rows each); `life_history_morr.csv` byte-identical (`git diff --exit-code`).
- [x] Restore the defect and prove the guard fires: hand the comparison a copy whose MORR spawning start differs, and separately one whose MORR note differs, and see each stop.
- [x] Commit before Phase 2: the site scripts read the committed CSVs.

## Phase 2: the site table and the runs

Review: under decision 3's recommendation the site scripts are not edited; the env and the stamped inputs were corrected; the April starts were flagged.

- [x] `scripts/departure_sites.csv`: Swift's `windows` `BULK UFRA`, Naver's `BULK COTR`. Commit.
- [x] Before running, on m1 (which runs the chinook site scripts since #167 and holds every site's series under `data/departure/`; this worktree has none): count the complete April-start migration windows at 08KA012 and 08KE014 in HYDAT 2026-07-17 (`wet_window_stats()`, `min_frac = 0.8`), since `departure_site.R:427` stops under 3; and check cd's ERA5-Land layers (`CD_RUN_TIME`, `CD_SHA`, printed at `departure_site_snow.R:374`) and `pcic.series` (fwapg commit and md5 in each site report) are still the ones the BULK reports name. If either was republished, the BULK reports cannot rerun byte-identical: stop and report.
- [x] Run, committed first: `WET_HYDAT_RELEASE=20260717 Rscript scripts/departure_site.R swift`, then `naver` (libpq's bare `PG*`), then `scripts/departure_site_snow.R swift` and `naver` (`WET_PG*`), with the PCIC year cache each header names. Logs under `data/logs/187/` in the main checkout.
- [x] New reports `data/checks/departure_site_swift_ufra_20260717.txt`, `departure_site_naver_cotr_20260717.txt`, `departure_site_snow_swift_ufra_20260717.txt`, `departure_site_snow_naver_cotr_20260717.txt`; the four `*_bulk_*` reports for Swift and Naver rewritten byte-identical (`git diff --exit-code`). Maxan and Gosnell are not rerun, so their reports, series and the parity test (`tests/testthat/test-departure_site_parity.R`, Maxan BULK only) are untouched; run the test under `NOT_CRAN=true` anyway.
- [x] Record each new window set's section 6 verdict (#147's rule: `covariance_pick` or distance), its section 5 change and its held-out scores in `findings.md`. Commit every report before Phase 3 (`vd_commit()` refuses a dirty `data/checks/`).

## Phase 3: the bundle and the comparison article

Review: the bundle script needs no logic change (`:130` loops every group; `:391`, `:465`, `:491`–`:496` already pick BULK); the article's assertions over every window set were listed; the bundle comparison names its expected differences; the map was added.

- [ ] `data-raw/chinook_sites_data.R`: header text only (which groups each site carries). Rebuild on m1. Compare with the old bundle after resetting row names: every element `identical()` except the expected differences: the UFRA/COTR rows added to `scores`, `windows`, `carry`, `score_settings`, `years`, `normal`; `sites$windows` for swift and naver; and `gauges` (no group column, the union of donors over window sets, `:380`–`:389`), which may gain donors used only under UFRA or COTR; list any it gains.
- [ ] `data-raw/chinook_sites_map.R` draws `values$gauges` (`:53`): rebuild `chinook_sites_map.rds` through `vm_write()` if the gauges changed (the Fraser map gains those donors), else confirm it is untouched.
- [ ] `vignettes/articles/flow-change-sparse-gauges.Rmd`, the assertions over every window set, case by case (keep a claim that spans every window set, rewording its prose if it no longer holds; filter to BULK and MORR only where the prose is about them): `:81`–`:82` (every change range's coverage at least 0.87), `:102`–`:104` ("fell clearly only at Maxan ... of every stream and window set"), `:108` (`n_pre` 10..30, `n_post` 9..10), `:136` (every borrowed migration-mean score at least 0.5), `:148` (`cy$ship[cy$site_id == "swift"] == "distance"`, now length 2), `:560` and `:581` (snow migration slopes above 0 in every group); rewrite `:158` to the four sites' window strings in the table's order (`BULK`, `BULK UFRA`, `BULK COTR`, `BULK MORR`), with its comment at `:157`.
- [ ] The paragraph after the Morice's (`:519`) reports Swift and Naver under their own windows (when each starts and ends against the Bulkley's, the spawning-window change and whether its range clears no change), each number under a `stopifnot()` in the chunk that computes it; restate "chinook salmon life history timing window" in full at first use in the section (CLAUDE.md naming rule). The `windows`, `years` and `change` figures (`:380`, `:414`, `:505`) stay on the Bulkley's windows, as Gosnell's Morice windows were left; check "used here at all four streams" (`:376`) still reads right beside the new paragraph.
- [ ] Rewrite the limit "The windows are the Bulkley's at all four streams. Only the Morice has its own cited windows" (`:629`) to what is now true, adding (decision 1) that the Fraser windows' edges are NuSEDS estimates.
- [ ] Cite Bradford and Taylor (2023), COSEWIC (2018) and Candy et al. (2002) where the paragraph uses them; regenerate the `.bib` with `Rscript data-raw/vignette_bib.R vignettes/articles/flow-change-sparse-gauges.Rmd`. Each key must resolve in the Zotero group library and carry a url or DOI (`vignette_bib.R:95` stops otherwise; check the Candy item); add or fix any that do not, per the reference conventions. Check the shared keys keep their titles, years and DOIs.
- [ ] Word cap: measure body prose before and after; raise `cap` (`:694`, now 1140) only by what the new paragraph and limit need, with the comment saying why.
- [ ] Install the branch, build the article, read the rendered page (no `citation ... not found` in the log), strip it to text and diff against main's render: only the new paragraph, the limit, the bundle's commit line (`:668`) and the bibliography differ.

## Phase 4: research and project notes

- [ ] `research/chinook_sites.md`, revised in place: `:21` ("No cited windows exist yet for the upper Fraser or the Cottonwood"); `:25`, `:35`, `:36` and `:93`, which say what each window set scores; a section on Swift and Naver under their own windows (windows and each row's sources, change, scores, section 6 verdict, the estimate caveat, and, under decision 3's recommendation, that each UFRA/COTR report header names the migration row's source only); the verified line.
- [ ] `CLAUDE.md`: the chinook-sites paragraph says Swift and Naver also run under their own groups' windows and that `data-raw/life_history_data.R` now pins knowledge apart from `data-raw/station_vignette_data.R`; update the shipped-route sentence if a new window set's verdict differs; correct the article's stated cap (it says 1,060; the article holds 1140, more if Phase 3 raises it).
- [ ] File a follow-up issue (no number written before it exists): re-pin and rerun when knowledge#256 or knowledge#242 revises the UFRA or COTR rows.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

Verification: Phase 1 by the guard and its restored defect, and `life_history_morr.csv` unchanged; Phase 2 by the BULK reports byte-identical and the Maxan parity test; Phase 3 by the bundle compared element by element with its expected differences named, every new sentence's `stopifnot()`, and the text diff of the rendered article; Phase 4 by grepping `research/` and `CLAUDE.md` for "No cited windows exist yet", "at every site", "Only the Morice" and "Bulkley's at all four".
