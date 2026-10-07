# Code review, round 3: scripts/wb_term_diagnose.R (#45)

Scope: the shared mechanism behind the round 1 and round 2 findings, then every place in the script
that mechanism reaches. The script was not run. Read-only probes:
- `cv_aet-cfu.rds` structure: 315 stations, with `station_number`, `cv_ann` and `code_md5`.
- the ECCC climate-stations API, into the scratchpad: 1762 BC stations, numberMatched = returned,
  no duplicate or NA `CLIMATE_IDENTIFIER`, every geometry a 2-vector.
- `ps`, and a diff of the in-flight frozen copy against the staged script.

Nothing under data/wb_term/, the report, or any PCIC value was read.

## The mechanism

Each earlier bug had the same cause: a derived object was identified by less than it depends on,
and nothing checked the gap.

- **A cache was trusted on its name and its existence.** The name carried fewer inputs than the
  content depends on. The release-only `pcic_upstream` key ignored the province run. Existence
  stood in for a finished write (the in-place writes).
- **A share was trusted on its numerator test.** The population it is taken over was left
  implicit:
  - the denominator lost the NA basins (`na.rm` in `w_high`);
  - "both PETs" was combined after the mean, not per basin.
- **An alignment check compared representations, not the values that define identity:**
  `identical()` on a double against an integer.

So the question to ask at each site: does its name or key enumerate everything its content
depends on, and is its population the one the rule names?

## Findings

- **[fragile] scripts/wb_term_diagnose.R:60, 88.** The `pcic_upstream` cache is still keyed on
  less than it depends on.
  - Its content is cut to `cal$watershed_feature_id`.
  - `cal` depends on the province run, which is now in the key. It also depends on
    `wb_cv_lib.R`'s filters (`min_frac`, accepted stations) and on the stations file
    `stations_<release>.rds`. Neither is in the key.
  - The key also leaves out the `pcic_cell` layers the cache was computed from.
  - Both of these are in `score_code_md5`. Line 100 asserts that `cv` matches the current
    `score_code_md5`, so after a refit under changed scoring code or a rewritten stations file
    (same key_dir, same release) that check passes. Line 61 then returns the old cut, and any
    newly calibrated gauge drops out at the inner `merge()` on line 105 without a message.
  - Fix, either of:
    - cache the uncut basin means and cut to `cal` after `readRDS`. The cache then depends only
      on the cell layers and the fwapg topology.
    - add `score_code_md5` to the filename.

- **[fragile] scripts/wb_term_diagnose.R:70, 80.** `pcic_cell_<code>.tif` is keyed on the basin
  code alone.
  - Its content also depends on `years`, on the `vars` mapping (which PCIC variable is behind
    `p_c` … `pet_c`) and on the run.
  - The check on line 80 compares only the left-hand names. If `years` or a variable is edited,
    the old layers are reused without a message.
  - The report header (lines 292-293) then prints the new `min(years)`-`max(years)` over values
    from the old period. The report would state a provenance its numbers do not have.
  - Fix: put a short hash of `c(years, vars, names(vars))` in the filename
    (`wet_md5_text()` is already loaded).
  - `data/pcic/` itself is correct: `wet_pcic_fetch()` keys on run, variable and the
    time/lat/lon indices, and writes atomically.

- **[fragile] scripts/wb_term_diagnose.R:189.** The unzip is now gated on existence:
  `if (!dir.exists(hz_src)) utils::unzip(...)`.
  - scripts/wb_inputs.R:74, which the comment cites, unzips into the same `src_<md5>` directory
    on every run with `overwrite = TRUE`, with no gate.
  - With the gate, a directory left partial by a killed unzip (from this script or from
    wb_inputs.R) is trusted from then on.
  - `terra::vect()` on a truncated shapefile set can read fewer polygons. Stations then fall to
    `zone = NA` without a message, which shrinks the ECCC set for (ii′) and can turn it into
    "unavailable" (fewer than 3 stations).
  - Fix: drop the gate and unzip as wb_inputs.R does. It is cheap.

