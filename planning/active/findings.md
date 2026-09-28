# Findings — MOD16 AET as a challenger to the shipped annual AET (#18)

## Issue context

**If we do it:** the one ET product #15 deferred gets scored. If it beats what ships (`max(CGIAR, Fu–Budyko)`), it replaces it, especially on the dry interior plateaus, where zone 24 still runs +102 %. **If we never do:** #15's comparison stays one product short, and "MODIS would have done better" remains an untested claim.

## Problem

#15 deferred MOD16A3GF v061 (LP DAAC, annual ET, 500 m, from 2000) because it needed an Earthdata login. That's now set up through `earthdatalogin`: a test tile (h10v03, 2010) downloads and reads, with ET in mm/yr and fill codes for water, barren, snow and urban. MOD16 is Penman–Monteith on MODIS land cover and LAI, not capped by a coarse precipitation field, so it's the independent AET #15 lacked.

## Proposed Solution

- **Fetcher:** `wet_mod16_aet(grid)`, following `wet_terraclimate_aet()`. It fetches the BC tiles for every year it averages, masks the fill codes, averages the annual ET, reprojects from sinusoidal with the two-step method from #15 (average in the target CRS, not across a rotation), and carries a method version in its cache key.
- **Gap cells:** these take the shipped AET, and their count is reported.
- **Scoring:** challenger variants `mod16` and `max(CGIAR, mod16)`, scored with `scripts/wb_validate.R` and compared under #15's rule with the shipped variant as the incumbent. That means the same 2-point headwater margin, the nested-basin guards and the fully nested selection. The rule is fixed here before any scoring.
- **Period (disclosed):** 2001–2020, 20 complete years with the most overlap with the gauge record. The rest of the model is on 1981–2010 normals.

Relates to #15


## Exploration (2026-09-27)

- Template fetcher: `R/wet_terraclimate_aet.R`; two-step reprojection: `R/wet_landcover_nrcan.R`.
- `scripts/wb_aet_compare.R` hard-codes cgiar as incumbent; it is in `score_code_md5`, so any edit forces a rescore of every variant (the new province key forces it anyway).
- #15 rerun chain: ~4 min per variant, ~6 min compare (`data/logs/20260928_run15c.log`).
- Earthdata login: earthdatalogin netrc (see memory); `earthdatalogin` not in DESCRIPTION.

## Errors Encountered

| Error | Resolution |
|-------|------------|
