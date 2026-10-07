# Code-check enumeration (#43, after round 2)

Rounds 1 and 2 each found a defect in the previous fix (the md5 split; then the carry and compare paths). The mechanism they share: **a default that picks something no rule chose**. These are all the defaults in the wb pipeline, and what each now does:

| Default | Where | Now |
|---|---|---|
| AET when no winner exists | `wb_validate.R` (was `ship_aet <- "cgiar"`), `wb_output.R` (was a cgiar fallback for a missing winner) | **Removed.** No winner means nothing ships; `wb_validate.R` without an AET argument stops |
| HYDAT file | `wb_hydat()` | **None.** `WET_HYDAT` is required and checked against the release |
| Release | `wb_release()`, used by stations, validate, output, cv_lib, vignette data | Shipped release (intended: these act on the shipped fit unless told otherwise). A mismatched `WET_HYDAT` stops stations and output |
| Release for the AET comparison | `wb_aet_compare.R` | **20251014 only**, the #15 reproduction. Any other release stops before anything is deleted |
| Release for the pooled test | `wb_pooled_test.R` | **Explicit `WET_HYDAT_RELEASE` required**: the test fixes a fit once, so the fit is named |
| Release for the map | `wb_map.R` | Shipped only (it writes the published PNG) |
| Release for acceptance | `wb_fit_accept.R` | Both named as arguments; each must be current under this code |
| Reference fit for the carry | `WET_AET_CARRY` | Explicit; the reference fit must be current (`aet_md5_for()`), not only self-consistent |
| Pooled variant | `wb_validate.R` | Nested choice per fold when no `pooled_variant.txt`: the pre-#43 behaviour, which the test exists to settle |
| cgiar as the #15 winner | `wb_aet_compare.R:149` | #15's own pre-registered rule (CGIAR stays unless a challenger passes): a rule's outcome, not a fallback |
| Report names | `wb_report()` | 20251014 keeps its published names; other releases are suffixed |

Latent defaults in `R/`, not relied on (every caller passes the argument; round 3 grepped): `wet_wb_raw(aet = "cgiar")`, `wet_wb_fit(pooled_adjust =)` defaulting to "other", and `wet_station_select/monthly/daily(hydat = wet_hydat_path())`. The station-flow scripts do rely on the last one (`station_departure.R`, `data-raw/station_vignette_*.R`), outside the wb pipeline: filed separately.

Round 3 (`review-round3.md`) found no defect that ships a wrong fit or AET, and nothing beyond these defaults. That, with this table, ends the loop.

Nothing else in `scripts/wb_*.R` or `data-raw/segment_vignette_*.R` falls back to a value when one is missing (grepped for `if (is.null(`, `Sys.getenv(` and `else "`).
