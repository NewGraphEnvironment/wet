# Code-check round 3 (#235)

## Checklist read

- code-check.md: the prose of every H3 under `## Mechanisms` (table rows skipped), in full for "A guard that fails toward pass", "A fixture that cannot reach the failure mode", "Zero-length, empty, and unset are three different things", "A guard's scope, escape hatches, and remedies", "Verification that reads its own output" and "One fact derived twice"; the rest from the index lines. Rules that stand alone, Security, Spreadsheets and PDFs: from the index only (none names a tool or shape this diff uses beyond the above).
- code-check-r.md: read in full "`ifelse()` with an all-NA test returns a logical vector", "`data.frame()` recycles a scalar against a zero-length column", "`paste()` with a zero-length argument returns length ONE", "`read.delim()` quotes by default"; applied from the index "`on.exit()` at a script's top level never fires", "`identical()` on two reader results", "`as.POSIXct` on character infers ONE format", "`sort()` and `order()` collate by `LC_COLLATE`", "`deparse()` re-encodes non-ASCII", "A `function(...)` mock hides arguments", "testthat counts an uncaught error under `error`". About 150 other headings not read (no matching tool or shape).
- code-check-shell.md: none read (the diff holds no shell code beyond `aws` calls through `system2()`, already covered in round 1).
- code-check-spatial.md: none read in full; "FWA `upstream_route_measure` misses the next segment's start" and "A Freshwater Atlas main stem's downstream end" applied from the index to the placement script.

## Mechanism

