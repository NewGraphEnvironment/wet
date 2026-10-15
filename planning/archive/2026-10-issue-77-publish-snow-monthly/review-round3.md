# Code-check round 3 for #77 (branch diff against dcd15b0)

## Findings

- **[severity: fragile] research/discharge_publish.md:105**: the sentence "about twice the first load, because `wet_db_load()` deletes the scenario's old rows in the same transaction" names one cause, and nothing measured separates it from two others.
  - **The code.** The delete is in the transaction (R/wet_db_load.R:92, inside `dbWithTransaction`). But the two loads also differ in their indexes.
    - The first load created its tables (`created = TRUE`). It inserted into a bare heap and built the 6-column primary key, the id index and the partial index afterwards (lines 119-130).
    - The reload went into existing tables. Every one of its 102.8M rows went through the existing primary key and id index while it was inserted. Incremental B-tree maintenance is usually far slower than a bulk build after the load.
  - **The run.** `planning/active/progress.md` records that the segment reload (03:20:53–04:07:00 UTC) ran on m4 "alongside" the BUILD rerun (03:21–03:30 UTC). That BUILD reads fwapg's routed table and the lut from the same Postgres.
  - **Why it matters.** The sentence tells the next person what makes a reload slow, and so what to change: drop the tables, or avoid the delete. The measurement cannot tell the three causes apart.
  - **Fix.** State the measured times with all three differences (existing indexes, the concurrent BUILD, the delete), or attribute it after a reload that varies one of them.
  - **Same paragraph.** "A later reload fills that space rather than growing again" is an unmeasured prediction. It holds only if a VACUUM has run since the previous reload, because a reload's inserts cannot reuse the space of the rows it deletes in its own transaction. It is true for the next reload after this VACUUM, so it is not false, but it is stated as fact.

Nothing else is false. The inventory follows. Every sentence that states a fact about the data, the build or the database was checked against its artifact. The vignette's checks were run: both vignettes were purled and run against the bundles at HEAD (a `git archive` copy with `load_all`), and every `stopifnot` passed.

## Inventory: the mechanism (a prose claim about the data that no check holds)

### vignettes/monthly-flow.Rmd (changed prose)

| Line | Claim | Held by | Verified value |
|---|---|---|---|
| 280 | Buck Creek: the balance's freshet is low | `stopifnot` `fr[wb] < fr[obs]` | 9.37 vs 16.37 m³/s |
| 280 | Buck Creek: the freshet is a month late | `peak_month` check | June vs May |
| 284 | The balance's peak is under half the gauge's May | `max(..) < max(obs)/2` | 10.34 vs 22.02 |
| 284 | The balance is above the gauge July–March | `stopifnot` | |
| 288 | Quick: high January–March | `stopifnot` 1:3 | 45/50/48 vs 38/31/31; April 85.7 < 93.4, so "March" is right |
| 289 | Quick: routed high July–August | `stopifnot` | |
| 286 | Both short by about a quarter | `stopifnot`, −20 to −33 | −23.7 / −22.6 % |
| 463 | Held out "as the fit stored them" | data script guards: `cv_share` = `cv_shares[[share_spec]]`, `share_spec` = `fits`, obs and obs_share identical to `cal`, scores re-derived | Local `cv_aet-cfu.rds` md5 9376f6a2… equals the bundle's provenance; `identical(cv_share, cv_shares$snow)` is TRUE |
| 566 | High in April and May, +7 % to +11 % | `stopifnot` | 10.7 / 6.8 |
| 568 | Within ±5 % in the other months | `stopifnot` | max abs 4.56 (Feb, printed +5 %) |
| 568–571 | 25 gauges routed does not reach, 19 in the Liard; −16 % in January, −62 % to −75 % in February–March | `stopifnot` | |
| 572 | Fewer than half within ±20 % in any month | `stopifnot` | max 44.4 % |
| 575 | "two snow terms from ERA5-Land" | `identical(prov$share_spec, "snow")` | `share_static$snow` is `snowmelt_doy_50`, `swe_max`; the manifest's `wet_balance` description names ERA5-Land |
| 577 | "The snow terms reduced the bias in winter and early spring" | **No check.** The bundle carries no base specification. | Verified from the stored `cv_shares`: Jan–Apr medians base 8.2/10.1/8.5/16.2 % → snow 0.1/4.6/3.4/10.7 %. Agrees with research §"Snow predictors" ("+8 to +16 → 0 to +11"). True today, held by nothing in the vignette. |
| 578 | 243 May–June peak gauges, 65 % below, median −13 % | `stopifnot` direction only | |
| 581 | Median NSE 0.73 over 315 | computed | Matches research 0.727 |
| 723 | Validation sentence | data script | Matches the guards in `data-raw/monthly_vignette_data.R` 62–77 |
| What's next | #16 and #68 removed | | Matches the CLAUDE.md gaps (#67, #6, fwapg#25) |

