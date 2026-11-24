# Code-check round 2 (#196, branch diff against 0e56d60e, HEAD 6c1194e1)

## Checklist read

- code-check.md: every H3 under `## Mechanisms`, prose only (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree; A wrapper's exit is not the work; Zero-length, empty, and unset; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Rules that stand alone, Security and Spreadsheets: Documentation Staleness from the index line only; the other 19 not read.
- code-check-r.md, read in full: Postgres row order is never fixed unless the query fixes it; `system2(stdout = TRUE)` warns on a non-zero exit; `ifelse()` with an all-NA test; `match()` treats NA as a matchable VALUE; A database driver's value is not a base R type; CSV whitespace. Checked against the index line only: `on.exit()` at a script's top level; `paste()` with a zero-length argument; `nzchar(NA)` is TRUE; `sort()` and `order()` collate by `LC_COLLATE`; `$` on a list partial-matches; `tempfile()` lives in the session tempdir. Not read: about 115.
- code-check-spatial.md, read in full: BC's water rights licence view repeats a row per licensee; A relation between FWA watershed codes is not a place; FWA lookup area follows watershed codes; A name is not a key. Index line only: The BC WFS caps an un-paged `GetFeature`; FWA main flow is not edge type 1000 alone. Not read: about 95.
- code-check-shell.md: none read (the diff has no shell code). Not read: about 110.

## How it was checked

A detached worktree of HEAD under the scratchpad, with `data/station_regulation/` symlinked in; the rule and lib sourced there and run over the cached WFS snapshot (20261124), the placement cache `placement_f8dd6b6504.rds` (the one under Amendment 2) and the snap cache; read-only queries on the local fwapg. The worktree is removed; nothing in the repo was written apart from this file.

Round 1's three fixes, checked:

- Surface mask: `cons` and `stor` (station_regulation.R:244-245) carry `u_lic$surface`, and `n_cons`, `n_stor`, `L_m3yr`, `S_m3yr` are all formed through them; `power` and `novol` carry `surface` inside the lib. The report's "counted" line (`sum(lic$candidate & lic$surface)`, 58081) now names the set the statuses use.
- `novol` against `candidate`: over the base set (Current, located, surface, consumptive or storage, kept, not rediverted; 59,727 rows) the two partition it exactly: 58,081 candidate, 1,646 novol, 0 both, 0 neither. All 880 "Total Flow" rows are novol, none a candidate; the 766 zero-or-missing novol rows match research's count; 114 rows whose own quantity is zero are candidates through their shared group's quantity (#53's split, as intended). No `v` is infinite or NaN on a candidate.
- Identifiers: every LICENCE_NUMBER, POD_NUMBER (lettered and numeric) and WLS_WRL_SYSID in the snapshot searched against the added lines of every branch commit (`git log -p 0e56d60e..HEAD`): no licence or POD number; the 18 SYSID "hits" are station numbers and counts. The status CSV holds computed columns only.
- Report and research numbers re-derived: snap legs (119/73/12, 53 not placed), status counts, reasons, the four HYDAT-regulated naturals (08EE0001, 08NM0004, 08NM0065, 08NM0033), the 1,646 = 880 + 766 split.

## Findings

- **[fragile]** R/wet_station_list.R:30-33 (and man/wet_station_list.Rd:59-62) — the exported documentation of `regulation` lists the unknown cases as not placed, basin outside BC, a power licence upstream, or no published flow, "and `"natural"` otherwise". Amendment 2's case, a licence with no volume upstream, is missing, so the contract says natural for the 18 stations the status file calls unknown with "licence with no volume upstream" (report "Why, by status"). CLAUDE.md and research/station_sources.md carry the case; the user-facing text does not. Add it to the unknown sentence and re-document.
  - **Rule:** code-check.md "Documentation Staleness"

- **[fragile]** scripts/station_regulation.R:170-203, 236, 344 — a point that is not placed in an FWA watershed is dropped with only a count ("points placed in an FWA watershed: 72023 of 72028"). An unplaced regulating dam, power POD, no-volume POD or counted POD can then never make a station regulated or unknown, so `natural` can be reached without the evidence the rule asks for, and nothing names which points were lost. Today's five are Tucker Creek Dam, a Fraser River storage POD and three spring PODs [source names redacted: the licence layer is Access Only]; I indexed each (fwa_indexpoint, 1 km, and 5 km for one spring) and none is upstream of any of the 77 natural stations, so no status is wrong now. A later snapshot gets no such check. Stop (or report each unplaced point with its class and nearest snapped station) when an unplaced point is a regulating dam, power, novol or surface candidate.
  - **Rule:** code-check.md "A guard that fails toward pass"

- **[fragile]** scripts/station_regulation_lib.R:93-95 — `surface` is `POD_SUBTYPE %in% "POD"` and `class` maps an NA purpose to "none" with no known-set check, unlike LICENCE_STATUS and the dam codes. A new POD_SUBTYPE value (or NA) reads as groundwater and drops the row out of L, S, `power` and `novol` together; an NA purpose drops it out of all four as well. Both fail toward natural. Today the snapshot holds only PG, POD and PWD, and the 6 NA-purpose rows are none of them located surface rows, so nothing moves now. `rg_codes_check(lic$POD_SUBTYPE, c("PG", "POD", "PWD"), "POD_SUBTYPE")` in the lib (not the rule file) would close it, in line with the header's "a code outside a known set stops the script".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

## Checked and found sound (not findings)

- Row order: every Postgres fetch that feeds a pick or sum is ordered on a unique key or reordered in R (`gd_ws` DISTINCT ON pid ordered by pid, watershed_feature_id; `rg_upstream_pairs` sorts; `merge()` sorts by pid), so `L_m3yr`/`S_m3yr` sums are deterministic.
- `match()` joins: no NA key on the right-hand side of any lookup (cand ids, HYDAT numbers, q0 ids); unaccepted stations are re-blanked after each join.
- `wet_station_regulation()` / `wet_regulation_of()`: missing row, wrong source, NA or out-of-vocabulary status and other-registry md5s each stop, and the test proves each.
- Report "counted", "power PODs" and "no volume" lines count the sets the statuses use (the latter two include rows not upstream of any station, as labelled).
