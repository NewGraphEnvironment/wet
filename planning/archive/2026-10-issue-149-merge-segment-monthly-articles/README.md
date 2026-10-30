## Outcome

"Monthly Flow per Segment" (`vignettes/monthly-flow.Rmd`) is merged into "Stream Discharge per Segment" (`vignettes/segment-discharge.Rmd`). The result is one article on the published product, answering the reader's questions in order: what it is (yearly, monthly and daily values, two sources), which value to use (`pick`), how to read it, what a year looks like at three Bulkley gauges, how good it is, a window from months or days, and its limits. The old address `articles/monthly-flow.html` redirects through pkgdown's `redirects:`. Both data scripts and bundles are unchanged, and every surviving sentence keeps its guard. The yearly and monthly scores now share one table on one gauge set: 279 gauges where routed PCIC has flow and the segment carries at least a fifth of the gauge's flow (decided at the gate), plus the balance at all 315. The branch also fixes #80 (dropping an unused check) and the article half of #74 (`INSTALL httpfs` in the recipe).

The main lesson came from review. Merging moved sentences into new company and reworded them, and the guards beside them kept testing a number while the sentences now also asserted a quantifier, a set or a reason. Examples: "the balance is unbiased" beside a +9 % bias row, "the shape holds at most gauges" when each half did but both together held at only 46 %, and "a window starts mid-month" for a whole-month window. Two rounds found defects inside earlier fixes. The loop ended on an enumeration of all 104 factual claims against their guards (`review-round3.md`).

## Measurement

- **Body prose** (the cap rule: Rmd source up to "Software and citation"): 829 + 1,543 = **2,372 words before → 1,827 after** (−23 %; forecast 1,800–2,000; cap set at 2,000). Rendered text to the citation section: 3,203 → about 2,340. The floor came from what stayed: both maps, the hydrographs and their two paragraphs, `pick`'s rule and counts, the scoring paragraph and six weakness bullets.
- **Scores on 279 gauges, not 290** (yearly): routed PCIC MAE 24.2 → 21.5 %, bias +1.4 → +5.1 %, within ±20 % 63 → 66 %. Balance on the same gauges 27.6 → 27.2 %. Routed is closer at 168 of 279. Monthly, the two sources score about the same: median NSE 0.82 and 0.82, gauge-months within ±20 % 40 % and 42 %. My first lead said otherwise, the table contradicted it, and the lead was corrected.
- **Numbers, both ways, sign-aware:** every new number is an intended move (the 279-gauge scores, the 315-gauge NSE of 0.81). Every number gone belongs to a cut table or sentence.
- **Figures:** the Bulkley map, the hydrographs and the monthly error figure are byte-identical to the old renders. The province map alternates between two PNGs across renders of the same source, including main's, so its variation predates the merge (not traced).
- **Review cost:** four agents in all. One Plan review (`review-plan.md`) and three code-check rounds: round 1 found 3, round 2 found 9 (2 inside earlier fixes), and round 3's enumeration found 8, all fixed.

## After the PR opened: soul#578's writing rules

The user asked for the article to be checked against NewGraphEnvironment/soul#578's eight writing lessons. Fixes:
- The windows' dates are credited to New Graph's species-timing table, with Gottesfeld and Rabnett's p. 355 for what the report says. The old wording, inherited from monthly-flow, credited the report with the exact dates.
- The window section no longer leans on the four-stream article.
- The routed-shape inference states its reason in terms of each half of the shape.
- The balance's coverage is guarded.
- Both map captions name every mark.
- A sentence places the Bulkley in BC.
- Data and references are lists with anchors, and the in-text citations link to them.

Two review rounds ran (`review-578-round1.md`, `review-578-round2.md`). Round 1 found a defect inside the fix: the restored reason said "the season at all of them". Round 2 enumerated all 23 changed claims and found 2 overstated: the reason again, and a caption claiming every order-5+ stream when the map's fetch extent is narrower than its frame. Both are fixed. The extent gap is filed as wet#151, and the evidence was added to soul#578's body. Review cost for this pass: two more agents, six in all for the branch.

## After the PR opened: the user's review of the merged article

