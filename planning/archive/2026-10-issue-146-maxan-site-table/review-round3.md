# Code-check round 3: branch 146-move-the-maxan-pilot-onto-the-site-table

Reviewed `git diff cfd7ed1...HEAD` (HEAD 8e63080), with the changed files read in full where the brief asked.

## Checklist read

- code-check.md (334 KB): the prose of all 14 H3s under `## Mechanisms`, table rows skipped; "Documentation Staleness". The other 22 headings were not read.
- code-check-r.md (191 KB): "`identical()` on two reader results tests the reader, not the file", "`$` on a list partial-matches, so a longer sibling key answers for a missing one", "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests", "`strsplit()` drops a trailing empty field, so a trailing separator vanishes", "`sub()` takes one replacement, not one per element", "A `data-raw/` script must load the source tree, not the installed package", "Rscript reads a script as it runs, so never edit a script while a run of it is in flight", "Regenerated binaries churn git even when nothing changed". 107 of 115 not read.
- code-check-shell.md (132 KB): none read. The diff contains no shell code. 70 of 70 not read.
- code-check-spatial.md (156 KB): "A name is not a key: `GNIS_NAME` matches features all over BC", read because the map script now takes `blue_line_key` from the site row. 92 of 93 not read.

## Probes run (in a scratch copy, nothing in the repo written)

- `tests/testthat/test-departure_site_parity.R`, run against copies of `scripts/departure_site_lib.R` and the four tracked reports with `NOT_CRAN=true testthat::test_file()`: 6 blocks, 21 passes, 0 failed, 0 errors, 0 skipped.
- The bundle `inst/vignette-data/short_record_values.rds`: `provenance$report_md5` equals the md5 of both tracked site reports, `provenance$code_md5` equals the md5 of both site scripts at HEAD, and `v$site` is `identical()` to today's `site_get("maxan")` over the fields it carries. It was built at 8b8f7fb. Since then only comments in `departure_site_lib.R` have changed.
- `git show d4fae1f:scripts/departure_pilot.R` and `git show d4fae1f:scripts/departure_snow.R` both resolve, as the research and CLAUDE.md citations say.
- No stale reference to the retired scripts remains outside `planning/`, `data/checks/` and the "retired in #146" notes.
- `scripts/departure_site.R` is the only `dbConnect(RPostgres::Postgres())` with no arguments in `scripts/`, `data-raw/` and `R/`, as CLAUDE.md's Database line now says.
- Both parity gates sit before the first write in their scripts (`writeLines(report)`, then `saveRDS`). The only earlier writes are the cd cache and `tempdir()`.
- `site_parity_pilot()` fails toward refusal. If the site change-table header matches zero lines or two, `site_change` is `character()`, so every tracked change row is reported missing.
- The live rds files are not on this machine (`data/departure/` is absent), so nothing was run against them.

## The mechanism behind round 1's finding

The shared assumption was that the md5 of the script that wrote a series file stands for everything that produced it. A series rds is keyed by `code_md5` and `release`, but the script that wrote it also read:
- inputs no md5 covers: `scripts/departure_sites.csv`, `inst/vignette-data/life_history_<group>.csv` and `data/wb/stations_<release>.rds`;
- sourced libraries: `scripts/departure_site_lib.R`, `scripts/wb_fit_lib.R` and `scripts/departure_snow_lib.R`;
- `R/`, through `load_all()`;
- the series file of the run before it.

That is a cache keyed by fewer inputs than the write depends on (code-check.md, "Written data outlives the fix"). `vd_commit()` does not close the gap. It shows the tree is committed now, not that the rds was made from that tree.

Where the mechanism reaches on this branch, and whether each place is covered:

