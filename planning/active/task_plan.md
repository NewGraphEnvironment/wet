# Task: Move the Maxan pilot onto the site table and retire departure_pilot.R and departure_snow.R (#146)

**If we do it:** Maxan's pilot, snow regression, data, map and article run from the same site table as the #126 sites, so there is one code path for the method, and a fix lands once. **If we never do:** `scripts/departure_pilot.R` and `scripts/departure_snow.R` stay as copies of `scripts/departure_site.R` and `scripts/departure_site_snow.R`, and an edit to one silently diverges from the other.

## Context

#126 generalised #120's Maxan pilot and #121's snow regression into `scripts/departure_site.R` and
`scripts/departure_site_snow.R`, keyed on `scripts/departure_sites.csv`. Maxan kept a row there only
so two parity gates could make the site scripts reproduce the pilot. Five files still run Maxan off
the old copies: `departure_pilot.R` and `departure_snow.R` themselves, the short-record article's data
and map scripts, and the article, plus `departure_pcic.R`, which hard-codes the Maxan box. So an edit
to the method can silently diverge between the two copies. After this change there is one code path:
Maxan runs from its site row like the other sites, and the two pilot scripts go. Their tracked
reports stay as #120's and #121's record, and a test holds the site reports to them.

What the exploration established (measured 2026-10-30):
- Of the 928 table rows in `data/checks/departure_pilot_20260717.txt` (lines starting with two spaces,
  trailing spaces stripped), 919 appear verbatim in `departure_site_maxan_bulk_20260717.txt`. The other
  9 rows are the section-4 change table, which is equal once the site row's added carried columns
  (characters 83–111: the carried % normal and its interval) are removed. Every table row of
  `departure_snow_20260717.txt` appears verbatim in `departure_site_snow_maxan_bulk_20260717.txt`. The
  lines that differ are prose and headers only.
- The site rds files (`data/departure/departure_site*_maxan_bulk_20260717.rds`) exist only on m4. m4's
  main checkout is clean, on `main` at 14fc428, and has not yet been pulled after #152.
- `data-raw/short_record_vignette_data.R` reads `pilot$mx` and the snow rds's `snow`, `series` and
  `fits`. The site rds carry the same objects: the current gate asserts `mx` `identical()` to the
  pilot's, and the snow fits and series `identical()` to #121's. So repointing the script should leave
  every value in the bundle unchanged. Two report patterns need narrowing, because each site report
  repeats them in its #152 section: the change-table row, and the snow before/after rows.
- Editing `departure_site.R` changes its md5, which makes every site's rds stale for
  `departure_site_snow.R`, `chinook_sites_data.R` and the short-record data. So all four sites are rerun
  on m4 (about 15 min for both scripts, going by the 2026-10-30 file times).

## Decided at the gate

All four were approved with the plan by the user, 2026-10-30.
- **Parity moves from bit-identity to the reports' printed precision.** (user approved the plan, 2026-10-30) The gates currently compare
  the series files bit for bit, but those files are gitignored and the scripts that made them are
  being retired. From now on the gates, and a new test, compare the site reports with the tracked
  pilot and snow reports, which is what the issue asks for.
- **The short-record article stays fixed on Maxan.** It is one site's prose, unlisted. Its data script
  takes the site id as one constant (`"maxan"`). The target, the stream's blue line, the snow gauges
  and the catchments come from the site row. The hand-placed map labels, nudges, Foxy Creek and the
  Bulkley-at-Quick limit stay in the article, because they are that page's cartography and prose.
- **`departure_pcic.R` gets a site id but is not rerun.** It reads its box and `maxan` from
  `site_get("maxan")`. Its report stamps the wet commit and refuses a dirty tree, so a rerun can never
  be byte-identical. Instead the plan checks that the site row's values are `identical()` to the
  literals they replace.
- **`chinook_sites_values.rds` is not regenerated.** Its numbers stay put if every site report reruns
  byte-identical. Its provenance names the commit it was built at.

