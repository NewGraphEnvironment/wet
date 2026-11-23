# PCIC's channel-scale output on the FWA

**Verified:** 2026-11-23 · **Issues:** #9 (the pilot PCIC suggested), #168 (backlog move 6, which ran it); feeds #169 (move 7: #4 scenarios, #5 coverage) · **Produced by:** `scripts/channel_scale_pilot.R` → `data/checks/channel_scale_pilot_20260717.txt`, HYDAT 2026-07-17, fwapg 5d50cc1's `pcic` schema, the live published build, hydromosaic's series fetched on 2026-11-23. The rules were registered in the script's header at 7d6c7b1 (01:46:50 UTC), before the first fetch (01:47:59 UTC). One amendment was made after the numbers were seen: rule 3's CMIP6 listing check, below. Two runs from the cache gave a byte-identical report (`data/logs/168/`).

## Verdict

By the registered rules, move 7 builds:

| domain | gauges with an outlet | rule 1 (crosswalk) | rule 2 (CMIP6 historical) | CMIP6 GCMs | builds on |
|---|---|---|---|---|---|
| Fraser | 73 | 100 % pass | fail: median 0.082 of observed flow from PNWNAmet's | 9 | CMIP5 gridded |
| Coast | 74 | 100 % pass | pass: 0.026 | 8 (no TaiESM1) | CMIP6 routed through fwapg's crosswalk |
| Columbia | 70 | 100 % pass | pass: 0.037 | 9 | CMIP6 routed through fwapg's crosswalk |
| Peace | 27 | 100 % pass | pass: 0.019 | 9 | CMIP6 routed through fwapg's crosswalk |

