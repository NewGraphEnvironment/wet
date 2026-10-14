## Outcome

The segment-discharge article now introduces the published product (`s3://fresh-bc/discharge/fwa/v1/`): where it is, what a row holds, how to read it, what `pick` selects, how each source was made, and how both score at the calibration gauges, with the Salmon River as the one worked group. Its segment values are read from the published parts and checked against their sources before they are bundled. The publish BUILD now checks every published flow against what it was built from (`wet_values_compare()`). It also checks the segment parts' runoff, coverage and `pick` against the segment table. The fwapg parity and sampling material moved out of the article to `research/fwapg_mad_method.md`, and the value checks are recorded in `research/discharge_publish.md`.

What was learned:
- The rebuild is byte-reproducible. All 67 parts written at 032242f were md5-identical to the 7c62b9e upload, so the bucket was not touched.
- The fingerprint total of fwapg's routed table can be reproduced exactly in R as an integer sum of micro-m³/s.
- Two review findings were the same mechanism: a claim about a whole population (a comparator's notion of "same", the word "every") that nobody had enumerated. Only listing the population ended it.
- The plan review caught a crash the first BUILD run would have hit at a drainage with no routed part.

## Measurement

- **Publish BUILD with the value checks** (full-run machine, wet 032242f, 22:59–23:06:55 UTC 2026-10-13, about 8 min against about 5 without): 555,857,796 values compared, 0 differing.
  - Exact everywhere except routed month 0 against the mean of its 12 months, where the largest difference is 9.09e-13 m³/s.
  - Routed total 178035348.248310 m³/s equals the table's fingerprint.
  - 67 of 67 parts are identical to the published build.
- **Vignette data**: 2,180 SALR balance values were exact, and 2,469 routed values (SALR and gauges) were within 1.1e-13. The read from the published parts took 28 s over httpfs.
  - One perturbed published value gave differing = 1 and a refusal, with the bundle unchanged.
  - A first perturbation attempt hit a row outside the checked set and proved nothing; it was redone.
- **The article** went from about 1,600 words to 1,093.

## Evidence

- `data/checks/discharge_publish_20260717.txt` (the value-checked build report)
- the BUILD's run log on the full-run machine (not committed; the report above is its record)
- `planning/archive/2026-10-issue-64-segment-vignette-published/review-round*.md`

Closed by: PR (see branch `64-segment-discharge-vignette-lead-with-the`)
