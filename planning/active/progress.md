# Progress — README: correct the link connection, list all three vignettes, describe the published product (#75)

## Session 2026-10-16

- Plan-mode exploration — phases approved by user (full readme.md convention, with figure)
- Created branch `75-readme-correct-the-link-connection-list` off main
- Scaffolded PWF baseline from issue #75 with approved phases
- Next: start Phase 1
- Phase 1: `_pkgdown.yml` gets seven `reference:` sections covering all 46 exports; `pkgdown::check_pkgdown()` reports no problems
- Phase 2: `data-raw/readme_figure.R` writes `man/figures/readme-pick.png` (1050x960, no alpha), the segment article's pick map without gauges or labels, per the user's "big picture" steer. Self-review at 700 px: fills frame, legend over Yukon, scale bar over ocean, both classes in legend
