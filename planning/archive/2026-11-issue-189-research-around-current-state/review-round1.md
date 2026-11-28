## Checklist read
- index: in full.
- code-check-python.md: in full.
- code-check.md: the prose of every H3 under `## Mechanisms` (table rows skipped; "A guard that fails toward pass" through "Written data outlives the fix", "Serialization loses meaning silently", "One fact derived twice", and the probe section), plus "Documentation Staleness". The other H3s were not read in full.
- code-check-shell.md: "`git diff a..b` compares TIPS". The rest read by index line only.
- code-check-r.md and code-check-spatial.md: no full sections; index lines only (the diff is prose plus one Python script).
- diff and changed files: the four rewritten notes were read from the tree and compared with origin/main; the research/README.md, fwapg and planning/archive diffs were read through git diff; numbers_check.py was read in full.

## Findings

- **[severity: bug]** research/chinook_sites.md, "What changed", bullet "Years behind each period": "Maxan's carried base is 10 years (its donors, 08EE003, 08EE013, 08JA016 and, for the maximum, 08JB002, hold no record from 1952 to 1970)" is false for the maximum and for 08JB002. `departure_site_maxan_bulk_20260717.txt`, section 6, gives the carried `max` rows (migration and spawning) a 1951-1980 base of **30** years, not 10, with donors that include 08JB002. HYDAT 20260717 (read-only query) has 08JB002 in all 19 years 1952-1970, and has none of the other three in any of them. This is a stale claim carried over from the old note, and the archive-moved old bullet holds the same wording. The 10-year base holds for mean, min7 and cov_day only.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug]** research/chinook_sites.md, same bullet: "1951-1980 has 20-30, except where covariance_pick chooses donors with short or broken records: Maxan..., Gosnell's migration-window min7 under the Morice windows is 17 and Naver's spawning-window cov_day under the Bulkley's 18" leaves out one shipped-route value. `departure_site_naver_cotr_20260717.txt`, section 6 (covariance_pick ships there), gives carried `max` migration a 1951-1980 base of **14** years. So the list of exceptions is incomplete. Either add it or limit the sentence to the scored statistics, which excludes max.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug]** research/station_flow_departure.md, "Provisional winters are not usable": "approved December-February means from 1981 run 0.06 to 2.1 m3/s, median 0.55" mixes two statistics. From HYDAT 20260717, 08EE013:
  - Season (Dec-Feb) means run 0.059 to 2.06, but their median is 0.57-0.58 (0.53 over 1981-2010 only). `wet_window_stats()` on the bundle gives 0.570 or 0.579, depending on the first season counted.
  - Single-month means for Dec, Jan and Feb from 1981 have a median of 0.55, but run **0.025 to 3.94**.
  
  The sentence sets this against provisional *monthly* means (6.6, 7.8, 15). Read as monthly, the range is wrong: the top is 3.9, not 2.1. Read as seasonal, the median is wrong. planning/active/findings.md marks it "restated from the read".
  - **Rule:** code-check.md "One fact derived twice"

- **[severity: fragile]** research/chinook_sites.md, "What changed", bullet "Migration-window mean": "Lower in every row, by 5 to 30 %, and clearly only at Maxan, on both routes." The section has two tables. In the filled-in table, Naver under COTR is **+2 %**, Naver under BULK is -0 %, and Swift is -4 % and -5 %. "Lower in every row, by 5 to 30 %" therefore holds only for the shipped-route table. "On both routes" invites reading it over both tables. The spawning bullet beside it names the route for each claim. This one should too: "lower in every shipped-route row...; at Maxan clearly on both routes".
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** research/chinook_sites.md, "Snow", last bullet: "Each site's snow gauges are the nearest two long records with an accepted snap, which depends on the windows". This is not how Maxan's were chosen. `departure_site_snow_maxan_bulk_20260717.txt` reads "Snow gauges: 08EE003, 08EE013, by the site table's snow_gauges", and `scripts/departure_sites.csv` fills `snow_gauges` for maxan only. The rule applies to Swift, Naver and Gosnell. Its pool also differs by site: the extension donor chain, or the carried donors at Gosnell.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

Checked and agreeing, for scope: the following matched their reports.
- discharge_publish.md: the build report, the daily report and the live fresh-bc manifest (read anonymously), including per-dataset GB, SETN at 373 MB, the 247 fit files and the clamp and day-mean figures.
- chinook_sites.md: the use table, both held-out score tables, both change tables, the snow R2 and snow-change figures, Gosnell's normal and its error, and the Maxan pilot tables.
- station_flow_departure.md: the pilot and snow figures, the ice shares, the August figures, the seasonal-gauge months and the 2016-2025 change and coverage figures.
- fwapg_mad_method.md: the new Fraser figures against data/basin/100_report.txt and both upstream-area reports.

No script under scripts/ or data-raw/ was run, and no request went to PCIC.
