# Findings — Read routed PCIC from fwapg's pcic schema (#101)

## Issue context

**If we do it:** wet reads routed PCIC from fwapg's `pcic` schema, with the run named in one place, and fwapg can drop its two frozen `whse_basemapping` copies (NewGraphEnvironment/fwapg#31). No published value changes. **If we never do:** wet keeps reading the frozen first build, fwapg#31 waits, and a reader can pick the stale copy by name.

**Scope:** the read only, pinned to the 1951–2012 run, which equals today's table row for row. Switching to the 1981–2010 run changes every routed value and needs a republish; that is #103.

Upstream fwapg loads no PCIC table, so this neither moves wet away from upstream nor toward it: the routed table was always an extra of New Graph's fork. Wet's other FWA reads stay on `whse_basemapping`.

## What fwapg provides (NewGraphEnvironment/fwapg#25, PR #32)

- `pcic.discharge_monthly`: `model, scenario, period, linear_feature_id, watershed_group_code, month, q_m3s`, primary key `(model, scenario, period, linear_feature_id, month)`.
- `pcic.runs`: one row per run, with `monthly_rows`, `monthly_segments`, `monthly_q_sum` (`sum(round(q_m3s::numeric, 6))`), `crosswalk_md5` and `built_at`. It records no build commit.
- `pcic.fwa_crosswalk`, shared by every run.
- The 1951–2012 run: 40,524,444 rows on 3,377,037 segments, `monthly_q_sum` 178035348.248310, and 0 rows differing from `whse_basemapping.fwa_stream_networks_discharge_monthly`.

## What changes in wet

- **One definition of the run.** The package names the table and the run together (`wet_segment_sources()` in `R/wet_segment_monthly.R`), and `scripts/pcic_routed_lib.R` takes them from there, so #103 flips one value. Every read is filtered on `(model, scenario, period) = ('PNWNAmet', 'historical', '1951-2012')`. The reads that interpolate `routed_table` today:
  - `routed_fingerprint()` and, through `wet_segment_monthly(from = "fwapg")`, `routed_annual()` (`scripts/pcic_routed_lib.R`);
  - `scripts/segment_output.R` (the per-basin routed join and the count of routed segments);
  - `scripts/discharge_publish.R` (the whole table, for the value checks);
  - `data-raw/monthly_vignette_data.R` (routed months at the segments used).
- **The fingerprint is still computed from the rows,** because it is what catches a table changing during a run, which a stored row cannot. It also asserts that its rows, segments and total equal the run's row in `pcic.runs`.
- **`WET_FWAPG_COMMIT` stays,** because `pcic.runs` has no commit. The runs were built from fwapg PR #32's branch, merged as 7c30f58.
- **`wet_segment_monthly(from = "fwapg")`:** its documentation names the table, the run and the period. A missing table names fwapg's `load/pcic_schema.sql`, `load/pcic.sql` and `load/pcic_run.sql`. A table without the run's rows is an error, not every segment missing. `"historical"` stays the only scenario.
- **Tests:** `tests/testthat/test-wet_segment_monthly.R` reads its reference months from `pcic.discharge_monthly` under the run filter, and gains a test that a missing run is an error.
- **Docs:** the routed-table lines in CLAUDE.md, `research/discharge_publish.md` and the roxygen. Dated records (`research/water_balance_method.md`, the planning archives) stay as written.

## Loading

fwapg's `load.sh` loads both runs. On an existing database, from an fwapg checkout on its `newgraph` branch:

```
psql $DATABASE_URL -v ON_ERROR_STOP=1 -f load/pcic_schema.sql -f load/pcic.sql
for run in pnwnamet_historical_1951-2012 pnwnamet_historical_1981-2010; do
  curl -sSf "https://fresh-bc.s3.us-west-2.amazonaws.com/fwapg/extras/pcic.discharge_monthly.$run.csv.gz" \
    | gunzip | psql $DATABASE_URL -v ON_ERROR_STOP=1 -v table=discharge_monthly -f load/pcic_run.sql
done
```

Load both: this issue reads 1951–2012, #103 reads 1981–2010. The loads use `psql`'s `\copy` and `COPY ... HEADER MATCH`, so the machine needs `psql` and PostgreSQL 15 or later.

## Done when

- `scripts/pcic_routed_compare.R`, rerun: scores and the `table:` fingerprint line unchanged; only the `routed:` line (table, fwapg commit) and the wet commit differ.
- `scripts/segment_output.R`, rerun on the full province run: every segment part byte-identical; the report differs only in those lines.
- `scripts/discharge_publish.R` BUILD: every value check passes and every part is byte-identical to the live build. Nothing is uploaded; the live manifest's provenance keeps naming the old table until #103 publishes.
- The vignette data scripts pass their guards against the new reports; their bundles' values are unchanged and their provenance names the new table and commit.
- Comment on NewGraphEnvironment/fwapg#31 that wet no longer reads the frozen tables.

Relates to #57, #58, #59, #99, #103, NewGraphEnvironment/fwapg#25, NewGraphEnvironment/fwapg#23, NewGraphEnvironment/fwapg#31.


## Errors Encountered

| Error | Resolution |
|-------|------------|
