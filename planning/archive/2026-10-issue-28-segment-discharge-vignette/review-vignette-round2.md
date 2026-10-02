# Review round 2: segment-discharge vignette (#28)

Reviewer: subagent, 2026-10-02. Rendered a copy of the vignette to a temp directory, which built clean and passed every stopifnot plus the 800-word cap. Ran `tests/testthat/test-vignette_data.R` with NOT_CRAN=true: 66 pass, 0 fail. Read the five figures. Checked against `segment_values.rds`, `segment_map.rds`, `data/checks/wb_validation.txt`, `scripts/wb_cv_lib.R`, `R/wet_cv_folds.R` and fwapg.

## Findings

- **[severity: bug]** vignettes/segment-discharge.Rmd:304-305, guard at :269-270; research/water_balance_method.md (new bullet, last sub-bullet). The sentence is "So most of the gap is the balance's, and PCIC adds to it in the large basins." The data do not support it for the large basins, and the guard does not pin it.
  - The gap at a gauge is wb − fwapg = (wb − obs) + (obs − fwapg). Per gauge, the balance's share of that gap is:

    | gauge | area | balance's share, as % of obs | balance's share, multiplicative (log) |
    |---|---|---|---|
    | 07ED001 Nation | 4,356 km² | 30 % | 28 % |
    | 08JE001 Stuart | 14,235 km² | 39 % | 36 % |
    | 08KC001 outlet | 4,227 km² | 60 % | 52 % |
    | 08JE004 | 439 km² | 98 % | 98 % |
    | 08KC003 | 297 km² | 95 % | 94 % |

  - So at 2 of the 3 large basins, most of the gap is PCIC's (Nation −14 % against +6 %; Stuart −17 % against +11 %). At the outlet the two split it almost evenly in the ratio terms the prose itself uses ("1.47 times"): 1.38 × 1.34.
  - "PCIC adds to it in the large basins" makes PCIC sound like the minor contributor there. The data say PCIC is the major contributor, or an equal one, in every large basin.
  - The direction logic is coherent: a low PCIC does widen the WB/PCIC gap when the balance is high, so "adds to it" is not wrong in sign. It is wrong in size.
  - The guard `mean(abs(ga$wb_err)) > mean(abs(ga$fw_err))` (24.5 against 11.7) is a proxy. The two small basins carry it (+34 % and +35 % against −1 % and −2 %), and neither of them lies in SALR. It would still pass if PCIC held the larger share at every large basin.
  - `outlet$wb_err > -outlet$fw_err` pins the outlet only in %-of-observed terms (37.7 against 25.4). In the multiplicative terms the sentence's "1.47 times" invites, it is 52/48.
  - The outlet basin is also 4,227 km² against SALR's 1,794 km², so 58 % of it lies outside the group. No gauge measures the SALR per-segment median directly.
  - What the data support is: the gap is the balance's at the small basins, and the two share it at the large ones, where PCIC's miss is the larger at Nation and Stuart. Guard it per size class, for example `all(ga$wb_err[close] > 5 * -ga$fw_err[close])` and a statement about `ga[!close, ]` that matches whatever the prose then says. The research bullet needs the same correction.

- **[severity: fragile]** vignettes/segment-discharge.Rmd:426-427. The bullet reads "`n_no_value` segments of order `prov$min_order` to `max_order_no_value`". The lower bound is the selection threshold, not the minimum order among the segments with no value. It is true today, because two BULK order-3 segments lack a watershed. If a rebuild dropped them, the text would claim order-3 segments that are not there, and nothing would fail. Use `min(seg$stream_order[is.na(seg$mad)])`, or assert that it equals `prov$min_order`.

## Checked and fine

- (a) Parity: `n_par == fwapg_discharge_rows[["SALR"]]` and `same5 == 1` pin "every one of the 9,000 … segments that fwapg gives a value". fwapg stores `mad_m3s` as double at 5 decimals (checked in the DB).
- (b) The captions read "2,180 of the 2,181" SALR segments and "7,748 of the 7,755" BULK segments, both correct.
- (c) NEWS has "four gauges within 30 km … and its outlet gauge … all five". The data show four gauges at 14–27 km plus 08KC001 at 46 km, and all five have wb_err > 0.
- "within 5% at the 2 smallest basins": the area guard `max(area[close]) < min(area[!close])` pins "smallest" (297 and 439 km², against 4,227 km² and up). "low at the 3 larger" is pinned by `fw_err[!close] < -5`.
- (e) BULK has 0 fwapg rows, which is pinned. (f) Zone 24 at 102 % is the only zone above 2 × 27.7 %, and zone 25 at 50 % is below it. Since the one zone above is the maximum, `worst` is that zone.
- "nested ones, whose basins hold other gauges" matches `wet_cv_folds()`: nested means another station is upstream. "Each WSC sub-sub-drainage is held out" matches the default `block`.
- The MAE figures (27.7, 31.2, 17.4, 51 %) match `data/checks/wb_validation.txt`. The limits bullet on the pooled-zone gate matches that report: pre-set "other" fails at 42.3 % against 31.6 %, and "none" passes.
- The research bullet's numbers (+6 % to +38 %; −1 %, −2 %; −14 % to −25 %; 297, 439, 4,227–14,235 km²) all round correctly from `gauges_salr`.
- Per-vignette size test: `expect_setequal` over the installed file list means a new file fails the test rather than escaping both budgets. A missing install dir gives `character(0)` and fails too. The current budgets are 427 KB (segment) and 129 KB (station).
- The figures match their captions. The SALR legend omits the 50+ class because SALR has no segment in it; the colours are shared. The BULK legend omits "0–20 % over" because no gauge falls there.
- README and CLAUDE.md sentences check out against the data script.
