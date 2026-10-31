## Checklist read

- code-check.md (334,881 bytes): the prose of all fourteen H3s under `## Mechanisms`, with the `|` table rows skipped. I read none of the 26 headings under "Rules that stand alone", Security, or Spreadsheets and PDFs, because none names a tool or shape this diff uses.
- code-check-r.md (190,768 bytes): 8 sections read:
  - "Tests that silently do not run"
  - "A `skip_if_not()` skips only its own `test_that()` block"
  - "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "A `data-raw/` script must load the source tree, not the installed package"
  - "`identical()` on two reader results tests the reader, not the file"
  - "`nzchar(NA)` is TRUE — non-empty checks silently pass NA"
  - "`sub()` takes one replacement, not one per element"

  107 not read.
- code-check-shell.md (131,937 bytes): 0 sections read and 70 not read. The diff has no shell.
- code-check-spatial.md (155,517 bytes): 0 sections read and 93 not read. The map script's only change swaps one literal blue_line_key for the bundle's integer of the same value, and keeps it keyed by blue_line_key rather than by name.

## Clean

No issues found.

What I checked, so the next round need not repeat it:

- **The parity tests in a scratch copy.** I ran `tests/testthat/test-departure_site_parity.R` with `NOT_CRAN=true` against the four tracked reports. All 6 blocks passed: 21 expectations, 0 failed, 0 skipped, 0 errors.
- **Whether a set match could pass by accident.** For every compared line, pilot and snow, I checked that each tracked line the gate compares sits in the same `## ` section of the site report as in the tracked one. I also checked that no compared line appears more often in the site report than in the tracked one. There were no mismatches. The only duplicated tracked line is the per-year table header, which appears 8 times, as the accepted tradeoff says.
- **Where the change table's header can match.** The site change-table header regex can match only section 4's header. Section 5's header has different columns, so `table_of()` cannot return NULL on a healthy run and empty the comparison.
- **Where the gates sit.** Both gates run after `out` is complete and before the report and rds are written. Nothing before them writes into the repo: duckdb runs in memory, and the normals rebuild goes to `tempdir()`.
- **`data-raw/short_record_vignette_data.R`.**
  - Section 4's slice and the 12-number parse fit the site report's mean and min7 rows. The `cov_day` and `max` rows are never used.
  - The new `sec3` end (`^\(swe_max in mm`, first match) stops before the 1951-1980 table.
  - The 8b8f7fb fix (`identical(x$site, site)`) holds for both series. `departure_site.R` and `departure_site_snow.R` both save `site_get(args)` unmodified, and neither assigns into `site` anywhere.
  - The committed bundle's `code_md5` and `report_md5` equal the current scripts' and reports' md5s. Its `site` carries an integer `blue_line_key`, which keeps `blk` in the map script an integer vector, under the same names as before.
- **`scripts/departure_pcic.R`.** Sourcing `departure_site_lib.R` clobbers nothing: the only `site*` names in it and in its other sourced libs are the new ones. The box parses to the same named values as the old literals.
- **Remaining references to the retired scripts.** No code path reads `departure_pilot.R`, `departure_snow.R` or their rds files. The remaining references are comments, the research doc, CLAUDE.md and NEWS history. `d4fae1f` holds both scripts unchanged from `cfd7ed1`, so the research doc's `git show d4fae1f:` recovery works.

One observation, not a finding: the lib's comment says the helpers refuse "a tracked report without the parts it compares". In code, they refuse only a report with no two-space row, and, for the pilot, one with no single change table. A tracked snow report truncated after section 3 would pass with less compared. Nothing writes those two tracked reports any more, now that the pilot scripts are retired, so I see no way for this to happen short of a hand edit to a committed file.