The research table's freshet row (241 gauges, 66.4 %, −12.7 %) and the vignette's (243, 65 %, −13 %) differ by definition: peak by monthly volume against peak by flow. The vignette says which it uses, and I reproduced 241 / 66.4 / −12.65 with the volume definition. This is not a defect.

### research/discharge_publish.md

Checked against the live manifest (fetched 2026-10-15 ~05:05 UTC).

| Claim | Verified |
|---|---|
| Built at acb820f, segment table 1718a3d | Manifest provenance |
| Province run e675918817, fit 20260717 | `sources[wet_balance].provenance` |
| crate 0.7.0 | Dataset schema version |
| 67 parts | Manifest: 43 `segment_monthly` (102,790,688 rows) and 24 `watershed_monthly` (41,904,356) |
| 1.84 GB | 1,836,285,495 bytes |
| "Row counts and picks are those of 7c62b9e" | The report's parts table is identical to the 032242f report (9e3ee30), which was byte-identical to 7c62b9e |
| Rebuild at eb17bca, 67 of 67 identical to acb820f | Report line 35. `git diff acb820f eb17bca -- R scripts` is empty. |
| Replaced 2026-10-15; about 4 min; 0 stale keys | Manifest built 02:06:57Z; progress.md upload 03:16:30–03:20:24 UTC, "0 stale keys deleted" |
| Reload "into the existing tables, so their indexes stayed" | True per code: indexes are made only when `created` |
| 46.1 and 21.6 min | progress.md timestamps |
| "about twice" | 1.93x and 2.02x |
| 39 / 17 GB against 20 / 8.5 GB | Internally consistent (2x) |
| Subquery 4,532,843 = 3,152,838 + 1,380,005 | Equals the report's reader lines |
| Comments name acb820f | The code writes the catalog's `provenance$wet_commit` |
| Causal "because …" | **Unsupported; see Findings** |

### research/water_balance_method.md:447

"Published with #77: build acb820f, uploaded 2026-10-15" agrees with the manifest and the upload time in UTC.

### CLAUDE.md, monthly-flow paragraph

- The gaps #67, #6 and fwapg#25 match "What's next".
- The stored-month refusal described matches the script.
- No other claim changed.

### data/checks/discharge_publish_20260717.txt

- Only lines 3 and 35 changed.
- Line 35's acb820f matches the manifest.

## Code (data-raw/monthly_vignette_data.R)

The guards fail closed:

- A `cv_aet` file without `cv_share` but with `cv_shares` makes `$` partial-match to a list, whose `dim()` is NULL, so it stops.
- `fits$share_spec` does not partial-match `share`.
- `shipped_heldout()` still pins `code_md5` for `fits.rds` and `cv_aet`.

`segment_values.rds` and `segment_map.rds` were built at 5ad20df, and their scripts are unchanged since. The segment-discharge vignette's checks pass on them.
