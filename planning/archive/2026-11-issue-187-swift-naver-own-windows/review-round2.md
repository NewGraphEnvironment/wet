# Code review, round 2 (#187): branch diff cbeb3489...HEAD (6afb5d04)

## Checklist read

- **code-check.md:** I read the prose of all 14 H3s under `## Mechanisms` (rows starting with `|` skipped): "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "A proxy is not the property", "Verification that reads its own output", "A guard's scope, escape hatches, and remedies" (read in full), "A fix lands in one of two callers that share a harness", "Restore the bug and prove the guard fires", "A shared working tree, and what generators leave in it", "A wrapper's exit is not the work", "Zero-length, empty, and unset are three different things", "The probe is broken before the world is", "Written data outlives the fix", "Serialization loses meaning silently" and "One fact derived twice". Not read: the other 24 headings.
- **code-check-r.md:** read "A `skip_if_not()` skips only its own `test_that()` block", "Under `R CMD check`, tests run from a temp dir against the INSTALLED package", "`system2(stdout = TRUE)` warns on a non-zero exit instead of raising, so a `tryCatch(error =)` around it never fires", "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests", "`paste()` with a zero-length argument returns length ONE, not zero" and "A `data-raw/` script must load the source tree, not the installed package". Not read: 126.
- **code-check-shell.md:** none read. The diff has no shell code. Not read: 75.
- **code-check-spatial.md:** none read. No spatial code changed; `chinook_sites_map.R` was only rerun. Not read: 98.

## The round-1 fix (6afb5d04)

The fix holds. I checked it against the rebuilt layers, not the prose:

- **Fraser map, new gauges.** Diffing `chinook_sites_map.rds$gauges` at cbeb3489 against HEAD by (site, role, station) adds four keys and drops none. Two are new stations: 08JE001 (extension donor) and 08KF001 (carried donor). The other two, 08KC001 and 08KG001, become carried donors at Naver, but both were already drawn as Naver extension donors.
- **What "carried donor" means.** `chinook_sites_data.R` builds `gauges` once per (site, window set), and lines 382-391 take donors from the shipped weighting. So each site's drawn donors are the union over its window sets.
- **The captions hold for both maps.**
  - Skeena: Maxan runs under BULK only. Gosnell's 13 carried donors are the BULK and MORR union, unchanged from the pre-branch layer. "with the gauges each borrows from under any of its windows" is true there.
  - Fraser: Swift's donors are the BULK and UFRA union (distance weighting under both). Naver's are the BULK and COTR union (covariance_pick under both). The caption is true there too.
- **"The flow figures show only those" holds.** All three flow figures read BULK only:
  - the windows hydrograph shades `wb`, which is BULK;
  - the years figure uses `yy`, filtered to BULK;
  - the change figure uses `dd`, filtered to BULK.

  The scores table also reads BULK only (`sc`, `ss_mig`, `ss_spw`).
- **"Swift, Naver and Gosnell creeks also run under their own stocks'"** is held by `identical(sites$windows, c("BULK", "BULK UFRA", "BULK COTR", "BULK MORR"))`.

Elsewhere:
- Every citation key in the Rmd is in the regenerated `.bib`.
- `lh_pin_guard()` and its tests hold as round 1 found:
  - a column-type drift between the two reads can only make the guard stop, never pass;
  - every test skips when `data-raw/` is absent.
- The `own-windows` guards hold for their sentences. A missing group cannot pass vacuously, because `row_of()` requires exactly one row.

## Findings

- **[severity: bug]** vignettes/articles/flow-change-sparse-gauges.Rmd:664-665 (limits bullet). It says "The upper Fraser and Cottonwood spawning windows rest on survey dates that are estimates from a few visits"; research/chinook_sites.md:111 says the same ("estimates from a few visits rather than the first and last spawners seen").
  - The source does not say the dates came from a few visits. Both texts cite knowledge#256, i.e. knowledge's `research/nuseds_timing.md` at a475dfe7 and the rows' notes in `life_history_ufra.csv` / `life_history_cotr.csv`. What the note says:
    - a NuSEDS date is "an estimate written on the record";
    - "How a date was made is mostly unrecorded" ("Unknown Estimate Method" on 82,437 dated records);
    - "Visits were seldom recorded before the 1980s" (21 records before 1980 give a number);
    - dates are written even where no spawner was seen.
  - The UFRA starts and ends run 1967-2000, and most COTR dated years are before 1975. So for these two windows, most records give no number of visits at all.
  - "From a few visits" therefore states a basis the source says is mostly unknown. It is published as the reason the edges are uncertain.
  - No guard or source line holds it. The sources support only "estimates, not the first and last spawners seen", which is the wording the CSV notes use.
  - **Rule:** none