- **The crosswalk reproduces PCIC.** At all 244 scored gauges whose segment holds a placed outlet, routed PCIC as published matches PCIC's own PNWNAmet outlet series over 1981–2010. Annual flow agrees within 1e-4 at 242 of them; the largest difference is 0.12 % (08LE031, where the two networks disagree above the outlet). This settles what `monthly_error.md`'s check 1 rested on: the scores of routed PCIC are scores of PCIC's own outflow.
- **In the Fraser the CMIP6 runs' historical flow is not PNWNAmet's.** The median of the 9 GCMs' 1981–2010 annual flow runs a median 7.3 % of observed flow below PNWNAmet's at the Fraser gauges (the absolute difference's 90th percentile is 36 %), against 2.0 % on the coast, 3.3 % in the Columbia and 1.5 % above in the Peace. The seasonal shape holds better: share NSE drops 0.036 against PNWNAmet's in the Fraser, inside rule 2's 0.05.
- **The Fraser's fallback is unscored.** Rule 3 sends the Fraser to CMIP5 gridded, which this pilot did not fetch (decision 3). Move 7 should score the CMIP5 runs by rule 2 before building on them, rather than take the fallback as better.

## What the product is

- The portal (`services.pacificclimate.org/chyp`) reads PCIC's `bbox-server` collections, keyed on PCIC's sub-basin outlets (`subid`). Its code names no hydromosaic path, series variable or CSV download, so the identity of the portal's product and hydromosaic rests on the shared `subid` network, runs and variables, not on a traced download.
- hydromosaic (`/hydromosaic` on `services.` and `beehive.pacificclimate.org`) serves daily streamflow, water temperature and saturated dissolved oxygen at those outlets: PNWNAmet, 1950–2012, and 9 MBCn-corrected CMIP6 GCMs under `historical, ssp245` and `historical, ssp585`, 1950–2100, all on the standard calendar.
- fwapg's crosswalk (`extras/pcic_crosswalk`) places those outlets on the FWA, and wet publishes its PNWNAmet run as routed PCIC. Scaling PCIC's output to the whole network, #9's question, is already done for the PNWNAmet run; for a CMIP6 run it is the same job with `MODEL` and `SCENARIO` set.
- hydromosaic lists CMIP6 streamflow at every scored outlet in the Peace and Columbia, where PCIC's July 2026 correspondence said those domains were still to be added. Whether those series are the released product or an earlier run is PCIC's to say.
- On the coast TaiESM1 has no series at any of the 74 outlets scored; the other 8 GCMs are complete.
- The historical half of each SSP's series is its own: `historical, ssp585` differs from `historical, ssp245` before 2015 (by up to 720 m³/s on a day at the six sites), though their 1981–2010 annual flows agree within about 3.5 % at the six sites. MBCn corrects each scenario on its own, so a change signal is taken against the same scenario's 1981–2010.

## The six sites

All in the Fraser. The headwater and the confluence were chosen by rules registered with the others.

| site | station | area km² | HYDAT | PCIC raw | routed published | balance published | wet's accumulation |
|---|---|---|---|---|---|---|---|
| headwater (SALR, interior) | – | 10.0 | – | 0.08 (rebuilt) | 0.08 | 0.13 | 0.10 |
| Salmon River near Prince George | 08KC001 | 4,227.5 | 27.41 | 24.11 | 24.11 | 33.60 | 20.45 |
| Quesnel River at Likely (lake outlet) | 08KH001 | 5,963.1 | 129.61 | 127.18 | 127.18 | 104.99 | 134.18 |
| confluence (BIGC, near 08MB006) | – | 1,019.0 | – | 6.92 | 6.92 | 9.13 | 7.23 |
| Fraser River at Hope (regulated) | 08MF005 | 216,659.4 | 2,663.59 | 2,590.73 | 2,591.08 | 2,701.66 | 2,476.28 |
| Lillooet River near Pemberton (glacier) | 08MG005 | 2,076.2 | 122.10 | 116.29 | 116.29 | 86.95 | 99.58 |

Annual flow, 1981–2010, m³/s. "wet's accumulation" is PCIC's gridded PNWNAmet runoff plus baseflow accumulated over FWA watersheds (centroid sampling, accumulated area), unrouted.

- At every site rule 1 holds: at an outlet's own segment the published flow is PCIC's series; at the interior headwater it is rebuilt exactly from the raw series of the outlets around it and the segment's area share (0.361).
- At Hope the networks disagree above the outlet and routed reads 0.014 % above PCIC's own. PCIC sits 2.7 % below HYDAT there, despite the regulated record.
- The confluence is one of 110 Fraser junctions where June's step in routed flow lands on the segment above the junction. There the step is PCIC's own: the outlet placed on that segment carries the tributary in PCIC's network, and its published flow is its series.

## Change signals and water temperature

Reported, deciding nothing (`data/checks/channel_scale_pilot_20260717.txt` has every GCM).

- Median annual change over the 9 GCMs, 2070–2099 against 1981–2010: from −0.2 % (Quesnel, SSP2-4.5) to +19.8 % (Salmon, SSP5-8.5); every site shows earlier spring flow and lower July–September flow.
- PNWNAmet water temperature at the six outlets peaks at 12.7 °C (the confluence) to 26.7 °C (Salmon) in August. water-temp-bc has daily means on the same days only at Hope, 409 days in 2002–2012: PCIC runs 0.50 °C warm, RMSE 3.06 °C.

## Crosswalk flags

Share of PCIC's outlets by flag, from `pcic.fwa_crosswalk` (#9's "what share needs flags"):

| domain | outlets | placed | no candidate | no series | broken chain | demoted |
|---|---|---|---|---|---|---|
| Fraser | 12,387 | 98.7 % | 0.4 % | 0.0 % | 0.8 % | 0.1 % |
| Coast | 14,605 | 93.9 % | 5.5 % | 0.2 % | 0.3 % | 0.1 % |
| Columbia | 11,033 | 49.4 % | 47.8 % | 0.0 % | 2.8 % | 0.1 % |
| Peace | 10,691 | 63.2 % | 36.3 % | 0.0 % | 0.5 % | 0.0 % |

Almost all unplaced Columbia and Peace outlets are `no_candidate`: no usable FWA stream within 150 m. This pilot did not map where they are.

## What move 7 builds on

- **First check:** whether each CMIP6 run's outlets with series are PNWNAmet's. fwapg's crosswalk refuses a run whose crosswalk differs from the stored one, and on the coast TaiESM1 already lacks series at every outlet scored.
- **Cost:** 2,194 CMIP6 outlet series took 798 MiB and 35 minutes of transfer here, one request at a time. At that pace a whole CMIP6 run (48,688 outlets with series) is about 17 GiB and 13 hours. fwapg's job fetches three batches at once, and its research puts a CMIP6 run's fetch at about 1.5 h.
- **The Fraser:** CMIP5 gridded by the rule, scored first by rule 2 against PNWNAmet at the same gauges.
- Done by hand in this pilot: starting the database and writing the site table. Everything else ran from the script.
