# Published discharge: the parts a manifest lists

Reads the `manifest.json` of a published discharge tree and returns one
row per parquet part, with where to fetch it and how to check it. The
tree is `s3://fresh-bc/discharge/fwa/v1/`, read anonymously over HTTPS.
The bucket allows no listing, so the manifest is how a reader finds the
keys.

## Usage

``` r
wet_catalog(manifest = getOption("wet.catalog_url", wet_catalog_url))
```

## Arguments

- manifest:

  Path or URL of a `manifest.json`. The default is option
  `wet.catalog_url`, or else the published discharge manifest.

## Value

`data.frame(dataset, scenario, forcing, source, code, drainage, key, href, rows, bytes, md5)`,
one row per part. `key` is the part's path below the manifest, and
`href` is where to fetch it. Attributes: `manifest` (where it was read
from), `id` (e.g. `discharge/fwa/v1`), `built` (UTC), `provenance` (a
named list: wet version and commit, and the code that built and
published it), `sources` (a data frame describing each `source`, with
its citation), and `source_provenance` (a list by source: what each
source's rows were built from, e.g. the routed table's fingerprint or
the balance's fit release).

## Layout

A dataset ID is `<variable>/<network>/<version>/<unit>_<timebase>`, e.g.
`discharge/fwa/v1/segment_monthly`. The same ID is the S3 prefix, the
crate schema key (`crate::crt_schema_conform(df, "nge", <ID>)`), and,
with the variable as the schema and the rest joined by `_`, the Postgres
table
[`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
writes (`discharge.fwa_v1_segment_monthly`). Under each dataset, parts
sit at `scenario=<s>/forcing=<f>/source=<src>/part-<code>.parquet`:

- scenario:

  The emissions pathway: `historical`, later `ssp245` and `ssp585`.

- forcing:

  The climate data that drove the estimate: `PNWNAmet` (PCIC's
  historical run), a GCM as PCIC spells it, `climr` (the open water
  balance's 1981-2010 normals), or `ensemble`.

- source:

  Who made the estimate and how, `<group>_<method>`: `pcic_routed`
  (PCIC's routed flow placed on the FWA) or `wet_balance` (wet's open
  water balance).

- code:

  The FWA top-level drainage the part holds: the first field of
  `fwa_watershed_code`, e.g. `100` for the Fraser. `drainage` names it.

The three keys are in the path, not in the files: duckdb's
`read_parquet(<hrefs>, hive_partitioning = true)` reads them back from
the hrefs. Files are overwritten in place when the data are rebuilt, so
`md5` identifies a build, and a read during a publish can find a part
that no longer matches its manifest entry: retry once the publish
completes. Each publish rewrites the whole manifest from one local tree.

## See also

[`wet_db_load()`](https://newgraphenvironment.github.io/wet/reference/wet_db_load.md)
to load one scenario of a dataset into Postgres.

## Examples

``` r
# the manifest of a tiny made-up tree, laid out as the published one
cat <- wet_catalog(system.file("extdata", "discharge_manifest.json",
                               package = "wet"))
cat[c("dataset", "scenario", "forcing", "source", "code", "rows")]
#>                              dataset   scenario  forcing      source code rows
#> 1   discharge/fwa/v1/segment_monthly historical    climr wet_balance  100   26
#> 2   discharge/fwa/v1/segment_monthly historical PNWNAmet pcic_routed  100   26
#> 3 discharge/fwa/v1/watershed_monthly historical    climr wet_balance  100   13
attr(cat, "sources")[c("source", "description")]
#>        source             description
#> 1 pcic_routed  Made-up routed values.
#> 2 wet_balance Made-up balance values.
```
