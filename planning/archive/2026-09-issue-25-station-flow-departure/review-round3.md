# Review round 3 (#25): mechanism behind R1–R2, and where else it reaches

Reviewer probes ran on a copy of the repo in the session scratchpad, with `data/` excluded. Nothing in `~/Projects/repo/wet` was modified except this file.

## Mechanism

The six earlier defects share one move: **a set or an extent taken from whatever is at hand stands in for the set the rule is defined over.**

- R1a: the rows inside `from`/`to` stood in for the source's whole record.
- R1b: any HYDAT file stood in for the HYDAT the test needs.
- R1c: stations that have baseline rows stood in for all stations.
- R2a: the local R stood in for the declared R floor.
- R2b: the object the attribute was attached to stood in for everything that object flows into.
- R2c: the most common exclusion reason stood in for the whole exclusion rule.

The R1a fix then produced a second form of the same thing, **one fact derived twice under two definitions**. HYDAT's extent is now computed by two queries with two predicates, and two consumers use two different extents: continuation uses the true extent, gap reporting uses the windowed one.

The parent's enumeration is organised by symptom (Date calls, attribute sites, message strings). That is why it is complete for each symptom but misses instances of the mechanism that show up differently.

## Findings

- **[bug] scripts/station_departure.R, `thin` and `nb` (~lines 122-126, 142-148).** The "No departure (fewer than 10 baseline years)" list and the "Baseline years per window" line are built from the periods present in `s`/`sb`, not from `windows$window`. A window with no qualifying window-year at all never appears in either, so the report says "none" for it.
  - Probe: a May–Oct seasonal gauge with windows aug, sep, djf, jja, son prints `No departure ...: none` and `Baseline years per window: aug 30 jja 30 sep 30`. djf and son have no departure and are missing from both lines.
  - A station with no daily rows prints "No departure ...: none" and then "No window has 10 baseline years, so no departures", which contradict each other.
  - This is the R2c class: the message states a set taken from the data present, not the rule's domain.
  - Fix: compute over `windows$window` (a window with no `q_mean` row counts as 0 baseline years).

- **[fragile] R/wet_station_daily.R, `wet_hydat_last()`.** The SQL decides "the month has a flow" with `FLOW1..31 IS NOT NULL`. The R unpivot decides it with "a valid calendar date and a non-NA value". These are two lists that happen to agree, and only because real HYDAT leaves days past month end NULL.
  - When they disagree, the station is not given the previous valid month. It is dropped from `last` entirely, so provisional is not cut and overlaps HYDAT.
  - Probe: add a 1985-02 row whose only value is FLOW30 to the fixture. `wet_hydat_last()` returns `numeric(0)`, `wet_station_daily()` returns 12 duplicated station-days, and `wet_window_stats()` aborts with "duplicate dates within a series".
  - The same outcome follows if `wet_hydat_daily()` succeeds while the separately wrapped `wet_hydat_last()` fails (`last <- numeric()` means nothing is cut). Two `wet_daily_try()` wrappers around one fact let it half-fail.
  - The fixture edit that moved FLOW30=99 out of the shared helper removed the one input that would have shown this.
  - Fix: derive `last` from the same unpivot as the rows. For example, take `max(date)` of `wet_hydat_unpivot()` over the station's full record, in the same `wet_daily_try()`.

- **[fragile] R/wet_station_daily.R, `wet_daily_gaps(out)` (~line 88).** The fix moved continuation to each source's true last day, but the seam-gap warning still reads the rows left after `from`/`to` filtering. That is R1a's mechanism on the sibling consumer.
  - A window that starts (or ends) inside a seam gap returns the missing days with no warning, although `@return` says such a gap "is reported with a warning".
  - Probe with the test fixture (HYDAT ends 1984-12-31, provisional starts 1985-01-05): `from = "1984-12-01"` warns about the 1985-01-01..04 gap, while `from = "1985-01-02"` returns 2 rows starting 1985-01-05 and no warning.
  - Fix: warn from the per-source extents (`last` against the next source's first day), or narrow the doc.

- **[fragile, not firing today] R/wet_station_daily.R, `wet_eccc_daily()` status.** `ifelse(grepl("^Provisional", approval), "provisional", "approved")` treats any Approval it does not recognise (NA, reworded, French-first) as approved. That is a guard that fails toward pass.
  - The script's provisional-winter exclusion and `frac_provisional` both key on `status`, so a wording change would let un-ice-corrected winter flow into djf/son silently.
  - Measured today: every archive row for 08EE013/08EE003 is `Provisional/Provisoire` (1389 rows). Across 173,677 rows there are no duplicate station-days and no NULL dates, so it does not fire now.
  - Fix: map `^Final` to approved and everything else to provisional.

## The parent's enumeration, challenged

**(a) numeric→Date: complete.**
- The only numeric-to-Date conversions are lines ~52, 53, 77 and the two in `wet_hydat_last`.
- `wet_daily_after` compares numeric with `as.numeric(date)` on both sides.
- I checked the other base-R behaviours the diff relies on against the R-4-1/4-2/4-3 branch sources:
  - `as.Date.default(NULL)` returns `Date(0)` in 4.1, so `c(from, ..., after = NULL)` is safe.
  - `as.Date.character(optional =)` exists in 4.1.
  - `as.Date.POSIXct(tz = "UTC")` behaves the same.
- No further R-floor issue.

**(b) attribute sites: complete for `"last"`.**
- There is one write (`wet_eccc_daily`), one read (`attr(pv, "last")`, taken before `wet_daily_after`), and one strip.
- Probed on R 4.5: `[.data.frame` keeps custom attributes, so `pv` and `rt` carry `"last"` until the strip. That is harmless.
- The enumeration omits the pre-existing `"years"` attribute from `wet_station_select`. It also survives `[`, and the script re-sets it after subsetting (`station_mad`), so that is handled.

**(c) script messages: incomplete.**
- Missing: the "No departure" list and the "Baseline years per window" line (the finding above).
- Minor wording: the header says `ice` is the "share of the window's days flagged B". It is the share of days *present* (`mean(ice[idx][have])`), which can differ by up to 20% of the window under `min_frac = 0.8`. Not flagged as a finding.

**Mechanism not named by the parent: one fact derived twice.** It covers the SQL-vs-unpivot extent, the separate failure wrappers, and continuation-vs-gap extents. The two fragile `wet_station_daily` findings are its instances.
