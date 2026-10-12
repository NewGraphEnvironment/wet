# Task: Publish per-segment discharge: parquet + STAC + fwapg load for fresh#114 (#7)

Issue #1 item 6. Publish the per-segment table and get it into fwapg so fresh can join it (fresh#114). Settled in plan mode on 2026-10-12: no STAC, a manifest instead; the layout and naming below.

## Decided layout and naming

**One identifier per dataset, with every name derived from it by one rule.** The dataset ID is `<variable>/<network>/<version>/<unit>_<timebase>`, for example `discharge/fwa/v1/segment_monthly`. It is used verbatim as:

- the S3 key prefix under `s3://fresh-bc/`
- the manifest's `dataset` field and `wet_catalog()`'s `dataset` column
- the crate key: `crt_schema_conform(df, "nge", "discharge/fwa/v1/segment_monthly")`, with the YAML at `inst/extdata/schemas/nge/discharge/fwa/v1/segment_monthly.yaml`
- the local build path: `data/publish/discharge/fwa/v1/segment_monthly/`

Postgres gets `<variable>.<network>_<version>_<unit>_<timebase>`, i.e. `discharge.fwa_v1_segment_monthly`. The version stays in the name, so a v2 lands beside v1 and consumers move over deliberately.

The manifest sits at `<variable>/<network>/<version>/manifest.json`, one per variable, network and version.

```
s3://fresh-bc/discharge/fwa/v1/
  manifest.json
  segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-<code>.parquet
  segment_monthly/scenario=historical/forcing=climr/source=wet_balance/part-<code>.parquet
  watershed_monthly/scenario=historical/forcing=climr/source=wet_balance/part-<code>.parquet
later:
  segment_monthly/scenario=ssp245/forcing=MPI-ESM1-2-HR/source=pcic_routed/…   (hydromosaic CMIP6, fwapg#25)
  s3://fresh-bc/water_temperature/fwa/v1/segment_monthly/…                      (hydromosaic water_temp)
  s3://fresh-bc/discharge/chn/v1/…                                              (national network)
```

