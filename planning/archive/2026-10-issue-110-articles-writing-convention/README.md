# #110: the three articles brought to soul's writing convention

## Outcome

The segment-discharge and station-flow articles now set their software in code font, link each name, and end in a computed "Software and citation" section. Each section's package lines come from the internal `wet_software_cite()`, lifted from monthly-flow's inline chunk. Dated words and the open fwapg#24 pointer are gone. segment-discharge's Validation section became the opening of its citation section, the zone adjustment is described as kept by decision, and the score table's note sits in a `kableExtra` footnote. station-flow defines Theil–Sen and Mann–Kendall where its Trends section reads them, and cites them.

The branch review found what the convention's checklist did not name. Provenance sentences in the closing sections claimed more than the bundle scripts check: "every value was checked", "the numbers are the published product's", and a Data line read as a complete input list. They had been written from memory of the pipeline, naming the best-known source and claiming it for the whole population. The same over-wide claims were in monthly-flow's closing paragraph from #107, so this branch corrected that paragraph too. All three now say which numbers come from where.

Moving the helper to `xciter` once a second repo needs it is NewGraphEnvironment/xciter#6.

## Decisions

- **Word caps unchanged.** Each guard counts body prose up to `## Software and citation`, and refuses a missing or duplicated heading. The user accepted this at the plan gate on 2026-10-23.
- **The helper is internal to wet, not in `xciter`.** The user asked, then judged the dependency not worth it yet, on 2026-10-23.

## Measurement

Body prose words, counted by each article's own guard:

| article | before | after | cap |
|---|---|---|---|
| segment-discharge | 899 | 829 | 900 |
| station-flow | 535 | 581 | 600 |
| monthly-flow | 1,762 | 1,762 | none |

monthly-flow's changes sit in its closing section, outside the count. The files went from 414 to 453 lines for segment-discharge, 659 to 703 for station-flow, and 877 to 878 for monthly-flow. No word forecast was set; the floor was the sections each article keeps plus the new software wording. monthly-flow's rendered text was identical to main's after the helper swap, until the review's fixes to its closing paragraph.

`/code-check branch` ran four rounds and a closing enumeration, six agents with the plan review:

| Round | Findings | Fixed | Accepted | Inside previous fix? |
|---|---|---|---|---|
| 1 | 3 | 3 | 0 | — |
| 2 | 3 | 3 | 0 | y (same paragraph, same over-wide claim) |
| 3 | 3, plus monthly-flow's paragraph outside the branch | 3, plus monthly-flow | 0 | y ("every published value" left from round 1) |
| 4 | 4 of 47 claim sentences fail, 3 judgement calls | 4, plus 2 of the judgement calls | 1 (CLAUDE.md text unchanged on the branch) | y (2 in round 3's monthly-flow rewrite) |

The loop ended on an enumeration, not a quiet round. Round 4 listed every claim sentence the branch added. The seven sentences its fixes changed were each checked against their evidence in `review-enumeration.md`, and all hold.

## Evidence

The plan review is in `review-plan.md`, the rounds in `review-round*.md` and the closing table in `review-enumeration.md`. The rendered before and after texts were compared in the session and are not kept.

## Owed

- pkgdown deploy: confirm the three articles on the live site carry their "Software and citation" sections, by checking the gh-pages provenance.

Closed by: PR #114.
