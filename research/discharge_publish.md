# Published discharge: where it lives and how it is named

**Verified:** 2026-10-24 (a BUILD under province run `92b893c4da`, not uploaded, #76); 2026-10-20 (`segment_daily` built and published, #99); 2026-10-19 (the donor gauges' monthly shares published, #102; the routed run moved to 1981–2010, published and reloaded under "Postgres", #103); 2026-10-18 (the routed table read, #101); 2026-10-17 (`segment_daily`'s stored form, #70); 2026-10-16 (the segment report the vignette data take, #93); 2026-10-15 (the status and the reload under "Postgres"; the rest 2026-10-13, the reader's parquet timings 2026-10-14) · **Issues:** #7 (decided, then published), #99 (`segment_daily` published), #64 (value checks), #77 (the snow-informed monthly balance published), #103 (routed PCIC over 1981–2010 published), #102 (the donor monthly shares published), #93 (vignette data after an identical rerun), #59 (the per-segment reader), #1 (D4, superseded), #57 (the table), #70 (the daily shape; `segment_daily` decided, not built), fwapg#25 (projections) · **Produced by:** plan-mode discussion on #7, recorded in `planning/archive/2026-10-issue-7-*/findings.md`, the probes listed under "Evidence", and `scripts/discharge_publish.R` (BUILD) for the value checks.

**Status:** published at `https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`, first on 2026-10-13 (wet 7c62b9e), replaced on 2026-10-15 by the build carrying the snow-informed monthly shares (#16, #77; that upload took about 4 min and deleted no stale keys), on 2026-10-19 by the build reading routed PCIC's 1981–2010 run (#103; about 5 min), the same day by the build carrying the donor gauges' monthly shares (#102), and on 2026-10-20 by the build adding `segment_daily` (#99; under 70 min from the BUILD's end to the live manifest naming it, nearly all of it the 445 new daily parts, the 67 monthly parts being already live with the same bytes). The `historical` scenario, built at wet 77585a8 (segment table d20a624, daily table 6bb261e, fit 20260717, province run e675918817, crate 0.8.0), is 512 parts and 33.23 GB: 43 `segment_monthly` (102,790,688 rows, 1.15 GB), 24 `watershed_monthly` (41,904,356 rows, 0.73 GB) and 445 `segment_daily`, one per watershed group and source (2,886,046,240 rows, 31.35 GB; the largest, `wet_balance` SETN, 373 MB). The monthly parts are byte-identical to #102's build 8ca2dee. The build report is `data/checks/discharge_publish_20260717.txt`: the BUILD rerun after the upload, at wet 608147e, with every check passing (15,040,448,264 values compared, 0 differing) and 512 of 512 parts byte-identical to the live build. Before it, #102's build at wet 8ca2dee changed the balance's months 1–12 only (47 balance and watershed parts; the 20 routed parts stayed byte-identical), and #103's at wet 94deeb5 had replaced acb820f's routed parts (36,700,180 of 40,524,444 routed monthly values changed, 4,733 picks moved). The reports before those were #101's rebuild at wet 1d0faf8 (58 of 67 identical, never uploaded) and #91's at wet 71af15a (67 of 67). Since #76 the tracked report is instead the BUILD at wet b4bbc50 under province run `92b893c4da`, not yet uploaded: every check passes (0 values differing) and 6 of 512 parts are byte-identical to the live build. The other 506 differ only in the balance's last bits (at most 7.2e-11 relative), the routed parts too, because they carry the balance's `runoff_mm`. Until that upload and a BUILD rerun after it, the vignette data scripts refuse, since the tracked report no longer names the live build with every part identical.

## The rule: one identifier per dataset

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
  - Monthly is the finest step both sources share; seasons are averages of months.
  - A daily or per-year product gets its own dataset (`segment_daily`, `segment_yearly`).
  - **`segment_daily`, decided in #70 (2026-10-17), built and published in #99 (2026-10-20):** one row per FWA segment, source and day of a 365-day common year (`doy` 1–365, 29 February folded into 28, the `doy` convention of `wet_flow_window()`), the mean flow of that day over the period, in `q_m3s` and `runoff_mm` (mm/day) as the monthly rows; no annual row. For the balance the days are the published months laid out with the within-month shape `scripts/wb_shape_daily.R` ships (`q[d] = Q[m] · n[m] · w[d]`), so a calendar month's days average to its `segment_monthly` row, and its daily depths sum to the monthly depth except in February (28 of the month's 28.25 days). For routed PCIC each day is routed from fwapg#25's sub-basin climatology (`pcic.subbasin_daily`, `cdo ydaymean`, 366 bins folded to 365 by `n_days` before routing) and the segment's weights (`pcic.segment_weights`), then clamped at zero and rounded to 5 decimals as fwapg makes its months (`wet:::wet_routed_days()`), so a month's days need not average to its published month (see "Routed days, against fwapg's months" below). Weeks (fixed day-of-year bins, fwapg#25) and month-day windows are derived on read (`wet_flow_window()`), never stored. Built by `scripts/segment_daily_output.R`; schema crate#33.

## Inside a dataset: Hive keys, then part files

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
- **`period` is a column, not a key.** In `historical`, routed and balance rows are both 1981–2010 since #103; routed rows were 1951–2012 until then. A projection partition will hold several periods.
- **Sources share one dataset**, so one read returns them side by side for the same segment, and reading one directory returns one source. The partition keys live in the path and are dropped from the file columns.
- **In v1, `pick` is unique per (scenario, feature, month).** `wet_db_load()` refuses a load that breaks this. A projection scenario holding several periods will need the rule restated (per period); that is undecided until one is built.
- **`pick` is a relation across sources.** It is TRUE on the default source for a segment (`wet_source_pick()`, #57). It is computed across every source of a scenario, so it spans `forcing` in `historical`. A rebuild of a scenario therefore rewrites every source's part files, and a new source (Poisson) means a rebuild.
- **`part-<code>.parquet`** holds one FWA top-level drainage in a monthly dataset: the first field of `fwa_watershed_code`. For example 100 is the Fraser, 200 the Mackenzie (Peace and Liard), 300 the Columbia, 900–960 coastal, and 999 spans 246 watershed groups. The manifest labels each code. Readers go through the manifest, not file names.
- **`watershed_group_code` is a column, and rows are sorted by it**, with row groups of about a watershed group's size. A read filtered to one group then skips the other row groups on their statistics, without a join to the FWA.
- **A daily part holds one watershed group** (`part-<GROUP>.parquet`, decided at #99's plan gate, 2026-10-20). At about 28 times the monthly rows a part per drainage would reach about 6 GB (the balance's part-200), past S3's 5 GB single PUT, which is what lets each part's ETag be its md5. A part's rows are sorted by segment and day, in row groups of 2,048 segments' days, so a read of a few segments skips most of its group's part. `wet_segment_daily()` needs `groups` to read the parts and opens only those groups'; the manifest labels each daily code with its group's name.

## Where: `s3://fresh-bc/`, not a new bucket

- **fresh-bc holds freshwater data for BC.** The bucket's own documentation sends *published* datasets to `stac-*-bc` buckets, but those are STAC catalogues, and this is not one.
- **Variable-first prefix.** The same doc scopes fresh-bc prefixes by producer (`bcfishpass/`, `fwapg/`) so they do not become dumping grounds. `discharge/` is a variable instead, chosen so that discharge from several producers sits in one place, with the producer in `source`. The exception is recorded in the bucket's documentation, where the policy change that opens the prefix is also tracked.
- **Access.** Anonymous `s3:GetObject` on `discharge/*` only, and no `s3:ListBucket`. Readers therefore use `manifest.json`, which names every key, rather than globbing.
- **The manifest is rewritten whole by each publish**, from one local tree, so that tree must hold every scenario meant to stay published. Its `sources` entries carry what each source's rows were built from (the routed table's fingerprint and fwapg commit; the balance's fit release and province run), and each dataset names its crate schema at a crate release. Since #103 the live manifest names `pcic.discharge_monthly`, run PNWNAmet historical 1981–2010 (fwapg 7c30f58, fingerprint 178918222.786650). The acb820f manifest before it named `whse_basemapping.fwa_stream_networks_discharge_monthly` at fwapg 341b078, the 1951–2012 run. #101 had moved the read to the same rows in `pcic.discharge_monthly`, equal value for value, and to a routed month 0 summed in month order (the old parts had summed in the frozen table's storage order, a difference of at most 1.81 units in the last place); that rebuild was never uploaded.
- **Overwrites.** Bucket versioning is off, so an overwrite is final. That is acceptable because every file is rebuilt from code and inputs, and the manifest records the wet commit, fit release and routed-table fingerprint that built it.

## Every published flow is checked against its source (#64)

The build's original cross-checks compared row and `pick` counts only, which cannot see a value that moved. Since #64 the build reads every written part back and compares it, value by value, with what it was built from (`wet_values_compare()`). It reports compared, differing and largest difference for each check, and fails on any difference. Every published flow (`q_m3s`) is checked against its source. Of the other columns, the segment parts' `runoff_mm`, `coverage` and `pick` are checked against the segment table, and `period`, `watershed_group_code` (filled from fwapg and checked only for NA), and the watershed parts' `runoff_mm`, `coverage` and `bc_fraction`, are not checked value by value:

| check | compared | differing | largest difference |
|---|---|---|---|
| routed months 1–12 = fwapg's routed table (then `fwa_stream_networks_discharge_monthly`; since #101 `pcic.discharge_monthly`, and since #103 its run PNWNAmet historical 1981–2010) | 40,524,444 | 0 | 0 |
| routed month 0 = mean of its 12 months | 3,377,037 | 0 | 9.1e-13 m³/s |
| balance (13 months) = the fit's `output/` through `fwa_streams_watersheds_lut` | 58,889,207 | 0 | 0 |
| segment parts = the #57 segment table, on each of `q_m3s`, `runoff_mm`, `coverage`, `pick` | 102,790,688 | 0 | 0 |
| watershed parts = the fit's `output/` | 41,904,356 | 0 | 0 |
| daily routed days = routed again from `pcic.subbasin_daily` and `pcic.segment_weights` (one sum per distinct upstream set, not the build's path), after rounding | 1,232,618,505 | 0 | 0 |
| daily balance = the fit's `output/` months laid on `shape_daily.rds` through the lut | 1,653,427,735 | 0 | 0 |
| daily balance, plain mean of each month's days = the `segment_monthly` parts | 54,359,268 | 0 | 3.6e-12 m³/s |
| daily parts = the #99 daily table, on each of `q_m3s`, `runoff_mm`, `coverage`, `pick` | 2,886,046,240 | 0 | 0 |

The routed months' total, rounded to 1e-6 m³/s per value, equals the table's fingerprint (178,918,222.786650 m³/s since #103; 178,035,348.248310 on the 1951–2012 run). Values copied from a double are compared exactly. Only the two means of twelve months meet within a tolerance (relative 1e-9), because R's `mean()` and a sum over 12 round differently in the last bits. The lut join re-does the segment table's join, so it catches indexing errors, not errors in the lut itself. Measured on m4 at wet 032242f on 2026-10-13: the build took about 8 min with the checks, against about 5 without; with `segment_daily` (wet 77585a8, 2026-10-20) it takes 3 h 29 min and compares 15,040,448,264 values. No routed day sat one rounding step from its recomputation at a tie.

The segment-discharge article reads its routed values at the calibration gauges, and every segment's `pick` for its map, from the published parts. `data-raw/segment_vignette_data.R` refuses to write unless each gauge value equals fwapg's routed mean of twelve months, and both data scripts refuse unless this report names the live build with no check failed (#64, #71). The segment counts come from the tracked segment report, which must be identical to its copy at the commit this report's build ran at: the build reads only committed reports, so that is the report it checked. The live manifest's `segment_commit` can be earlier, because a rerun of `segment_output.R` whose parts all match the live ones is not republished (#93).

## Routed days, against fwapg's months (#99)

Routed PCIC's days are made in wet, not read from fwapg, because fwapg keeps per-segment months and weeks but only per-sub-basin days (fwapg#25). `scripts/segment_daily_output.R` reads the run's `pcic.subbasin_daily` (13,786,122 rows, 37,667 sub-basins, 366 day-of-year bins) and `pcic.segment_weights` (3,377,037 rows) once, each held to the run's fingerprint in `pcic.runs`. It folds 29 February into 28 February by the bins' `n_days` and routes each day as fwapg routes a month, `max(Σ q_acc[upstream] + q_local · share, 0)`, rounded to 5 decimals half away from zero as Postgres rounds the numeric (`wet:::wet_routed_days()`; R's `round()` on the double can land one step away at a tie in the 15-significant-digit decimal, as it did on 4 of 6 constructed ties in the probe, so `wet_routed_round()` decides values near a tie from that decimal string; it equalled Postgres on 200,006 values).

- **The days reproduce fwapg's months and weeks.** The `n_days`-weighted mean of a month's unclamped days, clamped and rounded, equals `pcic.discharge_monthly` on all 40,524,444 segment-months, with no difference even at a rounding tie (the script refuses any difference but one 1e-5 step at a tie, which it counts; its report, `data/checks/segment_daily_output_20260717.txt`, and #99's Phase 1 probe). The same holds for `pcic.discharge_weekly` on 8,467,940 rows in five groups (BULK, LFRA, SQAM, FRAN, SETN; probe only).
- **The clamp, per day.** 13,456,319 of 1,232,618,505 routed segment-days are clamped at zero (1.092 %, against fwapg's 0.978 % of months and 0.977 % of weeks); mid-network, by fwapg's `qa_report_clamped.sql` definition, 48,440 of 97,680,205 (0.050 %, against 0.049 % and 0.048 %). The rule set before measuring was to publish whatever it is and to state it as a weakness above 0.1 % mid-network; it is under. The worst day mid-network is 16 May (874 segments).
- **A month's published days need not average to its published month.** The days are clamped one by one, so where a clamp bites their mean is at or above the clamped month. A reader's plain mean of a month's days also counts the folded 28 February as one day of 28, where the month counts it by how often the period holds 28 and 29 February (37 of February's 847 day-years in 1981–2010). Of 40,524,444 segment-months, 1,869,949 (4.614 %) have a plain day mean more than 1e-5 m³/s from the published month, 1,021,601 of them in February. The largest is 197.24528 m³/s above the month, the largest below 0.12366 m³/s. Outside February the period holds every day 30 times, so a plain mean there can sit below the month only by rounding (at most 1e-5).
- **The balance's days do average to its months.** They are the published months laid on the fit's daily shape, so over 38,680,224 watershed-months the day mean meets the month within 1.2e-15 relative, and the daily depths sum to the monthly depth (28/28.25 of it in February) within 1.3e-15.

## Why not STAC

#1's D4 proposed a STAC Collection with the table extension. It was a proposal and never approved. For a province-wide table, STAC's spatial and temporal search does nothing: every item's footprint would be all of BC. The two jobs STAC was doing here are done by `manifest.json`:

- naming every key, so readers need no listing;
- carrying provenance: checksum, rows, build commit.

A STAC catalogue can still be generated from the manifest later if discovery through a STAC API is wanted.

## Postgres

`wet_db_load()` writes one scenario of a dataset into `discharge.fwa_v1_segment_monthly`. The table holds all rows (both sources, 13 months) with `scenario`, `forcing`, `source` and `pick` as columns. fresh joins:

```sql
select linear_feature_id, q_m3s as mad_m3s
from discharge.fwa_v1_segment_monthly
where scenario = 'historical' and month = 0 and pick
```

`wet_segment_monthly()` (#59) reads the same table per segment and source, keyed on `linear_feature_id`. Without a database it reads the parts through duckdb instead. Measured 2026-10-14 over HTTPS: one segment took 3.3 s with its watershed group named and 27 s without. The parts are sorted by group, and a random ID falls inside about 131 of the 507 row groups' ID ranges, so a read of many IDs with no group reads nearly the whole tree. It warns on a table whose comment records a subset load, and stops on a scenario or source the table does not hold.

Measured on the province table (102,790,688 rows, 19 GB with indexes): the load takes about 24 min. fresh's subquery takes 6.7 s for the whole province, and 0.7 s joined to one watershed group, through a partial index `(scenario, linear_feature_id) WHERE month = 0 AND pick` that `wet_db_load()` creates; without it the subquery takes 197 s.

Loaded from the published manifest on 2026-10-13, into tables dropped first. The partial index exists only on a table `wet_db_load()` created, so tables from before it need dropping. Segments took 23.9 min (20 GB with indexes) and watersheds 10.7 min (8.5 GB). Every part was downloaded into an empty cache and md5-checked. fresh's subquery returned 4,532,843 rows (3,152,838 routed, 1,380,005 balance), in 9.3 s as the first query after the load. Each table's comment names the manifest URL and the build commit, which is how to tell which build a database holds.

Reloaded on 2026-10-15 (#77) from the acb820f manifest, into the existing tables, so their indexes stayed. Segments took 46.1 min and watersheds 21.6 min, about twice the first load. A publish BUILD reading the same database overlapped only the first 9 min of the segment load, and the watershed load ran alone and still doubled (21.6 against 10.7 min), so the BUILD does not explain it. Two differences remain, and the measurement does not separate them: `wet_db_load()` deleted the scenario's old rows in the same transaction, and the rows went through the existing primary key and indexes rather than having them built after the insert. A plain `VACUUM ANALYZE` (33.6 min for both) marks the old rows' space for reuse but does not return it, so the tables stay at 39 GB and 17 GB with indexes against 20 GB and 8.5 GB after a load into new tables. A reload can reuse only space a VACUUM freed before it, not that of the rows it deletes itself; `VACUUM FULL` or dropping the tables first returns the space. A count of the rows fresh's subquery selects gave the same 4,532,843 (3,152,838 routed, 1,380,005 balance) in 1.7 s after the VACUUM (a count, not fresh's select, so not comparable with the 9.3 s above), and both table comments name acb820f.

Reloaded on 2026-10-19 (#103) from the 94deeb5 manifest, the same way, into the existing tables. Segments took 100.6 min and watersheds 47.6 min, about twice the #77 reload again. Afterwards the segment table was 41 GB with indexes and the watershed table 8.5 GB. A count of the rows fresh's subquery selects gave 4,532,843 (3,154,131 routed, 1,378,712 balance, the segment report's picks) in 11.7 s, every routed and balance row's period is 1981-2010, and both table comments name 94deeb5.

## Evidence

- **hydromosaic API** (`https://beehive.pacificclimate.org/hydromosaic/`, 2026-10-12):
  - `/variables` lists `streamflow`, `water_temp` and `DO_sat`.
  - `/outlets` lists 68,716 outlets.
  - `/outlets/4008184/timeseries` lists 19 series per variable: one `historical` (PNWNAmet, 1950–2012) and 9 GCMs × `historical, ssp245` and `historical, ssp585` (1950–2100). The GCMs are CNRM-ESM2-1, FGOALS-g3, IPSL-CM6A-LR, MIROC-ES2L, MPI-ESM1-2-HR, MRI-ESM2-0, NorESM2-LM, TaiESM1 and UKESM1-0-LL.
- **fresh-bc policy** (`aws s3api get-bucket-policy`, 2026-10-12): anonymous GetObject on `bcfishpass/*`, `bcgw/*` and `fwapg/extras/*`. `discharge/*` was added on 2026-10-13 (GetObject only, no ListBucket); an unsigned GET of a probe returned 200 (#7 comment). Default encryption is SSE-S3 (`get-bucket-encryption`: AES256), so a single-PUT part's ETag is its md5, which `wet_catalog_verify()` relies on.
- **The publish** (`WET_PUBLISH=1 Rscript scripts/discharge_publish.R` on the full-run machine, 2026-10-13 03:29–03:31 UTC) ended `published 67 parts, 0 stale keys deleted; all verify`. From a second machine, unsigned, every part answers a HEAD with its bytes and md5, and a full GET of `segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-400.parquet` matched the manifest's md5 and its 3,420,157 rows.
- **Drainage codes:** `split_part(fwa_watershed_code, '-', 1)` over `whse_basemapping.fwa_stream_networks_sp` in the local fwapg.
