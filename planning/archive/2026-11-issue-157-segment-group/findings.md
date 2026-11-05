# Findings — Build one watershed group's segment product from a published fit? (#157)

## Issue context

**If we do it:** one basin's segment discharge can be rebuilt from a changed input or parameter in minutes instead of a province run, and an app could compute a scenario for one site (a different climate period, say). **If we never do:** every change waits for a province run, and anything outside the published product is out of reach.

### Question

Is a per-group build worth having, and what is its smallest shape? As it stands:

- `scripts/segment_output.R` needs the shipped province fit (`fits.rds`, not published), a clean tree and the complete province run.
- Accumulation runs per basin (`scripts/wb_province.R` samples per group and sums upstream per basin), so a group needs the groups upstream of it.
- `scripts/wb_inputs.R` fetches from figshare, TerraClimate, PCIC and Environment Canada.

### Candidate shape

1. Publish the shipped fit beside the discharge product.
2. Take a group, resolve the groups upstream of it, and sample and accumulate only those.
3. Apply the published fit and write the group's segments.
4. Test: one group's output against the published product, segment by segment.

Out of scope: refitting.

## Plan-mode measurements (2026-11-04)

### Closure of every watershed group (m1 fwapg, read-only psql, 24 min)

Roots of a group: its distinct `wscode_ltree` values with no proper ancestor among them; closure: every polygon whose wscode lies under a root. Over 246 groups (3,245,453 polygons):

| groups a group needs | count |
|---|---|
| 1 (itself) | 53 |
| 2–3 | 59 |
| 4–10 | 62 |
| more than 10 | 72 |

| closure polygons | count |
|---|---|
| ≤ 50k | 146 |
| 50k–200k | 52 |
| > 200k | 48 |

Examples: BULK (root `400.431358`) BULK + MORR, 35,191; SALR (`100.591289`) SALR + LSAL + MUSK, 12,481; LNRS (`100.567134`) 19 groups, 116,474; MORK, SETN, TWAC, COTR, FRCN (root `100`) 70 groups, 644,710; UFRA 82 groups (a second root `999.…`); LFRA 6 roots, 77 groups, 796,176. The groups with root `100` (or `200`, `300`) hold a mainstem polygon with `localcode == wscode`, and for such a row `FWA_Upstream` is the whole subtree, so under fwapg's semantics they need the whole basin. A position-aware refinement (polygons at or above the group's lowest code, with `min(least(wscode, localcode))` per root) was measured on UFRA, TWAC, MORK, SETN, LFRA, BULK, LNRS, COTR and changed no count, because that lowest code is the root itself wherever a `(W, W)` row exists. The simple rule stands.

54 groups span more than one top-level drainage code (first ltree label), so a group's published rows can sit in several parts.

Brute-force check of the closure claim: `FWA_Upstream(a, b)` pairs with `a` in BULK and `b` not under `400.431358`: 0. BULK has 12 irregular polygons (localcode not under wscode) of 20,970.

Scratch output: `closure_all.tsv` in the session scratchpad (not kept); Phase 1's `scripts/segment_group_closure.R` writes the tracked table.

### m4's province run `92b893c4da`

`layers.tif` 552 MB, `in_bc.tif` 0.7 MB, `sample/` 246 files, 1.1 GB (BULK 7.8 MB, SALR 1.6 MB, LFRA 5.2 MB), `upstream/` 1.3 GB, `fit_20260717/output` 826 MB, `segment` 1.3 GB. `sample_times.txt`: BULK 10 s, MORR 8 s, SALR 3 s, LSAL 3 s, MUSK 2 s, MORK 15 s, LFRA 8 s (4 workers); the province log: sampling 6.5 min, accumulation 4.5 min. m4 main checkout at 83af891, clean; duckdb 1.4.3, arrow 25.0.1, terra 1.9.46. m1 holds a reduced bundle: no rasters, no samples, 25 `upstream/` files (335 watersheds).

### The published parts, one group

`wet_catalog()`: `segment_monthly` historical code 400: `wet_balance` 3,420,196 rows (44.5 MB), `pcic_routed` 3,420,157 rows (32.1 MB). duckdb over httpfs with `watershed_group_code = 'BULK'`: balance 390,481 rows, 30,037 segments, 10,569 picked (= 813 × 13, the segment report's BULK balance count) in 1.0 s; routed month 0: 30,037 segments in 0.8 s.

### Code constraints

- `scripts/wb_province.R:52-61` hashes itself, 13 `R/` files and `inst/extdata/chapman_table3.csv` into the province key; `scripts/wb_score_md5.R` hashes the scoring files into the fit's `code_md5`. New functions go in new files; none of those files is edited.
- `scripts/discharge_publish.R:196-212` refuses the segment table once any file under `R/` or `scripts/` (bar the publish's own and the daily script) moved since its report; 21 have moved since 28105a3, so the rerun is already owed (m4 memory, #117).
- `scripts/discharge_publish.R:334-336` drops watershed rows with NA `q_m3s`; `segment_output.R:163` keeps balance segment rows only where the watershed has a value.
- `vd_published()` (`scripts/vignette_data_lib.R`) refuses until the next BUILD writes #117's digests, so the group script verifies the parts it reads with `wet:::wet_catalog_verify()` instead.
- `wet_manifest_write()` lists `*.parquet` only and `wet_part_parse()` accepts `part-<code>.parquet` keys only, so publishing `fits.rds` is a manifest-format change.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `function min(ltree) does not exist` (refinement probe) | `min(least(w, l)::text COLLATE "C")::ltree` |

## Implementation findings (2026-11-04)

- The closure under a group's roots is enough but not the least: the plan-mode claim that a position-aware refinement "changes none of them" was wrong (SALR's rows reach 4,589 of 12,481; UFRA's 23,358 of 644,770). `wet_ws_reach()` trims to the exact reach; `data/checks/segment_group_closure.txt` holds both counts.
- BULK's 11 calibration-gauge watersheds differ from the published months because `wet_donor_mean()` tests distance `== 0`: #158.
- Subsetting a data frame by a logical index drops its custom attributes; by an integer index it keeps them.

| Error | Resolution |
|-------|------------|
| soul's `gh_rest.sh` fails to parse under `/bin/bash` 3.2 (`case` pattern `)` inside `$( )`) | Default branch read with `gh api repos/<o>/<r> --jq .default_branch`; soul#718 |
| Beyond-tolerance listing printed the merge's columns off by one | Columns taken by name (ae518cb) |
