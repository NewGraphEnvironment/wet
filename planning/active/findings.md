# Findings — Backlog move 4: Monthly error at the gauges (#166)

## Issue context

**If we do it:** the published monthly flows are scored at the gauges by region, season and basin size in one tracked report, routed PCIC's seasonal shape is attributed with the two checks #67 names, and the comparison starts where DFO's Fraser threat layers are weakest (August and September minimum flows). **If we never do:** readers of the default source get March–April about a tenth low and July–August about a sixth high with only an article saying so, and we rebuild a monthly product DFO already built without knowing where ours is better.

Order: `planning/backlog.md`, move 4. Run `/planning-init <this issue>`: one phase per batch, one PR.

## Batch 6: monthly error at the gauges

**Why here:** all three read the same held-out balance (`cv_share`), routed PCIC at the same gauge segments and the same observed months, so one report script serves them, and #162 names the months #6's report should lead with.

**Touches:** a new report script under `scripts/`, `data/checks/`, `research/`.

**Decided at the gate:** a tracked report or a section of the segment-discharge article; the region unit (watershed group, hydrologic zone or ecoprovince). Sending the draft to PCIC needs the owner's approval of its exact text. Open work in fwapg places more PCIC outlets, which changes the gauge set this report scores.

| issue | title |
|---|---|
| #6 | Station check: modelled monthly flow vs HYDAT, bias by region and season |
| #67 | Routed PCIC monthly shape at the gauges: low in March-April, high in July-August |
| #162 | Benchmark monthly flows against DFO's Fraser threat-layer method (Iacarella et al. 2025) |


## Batched issues

#6 (station check by region and season), #67 (routed PCIC monthly shape), #162 (DFO Fraser benchmark, Iacarella et al. 2025 App. F). Bodies on GitHub; read 2026-11-17, no comments on #67 or #162, one on #6 (basin accumulation pointer).

## DFO Table F1 (Iacarella et al. 2025, App. F, p. 118)

Read from the Zotero PDF (item N3I48AN2). Foundry Spatial scored downscaled flow against 86 Fraser hydrometric gauges (list not published; map only, Fig. F1). Columns Min / Max / Mean per month, season and year: R2, MAE (m3/s), MAPE (fraction), NSE. "Min" is the lowest monthly value over 1981-2010; August and September Min R2 0.35 and 0.34 are the weakest; Mean R2 0.95 and 0.97. Mean MAPE Aug 0.49, Sep 0.43.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| zotero MCP: missing ZOTERO_LIBRARY_ID / API key | read the PDF path from a copy of zotero.sqlite; pdftotext |

## Plan review (Plan agent, delivered 2026-11-17 ~15:39Z), probed before acting

