## Outcome

`vignettes/segment-discharge.Rmd` was reordered for readers: what mean annual discharge is (a worked unit example and linked terms), which estimate to use, how close the open water balance is at 290 gauges, the Salmon River as a fwapg | balance pair and the Bulkley with a worked segment-to-gauge example, limits, and how it is built. One ±20 % error scale throughout, and a build guard that stops the article if any station named in the text or a table falls outside a map frame. To back the recommendation, fwapg (PCIC) was scored at every calibration gauge it covers. The pre-set rule fired by 0.03 points, and the user kept "the balance everywhere" on the record; the article states the rule and the gap. Learned: fwapg's coverage is narrower than its discharge table suggests (null-only and grid-edge groups; almost no order-8+ values), and a coverage rule of "any value" would have scored grid-edge artefacts. Review found the most in layer-selection rules whose guards only asked whether anything came back, and in prose numbers rounded so the claim they support disappeared.

## Measurement

- At 168 calibration gauges in PCIC's coverage with a fwapg value: balance (held out) 30.5 % MAE, fwapg 25.5 %; within ±20 %, 48 % against 60 %. Peace 19.6 vs 14.2, Fraser 29.4 vs 28.8, Columbia 34.7 vs 25.4. The gap of 5.03 fired the 5-point rule; it was 4.70 under the first coverage definition, which counted the grid-edge gauge 10CB001. The rule outcome and the decision are in `findings.md`; the durable verdict is in [`research/water_balance_method.md`](../../../research/water_balance_method.md) §0.
- fwapg coverage: 112 groups with >= 50 % of rows valued; 27 null-only groups and 11 Liard grid-edge groups (0.02–23 %) excluded. Of 13,883 segments of order 8 and up in coverage, 38 hold a value; 18 calibration gauges in coverage cannot be scored (median 11,859 km²; the balance scores 13.3 % there).
- Bundles: 456 KB of the 500 KB budget after the 9,000-row parity table became a one-row summary (all 9,000 match fwapg to five decimals).
- Wrong turns kept: the first coverage assertion (`in_pcic` iff a value) failed on the mainstems; the context-river edge-type list dropped every large river; zones would not union until Z was dropped; a reorder left a loose `close` vector and published −2 % for −14 %.

## Evidence

Review files in this directory: `review-plan.md`, `review-round*.md` (data scripts), `review-article-*.md` (article). Data built at commits 2d4a1de and 42adbb1 (`provenance$wet_commit` in `inst/vignette-data/segment_values.rds`).

Closed by: PR for branch `39-segment-discharge-article-reorder-for-re` (Fixes #39)
