# Code-check round 1: branch 107-monthly-flow-article-chinook-windows-fro (#107)

Diff reviewed: `branch.diff` (merge-base 5bc6cc2 → HEAD 9175569), in full. Changed files read at HEAD
in full: `data-raw/monthly_vignette_data.R`, `tests/testthat/test-vignette_data.R`,
`vignettes/monthly-flow.Rmd`, the `monthly-flow` paragraph of `CLAUDE.md`. Supporting code read:
`scripts/vignette_data_lib.R`, `scripts/pcic_routed_lib.R` 130–200, `scripts/discharge_publish.R`
1–100 and 515–619, `R/wet_routed_days.R`, `R/wet_shape_predict.R`, `R/wet_values_compare.R`,
`R/wet_flow_window.R`, `R/wet_doy_month.R`, `data-raw/segment_vignette_data.R` 155–199,
`R/wet_segment_daily.R` 44–48, `scripts/wb_shape_daily.R` (the saved fields). Bundle inspected
read-only (`str()` and the `published_check` table).

## Checklist read

- `code-check.md`: every H3 under `## Mechanisms` read in full (prose, table rows skipped); the
  stand-alone, Security and Spreadsheets sections read as index only.
- `code-check-r.md`: 25 of ~118 headings read in full — data-raw loads the source tree; tests that
  silently do not run; duplicate knitr chunk label; moving prose into a chunk; `$` partial match;
  DBI driver values / integer64; `paste()` zero-length; `strsplit()` trailing field; `nzchar(NA)`;
  `sort()`/`order()` collate; a library call dispatching on a global option; `identical(-0, 0)`;
  `vapply(USE.NAMES = FALSE)`; `stats::aggregate()`; `match()` on NA; `unlist()` of `split()`;
  `tolerance` is relative; `[[` on a named atomic; `data.frame()` recycles against zero length;
  Postgres row order; range totals from running sums; `pkg::` in a test; `c()` dispatch;
  `bind_rows()` of NULL; regenerated binaries churn. The other ~93 read as index lines only.
- `code-check-shell.md`: index only (the diff adds no shell).
- `code-check-spatial.md`: index only (the diff adds no spatial code).

## Probes run (read-only, repo at HEAD)

- `inst/vignette-data/segment_values.rds` on HEAD and on 5bc6cc2 both carry `daily`; the test's
  `expect_named` change is a correction of a test that was already stale on main, not a regression.
- `data/checks/segment_daily_output_20260717.txt` has exactly one `^daily: ` line, and it equals the
  bundled `provenance$daily_fingerprint`.
- Chunk labels in `vignettes/monthly-flow.Rmd`: no duplicates.
- `duckdb`, `knitr`, `ggplot2`, `gq` are all in `Suggests`, so the citation chunk's
  `requireNamespace()` guard holds on CI.
- `wet_segment_daily()` accepts `groups =` and `catalog =` as called.
- Bundled `published_check`: 8 rows, all `differing == 0`; row 6 compared 1,095 (= 3 × 365), row 7
  730 (= 2 × 365), row 8 36 (= 3 × 12), matching the script's `n_src`.
- `shape_daily.rds` is written with `method, fit, static, aet, release, code_md5, shape_code_md5`,
  the fields the script reads.
- Routing again through `wet:::wet_routed_raw()` on a subset fold is the build's own path (the fold
  is per-sub-basin and `rowsum(reorder = FALSE)` keeps `upstream_subids` order), so the tie
  allowance is a no-op by construction — accepted tradeoff (2), recorded here only.

## Findings

- **[fragile]** `vignettes/monthly-flow.Rmd:763-765` — the Validation prose hardcodes a count the
  data does not pin: "at `r and_text(st_label[prov$shape_stations])`, the gauges whose watershed
  predictors the copy of the fit held; **the third segment's** days rest on the publish report's
  daily check." `data-raw/monthly_vignette_data.R:307-311` takes `held` from whatever
  `upstream/400.rds` holds and asserts only `any(held)`, and the script's own comment says a full
  (non-reduced) bundle holds every watershed. Rebuilt on the machine with the full province run,
  `shape_stations` is all three gauges and the sentence states a falsehood ("the third segment"
  with nothing left over), while every `stopifnot` stays green. The month-check paragraph just
  above handles the same fork with `out_text` (line 721); this one needs the same branch on
  `length(prov$shape_stations)` (or `setdiff(stations, prov$shape_stations)`), not a count typed
  into prose. Same mechanism as code-check.md "A guard's scope … treat `every`, `all N` as words to
  check".

No other defects found. Specifically checked and clean: the `match()` keys on `id * 512 + doy` have
no NA on either side (`stopifnot(!anyNA(j))`, ids asserted non-NA upstream); `aggregate()` runs on
frames asserted non-empty and NA-free; `vapply()` over one or more segments yields a 12 × n matrix
in both cases; the test regexes select exactly the two balance-day rows (checks 3–5 do not match
`^balance (days|months from the days)`); the `[!in_poor]` logical index over `c(a, b)` recycles
over an exact multiple; `packageDescription()$RemoteSha` is an exact field name with no longer
sibling, so `$` partial matching cannot answer for it; the vignette's `sd <- v$segments_daily`
masks nothing it later calls.
