# Findings — Backlog move 17: Provincial station records, current copy and Hakai's early years (#210)

## Issue context

**If we do it:** we know which copy of the province's 2021–2026 non-integrated discharge is current, and the three Hakai stations on Calvert and Hecate islands gain their 2013–2020 record, enough years to serve as donors and test sites on the central coast. **If we never do:** those provincial years stay of unknown standing, and wet reads the Hakai stations from 2021 only.

Order: `planning/backlog.md`, move 17. Run `/planning-init <this issue>`: one phase, one PR.

When the plan finds that a batch, or one of its members, is more than one PR's work, it carries the first piece and files each other piece as its own issue naming move 17, and leaves it out of `planning/backlog.md`: the next `/backlog-sweep` places it in another move.

## Batch 19: provincial station records, current copy and Hakai's early years

**Why here:** both continue the province's station records through `wet_station_daily()`'s sources and the chaining rule move 13 landed, both rebuild the same station registry, and both edit `research/station_sources.md`, which #207 consolidates in the same pass. Both were split from move 13.

**Touches:** `R/wet_station_daily.R`, `data-raw/station_sources_snapshot.R`, `inst/extdata/station_sources/`, `research/station_sources.md`, `tests/testthat/test-wet_station_daily.R`.

**Decided at the gate:** whether to accept the province's Aquarius WebPortal click-through disclaimer, so its 2021–2026 records can be read and compared (#190); Hakai's published data package, or asking Hakai whether a scripted read is welcome, which is outward contact through the owner (#192); how an earlier record from another publisher continues a provincial station under its own number.

| issue | title |
|---|---|
| #190 | Tell which copy of the province's 2021–2026 discharge is current, from its Aquarius portal |
| #192 | Hakai's 2013–2020 discharge at its three Calvert and Hecate stations |
| #207 | Consolidate research/station_sources.md around the current state |

## Exploration, 2026-11-25 (plan)

- **Members free.** `members_check.sh` on #210: `FREE #190`, `FREE #192`, `FREE #207`.
- **#207's flag is words, not sections.** `research_check.sh research/station_sources.md` →
  `words=5004 sections=0 verified=2026-10-29 FLAG words` (threshold 3,000 prose words; `sections`
  counts issue-headed headings, of which the file has none; it has 12 plain `##` sections).
- **Hakai package period.** Korver, Haughton, Floyd and Giesbrecht 2022, "High-resolution streamflow
  and weather data (2013–2019) for seven small coastal watersheds in the northeast Pacific coastal
  temperate rainforest, Canada", ESSD 14, 4231–4250 (<https://essd.copernicus.org/articles/14/4231/2022/>):
  1 October 2013 to 30 September 2019, hourly and 5-minute data at DOI 10.21966/J99C-9C14,
  watershed delineations at DOI 10.21966/1.15311 [S, the article's landing page via search; the data
  package itself not yet read].
- **Provincial Hakai records begin 2021-10-01** (`inst/extdata/station_sources/bcenv_20261028_hydat.csv`:
  H08KC0626, H08KC0703, H08KC0844, `first` 2021-10-01, `last` 2026-10-27, regulation `unknown`). So
  the package leaves 2019-10-01 to 2021-09-30 out, and no day overlaps for a parity check.
- **Aquarius portal.** `aqrt.nrs.gov.bc.ca` redirects to `bcmoe-prod.aquaticinformatics.net`; curl's
  default agent gets `/InvalidBrowser` (HTTP 500), a browser agent gets `/Disclaimer` (HTTP 200) with
  Accept and Reject buttons. Text: "Welcome to the Real-time Water Data Tool. The information provided
  should not be used as a basis for making financial or any other commitments. The Government of
  British Columbia accepts no liability for the accuracy, availability, suitability, reliability,
  usability, completeness or timeliness of the data or graphical depictions rendered from the data.
  Read our Disclaimer and Privacy pages for more information." `robots.txt` answers HTTP 200, empty.
  Not accepted. The linked Terms of use not yet read.
- **Regulation file pins the registries.** `scripts/station_regulation.R` hashes the shipped registries
  (`reg_md5`), and `wet_station_regulation()` refuses a status file built from other md5s, so the Hakai
  rows go in a registry of their own rather than the Tool's.
- **Continuation code today.** `wet_bcwatertool_station_days()` (`R/wet_station_daily.R`) cuts a
  continuing listing at `continues_before` and renames it to the provincial number;
  `wet_station_list()` splices a continued station's `first`, `licence` and `credit`. Both are
  Tool-specific and are generalised in Phase 2.

## Phase 1: the Aquarius portal (#190), 2026-11-25

- **Terms.** The portal's own disclaimer (above) and the page it links, `gov.bc.ca/disclaimer` (updated 2016-09-07): a warranty disclaimer and a limitation of liability, no restriction on use. The vendor's `us.aquaticinformatics.net/legal/terms-of-use` is a JavaScript app (a OneTrust notice) that renders nothing to a script; it covers Aquatic Informatics' own site. The owner accepted (decision 1) and said publishing is unrestricted.
- **Request shape.** `POST /AcceptDisclaimer` with the page's `__RequestVerificationToken` sets the session cookie; `GET /Data/SearchLocations/?term=<id>&limit=21` gives the location's `IDNumber`; `GET /Data/DataSets/?locationid=<IDNumber>` lists its data sets (`Discharge.Working@<id>`, also `Discharge.Field Visits` and `Discharge.Logger`); `GET /Export/DatasetCalculations?datasetId=<n>` lists units (m^3/s instantaneous is UnitId 350); `GET /Export/BulkExport?DateRange=Custom&StartTime=...&EndTime=...&TimeZone=0&Interval=PointsAsRecorded&ExportFormat=csv&IncludeGradeCodes=True&IncludeApprovalLevels=True&Datasets[0].DatasetName=Discharge.Working@<id>&Datasets[0].Calculation=Instantaneous&Datasets[0].UnitId=350` returns 15-minute points in UTC with grade and approval codes (800 working, 900 in review, 950 reviewed, 1200 approved).
- **The provincial files' hour is the portal's point at the hour, rounded** to 0.001 m^3/s (07FC0001, 2023-07-01 00:00: portal 0.6192893, files 0.619).
- **Gaps** are rows of grade -3 with value `NaN` (amendment 1 in the script header).
- **Result** (`data/checks/station_sources_portal_20261125.txt`): the files equal the portal from 2021-10 to 2026-05; January–September 2021 has been revised since both copies were taken; June–October 2026 is partly revised. An ad hoc read of three stations (not in the report) had the disagreeing 2021 hours all at approval 800 (working), with portal/file ratios drifting month to month, 0.72–1.30 at 08NM0002.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| curl to the Aquarius portal returns `/InvalidBrowser` HTTP 500 | Send a browser user-agent |
| The Tool's listings 13511 and 27812 are missing from the manifest | The survey ordered Tool ids as numbers before dropping duplicate nids; order numerically |
| A plan edit matched an inline mention of `## Open decisions` and truncated the plan (committed in a6a029f5) | Restored from the baseline; match the heading with its newlines |
