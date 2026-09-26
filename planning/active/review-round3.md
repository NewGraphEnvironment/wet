# Code review, round 3 (staged diff, #1 Phase 3/4)

## Findings

- **[severity: bug]** R/wet_upstream_mean.R:43 (`num_total <- tapply(v * a, key, sum)`). With `denom = "total"` the numerator ignores `cover`. So when a polygon has only partial cover (which only `method = "area"` produces), its uncovered ground is filled with the mean of its covered part. A polygon with no cover at all adds 0 instead. The same missing ground therefore counts as the covered mean or as zero depending on whether a sliver of the polygon touches data. That contradicts this mode's own documented premise, "partial coverage biases the mean low".
  - Checked in R: two 100 m² polygons with upstream area 200, polygon 1 at value 10 with cover 1, polygon 2's covered part at 10.

    | cover of polygon 2 | `value` | `coverage` |
    |---|---|---|
    | 1 | 10 | 1 |
    | 0.5 | 10 | 0.75 |
    | 0.01 | 10 | 0.505 |
    | 0 | **5** | 0.5 |

    The result stays at 10 all the way down to 1% cover, then halves at 0. Nothing in the result distinguishes the 1% case from full cover.
  - Where it reaches: the exported `method = "area"` + `denom = "total"` combination, and the `area / total` row of `scripts/mad_parity.R`'s sensitivity section. That row is presented as "the effect of area-weighted sampling", but it also silently changes how uncovered ground is treated.
  - Where it does not reach: the parity build (`centroid`/`total`), where `cv` is always 0 or 1, so `v * a == v * a * cv` wherever `has` is true. SALR also has `coverage == 1` in every output (I checked `SALR_area_total.csv`), so no number reported so far is affected.
  - Fix: use `tapply(v * a * cv, key, sum)` for the `"total"` numerator. Uncovered ground then adds nothing whether it is a whole polygon or part of one. The result is unchanged for centroid sampling, so fwapg parity holds.

- **[severity: fragile]** scripts/mad_parity.R:130-138. The sensitivity summary is an inner `merge()` followed by `na.rm = TRUE` on `r = (s - p) / p`. A watershed that one build values and the other leaves `NA` therefore drops out of the median, the 1-99% range and the "|change|>5%" share. That affects:
  - `area` giving a value where `centroid` gave `NA` (centroid on a fill cell);
  - `covered` recovering a value that `total` left out.

  Those are the largest changes the proposed methods make, and the summary cannot see them. No count of them is printed. It is harmless on SALR because no NA occurs on either side, but on any group touching the edge of PCIC coverage (Peace/Fraser/Columbia only) it will understate the effect of the method change. Printing the number of NA-to-value and value-to-NA transitions per method pair would close it.

## Mechanism enumeration

### The mechanism

Both earlier bugs came from one assumption: that **the rows or values present stand for the population the quantity is about.** Where something is absent (no row, no value, no byte), the code either:

- **(a)** gave it a neutral number: 0 added to a sum, 0 as a result, or a raw 0 decoded as a real value; or
- **(b)** left it out of a denominator or summary, which is the same as giving it the mean of what is present.

Round 1 bug 1 was (a): no upstream value became `0 / up = 0`. Round 1 bug 2 was (b): the cover denominator was the sum of fractions over the rows `extract()` returned, not over the polygon.

The test for every site below: **what is the population, who produced the denominator, and what does absence turn into?**

### Every site in the diff

**R/wet_upstream_mean.R**

