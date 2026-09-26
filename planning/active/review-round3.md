# Code review, round 3: staged diff for wet#2 (mechanism sweep)

## Findings

- **[severity: bug]** R/wet_upstream_mean.R:64-79: when `upstream_area` is supplied, `coverage` is `s$area_cov / up`, where `up` is the override (fwapg's stored table in every caller). So the stale snapshot is used as the denominator for a *fraction of real ground*, not only for the fwapg-parity value.
  - Measured on the whole Fraser (`wet_ws_fetch(conn, "100")`: 644,710 polygons, with the complete `wet_upstream_irregular()` pairs, `value = 1` and `cover = 1` everywhere, `upstream_area` = the stored table):
    - 1,155 watersheds report `coverage` above 1 (maximum **251.6**);
    - 576 watersheds report `coverage` below 1 although every polygon is covered.
  - It is the same in `denom = "covered"`, where `up` has no other role: there the override changes only `coverage` and `upstream_area_m2`.
  - The docs describe `coverage` as how much of the upstream area has data, and say the override exists to reproduce fwapg's discharge. fwapg has no coverage column, so reproducing fwapg is no reason to put the stale denominator into it.
  - Both scripts already work around this. `mad_parity.R:120` and `:156` (and `mad_basin.R`, through its `live` and `area_cov` builds) run a second, un-overridden build just to get a correct `coverage`. Any other caller that passes `upstream_area` gets silently wrong coverage, the same failure round 2 fixed in the script.
  - Fix: always compute `coverage = s$area_cov / s$area` (the accumulated area), and apply the override only to `value` (in `"total"` mode) and `upstream_area_m2`. The script workarounds then become redundant, but they stay correct.

- **[severity: fragile]** R/wet_upstream_sums.R:101-109 (and the roxygen at lines 23-24): the completeness check is necessary but not sufficient, yet the docs promise that pairs from "a partial fetch" are an error.
  - `setdiff(irregular, irregular_pairs$id_up)` only proves that every irregular polygon appears in at least one pair.
  - A partial table that keeps each irregular polygon's self pair, but loses some of its downstream `a` rows, passes the check. Every downstream watershed that lost its pair then silently leaves out that polygon's area and values.
  - Verified on `random_ws(7, irregular = 4)` (14 polygons, 3 irregular, 13 true pairs) against `brute_upstream()`:
    - only the 3 self pairs: 6 of 14 sums wrong, with no condition raised;
    - self pairs plus half of the others: 5 of 14 wrong, with no condition raised.
  - Package-produced pairs are not affected: `wet_upstream_irregular()` returns every `a` for each `b`, because `a` is not restricted to the basin.
  - Paths that trigger it:
    - caller-side filtering by the `a` side, e.g. keeping only a group's `watershed_feature_id` while `ws` is the whole basin;
    - chunked or limited fetches split by row rather than by `b`;
    - pairs from a different DB snapshot.
  - Fix, either of:
    - make the check exact: for each irregular `b`, the candidate `a` are only the rows whose `wscode` equals `b`'s or is an ancestor of it, a handful per `b`, so the expected pair count per `b` can be computed from `ws` with the `FWA_Upstream` predicate;
    - or narrow the docs to what the check actually guarantees (a missing irregular polygon is an error; missing downstream rows are not detected).

- **[severity: fragile]** R/wet_upstream_sums.R:29-30, 37: `wet_upstream_sums()` sums only over the rows of `ws`. It does not document that `ws` must be upward-closed (every polygon upstream of any row must itself be a row, for example a whole basin from `wet_ws_fetch()`).
  - `wet_upstream_mean()` documents this ("every polygon of the basin"). The exported `wet_upstream_sums()` does not, and nothing checks it.
  - Two neighbouring APIs invite the mistake, because both work per watershed group:
    - `wet_upstream_pairs()`, the documented oracle to compare against;
    - `wet_ws_geom()`.
  - A group-level `ws` passes every guard in these cases, with no condition raised:
    - `irregular_pairs = NULL` and no irregular polygons in the group;
    - pairs built for that subset.
  - Verified: `random_ws(7, irregular = 4)` with one deep subtree removed, and exact pairs for the remainder, gives 3 of 12 sums wrong against the full-basin truth, with no condition raised.
  - When the pairs come from the basin, the `id_up %in% irregular` check does catch it, but only if the basin has an irregular polygon outside the subset.
  - Fix: state the requirement in `@param ws` and the description (as `wet_upstream_mean()` does).

## Mechanism enumeration

**Mechanism.** A table that crosses a function or DB boundary is trusted to be *complete*, *unduplicated*, *from the same basin* and *current*. A positional `match()`, an aggregating `rowsum()`/`tapply()`, a `merge()` or an SQL `INNER JOIN` then fills what the table lacks (with NA→0 or "uncovered"), drops it, or double-counts it. The output still has one plausible number per row. The narrow forms are:

- completeness proved by a necessary condition, not an exact one;
- a stored snapshot used where the live quantity is meant.

Each site below is listed with what happens if its table is **partial / duplicated / from another basin / stale**. Status is one of **Detected**, **Tolerated** (deliberate and documented) or **Silent**, which means a finding.

### R/wet_upstream_sums.R

| Line | Site | Partial | Duplicated | Other basin | Stale | Status |
|---|---|---|---|---|---|---|
| 42, 56, 84 | `ws` itself (`rowsum(match(kb, uk))`, `match(ka, ka[qa])`) | not upward-closed: sums miss the ground outside `ws` | `watershed_feature_id` duplicates: stopifnot. Distinct ids that share a code pair are intended and handled | n/a (it *is* the basin) | n/a | Duplicates **Detected**. Partial **Silent**, and documented only in `wet_upstream_mean` (finding 3) |
| 87-92 | `irregular_pairs = NULL` | – | – | – | – | Warns when irregular polygons are present. **Detected** |
| 95 | `id_up %in% irregular` | – | – | pairs from a larger or other basin: error | pair names a polygon that is regular now: error | **Detected** |
| 98 | `anyDuplicated(pairs[, c(a, b)])` | – | error | overlapping-basin rbind: error | – | **Detected** |
| 105 | `setdiff(irregular, id_up)` | a `b` missing entirely: error. A `b` present with only some of its `a`: passes | – | smaller basin: error | – | Partly **Silent** (finding 2) |
| 110-116 | `match(a)`, `match(id_up)`, `rowsum` | `a` outside `ws`: dropped | excluded by 98 | – | pair that is no longer upstream under current codes: added | `a` outside `ws` **Tolerated** (documented tradeoff). Snapshot mismatch between `ws` and pairs cannot be detected here; the same DB/basin fetch is assumed |

### R/wet_upstream_mean.R

| Line | Site | Partial | Duplicated | Other basin | Stale | Status |
|---|---|---|---|---|---|---|
| 44-47 | `match(ws id, values id)` | absent: counts as uncovered | stopifnot | ids don't match: all uncovered, `value` NA, `coverage` 0 (visible) | ids are stable, so this is harmless | Partial **Tolerated** (documented). Duplicates **Detected** |
| 60 | `wet_upstream_sums(q, ..., irregular_pairs)` | inherits all of the above | | | | as above |
| 64-71 | `upstream_area` override, `match()` | error (70) | error (66) | missing rows: error | used as the `value` denominator in `"total"` | `value`: **Tolerated** (documented fwapg reproduction) |
| 79 | `coverage = area_cov / up` with the override | – | – | – | stale denominator in a coverage fraction (Fraser: max 251.6, 1,731 wrong) | **Silent** (finding 1) |

### R/wet_ws_sample.R

- **:32-36** (data.frame points): one `extract` row per input point, in the same order, and `id` is taken from the same frame. Duplicated ids pass straight through and are then caught by `wet_upstream_mean`'s stopifnot. **Clean.**
- **:55-57** `tapply(..., factor(ID, levels = seq_along(id)))`: the IDs are the row indices of `poly`, which `project()` keeps in order. A polygon with no `extract` rows gets `tot` NA, so `cover` is 0 and `value` is NA. The raster is extended beforehand, so a partial raster makes `cover` fall rather than being dropped. **Detected** (shows as `cover`).

### R/wet_ws_fetch.R and R/wet_upstream_pairs.R (DB boundaries)

- **`wet_ws_fetch`:31-35**: NULL-coded polygons are dropped with a warning. The irregular SQL never returns them (`NOT NULL <@ ...` is NULL), so `ws` and the pairs agree. **Detected.**
- **`wet_upstream_irregular`:54-63**: the `a` side is unrestricted, so every `a` is returned for each `b`. It is complete by construction. **Clean.**
- **`wet_ws_geom`:86-92**: ids are assigned positionally from the same result set. A group that spans another basin contributes rows whose ids are not in `ws`, and `wet_upstream_mean`'s `match` ignores them. **Tolerated.**
- **`wet_upstream_pairs`:22** `INNER JOIN fwa_watersheds_upstream_area`: a watershed with no stored row would be dropped silently. In the local DB, the stored table has a primary key on `watershed_feature_id`, and all 3,245,453 polygons have a stored row. The only caller (`mad_parity.R`) would already have stopped at the `upstream_area` override for any such watershed. It uses the stored area by design (oracle of fwapg's formula). **Tolerated** (unreachable today, and the intended oracle semantics).

### R/wet_pcic_annual.R

- **:17**: duplicated or NA years: error.
- **:26-29**: `compareGeom` across years: a different grid is an error.
- An incomplete year is an error in `wet_runoff_annual`.
- The per-year cache (`wet_pcic_fetch`, not in this diff) is keyed on run, variable and time/lat/lon indices, and is written atomically through a temp file and rename.
- **Detected / clean.**

### scripts/mad_parity.R

- **:67-73** `ws`, `irr`, `stored`: all are fetched with the same `basin` code from the same connection. `stored` has a primary key and a row for every polygon. **Clean.**
- **:79-80** values only for polygons in the bounding box; everything else is uncovered. This is guarded for the group at :94 on `live$coverage`. **Detected.**
- **:90** `parity` with `upstream_area = stored`: the stale denominator is deliberate for `value`/`mad_m3s`. **Tolerated** (accepted tradeoff).
- **:100-109** pairwise cross-check: `match(id_up, cen)` treats out-of-bbox as 0, the same as `wet_upstream_mean`.
  - Both sides divide by `stored`, so staleness cancels.
  - A group watershed missing from `pairs` (no stored row) would have stopped at :90 already.
  - `max()` without `na.rm` makes any NA fail the stopifnot.
  - **Detected.**
- **:120, :123** `match()` between `parity` and `live`: both have one row per `ws` row. **Clean.** (The :120 workaround is correct but only needed because of finding 1.)
- **:121** `merge(ref, parity, all.x = TRUE)`: `parity` is unique by id, so there is no row blow-up. LUT rows outside `ws` show as NA and are counted in the printed "wet has value" count. **Detected (visible).**
- **:150-151** area values for groups that have a centroid in the bounding box. Anything else counts as uncovered, and `min coverage` is printed. **Tolerated** (sensitivity output, not guarded).
- **:154** sensitivity builds with `upstream_area = stored`:
  - `mad_mm` is compared against the `parity` build, which uses the same denominator, so the comparison is like for like.
  - In the `covered` modes, `mad_m3s` in the CSV is the covered mean multiplied by the stored area.
  - **Tolerated** (same tradeoff as parity mode).
- **:156** coverage from a live build. **Clean** (a workaround for finding 1).

### scripts/upstream_area_check.R

- **:33-38** `ref` from the stored table: it is used only as a first-pass reference, which is its stated purpose.
- **:44** `merge(all = TRUE)`: rows missing on either side are counted and printed, and the primary key rules out duplicates.
- **:42** `suppressWarnings` on the deliberately uncorrected run.
- **:64** the basin mouth row is always re-checked.
- **:73** the id list goes in as integers (the DB column is `integer`, so `paste` gives no `1e+05`).
- **:75** inner `merge` with the live join: every `a` is upstream of itself, so nothing drops.
- Minor, display only: `sum(rel_ref <= 1e-9)` would print NA if the basin-mouth row had no stored row (impossible with the current primary key and full coverage).
- **Stale by design, then re-checked live: clean.**

### Every use of fwapg's stored `fwa_watersheds_upstream_area`

1. `R/wet_upstream_pairs.R:20-22`: oracle denominator and inner join. Tolerated, see above.
2. `scripts/mad_parity.R:69-73` → `:90` (parity value, tolerated) and `:154` (sensitivity value, tolerated).
3. `scripts/mad_parity.R:104`, through `pairs$upstream_area_m2`: cross-check denominator. It cancels against :90.
4. `R/wet_upstream_mean.R:79` when a caller passes it: **coverage denominator, silent (finding 1)**. Every current script overwrites the result with a live build (`mad_parity.R:120`, `:156`; `mad_basin.R` takes coverage from its live builds).
5. `scripts/upstream_area_check.R:33-38`: first-pass reference only; mismatches are re-checked against live `FWA_Upstream`.

### Verification notes

- `devtools::test()`: all tests pass.
- DB (local fwapg):
  - `fwa_watersheds_upstream_area` has a primary key on `watershed_feature_id`, with 3,245,453 rows, equal to the number of polygons;
  - `watershed_feature_id` is `integer`.
- Findings 2 and 3 were checked on `random_ws(7, irregular = 4)` against `brute_upstream()`. Finding 1 was checked on the full Fraser basin (`"100"`).
