# Code review, round 3: #27 vignette diff (`git diff origin/main...HEAD`, HEAD 5e4d83c)

Reviewer: subagent, 2026-10-01. Read code-check.md and code-check-r.md. All probes ran on a copy (`$TMPDIR/wet_review3`). I rendered the vignette there with `load_all()`, saved the render environment, and purled the vignette to run mutations. Nothing in the repo was modified apart from this file.

## How the enumeration was checked

I extracted all 41 inline `` `r` `` expressions with `grep -no`. I listed every prose line carrying a digit or a quantifier (both, every, only, most, all, none, a month name) by parsing out the chunks. I took every `sprintf`/`paste` caption and every registry `class_label`. Each was then re-derived from the saved environment.

What re-derives correctly:
- **Rendered values, all true against their objects:**
  - March 2025 and 30 September 2026
  - 44%
  - 1971 and 2011–2026, where the Jan–Feb table matches the Figure 1 bars year by year
  - 58%–81% and 2023–2026: 8 rows, all negative
  - 6.6–15.0 and 3.9: the Dec 2025–Feb 2026 provisional months against approved DJF months since 1981, where the maximum is Dec 1989
  - the drop sentence, which matches the strip's 9 and 3 `dropped` cells exactly
  - 64% / 59%: medians over 42 years
  - 68 / 5 / 3, all negative. The 5 significant slopes are three at 08EE013 from 2000 and two at 08EE003 from 2000.
  - 2010 or 2011: 08EE003 has 0 `stats` rows in 2000–2009
  - CH incubation, ST spawning and BT incubation, with 1, 1 and 7 baseline years. Chinook incubation's one year is 2010.
  - 0.91 / 0.59 / 36%. `cd_baseline` is a plain mean over the same rows.
  - 7 of 11
  - 2026-07-17, 1 October 2026 and c97c4d0
- **Figure 2's lines carry no NA status or year.** Real-time rows are `status = "provisional"`, so "dashed where provisional" covers them.
- **Figure 3 has no NA class.** Blank cells correspond exactly to absent `stats` rows.
- **Figure 4: every window with ≥ 10 baseline years has all 4 points per station.** No slope is NA, so "A window with no point has under 10 baseline years" holds today.
- **The q_min7 baseline-year counts equal the q_mean counts in every window**, so `nb` (built on q_mean) is also right for the min7 departures.
- **"Seasonal gauge for most of its record" is supported.** 08EE003 has 41 Apr–Nov seasonal years (1930–1951 and 1980–1998), 10 near-empty years (2000–2009) and 17 winter-gauged years.
- **The provisional record carries no ice symbol.** Provisional and real-time `symbol` are all NA, so "ECCC's provisional archive records no ice symbol" is true.

## Findings

