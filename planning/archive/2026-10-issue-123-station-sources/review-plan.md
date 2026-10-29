# Plan review — #123 (Plan agent, 2026-10-28)

Spawned 21:34 UTC after the baseline (323a655); delivered by message, written here by the parent. Every file:line claim below was checked against the code before folding (departure_pilot.R:28-29, 46, 49-52, 211-214; wet_window_stats.R:71; wet_station_select.R:5-7; wb_fit_lib.R:34-40). All findings folded into `task_plan.md`.

**Blocker 1. The station threshold can't be computed from station lists.** The bar needs "≥ 3 complete years in some Chinook window". In the pilot, complete is a row `wet_window_stats()` returns at `min_frac = 0.8`, which takes daily values. A first/last year doesn't show gaps, and seasonal gauges are exactly the gappy case. Fix: the probe pulls dailies for every non-HYDAT discharge station whose source can serve them and applies `wet_window_stats()`; otherwise a period-of-record proxy tagged `[I]`, which alone never reaches harvest. Do not use `wet_station_select()`'s complete year (12 full months; seasonal gauges never qualify). → folded (decision 3 pin; Phase 3).

**Assumption 1. The window is ambiguous.** "Some Chinook window (05-01–09-15)" spans both windows; the pilot's pool counted migration only. Pin: migration OR spawning, each complete at `min_frac = 0.8`. → folded (decision 3 pin).

**Gap 1. Regulation.** The pilot pool was `REGULATED = 0` only; non-HYDAT lists rarely carry a flag. Record regulation per station (natural, regulated, unknown). → folded.

**Gap 2. A site match is not a duplicate.** A gauge at a discontinued HYDAT site that adds years would be called a duplicate. Test period overlap; count "same site, new years" separately. → folded (verdict "no").

**Gap 3. The HYDAT match.** Number matching only helps sources storing WSC IDs; stream names need normalising; list near misses (≤ 1 km different name, same name 1–3 km) for a hand check; old HYDAT coordinates can be off by more than 1 km; match against all of `STATIONS` (stage-only, discontinued, AB/YT/US). → folded (Phase 3).

**Gap 4. DataStream API terms.** Possibly needs a key: env var, never committed, report names sources needing credentials. → folded.

**Scope 1. Cited HYDAT counts** (runoff_prior_art.md:78) came from an unpinned local HYDAT; recount on 20260717. → folded.

**Ordering 1. Cache-or-fetch mode** so a rerun on the same snapshots reproduces the report. → folded.

**Gap 5. Conventions.** HYDAT via `WET_HYDAT_RELEASE` → `wb_hydat()`, refuse other releases; report named by release (`station_sources_20260717.txt`), snapshot dates inside; no timestamp; `code_md5`. → folded.

**Acceptance.** "Every URL answers" contradicts recording dead links: check recorded status against curl instead. "Every `[M]` greps to a report line" fails for desk measurements: restrict to probe output, or name the command. "Identical given same snapshots" needs the cache mode. Point 6 is answered once, org-wide; a recorded negative satisfies it. → folded.

**Dropped from the issue.** Record lengths per source (point 5); the rating's maintainer (point 1); seasonal-only stations counted explicitly under the lower bar. → folded.