| # | Consumer, and what it reads | Input not in the md5 | Covered? |
|---|---|---|---|
| 1 | `data-raw/short_record_vignette_data.R`, reading the `departure_site.R` maxan/bulk rds | site row (`departure_sites.csv`) | **Yes**, since 8b8f7fb (`identical(x$site, site)`). |
| 1a | same | window dates (`life_history_bulk.csv`, parsed by `site_windows()` in `departure_site_lib.R`) | **No.** Only `srun$windows$window` (the names) is checked, although the rds carries `start`/`end`. See Finding 1. |
| 1b | same | `R/`, `departure_site_lib.R`, `wb_fit_lib.R`, the stations rds | **No** by md5. **Bounded** at printed precision: every value the bundle takes is held to its line in the tracked site report, and the parity test holds that report to #120's tracked report. An rds/report pair from older code passes only if it still reproduces #120's record, so what is left is the bundle's claim that its commit rebuilds it. |
| 2 | same script, reading the `departure_site_snow.R` maxan/bulk rds | site row | **Yes** (8b8f7fb). It is also transitive: `srun$site` and `snow_rds$site` must both equal today's row, so they equal each other. |
| 2a | same | which site rds the snow run read (the snow rds records no md5 or identity for it) | **No.** **Bounded** the same way as 1b: each rds is held to its own tracked report, and each report to #120's or #121's. |
| 2b | same | window dates (`snow_rds$windows`, copied from the site rds) | **No.** Names only. Same as 1a. |
| 2c | same | the cd layer run | **Partly.** `cd_sha` comes from the tracked snow report's `swe_max` line, which is exempt from parity, and the rds carries no cd tag. A snow rds from another cd run passes while its values agree with the report at printed precision. This is the accepted cd exemption, listed for completeness. |
| 3 | `scripts/departure_site_snow.R`, reading the site rds | site row (`pr$site` against `site` is never compared), window dates (`windows <- pr$windows`) | **No.** Predates the branch; out of scope. For maxan BULK the snow parity gate bounds it. For the other three sites nothing does: a CSV edit between the site run and the snow run mixes two rows in one tracked snow report (for example snow gauges from the new row, series from the old). |
| 4 | `data-raw/chinook_sites_data.R`, reading all eight site and snow rds files (`read_series()`) | site row, window dates, `R/`, libraries | **No.** It checks md5 and release only. Predates the branch; out of scope. Round 1's fix landed in only one of the two data scripts that read these files (code-check.md, "A fix lands in one of two callers that share a harness"). `chinook_sites_values.rds` still names commit 52facd0 and the pre-branch script md5s (48bdc697…, 1b2c1ea3…). That is consistent at that commit, so it is not a defect, but rebuilding it at HEAD needs the reruns made on the other machine. |
| 5 | `scripts/departure_pcic.R` (its own report and rds) | box and target, moved from literals (which its md5 covered) to `departure_sites.csv` (which it does not) | **Yes**, by other means. The script refuses a dirty `R/` or `scripts/` (the CSV is under `scripts/`) and records `wet_commit` in both its report and its rds. Nothing in the repo reads that rds yet. |
| 6 | the parity gates in `departure_site.R` and `departure_site_snow.R` | (previously: the pilot rds files, gated by the pilot scripts' md5) | **Not applicable any more.** The gates now compare committed text, so no md5 is assumed. |
| 7 | `data-raw/short_record_vignette_map.R` and `vignettes/short-record-flow.Rmd`, reading `values$site` | none (they read the bundle's own copy) | **Yes.** The bundle's site is checked against today's row at build time. The article's `stopifnot(!anyNA(catch$part))` ties the map's catchments (not regenerated, as accepted) to that site. `test-vignette_data.R` pins `site_id`, `target_station` and `snow_gauges`. |

## Findings

- **[severity: fragile]** data-raw/short_record_vignette_data.R:104. The window dates are checked by name only, so a series made under other window dates passes `read_series()`. This is round 1's mechanism on the input next to the one it fixed.
  - **What happens.** `stopifnot(identical(srun$windows$window, windows), identical(snow_rds$windows$window, windows))` compares only the names `migration` and `spawning`. Each rds carries its windows' `start` and `end`, set at run time from `inst/vignette-data/life_history_bulk.csv` through `site_windows()` in `scripts/departure_site_lib.R`. No md5 covers either file. `vd_commit()` does not cover `inst/`, and this script never reads that CSV.
  - **What can go wrong.** Suppose the BULK file is regenerated (`data-raw/life_history_data.R`) or `site_windows()` changes. An existing gitignored rds made under the old windows still passes the code md5, release and site row checks. Its values match its own tracked report, which still reproduces #120's. The bundle is then rebuilt naming a commit at which `scripts/departure_site.R maxan` would compute other windows and stop at its parity gate. So "the commit the bundle names rebuilds it" (the header's claim, and round 1's reason for adding the site row check) is false, and nothing refuses.
  - **How much this branch owns.** The pilot also read this CSV without a check. But the pilot parsed it inline, inside the hashed script. The parsing now sits in the unhashed `departure_site_lib.R`, and the rds now carries the dates, so the check is one line. For example, compare each rds's `windows` with `site_windows(site)[[wname]][c("window", "start", "end")]` (`scripts/departure_site.R:304` builds it in exactly that form) and add it to the refusal in `read_series()`.
  - **Rule:** code-check.md "Written data outlives the fix" ; code-check.md "A proxy is not the property"

## Notes (not findings)

- The pilot exemption `^The rule: the highest median ` drops the only line that prints the race medians to three decimals (ols 0.502, ratio 0.416). The method table compares them to two decimals. This falls under the accepted exemption list, so it is noted rather than flagged.
- Everything else the gates compare holds under mutation in the shipped test, and both directions were checked in the probe above.