- **[severity: bug]** vignettes/station-flow.Rmd:241-244, and README.md (added line). This is the mechanism again, and the enumeration's spawning row misses it. The paragraph says:
  1. "Each recent year is drawn over the 1981–2010 normal for that day". What Figure 2 draws is the **daily median** (`band$med`) and the interquartile range of approved days.
  2. Then, in the next sentence, "both stations ran 58%–81% below normal". That figure is cd's departure from the **window mean** (`anom`), which is a different object.

  Because the mean is skewed by wet years (the limits section itself puts Buck Creek's median year at 36% below the mean), the reader looking at the key figure sees much smaller gaps than the sentence states. I measured the spawning-window mean of each recent year against the mean of the drawn median line over 1 Aug–15 Sep:

  | station | year | gap to the drawn line | stated |
  |---|---|---|---|
  | 08EE013 | 2023 | −47% | −68% |
  | 08EE013 | 2024 | −67% | −80% |
  | 08EE013 | 2025 | −53% | −72% |
  | 08EE013 | 2026 | −38% | −63% |
  | 08EE003 | 2023 | −60% | −75% |
  | 08EE003 | 2024 | −70% | −81% |
  | 08EE003 | 2025 | −54% | −72% |
  | 08EE003 | 2026 | −33% | −58% |

  The README repeats it: "the hydrograph against its 1981–2010 normal". The enumeration's spawning row checks the number against "the heat strip's departures", which is right for the number but not for the sentence: it sits in the hydrograph paragraph and points at the hydrograph's line.

  Two possible fixes:
  - Call the drawn line the median in both places, and say "below the window's 1981–2010 mean (Figure 3)".
  - Or compute the claim from `band`/`lines`.

- **[severity: fragile]** vignettes/station-flow.Rmd:386-397, 408-409. The guard `stopifnot(length(start_003) == nrow(fit))` cannot fire. `cd_trend()` emits a row only for a series with ≥ 3 anomaly rows from `trend_start`, and `a3` is that same `anom` filtered to `fit`'s series, so the two counts agree by construction. Only an NA anomaly could split them, and with ≥ 10 baseline years that cannot occur.

  What the guard should protect is unguarded: the phrasing. **Mutation, proven on the copy:** drop 08EE003's 2010 days (`daily <- daily[!(station == "08EE003" & year == 2010), ]`). The vignette then runs clean, the guard passes, and `since_2000_003` is `"2011"`, so the prose reads:

  > "from 2000" starts in 2011, depending on the window, because it has no window-years from 2000 until then

  "depending on the window" is now false. If a refresh ever gave a series starting in 2000 itself, the sentence would read "starts in 2000 … no window-years from 2000 until then". Two fixes are needed:
  - Branch the phrasing on `length(unique(start_003))`.
  - Guard `all(start_003 > trend_start[2])`, or drop the sentence when it is false.

- **[severity: fragile]** inst/cartography/wet_station.csv:22 (`no_baseline`, label "Under 10 baseline years"). This label is a literal restating `min_baseline`. The enumeration's last row ("10 … in prose, captions and legends … computed. The registry labels no longer carry years") does not hold for it: it carries no year, but it does carry the constant. **Mutation, proven on the copy:** with `min_baseline <- 15`, the render succeeds and the `classes()` guard passes. Two things then disagree:
  - The Figure 3 legend still says "Under 10 baseline years".
  - The prose and the Figure 4 caption say "under 15", and 08EE003 CO spawning (14 baseline years) now renders in that "Under 10" class.

  Fix: compute the label in the vignette (`pal_dep$labels[["no_baseline"]] <- sprintf("Under %d baseline years", min_baseline)`), the way `pal_year` and `pal_hydro` are handled. The same applies with less force to "Since 1981"/"Since 2000" (csv:23-24). The class names are guarded against `trend_start`, but the labels are not; `paste("Since", trend_start)` would close that too.

- **[severity: fragile]** vignettes/station-flow.Rmd:427, 440-441. The limits bullet says "Its `thin_003` windows have under `min_baseline` baseline years (Chinook incubation has `b3`)". The parenthetical names CH incubation unconditionally, and `b3` is read for it whether or not it is in `thin_003`. If a refresh or a knowledge change gave CH incubation ≥ 10 baseline years while another window stayed thin, the guard would still pass (`nzchar(thin_003)`), and the sentence would read "… have under 10 baseline years (Chinook incubation has 12)". Fix: guard `"CH incubation" %in% thin_003`'s source, or pick the window for the parenthetical from `thin`.

- **[severity: bug, minor]** vignettes/station-flow.Rmd:325 (Figure 3 caption) and :330. The prose says each cell is "as a percentage of its 1981–2010 mean", and the caption says "Window mean flow in % of the … normal". What is plotted is cd's `pct_normal` anomaly, `value / baseline_mean * 100 - 100`: a departure, capped at ±200. The legend reads it that way too ("50-75% below"). A window at 40% of its mean is described by the prose as "40% of normal" but drawn in the "50-75% below" class. "Departure from its 1981–2010 mean, in %" matches the object. The Figure 4 caption ("slope of the departure") is already right.

- **[severity: fragile]** Enumeration gaps, consistent today and of the restated-constant shape the mechanism names:
  - "November–April" (:333) restates `c(11:12, 1:4)` in `touches_ice`.
  - "December–February" (:334) restates `c("12", "01", "02")` in `pw`.
  - "Buck Creek" (:174, :333, :338, :443) and "Bulkley River near Houston" (:175, :408, :439) are literals. The enumeration's first row says station names come from HYDAT, which holds only for the intro's `station_label`.
  - "In the Chinook spawning window" and "Chinook incubation" are literals beside `"CH spawning"`/`"CH incubation"` keys.

  None is wrong now. The month spans are the ones a rule change would desynchronise.

- **[severity: fragile, trivial]** vignettes/station-flow.Rmd:468. The comment `# 485 at #27` is stale. The body prose is 509 words at HEAD, measured with the chunk's own counting code (and round 2 counted 519).

## Guards: which can fire (mutations on the copy)

| guard | mutation | fired? |
|---|---|---|
| `stopifnot(nrow(spawn) == …, all(spawn$anomaly < 0))` | one 2024 08EE013 CH spawning anomaly set to +5 | yes |
| same guard | daily truncated to 2026-07-20, so no 2026 spawning window-year | yes (row count) |
| `stopifnot(nzchar(thin_003))` | `min_baseline <- 1` | yes |
| `stopifnot(length(start_003) == nrow(fit))` | 2010 removed at 08EE003 | **no**: cannot fire by construction (above) |
| `classes()` `identical(names, expect)` | not mutated | can fire: a mistyped `layer_key` or a reordered row changes `names(x$values)` |
| `stopifnot(nrow(ice_win) > 0)` | not mutated | can fire: if no window has a median ice share above 0.25 |

Not re-flagged: everything listed under the accepted tradeoffs.
