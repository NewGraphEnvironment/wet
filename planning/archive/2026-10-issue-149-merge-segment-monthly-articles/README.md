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

## Owed

- [ ] After the deploy, fetch `https://newgraphenvironment.github.io/wet/articles/monthly-flow.html` and confirm it redirects. Check the deploy provenance on `gh-pages` first.

Closed by: PR (this branch, `149-merge-the-segment-discharge-and-monthly`)
