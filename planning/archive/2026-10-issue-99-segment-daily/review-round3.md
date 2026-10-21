# Code-check round 3: #99 segment_daily (diff 40560dc...HEAD, after b69e2c8)

## Checklist read

- code-check.md: all 14 H3s under `## Mechanisms`, prose in full (table rows and evidence blocks skipped). The other 30 H3s (Rules that stand alone, Security, Spreadsheets and PDFs): index only.
- code-check-r.md: all 111 index lines, and 7 sections in full: "`data.frame()` recycles a scalar against a zero-length column", "`paste()` with a zero-length argument", "Postgres row order is never fixed", "`ifelse()` with an all-NA test", "`match()` treats NA", "A database driver's value is not a base R type", "`bind_rows()` of all-`NULL`". The other 104: index only.
- code-check-shell.md: index only (67 lines). The diff has no shell code; git and aws run through `system2()` with `shQuote()`.
- code-check-spatial.md: index only (92 lines). The diff does no spatial operations.

## Mechanism

Two shapes produced all six earlier findings.

1. **The fixture is one population.** The fixture tree is one drainage (100) and one watershed group (SALR, or BULK in the article) that holds both sources. So every path assumes that each side has rows and that each named key exists. The cases it cannot reach are a group with one source (47 groups have no routed segment), a group with no part, and a key that matches nothing. That produced r1 #3, r2 #1 and, through its fix, r2 #2.
2. **A condition stands for a property.** A one-step difference stood for "a rounding tie" (r1 #1). A digit-count window stood for "Postgres's 15-digit tie" (r1 #2). The `"; subset "` marker stood for "a groups subset" (r2 #2). The same shape holds one level down: "parts were selected" stands for "the named groups are in the data" (finding 1 below).

The r1 and r2 fixes for the reader (#3, then r2 #2) turned an absent source from an error into NA, keyed on the groups marker. Where the subset does not name a real group, that exemption hides the empty load finding 1 describes.

### Where the mechanism reaches, place by place

| place | one source / none / no match | holds? |
|---|---|---|
| segment_daily_output.R, `if (nrow(b0))` / `if (nrow(r0))`, `do.call(rbind, rows)` | a group with one source gives one element. `sg` is never empty, and only two sources exist | holds |
| segment_daily_output.R, `valued` empty for a code (0-row `q_mon`, `wet_shape_predict`) | not reachable: no basin in data/checks/wb_output_20260717.txt has every watershed NA (the largest is 915, with 12,924 NA of 94,810) | holds |
| segment_daily_output.R, the `tally` and pieces merge, `by_group` rows = 365 x (routed + balance) | groups with only balance segments, and a group split across codes | holds |
| segment_daily_output.R, `vs_month` and `clamp` in a code with no routed segment (800, 945, 990) | the counters stay at 0; the only stop is on `differing` | holds |
| segment_daily_output.R, `n_weights_unpublished == n_unplaced` | `routed_seen` is a subset of the weights and of the routed table, so this tests \|weights\| == \|distinct routed segments\|: a count standing for a set. It fails toward abort | holds (proxy, fails toward abort) |
| segment_daily_output.R, the month guard `tie` (`d <= 1.000001e-5`) | at a one-step `d`, the float error in `d` exceeds 1e-6 of a step only above about 4.5e4 m3/s. That is far above any routed month (the Fraser part's largest is 8,517.5), and it fails toward abort | holds |
| discharge_publish.R, the daily part writer `if (!nrow(p)) next` | | holds |
| discharge_publish.R, `day_seen` (r2 fix) | `rep()` per side, and `c()` of numeric(0) with integer | holds; correct |
| discharge_publish.R, `if (nrow(pr))` / `if (nrow(pb))` | | holds |
| discharge_publish.R, `wet_values_compare()` of 0-row `read_part()` against 0-row `st[...]` (four columns x two sources) | keys are numeric(0) and `all(logical(0))` is TRUE, so it returns c(0, 0, 0) | holds |
| discharge_publish.R, `seg_ids()` over a missing monthly part | `read_part()` returns 0 rows | holds |
| discharge_publish.R, `day_checks` length 6, `n_vc()` over a check absent from `vc_sum` | an absent check makes `vapply` error rather than pass | holds |
| discharge_publish.R, `hive_day` with a source holding no part | only the sums are used | holds |
| discharge_publish.R, `publish_part_write(rows_per_group =)` | one group per daily part is asserted | holds |
| R/wet_segment_monthly.R `wet_segment_parts()`, a source with no part in the groups (r1 fix) | a typed 0-row frame, then NA | holds |
| R/wet_segment_monthly.R `wet_segment_pg()` `by_groups` (r2 fix) | the regex matches only the `groups` arm of `where`. It is correct for that, but see finding 1. It also reads the table-wide comment for a per-scenario fact: a groups load of one scenario exempts another. Not reachable while only `historical` exists | holds for the named case |
| R/wet_db_load.R, "no parts for groups" stop | **does not hold**: finding 1 | **no** |
| data-raw/segment_vignette_data.R, the daily and monthly reads (r2 fix) | both are verified before and after. The daily read takes `wet_catalog()` live rather than `cat_pub`, but the verify after it is against `cat_pub`'s md5s, so a republish between them is refused | holds; correct |

## Findings

- **[severity: fragile]** R/wet_db_load.R:76-80 with :113, and R/wet_segment_monthly.R:213. `wet_db_load(groups =)` guards "the groups exist" by checking that some part was selected. `wet_parts_groups()` keeps every drainage-keyed part whatever `groups` says, so for the monthly datasets that stop can never fire.
  - **Monthly load.** A load naming a group that is in no part (a misspelt code, `"SALT"` for `"SALR"`) deletes the scenario (line 113), loads 0 rows and returns without error. The reader then gives every segment NA, because round 2's `by_groups` exemption now skips the "has no rows for scenario … source …" stop for any groups subset. The only signal left is the subset warning, which describes a correct subset.
  - **Daily load.** The stop fires only when every named group is missing: `groups = c("BULK", "BLUK")` loads BULK and drops BLUK without a word.
  - **Probe.** Run in a copy against the local fwapg, in a `wet_test_probe` schema with the fixture tree: the table went from 52 rows to 0 with no error, and `wet_segment_monthly` read 26 of 26 values as NA, with only the subset warning.
  - **Why the stop was there.** Before round 1's fix the reader would have stopped on an empty table. So the r1/r2 fixes made this case silent rather than loud.
  - **Fix.** Inside the transaction, before the commit, select the distinct `watershed_group_code` loaded for the scenario and stop unless it holds every named group (the `stop()` rolls back the DELETE). Or check `groups` against the FWA's or the parts' group codes before fetching.

No other real issues found.

## Round 2 fixes, checked

- `day_seen` (discharge_publish.R:277-280): correct for empty, one-sided and two-sided groups. `c(numeric(0), <integer>)` gives numeric, so `setequal()` against `seg_ids()` still matches by value.
- `by_groups` (R/wet_segment_monthly.R:213): matches exactly the comment that `wet_db_load(groups =)` writes (`… AND watershed_group_code IN (…)`), and not a `months`, `doys` or `pick_only` subset. The new test (a `doys` subset with a source absent is an error) passes. Its reach past that case is finding 1.
- data-raw monthly read: `vd_verify(mon_parts)` wraps the read, and `mon_parts` is every historical segment_monthly part, both sources.

## Also checked, clean

- Tests run in a copy (`NOT_CRAN=true`, `testthat::test_file`, failed/error/skipped all 0):

  | test file | passed |
  |---|---|
  | test-wet_routed_days | 36 |
  | test-wet_segment_daily | 30 |
  | test-wet_values_compare | 24 |
  | test-wet_catalog | 37 |
  | test-wet_db_load | 29 |
  | test-wet_segment_monthly | 47 |

- Routed daily `runoff_mm` uses the same area as the monthly row (the lut watershed's `upstream_area_m2`, in mm/day), and is NA wherever the month-0 row's is (off its own line, or no area).
- Row recycling in `q_day[ir, ] * to_mm[iw]`, `qd * area_mm` and `route_by_set()`'s `* w$share` is row-wise, because the vector has the matrix's row count.
- `routed_daily_inputs()` orders on unique keys, and an empty `upstream_subids` gives `""`, then `integer(0)`, then a zero sum, in both routing paths.
- The PUBLISH skip by ETag reads the public URL. A 404, a 403 or a multipart ETag is "not ok", so the part is uploaded.
- `vd_published()`'s `re_seen` is anchored at `^historical`, so the new `segment_daily …` reader lines stay out of the segment_monthly reader counts.

## Triage (main session)

- The finding (a named group no part holds empties the table silently): fixed in `wet_db_load()`, inside the transaction, so the refusal rolls back the delete; tests for a daily and a monthly load; disabling the guard turns 3 tests red.
- The loop ends here by enumeration: the mechanism table above walks every place the two shapes reach in the build, the publish check, the readers and the article data script, and this was the only open one.
