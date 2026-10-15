# Code-check round 2 (#77, branch against dcd15b0)

## Clean
No issues found.

What was checked, so a later round knows what this verdict covers:

- **The round-1 fix (`share_spec`).** `data-raw/monthly_vignette_data.R:288` records `fits$share_spec`. The bundled `inst/vignette-data/monthly_values.rds` carries `share_spec = "snow"` and `wet_commit = fc105e4`, the commit that added the field. HEAD 684fa77 changes only the .rds after it, so the bundle's recorded commit can rebuild it.
  - `stopifnot(identical(prov$share_spec, "snow"))` (vignettes/monthly-flow.Rmd:525) sits in `score-text`, ahead of the only prose that names the snow terms (lines 575–578).
  - It fails in the right direction. A bundle without the field gives `identical(NULL, "snow")`, which is FALSE, and no provenance name partial-matches `share_spec`. A bundle from a "base" fit fails the same way.
  - No test asserts the monthly provenance names, so nothing else needed the new field. `fits$share_spec` is the `ship_share` that `wb_validate.R:110` fits `ins_share` under. The published balance months are recomputed from `fits$share`, so the label and the values come from one fit.
- **The stored-month guards (data-raw/monthly_vignette_data.R:62–77).**
  - `cv_share` exists and has dims (nrow(cal), 12).
  - `cvr$share_spec == fits$share_spec`.
  - `cv_share` is identical to `cv_shares[[spec]]`. This matters because `predict_cv()` returns the first specification as `$share`, and `wb_validate.R:109` reassigns it to the shipped one.
  - Observed annual and shares are identical to `cal`'s. Re-scoring reproduces `cv_v$stations`, which `wb_validate.R:118` computed from the same `cv$ann` and `cv$share`.
  - `$` partial matching: `cv_share`/`cv_shares`, `obs`/`obs_share` and `share`/`share_spec` each resolve to the exact key when it is present. When `cv_share` is absent, the partial match on `cv_shares` gives a list with no dim, and the guard refuses it.
  - `shipped_heldout()` refuses a cv file whose `code_md5` does not match `score_code_md5` (the scoring code is covered).
- **Vignette claims against the bundle.** I rendered a copy of `monthly-flow.Rmd` under `load_all()` in a temp dir, and every `stopifnot` passed. The prose agrees with the numbers:
  - Balance median by month: April and May are +10.7 % and +6.8 %; every other month is within 4.6 %.
  - Gauges routed PCIC does not reach: January −16 %, February–March −62 % to −75 %. This matches the research table (Liard January −76 % → −16 %).
  - Buck Creek: the balance's peak is 10.3 against 22.0 observed (under half), and its May–June flow is 9.4 against 16.4 (low, not under half).
  - Quick: the balance is above the gauge in January–March but not in April (85.7 against 93.4), so "January to March" is correct.
- `tests/testthat/test-vignette_data.R` with `NOT_CRAN=true` against the source tree: 0 failed, 0 errors, all 7 blocks ran.
- `CLAUDE.md`: the gap list (#67, #6, fwapg#25) matches the vignette's "What's next". The description of the stored-month guards matches the code.
- `research/water_balance_method.md:447`, "uploaded 2026-10-15": the manifest's `built` is 2026-10-15T02:06:57Z, so the UTC date is consistent.
- The publish report names live acb820f, 67 of 67. `vd_published()` accepts it, and the segment bundles were regenerated at 5ad20df from that build. No segment data script changed after that commit.

Not re-flagged, per the brief: `research/discharge_publish.md:5` naming 7c62b9e.
