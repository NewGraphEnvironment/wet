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
