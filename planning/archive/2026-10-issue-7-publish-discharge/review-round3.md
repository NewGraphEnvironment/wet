# Code-check round 3 (#7, crate#31)

Scope: the wet branch diff (diff_wet.patch), the round-2 fix commit a6ebd1b (diff_round2_fix.patch) and the
crate#31 diff. I read in full R/wet_catalog.R, R/wet_db_load.R, scripts/discharge_publish.R,
scripts/discharge_publish_lib.R, the two test files, the helper and the fixture script. For context I read
scripts/segment_output.R (its guards), wb_fit_lib.R, wb_score_md5.R and the committed segment report. I ran the
author's enum.R read-only. I read the bucket's default encryption (SSE-S3 AES256, so a single PUT's ETag is the
MD5 and wet_catalog_verify's ETag test is valid). No file in the repo or the crate worktree was changed except this
one.

## Findings

### The mechanism

Every guard so far has been placed and scoped by **which run it can stop, not which artifact it can withhold**.
The author's model is "if the run errors, nothing publishable results". The artifact PUBLISH consumes is
`data/publish/discharge/fwa/v1/manifest.json` plus the tree, and that artifact outlives runs. So a guard only
protects the publish if, when it fires, no publishable manifest is left behind.

- Round 2's defect: num() stopped BUILD after a valid manifest was already written.
- Round 1's commit-identity check: it checked a label (HEAD) instead of the content the label was meant to carry.

Both come from the same assumption: what one run checked is taken to hold for the artifact at the time another run
reads it. PUBLISH checks only that the *code* is unchanged since `built_at` and that the files match their own
manifest. It never checks that BUILD's input-side guards would still pass, and nothing removes the old manifest
when they do not.

Where this mechanism reaches in the current diff:

1. BUILD refusals before `unlink(root)` at line 178 (below, the Medium finding).
2. PUBLISH's freshness test is code only. It does not compare the manifest's `segment_commit`, `fit_release` or
   routed fingerprint with the current inputs. `fit_release` is itself a label: a refit under the same release
   keeps it.
3. The watershed parts' completeness rests on segment_output.R having checked it once, earlier (below, the Low
   finding).

### **[medium]** scripts/discharge_publish.R:101-176 against :178. A refused BUILD leaves the previous build publishable

The round-2 fix moved the *new* manifest behind every check, as `manifest.pending.json` renamed at line 316. It did
not deal with the *old* one. `unlink(root, recursive = TRUE)` runs at line 178, not at the start of BUILD. enum.R's
own output shows 10 script-level BUILD refusal sites before it: lines 101, 114, 118, 126, 127, 134, 144, 153, 157
and 161. More sites sit in code called before 178:

- publish_schema_cols() (lib:26) at 105-106;
- a curl error at 113, when raw.githubusercontent.com is unreachable;
- wb_key_dir() (wb_fit_lib.R:42) at 122;
- `source("scripts/wb_score_md5.R")` at 148, through score_files_for()'s stop (wb_score_md5.R:18);
- readRDS() and readLines() at 132, 149 and 150;
- git() (line 38) at 141;
- the dbConnect and queries at 163-172;
- publish_drainage_labels() (lib:111) at 174.

The shared preamble (lines 38, 42 and 47, which enum.R files under PUBLISH) also refuses BUILD with the old tree in
place. When any of these fires, the previous successful build's `manifest.json` and tree stay on disk. PUBLISH then
accepts them:

- the dirty check passes once data/checks is committed;
- `git diff built_at HEAD -- R scripts` is empty whenever the change that made BUILD refuse was in data and not code;
- wet_catalog_verify() passes, because the tree matches its own manifest.

Concrete path:

1. BUILD #1 succeeds and its report is committed.
2. The fit is redone under the same release, by a new `adjust_override.txt` or `pooled_variant.txt`. Both are data
   files that score_code_md5 covers. `scripts/wb_output.R` is rerun, but segment_output.R is not yet.
3. BUILD #2 refuses at 153, because the scoring md5 differs from the segment report's. It could equally refuse at
   157, because the segment table predates the balance output.
4. `WET_PUBLISH=1` uploads BUILD #1's tree: the superseded fit's discharge, under a manifest whose provenance reads
   `fit_release 20260717`, the same label as the new fit.

BUILD refused exactly this data, and PUBLISH ships it. This is round 2's defect again with the old manifest in place
of a fresh one: a stop that protects BUILD but not PUBLISH.

The sibling script already does it the other way. segment_output.R:60-61 says "the old table goes first, so a
refused run never leaves one to be read".

Fix: make removing the publishable manifest the first act of a BUILD, before any check that can refuse. For
example, right after `publish` is decided: `if (!publish) unlink(file.path("data", "publish", publish_id,
"manifest.json"))`, which needs `root` defined above the dirty check. Keep the `unlink(root)` at 178 for the tree.

