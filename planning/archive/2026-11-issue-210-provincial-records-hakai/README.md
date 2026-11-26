## Outcome

Backlog move 17 (#210) carried three members in one PR.

**#190.** `scripts/station_sources_portal.R` reads the province's Aquarius portal. It registered its rules and committed its station pick before any portal value was read. It compares the portal's working series with the pinned provincial files and with the BC Water Tool's copy. Where the portal logs a point on the hour, the pinned files equal it from October 2021 to May 2026. The Tool's copy is the one that parts. For January–September 2021 the portal has been revised since both copies were taken, at four of five stations. The portal also holds months the pin lacks: three stations' 2021, and one station's 2026 season. Spans where a logger records off the hour (20,484 pinned hours) were not compared. A newer provincial pin is #232.

**#192.** `wet_station_daily(sources = "hakai")` reads Hakai Institute's published package (DOI 10.21966/J99C-9C14, CC-BY 4.0, pinned at commit 8318556d2baf). Its 2014–2019 days continue H08KC0626, H08KC0703 and H08KC0844 under the provincial number. They go through the Water Tool's continuation rule, which a pure refactor commit first made shared. The package's timestamps end in `Z` but are PST hour ends, as its README says; three checks agree, and the rules were registered before any day was counted. The other four watersheds are #233. The draft ask to Hakai for the 2019–2021 years (its ERDDAP disallows queries) is in `findings.md`, unsent.

**#207.** `research/station_sources.md` was rewritten around the current state: 6,035 prose words down to 2,998. History moved verbatim into the #123, #179, #195 and #196 archive READMEs.

What was learned:
- An agreement share taken on hours both copies hold says nothing about hours one copy lacks.
- A coverage count keyed only on top-of-hour points misreads off-the-hour loggers as missing data.
- Code-check rounds 3 to 6 each found a prose claim summarising a nearby set. The loop ended on round 6's enumeration of 86 claims, with 1 wrong and then fixed (`review-verdict.md`).

## Measurement

- **Portal against the pinned files**, on compared hours (the portal's points on the hour): 99.9–100 % a month from 2021-10 to 2026-05; 0.1–24 % a month January–September 2021; 80–91 % from June 2026.
- **The Tool's copy against the portal:** 38–83 % of days a year from 2022.
- **Coverage:** 0 pinned hours with no portal point in the hour; 20,484 pinned hours at four off-the-hour loggers not compared. This changed the #190 answer from "the pinned files are current" to "equal where compared, with revised and added months to pin".
- **Hakai:** 1,885, 1,883 and 1,846 days added, 93.4–98.5 % approved. Complete Chinook-window years rise from 5 to 10, 2 to 7 and 4 to 9; H08KC0703 now passes the station test.
- **Timestamps:** rain-to-rise lag 2 h (correlation 0.37, not 10 h), and solar radiation peaks at the hour ending 13:00. Together they turned the README's "PST" from a statement into a measurement.

`research/station_sources.md` ("Data notes", "The Hakai package in wet") holds the current statement.

## Evidence

`data/checks/station_sources_portal_20261125.txt` (its pick committed first, at a6a029f5); `data/checks/station_sources_hakai_8318556d2baf.txt`. Both reproduce byte for byte from the raw copies under the main checkout's gitignored `data/station_sources/raw/portal/20261125/` and `data/station_sources/raw/hakai/8318556d2baf*/`. Hakai's file is backed up privately at `s3://fresh-bc/station_sources/hakai/8318556d2baf/`.

Closed by: PR for branch `210-backlog-move-17-provincial-station-recor` (#190, #192, #207)
