# Code check, round 2 (#145): branch 38a9672...HEAD

## Checklist read

- Index (`checklist.txt`): read in full, all four files.
- code-check-r.md: full sections read for:
  - "Moving prose into a code chunk hides it from tools that scan the document"
  - "A `data-raw/` script must load the source tree, not the installed package"
  - "Regenerated binaries churn git even when nothing changed"
  - "A duplicate knitr chunk label fails the build, and reading the diff will not find it"
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "`paste()` with a zero-length argument returns length ONE, not zero"
  - "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"
  - "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"
  - "`[[` on a named ATOMIC vector with an absent key is an error, not `NULL`"
  - "Postgres row order is never fixed unless the query fixes it, so a pick, a float sum and a presence check can each depend on it"
  - "`sprintf("%g", x)` writes `Inf` and `NA` into SQL as bare words, which Postgres reads as column names"
  - "`c(name = x)` keeps `x`'s own name, so a value from a named vector becomes `name.X`"

  That is 12 sections. The other ~105 were judged from the index alone.
- code-check-spatial.md: full sections read for:
  - "bcdata: `filter()` translates the calls inside it, so build strings, value lists and transforms before the query"
  - "A coordinate stored as an attribute can disagree with the geometry it describes"
  - "A name is not a key: `GNIS_NAME` matches features all over BC"
  - "The BC WFS caps an un-paged `GetFeature` at 10,000 features and still answers HTTP 200"
  - "`atan2(0, 0)` is 0, so two points at one place have a bearing of due north"
  - "A Freshwater Atlas main stem's downstream end lies on the receiving river's centreline, not at the confluence"

  That is 6 sections. The other ~86 were judged from the index alone.
- code-check-shell.md: no full sections read, because the diff has no shell code. All ~70 were judged from the index alone.
- code-check.md: the prose of all 14 H3s under `## Mechanisms` was read, with the `|` table rows and evidence blocks skipped. None of the Rules that stand alone, Security, or Spreadsheets sections were read in full (about 20).
- writing.md (soul `conventions/writing.md`): read in full.

## Findings

- **[severity: bug]** vignettes/flow-departure-normal.Rmd:678–680, with its guard at :674–675. The bullet says "approved HYDAT flows end in March 2025, so 2 of the five years rest **partly** on provisional flows, which may be revised."
  - **What the data say.** Every bar in both years is wholly provisional. In the bundle, `kf$frac_provisional` is 1 for every station and window in 2025 and 2026, and 0 in 2022–2024 (`aggregate(frac_provisional ~ year, kf, range)`). The record agrees: HYDAT ends 2025-03-02 and 2025-03-04, before the first window opens on May 1. Provisional data then runs to 2026-09-12, and real-time after that.
  - **Where it came from.** The branch added the word. The old article said "rest on provisional flows".
  - **Why the guard misses it.** The guard is `stopifnot(n_prov > 0)`. It covers "some years are provisional". It does not cover "partly": a year is counted when any bar has `frac_provisional > 0`, whatever the share.
  - **Fix.** Drop "partly", so the bullet reads "rest on provisional flows". Or, to keep the word, guard it with `all(kf$frac_provisional[kf$status == "provisional"] < 1)`, which fails today.
  - **Rule:** writing.md "Check that each guard covers the set its sentence names"

## Checked, not flagged

- **Round 1's three fixes.**
  - Fix 1 is sound. `low_years` and `min(low_years):last_year` are both integer, so `identical()` can be true. Together with `all(low$pct < low$median_pct)`, the guard covers every bar from 2023 to the last year (24 bars).
  - Fix 2: the new bullets credit the Stream Network for streams and mouths, and the Atlas's watersheds, lakes and boundary for catchments, lakes and the province outline. That matches the layers' sources (`vm_catchments`, `vm_lakes`, `vm_bc`).
  - Fix 3: the committed `.bib` is in C order (`Kendall` first, then `arguez` … `zyp`), which is what `method = "radix"` gives.
- **"21 of those 24 window means were drier than nine 1981–2010 years in ten".** I measured how much the count depends on the definition. The guard uses `value < quantile(v, 0.1)` (type 7). An empirical definition, the share of baseline years wetter than the bar being at least 0.9, also gives 21. Among the 21, the share runs from 0.931 to 1. So the two definitions give the same count.
- **Other prose and caption claims, re-run from the purled vignette in a temp dir:**
  - n_low 24, n_dec 21, n_min 6.
  - The low years are 2023–2026 and the up year is 2022.
  - 2 of 24 trends have p < 0.05, both negative (08EE013 Spawning from 2000; 08EE003 Migration from 2000).
  - `start_003` is 2011.
  - Medians run 64–96 % of the mean.
  - Hazelton from Houston is 116 km at a bearing of about 325°, which prints as "120 km north-west".
  - The Buck mouth is 0.89 km from Houston and the Bulkley mouth 1.15 km from Hazelton.
  - Buck's share is 567/2315, which prints as 24 %.
  - Both gauges' HYDAT ends in March 2025.
  - "grey line" is #636363, and the hydrograph median colour is the gq registry's.
- **`trend_on` and the trend wording.** `trend_on` is `anomaly` (`pct_normal`, `%`). `cd_trend()` uses `zyp::zyp.sen` (Theil–Sen) and `Kendall::MannKendall`, so the trend paragraph's wording holds.
- **`vm_into()` is moved verbatim** from chinook_sites_map.R. The only change is `drop = FALSE` on the mouth coordinates, which is harmless.
  - The rows come back in the given order, and `mouths` uses `names(blk)`.
  - The new `station_map.rds` matches the old one exactly in stations, catchments, streams, places and `bc`, so segment-discharge and the README figure, which read `bc`, are unaffected. Lakes differ only in row order, which is an accepted tradeoff.
  - `vm_places()` filters on `names`, a plain local variable, which bcdata translates fine.
- **No stale `station-flow` links** remain outside the planning archive, the redirect and its history notes.
- **`vignette_bib.R`.** The entry regexes, the software-to-`@misc` rewrite and the local-path guard all behave on the committed `.bib`. No abstract, file or keywords field survives in it.