- **B1 confirmed:** all 245 gauge segments holding a placed outlet have `share` = 1 and `segment_weights.subid` an outlet on that segment, and fwapg's README step 5 accumulates `q_acc` down the FWA tree of placed outlets. Check 1 compared the segment with itself. Redesigned: split by whether the outlet's FWA upstream set equals its PCIC subtree (there `q_acc` is PCIC's outflow).
- **A1 confirmed:** under 100 km² routed monthly NSE 0.44 but share NSE 0.80 (balance 0.64 / 0.91); Spearman of monthly NSE with |annual error| −0.77, share NSE −0.19. #67's "shape is where it loses" is mostly volume; checks 2–3 rescored on share NSE.
- **A2:** VIC-GL cells is area rescaled (cos(lat) barely varies); dropped.
- **A3:** parity tightened to identical (obs, balance, routed 1–12), month 0 within 1e-12, fit md5s = bundle provenance (fits.rds 5d228d42…, cv_aet-cfu.rds bbe66146…, both equal on m1).
- **A4:** bin parity of the files against the 1981–2010 run's `pcic.subbasin_daily` added to `routed_years_check()` (the 1981–2010 days are on m1). February weighting does not apply: the segment parity averages all days of a month across years.
- **B2:** DFO's modelled Min sums per-cell minima across the grid (p. 30), so it sits at or below the minimum of the summed flow; caveat in the report, DFO shown as context.
- **A5:** log-space R² and per-gauge median APE added beside DFO's across-gauge statistics.
- **A6:** `elev` is the area-weighted upstream mean (`wb_province.R`), not the median.
- **G2:** guard now `vd_commit()` (R, scripts, data-raw, data/checks) plus `inst/vignette-data`.
- **S1, S2:** #6's `hydro_stn_cmip5` second reference and #162's #3 item are not done here; said so in the issue bodies.
- **O1:** corrected rules registered in the script header in their own commit before the rerun.

## Enumeration after code-check round 2: every registered rule against its code (at 4293f2b)

Mechanism (rounds 1–2): a verdict label or a bound in code or report that the header's registered rules do not hold. Candidate set: every outcome and bound the header states, and every threshold in code that decides a verdict, a refusal or a "registered" claim.

| Header rule | Code | Match |
|---|---|---|
| check 1 theirs: agreeing gauges Mar–Apr ≤ −5 %, Jul–Aug ≥ +5 % | `shape_holds()` l.483, `c1_verdict` l.484 | yes |
| check 1 ours: neither at agreeing, both elsewhere | l.486 (`> -5 && < 5` at i_ag, `shape_holds(i_sh & !i_ag)`) | yes (fixed round 1) |
| check 1 otherwise unresolved | l.490 | yes |
| share NSE; gap = median(balance − routed) per gauge | `nse_share_g()` l.389, `gap()` l.400 | yes |
| checks 2–3: supported if gap difference ≥ 0.05, else unresolved | l.401, l.530, l.551, `verdict_off()` l.404 (prints "unresolved" only) | yes (fixed round 2) |
| check 2 local share 1 (above 0.999) | l.516 | yes (registered round 2) |
| check 3 peaking by May | l.541 | yes |
| bin parity 2^-23 of mean abs + 1e-9 | lib l.294–295 | yes (registered round 2) |
| per-year days to published months, 1e-3 relative, no floor | l.602, l.606 | yes (fixed round 2) |
| HYDAT years to normals 1e-9 relative | l.666 | yes (bound tightened from 0.02, registered round 2) |
| gauge table identical; month 0 1e-12; fit md5s | l.213, l.218, l.219 | yes |

Thresholds in code that decide nothing registered and are printed as definitions: `err_cut` 20 (within ±20 %), `min_zone` 5 (marking), `routed_far_low` 0.2 (shared set, from the lib), dry-gauge exclusion (`obs > 0`) — each named in the report text where used. Nothing sits above its source of truth.

## Terminal enumeration after code-check round 3 (at 2ef9254)

Round 3 named the mechanism: the fixes treated the header at HEAD as the registered record and checked it against code written in the same commit (verification that reads its own output), and each verdict or bound was restated by hand in several copies, so a fix reached only the copies a review named. The independent reference is the header as committed at 520b9ca.

- **(a) Registered text against 520b9ca:** the block from "A first run" to "rounded to 5 decimals)." equals 520b9ca's byte for byte (`diff` of the two `sed` extracts, empty). Every later change sits in the header's separate "amended after numbers were seen" list, with its commits: local share above 0.999, the verdict wording of checks 2–3, the bin parity's 1e-9 m3/s, the per-year floor's history (ba29835 → 7a8a5ac → none since 613b296), and the HYDAT-normals bound (0.02 → 1e-9).
- **(b) Every "registered" in the branch's copies:** in the report, research/monthly_error.md, research/README.md, CLAUDE.md line 25, the PR draft and the #6/#67/#162/#166 bodies, each instance refers to a rule in the 520b9ca text (the per-year 1e-3 bound, the 0.05 margin, the rules as a whole). The HYDAT bound is printed as "set after the first runs"; the bin floor is printed without the word.
- **(c) Every verdict and its copies:** the report prints check 1 theirs, check 2 unresolved (gap the other way), check 3 unresolved. research/monthly_error.md (answer bullet, headings), research/README.md, #67, #166 and the PR draft carry the same three; "not supported", "neither … explains" and "zonal levels, not a seasonal shape" appear in no copy (grep).
- **Refusal thresholds that judge inputs, not results** (`all.equal` on the stored scores, `share == 1` on outlet segments, at least 20 days a month, the years count, 366 bins a sub-basin): integrity guards inherited from the scripts they copy, outside the rule set; none decides a verdict.

The candidate set is the 520b9ca rules, the amendment list, and every copy of a verdict or "registered" claim; nothing sits above its source of truth. The loop ends here.