- **`<variable>`:** `discharge` now. Later `water_temperature` and `oxygen_saturation` (hydromosaic's `water_temp` and `DO_sat`); not `temperature`, which cd's air temperature makes ambiguous.
- **`<network>`:** `fwa`. It decides the ID columns and the coverage.
- **`<version>`:** the schema version. Data iterations overwrite within it, and it bumps only on a breaking column change.
- **`<unit>_<timebase>`:**
  - `segment_monthly` and `watershed_monthly` are separate datasets, because their key columns differ.
  - `monthly` means a mean per calendar month over a period, with month 0 the annual.
  - Later products are named for their time base: `segment_daily`, `segment_yearly` (e.g. GSDD).
- **Hive keys, in order: `scenario`, `forcing`, `source`.**
  - `scenario`: `historical`, `ssp245`, `ssp585`.
  - `forcing`: the climate data that drove the estimate. `PNWNAmet` for PCIC's historical run, a GCM as PCIC spells it (`MPI-ESM1-2-HR`), `climr` for the balance's 1981–2010 normals, or `ensemble` for an ensemble mean.
  - `source=<group>_<method>`: `pcic_routed`, `wet_balance`, later `poisson_<method>` (Poisson Consulting).
- **`period` is a column.** Routed is 1951–2012 and the balance 1981–2010 until fwapg#25 builds routed flow over 1981–2010. Projection partitions will hold several periods.
- **`pick` spans sources within one scenario** (and so spans `forcing` for historical). Any rebuild of a scenario rewrites every source's part files.
- **`part-<code>.parquet`:** one file per FWA top-level drainage code (100 Fraser … 999). The manifest gives each code a drainage label: the named mainstem, or else its largest watershed groups.
- **`watershed_group_code` column:**
  - Rows are sorted by `watershed_group_code, linear_feature_id, month` (watershed table: `…, watershed_feature_id, month`).
  - Row groups are sized at about one watershed group, so a by-group read prunes on row-group statistics.
- **Segment columns:** `linear_feature_id, watershed_group_code, month (0 = annual), runoff_mm, q_m3s, coverage, period, pick`.
- **Watershed columns:** `watershed_feature_id, watershed_group_code, month, runoff_mm, q_m3s, coverage, bc_fraction, period`. `discharge_m3s` is renamed `q_m3s` for consistency.
- **Postgres:** `discharge.fwa_v1_segment_monthly` and `discharge.fwa_v1_watershed_monthly`, each holding all rows plus `scenario`, `forcing` and `source`. fresh's subquery is:
  ```sql
  select linear_feature_id, q_m3s as mad_m3s
  from discharge.fwa_v1_segment_monthly
  where scenario = 'historical' and month = 0 and pick
  ```
- **Column schemas:** registered in crate as `("nge", "discharge/fwa/v1/segment_monthly")` and `("nge", "discharge/fwa/v1/watershed_monthly")` (`schema_only`). The publish step runs `crt_schema_conform()`, and the manifest names the schema rather than restating it.
- **Public access:**
  - fresh-bc gets `discharge/*` as a public GetObject prefix (a change in the bucket's infrastructure repo; the user runs the apply).
  - With no ListBucket, readers go through `manifest.json`.
  - Bucket versioning is off, so overwrites are final. That's acceptable because everything is rebuildable.

### Phase 1: Record the decisions
- [x] Edit #7's body (and title: STAC → manifest):
  - drop STAC
  - record the layout, naming rules and overwrite policy
  - name `discharge.fwa_v1_segment_monthly` as fresh's join
- [x] `research/discharge_publish.md`:
  - the layout and the reasons for it (network-keyed, variable-first, sources as a Hive key, `pick` across sources, why no STAC, why fresh-bc)
  - the naming rule (dataset ID → S3, crate, Postgres), and the `scenario` / `forcing` / `source` conventions with hydromosaic's variables, GCMs and SSPs as the worked case
  - a row in `research/README.md`
- [x] File the issue in the bucket's infrastructure repo:
  - add `discharge` to fresh-bc's `public_read_prefixes`
  - add the `discharge/` row to `docs/fresh-bc-bucket.md`
  - amend its "scope a prefix by source" rule for published variables

### Phase 2: crate schemas (crate PR, merged before Phase 5 uses them)
- [x] `inst/extdata/schemas/nge/discharge/fwa/v1/segment_monthly.yaml` and `…/watershed_monthly.yaml`, keyed by the dataset ID: types, required flags, units, notes. Hive keys are documented but not columns.
- [x] A registry-integrity test that `schema_yaml` equals `schemas/<source>/<file_name>.yaml` for path-style names.
- [x] Registry rows and tests (crate#31, branch `31-discharge-schemas`); a decision entry `decisions/nge/20261012_dataset_id_keys.md`
- [ ] crate PR open; its merge and release are the user's call, and gate Phase 5's real run

### Phase 3: `wet_catalog()` (tests first)
- [x] `R/wet_catalog.R`: reads `manifest.json` from a path or URL. The default is `getOption("wet.catalog_url", "https://fresh-bc.s3.us-west-2.amazonaws.com/discharge/fwa/v1/manifest.json")`.
  - Returns one row per part: `dataset` (the full ID), `scenario, forcing, source, code, drainage, href, rows, bytes, md5`.
  - Build provenance comes back as attributes: wet commit, fit release, routed fingerprint, fwapg commit, build time.
- [x] An internal manifest writer in the same file, so the shape written is the shape read.
- [x] A small fixture tree plus manifest in `inst/extdata/discharge/fwa/v1/`, used by the runnable example and the tests.
- [x] `tests/testthat/test-wet_catalog.R`:
  - a write → read round trip
  - relative hrefs resolve against the manifest's location
  - a malformed manifest is refused

### Phase 4: `wet_db_load()` (tests first)
- [x] `R/wet_db_load.R`:
  - `wet_db_load(conn, catalog = wet_catalog(), dataset = "discharge/fwa/v1/segment_monthly", scenario = "historical", months = 0:12, pick_only = FALSE)`
  - Downloads each part with curl to a cache, checks size and md5 against the manifest, and reads it with duckdb (Suggests).
  - Writes to the table the rule derives from the ID (`discharge.fwa_v1_segment_monthly`), replacing that scenario's rows in one transaction. It creates the schema, table and key the first time, and the table comment records the manifest URL and wet commit.
- [x] `tests/testthat/test-wet_db_load.R` (`local_fwapg()`, so skipped on CI):
  - a load
  - a reload doesn't duplicate rows
  - a md5 mismatch is refused, and nothing is written
  - fresh's subquery returns one row per segment

### Phase 4b: Plan-review fixes to landed code (`review-plan.md`)
- [x] G14: ship only a manifest (`inst/extdata/discharge_manifest.json`) for the example; tests build the Hive tree in a tempdir with duckdb and the writer (no parquet in git, no >100-byte paths)
- [x] G4: per-source provenance in the manifest's `sources` entries; crate version and schema URL in `datasets`; the rule that each publish rewrites the whole manifest from a local tree holding every scenario
- [x] G7: internal `wet_catalog_verify()`: an anonymous HEAD per href, Content-Length == bytes and ETag == md5 (single-part uploads), tested with mocked curl
- [x] G3: `wet_db_load()` asserts one `pick` per (feature, month) in the scenario after a load of a dataset that has `pick`
- [x] G6: `?wet_catalog` documents reading the tree with duckdb `hive_partitioning = true`

### Phase 5: Build the release tree
- [ ] ~~`scripts/segment_output.R`: add `watershed_group_code`, and sort by group.~~ The publish script adds `watershed_group_code` from fwapg and sorts (review O3), so the segment table needs no rebuild
- [ ] `scripts/discharge_publish.R`:
  - Reads the shipped fit's `segment/` and `output/`, and takes watershed groups and drainage labels from fwapg.
  - Conforms each part to the crate schema and splits it by source into the Hive tree under `data/publish/discharge/fwa/v1/`, with sized row groups.
  - Writes `manifest.json` and the report `data/checks/discharge_publish_<release>.txt`.
  - Refuses an uncommitted tree, and a segment table older than the fit.
  - It also refuses when the segment code has changed since the commit the segment report names (review G11).
  - Asserts (G1, G2, G3):
    - column names and order equal the crate YAML's, with `source` dropped after checking that it holds one value
    - classes and NA counts are unchanged by conform
    - `month` is in 0–12, keys have no NA, `period` matches `YYYY-YYYY`, and `q_m3s` is ≥ 0
    - rows are unique on (feature, month)
    - exactly one `pick` per (segment, month) across a scenario's files
  - Writes one parquet row group per watershed group with arrow's `ParquetFileWriter` (B2).
  - Drops NA-flow watershed rows, as the segment table does (G12).
  - Labels each drainage with the GNIS name of the stream whose watershed code is `<code>-000000…`, or else its three largest groups (G15).
  - `period_routed` and `period_balance` move to the shared libs (G12).
- [ ] Upload only with `WET_PUBLISH=1`; the default is a dry run that lists the plan, and the first output line says which.
  - Each part goes up with `aws s3api put-object --content-md5`, then the manifest, then stale keys under the prefix are removed (G7, G8).
  - Afterwards `wet_catalog_verify()` reads every key anonymously.

### Phase 6: Run it where the full province run is
- [ ] Check the routed table's fingerprint against the tracked report first (A1). Then run `scripts/discharge_publish.R` (no upload) and commit its report.
- [ ] Measure pruning: for one watershed group, the row groups read against the total.
- [ ] `wet_db_load()` into that fwapg. Count fresh's subquery against the segment report's picked totals.

### Phase 7: Docs
- [ ] CLAUDE.md:
  - an architecture line for the publish path
  - the Data Sources note on what is published where
- [ ] ~~`_pkgdown.yml` reference entries~~: the site has no reference index, so `check_pkgdown()` has nothing to check (review G16)
- [ ] `devtools::document()`, `lintr::lint_package()` and `pkgdown::check_pkgdown()`.

### After the PR (user-gated, not in the mandate)
- The infrastructure apply opens `discharge/*`.
- Then `WET_PUBLISH=1 Rscript scripts/discharge_publish.R` uploads.

## Validation

- [ ] Tests pass, plus `devtools::check()` with no new NOTE
- [ ] Acceptance on real data (review, from `segment_output_20260717.txt` and `wb_output_20260717.txt`):
  - segment total 102,790,688 rows: routed 43,901,481 and balance 58,889,207
  - `sum(pick)` 58,926,959
  - fresh's subquery returns 4,532,843 rows (3,152,838 routed, 1,380,005 balance)
  - the watershed dataset holds 42,190,889 rows less the NA-flow rows
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