| Line | Site | Verdict |
|---|---|---|
| 34 | `match(pairs$id_up, values$watershed_feature_id)`: an id missing from `values` becomes `NA`, never a value | Correct. Absent becomes `has = FALSE`. `match()` would pair `NA` with `NA`, but `id_up` comes from an inner join on a primary key and is never `NA`. |
| 38 | `cv[!has \| is.na(cv)] <- 0`: absent or `NA` cover becomes 0 | Correct in the pipeline, because `wet_ws_sample` never emits `NA` cover. With hand-built input, a value with `cover = NA` counts fully in `total` but is dropped in `covered`. That input is outside the documented contract. |
| 39 | `v[!has] <- 0`: absent value becomes 0 in the numerator | Correct: this is `SUM` skipping `NULL` in fwapg `discharge03_wsd.sql`. The all-absent case is caught by line 52. |
| 43 | `num_total = sum(v * a)` | **Finding 1.** Absent ground inside a polygon takes the covered mean; a wholly absent polygon takes 0. |
| 44-45 | `num_cov`, `area_cov`, weighted by `a * cv` | Correct. The numerator and denominator come from one population, the covered ground. |
| 42 | `key <- factor(pairs$watershed_feature_id)`: `factor()` drops `NA` ids | Correct. `a.watershed_feature_id` is a primary key and is never `NA`. Every level has at least one row, so no `tapply` cell is `NA` from an empty group. |
| 46 | `up <- tapply(upstream_area_m2, key, [, 1)`: the denominator comes from a different producer (fwapg's precomputed table) than the numerator (`ST_Area` over `FWA_Upstream` pairs) | Correct. `fwa_watersheds_upstream_area.sql` is the same `FWA_Upstream` join summing the same `ST_Area`, so it is one population. Checked: SALR `coverage` from the `centroid/covered` build is 1 to within 4e-15, so `sum(a) == up`. |
| 47, 52 | `any_value`: no upstream value gives `NA`, not 0 | Correct (round 1 fix). `has` is never `NA`. |
| 50 | `ifelse(area_cov > 0, ..., NA)` | Correct. |
| 55 | `coverage = area_cov / up` | Correct. The numerator is covered ground and the denominator is total upstream ground. |

**R/wet_ws_sample.R**

| Line | Site | Verdict |
|---|---|---|
| 28-31 | centroid: `extract()` on points | Correct. A point beyond the extent gets an `NA` row, not no row, so `cover` is 0 (tested). `NaN` from `wet_runoff_annual` (see below) also gives `is.na` TRUE, so `cover` is 0. |
| 38 | `extend(... snap = "out")`: pads with `NA` so `extract()` returns rows for off-raster ground | Correct (round 2 checked 300 random rectangles). |
| 42 | `tot` = sum of `fraction` over all rows, including padded ones | Correct. The denominator is now the whole polygon in cell units, whatever the data covers. Fractions are in degree² space, which is the same metric as the numerator. Cell-area change with latitude inside one fundamental watershed is negligible, and fwapg uses no area weighting at all. |
| 43-47 | `cov[is.na(cov)] <- 0`, then value `NA` where `cov == 0` | Correct. A polygon with no valued cell gives `NA`, not 0. |
| 48 | `cover` is 0 when `tot` is `NA` or 0 | Correct. After `extend()` a non-empty polygon always has rows. |

**R/wet_runoff_annual.R**

| Line | Site | Verdict |
|---|---|---|
| 20-26 | Per-year denominator: `n` (days present) compared with calendar days | Correct. The expected count comes from the calendar, not from the data, and duplicates are refused first. |
| 27 | `tapp(fun = "sum")` with `na.rm = FALSE`: one missing day makes the year `NA` | Correct, and the safe direction. Checked: one `NA` day gives `NaN` for the cell. `cdo yearsum` skips missing days (checked with cdo: 3 rather than 4), so fwapg would bias such a cell low where wet gives `NA`. The two agree whenever the PCIC mask is static. The SALR subset has zero `NA` over all 10957 days × 255 cells, so this path was not exercised by parity. The doc's "the same as `cdo -timmean -yearsum`" holds only for cells with no partial-missing days. |
| 28 | `mean(yearly)`: the denominator is years present | Correct in context. `wet_pcic_fetch` always returns one contiguous range, so a missing whole year cannot occur on the documented path. A caller who `c()`s non-adjacent years gets a mean over a period the output does not name. |

**R/wet_pcic_index.R**

| Line | Site | Verdict |
|---|---|---|
| 32-37 | `cell()` clamps edge indices, so part of a bbox beyond the grid is silently excluded | Correct. There is no data there, and `wet_ws_sample` then counts that ground as uncovered (padding in area mode, `NA` in centroid mode). A bbox wholly off the grid is refused (line 42). |
| 47 | Time index from `end` is not checked against the dataset length | Correct. An out-of-range OPeNDAP constraint is an HTTP error, which is loud. |

**R/wet_pcic_fetch.R**

| Line | Site | Verdict |
|---|---|---|
| 35-36 | `wet_is_netcdf()` checks magic bytes, a proxy for "complete file" | Correct in practice, but not because of this check. Verified that a classic NetCDF 100 bytes short passes the check, opens with all 10957 layers and the right last date, and reads its missing bytes as raw 0, which unpacks to `add_offset` = **88.57 mm/day** in 49 cells. That is +2.95 mm/yr on the annual mean, with no error. What prevents it: PCIC sends `Content-Length` (checked: HTTP/2, `content-length: 6284`, pydap 3.2.6), and R's libcurl `download.file()` raises an error on a partial transfer (checked against a local server that under-delivers). The `on.exit` then unlinks the temp file. Larger truncations are also caught downstream by the duplicate-date and incomplete-year checks. Not flagged. |
| 28 | Cache hit returns without re-validating | Correct. Only validated files are ever renamed into the cache. |

**R/wet_upstream_pairs.R**

| Line | Site | Verdict |
|---|---|---|
| 21-22 | `INNER JOIN fwa_watersheds_upstream_area` drops a watershed with no area row | Correct. It matches fwapg, and the result is absence, not 0. Checked on the local database: 0 of all `fwa_watersheds_poly` lack an area row. |
| 23-25 | `INNER JOIN ... ON FWA_Upstream(...)`: a polygon with `NULL` codes would match nothing, not even itself | Correct. There are 0 such polygons province-wide in the local database. |
| (wet vs fwapg) | wet keeps upstream polygons with no value; fwapg's inner join to `discharge02_load` drops them | Equivalent. Absent contributes 0 to the sum on both sides, both use the same `up` denominator, and all-absent gives `NA` in wet against no row / `NULL` in fwapg. |

**R/wet_mm_to_m3s.R**

| Line | Site | Verdict |
|---|---|---|
| 13 | `NA` in gives `NA` out; 0 only from a real 0 | Correct. The constant 31536000000 is 1000 × 365 × 86400, which matches fwapg. |

**scripts/mad_parity.R**

| Line | Site | Verdict |
|---|---|---|
| 37, 80-81 | bbox subset against the upstream polygons, which extend beyond the group | Correct. It is guarded: the script stops if any sampled polygon lies outside the fetched bbox. |
| 70-79 | Sampling set comes from `pairs$id_up` | Correct. `setequal()` asserts that every upstream polygon was sampled, so none is silently uncovered. |
| 56 | `runoff + baseflow`: `NA` in either gives `NA` | Correct. It matches cdo `add`. |
| 93-98 | `JOIN fwa_streams_watersheds_lut` drops segments without a lookup row | Correct. fwapg's own build uses the same inner join, and the lookup is 1:1 (4,538,224 rows, all distinct). No SALR `linear_feature_id` is duplicated after the merge. |
| 100 | `merge(all.x = TRUE)` | Correct. Segments without a wet value become `NA` and show in the "wet has value" count. Extra wet rows (order-8+ rivers) are dropped. |
| 104 | `both` excludes `NA` on either side and `mad_m3s_fwapg == 0` from every parity percentage | Correct for SALR (the counts line shows 9000 in the lookup = 9000 in fwapg = 9000 in wet = 9000 compared, with no zeros). Off-SALR, the excluded cases stay visible only through that counts line. fwapg rounds to 5 decimals, so headwaters under 5e-6 m³/s are stored as 0 and fall out of the percentages. They are visible as "fwapg has value" minus "compared". Not flagged, because the counts are printed beside the percentages. |
| 130-138 | Sensitivity summary over the intersection only | **Finding 2.** |

### Also confirmed, not part of the mechanism

- **Fill values:** PCIC's `_FillValue = -32767s` on packed shorts is read as `NA` by terra 1.9.46. I checked by writing a fill into a copy of the cached file: exactly one `NA` appeared, in the right cell.
- **Tests:** the test suite passes (`devtools::test()`).
