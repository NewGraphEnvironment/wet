# WALLY's mean annual runoff model beside wet's estimates at the calibration gauges

**Verified:** 2026-11-23 · **Issues:** #178 (its desk comparison and gauge filters), in backlog move 11 (#188) · **Produced by:** `scripts/wally_compare.R` → `data/checks/wally_compare_20260717.txt`. Inputs: `bcgov/WALLY`'s `modelling/` folder at commit 9de322b (Apache-2.0; each file's md5 in the report, each fetch in `data/logs/188/wally_fetch.tsv`), Table 1 of its report `WALLY_Modeling_FSL_V0.5.pdf` transcribed in `scripts/wally_zone_scores.csv` (digits from the PDF's text layer, each coefficient's column from the page image, both held to the table's own Count and Average rows), and the shipped fit (HYDAT 2026-07-17, province run 768876badf). Two runs gave byte-identical reports. · **Status:** desk comparison done; the hosted tool was not used; WALLY's approach as a candidate adjustment is scored in a follow-up issue.

WALLY, the province's Water Allocation Data Library, estimates mean annual runoff (MAR, in l/s/km²) at ungauged sites by regressing it on catchment traits, one model per hydrologic zone. Its 2021 modelling folder is open. Under "own estimates first" (CLAUDE.md) it is a yardstick here, not an input.

## The answer

- **WALLY's models lean on precipitation, slope and glacier cover.** Of its 27 zone models, precipitation is in 16, average slope in 15, glacier cover in 14, potential ET in 13, median elevation in 12, solar exposure in 8 and drainage area in 2.
- **Its gauge set is close to ours but not natural-flow only.** 280 of our 315 calibration gauges are among its 482 training stations, so a WALLY score there is in-sample. It filters on licensed use, not regulation: HYDAT flags 110 of its 482 stations as regulated.
- **Its published scores are not held out, and ours are, so the two are not a race.** In each zone WALLY's R² is computed over training and test stations together. Its median zone R² is 90 %, against the balance's held-out 60 % and routed PCIC's 74 % on the same zone classes. Province-wide, the held-out balance reaches R² 87 % and routed PCIC 90 %, against WALLY's in-sample XGBoost 96 %.

## What WALLY's models use

The report's MkMGR (modified k-fold multivariate geospatial regression, p. 23) fits ordinary least squares per hydrologic zone, with zones 7, 11 and 12 pooled. Its candidate traits are annual precipitation, average slope, drainage area, glacier cover, median elevation, potential ET (Hamon) and solar exposure, all computed over WALLY's own catchment outlines (DEM-delineated, then fitted to the Freshwater Atlas). For each zone it keeps the trait set with the highest minimum R² over 30 random 70/30 splits and refits it on all stations. Table 1 gives unstandardized coefficients, so it ranks no trait inside a zone; a trait in a zone's model is counted as used there.

The report names precipitation, slope, glacier, PET and median elevation as the important traits, and drainage area and solar exposure as minor (p. 35). Its XGBoost model is one model over all zones, and by gain it puts precipitation far first, then PET and glacier (p. 62).

## How each picks its gauges

- **WALLY:**
  - its catchment area within 20 % of HYDAT's gross area;
  - more than 10 years of record in any years, with MAR over the whole record;
  - gross licensed allocation at most 200 % of mean annual discharge, or net allocation zero (p. 19);
  - naturalization was not attempted, and there is no regulation filter.
- **The open balance:**
  - HYDAT's natural flag;
  - at least 10 complete years in 1981–2010;
  - its FWA area within 10 % of HYDAT's gross area;
  - at least 95 % of the basin in BC and on the climate grid.

The folder's earlier merged tables were cut at 5 % of HYDAT's area; the training table the report's models use is cut at 20 %.

Of WALLY's 482 training stations, 280 are our calibration gauges. The other 202 are regulated by HYDAT's flag (110), short of 10 complete years in 1981–2010 (76), under 95 % in BC or on the grid (11), or off by more than 10 % in FWA area (5). Of our 315, 32 are not in WALLY's table at all, and 3 are dropped by its allocation filter. At the 280 shared gauges the measured MAR barely differs: WALLY's, over the whole record and its own area, is a median 1.01 times ours. Their hydrologic zones agree at 275. WALLY places a gauge by the station's location, and we use the zone covering most of the basin.

## How the scores compare

The report keeps no held-out error per zone. For each zone its Table 1 gives:

- R² on all stations, training and test together, because in small zones a test set of 2 or 3 stations could not be scored (p. 23);
- the lowest R² of the 30 splits;
- STEYX, the model's standard error in l/s/km².

At the pinned commit the model script scores each split's test set, but the report says R² was taken over all stations. Which of the two Table 1's lowest R² is cannot be told from the table.

Ours are scored in WALLY's metric over the 25 zone classes holding 5 or more of our gauges. R² is the squared correlation of the held-out value with observed MAR, and the error is RMSE in l/s/km²:

- WALLY's median zone R² is 90 % (lowest-split R² 83 %);
- the held-out balance's median is 60 %, and it reaches WALLY's R² in 1 class of 25;
- routed PCIC's median is 74 %, over the 23 classes with 5 or more of its shared gauges;
- the median ratio of our RMSE to WALLY's STEYX is 2.2 for the balance and 1.8 for routed PCIC.

Province-wide, the balance's held-out R² is 87 % (RMSE 12.5 l/s/km²) at all 315 gauges, and routed PCIC's is 90 % (11.2) at its 283 shared gauges. WALLY's XGBoost scores 96 % (STEYX 5.9) over 480 stations, its predictions made with all of them in training.

How much of the gap is the scoring is not known: an in-sample R² on 6 to 43 stations from a model with up to 5 traits is optimistic, by an amount the report does not measure. Whether a per-zone regression on catchment traits holds up held out is the candidate the follow-up issue scores, under a rule registered before its numbers.

## Not done here

- **The hosted WALLY tool** needs a sign-in, and nothing above depends on it. A few sites by hand stays open in #178.
- **Running WALLY's models at our gauges** is out of scope (#178): its traits come from its own catchment outlines, which we cannot reproduce or keep current.