- **[fragile] scripts/wb_term_diagnose.R:162.** `eccc_climr.rds` has no key at all. It depends on
  `years` (`obs_years`), the hydrologic-zones zip (whose md5 is computed on line 188, but only
  to name the unzip directory) and the climr reference map. It is the same shape as the
  `pcic_cell` finding, with a lower chance of firing. Fix: the same hash, plus the zip md5, in
  the filename.

- **[fragile: pre-registration, unrecorded reading] scripts/wb_term_diagnose.R:271-275.** The lever
  veto matches the pooled verdict as an exact string.
  - `term_of("unstable (AET side (ours))")` is NA, so an **unstable** pooled verdict for the
    other term never vetoes.
  - Amendment 1 says "unstable" casts no **vote**. The veto clause ("the pooled stratum's
    verdict is not the other term") does not say whether an unstable other-term verdict counts.
  - This is the same kind of gap as round 2's "both PETs": the code's reading is defensible but
    not written down. Record it among the Implementation readings now, before any PCIC value is
    seen. If the stricter reading is wanted, strip the `unstable (...)` wrapper before
    `term_of()` for the veto only.

- **[fragile] scripts/wb_term_diagnose.R:352.** The tracked report path takes no release:
  `data/checks/wb_term_diagnose.txt`.
  - Every other wb script writes `wb_report(stem, release)`, so a later fit's report carries its
    release (scripts/wb_fit_lib.R:48-53; CLAUDE.md, per-release fits). The rds on line 354 is
    keyed by release.
  - A run with `WET_HYDAT_RELEASE=20251014`, a fit that exists on m4, overwrites the shipped
    fit's tracked report. Only the header line distinguishes the two.
  - Fix: `wb_report("wb_term_diagnose", release)`. The 20260717 file then carries the suffix.
  - The script header and the final `stamp` name the path, and need the same change.

## Every other place the mechanism reaches: checked, no finding

- **Caches and outputs:**
  - `data/pcic/` is fully keyed and atomic.
  - `save_atomic()` covers `pcic_cell`, `pcic_upstream` and `eccc_climr`.
  - `diagnose_<release>.rds` is an output that is never read back.
- **Joins and alignment:**
  - `merge(cal, pc)` is an inner join by design; `n_in_basins` reports the count.
  - `cv` matches all 315 gauges (same `code_md5`, and the vectors have the same length).
  - The fwapg `mad_mm` match: an NA is reported, never used in the rule.
  - The `tapply` over `factor(cl$id, levels = pts$id)` keeps the point order.
  - The `zp` row check compares values (fixed).
  - The ECCC normals and station merge: probed, no duplicate IDs, so no row is doubled.
- **Populations and denominators:**
  - `w_high` and `w_low` are per basin with every basin in the denominator (fixed).
  - Every median in `verdict()` runs over `d` with no NA source after the ≥ 0.95 cover filter:
    `wet_upstream_means()` sets NA only where `w__ = 0`.
  - `closure` is NaN only when R_c is exactly 0.
  - The ECCC subset uses the median elevation of the subset being judged, the LOO subsets
    included.
  - The 1 mm floor on R_o and R_c preserves rank, so it can move a median only if half of a
    zone's basins are floored; that count is reported.
- **Conjunction scope:**
  - The shared-P test (`tc_o`, `tc_c`) and the AET corroboration (`w_low`, `mod16`) are each a
    zone-level conjunction, which is what Amendment 1 says.
  - The P corroboration is an OR of (i′), (ii′) and (iii), as registered.
- **Basin 200 is the whole Mackenzie, not only the Peace.** Its bbox (from the run log) reaches
  −132.1°, into the Liard, beyond PCIC's domain. Gauges there get coverage < 0.95 and drop at
  line 113 by design. The cost is fetch volume only.

## Operational note

The in-flight run (PID 72216) is still `data/logs/45/wb_term_diagnose_frozen.R`, from before all
round 1 and round 2 fixes.
- It writes `pcic_upstream_<code>_20260717.rds` under the old name. The staged script never reads
  that file, so it recomputes the cut. That costs fwapg time, but no result.
- It writes `pcic_cell_<code>.tif` in place, under the same name the staged script trusts. If the
  run is killed during the Peace write, delete `pcic_cell_200.tif` first.
- It ends at the old `identical(zp$id.y, …)` stop, before any ECCC cache, report or value.
