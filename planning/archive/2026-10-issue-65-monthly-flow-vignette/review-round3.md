# Code-check round 3 (#65): branch review

Method: ran the vignette's code from a `git archive HEAD` copy (`pkgload::load_all`), evaluated all 72 inline values, and recomputed the claims under other definitions of their sets. No repo file was touched other than this one.

## Mechanism

Each sentence's set is chosen in two places that nothing links. The prose names a set ("the gauges", "every segment", "the 11", "the right months"), and the code builds a set from whatever filter the computation needed: logs need positive values, joins need rows, and the far-low cut is the report's. A guard then checks the claim's direction on the code's set. That catches arithmetic slips. It cannot catch three things: (a) a filter that is correlated with the statistic it filters; (b) a quantifier or characterisation in the prose that no computation produces; (c) a qualitative word that the guard's threshold does not imply. Rounds 1 and 2 were mostly (a) in its plain form, a number over the wrong set. The enumeration walked every inline value to its computation, but it asks only "is the set right?", never "does the set's own filter move the answer?". It also skips sentences that hold no inline value. The findings below are the instances still left.

## Findings

- **[bug] vignettes/monthly-flow.Rmd:390, 515-517 (and the figure, the table and `r_closer`)**: the balance's winter numbers come from a filter that removes only its own worst errors. `both` drops the 89 gauge-months where the held-out balance is 0. Each of those is a −100% error. 62 of the 89 fall in Dec–Mar (Jan 34, Feb 16, Mar 14, Dec 12; Jul 6, Aug 4, Sep 1, Apr 2). The median does not need the exclusion: the ratio is 0, and the log is −Inf, which still ranks. Measured at the same 279 gauges with obs ≥ 1 mm and the zeros kept:
  - January's balance median is +11.5%, not +22.6%.
  - The winter range is +4.9% to +13.5%, not "+7% to +23%".
  - The highest month is **April**, not "January".
  - January's within-±20% share is 20.6%, not 23.5%.

  The sentence "reads high from December to May … (highest in January)" therefore depends on the definition. It also hides a balance fault the article never mentions: a held-out share of zero, that is, no flow predicted in January, at 34 gauges. The direction still holds (`min(winter) > max|summer|` passes either way, and `r_closer` is the same 10 months), but the quoted range and the peak month do not. Fix: keep the balance-zero months in the medians (drop only obs < 1 mm), or report both and name the 62 winter zeros.

- **[bug] vignettes/monthly-flow.Rmd:379-381, 438-440**: the characterisation of the 11 far-low gauges contradicts the tracked report it cites. The prose says they are "side channels, reservoirs and misplaced outlets, as in the annual routed comparison", and the code comment says "not model error". `data/checks/pcic_routed_compare_20260717.txt` ("The 11 gauges …") attributes them as 6 "placement or snap", 4 "unresolved" (08KH006, 08DB013, 08EE028, 08DB014) and 1 "PCIC runoff" (08NE039, Big Sheep Creek). So one excluded gauge is attributed to PCIC's model error, and four are unattributed. Excluding them can be defended as the report's cut, but the reason given for it is wrong for 5 of the 11. Say "whose segment carries under 20% … (the annual comparison attributes 6 to placement, 1 to PCIC's runoff and leaves 4 unresolved)", or similar.

- **[bug] vignettes/monthly-flow.Rmd:266-267**: "The water balance has hardly a freshet" is contradicted by the numbers beside it. At Buck Creek the balance runs from 1.04 m³/s in January to 9.58 in June, a 9.2× seasonal rise. The guard (`max(bal) < max(obs) / 2`, line 257) supports "its peak is under half the gauge's", which is what the numbers show. It does not support "hardly a freshet". This is the same shape as round 2's "both come close at Quick". Reword to what is asserted, for example "a freshet under half the gauge's, a month late".

- **[fragile] vignettes/monthly-flow.Rmd:526**: "Routed PCIC has its freshet in the right months" is a claim over the gauges that no computation produces, and the obvious measure does not separate the two sources. At the 279 gauges, routed's peak month equals the observed peak month at 66% and the balance's at 64%. Within one month, routed matches at 92%. The pooled medians (routed May −15%, June +2%) are what the sentence rests on. Either compute and assert a peak-month or freshet-month measure that supports the contrast, or narrow the sentence to "its freshet peaks in May–June, as the gauges' do".

- **[fragile] vignettes/monthly-flow.Rmd:586-587**: "its shares know nothing of the lake, and routing does" implies routed scores well at lake outlets. It holds (routed 0.93 against balance 0.52 at the 17 lake outlets), but no guard asserts it. The `stopifnot` at line 576-578 checks only the balance's weakness. Add `nse_g(gr, "lake", "lake outlet") > nse_g(gw, "lake", "lake outlet")`.

- **[fragile] vignettes/monthly-flow.Rmd:71-73**: "gives every FWA segment thirteen values per source" is false over its set. The publish report's reader line gives 43,901,481 routed rows (3,377,037 segments) and 58,889,207 balance rows (4,529,939 segments), so about 1.15 M segments carry no routed values. The segment-discharge article and the scores section of this article both say routed covers only part of BC. Use "every segment it covers".

- **[fragile] vignettes/monthly-flow.Rmd:646-648 and data-raw/monthly_vignette_data.R:190-214**: "It checked every bundled published value against what it was built from" is not what the script does. Routed **month 0** on the 290 calibration gauges' segments (`pub_gauge` month 0, bundled as `gauges$routed_mm` at month 0) is never compared: `pr_m` takes `pub_gauge$month > 0` only, and `src_r0` is restricted to the Bulkley segments. Those values define `far`, the 11-gauge exclusion. I checked the bundle: each equals the mean of its checked months to 4e-16, so no value is wrong today, but the claim and the guard differ. Extend `src_r0` to `ids_used` and compare `pub_gauge` month 0 too, or narrow the sentence.

- **[fragile] vignettes/monthly-flow.Rmd:657 and data-raw/monthly_vignette_data.R:167-168**: "On the machine that built it, the fit's output held month 0 only" is not recorded anywhere. The script filters `wb$month == 0` whatever `output/` holds and puts nothing in provenance. A rebuild on the machine with the full fit would leave the sentence false. Record `sort(unique(month))` of the unfiltered `output/400.parquet` in provenance and drive the sentence from it.

## Enumeration (review-enumeration.md): what it misses

- Its "Scores: balance" row lists the guard on the winter range but not that the set excludes the balance's −100% months. Its "Set it is over" column says `both`'s gauge-months without asking whether that filter is neutral to the statistic. That is finding 1.
- It says the prose outside inline values is fixed, but the sentences with no inline value (findings 2–6) were not walked.
- The data script, lib (`vd_*` refactor of segment_vignette_data.R: no leftover references to the removed `pr_lines`, `same`, `pub_commit` or `git()`), the tests and the cartography CSV raised nothing beyond findings 7–8.
