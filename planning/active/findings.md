# Findings — Publish per-segment discharge: the upload (#7)

## Issue context

Issue #1 item 6. Publish the per-segment table and get it into fwapg so fresh can join it (fresh#114).

**Revised 2026-10-12** in planning: STAC is dropped (it was #1's D4 proposal, never approved), and replaced by a manifest. The layout and naming below replace D4's `wet/v<major>/unit=…/scenario=…/period=…` key. The durable record is [`research/discharge_publish.md`](https://github.com/NewGraphEnvironment/wet/blob/main/research/discharge_publish.md).

## Naming: one identifier per dataset

A dataset ID is `<variable>/<network>/<version>/<unit>_<timebase>`, for example `discharge/fwa/v1/segment_monthly`. Every other name derives from it:

- **S3:** `s3://fresh-bc/discharge/fwa/v1/segment_monthly/`
- **manifest:** `s3://fresh-bc/discharge/fwa/v1/manifest.json`
- **crate schema:** `("nge", "discharge/fwa/v1/segment_monthly")`
- **Postgres:** `discharge.fwa_v1_segment_monthly`

The levels:

- **variable:** `discharge` now; later `water_temperature` and `oxygen_saturation`, from PCIC hydromosaic.
- **network:** `fwa` now; a national product would be `chn`.
- **version:** the schema version. Data are overwritten in place within a version, which bumps only on a breaking column change.
- **unit and timebase:** `segment_monthly` and `watershed_monthly` (month 0 = annual).

## Layout

```
s3://fresh-bc/discharge/fwa/v1/
  manifest.json
  segment_monthly/scenario=historical/forcing=PNWNAmet/source=pcic_routed/part-<code>.parquet
  segment_monthly/scenario=historical/forcing=climr/source=wet_balance/part-<code>.parquet
  watershed_monthly/scenario=historical/forcing=climr/source=wet_balance/part-<code>.parquet
```

- **Hive keys:**
  - `scenario`: `historical`, `ssp245`, `ssp585`.
  - `forcing`: the climate data that drove the estimate. `PNWNAmet`, a GCM as PCIC spells it, `climr`, or `ensemble`.
  - `source`: `<group>_<method>`, e.g. `pcic_routed`, `wet_balance`, later `poisson_<method>`.
- **`period` is a column.** Routed is 1951–2012 and the balance 1981–2010 until NewGraphEnvironment/fwapg#25.
- **`part-<code>`:** one FWA top-level drainage (the first field of `fwa_watershed_code`), labelled in the manifest.
- **Segment columns:** `linear_feature_id, watershed_group_code, month, runoff_mm, q_m3s, coverage, period, pick`.
  - Rows are sorted by `watershed_group_code`, so a one-group read prunes on row-group statistics.
  - `pick` is TRUE on the default source (#57, `wet_source_pick()`): routed PCIC unless its annual flow is under 0.2 × the balance's, and only on a watershed's own line.
- **Watershed columns:** `watershed_feature_id, watershed_group_code, month, runoff_mm, q_m3s, coverage, bc_fraction, period`.
- **Column types and meanings** are registered in crate and applied with `crt_schema_conform()` before writing.

## Pieces

- **`wet_catalog()`:** reads `manifest.json` and returns one row per part (dataset, scenario, forcing, source, code, drainage, href, rows, bytes, md5), with build provenance.
- **`wet_db_load()`:** downloads one scenario of a dataset, checks each part's md5 against the manifest, and writes `discharge.fwa_v1_segment_monthly` (all rows, both sources, with `pick`). fresh then joins with no change to fresh:
  ```r
  frs_col_join(from = "(select linear_feature_id, q_m3s as mad_m3s
                        from discharge.fwa_v1_segment_monthly
                        where scenario = 'historical' and month = 0 and pick)")
  ```
- **`scripts/discharge_publish.R`:** builds the tree and manifest from the shipped fit's `segment/` and `output/`, writes a tracked report, and uploads only when asked.

## Blockers

- **PCIC terms of use:** "AS IS", with no named open licence. Publishing derived per-segment values, cited, is not a concern (decided 2026-10-07).
- **Public read:** fresh-bc grants anonymous `s3:GetObject` on `bcfishpass/*`, `bcgw/*` and `fwapg/extras/*` only. `discharge/*` needs one more prefix in the bucket policy, which is tracked in the bucket's infrastructure repo. No `s3:ListBucket`: readers go through the manifest.

Relates to #1, fresh#114.


## Exploration (2026-10-12)

- No code drift since the segment table: `git diff 653fc13 origin/main -- R scripts`, excluding the four publish files, is empty, so BUILD's segment guard passes from main.
- The committed `data/checks/discharge_publish_20260717.txt` names build 7e738e1 and crate 0.6.0; PUBLISH refuses a tree whose code changed since its build, so it is rebuilt.
- m4: crate 0.4.0 installed; aws CLI with the `airvine` profile and no default; 531 GB free.
- crate#32 merged and released as v0.7.0; anonymous GetObject on `fresh-bc/discharge/*` live (issue comment, 2026-10-13).

## Errors Encountered

| Error | Resolution |
|-------|------------|
| BUILD on m4: `git diff … :(exclude)R/wet_catalog.R … failed:` with no message | `system2()` passes args to `sh` unquoted, so `(` is a syntax error (status 2). The segment guard was added in #62's code-check rounds, after the last real build, so it had never run. `shQuote()` in the `git()` and `aws()` helpers of `scripts/discharge_publish.R`. |
| m4 launch: `cd … && … && nohup … &` ran the `cd` in the background too, so the foreground probe looked in `~` | `&` binds to the whole `&&` list (code-check-shell); separate with `;` and guard the `cd` with `|| exit` |
