# Review round 3: staged diff, scripts/wb_gauge_diversion.R (#53), after the round-2 fixes

Reviewer: code-check subagent, 2026-10-07. I ran probes in the session scratchpad (`r3/`). I also ran a full copy of the repo there, with HYDAT 20260717 and the cached placement `placement_f9e69763cb.rds`. Its report is byte-identical to the staged `data/checks/wb_gauge_diversion_20260717.txt` (verdict: not gauge side). The only repo file I wrote is this one.

## Mechanism

The rule's unit is "one row = one POD of one licence-purpose". The snapshot's unit is one row per licensee × licence-purpose × POD (× flag × units). So the script holds two populations of the same thing, snapshot rows and kept PODs (`one = !dup_pod`). Downstream of them sit narrower populations: located, candidate, `u` pairs and placement pairs.

All the earlier defects share one shape. A value is computed over one population and then used or labelled as if it were over another:
- R1: per-row quantities summed as if they were per-POD.
- R1: a group maximum taken over all rows but divided over the shared PODs only.
- R1: the straddle-full "first row" taken over unmasked `u` but used on masked rows.
- R2: a POD's quantity built from repeats of any flag, while its flag and units came from the kept row (one record put together from different rows).
- R2: report counts over all rows labelled as PODs.

A second, quieter form is two lists that agree only because of the data. `g_npod` (lic: located, kept, shared) and `n_up` (u: candidate, shared) count the same PODs only because candidacy is uniform within a shared group: class, v and redivert. The code does not enforce that.

The enumeration below walks every derived quantity and every count or lookup in the script. For each it gives the population it is computed over and whether that is the one the spec or label means.

## Enumeration

