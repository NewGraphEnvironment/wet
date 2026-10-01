# Plan review — #27 (Plan agent, 2026-10-01)

Ran concurrently after Phases 1–2 had landed; written here by the parent, since Plan agents have no Write tool. Each finding is followed by what was done with it.

- **Blocker: none.**
- **Gap 1: the hydrograph shows the provisional winter days the strip drops.** Kept on purpose. The prose names those dashed lines as the reason for the drop, which is what the user asked for at the plan gate.
- **Gap 2: gq registry.**
  - A class colour is read only from `fill_color`; I confirmed this in gq's source and it is not a bug.
  - All columns must be present; the header was copied from drift.
  - Window strips use the registry's `hydrograph/window` class, and heat-strip classes were added for `dropped` and `no_baseline`.
  - `recent_year` switched to ordinal classes, with labels taken from the data.
  - There is no `station` layer: stations are facets.
- **Gap 3: compute the drop once.** A single `stats$dropped` column drives the strip, the dropped-years sentence and the cd input. `touches_ice` is deliberately duplicated between the script and the vignette (6 lines, commented).
- **Gap 4.** The trend figure shows both `trend_start` values (colour). The strip runs from 1981. All 11 strips are kept, and the y ticks are suppressed among them.
- **Gap 5.** Added the `cd (>= 0.5.0)` pin. The slope axis is labelled "percentage points of normal per year". The ±200 cap is covered by the "More than 100% above" bin.
- **Gap 6.**
  - `CITATION.cff` NOTE: predates this branch, left alone.
  - No `scales::` calls.
  - `fig.width`/`fig.height` set.
  - Index entry matches the title.
  - Zero flows filtered before the log axis.
- **Gap 7: CI is slow.** Accepted; the PR's CI will be watched.
- **Assumption 1: no duplicate CSV rows.** Confirmed and corrected in the plan and findings.
- **Assumption 2: the drop reaches spring windows** (CH emergence, ST spawning). The rule was kept as is at the user's decision, and the vignette lists every dropped window-year.
- **Assumption 3.** 08EE003's refused windows appear as "Under 10 baseline years" in the strip; the trend caption says a missing point means too few baseline years.
- **Assumption 4: per-cell ice marks carry no information.** Removed the dots and stated it once, computed (median-year ice share of the incubation windows).
- **Assumption 6: the private knowledge table is bundled into a package that will go public.** Flagged for the public flip.
- **Ordering.** `fs::dir_create` replaced with `dir.create`, and the incorrect duplicate-row comment fixed.
- **Scope.** README links the Rmd, not the site (404 while private).
- **Acceptance.**
  - Word cap set to 600 (485 at the time); proved it fires with a cap of 400 on a copy.
  - The check bar is 0 errors and 0 warnings.
