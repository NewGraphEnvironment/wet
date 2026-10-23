# Progress — Monthly-flow article: Chinook windows from the published daily flow (#107)

## Session 2026-10-23

- Plan-mode exploration — the issue's parked plan (2026-10-20) verified against the code; phases approved by user ("all phases to the PR")
- Created branch `107-monthly-flow-article-chinook-windows-fro` off main (5bc6cc2, v0.4.16)
- Scaffolded PWF baseline from issue #107 with approved phases
- Next: start Phase 1
- Phase 1: script committed (fa5e5a1), first run refused (m1's `pcic.subbasin_daily` empty), loaded the run's days (90 s), balance-days check narrowed to the watersheds the bundle holds (cd4c3c4), bundle rebuilt (7c0b4e2): 8 checks, 0 differing, 0 ties, 134 KB
- Phase 2: the bundle test, failing on the old bundle and passing on the new (fa5e5a1); also fixed the segment-values test for #99's `daily`
- Plan review (background, unnamed): 12 findings in `review-plan.md`; 7 already covered, 5 taken
- Phase 3: the article, `CLAUDE.md` paragraph; rendered before and after and diffed (findings.md)
- Next: full `devtools::test()` (running), `/code-check branch`, archive, PR
- `devtools::test()`: FAIL 0, WARN 0, PASS 1318 (`data/logs/107/devtools_test.log`); `lintr::lint_package()` only pre-existing lints; `pkgdown::check_pkgdown()` clean
- `/code-check branch` round 1 spawned 03:27 UTC
- Round 1 (03:27-03:34 UTC): 1 finding (fragile), fixed: the Validation sentence on which segments' balance days were made again now branches on `shape_stations`
- Round 2 (03:34-03:40 UTC): 1 finding (fragile), fixed: Limits said "the scores below" for a section above; also took its wording note, a fall printed signed, now `drop_of()` (unsigned, sign asserted)
- Round 3 (03:42-03:50 UTC): 1 finding (fragile), fixed: the Limits bullet said the balance's shape is "not the gauge's own", false on a calibration gauge's segment. The reviewer named the mechanism (prose stating a fact with no guard tying it to the data) and enumerated every changed sentence stating a count, direction, sign, position or set (`review-round3.md`): all tied except that one and the layout/contract sentences the data cannot move. Loop ended by enumeration after three rounds; no round found a defect inside an earlier fix.
