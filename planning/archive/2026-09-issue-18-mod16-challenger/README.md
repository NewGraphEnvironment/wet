## Outcome

MOD16A3GF v061 annual ET was scored as a challenger to the shipped annual AET, `cfu` = max(CGIAR, Fu–Budyko), under a rule fixed before scoring. **`cfu` stays.** MOD16 improves on CGIAR alone but not on the Budyko floor, and even basins that are almost entirely MOD16 score worse (37.5 % against 31.9 % headwater MAE). The work added `wet_mod16_aet()`, which lists granules through CMR, downloads with `curl` and an Earthdata netrc, takes a per-pixel 2001–2020 mean, and puts it on the grid in two steps from sinusoidal. It also made `scripts/wb_aet_compare.R` a two-stage comparison, in which #15's stage must reproduce its published result before #18's runs. The durable verdict is `research/water_balance_method.md` §0, "MOD16 as a challenger (#18)".

Learned along the way (details in `findings.md`):
- MOD16A3GF's gap codes are uint16 65529–65535. The plan had the int16 MOD16A2 codes.
- `earthdatalogin` overwrites a netrc with its shared default login when it finds none.
- `terra::densify()` on lon/lat follows great circles, and bowed a raster edge into a tile the grid never reaches.
- The province run's upstream rows come back in a different order each run, because the query has no ORDER BY.
- The (d) nested check against an as-shipped score is about 2 points stricter than nested against nested, because each fold picks its own gate. That disproves a plan-review claim; the dry run measured it.
- Three code-check rounds on the scripts found labels written from other documents rather than from the expression they describe: an inverted "full" count, a stale restatement, and a period disclosure copied from the plan and wrong for CGIAR. The loop ended by enumerating all 29 report lines against their sources.

## Measurement

Blocked-CV MAE on annual runoff at 290 HYDAT stations (218 headwater):

| AET | Headwater | All | Nested | Nested ±20 % |
|---|---|---|---|---|
| cfu (shipped) | 31.2 % | 27.7 % | 17.4 % | 70.8 % |
| cmod16 | 34.6 % | 30.4 % | 17.7 % | 69.4 % |
| mod16 | 36.3 % | 31.4 % | 16.5 % | 75.0 % |

- **Zone 24:** +102 % with cfu, +166 % with mod16.
- **Greata Creek upstream AET:** cfu 499 mm, mod16 419 mm; the gauge implies about 693 mm.
- **Nested estimates:** cfu alone scores 33.2 % headwater, and every nested fold chose cfu.
- **MOD16 cover:** 91.5 % of the analysis grid by area (180 granules, 9 tiles, 3.9 GB, 14 min to build).
- **Reproduction:** the province run reproduced #15 (53 layers identical; upstream means within 5.4e-14 after matching by id), and stage 1 reproduced #15's published comparison exactly.
- **What changed because of it:** the "independent AET might fix the interior" hypothesis is now a measured no. The zone 24 residual points more toward the P or gauge side ([I], research §0).

## Evidence

- `data/checks/wb_aet_compare.txt`, `data/checks/wb_validation_aet-*.txt`, `data/checks/wb_province_run.txt`, `data/checks/wb_inputs.txt` (tracked).
- Run logs, gitignored, on the machine that ran them: `data/logs/20260928_*18*`.
- Plan review and code-check rounds: `review-*.md` in this directory.

Closed by: PR (see `gh pr list --head 18-mod16-aet-as-a-challenger-to-the-shipped`)
