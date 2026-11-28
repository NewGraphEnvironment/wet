## Outcome

Backlog move 5 (#167) became batch 8 alone. At the plan gate the four chinook site boxes were counted against #123's station survey. The province's non-integrated stations and the BC Water Tool's third-party gauges hold no record with a 1981–2010 baseline in any box, so they can add no carry donor there. Batch 7 (#142, #144) moved to its own move, #179, and the count went into `research/station_sources.md`. #135 gave PCIC's per-year files a per-machine cache, `wet:::wet_pcic_years()`: a download lands only when its size equals its `pcic.series` row, `WET_PCIC_YEARS` still names any other directory, and `scripts/departure_pcic.R` and `scripts/gauge_monthly_compare.R` default to the cache through `routed_years_dir()`. #147's rule was registered in `scripts/departure_site.R`'s header before any body code, then amended from the plan review before any run. A section 6 in each site report scores #122's `covariance_pick` against inverse distance at the box's PCIC-covered gauges, and ships it where it wins by 0.01 under leave-one-out and leak-free. It ships at Maxan, Naver and Gosnell (both window sets); Swift keeps distance. The comparison article now carries each stream's shipped borrowed route: its answer, scores and limits were rewritten from guarded values, and its maps rebuilt. Findings: `research/chinook_sites.md`, "covariance_pick at the sites (#147)".

## Measurement

- **Cache:** 62 files, 1951–2012, 8.67 GiB, filled from `fresh-bc/fwapg/extras/` in about 14 min on m1, each held to its `pcic.series` row (fwapg commit 26d7582).
- **Verdicts** (median held-out centred log NSE, migration mean, covered gauges; distance against covariance_pick):

  | site | distance | covariance_pick | ships |
  |---|---|---|---|
  | Maxan | 0.62 | 0.67 | covariance_pick |
  | Swift | 0.55 | 0.61 | distance (leak-free gain 0.000) |
  | Naver | 0.58 | 0.75 | covariance_pick |
  | Gosnell | 0.64 | 0.67 | covariance_pick |

  PCIC covers every box (Morice 50 of 54 gauges, upper Fraser 27 of 30), settling the gate's open question.
- **The article's story moved.** Maxan's borrowed migration-window mean now falls 30 % (range −49 to −4 %), clear of no change. The spawning seven-day low is clear at Gosnell as well as Maxan. Borrowed spawning scores now clear the 0.5 bar everywhere but Swift (Maxan 0.49 → 0.66, Naver 0.42 → 0.60, Gosnell 0.45 → 0.71). Maxan's 1951–1980 base under covariance_pick is 10 years, since its donors hold no record from 1952 to 1970; the article says so.
- **Sections 1–5 reproduce on m1**, byte for byte at Maxan, Swift and Naver, and in all five snow reports. The rds `mx` matches m4's to within 7e-14. Gosnell's normal-error rows moved because the live build changed under them: #163 uploaded LEUT, UEUT and UNRS on 2026-11-14, so the digest went 0f4f8caa → d554e3aa. Traced and accepted, not a branch defect.
- **Wrong turns kept:** the first version of the article's Maxan limit said its donors had "almost no record before 1971". The years showed 1931–1951 present and only 1952–1970 missing, and the sentence was corrected with a guard. The short-record bundle rebuilt on m1 differed from m4's by rounding only (at most 3e-11), so the committed one was kept.
- **Review:** a plan review and five code-review rounds. Round 1: an RPostgres integer64 id zeroed by `rbind()`, which would have kept Gosnell on distance whatever its scores. Rounds 2–4: section 6's empty-pool paths, two findings inside round 2's fixes. Round 5: an article sentence the new values made false. Ended by enumeration (`review-verdict.md`).

## Evidence

`data/logs/167/` in m1's checkout (gitignored): `pcic_years_fill_*`, `trial_site_maxan_*`, `site_*_20261119.log`, `snow_*_20261119.log`, `site_runs_*`, `chinook_sites_*`, `short_record_vignette_data_*`, `test_suite_*`. The tracked reports are `data/checks/departure_site[_snow]_*_20260717.txt`.

Closed by: PR for branch `167-backlog-move-5-more-donors-and-pcic-s-ye` (closes #135, #147; #167's umbrella)

## From research/chinook_sites.md (moved by #189)

- **Maxan's 1951–1980 base is 10 years** under covariance_pick: its donors (08EE003, 08EE013, 08JA016, and 08JB002 for max) hold no record from 1952 to 1970, against 20–30 years on every other route.

- **Held-out scores rise** wherever it ships, most in the spawning window (Maxan 0.49 → 0.66, Naver 0.42 → 0.60, Gosnell 0.45 → 0.71) and for the lowest seven-day flow, now below the 0.5 bar in 4 of 8 site-windows rather than 7.

- **Gosnell's normal-error rows moved** for another reason: the published build changed under the report (digest 0f4f8caa → d554e3aa, #163's upload of LEUT, UEUT and UNRS on 2026-11-14), so four Nechako box gauges' picked source and the error quartiles changed. The mouth's normal did not.