| # | Line | Quantity | Population computed over | Population meant (spec / label) | OK? |
|---|---|---|---|---|---|
| 1 | 109-125 | units, m3yr, py, sy, current, start, end, class, located, surface, redivert | every snapshot row, own attributes | per row | yes |
| 2 | 127-128 | `key3`, `replaced` | all rows, any licence (Current rows from any licence) | A1 item 1: any Current row sharing POD, purpose and priority | **no for NA keys**: `paste()` makes NA the string "NA", so 7 kept rows are "replaced" by an unrelated licence's all-NA Current row (finding 2) |
| 3 | 135 | sort: located first, then id | all rows | "first located by id" | yes |
| 4 | 136-139 | `grp`, `pod_key`, `dup_pod` | all rows; NA POD keyed by id | Dev 1: licence, purpose, POD, flag, units | yes. No-POD rows are never deduped. 327 of the 9,544 are identical on licence, purpose, flag, units, quantity, status and priority; none is located, so the accounting is unaffected (see notes) |
| 5 | 141 | `m3yr_pod` | all rows of a `pod_key` (same flag and units) | quantity at a POD, the maximum over its repeats | yes. Flag, units and quantity come from one key, and `shared` is uniform within a key because the key carries flag and grp |
| 6 | 145-147 | `dp_rep` | D/P kept rows, located or not, any class | A1 item 3: the group's rows all carry one quantity, across distinct PODs | yes |
| 7 | 148 | `shared` | all rows (flag plus `dp_rep[grp]`) | M, none, or D/P-as-M | yes |
| 8 | 151 | `g_max` | shared rows of the grp, including repeats and unlocated rows (values via `m3yr_pod`) | Dev 1: the licence-purpose's quantity from the shared rows only | yes. Repeats carry the same `m3yr_pod`, and the quantity is licence-level, so unlocated rows rightly count |
| 9 | 152 | `g_npod` | located, kept, shared rows | A1 item 3: distinct located PODs | yes. A POD carrying two flags or units counts twice, an accepted tradeoff |
| 10 | 155 | `v` | shared: `g_full / g_npod`; else `m3yr_pod` | rule item 6 and Dev 1 | yes. Zero-quantity no-flag PODs in M, D-as-M or P-as-M groups get a share: 205 candidate rows, the accepted tradeoff. The largest move is 08GD008, L/obs 0.0898 → 0.0902 with them; no flag at 0.05, 0.10 or 0.20 changes |
| 11 | 158-159 | `candidate` | kept, located, consumptive or storage, v > 0, not redivert | rows that can count | yes. Every kept row with empty quantity (9,403) or a no-volume unit (1,460) has v NA, so none is a candidate |
| 12 | 200-203 | `pts` | all located rows, repeats included, plus dams | placement cache input | yes. Repeats drop at the `u` merge (accepted) |
| 13 | 226-231 | `up`, `below` | placement pairs (all located rows and dams), own-reach indexed below removed | A1 item 8 | yes |
| 14 | 250-253 | `u` | `up` ⋈ candidate rows | (gauge, counted POD) pairs | yes |
| 15 | 255-256 | `w`, `w30` | per u pair: the gauge's complete years, and 1981-2010 | A1 item 4 | yes |
| 16 | 259-260 | `n_up`, `straddle` | u pairs in shared groups, all masks | "PODs of the group upstream" against `g_npod` | yes in this snapshot. It equals `g_npod`'s population only because class, v and redivert are group-uniform (redivert is all N). The data holds this, not the code |
| 17 | 263-277 | `depth()` vol, mask, full, zero | u pairs × mask × class; full picks the first row the mask keeps per (gauge, grp) | rule "Per gauge", A1 item 3 | yes |
| 18 | 279-280 | `L`, `S` | u pairs, surface and not replaced | rule L and S | yes |
| 19 | 281-282 | `n_cons`, `n_stor` | u pairs, surface and not replaced, **any weight** (w = 0 included) | "cons", "stor": rows upstream | yes, as rows upstream (not "in force") |
| 20 | 283 | `n_dams` | `up` (below removed) ∩ dams | dams upstream | yes |
| 21 | 285-292 | `L_var` (current_only, no_replacement_removal, core, no_m3sec, w30, no_own_reach, split_zero, split_full) | u pairs under each mask | A1 items 1, 3, 4, 5, 8; registered m3/sec variant | yes. `no_m3sec` masks on each row's units while a shared row's v can come from another row's units. 1 shared group mixes units, and in none does an m3/sec row set a non-m3/sec row's share or the reverse. Holds by data |
| 22 | 294-295 | `L_gw`, `L_gw_likely` | u pairs, groundwater, not replaced, w-weighted | A1 item 6 | yes, as a depth |
| 23 | 296-301 | `D`, `Sf`, `*_sensitive` | gauges | A1 items 3, 4, 8, 10 | yes |
| 24 | 309-384 | `decide()`: b_dry, b24, strata medians, null draws, minp, step 1, step 2, verdict | gauges in `x` (all of g, or g less one) | A1 items 12-14 | yes. Medians and baselines are recomputed per `x`, as A1 asks |
| 25 | 389-399 | `reg_null` | dry gauges, D count per zone | registered zone-only null | yes |
| 26 | 401-412 | `stab` | each D-flagged dry gauge unflagged; each zone-24 gauge removed | A1 item 15 | yes |
| 27 | 414-429 | `sens`, labels | gauges | A1 item 17 | yes |
| 28 | 431-445 | replication `fl`, `partner`, `rep_diff` | non-dry gauges | A1 item 20 | yes |
| 29 | 455-462 | `stat_cells`, `zone_row` | gauges per zone, kept = !D | A1 item 18 | yes |
| 30 | 472-479 | `top_purpose` | u pairs, surface, not replaced, consumptive, w × v | purposes of L | yes (same vol as L's split) |
| 31 | 487-488, 527-540 | `cnt()` lines | kept rows (`one`) | "counts below exclude them" | yes, except "replaced", which carries row 2's 7 NA-key rows |
| 32 | 525-526 | "rows in the snapshot", "repeat rows" | all rows; `dup_pod` | as labelled | yes |
| 33 | 536 | "D/P groups repeating one quantity" | `dp_rep` groups | groups | yes |
| 34 | 489, 541-543 | `sy_gap` | Current kept rows | A1 item 7 | yes |
| 35 | 490-492, 549-552 | `kept_pid`, `pl_up`, `pl_own`: placed, pairs, own reach, below, not indexed | kept located rows and dams; `pl$up` before the below-removal | "on codes", "(located kept licence rows and dams)" | yes |
| 36 | 493-500 | `cap`, `cap_lines` | zone-24 D-flagged gauges with cv > obs | A1 item 16 | yes |
| 37 | 501 | `s_only` | dry gauges, Sf and not D | A1 item 10 | yes |
| 38 | 502-506 | `dam_lines` | `up` (below removed) ∩ dams, per dry gauge | rule: dams by function and class | yes (same population as `n_dams`) |
| 39 | 508-509 | `rho_l`, `rho_reg` | dry gauges | A1 item 19 | yes |
| 40 | 583-584 | "dry gauges with groundwater consumptive licences upstream" | dry gauges with **w-weighted** `L_gw > 0` | label: licences upstream; registered "groundwater licences upstream" | **no** (finding 1) |
| 41 | 585-586 | W, P, X counts | dry gauges | A1 items 3, 4, 8 | yes |
| 42 | 517-519 | as-amended verdict line | tied to `raw_key == "9adbffe764"` | Ordering clause | yes |

## Findings

Neither finding changes a flag, a test or the verdict. Both are numbers printed in the tracked report.

- **[report number] scripts/wb_gauge_diversion.R:583-584: "dry gauges with groundwater consumptive licences upstream: 10 (hydraulically connected, Likely: 8)" counts gauges whose in-force-weighted `L_gw` is above 0, not gauges with licences upstream.**
  - 08KF001 has 4 groundwater consumptive candidate rows upstream (L109976, L16869, L89562, L89657; 2 of them Likely). All have priority years 2000-2012, after the gauge's complete years, so w = 0 and L_gw = 0.
  - Counted as licences upstream, the line reads 11 (Likely 9).
  - The report mixes the two populations under one word. `n_cons`, `n_stor` and `n_dams` ("upstream" columns) count rows whatever their weight, while this line counts in-force depth. The registered item is "groundwater licences upstream".
  - Fix: count gauges with any `!surface & !replaced & class == "consumptive"` pair in `u`, or relabel the line "with groundwater consumptive licences in force over the gauge's years".

- **[report number] scripts/wb_gauge_diversion.R:127-128: `key3` is built with `paste()`, which writes NA as the string "NA". So a non-current row whose POD, purpose and priority date are all NA is "replaced" by any Current row that also has all three NA, from an unrelated licence.**
  - 6 Current rows have all three NA. 7 kept non-current rows are marked replaced through them, for example F007114 (Cancelled), F038557 (Abandoned) and F048082 (Cancelled).
  - "replaced (a Current row carries POD, purpose, priority) 1182" therefore includes 7 rows that no Current row carries.
  - None of them is located, so no L, S or flag moves. This is the `match()` treats-NA-as-a-value trap through `paste()`.
  - Fix: `lic$replaced <- !lic$current & !is.na(lic$POD_NUMBER) & key3 %in% key3[lic$current & !is.na(lic$POD_NUMBER)]`. Also consider NA purpose and NA priority, which have the same exposure but are at least the same POD.

## Notes (checked, not findings)

- **Report reproduces.** A fresh run of the staged script in a copy gives a byte-identical report.
- **No-POD rows (row 4).** The 9,544 rows with no `POD_NUMBER` are all unlocated surface rows: 5,223 Abandoned, 4,307 Cancelled, 14 Current. They are kept one per id by design, and 327 of them match an earlier no-POD row on licence, purpose, flag, units, quantity, status and priority. Without a POD number these cannot be told apart from distinct unnumbered PODs, and none reaches the accounting. If they are licensee repeats, "no location, surface, not current 10222" is high by up to 326 and the Current line by up to 1. I am not calling this a defect, because the evidence does not discriminate.
- **Volume counts (row 11).** "no volume: empty quantity 9403" and "no volume: unit … 1460" are exact. No such kept row gets a volume through `m3yr_pod` or a shared split.
- **Unlocated rows.** No unlocated kept row has a located kept row at the same licence-purpose and POD, so "no location … (not placed)" is not inflated by flag or units splits.
- **Invariants that hold by data, not by code (rows 16 and 21).**
  - `g_npod` and `n_up` agree only while candidacy is uniform within a shared group. If a `REDIVERSION_IND = Y` POD sat in an M group, every gauge would read the group as straddling, which reaches only the X marks.
  - `no_m3sec` is exact only while no shared group's maximum comes from a row of different units than the row carrying the share.
  - Both hold in snapshot 9adbffe764. A new snapshot (the m4 case R2 raised) could break either without an error.
