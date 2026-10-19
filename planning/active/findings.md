# Findings — Routed PCIC over 1981-2010: switch the pcic run and republish (#103)

## Issue context

**If we do it:** both sources on every segment describe 1981–2010, the period the balance and the gauge scores use, and the period caveat leaves both articles. **If we never do:** routed flow stays 1951–2012 against a 1981–2010 balance and 1981–2010 observations, and part of routed PCIC's error at the gauges stays its period (the monthly-flow article bounds it).

Depends on #101, which moves the read to fwapg's `pcic` schema with the run pinned at 1951–2012 and no value changed. This issue flips the pin.

## The run

fwapg publishes it (NewGraphEnvironment/fwapg#25, `pcic.runs`):

| run | rows | segments | `monthly_q_sum` |
|---|---|---|---|
| PNWNAmet historical 1951–2012 (today) | 40,524,444 | 3,377,037 | 178035348.248310 |
| PNWNAmet historical 1981–2010 | 40,524,444 | 3,377,037 | 178918222.786650 |

Same segments, same crosswalk (`crosswalk_md5` b1a71083…), so coverage does not move. Every routed value does.

## What changes

- **The pin** (#101's one definition of the run) to `period = '1981-2010'`.
- **Picks.** `pick` moves wherever routed annual flow crosses 0.2 of the balance's. The cut and #57's rule stay.
- **Period text and assertions:**
  - `scripts/segment_output.R` (`period_routed`), `scripts/discharge_publish.R` (the `pcic_routed` description), `scripts/pcic_routed_compare.R` (the two report lines that say 1951–2012);
  - `vignettes/segment-discharge.Rmd`: the routed source paragraph and the score table's caption;
  - `vignettes/monthly-flow.Rmd`: the period section, which bounds the share of routed's error that is its period, and its `stopifnot()` on "1951–2012". With both sources on 1981–2010 there is nothing left to bound, so the section and `data-raw/monthly_vignette_data.R`'s observed 1951–2012 block go;
  - `tests/testthat/test-vignette_data.R` (the routed period expected);
  - `research/discharge_publish.md` ("`period` is a column"), `research/water_balance_method.md` (the line on periods), CLAUDE.md (the routed data source).
- **Prose resting on routed scores.** The segment article's routed-closer counts and province pick counts; the monthly article's claims that routed is low in March–April and high in July–August, which its `stopifnot()`s will catch if they move; the README map (`data-raw/readme_figure.R`, from the segment map).

## Run order

1. `scripts/pcic_routed_compare.R`: new scores. Record how they moved from the 1951–2012 report, overall, by basin and by month, and whether routed's spring-low, summer-high shape (#67) survives the period switch. The monthly article attributes it to PCIC's model, not the period; this is the test of that.
2. `scripts/segment_output.R`, then `scripts/discharge_publish.R` BUILD.
3. Upload (`WET_PUBLISH=1`), on the user's go.
4. The vignette data scripts, the segment map, the README figure; rewrite the article text the new numbers change.

## Publish together with #102

#102 changes the balance's monthly shares (not annual flow, so no pick). If its rule ships a candidate, publish both in one build: one rerun of the chain, one upload, one rewrite of the monthly article.

Relates to #57, #58, #65, #67, #101, #102, NewGraphEnvironment/fwapg#25.


## Errors Encountered

| Error | Resolution |
|-------|------------|
