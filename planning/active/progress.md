# Progress — Article: stream temperature for every reach, from stations to a network model (#220)

## Session 2026-11-25

- Plan-mode exploration — phases approved by user
- Created branch `220-article-stream-temperature-for-every-rea` off origin/main
- Scaffolded PWF baseline from issue #220 with approved phases
- The issue body was edited during the plan gate (its closing on thresholds); the baseline carries the
  body as re-read, and Phase 3's closing section follows it

## Phase 1, 2026-11-25

- Completed: the basin table, the data script with both rules in its header, the values bundle (8 KB), its
  tests; the pick is 08EE012 (Simpson Creek at the mouth), 2020, a 29-day gap from 25 August
- Found: the reading on the day before the gap is a sensor out of the water (findings.md); shown as read, as
  the plan decided
- Corrected in the plan: season dates come from `gsdd::gss()`; no cube drop-and-retry
- Commits: the script and table, then the bundle with its tests
- Next: Phase 2, the basin map bundle

## Phase 2, 2026-11-25

- Completed: `vm_tree()`, the map script and bundle (393 KB, every stream order drawn), the colour registry,
  the map's tests
- The plan review returned (`review-220.md`: one blocker, the recipe; no owner fork) and was folded into the
  plan and both scripts: the values bundle was rebuilt with the basin's code, the candidates' run lengths
  and a second fill with the day before the gap hidden (that reading is worth 67 °C-days of the year's 1,460)
- Commits: the helper, script and registry; the review's script changes; the rebuilt values; the map bundle
  with the tests and this record
- Next: Phase 3, the article

## Phase 3, 2026-11-25

- Completed: the article (four figures, 1,066 words), the chain's two tables and their test, the `.bib`
  (25 entries; one reference added to Zotero), the recipe guard in the data script, `_pkgdown.yml`, README
- Found: `wet_temp_daily()` differs in the last bits between two reads of one archive, so the bundle is held
  to a tolerance; the empty-cache rerun then left it as it is
- Commits: the draft with the recipe guard; the rebuilt values; the tolerance; the article as written
- Next: Phase 4, proof and records
