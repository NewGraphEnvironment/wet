# Published discharge: where it lives and how it is named

**Verified:** 2026-10-13 · **Issues:** #7 (decided, then published), #64 (value checks), #1 (D4, superseded), #57 (the table), fwapg#25 (projections) · **Produced by:** plan-mode discussion on #7, recorded in `planning/archive/2026-10-issue-7-*/findings.md`, the probes listed under "Evidence", and `scripts/discharge_publish.R` (BUILD) for the value checks.

**Status:** published 2026-10-13 at `https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json`. The `historical` scenario, built at wet 7c62b9e (segment table 653fc13, fit 20260717, crate 0.7.0), is 67 parts and 1.80 GB: 43 `segment_monthly` (102,790,688 rows) and 24 `watershed_monthly` (41,904,356). The build report is `data/checks/discharge_publish_20260717.txt`. Since #64 it is the value-checked rebuild at wet 032242f, whose 67 parts are byte-identical to the 7c62b9e upload, so the upload was not repeated.

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
- **`<unit>_<timebase>`:** the feature a row describes and the time step of its values.
  - `segment_monthly`: one row per FWA segment and calendar month, a mean over a period, with month 0 the annual.
  - `watershed_monthly`: the same per fundamental watershed.
  - Monthly is the finest step both sources share; seasons are averages of months.
  - A daily or per-year product gets its own dataset (`segment_daily`, `segment_yearly`).

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
- **`climr` names the balance's climate input**, not every input: its actual evapotranspiration is CGIAR, carried from #15. The manifest's source description gives the whole recipe.
- **`period` is a column, not a key.** In `historical`, routed rows are 1951–2012 and balance rows 1981–2010 until fwapg#25 builds routed flow over 1981–2010. A projection partition will hold several periods.
- **Sources share one dataset**, so one read returns them side by side for the same segment, and reading one directory returns one source. The partition keys live in the path and are dropped from the file columns.
- **In v1, `pick` is unique per (scenario, feature, month).** `wet_db_load()` refuses a load that breaks this. A projection scenario holding several periods will need the rule restated (per period); that is undecided until one is built.
- **`pick` is a relation across sources.** It is TRUE on the default source for a segment (`wet_source_pick()`, #57). It is computed across every source of a scenario, so it spans `forcing` in `historical`. A rebuild of a scenario therefore rewrites every source's part files, and a new source (Poisson) means a rebuild.
- **`part-<code>.parquet`** holds one FWA top-level drainage: the first field of `fwa_watershed_code`. For example 100 is the Fraser, 200 the Mackenzie (Peace and Liard), 300 the Columbia, 900–960 coastal, and 999 spans 246 watershed groups. The manifest labels each code. Readers go through the manifest, not file names.
- **`watershed_group_code` is a column, and rows are sorted by it**, with row groups of about a watershed group's size. A read filtered to one group then skips the other row groups on their statistics, without a join to the FWA.

## Where: `s3://fresh-bc/`, not a new bucket

- **fresh-bc holds freshwater data for BC.** The bucket's own documentation sends *published* datasets to `stac-*-bc` buckets, but those are STAC catalogues, and this is not one.
- **Variable-first prefix.** The same doc scopes fresh-bc prefixes by producer (`bcfishpass/`, `fwapg/`) so they do not become dumping grounds. `discharge/` is a variable instead, chosen so that discharge from several producers sits in one place, with the producer in `source`. The exception is recorded in the bucket's documentation, where the policy change that opens the prefix is also tracked.
- **Access.** Anonymous `s3:GetObject` on `discharge/*` only, and no `s3:ListBucket`. Readers therefore use `manifest.json`, which names every key, rather than globbing.
- **The manifest is rewritten whole by each publish**, from one local tree, so that tree must hold every scenario meant to stay published. Its `sources` entries carry what each source's rows were built from (the routed table's fingerprint and fwapg commit; the balance's fit release and province run), and each dataset names its crate schema at a crate release.
- **Overwrites.** Bucket versioning is off, so an overwrite is final. That is acceptable because every file is rebuilt from code and inputs, and the manifest records the wet commit, fit release and routed-table fingerprint that built it.

## Every published flow is checked against its source (#64)

The build's original cross-checks compared row and `pick` counts only, which cannot see a value that moved. Since #64 the build reads every written part back and compares it, value by value, with what it was built from (`wet_values_compare()`). It reports compared, differing and largest difference for each check, and fails on any difference. Every published flow (`q_m3s`) is checked against its source. Of the other columns, the segment parts' `runoff_mm`, `coverage` and `pick` are checked against the segment table, and `period`, `watershed_group_code` (filled from fwapg and checked only for NA), and the watershed parts' `runoff_mm`, `coverage` and `bc_fraction`, are not checked value by value:

| check | compared | differing | largest difference |
|---|---|---|---|
| routed months 1–12 = fwapg's `fwa_stream_networks_discharge_monthly` | 40,524,444 | 0 | 0 |
| routed month 0 = mean of its 12 months | 3,377,037 | 0 | 9.1e-13 m³/s |
| balance (13 months) = the fit's `output/` through `fwa_streams_watersheds_lut` | 58,889,207 | 0 | 0 |
| segment parts = the #57 segment table, on each of `q_m3s`, `runoff_mm`, `coverage`, `pick` | 102,790,688 | 0 | 0 |
| watershed parts = the fit's `output/` | 41,904,356 | 0 | 0 |

The routed months' total, rounded to 1e-6 m³/s per value, equals the table's fingerprint (178,035,348.248310 m³/s). Values copied from a double are compared exactly. Only the two means of twelve months meet within a tolerance (relative 1e-9), because R's `mean()` and a sum over 12 round differently in the last bits. The lut join re-does the segment table's join, so it catches indexing errors, not errors in the lut itself. Measured on m4 at wet 032242f on 2026-10-13: the build took about 8 min with the checks, against about 5 without.

The segment-discharge article reads its values from the published parts, and `data-raw/segment_vignette_data.R` refuses to write them unless each equals its source and this report names the live build with no check failed.

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

Measured on the province table (102,790,688 rows, 19 GB with indexes): the load takes about 24 min. fresh's subquery takes 6.7 s for the whole province, and 0.7 s joined to one watershed group, through a partial index `(scenario, linear_feature_id) WHERE month = 0 AND pick` that `wet_db_load()` creates; without it the subquery takes 197 s.

Loaded from the published manifest on 2026-10-13, into tables dropped first. The partial index exists only on a table `wet_db_load()` created, so tables from before it need dropping. Segments took 23.9 min (20 GB with indexes) and watersheds 10.7 min (8.5 GB). Every part was downloaded into an empty cache and md5-checked. fresh's subquery returned 4,532,843 rows (3,152,838 routed, 1,380,005 balance), in 9.3 s as the first query after the load. Each table's comment names the manifest URL and the build commit, which is how to tell which build a database holds.

## Evidence

- **hydromosaic API** (`https://beehive.pacificclimate.org/hydromosaic/`, 2026-10-12):
  - `/variables` lists `streamflow`, `water_temp` and `DO_sat`.
  - `/outlets` lists 68,716 outlets.
  - `/outlets/4008184/timeseries` lists 19 series per variable: one `historical` (PNWNAmet, 1950–2012) and 9 GCMs × `historical, ssp245` and `historical, ssp585` (1950–2100). The GCMs are CNRM-ESM2-1, FGOALS-g3, IPSL-CM6A-LR, MIROC-ES2L, MPI-ESM1-2-HR, MRI-ESM2-0, NorESM2-LM, TaiESM1 and UKESM1-0-LL.
- **fresh-bc policy** (`aws s3api get-bucket-policy`, 2026-10-12): anonymous GetObject on `bcfishpass/*`, `bcgw/*` and `fwapg/extras/*`. `discharge/*` was added on 2026-10-13 (GetObject only, no ListBucket); an unsigned GET of a probe returned 200 (#7 comment). Default encryption is SSE-S3 (`get-bucket-encryption`: AES256), so a single-PUT part's ETag is its md5, which `wet_catalog_verify()` relies on.
- **The publish** (`WET_PUBLISH=1 Rscript scripts/discharge_publish.R` on the full-run machine, 2026-10-13 03:29–03:31 UTC) ended `published 67 parts, 0 stale keys deleted; all verify`. From a second machine, unsigned, every part answers a HEAD with its bytes and md5, and a full GET of `segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-400.parquet` matched the manifest's md5 and its 3,420,157 rows.
- **Drainage codes:** `split_part(fwa_watershed_code, '-', 1)` over `whse_basemapping.fwa_stream_networks_sp` in the local fwapg.
