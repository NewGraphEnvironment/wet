## Outcome

The question was whether climr's precipitation is too high on the dry interior plateaus (hydrologic zones 15, 17, 23 and 24). That was the lean #45 left behind, with climr P at 1.43–1.61 × PNWNAmet there against 1.15 elsewhere. `scripts/wb_plateau_p.R` scored climr, PNWNAmet (PCIC PREC) and TerraClimate against the River Forecast Centre's own observations at plateau elevation: ASWS precipitation gauges and pillows, and April 1 snow courses. Dry zones were compared with the interior zones east of the Coast Mountains, at 900–2,100 m in PCIC's domain.

The rule was fixed before any product value was computed at a site. A blind plan review then found 4 blockers and 6 gaps, and the rule was amended (Amendment 2) before any value was seen. Running it took three recorded deviations and one correction:
- **Deviation 1.** The archive defines daily P as max(0, ΔAccumP). The registered hourly processing kept signed days, so check (a) stopped the first run.
- **Deviation 1b.** The archive's own negative P is floored too.
- **Deviation 1c.** The daily era's evaporation flag reads AccumP.
- **Correction 1.** The catch-factor denominator was wrong.

**Result: registered verdict "not decided"; no correction issue.**
- The gauge sites do show #45's gap: R = 1.18.
- climr is at most modestly high relative to the interior: D = 1.09, bootstrap 0.98–1.28, unstable toward about 1.2 under two conditions.
- climr's winter P is never below snow-course SWE.

Post hoc, on the long-record gauges D(climr) is 1.01 and D(PNWNAmet) 0.91. So part of #45's gap is PNWNAmet's, and #45's lean to climr's plateau P is weakened. The written result is in `research/water_balance_method.md` §0, "Plateau precipitation (#50)". The next candidate for zone 24 is the gauge side: diversions and storage on the plateau creeks.

Also filed: #51 (two older scripts average climr's 1961–1990 reference row into 1981–2010 means).

## Measurement

**Sites.** 18 dry and 55 contrast ASWS gauges with complete water years; 42 dry and 92 contrast snow courses.

**Check (a)**, daily archive ÷ hourly PC on 285 overlap gauge-years at 50 sites:
- as registered: **1.156**, and the run stopped;
- after Deviation 1: 1.01.
- The evaporation flag on the same years after Deviation 1c: 195 from AccumP against 196 from hourly PC, 189 on the same years.

**B3:** climr ÷ PNWNAmet, dry over contrast, at the gauge sites (WY ≤ 2012) is **1.18**. Zone 15: 1.51; zone 24: 1.63.

**T1:** D(climr) = **1.09** (13 dry, 46 contrast), in the inconclusive band (1.05–1.15).
- leave-one-out 1.07–1.14;
- bootstrap 90 % 0.98–1.28;
- era ≤ 2011: 1.01; era ≥ 2012: 1.12;
- without the PRISM-input gauges: 1.19; without the flagged years: 1.20; |Δz| ≤ 200 m: 1.15.
- D(PNWNAmet) = 0.91; D(TerraClimate) = 1.07.

**T2:** climr ÷ gauge P is below 1 at 23 % of the dry gauges, so no veto. The catch factor is 1.00 at the median in both groups.

**T3**, share of dry courses where winter P is below the April 1 SWE: climr 2 %, PNWNAmet 29 %, TerraClimate 21 %. The dry ÷ contrast P/SWE factor is 1.61, 1.16 and 1.51.

**What changed because of it.** #45's post hoc lean to climr's plateau P no longer stands as the leading explanation. The gauges that cover the dry interior do not show a climr excess of the size #45's basin ratios implied, so the next step moves to the gauge side.

**Wrong turns, kept:**
- A first observation run under the pre-review processing was stopped unread.
- climr returned its 1961_1990 row despite `return_refperiod = FALSE`, which first crashed the run and then exposed #51.
- TerraClimate's NCSS returned one month until `temporal=all` was added.
- Three code-check rounds each found a defect, two of them inside the previous fix. Round 3 named the mechanism (the gauge's daily increment derived two ways, one per era) and enumerated all 25 ratios in the script. That enumeration ended the loop.

## Evidence

- Report: `data/checks/wb_plateau_p.txt` (tracked; reproduces byte-identical from cache).
- Run logs: `data/logs/50/20261007_*` on m1 (gitignored).
- Caches and raw snapshots (md5s in the report): `data/plateau_p/` on m1.
- Reviews in this directory: `review-rule.md` (the blind rule review) and `review-round{1,2,3}.md` (code-check).

Closed by: PR (this branch), `Fixes #50`.