## Phase 1: Parity helpers and their test (test first)
- [ ] `tests/testthat/test-departure_site_parity.R` (repo-tree test, skipping when `scripts/` or `data/checks/` is absent, as `test-publish_report_live.R` does): the tracked Maxan site reports pass against the tracked pilot and snow reports; one digit changed in a table row, a missing row, and a changed carried value in the change table each fail
- [ ] `scripts/departure_site_lib.R`: `site_parity_pilot(out, tracked)` and `site_parity_snow(out, tracked)`, each returning the tracked lines the run's output lacks. They check every table row, with trailing spaces stripped. For the pilot they also check the six prose lines the current gate names, and match the change table after removing characters 83–111 of the site row

## Phase 2: The site scripts' gates read the reports
- [ ] `scripts/departure_site.R`: drop the rds/md5 gate and `mx_core`; the maxan BULK run stops before writing unless `site_parity_pilot(out, <tracked pilot report>)` is empty; rewrite the header's parity section and its references to `departure_pilot.R` (retired; the tracked report is #120's record)
- [ ] `scripts/departure_site_snow.R`: the same with `site_parity_snow()` and the snow report

## Phase 3: Retire the pilot scripts
- [ ] `git rm scripts/departure_pilot.R scripts/departure_snow.R`; the reports `data/checks/departure_pilot_20260717.txt` and `departure_snow_20260717.txt` stay
- [ ] Repoint the comments that name them: `scripts/departure_snow_lib.R`, `scripts/station_sources_probe.R`, `research/station_flow_departure.md` (the #120 and #121 "Produced by" lines: retired in #146, recoverable from git at the commit before it), and `CLAUDE.md`'s station-departure, #126 and short-record paragraphs and the Database line (`departure_site.R` now reads the bare `PG*` variables in the pilot's place)

## Phase 4: The short-record article onto the site run
- [ ] `data-raw/short_record_vignette_data.R`: read `departure_site_maxan_bulk_20260717.rds` and `departure_site_snow_maxan_bulk_20260717.rds` (held to the md5s of `departure_site.R` and `departure_site_snow.R`) and their tracked reports. Narrow the change-table and snow-change patterns to the section-4 table and the first table of section 3, and re-index the change row's fields. Take the target and the snow gauges from `site_get("maxan")`. The bundle gains `site` (site_id, name, wsg_code, target_station, blue_line_key, snow_gauges), and its provenance names the site scripts and reports
- [ ] `data-raw/short_record_vignette_map.R`: the catchment gauges and Maxan's blue line come from `values$site`
- [ ] `vignettes/short-record-flow.Rmd`: `maxan` and the catchment parts come from `v$site`
- [ ] `tests/testthat/test-vignette_data.R`: the bundle's names now include `site`, and its target and snow gauges match the site row
- [ ] On m4 (branch checked out in the clean main checkout): rerun `departure_site.R` and `departure_site_snow.R` for maxan, swift, naver and gosnell, from frozen copies; every tracked site report must come out byte-identical (`git status` clean under `data/checks/`)
- [ ] On m4: run the short-record data and map scripts. Assert every element of the new bundle is `identical()` to the old one, apart from `provenance` and the new `site`, and the map layers likewise. Commit the bundles

## Phase 5: departure_pcic.R takes a site id
- [ ] `scripts/departure_pcic.R`: `site <- site_get("maxan")`; `box <- site$box`; `maxan <- site$target_station`; one header line says so; `Rscript` check that both are `identical()` to the literals they replace

## Owed at the end (reported, done after merge)
- [ ] m4: put the main checkout back on `main` and pull (this also clears the pull owed since #152)

## Validation
- [ ] Tests pass (`devtools::test()`), lintr clean on touched R
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- Helpers: the new test passes on the tracked reports, and fails on a doctored copy of each kind (a mutation table in findings.md).
- Gates: the maxan reruns on m4 pass the new gates, and a frozen copy run against a doctored copy of the tracked report refuses before writing (one mutation per script).
- Retirement: `grep -rn 'departure_pilot\.R\|departure_snow\.R'` outside `planning/archive/`, `NEWS.md` and the tracked reports finds nothing still pointing at a live script.
- Article: all site reports are byte-identical after the reruns; the bundle is `identical()` apart from provenance and `site`; the article renders from the installed branch, and its text, stripped of HTML, diffs empty against a render at main.
- `departure_pcic.R`: the `identical()` check above.

