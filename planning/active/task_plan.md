# Task: Publish segment_daily: the balance's daily shape and routed PCIC's day-of-year climatology per segment (#99)

**If we do it:** a segment's flow can be read for any week or month-day window from a published daily climatology for both sources, with the balance's days consistent with its published months. **If we never do:** the daily shape #70 fitted and scored stays in the fit directory, and every window read still spreads each month's mean over its days (up to 27 % off the gauge in the Chinook fry-migration window, #65).

## Context

Every window read today spreads each month's mean over its days (up to 27 % off the gauge in the
Chinook fry-migration window, #65). #70 fitted and shipped the balance's within-month shape
(`fit_20260717/shape_daily.rds`, donor k = 5, refitted on #102's months), and fwapg#25 (PR #32)
loaded routed PCIC's day-of-year climatology as sub-basin days + per-segment weights
(`pcic.subbasin_daily`, `pcic.segment_weights`, fingerprints in `pcic.runs`). #101, #102 and #103
are closed, so nothing upstream blocks. This builds and publishes `discharge/fwa/v1/segment_daily`
(one row per segment, source and `doy` 1–365, Feb 29 folded into Feb 28), and the readers for it.

Explored: `scripts/pcic_routed_lib.R` (run named once via `wet_segment_sources()`, fingerprint
asserted against `pcic.runs`), `R/wet_segment_monthly.R` (`wet_timebase()` already a switch;
`wet_segment_pg()`/`wet_segment_parts()` hard-code `month`; `wet_segment_sources()` gives fwapg a
row only for the month timebase), `R/wet_db_load.R` (`months`, PK on `month`, partial index
`month = 0 AND pick`), `R/wet_values_compare.R` (`id * 16 + month`), `R/wet_catalog.R` (part regex
already accepts `part-<A-Za-z0-9>`; `drainage` label required per code), `scripts/segment_output.R`,
`scripts/discharge_publish.R` + `_lib.R` (per-drainage parts, single-PUT with Content-MD5, value
checks #64, crate release check), `R/wet_shape_predict.R` (`wet_shape_predict()`, `wet_shape_daily()`),
fwapg's `pcic_crosswalk09_discharge.sql` (`round(greatest(q, 0)::numeric, 5)`).

Measured during planning: m1's and m4's fwapg both hold both runs in `pcic.runs` (daily_rows
13,786,122, weights_rows 3,377,037); m4 has 426 GB free; the live manifest's largest monthly part
is 215 MB (balance part-200, 17.6 M rows), so a daily part per drainage would be ~6 GB.

## Decided at the gate (airvine, 2026-10-20)

- **Daily parts per watershed group:** `segment_daily/scenario=/forcing=/source=/part-<GROUP>.parquet`
  (~490 parts, ~80 MB average), each under S3's 5 GB single PUT so the md5/ETag check holds; the
  manifest labels each with its group's name. Monthly parts stay per drainage.
- **crate:** I open, merge and release the crate PR carrying `segment_daily.yaml` inside this run.
- **Publish during the branch,** as #102/#103: I BUILD on m4, the user runs the PUBLISH there
  (auto mode refuses it), I rerun BUILD to confirm identical, then regenerate the article data
  against the live build before the PR.

Mechanism choices I made (not questions):
- The daily table gets its own script, `scripts/segment_daily_output.R`, not more code in
  `segment_output.R` (the issue's item 4): the daily run takes far longer and reads the monthly
  table for `pick`, so the monthly rerun stays fast. Both reruns are needed anyway at the end.
- Routed days are computed in R from the two tables read once per run (37,667 × 365 folded
  matrices; each distinct upstream set summed once), rounded as fwapg rounds (5 decimals, after the
  clamp), so they sit on the same footing as `pcic.discharge_monthly`/`_weekly`.
- PUBLISH uploads only parts whose md5 differs from the live manifest's (still verifying all), so
  a monthly-only republish does not resend ~40 GB of unchanged daily parts.
- No `watershed_daily` dataset, no `from = "fwapg"` daily read (fwapg keeps no per-segment days),
  and no Postgres load of the daily in this run (the issue: partial and on request).

## Phase 1: Routed days from the weights (`scripts/pcic_routed_lib.R`, `R/`)
- [x] Internal `wet_routed_fold()` (366 bins → 365, n_days-weighted, on q_local and q_acc) and
      `wet_routed_days()` (segments × 365: `greatest(sum q_acc[upstream] + q_local[subid] * share, 0)`,
      returning raw and clamped, clamped rounded to 5 dp), in `R/`, with unit tests on a tiny
      hand-computed network (fold weights, an empty upstream set, a losing reach clamped, a
      shared upstream set computed once)
- [x] `routed_daily_fingerprint(conn)`: daily rows/sub-basins/`daily_q_sum` and weights
      rows/`weights_share_sum` computed from the rows, refused unless equal to the run's `pcic.runs`
      row (as `routed_fingerprint()` does for months); `routed_daily_inputs(conn)` reads the run's
      days (filtered on `routed_where`) and the weights once
- [x] Acceptance probe (m4's fwapg over the LAN; m1's `pcic.subbasin_daily` is empty): n_days-weighted
      means of the raw (unclamped, unrounded) days over each month and week, clamped and rounded by
      `wet_routed_round()`, reproduce `pcic.discharge_monthly` and `pcic.discharge_weekly` on a few
      groups (BULK, a Fraser mainstem group, a coastal group); rows differing only by one 1e-5 step
      at a rounding tie are counted, not failed (review 2); `wet_routed_round()` checked against
      Postgres's own `round(q::numeric, 5)` on a large sample
- [x] Measure the per-day clamp: clamped rows per day, overall and mid-network (fwapg's
      `qa_report_clamped.sql` definition), against fwapg's monthly 0.978 % / weekly 0.977 %;
      record in `findings.md`. Rule set before measuring: the clamp is fwapg's rule and the
      daily is published whatever it measures; a mid-network share above 0.1 % (twice the
      weekly's) is stated as a weakness in the dataset description and research

## Phase 2: crate schema (NewGraphEnvironment/crate)
- [x] `inst/extdata/schemas/nge/discharge/fwa/v1/segment_daily.yaml` (columns
      `linear_feature_id, watershed_group_code, doy, runoff_mm, q_m3s, coverage, period, pick`;
      the routed days' month-consistency, `runoff_mm` in mm/day (February's days summing to
      28/28.25 of the monthly mm), only `q_m3s` means matching the months, and no annual row
      stated in the description; review 13) and its registry row, as
      crate#31 added `segment_monthly`; fix `segment_monthly.yaml`'s stale "routed 1951-2012"
      period note (1981-2010 since wet#103) in a separate commit
- [x] crate tests and check pass; PR, `/code-check`, merge, release (tag + GitHub release)
- [x] `discharge_publish.R`'s crate release check covers `segment_daily`

## Phase 3: Readers over `doy` (`R/`)
- [x] `wet_timebase()` gains `daily = list(col = "doy", values = 1:365)`
- [x] `wet_segment_pg()` and `wet_segment_parts()` select the timebase's column, not `month`;
      for per-group parts, `wet_segment_parts()` opens only the parts whose code is in `groups`,
      and a daily read of parts requires `groups` (review 8)
- [x] Exported `wet_segment_daily(conn, segments, source, scenario, groups, catalog)`
      (`from = "published"` only), returning `linear_feature_id, doy, q_m3s, source` with 365 NA
      rows for a missing segment, feeding `wet_flow_window()` with `basis = "daily"`; runnable
      `@examples` (`\dontrun{}` for the network read, as `wet_segment_monthly()`), pkgdown index
- [x] `wet_db_load()`: time column from the timebase (`months` for monthly, `doys` for daily),
      a `groups` subset filtered before any part is fetched (recorded in the table comment as a
      subset; review 8), PK on the time column,
      `month = 0 AND pick` partial index for monthly only
- [x] `wet_values_compare()` keyed on a `time` column (`id * 512 + doy`, exact below 2^53)
- [x] `wet_catalog()` docs: a daily part's `code` is a watershed group, labelled with its name
- [x] Tests for each against small local parquet trees and the existing helpers;
      `devtools::document()`, `lintr`, `pkgdown::check_pkgdown()`

## Phase 4: The daily table (`scripts/segment_daily_output.R`)
- [x] Loop over drainages (the inputs' unit, review 4): each watershed's 365 days computed once,
      `wet_shape_daily(output months, wet_shape_predict(shape_daily.rds, upstream predictors))`, only
      where the balance has months, asserted equal to the complete-predictor set and
      `shape_daily.rds$method == "donor"` (review 5); through `fwa_streams_watersheds_lut` to
      segments; routed days from Phase 1; `runoff_mm`, `coverage` and `period` as the monthly rows
      (routed `runoff_mm` NA off its own line); `pick` carried from the monthly segment table;
      (drainage, group) pieces assembled into one file per group. Guards as `segment_output.R`:
      clean tree, shipped fit and scoring md5, `shape_daily.rds` made on this fit, routed table =
      the tracked routed report's, the daily inputs' fingerprint, monthly segment table current,
      routed segments in the weights = the monthly table's routed segments (review 15)
- [x] The province reproduction of `pcic.discharge_monthly` from the raw days is a guard in the
      script, its counts in the report (review 15); `wb_output.R` and `segment_output.R` unlink
      `segment_daily/` with `segment/` (review 6)
- [x] Writes `<fit>/segment_daily/<GROUP>.parquet` and report
      `data/checks/segment_daily_output_<release>.txt`: rows, the per-day clamp, the routed
      segment-months whose n_days-weighted day mean differs from the published month by more than
      the rounding (count and largest), and the balance identity (every calendar month's days
      average to its monthly row, relative 1e-9; review 14)
- [x] Run on m4 (worktree, `data/` symlinked), whole-province Phase-1 reproduction there, timing
      recorded; commit the report

## Phase 5: Publish (`scripts/discharge_publish.R`, `_lib.R`)
- [x] BUILD writes `segment_daily` parts per group, conformed to crate (`publish_part_prepare()`
      generalised over the time column); manifest labels per group from
      `fwa_watershed_groups_poly` (review 7); guards for the daily table: its report's commit and
      its own git diff, the daily script left out of the monthly table's diff, mtime after the
      segment table, report naming seg_commit, one part per group, 365 rows per segment and
      source (reviews 6, 9); the daily hive line names its dataset and `vignette_data_lib.R`'s
      `re_seen` is anchored to `segment_monthly` (review 3)
- [x] Value checks (#64) for the daily: routed days recomputed independently (per distinct
      upstream set, not the build's per-segment `rowsum()`), unrounded within relative 1e-12 and
      rounded equal except a 1e-5 step at a tie, tie flips counted on their own line (review 1); balance days recomputed from `output/` and the
      shape through the lut; `q_m3s`, `runoff_mm`, `coverage`, `pick` against the daily table;
      the balance's month identity against `segment_monthly`; inputs' fingerprints exact
- [x] PUBLISH skips a part only when its HEAD ETag equals the local md5 (review 12), then
      verifies every part
- [x] Every R/ and scripts/ edit (Phase 6's included) committed first (review 11). On m4:
      `segment_output.R`, commit its report; `segment_daily_output.R`, commit its report; BUILD,
      commit its report (review 10); hand the user the PUBLISH command; BUILD again and commit
      (all parts identical to live)

## Phase 6: Docs and articles
- [ ] `research/discharge_publish.md`: `segment_daily` built and published (layout, sizes, checks
      table, the clamp and month-consistency figures); `CLAUDE.md` architecture paragraph
- [ ] `vignettes/segment-discharge.Rmd`: the daily read (`wet_segment_daily()` and a window with
      `basis = "daily"`), its recipe run and checked by `data-raw/segment_vignette_data.R` against
      the live build under the existing guards; regenerate on m1
- [ ] `vignettes/monthly-flow.Rmd`: the limits line points to the published daily, not a plan
- [ ] Fix the issue body where the work corrected it (the check's equality is after rounding;
      the separate script); file the follow-up for daily-basis windows in the monthly-flow table

## Owed at the end (reported, done after merge)
- [ ] Remove the m4 worktree after moving its `data/logs/99/` into the main checkout

## Validation
- [x] Tests pass
- [x] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: unit tests on hand-computed fixtures for the fold, routing, readers,
loader and comparer (each guard restored to the bug once, `code-check.md`); the Phase-1
reproduction of fwapg's monthly and weekly tables from the routed days (every row, province on
m4); the BUILD's value checks with 0 differing; the post-upload BUILD byte-identical to live; the
article data scripts' refusals passing against the live build.

