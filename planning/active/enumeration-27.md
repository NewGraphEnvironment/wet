# Enumeration of computed claims: station-flow vignette (#27 Chinook revision)

Code-check round 2 found a defect inside round 1's fix: the figure 2 caption lost the "1981–2010" qualifier. Under `/code-check` that means only an enumeration ends the loop. The mechanism behind both instances is **prose whose wording asserts a qualifier — a direction, a scope, a quantifier or a comparison — around a computed value, where the computation enforces the value but not the qualifier.**

The candidate set was extracted mechanically from `vignettes/station-flow.Rmd`, every `` `r …` `` outside code fences: 49 inline expressions in prose and 5 `fig.cap` captions. The table below covers every one whose surrounding wording carries a qualifier. The rest are definitional (`base_text`, `recent_text`, `alpha`, provenance fields).

| # | Claim (wording) | Computed from | Qualifier enforced by |
|---|---|---|---|
| 1–3 | adults migrate from / spawn from / fry move from `w_start` | `windows`, the filtered CSV rows | `stopifnot(identical(life_stage, …))`; recipe dates `stopifnot` |
| 6 | incubation/emergence "reach into November–April" | `out`, the rows `touches_ice()` flagged | definition of `out` |
| 7 | "Both stations are at Houston … gauge sits just downstream … drains X%" | `catch` areas | containment > 0.99; **new:** station–Houston distance < 5 km |
| 10 | "Every window at both stations was below normal in Y" | `low_years`: all `kr$pct < 100` | definition; `length >= 2` |
| 12–13 | "a typical year falling under a mean … median year sits at A–B% of the mean" | `ref$median_pct` | **new:** `med_range[2] < 100` |
| 14–15 | "but N of those M were drier than nine years in ten" | `low$value < low$q10` | `n_dec > 0`; `value` numeric (round-0 silent-NULL fix) |
| 17 | "N were drier than any" | `value < q_min` | grammatical at 0; no qualifier |
| 18–21 | "The lowest was …" | `which.min(kr$pct)` over all 30 | definition |
| 22–23 | "Y was the exception, with W above normal at both stations" | `up_years`, `up_both` | `length(up_years) == 1`; `up_both` non-empty; low ∪ up = recent by construction |
| 24–25 | "same side of normal in N of M … partly by construction, because one catchment holds the other" | `agree` | containment guard |
| 29–30 | "08EE003 has no complete window in G" | `gap`, the years with no `stats` row; `wet_window_stats()` emits no row under `min_frac` | checked: R/wet_window_stats.R:183 |
| 32–36 | "Of N slopes, K are significant … all negative" | `tr` | `sign_text` branches |
| 37 | "not independent: fry migration shares S of its days with spawning" | `shared` | **new:** `shared > 0` |
| 38–40 | "'from 2000' starts in Y" | `start_003` | `all(start_003 > 2000)` |
| 41–42 | "Approved HYDAT ends …, so N of the five years rest on provisional flows" | `kf$status` | **new:** `n_prov > 0` |
| 43–45 | "has a shorter normal … 1981–2010 baseline has complete windows in S only" | `base_span` (cut to baseline years) | round-2 fix: `base_span != base_text`; qualifier "1981–2010 baseline" in the bullet and caption |
| 46 | "fry migration citation is carried over from a neighbouring watershed's row" | `ch$note` matches "other area" | `stopifnot(identical(borrowed, "Fry migration"))`, and one source key |
| cap_map | "lies inside … so the two records are not independent" | `catch` | containment guard |
| cap_recent | "At 08EE003, the 1981–2010 baseline has complete windows in S only" | `base_span` | as #43–45 |
| cap_hydro | "drawn only on days with at least 10 years" | `band$n >= min_baseline` | definition |
| cap_heat | "Blank cells have under 80% of their days" | `formals(wet_window_stats)$min_frac` | definition |
| cap_trend | slope units; "filled where p < alpha" | `tr$sig` | definition |

Result: 4 qualifiers were unguarded (marked **new**) and are now guarded. Each renders unchanged against today's data. No qualifier in the set rests on an unenforced condition.

## Round 3: typed nouns carry qualifiers too

Round 3 named a wider mechanism. **A plain word in the prose ("complete", "window-years", "at Houston", "under the mean") takes its meaning from somewhere the sentence does not show:** a function default, a counting unit that changes between sentences, a distance threshold, or a rounding applied after the guard. The table above indexed only inline code, so it could not see these words. Round 1's own fix introduced "complete window". The fixes:

| Word | Was | Now |
|---|---|---|
| "complete window" | meant ≥ `min_frac` (80%) of days, undefined in prose | "a window with 80% of its days", with `need_text` from `formals(wet_window_stats)$min_frac`; the limits define it |
| "window-years" | 24 (station × window × year) and 15 (window × year) in one paragraph | "bars" for the 24, and "for each window and year … cases" for the 15; NEWS and research say "station-window values" and "15 pairs" |
| "at Houston" | guarded at < 5 km against 4.6 km | "near Houston", guarded at < 10 km |
| "under the mean" | guard on the unrounded median | guard on `round(med_range[2])`, the printed value |
| `base_span` | pooled min–max across windows | `years_text()` of the one year set, asserted identical across windows |
| "continuous record from 2010" (research) | false: 2025 gaps | gaps named, with the three partial windows and their day counts |
| partial windows | undisclosed: 3 of 30 bars at 80–91% of days | limits bullet, computed from `n_days`, guarded `nrow(part) > 0`; hydrograph lines break at missing days |

## Round 4: the loop ends on the enumeration

Round 4 wrote the terminal enumeration: every rendered sentence and caption, 44 rows, each marked OK or FINDING, with the meaning of each qualifier traced to the code that sets it. It is in `review-round4.md`. Round 4 also mutation-tested the four new guards, and each stopped the render. A control showed the old unrounded median guard did not stop it. Five findings, none a wrong number, all fixed:

- **The hydrograph band's baseline.** It used every approved day in 1981–2010, so it included 08EE003's September–October 2010 and the 2000–2009 spot values. It now uses the same station-years as the window means.
- **Missing baseline years are stated for every station and window,** computed. 08EE013 lacks 1984 in spawning and fry migration, which no sentence said before.
- **"Joins the Bulkley in the town"** is guarded at 08EE013 within 1 km of Houston; it measures 280 m.
- **"Have flow"/"no flow" became "a recorded flow"/"no record".** A guard asserts there are no zero-flow days in May–October, so a break in a line means a missing record.
- **The research file's "2022 was wet"** is now scoped to migration and fry migration.