The user read the article and asked for less of what serves its authors. Changes:
- **Counts out:** row, part, size and md5 counts are gone from the prose, and segment counts became shares.
- **Coverage as a share:** coverage is now "99.9 % of segments matched to a watershed polygon". Measured, 92.4 % of all segments have a value. The unmatched 7.5 % are almost all connection lines and secondary channels, and neither source is published on them.
- **Product address moved:** the bucket, manifest and build moved from the opening to the Data list.
- **Data credit:** the Freshwater Atlas is credited to the Province, through DataBC, not to `fwapg`.
- **Citations:** references come from `vignettes/segment-discharge.bib` through pandoc, and only `citation("wet")` is printed, as the organisation's knowledge articles do. The other three articles are wet#152.
- **Bulkley map dropped:** it repeated the setting "Chinook Flow at Two Stations" already maps. Its catchments and gauge points in `monthly_map.rds` still guard the sentences on nesting and flow direction. wet#151 was closed, and the registry's `bulkley_map` rows were removed.
- **Windows' sourcing:** cut to one sentence.

Body prose went from 1,886 to 1,830 words.

Two review rounds ran (`review-user-round1.md`, `review-user-round2.md`).
- **Round 1 found 4, all fixed:**
  - "5 % of them" was a share of all segments, read as a share of the balance's;
  - the coverage wording named a different set than its guard counts;
  - the nesting guard passed on catchments that do not overlap (`stopifnot(numeric(0) > 0.99)`), which a disjoint-polygon probe confirmed;
  - two counts were left in Limits.
- **Round 2 enumerated all 28 changed claims and found 3 fragile items, all fixed:**
  - the 5 % read as extra to the 28 % (round 1's fix), so a guard now ties the balance's share to far-low plus routed-missing;
  - the References' fork commit lived in the `.bib`, which the guard never read; it now reads the `.bib`, checked both ways;
  - CLAUDE.md still said "province counts".

The lessons were added to soul#578 as rules 9 to 13. Review cost for this pass was two more agents, eight in all for the branch.

## After the PR opened: the user's second review

The user's second read changed seven things:
- **Plain term:** "windows" became "chinook salmon life history timing windows" (then "timing window"), and species names are lower case.
- **Every package cited:** each package the code and recipes use is cited inline, author-year, ours included: `wet`, both `fwapg`s, `climr`, `cd`, `duckdb`, `DBI`, `RPostgres`, `knitr`, `kableExtra`, `ggplot2`, `gq`, `sf`, `bookdown` and R. The credits are a list with one role per line.
- **High-level PCIC method:** routed PCIC is one sentence each for PCIC (VIC-GL, Schnorbus 2018; Raven, Craig et al. 2020) and the fork, which links its research notes.
- **Coverage sentence removed:** the 99.9 % was the user's example of a digestible form, not content to add.
- **Map up front:** the province map moved up under the opening paragraph.

Body prose went from 1,830 to 1,775 words. Two review rounds ran (`review-user2-round1.md`, `review-user2-round2.md`):
- **Round 1 found 5:**
  - four packages were uncited;
  - "the balance's inputs come through climr and cd" was overstated, since AET and the DEM do not;
  - sf's publisher was split by single braces;
  - a guard comment pointed at a deleted sentence;
  - "almost every stream" was guarded over matched segments with an exact 99.9 pin. It is now guarded over every segment but the unmatched connectors, at 99.8 % and above 99 %.
- **Round 2 enumerated every changed item and found 3:**
  - the Limits bullet had lost "almost all connection lines and secondary channels" and its guard, a defect inside round 1's fix;
  - `'kable'` was title-cased;
  - `bookdown` was uncited.

All are fixed. The review copy went to the user as a private claude.ai artifact instead of a PDF, which soul#580 proposes as the standing route, and the lessons went to soul#578 as rules 14 to 18. Review cost for this pass was two more agents, ten in all for the branch.

## Owed

- [ ] After the deploy, fetch `https://newgraphenvironment.github.io/wet/articles/monthly-flow.html` and confirm it redirects. Check the deploy provenance on `gh-pages` first.

Closed by: PR (this branch, `149-merge-the-segment-discharge-and-monthly`)
