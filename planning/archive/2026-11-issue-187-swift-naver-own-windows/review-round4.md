# Code-check round 4 (#187), branch 187-backlog-move-10-swift-and-naver-creeks-u at e1b5ba25

## Checklist read

- code-check.md: under `## Mechanisms`, read as prose with the tables skipped: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; A guard's scope, escape hatches, and remedies (up to "Compression runs both ways", where my read stopped; round 3 quoted the rest). The other mechanism H3s I took from their index lines only. 38 H3s in the file; 34 not read in full.
- code-check-r.md: read `system2(stdout = TRUE)` warns on a non-zero exit instead of raising; A `data-raw/` script must load the source tree, not the installed package; CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests; A `skip_if_not()` skips only its own `test_that()` block; Under `R CMD check`, tests run from a temp dir against the INSTALLED package. 132 headings; 127 not read.
- code-check-shell.md: none apply (the only shell is `gh api` argv through `system2()`, covered by the R rule). 75 headings; 75 not read.
- code-check-spatial.md: none apply (the map bundle was rebuilt by an unchanged script). 98 headings; 98 not read.

## Round-3 fixes, each read against its artifact

| Fix | Artifact | Verdict |
|---|---|---|
| Rmd:550 "Fraser River chinook enter the river from April [Bradford and Taylor 2023, p. 131; citing COSEWIC 2018]" | the page, as quoted: adults "entering the Fraser River from April to August", said of the spring- and summer-run populations upstream of the Thompson confluence (the paper's title: "... Spring and Summer Chinook Salmon from the Fraser River"); knowledge's UFRA note at a475dfe7: "across the region's spring and summer runs" | **too wide by one step** (Finding 1) |
| research:100 "BULK's chinook migration and spawning rows equal `life_history_bulk.csv`'s" | `lh_pin_guard()` `ch()`: `species_code == "CH" & life_stage %in% c("migration", "spawning")` | holds |
| research:113 Swift UFRA "−15 % (−33..+5)" | bundle carried UFRA spawning mean: change −0.16808, lo −0.40154, hi 0.05341, which give −15.47, −33.07, +5.49 | holds |
| research:116 and :87 Naver BULK "−35 % (−58..+2)" | bundle: −0.43353, −0.87918, 0.01967, which give −35.18, −58.49, +1.99 | holds |
| other cells of the new table | Swift BULK −0.16585 / −0.38503 / 0.04967 give −15 (−32..+5); Naver COTR −0.42806 / −0.90259 / 0.08513 give −35 (−59..+9); migration means −6, −5, −11, −13; Swift extended −31.66 (−49.35..−6.10) against −27.46; Naver :87 min7 −29.96 (−51.9..+3.96) | all hold, each rounded once |
| research:119 "Every UFRA and COTR interval's coverage is 0.93 or more on mean and min7, both routes" | Swift UFRA section 5: min 0.953. Naver COTR section 5: extended min 0.955, distance-carried 0.931. Naver COTR section 6 (covariance_pick): min 0.952 | holds |
| research "within a point of its value under the Bulkley windows" | 0.19 (Swift) and 0.36 (Naver) points | holds |
| data-raw/life_history_data.R:10-11 "read with `gh api`, which needs a GitHub login" | `lh_read()` | holds |

Other branch lines checked with fresh eyes and found to hold:
- the `own-windows` chunk's guards: `row_of(group =)` exists; `wb` is BULK's windows; the 8 to 12 day offsets; the change within 2 points; `pct_hi > 0`
- `sites$windows` `identical()` against the bundle's site order
- `lh_pin_guard()` in both the `sys.source()` and the `Rscript` paths (`sys.nframe()`)
- the test skips under `R CMD check` (each `test_that()` reaches `lh_lib()`, or `lh_csv()` with its own `skip_if_not`)
- the vignette-data budget test's file list and sizes
- CLAUDE.md's four edits

## Findings

- **[severity: fragile]** vignettes/articles/flow-change-sparse-gauges.Rmd:550-551, inside a round-3 fix. The article says "Fraser River chinook enter the river from April [@bradford_taylor2023Diversityfreshwater, p. 131; citing @cosewic2018COSEWICAssessment]". Round 3 widened the subject from "Upper Fraser chinook" to all Fraser River chinook. That is one step past the cited page, which states the April entry for the spring and summer runs (upstream of the Thompson confluence, in a paper titled for Fraser spring and summer chinook). knowledge's UFRA row at the pin keeps the same limit: "across the region's spring and summer runs". Fall-run Fraser chinook, Harrison's for example, are in the sentence's subject but not on the page. The sentence restates the neighbouring artifact (knowledge's note) and drops its qualifier, while the guard (`own_w("swift", "migration")$start == "04-01"`) checks only the date. A sentence exactly as wide as the page: "Spring and summer chinook bound for the Fraser above the Thompson enter the river from April". If the caller's description of the page's scope is uncertain, "Fraser River spring and summer chinook enter the river from April" is narrower and matches the paper's title and knowledge's note. Either rewording adds words while the body prose sits exactly at the cap (1245), so raise `cap` and the cap comment, and CLAUDE.md's "(1,245)", together.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"
