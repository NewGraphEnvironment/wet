# Task: Read routed PCIC from fwapg's pcic schema, run pinned at 1951-2012 (no value changes) (#101)

**If we do it:** wet reads routed PCIC from fwapg's `pcic` schema, with the run named in one place, and fwapg can drop its two frozen `whse_basemapping` copies (NewGraphEnvironment/fwapg#31). No published value changes. **If we never do:** wet keeps reading the frozen first build, fwapg#31 waits, and a reader can pick the stale copy by name.

**Scope:** the read only, pinned to the 1951–2012 run, which equals today's table row for row. Switching to the 1981–2010 run changes every routed value and needs a republish; that is #103.

## Context (plan mode)

wet reads PCIC's routed monthly flow from fwapg's frozen first build,
`whse_basemapping.fwa_stream_networks_discharge_monthly`. fwapg#25 (PR #32, merged 7c30f58) moved
routed flow into a `pcic` schema keyed by run (`model, scenario, period`), and fwapg#31 waits to drop
the frozen copies until wet stops reading them. This issue switches the read only, pinned to the
`PNWNAmet / historical / 1951-2012` run, which equals today's table row for row (40,524,444 rows,
3,377,037 segments, total 178035348.248310). No published value changes. #103 later flips the period.

Found while exploring:
- The table name is hard-coded twice: `R/wet_segment_monthly.R:84` (`wet_segment_sources()`) and
  `scripts/pcic_routed_lib.R:12` (`routed_table`, asserted equal to the package's in `routed_annual()`).
- `sprintf("routed: %s, built by NewGraphEnvironment/fwapg at %s", routed_table, commit)` is built in
  three places (`pcic_routed_compare.R:106`, `segment_output.R:96`, `vignette_data_lib.R:48`) and grepped
  back by `discharge_publish.R:203` into the manifest's provenance.
- "1951-2012" is also hard-coded in `segment_output.R:120` (`period_routed`, the published `period`
  column), `pcic_routed_compare.R:108,206` (report text) and `discharge_publish.R:294` (manifest
  description). For #103 to flip one value, these take the run's period.
- m1's fwapg has no `pcic` schema yet; m4's neither (assumed; m4 unreachable over ssh from m1 right now).
  The fresh-db container has psql 17.5 but no curl, so `load/pcic.sql`'s `\copy FROM PROGRAM 'curl …'`
  must run from a host psql. m1 has one; m4 has none.

## Phase 1: Load the `pcic` schema
- [ ] m1: run the issue's load block from an fwapg checkout at `origin/newgraph` (7c30f58), both runs;
      check `pcic.runs` has the 1951–2012 row with 40524444 / 3377037 / 178035348.248310
- [ ] m1: confirm 0 rows differ between the 1951–2012 run and the `whse_basemapping` table (one SQL
      `EXCEPT` both ways), recorded in findings
- [ ] m4: same load. Route: psql on m1 against m4's fwapg over Tailscale if its port is reachable;
      otherwise ask (installing psql on m4 is a machine change)

## Phase 2: One definition of the run (package)
- [ ] `wet_segment_sources()`: the fwapg row names `location = "pcic.discharge_monthly"` and the run in
      three new columns `model`, `scenario`, `period` (`PNWNAmet`, `historical`, `1951-2012`; NA on the
      published rows); `origin` names fwapg's `load/pcic_schema.sql`, `load/pcic.sql`, `load/pcic_run.sql`
- [ ] `wet_segment_fwapg()`: filter every read on `(model, scenario, period)`; the requested scenario
      must equal the run's (message from the lookup, "historical" still the only one); a missing table
      names the three load files; a table with no rows for the run is an error naming
      `load/pcic_run.sql` and the run (index seek on the primary-key prefix, not a scan)
- [ ] roxygen: `from = "fwapg"` names the table, the run and the period; `devtools::document()`
- [ ] tests (`test-wet_segment_monthly.R`): reference months from `pcic.discharge_monthly` under the run
      filter; new test that a missing run is an error (mock `wet_segment_sources()` to a run that does
      not exist); the missing-table test expects the load-file names. Restore each defect once to see
      the new tests go red

## Phase 3: Scripts take the run from the package
- [ ] `scripts/pcic_routed_lib.R`: `routed_run` (the lookup row) and `routed_table` from
      `wet:::wet_segment_sources()`, a `routed_where` SQL filter, and `routed_line(commit)` replacing the
      three `sprintf`s (`routed: pcic.discharge_monthly (PNWNAmet historical 1951-2012), built by
      NewGraphEnvironment/fwapg at <commit>`); header comment rewritten
- [ ] `routed_fingerprint()`: computed from the run's rows as now (same text, so the `table:` line is
      unchanged), and stops unless rows, segments and total equal the run's row in `pcic.runs`
- [ ] `segment_output.R` (routed join, count of routed segments, `period_routed`),
      `discharge_publish.R` (whole-run read, description period), `data-raw/monthly_vignette_data.R`
      (routed months), `pcic_routed_compare.R` (report text period): filter on the run, use
      `routed_line()` / `routed_run$period`; `vignette_data_lib.R` uses `routed_line()`
- [ ] `WET_FWAPG_COMMIT` stays; its error message names the run; usage headers say 7c30f58

## Phase 4: Docs
- [ ] CLAUDE.md routed-table lines (scripts list #58, Data Sources "PCIC routed flow"),
      `research/discharge_publish.md` (value-check row and the table named, Verified line),
      `research/README.md` row if it names the table. Dated records stay as written
- [ ] NEWS.md entry under the development version

## Phase 5: Reruns (the issue's "Done when")
- [ ] m1: `WET_FWAPG_COMMIT=7c30f58 Rscript scripts/pcic_routed_compare.R`; diff vs committed report:
      only the wet commit and `routed:` lines differ; commit the report
- [ ] m4 (worktree, `data/wb` symlinked): `segment_output.R`; every segment part byte-identical (md5
      before/after); report differs only in those lines; commit the report
- [ ] m4: `discharge_publish.R` BUILD (no `WET_PUBLISH`): every value check passes, every part
      byte-identical to the live build; commit the report. Nothing uploaded
- [ ] m1: `data-raw/segment_vignette_data.R` and `data-raw/monthly_vignette_data.R` pass their guards;
      bundle values equal the previous bundles' (compare all but provenance); provenance names
      7c30f58 and the new table; commit the `.rds`
- [ ] Comment on NewGraphEnvironment/fwapg#31 that wet no longer reads the frozen tables (after merge
      of this PR, linking it)

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification
- Phase 1: `SELECT * FROM pcic.runs`; the `EXCEPT` both ways returns 0.
- Phase 2: `devtools::test(filter = "wet_segment_monthly")` live on m1; mutation runs for the new guards.
- Phase 5: report diffs (`git diff data/checks/`) limited to the named lines; md5 of every part
  before/after on m4; BUILD report's "parts identical to the published build N of N"; `identical()`
  of old and new vignette bundles with provenance dropped.

Risk: m4 unreachable or without a way to load → Phases 5's m4 steps wait; everything else lands and the
blocker is named in the PR.
