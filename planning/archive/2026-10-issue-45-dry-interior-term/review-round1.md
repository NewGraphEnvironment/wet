# Code review, round 1: scripts/wb_term_diagnose.R (#45)

Reviewed the staged diff against findings.md "Pre-registered attribution rule" + "Amendment 1"
(Amendment 1 wins). Read wb_cv_lib.R, wb_fit_lib.R, wb_score_md5.R, the package functions
used, mad_basin.R and wb_inputs.R's ECCC block. Probes were small and read-only (scratchpad):
`cal` columns and NA counts, terra 1.9.50 vector-on-vector `extract()` output, `rast(list)`
names, and the ECCC API counts. No PCIC value, data/wb_term/ or the report was read.

## Findings

- **[bug]** scripts/wb_term_diagnose.R:186. `stopifnot(identical(zp$id.y, seq_len(nrow(ec))))`
  is always FALSE, so stage 3 stops on every run. terra's `extract(<polygons>, <points>)`
  returns `id.y` as a **double**, and `seq_len()` is an integer, so `identical()` fails even
  when the values match. Measured on terra 1.9.50: for 4 points the result after the dedupe
  is `id.y = c(1, 2, 3, 4)` (num), and `identical()` returns FALSE (`code-check-r`,
  "`expect_false(identical(x, y))`…": identical is type-strict). The stop comes after the
  PCIC stage has cached (data/pcic/, pcic_cell_*.tif, pcic_upstream_*.rds) and after
  `cv`/`g`/`b` are built. Nothing is written to `f_eccc`, no report is written, and no
  value is printed, so the firewall holds and a rerun after the fix is cheap. But if the
  in-flight run is using this code, it will end there. Fix:
  `stopifnot(nrow(zp) == nrow(ec), all(zp$id.y == seq_len(nrow(ec))))`. An unmatched
  point still gets a row (with NA attributes), so a row-count check is valid here.

- **[bug: departs from the rule]** scripts/wb_term_diagnose.R:202-203, `w_high` uses
  `mean(..., na.rm = TRUE)`. `omega_implied()` returns NA where the implied AET P_o − Q ≤ 0
  (the gauge yields more than our P). Under (i′) such a basin does not satisfy "ω > 5 or no
  solution": the rule's no-solution test is P_o − Q ≥ min(P_o, PET), which is false there.
  So the basin should count in the denominator as a fail. Dropping it raises the share,
  toward a "P side" corroboration. `w_low` (line 204) has no `na.rm` and counts NA as a
  fail, so the two shares also use different denominators.
  - Measured on the current `cal`: 0 of the 40 gauges in zones 15/17/23/24 have
    P_o − Q ≤ 0. So the voting zones, the pooled stratum and the lever are **unaffected
    on this fit**.
  - 30 calibration gauges in contrast zones do have P_o − Q ≤ 0 (zones 01, 08, 09, 10, 22,
    25–29), so those zones' (i′) can come out other than as registered.
  - Fix:
    `min(mean(!is.na(d$w_harg) & d$w_harg > omega_max), mean(!is.na(d$w_pcic) & d$w_pcic > omega_max))`.
    `Inf > 5` is TRUE, so the separate `is.infinite()` is not needed.

- **[fragile]** scripts/wb_term_diagnose.R:69. `writeRaster(r, f_cell, ...)` writes straight
  to the cached path, and line 63 then trusts any file that exists. A run killed during the
  write leaves a truncated GeoTIFF that the next run uses as the PCIC layers for the whole
  basin, either erroring or reading partial values. This basin cache holds about 2 h of
  fetches, and a run of this script has already been killed once. wb_inputs.R:86-94 writes
  to a temp file in the same directory and then `file.rename()`s it, for this reason. The
  same applies to `saveRDS(up, f_up)` (line 82) and `saveRDS(ec, f_eccc)` (line 188),
  though a truncated .rds errors on read rather than giving wrong values.

## Checked and faithful to the rule (no finding)

- **Inclusion:** PCIC coverage ≥ 0.95 (`>=`). `coverage` from `wet_upstream_means()` is the
  covered share of the upstream area, with one cover across all five layers.
- **Dedupe:** one row per distinct `watershed_feature_id`, numerics averaged (only
  08NM240/08NM241 share one, measured). "Too few" is n < 4 distinct basins, counted after
  the cover filter.
- **Order of tests:** too few → material gap (`le_o < 0.10` → none) → usable (`ale_c > 0.25`
  or `|closure| > 0.25` → unresolved; closure scaled by R_c) → shared overshoot
  (`le_c >= 0.10 && le_c >= 2/3 · le_o`; P shared iff `tc_o <= 0.90 && tc_c <= 0.90`, else
  gauge side) → decomposition. Decomposition is always computed and reported.
- **Decomposition:**
  - G ≤ 0 is undefined.
  - Both bands are inclusive [⅔, 1.5].
  - Because share_p + share_a = 1, the branches cover every case: P band, A band,
    compensating (> 1.5), mixed.
  - P corroboration: (i′) `min share >= 0.5` with strict `> 5`; (ii′) ≥ 3 stations,
    `>= 1.10`, NA counts as unavailable rather than failed; (iii) `<= 0.90`.
    Any one of the three is enough.
  - AET corroboration needs both conditions: `w_low > 0.5` with `<= 5`, and `mod16 >= 1.00`.
- **ECCC elevation filter:** `elev >= median(basin elev) - 500`, where `cal$elev` is the
  upstream-mean DEM (checked). Any normal code (163 BC stations: 78 A, 85 C). Not truncated:
  numberMatched = numberReturned for both queries, and no duplicate climate IDs.
- **Zone codes:** `sprintf("%02d")` matches `cal$zone` ("15", "17", "23", "24").
- **Disagreement:** the larger median |log(R/Q)| is the one that is off (a tie reads
  "theirs").
- **Stability:**
  - Leave-one-basin-out on every judged zone and on the pooled stratum; any difference →
    "unstable (…)".
  - It runs with `check_n = FALSE`. The rule does not say whether the n ≥ 4 minimum applies
    to the subsets. The script's reading is the sensible one: otherwise every 4-basin zone,
    zone 17 included, would always be "unstable". Consider recording this as an
    interpretation in findings.md.
  - `zs_big` (≥ 100 km²) has no stability test, but it is reported only.
- **Lever:**
  - Votes come from zones 15, 17, 23 and 24. Only the three term verdicts vote, so
    "unstable (…)" casts none.
  - The lever needs ≥ 2 votes and a strict majority (a 2–2 tie gives none).
  - It is vetoed only when the pooled verdict is the other term.
- **Inputs to the rule:** no NA in `ppt_tc`, `aet_mod16`, `obs`, `p_yr`, `aet_cfu` or
  `pet_yr` across the 315 calibration gauges, so no `median()` → NA → `if (NA)` abort from
  ours. The `cv_aet-cfu.rds` md5 and release match the current scoring code.
