# Plan review (#152), Plan agent, delivered 2026-10-30

The reviewer read the plan, the issue and the code while the Phase 3 bodies were uncommitted. Findings, each with the disposition taken:

## Blockers
- **B1** `vignette_bib.R` stops on the fwapg fork's `/tree/newgraph` url. **Fixed**: the url regex takes an optional `/tree/<branch>`, which goes into the title.
- **B2** The articles cannot be validated against the `.bib` until Better BibTeX returns. **Taken**: prose and guards first, `.bib` last per article. Acceptance waits on Phase 6.

## Ordering
- **O1** Code-check the site scripts before the m4 runs. **Too late**: the runs were already in flight. The branch code-check reviews them, and a finding means a rerun.
- **O2** The reruns overwrite #126's `data/departure/*.rds` on m4. **Accepted**: the rerun rds hold #126's `mx` plus `p152`. Main's scripts refuse them by md5 until merge. m4 stays on the branch through Phase 4.
- **O3** `vd_commit()` refuses untracked files. **Taken**: commit before every m4 data run.
- **O4** Phase 2's bullet is stale. **Fixed** in task_plan.md.

## Gaps
- **G1** The coverage simulation is iid and has no donor change between the periods. **Kept as registered**. The article states what the range does not cover (autocorrelated years, a donor set that differs between the periods).
- **G2** Monte Carlo noise against a cell-wise 0.87 bar. **Kept as registered**: a noisy failure only relabels the range as resamples and cuts counts, the conservative side. The rule was registered before any site result was seen, so it is not changed after.
- **G3** The coverage outcome should be a guard. **Taken**: the bundle carries `cover`/`cover_c`, and the article builds its label from them.
- **G4** The measured article's outcome is undefined either way. **Settled**: it failed (0.834–0.867), so the label stays as resamples, with a comment citing the report.
- **G5–G7** Measured article: `recent`, Buck Creek's 2016, the hard-coded "five". **Fixed** (41a3ffb).
- **G8** The rebuilt article hard-codes its periods. **Taken**: the bundle gains `periods`, and the captions and `per` read it.
- **G9** `tests/testthat/test-vignette_data.R` checks the bundle's names. **Taken** in Phase 4.
- **G10** min7 has its own held-out scores. **Taken** in Phase 5.
- **G11** The snow-gauge fits are already in the bundle; say how the gauges were chosen. **Taken**.
- **G12** Section 5 does not name its registration commit. **Not taken**: the header records it (b66b577), and naming it in the output would change the md5 of every run.

## Assumptions
- **A1** The published build and the cd layers may have drifted since #126. **Checked after the run**: `git diff` of the reports must show additions only.
- **A2** `cd`'s recent default is 2015–2025. **Taken**: the articles say 1951–1980 is cd's reference period only, and that ERA5-Land reaches back to 1950.

## Scope
- README line 43 ("how it has trended since"); CLAUDE.md lines 43 and 45; `years` left identical. **Taken** in Phases 4 and 9.
