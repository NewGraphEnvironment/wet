# Findings — Publish per-segment discharge (#7)

## Issue context (as filed, before this branch edited it)

Issue #1 item 6. Publish the per-segment table and get it into fwapg so fresh can join it (fresh#114).

## Proposed (#1 decision D4)

- **Format:** Hive-partitioned parquet. Path `s3://<bucket>/wet/v<major>/unit=segment/scenario=<run>/period=<yyyy-yyyy>/part-0.parquet`; columns `linear_feature_id`, `month` (0 = annual), `runoff_mm`, `q_m3s`, `coverage`, `source` (`pcic_routed` or `wet_balance`), `period` and `pick` (#57). Both sources are stored where both have a value, and `pick` is TRUE on the default: routed PCIC unless its annual flow is under 0.2 × the balance's, then the balance, and only on a segment on its watershed's own line (side channels and connectors keep routed; `wet_source_pick()`). Until NewGraphEnvironment/fwapg#25 builds routed flow over 1981–2010, routed rows are `period = 1951-2012` and the balance's `1981-2010`, so the default slice spans two periods: partition on scenario only, or keep `period` a column. `scripts/segment_output.R` writes this table per basin locally (`data/wb/<key>/fit_<release>/segment/`). Also publish a per-watershed table (`unit=watershed`).
- **STAC:** one Collection (unlike `cd`'s inline-items Catalog) with the table and version extensions, and one Item per scenario × period.
- **`wet_db_load()`:** loads one slice into Postgres (for example `wet.discharge_monthly`). `fresh::frs_col_join(from = "(select linear_feature_id, q_m3s as mad_m3s from wet.discharge_monthly where month = 0 and scenario = 'PNWNAmet')")` then works with no change to fresh, given `AND pick` in the subquery.
- **Consumer:** a `wet_catalog()` reader, like `cd_catalog()`.

## Blockers

- **PCIC terms of use:** "AS IS", with no named open licence. Publishing derived per-segment values, cited, is not a concern (decided 2026-10-07).
- **Bucket:** either a prefix under `s3://fresh-bc` or a dedicated bucket. As of 2026-10-11 fresh-bc's policy grants public `s3:GetObject` on `bcfishpass/*`, `bcgw/*` and `fwapg/extras/*` (fwapg#9's published tables), so a `wet/*` prefix needs one more resource line. `GetObject` alone serves exact keys only: a Hive glob read (`arrow::open_dataset()`, duckdb `read_parquet('…/*/…')`) needs `s3:ListBucket` on the bucket ARN, or the catalogue must name every key (a manifest, or the STAC items), which `wet_catalog()` should then read instead of listing.

Relates to #1, fresh#114.

## Plan-mode decisions (2026-10-12)

- **STAC dropped.** It came from #1's D4, which was proposed and never approved. For one province-wide table its spatial and temporal search buys nothing; a manifest names every key (so no ListBucket is needed) and carries provenance.
- **Bucket: `s3://fresh-bc/`**, which holds freshwater data for BC. The bucket's documentation sends published datasets to `stac-*-bc` buckets, but that rule was about STAC catalogues. It also says prefixes are scoped by source, never by kind; `discharge/` is a deliberate exception to amend there.
- **Live policy, read 2026-10-12:** anonymous `s3:GetObject` on `bcfishpass/*`, `bcgw/*` and `fwapg/extras/*` only. No ListBucket. Bucket versioning is off.
- **Overwrites are fine.** One live copy per schema version; `v1` bumps only on a breaking column change.
- **Variable-first, network-keyed:** `discharge/fwa/v1/<unit>_<timebase>`. CHN (NRCan's Canadian Hydrospatial Network) would be `discharge/chn/v1/…`.
- **Hive keys `scenario` / `forcing` / `source`.** Poisson Consulting estimates come in as `source=poisson_<method>`.
- **Monthly** is the finest step both sources share (fwapg's routed table and the balance output); seasons derive from it.
- **Postgres:** `discharge.fwa_v1_segment_monthly` holds all rows plus a `pick` column (about 100M rows). fresh filters `month = 0 AND pick`.
- **crate:** it had no discharge schemas. Registry `file_name` and `schema_yaml` are free strings, so the dataset ID can be the key.

## hydromosaic API (probed 2026-10-12)

`https://beehive.pacificclimate.org/hydromosaic/` serves `/variables`, `/outlets` (68,716) and per-outlet `/timeseries`.
- Variables: `streamflow` (m**3 s**-1), `water_temp` (degC), `DO_sat` (mg/L).
- At outlet 4008184, per variable: 1 `historical` series (PNWNAmet, 1950-01-01 to 2012-12-31, 23,011 days) plus 9 GCMs × `historical, ssp245` and `historical, ssp585` (1950–2100, 55,152 days).
- GCMs: CNRM-ESM2-1, FGOALS-g3, IPSL-CM6A-LR, MIROC-ES2L, MPI-ESM1-2-HR, MRI-ESM2-0, NorESM2-LM, TaiESM1, UKESM1-0-LL.
- That is the case the `forcing` key is for.

## FWA top-level drainage codes (local fwapg, 2026-10-12)

The first field of `fwa_watershed_code`:

| code | drainage |
|---|---|
| 100 | Fraser |
| 200 | Mackenzie (Peace, Liard) |
| 300 | Columbia |
| 400 | Skeena |
| 500 | Nass |
| 600 | Stikine |
| 700 | Taku |
| 800 | Yukon headwaters |
| 900–960 | coastal |
| 970 | Skagit/Chilliwack |
| 990 | Alsek |
| 999 | spans 246 groups |

These are the `part-<code>` chunks.

## Publish build notes (2026-10-12)

- arrow's `write_parquet()` writes one row group under 2.5e8 cells, so nothing would prune; `ParquetFileWriter` with one `WriteTable()` per watershed group gives one row group per group (review B2). Smoke test: 4 groups in, 4 row groups out, and a read for one group opens 1.
- `count(*)` arrives from RPostgres as integer64, and `order(-n)` does not sort it: drainage labels came out alphabetical ("Annacis Channel" for 100) until cast to `::int`.
- The segment code is unchanged between 653fc13 (which built the province run's segment table, on the full-run machine) and this branch, so the table publishes without a rebuild.

## Postgres load on the full-run machine (2026-10-12, 14:41–15:17 UTC)

`wet_db_load()` of the 7e738e1 build into the local fwapg:
- **`segment_monthly`:** 102,790,688 rows in 23.7 min.
- **`watershed_monthly`:** 41,904,356 rows in 11.3 min. That is 42,190,889 less 22,041 NA-flow watersheds × 13.
- **Sizes:** segment table 19 GB (11 GB heap); watershed 8.5 GB.
- **fresh's subquery:** 3,152,838 routed + 1,380,005 balance = 4,532,843 rows, one per segment.
  - Without an index it took 197 s, a full scan.
  - A partial index `(scenario, linear_feature_id) WHERE month = 0 AND pick` took 0.5 min to build. After it the subquery takes 6.7 s, and a one-group join like fresh's (BULK, 30,037 rows) 0.7 s.
  - `wet_db_load()` now creates that index.
- A separate long query (`fwapg.pcic_voters`) ran on the same database during the load, so the times are an upper bound.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| duckdb `read_parquet()` added `scenario`/`forcing`/`source` from a Hive-shaped local path, so the load named them twice | `hive_partitioning = false`; the keys come from the catalog |
| `modifyList()` merged a shorter `sources` list into the default in a test | replace arguments, do not merge |
