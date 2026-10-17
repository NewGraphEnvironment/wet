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
| `pkgdown::init_site()` into a scratch destination still wrote `pkgdown/favicon/` in the repo | Removed it (untracked, made by that run); build only home + reference into scratch |

## Plan review (Plan agent, delivered 2026-10-17 ~06:45 UTC)

Acted on: window functions moved to a "Date windows" group, since flow and temperature share them; `wet_month_days` placed next to `wet_mm_to_m3s`; the dead `devtools::load_all()` dropped from the figure script (PNG byte-identical); the opening now says the flow is a modelled long-term average and mentions temperature gap filling; a Learn more line for the water-temperature reference section; water-temp-bc moved from Ecosystem (packages) into Data; Phase 2 text brought in line with the landed script.

Checked and already true of the landed README: "almost every" (not "every") stream, since 374,598 of 4,907,441 segments have neither source; no "departures" claim (cd computes them); the example does not claim to return the default (`wet_segment_monthly()` has no `pick`); no Pipelines block; no counts or periods in the prose.

Left open, for the user:
- **NOTICE.** The published manifest says the balance contains modified Copernicus (C3S, ERA5-Land) information, and the bucket republishes PCIC's routed flow. The repo itself carries only derived values in `inst/vignette-data/` (routed and balance annual values at gauges, picks on rivers). The convention asks for a NOTICE where the repo redistributes someone else's data. This branch adds none; that decision is the user's.
- The GitHub About was changed outside the PR (before: "Stream discharge for BC's Freshwater Atlas: monthly and seasonal flow per segment, historical and climate-scenario, from modelled runoff and hydrometric stations"; after: the tagline). Record it in the PR body.
- CITATION.cff picks up New Graph Environment Ltd. only after merge (the workflow runs on pushes to main that touch DESCRIPTION).

## Code-check enumeration (round 3 found a defect inside round 2's rewording)

Mechanism: a sentence naming a set by its best-known members (rounds 1 and 3). The set is the 8 `_pkgdown.yml` group descs × 46 members, walked against each member's Rd title, plus the README and DESCRIPTION claims that rounds 1–3 each enumerated in full (44, 48 and all set-naming sentences). Three descs missed a member and were reworded: water-balance inputs (temperature normals → "Climate normals"), watersheds (conversion to discharge: `wet_mm_to_m3s`, `wet_month_days`), date windows (`wet_windows_calendar` defines windows). The other five hold member by member. This enumeration ends the loop.
