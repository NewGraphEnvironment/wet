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


## Phase 2: routed scores, 1951-2012 run against 1981-2010 run (2026-10-18)

`scripts/pcic_routed_compare.R` on m1 (`WET_FWAPG_COMMIT=7c30f58`, log `data/logs/103/pcic_routed_compare.log`). Table fingerprint 178918222.786650, equal to the 1981-2010 row in `pcic.runs` (issue table). Same 290 of 315 gauges with routed flow, same 25 without, same 11 far-low gauges, same 7 where the pick is the balance.

Annual, at the 290 gauges (mean abs / median abs / within 20 % / bias / routed closer %):

| set | 1951-2012 | 1981-2010 |
|---|---|---|
| all | 24.1 / 13.0 / 62 / +0.2 / 59 | 24.2 / 13.1 / 63 / +1.4 / 58 |
| headwater (218) | 28.3 / 18.2 / 53 / +1.6 / 56 | 28.3 / 16.7 / 56 / +2.7 / 58 |
| nested (72) | 11.3 / 8.6 / 89 / -3.9 / 65 | 11.7 / 9.0 / 88 / -2.6 / 60 |
| Peace (28) | 20.5 / 11.2 / 68 / +9.4 | 19.0 / 11.9 / 79 / +5.5 |
| Fraser (90) | 30.8 / 18.2 / 51 / -5.7 | 30.7 / 17.6 / 54 / -5.0 |
| Columbia (78) | 23.7 / 13.1 / 68 / +7.8 | 24.6 / 13.0 / 68 / +11.6 |
| Coast (94) | 18.9 / 10.8 / 66 / -3.0 | 19.2 / 11.1 / 64 / -2.2 |
| pick, every gauge (315) | 23.2 / 14.0 / 61 / +2.9 | 23.3 / 14.0 / 62 / +3.9 |

The period barely moves annual skill: routed's bias rises by about 1 point (the 1981-2010 table total is 0.5 % higher), the Columbia's by 3.8 and the Peace's falls by 3.9.

By month (scratch probe, `data/logs/103/period_probe.R` and `.txt`): routed over observed 1981-2010 months at the 279 gauges with routed flow, less the 11 far-low, median error %:

| month | 1951-2012 | 1981-2010 | move |
|---|---|---|---|
| 1 | -11.9 | -5.8 | +6.1 |
| 2 | -5.8 | -0.2 | +5.6 |
| 3 | -19.5 | -11.1 | +8.4 |
| 4 | -19.5 | -12.2 | +7.3 |
| 5 | -15.5 | -17.2 | -1.7 |
| 6 | +2.2 | +1.4 | -0.8 |
| 7 | +19.4 | +19.9 | +0.5 |
| 8 | +17.7 | +13.0 | -4.7 |
| 9 | +6.7 | +2.9 | -3.8 |
| 10-12 | -2.9, -7.6, -2.3 | -2.7, -6.1, -2.0 | small |

Seasons (median over gauge-months): March-April -19.5 -> -11.5; July-August +18.7 -> +15.8. Per gauge, 1981-2010: low in March-April at 61 % (was 69 %), high in July-August at 68 % (69 %), both 41 % (48 %).

**The #67 test.** Routed's spring-low, summer-high shape survives on 1981-2010, so it is not the period. The period accounted for about 40 % of the March-April shortfall and about 15 % of the July-August excess, against the old article's long-record estimate, which put both under 50 %. With both periods equal, what remains (-11.5 % spring, +15.8 % summer) is attributable to PCIC's model or its placement, not to the period. The article's thresholds (spring < -10 %, summer > +10 %) still hold, March-April narrowly.

## Errors Encountered

| Error | Resolution |
|-------|------------|
