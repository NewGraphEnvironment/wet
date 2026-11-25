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

## Phase 4, 2026-11-25

- Completed: two identical pkgdown builds; four broken facts each stop the build; a cold read (the reader
  could say what goes to a network model and what comes back) and the revision it prompted; the page sent
  for a phone read; `CLAUDE.md`; the whole suite (541 tests, 0 failed, 9 skipped elsewhere)
- Filed: #222 (a reading that is not water, beside a gap, is carried into the fill) and #224
  (`wet_temp_daily()` differs in the last bits between reads)
- Commits: the instructions; the cold-read revision; this record
- Next: `/code-check branch`, then the archive and the pull request

## Review and wording, 2026-11-25

- Completed: four review rounds (14 findings fixed; round 4's table of 189 claims found none wrong); the
  owner's wording rules applied; two wording changes he approved; a second cold read as an outside modeller
  and the wording it prompted; three identical pkgdown builds
- Also: the logger issue's body (#215) gained the Skeena temperature sources, at the owner's request
- Held: nothing is pushed. The owner reads the rendered page first (his rule); then one review round on the
  wording changed after round 4, the verdict, the archive and the pull request
- Commits: one per round's fixes, the wording pass, the heading and small-streams change, the legend order,
  the outside-modeller wording
- Later the same day: the owner read the page, the basin was named as an example of a province-wide aim, a
  fifth short round reviewed the last wording (2 items fixed), and the verdict was written (enumeration, 5
  rounds). Next: the archive and the pull request
