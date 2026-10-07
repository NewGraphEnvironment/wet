# Article code-check: enumeration that closed the loop (#39)

Round 2 found a defect inside a round-1 fix (precision), and one introduced by the rewrite's reorder. Mechanisms, and every place each reaches, over all 91 inline `r` values in `vignettes/segment-discharge.Rmd` and the vectors they read:

## A derived vector indexing a frame that is later reordered or filtered
- `close` against `ga` (reordered for the table): **fixed**, now `ga$close`, re-read after the reorder.
- `outlet`: a frame cut before the reorder; reads only its own row. Clean.
- `gb`: ordered before anything is derived from it. Clean.
- `seg`: filtered after `n_no_value`/`order_no_value` are taken from the unfiltered frame, which is what they describe. Clean.
- `sk`, `both`, `dropped`, `sm`: never reordered. Clean.

## A printed value rounded so the claim it supports is hidden
- Rule gap: printed to 2 decimals, guarded on the printed value. **Fixed.**
- fwapg vs balance MAE in prose and table: 1 decimal (25.5 / 30.5), with the 5.03 gap printed beside. **Fixed.**
- Worked example "closer": whole percents (−9 % vs −8 %); **guarded on the printed values.**
- SALR "within 5%" (−1 %, −2 %) and "larger ones" (−14 % to −25 %): thresholds 5 apart from printed values. Clean.
- Nested 17 % vs headwater 31 %, large 21 % vs small 43 %, zone 24 at 102 % (twice the 28 % average): no threshold near a printed digit. Clean.
- Sampling: 11 % move > 5 %, q99 24 % vs 2.8 %. Clean.
