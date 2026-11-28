# Published discharge: where it lives and how it is named

**Verified:** 2026-11-27 (re-read: the live manifest and `receipt.json`, anonymously; the build report and the daily report; the load, reader, layout and check claims against the code. Not re-read: the database and reader timings, the bucket's settings and the hydromosaic listing, which carry their own dates) · **Issues:** #7, #57, #59, #64, #70, #77, #88, #94, #99, #101, #102, #103, #108, #117, #160, #161, #163, #164, #165; fwapg#24, fwapg#25 · **Produced by:** `scripts/discharge_publish.R` (BUILD and PUBLISH) → `data/checks/discharge_publish_20260717.txt`; `scripts/segment_daily_output.R` → `data/checks/segment_daily_output_20260717.txt`; plan-mode discussion on #7 (`planning/archive/2026-10-issue-7-publish-discharge/findings.md`). Each earlier build's history is in its issue's archive README.

## What is published now

The live manifest is `https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`. It names the build of 2026-11-15 (read 2026-11-27): wet a0318b7, segment table 66cf795, daily table bc55d30, fit 20260717 of province run `768876badf` (scoring code `df3280b5c3ff52385f631bc09d3eaadd`), crate 0.16.0, written with arrow 25.0.1 and duckdb 1.5.6. The `inst/vignette-data/` bundles read this build.

It holds the `historical` scenario in 512 parts, 33.36 GB:

| dataset | parts | rows | GB |
|---|---|---|---|
| `segment_monthly` | 43 | 102,790,688 | 1.16 |
| `watershed_monthly` | 24 | 41,904,356 | 0.73 |
| `segment_daily` (one per watershed group and source) | 445 | 2,886,046,240 | 31.48 |

The largest part is `wet_balance` SETN in `segment_daily`, 373 MB. Beside the parts are `receipt.json` and the `fit/` files (247 of them, 1.44 GB). The parts' digest is `d554e3aad481d86bffa4baef687287ed`.

The sources, as the manifest's `sources` entries record them:

- **`pcic_routed`:** `pcic.discharge_monthly`, run PNWNAmet historical 1981–2010, built by fwapg at 5d50cc1 (40,524,444 rows over 3,377,037 segments, total 179,854,603.510890 m³/s). That is fwapg#24's rebuild, which places the Nechako Reservoir.
- **`wet_balance`:** the fit of release 20260717 on province run `768876badf`, with `cfu` actual evapotranspiration, which the BUILD refuses to change until the manifest's `wet_balance` description, the README and this file are rewritten for the new one (#85).

A BUILD took 2 h 59 min on the last build, comparing 15,040,448,264 values (2026-11-15). A PUBLISH uploads only the parts whose live ETag is not already their md5.

## Naming: one identifier per dataset

A dataset ID is `<variable>/<network>/<version>/<unit>_<timebase>`. The first is `discharge/fwa/v1/segment_monthly`. Every other name comes from the ID by one rule:

| where | name |
|---|---|
| S3 prefix | `s3://fresh-bc/discharge/fwa/v1/segment_monthly/` |
| manifest | `s3://fresh-bc/discharge/fwa/v1/manifest.json`, one per variable, network and version |
| `wet_catalog()` `dataset` column | `discharge/fwa/v1/segment_monthly` |
| crate schema | `crt_schema_conform(df, "nge", "discharge/fwa/v1/segment_monthly")`, at `inst/extdata/schemas/nge/discharge/fwa/v1/segment_monthly.yaml` |
| local build | `data/publish/discharge/fwa/v1/segment_monthly/` |
| Postgres | `discharge.fwa_v1_segment_monthly`: the variable becomes the schema, and the rest is joined with `_` |

Each level means one thing:

- **`<variable>`:** what is measured. `discharge` now. Later `water_temperature` and `oxygen_saturation`, which are hydromosaic's `water_temp` and `DO_sat`. Not `temperature`, because cd publishes air temperature.
- **`<network>`:** the hydrographic network the rows are keyed to. `fwa` (BC Freshwater Atlas: `linear_feature_id`, `watershed_feature_id`). A national product would be `chn` (NRCan's Canadian Hydrospatial Network). The network decides the ID columns and the coverage, so two networks can never share a dataset.
- **`<version>`:** the schema version. Data are rebuilt and overwritten in place within a version. It bumps only when a column is renamed or changes meaning, and then v2 lands beside v1.
  - **Decided for v2 (#71, 2026-10-14):** `pick` is renamed `is_default` when a v2 is cut for another reason, not on its own, since a rename alone would move the S3 prefix, the crate schema, the Postgres table and fresh's query. `is_default` follows fresh's `is_`/`has_` pattern; `q_pick` was set aside because under the product's `<quantity>_<unit>` pattern (`q_m3s`, `runoff_mm`) it reads as a flow.
- **`<unit>_<timebase>`:** the feature a row describes and the time step of its values.
  - `segment_monthly`: one row per FWA segment and calendar month, a mean over a period, with month 0 the annual.
  - `watershed_monthly`: the same per fundamental watershed.
  - Seasons are averages of months.
  - A daily or per-year product gets its own dataset (`segment_daily`; later `segment_yearly`).
  - **`segment_daily` (decided in #70, published since #99):** one row per FWA segment, source and day of a 365-day common year (`doy` 1–365, 29 February folded into 28, the `doy` convention of `wet_flow_window()`), the mean flow of that day over the period, in `q_m3s` and `runoff_mm` (mm/day) as the monthly rows; no annual row. For the balance the days are the published months laid out with the within-month shape `scripts/wb_shape_daily.R` ships (`q[d] = Q[m] · n[m] · w[d]`), so a calendar month's days average to its `segment_monthly` row, and its daily depths sum to the monthly depth except in February (28 of the month's 28.25 days). For routed PCIC each day is routed from fwapg#25's sub-basin climatology (`pcic.subbasin_daily`, `cdo ydaymean`, 366 bins folded to 365 by `n_days` before routing) and the segment's weights (`pcic.segment_weights`), then clamped at zero and rounded to 5 decimals as fwapg makes its months (`wet:::wet_routed_days()`), so a month's days need not average to its published month (see "Routed days, against fwapg's months" below). Weeks (fixed day-of-year bins, fwapg#25) and month-day windows are derived on read (`wet_flow_window()`), never stored. Built by `scripts/segment_daily_output.R`; schema crate#33.

## Layout: Hive keys, then part files

```
discharge/fwa/v1/segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-100.parquet
discharge/fwa/v1/segment_monthly/scenario=historical/forcing=climr/source=wet_balance/part-100.parquet
discharge/fwa/v1/segment_monthly/scenario=ssp245/forcing=MPI-ESM1-2-HR/source=pcic_routed/part-100.parquet   (later)
```

| key | meaning | values |
|---|---|---|
| `scenario` | the emissions pathway | `historical`, `ssp245`, `ssp585` |
| `forcing` | the climate data that drove the estimate | `PNWNAmet` (PCIC's historical run); a GCM spelled as PCIC spells it (`MPI-ESM1-2-HR`); `climr` (the balance's 1981–2010 normals); `ensemble` (an ensemble mean) |
| `source` | who produced the estimate, and by what method: `<group>_<method>` | `pcic_routed` (PCIC's Raven routing over VIC-GL, placed on the FWA by fwapg#6), `wet_balance` (wet's open water balance), later `poisson_<method>` (Poisson Consulting) |

- **Why two keys, `scenario` and `forcing`.** PCIC's projections are 9 GCMs × 2 SSPs. With one key the GCM would have to be parsed out of a string, and GCM names contain hyphens. As two keys they match hydromosaic's own `(scenario, model)`.
- **Why `forcing` and not `model`.** "Model" would be confused with the hydrology model, which `source` already names.
- **`climr` names the balance's climate input**, not every input: its actual evapotranspiration is `cfu` (CGIAR floored by Fu-Budyko), chosen by #15 and re-decided on the shipped release by #81. The manifest's source description gives the whole recipe.
- **`period` is a column, not a key.** In `historical`, routed and balance rows are both 1981–2010. A projection partition will hold several periods.
- **Sources share one dataset**, so one read returns them side by side for the same segment, and reading one directory returns one source. The partition keys live in the path and are dropped from the file columns.
- **In v1, `pick` is unique per (scenario, feature, month).** `wet_db_load()` refuses a load that breaks this. A projection scenario holding several periods will need the rule restated (per period); that is undecided until one is built.
- **`pick` is a relation across sources.** It is TRUE on the default source for a segment (`wet_source_pick()`). It is computed across every source of a scenario, so it spans `forcing` in `historical`. A rebuild of a scenario therefore rewrites every source's part files, and a new source (Poisson) means a rebuild.
- **`part-<code>.parquet`** holds one FWA top-level drainage in a monthly dataset: the first field of `fwa_watershed_code`. For example 100 is the Fraser, 200 the Mackenzie (Peace and Liard), 300 the Columbia, 900–960 coastal, and 999 spans 246 watershed groups. The manifest labels each code. Readers go through the manifest, not file names.
- **`watershed_group_code` is a column, and rows are sorted by it**, with row groups of about a watershed group's size. A read filtered to one group then skips the other row groups on their statistics, without a join to the FWA.
- **A daily part holds one watershed group** (`part-<GROUP>.parquet`, decided at #99's plan gate, 2026-10-20). At about 28 times the monthly rows a part per drainage would reach about 6 GB (the balance's part-200), past S3's 5 GB single PUT, which is what lets each part's ETag be its md5. A part's rows are sorted by segment and day, in row groups of 2,048 segments' days, so a read of a few segments skips most of its group's part. `wet_segment_daily()` needs `groups` to read the parts and opens only those groups'; the manifest labels each daily code with its group's name.

## Where: `s3://fresh-bc/`, not a new bucket

- **fresh-bc holds freshwater data for BC.** The bucket's own documentation sends *published* datasets to `stac-*-bc` buckets, but those are STAC catalogues, and this is not one.
- **Variable-first prefix.** The same doc scopes fresh-bc prefixes by producer (`bcfishpass/`, `fwapg/`) so they do not become dumping grounds. `discharge/` is a variable instead, chosen so that discharge from several producers sits in one place, with the producer in `source`. The exception is recorded in the bucket's documentation, where the policy change that opens the prefix is also tracked.
- **Access.** Anonymous `s3:GetObject` on `discharge/*` only, and no `s3:ListBucket`. Readers therefore use `manifest.json`, which names every key, rather than globbing.
- **The manifest is rewritten whole by each publish**, from one local tree, so that tree must hold every scenario meant to stay published. Its `sources` entries carry what each source's rows were built from, and each dataset names its crate schema at a crate release.
- **Overwrites.** Bucket versioning is suspended, so an overwrite is final and a republish replaces bytes rather than adding storage (measured 2026-10-24: under `discharge/fwa/v1/`, one current version per key, no noncurrent copies or delete markers). A bucket lifecycle rule moves objects to Standard-IA after 30 days, whose 30-day minimum bills an IA part overwritten early for its remaining days. That is acceptable because every file is rebuilt from code and inputs, and the manifest records the wet commit, fit release and routed-table fingerprint that built it.

## Beside the parts: the receipt and the fit

A build lists two more kinds of file beside its parts, both written by the BUILD and named in `manifest.json` with their bytes and md5, so PUBLISH uploads and verifies them as it does the parts:

- **`receipt.json`**, the build's provenance record in crate's shared shape (`crate::crt_receipt_write()`, crate#43): the output (`discharge/fwa/v1`), the recipe (the full wet commit; the settings and inputs `inst/receipt/discharge_fwa_v1.yaml` declares: the crate release whose schemas the parts conform to, the province run, the fit as `<release>/<scoring md5>`, the HYDAT release, routed PCIC's monthly and daily fingerprints and the fwapg commit that built them) and its `recipe_id`, each file's bytes and SHA-256, row counts per dataset, and the context (time, toolchain; no host, since it is published). The manifest's `receipt` entry carries its `recipe_id`, and `wet_db_load()` records that id beside each part it loads. Compare two builds' receipts with `crate::crt_receipt_compare()`: identical when recipe and every file agree. No table is fingerprinted (the daily dataset's 2.9 billion rows are past crate#50's limit) and no tolerance is declared, because a rerun on the same inputs and software writes the same bytes (#76). The receipt sits **beside** the manifest, not in its place: the manifest stays the catalog at `manifest_version = 1`, so a wet installed before it still reads it, and its md5s stay the S3 ETags the verification checks; a receipt holds SHA-256. The receipt's bytes change with every BUILD (its time), so no PUBLISH skips it, and it is served `no-cache`. The live one has `recipe_id` `68ae10bc2e0537045c4749269559b5619e601045f2c17114c269efd40787f58e`; crate hashed the 759 files it lists in 94 s.
- **`fit/`**: the shipped fit (`fit/fits.rds`) and each watershed group's sample of the province run's layers (`fit/sample/part-<GROUP>.parquet`, all 246 groups, each read back `identical()` to the rds it was written from), with the fit's release, province run, scoring code, a description of the data the samples derive from and a citation in the manifest's `fit` entry. `scripts/segment_group.R` rebuilds one group's balance rows and pick from them on any machine with fwapg (`research/segment_group.md`).

`wet_catalog()` returns both as attributes (`receipt`, `fit`), `NULL` for a build published without them. The parts' digest (`tree parts md5`, `wet:::wet_catalog_digest()`) covers the parts alone, so the vignette data guards and the departure reports that hold it do not move with these files. The report gives the fit and receipt their own lines (`tree fit and receipt md5`, the receipt's `recipe_id`), which PUBLISH requires of a committed report as it requires the parts' digest.

## How a build is checked

The BUILD reads every written part back and compares it, value by value, with what it was built from (`wet_values_compare()`). It reports compared, differing and largest difference for each check, and fails on any difference. Row and `pick` counts alone would not see a value that moved. Every published flow (`q_m3s`) is checked against its source. Of the other columns, the segment parts' `runoff_mm`, `coverage` and `pick` are checked against the segment table; `period`, `watershed_group_code` (filled from fwapg and checked only for NA), and the watershed parts' `runoff_mm`, `coverage` and `bc_fraction`, are not checked value by value.

The live build's checks (`data/checks/discharge_publish_20260717.txt`):

| check | compared | differing | largest difference |
|---|---|---|---|
| routed months 1–12 = fwapg's `pcic.discharge_monthly` (run PNWNAmet historical 1981–2010) | 40,524,444 | 0 | 0 |
| routed month 0 = mean of its 12 months | 3,377,037 | 0 | 9.1e-13 m³/s |
| balance (13 months) = the fit's `output/` through `fwa_streams_watersheds_lut` | 58,889,207 | 0 | 0 |
| segment parts = the segment table, on each of `q_m3s`, `runoff_mm`, `coverage`, `pick` | 102,790,688 | 0 | 0 |
| watershed parts = the fit's `output/` | 41,904,356 | 0 | 0 |
| daily routed days = routed again from `pcic.subbasin_daily` and `pcic.segment_weights` (one sum per distinct upstream set, not the build's path), after rounding | 1,232,618,505 | 0 | 0 |
| daily balance = the fit's `output/` months laid on `shape_daily.rds` through the lut | 1,653,427,735 | 0 | 0 |
| daily balance, plain mean of each month's days = the `segment_monthly` parts | 54,359,268 | 0 | 3.6e-12 m³/s |
| daily parts = the daily table, on each of `q_m3s`, `runoff_mm`, `coverage`, `pick` | 2,886,046,240 | 0 | 0 |

The routed months' total, rounded to 1e-6 m³/s per value, equals the table's fingerprint (179,854,603.510890 m³/s). Values copied from a double are compared exactly. Only the two means of twelve months meet within a tolerance (relative 1e-9), because R's `mean()` and a sum over 12 round differently in the last bits. The lut join re-does the segment table's join, so it catches indexing errors, not errors in the lut itself. No routed day sat one rounding step from its recomputation at a tie.

The segment-discharge article reads its routed values at the calibration gauges, every segment's `pick` for its map, and the Bulkley segments' months and days from the published parts, in three bundles (`segment_values.rds`, `segment_map.rds`, `monthly_values.rds`). The three scripts that build them (`data-raw/segment_vignette_data.R`, `segment_vignette_map.R`, `monthly_vignette_data.R`) refuse unless the committed publish report names the live build with no check failed (`vd_published()`). The report records `tree parts md5`, the digest of its own tree (`wet:::wet_catalog_digest()`: md5 of the sorted `<key> <md5>` lines), and its live-build line ends in the live parts' digest; both must be the live manifest's. PUBLISH uploads a tree only under a committed report naming that tree's digest, and after the upload writes the live-build line from the verified manifest (`publish_report_live()`), leaving the report for a commit, so no BUILD follows an upload. A tree rebuilt at the report's commit from other inputs can therefore neither be uploaded nor read under the older report. `segment_vignette_data.R` also refuses unless each gauge's routed value equals fwapg's mean of twelve months, and takes the segment counts from the tracked segment report, which must be identical to its copy at the commit the report's build ran at (the build reads only committed reports, so that is the report it checked). The live manifest's `segment_commit` can be earlier, because a rerun of `segment_output.R` whose parts all match the live ones is not republished.

## Routed days, against fwapg's months

Routed PCIC's days are made in wet, not read from fwapg, because fwapg keeps per-segment months and weeks but only per-sub-basin days (fwapg#25). `scripts/segment_daily_output.R` reads the run's `pcic.subbasin_daily` (13,961,436 rows and 38,146 sub-basins; 366 day-of-year bins) and `pcic.segment_weights` (3,377,037 rows) once, each held to the run's fingerprint in `pcic.runs`. It folds 29 February into 28 February by the bins' `n_days` and routes each day as fwapg routes a month, `max(Σ q_acc[upstream] + q_local · share, 0)`, rounded to 5 decimals half away from zero as Postgres rounds the numeric (`wet:::wet_routed_days()`). R's `round()` on the double can land one step away at a tie in the 15-significant-digit decimal, so `wet_routed_round()` decides values near a tie from that decimal string (probed in #99).

- **The days reproduce fwapg's months.** The `n_days`-weighted mean of a month's unclamped days, clamped and rounded, equals `pcic.discharge_monthly` on all 40,524,444 segment-months, with no difference even at a rounding tie (the script refuses any difference but one 1e-5 step at a tie, which it counts). The same held for `pcic.discharge_weekly` in five groups on an earlier fwapg build (#99's probe, not re-run).
- **The clamp, per day.** 14,577,433 of 1,232,618,505 routed segment-days are clamped at zero (1.183 %), and 53,610 of 99,306,645 mid-network, by fwapg's `qa_report_clamped.sql` definition (0.054 %). The worst day mid-network is 16 May (944 segments). The rule set before measuring (#99) was to publish whatever the daily share was and to state it as a weakness above 0.1 % mid-network; it is under. fwapg's own month and week clamp shares were last measured on the earlier build (0.978 % and 0.977 % of months and weeks, 0.049 % and 0.048 % mid-network, against 1.092 % and 0.050 % for wet's days then), and are not re-measured on 5d50cc1.
- **A month's published days need not average to its published month.** The days are clamped one by one, so where a clamp bites their mean is at or above the clamped month. A reader's plain mean of a month's days also counts the folded 28 February as one day of 28, where the month counts it by how often the period holds 28 and 29 February (37 of February's 847 day-years in 1981–2010). Of 40,524,444 segment-months, 1,908,991 (4.711 %) have a plain day mean more than 1e-5 m³/s from the published month, 1,036,583 of them in February. The largest is 197.24528 m³/s above the month, the largest below 0.12366 m³/s. Outside February the period holds every day equally often, so a plain mean there can sit below the month only by rounding (at most 1e-5).
- **The balance's days do average to its months.** They are the published months laid on the fit's daily shape, so over 38,680,224 watershed-months the day mean meets the month within 1.2e-15 relative, and the daily depths sum to the monthly depth (28/28.25 of it in February) within 1.3e-15.

## Why not STAC

#1's D4 proposed a STAC Collection with the table extension. It was a proposal and never approved. For a province-wide table, STAC's spatial and temporal search does nothing: every item's footprint would be all of BC. The two jobs STAC was doing here are done by `manifest.json`:

- naming every key, so readers need no listing;
- carrying provenance: checksum, rows, build commit.

A STAC catalogue can still be generated from the manifest later if discovery through a STAC API is wanted.

## Postgres

`wet_db_load()` writes one scenario of a dataset into the table the dataset ID names (`discharge.fwa_v1_segment_monthly`). The segment table holds all rows (both sources, 13 months) with `scenario`, `forcing`, `source` and `pick` as columns. fresh joins:

```sql
select linear_feature_id, q_m3s as mad_m3s
from discharge.fwa_v1_segment_monthly
where scenario = 'historical' and month = 0 and pick
```

In the live build that subquery selects 4,532,843 rows (3,213,337 routed, 1,319,506 balance; the build report's count over the local tree).

`wet_segment_monthly()` reads the same table per segment and source, keyed on `linear_feature_id`; without a database it reads the parts through duckdb instead. It warns on a table whose comment records a subset load, and stops on a scenario or source the table does not hold. Over HTTPS (2026-10-14), one segment took 3.3 s with its watershed group named and 27 s without: the parts are sorted by group, and a random ID fell inside about 131 of the 507 row groups' ID ranges, so a read of many IDs with no group reads nearly the whole tree.

**Which parts a table holds.** Each load also writes one row per loaded part to `discharge.wet_load` (in the dataset's schema): `dataset, scenario, key, md5, rows, subset, manifest, built, wet_commit, recipe_id, loaded_at`, primary key `(dataset, scenario, key)`, the dataset and scenario's rows replaced in the same transaction as the data and written before its checks, so a refused load leaves them as they were. The table comment is unchanged word for word, because downstream code parses it, but it names only the scenario loaded last; the load table keeps every dataset and scenario's load, so a consumer reading only the historical rows can key on the historical load. A load of the annual picks (`months = 0, pick_only = TRUE`) from the live build into a scratch database took 102 s for 43 parts and 4,532,843 rows, and its `wet_load` rows carried the catalog's keys and md5s, the manifest, build time, wet commit, the receipt's `recipe_id` and the subset (2026-11-15).

**Cost of a load** (earlier builds of the same two tables, not re-timed). A whole load into tables dropped first took 23.9 min for the segments (20 GB with indexes) and 10.7 min for the watersheds (8.5 GB), on 2026-10-13. The annual-default query took 6.7 s for the whole province and 0.7 s joined to one watershed group, through a partial index `(scenario, linear_feature_id) WHERE month = 0 AND pick`; without it, 197 s (#7). `wet_db_load()` creates that index only when it creates the table. Two later reloads into the existing tables took about 2 and then 4 times as long as that first load (#77, #103). After the first, a plain `VACUUM ANALYZE` left the tables at 39 GB and 17 GB: it marks the deleted rows' space for reuse by a later load but does not return it, and a reload cannot reuse the space of rows it deletes itself. `VACUUM FULL`, or dropping the tables first, returns it.

## Evidence

- **hydromosaic API** (`https://beehive.pacificclimate.org/hydromosaic/`, 2026-10-12; not re-read, since PCIC's robots.txt disallows `/hydromosaic`, `research/pcic_hydrology.md`):
  - `/variables` lists `streamflow`, `water_temp` and `DO_sat`.
  - `/outlets` lists 68,716 outlets.
  - `/outlets/4008184/timeseries` lists 19 series per variable: one `historical` (PNWNAmet, 1950–2012) and 9 GCMs × `historical, ssp245` and `historical, ssp585` (1950–2100). The GCMs are CNRM-ESM2-1, FGOALS-g3, IPSL-CM6A-LR, MIROC-ES2L, MPI-ESM1-2-HR, MRI-ESM2-0, NorESM2-LM, TaiESM1 and UKESM1-0-LL.
- **fresh-bc policy** (`aws s3api get-bucket-policy`, 2026-10-12): anonymous GetObject on `bcfishpass/*`, `bcgw/*` and `fwapg/extras/*`. `discharge/*` was added on 2026-10-13 (GetObject only, no ListBucket); an unsigned GET of a probe returned 200 (#7 comment). Default encryption is SSE-S3 (`get-bucket-encryption`: AES256, 2026-10-12), so a single-PUT part's ETag is its md5, which `wet_catalog_verify()` relies on.
- **The live build** (2026-11-27, unsigned): the manifest's parts digest equals the report's, and `receipt.json` answers with the 153,211 bytes and md5 the manifest names.
- **Drainage codes:** `split_part(fwa_watershed_code, '-', 1)` over `whse_basemapping.fwa_stream_networks_sp` in the local fwapg.