A second line of defence that does not depend on run order: PUBLISH requires the manifest's `segment_commit` to
equal the `wet commit` in the current `segment_output_<release>.txt`. It also requires the committed
`discharge_publish_<release>.txt` to name `built_at` and to have no `FAIL` line. Round 2 offered that as the
alternative.

### **[low]** scripts/discharge_publish.R:125-127, 173, 212-232. Nothing checks the watershed_monthly parts' basin set

`ws_files` is whatever `output/*.parquet` holds when BUILD runs. Per file, BUILD checks only that all 13 months are
present. Nothing ties it to anything else:

- not to `seg_files`' codes;
- not to the province run's `upstream/<code>.rds`, which segment_output.R:80-82 requires to equal the output basins;
- not to any per-basin watershed count.

The segment parts are cross-checked against the segment report's totals. The watershed parts have no
cross-check of any kind. The mtime guard at 156 only orders files: it cannot see a basin file that is missing.

So any of these publishes without a complaint and drops whole drainages from `watershed_monthly`:

- an output directory missing one basin's file, for example after a partial copy between machines (CLAUDE.md:
  "copy reduced bundles rather than rebuilding");
- a bundle cut to some watersheds that still has all 13 months.

The header (line 25) says "BUILD refuses a reduced bundle". It refuses only the month-0-only shape. m1's bundle is
also missing basins: it holds output/100 and 400 against 24 upstream/*.rds. The month check catches m1 today
only because those two files are month-0 only.

Fix: `stopifnot(setequal(seg codes, ws codes))`, and, as segment_output.R does, `setequal` against
`upstream/*.rds` and the per-basin watershed count against `nrow(readRDS(upstream/<code>.rds))`.

## Verdict on the author's enumeration

- **"20 BUILD refusal sites, all before the rename at 316": the count is right but it measures the wrong thing.**
  enum.R splits them 10 before `unlink(root)` and 10 after. The 10 before the unlink leave the old manifest
  publishable (the Medium finding above). So "before the rename" is not "nothing publishable results". The
  "unlink at the start of BUILD" that the brief assumes does not exist: the unlink is at line 178, after 10
  script-level sites and every sourced-lib and package call listed above.
- **The candidate set is incomplete as enumerated.** enum.R parses only `stop`, `stopifnot` and `quit` tokens in
  discharge_publish.R. It misses the following:
  - The sourced libs: discharge_publish_lib.R at 9, 26, 37, 42, 49, 51, 56, 77 and 111; wb_fit_lib.R at 23, 32, 34
    and 42; wb_score_md5.R at 18.
  - The package functions: wet_manifest_write (wet_catalog.R 165-179 and 212), wet_catalog, wet_id_check and
    wet_part_parse.
  - Plain R errors: curl, readRDS, readLines, DBI, arrow and duckdb failures, and `if (!all(checks))` on an NA.

  Checked by hand, every one of these is reached at or before line 316, and lines 317-319 only print. So the
  "before the rename" placement holds for the whole set. The before-the-unlink problem holds for every call at
  lines 29-176.
- **The shared preamble is misfiled.** Lines 38, 42 and 47 run in both modes, and enum.R counts them as PUBLISH
  only. For BUILD they are refusal sites before the unlink.
- **PUBLISH: "every refusal before any upload except the prefix assertion and the final verification" is
  incomplete.** After the first PUT (line 75), these can also refuse:
  - put failures through aws() (line 66). Mid-upload, so this falls under the accepted tradeoff.
  - list-objects-v2 at 82 and delete-object at 89, both through aws().
  - wet_catalog(publish_url) at 92, for example HTTP 403 before the bucket policy opens.
  - the stopifnot at 93 and the stop at 95.

  None of these leaves readers worse off than the accepted tradeoff: the new manifest names only new keys. The
  prefix assertion at 87 cannot fire, because `--prefix` already guarantees it.

## Checked and clean

- crate#31: the registry path rule makes `system.file("extdata","schemas","nge",<ds>.yaml)` the same file as
  `row$schema_yaml`, so the md5 check at 117 compares the file conform actually uses.
- The num() patterns against the committed segment report: each matches exactly one line, and `sr[3]` carries the
  scoring md5.
- `git diff 653fc13 HEAD -- R scripts` minus the publish files is empty, so BUILD is not blocked by its own
  branch.
- Bucket default encryption is SSE-S3, so the ETag equals the MD5.
- 1.80 GB over 67 parts, all under the 5 GB single-PUT limit.
- wet_db_load: transaction, rollback, PK after load, pick check and cache.
- wet_catalog: parsing, NULL/empty sources, and vapply's integer-to-double promotion.
