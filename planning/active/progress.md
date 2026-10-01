# Progress — Vignette: flow in species windows at two real-time stations (#27)

## Session 2026-10-01

- Plan-mode exploration — phases approved by user ("go all phases")
- Created branch `27-vignette-flow-in-species-windows-at-two` off main
- Scaffolded PWF baseline from issue #27 with approved phases
- Next: start Phase 1
- Phase 1: `_pkgdown.yml`, pkgdown workflow (drift origin/main's, which removes CLAUDE.md before the build and fails on an unexpected root page), DESCRIPTION (URL, VignetteBuilder, Suggests, gq Remote), ignores. `check_pkgdown()` clean; local `build_site(install = TRUE)` rc 0 (needs install: wet is not installed on this machine). Local build renders CLAUDE.html into gitignored docs/; CI removes CLAUDE.md first.
- Phase 2: `data-raw/station_vignette_data.R` run; 61 KB bundled; `test-vignette_data.R` 13 pass. Corrected the plan's duplicate-row claim (it was a misread).
