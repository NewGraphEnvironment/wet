# Findings — README: correct the link connection, list all three vignettes, describe the published product (#75)

## Issue context

## Problem

The README is close to current (v0.4.4), but it states one pipeline connection that does not exist yet, and it leaves out the published product and a vignette.

## Findings

**Ahead of the code (overselling)**
- README.md:56 and :63 say link reads wet's discharge through `lnk_discharge()`. `lnk_discharge()` is internal to link and reads fwapg's discharge table today. Reading from wet is NewGraphEnvironment/link#331. Describe the intended connection as planned until that lands.

**Shipped but not in the README (underselling)**
- The third vignette, "Monthly Flow per Segment" (v0.4.2). README.md:43-48 says "both vignettes".
- The published per-segment product and its readers, `wet_catalog()`, `wet_db_load()`, `wet_segment_monthly()` (v0.4.0, v0.4.4)
- Water-temperature gap filling, `wet_temp_fill()` (v0.3.0)

**Stale**
- Vignette links use `www.newgraphenvironment.com/wet/`, while `_pkgdown.yml` uses `newgraphenvironment.github.io/wet/`. Pick one.

## Tasks

- [ ] Correct the link connection to its current state
- [ ] List all three vignettes
- [ ] Describe the published product and how to read it
- [ ] Make the docs URL consistent
- [ ] Group the `_pkgdown.yml` reference index by purpose. It has no `reference:` sections today, so the docs site shows a flat alphabetical list.

## Context

Audited 2026-10-14 against `origin/main` @ `6fa5a0a`, from README, DESCRIPTION, NEWS, NAMESPACE and vignettes. Verify each item against the code before acting. Versions cited are where a capability landed.

The New Graph website will describe this package from its README (NewGraphEnvironment/newgraphenvironment.github.io#53), so the README is the source of truth for the public one-liner. Plain language in the opening paragraph: what it does today, and what restoration planning, implementation or monitoring decision it informs.


## Premises checked 2026-10-16

- link#331 closed 2026-10-16 by link PR #344 (link v0.66.0): bundles choose `pipeline: discharge_source: fwapg | wet`; `default_tuned` reads wet's annual pick from `discharge.fwa_v1_segment_monthly` (loaded by `wet_db_load()`); `default` and `bcfishpass` stay on fwapg. `lnk_discharge()` is not exported (link NAMESPACE has only `lnk_preflight_discharge`).
- `https://newgraphenvironment.github.io/wet/` answers 301 to `https://www.newgraphenvironment.com/wet/` (curl). `_pkgdown.yml`, DESCRIPTION and link, fresh, gq, cd, flooded, drift all use github.io.
- GitHub About read: "Stream discharge for BC's Freshwater Atlas: monthly and seasonal flow per segment, historical and climate-scenario, from modelled runoff and hydrometric stations". Climate-scenario output is not built.
- `update-citation-cff.yaml` calls `cffr::cff_create()` without `authors_roles`, so CITATION.cff lacks New Graph Environment Ltd.

## Errors Encountered

| Error | Resolution |
|-------|------------|
