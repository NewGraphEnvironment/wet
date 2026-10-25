# Code-check round 2 (#120), branch 120-maxan-creek-chinook-pilot-extend-08ee018 at 781e892

## Checklist read

- code-check.md: the prose of all 14 H3s under `## Mechanisms`, table rows skipped. The other 27 H3s (standalone rules, Security, Spreadsheets and PDFs) were not read: none names a tool or shape this diff uses.
- code-check-r.md: read in full 9 sections: `sample.int(prob =)`; `ifelse()` with an all-NA test; `paste()` with a zero-length argument; `$` partial matching; `match()` and NA; `vapply(USE.NAMES = FALSE)`; Rscript reading a script while it runs; a `data-raw/` script loading the source tree; testthat `tolerance` is relative. 102 not read.
- code-check-spatial.md: read in full 2 sections: `terra::project()` given only a CRS; sf and terra linking different GDALs. 91 not read.
- code-check-shell.md: 0 read, 67 not read. The diff has no shell code.

## Round-1 fixes, checked

1. "220 blocks, of which 218 had a donor covering them". I re-ran the block tiling and `wet_window_extend(method = "ols")` on the 21 extension-pool gauges (HYDAT 20260717, scratch copy). There are 220 blocks. The only 2 errors are the "no donor has ... in every one" stop, at 08EE004's 1931 and 1936 blocks. So the `no_donor` counter is the "no covering donor" count, and the research sentence holds.
2. The Limits paragraph is correct as reworded. 08EE004 supplies all 30 years 1931–1960, plus 1972, which makes 31 of the 50 pre-1981 years. 08EE008 supplies 11 (1961–71), 08EE013 3 (1973, 1974, 1980), and 5 are observed.
3. The q_max rows:
   - `combos` takes max last, and the bootstrap for max draws nothing, so the RNG stream for the six existing rows is unchanged. The diff of the report adds lines only.
   - `na.rm = TRUE` in `quantile()` changes nothing for the other rows: their `res` has no NA, because `complete.cases` is applied in `pseudo_run`.
   - The printed max values agree with each other: -0.323 is -27.6 %, and -0.413 is -33.9 %.
   - Other research numbers I re-derived from the report all match: the method table, 0.63/0.34/0.75, 0.69, 0.92, 0.57, 0.49, 0.23, the before/after table, carried -3 % and -46 %, r 0.93 and 0.78, and the donor-year ranges.

## Findings

- **[severity: bug]** scripts/departure_pilot.R:731, which writes data/checks/departure_pilot_20260717.txt:187. The report says "the years before 1961 come from 08EE004, **the only donor reaching them**". That is false.
  - The chain is 08EE013, 08EE008, 08EE004, 08ED002, 08ED001. Chain member 08ED001 (Nanika) has complete migration-window means for 1950, 1951 and 1952 (measured on HYDAT 20260717; it does for spawning and max too). It supplies none of them only because 08EE004 sits nearer in the chain.
  - The code derives the clause from the donors that *supplied* years: it takes the second-earliest supplying donor's first year, then the earliest supplier's name. It never checks which chain donors *reach* those years, so "only" is an unexecuted claim.
  - The registered header (line 190–191) says something different: "the years before 1961 rest on the one or two donors in the chain that reach them". Here that is two donors for 1950–52, with 08EE004 supplying.
  - The research file's wording, "come from one large mainstem gauge", is still true. Only the report line overstates.
  - Fix: drop ", the only donor reaching them", or compute and name the chain donors with any year before the cut, e.g. `chain[vapply(chain, function(d) any(g$year[g$station_number == d] < cut), TRUE)]`. Then regenerate the report.

No other issues found. Round 1's verification of header-to-body correspondence was not repeated beyond the fixed lines and the limit sentence above.
