# Findings — Merge the segment-discharge and monthly-flow articles into one article on the published product (#149)

## Issue context

**If we do it:** one article answers "what does wet publish for my stream, which value should I use, how do I read it, and how good is it", for the yearly, monthly and daily values together. **If we never do:** a reader has to read "Stream Discharge per Segment" and "Monthly Flow per Segment" side by side, and both repeat the two sources, their periods, how to read the parts and the scores at the calibration gauges.

`vignettes/segment-discharge.Rmd` (about 900 words of body prose, one figure) covers the yearly figure and `pick`. `vignettes/monthly-flow.Rmd` (about 1,600 words, three figures) covers months 1–12 and the days. Measured 2026-10-29 by counting the prose up to "Software and citation".

Proposed order, as the reader's questions:

1. What it is: the two sources, their periods, the yearly, monthly and daily values.
2. Which value to use: `pick`, its rule and the province map.
3. How to read it: one recipe for a segment (`wet_segment_monthly()`, `wet_segment_daily()`), then `wet_db_load()`.
4. What a year looks like: the Bulkley hydrographs at three gauges.
5. How good it is: yearly and monthly scores for both sources at the calibration gauges, one table.
6. Limits, then "Software and citation".

- Cut what the two say twice. Estimate 1,800–2,000 words from 2,500; measure before and after (`writing.md`, "Measure the simplification").
- "Flow in the Chinook windows" (monthly-flow) shrinks to the point it makes for the product: a window read from monthly means costs this much, and the published days remove it. Windows themselves are defined in "How Stream Flow Has Changed Where Gauges Are Few".
- Keep both data scripts and bundles (`data-raw/segment_vignette_data.R`, `data-raw/monthly_vignette_data.R`) and every guard; the article reads both. Render before and after, strip to text and diff: only the prose meant to change may differ.
- One address goes away: redirect it with pkgdown's `redirects:` so existing links keep working, and update README's Learn more and CLAUDE.md.
- Title says what the product is, per #145's rule (flow, not Chinook).

Relates to #28, #59, #65, #71, #107, #145 (article titles and which articles stay listed).


## Exploration (2026-10-29)

- Both bundles come from one published build: `segment_values.rds` and `monthly_values.rds` both read build `b4bbc50`, built 2026-10-24 (`provenance$built` 20750 in both).
- The `skill` frame (segment bundle, 315 gauges) and the `gauges` frame (monthly bundle, month 0) hold the same 315 gauges with equal `obs`, and `wb_mm` equals `obs * (1 + err_pct / 100)`.
- 290 gauges have routed flow and 11 of them are far-low (segment flow under 0.2 of the observed): 08DB013, 08DB014, 08EE028, 08JA014, 08JA015, 08JA016, 08JA028, 08KG003, 08KH006, 08MH141, 08NE039.
- Yearly scores, 290 → 279 gauges: routed MAE 24.2 → 21.5 %, bias +1.4 → +5.1 %, within ±20 % 63.4 → 65.9 %; balance MAE 27.6 → 27.2 %; routed is closer at 169 → 168.
- Links from outside the repo: only the wet README (both articles) and a compost communications draft (segment-discharge). That address stays.
- The only redirect needed is pkgdown 2.2.0's `redirects:` field (meta refresh).
- #80 (drop the >0.5 check) and #74 (recipe INSTALL httpfs) touch the same chunks.

## Baseline renders (2026-10-29, main at 14fc428, installed 0.4.29)

- Body prose by the articles' own rule (Rmd source up to "Software and citation", code and inline `r` removed): segment-discharge 829 words, monthly-flow 1,543, **2,372 together**. The issue's 2,500 was this count rounded up.
- Rendered text up to the citation section, tables and captions included: 1,004 + 2,199 = 3,203 words.
- Distinct numbers printed: 108 in segment-discharge and 177 in monthly-flow. Kept in the scratchpad as `before/*.txt.nums` for the Phase 4 number check, with the strip script `html_text.R`.
- The two bundles' provenance agrees on `built`, `wet_commit`, `province_run`, `aet`, `hydat_release`, `routed*` and the published manifest, build, commit, parts, reader and report. Only `published_check` differs (each bundle checked its own values).

## Errors Encountered

| Error | Resolution |
|-------|------------|