The three earlier findings share one assumption: that the case the author had in mind is the whole population, so a statement written from the design is taken as true of the artifact without being checked against it. A degree sign was assumed harmless in R code because the reader worked; an empty hour table was assumed impossible because real series have kept hours; Whitesail was named clock-shifted because a shift was the expected explanation. The shape that remains in this diff is the same one in prose: a count or scope inherited from one list (the code comment's numbered four steps, which include the hour rule) and restated in a sentence whose own enumeration is different.

Places the mechanism reaches, each checked:

- Roxygen of `wet_temp_daily()` and `man/wet_temp_daily.Rd`:
  - "about 340 BC stations": findings.md records 342 on 2026-11-27. Holds.
  - "32 sites, 2019-2024, 15-minute readings, CC BY 4.0, Zenodo record 15053907": registry 32 rows; report 2019-06-27 to 2024-12-15. Holds.
  - "four more rules ... in this order:" followed by three rules. **Contradicted (finding 1).**
  - "more than 154 hours", "above 0.5 degrees C", "May-September", "no gap over 6 hours", "12.09 to 18.38": the constants in `R/wet_logger_daily.R` and the threshold report. Holds.
  - "A series that cannot be read is skipped with a warning": `tryCatch()` around `wet_logger_daily()` per series; tested. Holds.
  - Example "14 MB": `01_Data.zip` 13,830,401 bytes. Holds. "Otter Creek below Finger Lake" is NHG_01FW007. Holds.
  - `t_min_c`/`t_max_c` "over the readings themselves": logger `v_min`/`v_max` are per-hour min/max of the readings, then min/max over the day. Holds, as in the ECCC SQL.
- Roxygen of `wet_temp_fill()` (`pool` from the registry's `subdrainage`): the registry carries it, and the test pools through it. Holds.
- NEWS.md: 32 sites, 2019-2024, ids, checksums (data-raw takes them from Zenodo's API), three screens named, "30 complete growing seasons at 22 sites", "28 sites placed ... main-flow tree". All agree with the report (summed from its per-site table: 30/22, 24/18, 142 site-years). Holds.
- CLAUDE.md: "four logger rules in order (stuck runs ..., the hour rule, deployment ends, air days ...)" names four and lists four, matching the code comment. Holds.
- research/station_water_temperature.md, "Logger records":
  - "with four more rules that apply to logger series only", then rule 2 "The hour rule, as for the archive". **Contradicted (part of finding 1).**
  - Rules 1, 3, 4 and their constants: agree with the code and the threshold report.
  - Amendment 1 numbers (3,314 h, 676 h, 687 h, 24.97, 6 station-years, 168 h, 135 days, 20 degC): agree with the threshold report. "August ranges reached 35.5 degC": printed by no tracked report (the report's "Unscreened" line gives percentiles only; its `max` column is screened); also in the script's header. Not contradicted; no tracked producer.
  - The Nechako paragraph: 87 % (770,925 / 884,865 = 0.871); Chedakuz 18,684 vs 9,936; Endako 15,581 vs 14,496; Whitesail about a sixth at every alignment (5,800-6,012 of 36,334); 0.51 and 0.08 degC. Agree with the report. "stamp an hour twice at the autumn and spring clock changes": measured on the earlier record's files here; duplicated stamps at 2019-11-03 08 and 2020-11-01 08 UTC (autumn, five files) and 2021-03-14 10 UTC (spring, Whitesail). Holds.
  - Bullets: 34,778 / 34,017 / 650 / 100 / 11 / 0; 3,153 flagged kept days; 30 at 22, 24 at 18; 31 of 32 at 365; 28 placed, 24 name and 4 nearest, all on tree, four lake sites unplaced; 0.46 and 0.50 km; 08J 29, 08K 3 (registry table). Agree with the report and registry.
  - Series table: 6426024 spans 2019-07-13 to 2021-10-29 in its files ("2019-2021"). Holds.
- Code comments in `R/wet_logger_daily.R`: the four numbered rules and their order agree with the `ifelse()` chain (stuck only on a short day that lost stuck hours, then hours, deployment, air). Holds.
- Zero-length paths, `R/wet_logger_daily.R`:
  - `wet_logger_days()`: no valid reading returns the typed empty frame; every hour stuck returns one "stuck" row per day (round 2's fix, tested); otherwise `d` is non-empty, `diff()` on length 1 is fine, `tapply()` levels are numeric-sorted group ids, and the nested `ifelse()` assigns `NA_character_` so the column stays character even when every test is FALSE. Holds.
  - `wet_logger_daily()`: no matching registry rows gives `split()` an empty list and the result is `wet_temp_empty()`; a site with no kept day returns `NULL`, dropped by `rbind`; `data.frame()` is built only after `nrow(d) > 0`. Holds.
  - `wet_logger_registry()` with no series returns a typed empty frame. Holds.
  - `wet_logger_read()` on a header-only file returns a zero-row frame that `wet_logger_days()` takes to its empty return. Holds.
- Zero-length paths, `R/wet_temp_daily.R`: `match()` against an empty registry gives all NA, so every id goes to ECCC; the loop over `intersect(sources, series)` runs zero times when no logger id is asked; `rbind` starts from `wet_temp_empty()`. Holds.

## Findings

- **[severity: fragile]** R/wet_temp_daily.R:44-46 (roxygen, "Logger records"; rendered at man/wet_temp_daily.Rd:92-93) and research/station_water_temperature.md:45 — the count of logger rules contradicts its own list. The roxygen says "four more rules screen what a gauge does not need screening for, in this order:" and then names three (stuck runs, deployment ends, air days; the hour rule is mentioned only as what the stuck rule comes before, and it is one of "the steps above"). The research file says "four more rules that apply to logger series only, in this order", and its rule 2 is "The hour rule, as for the archive", which is not logger-only. Both inherit "four" from the code comment's numbered list (R/wet_logger_daily.R:156-165), where counting the hour rule is correct, and restate it in sentences that scope it differently. A reader of the help page looks for a fourth screen that does not exist. Fix: "three more rules" in the roxygen, and in the research file either "three more rules ... (the hour rule keeps its place between the first two)" or "four rules, three of them for logger series only".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (list every quantified or inherited claim with a measured verdict)

index, diff and changed files read from file
