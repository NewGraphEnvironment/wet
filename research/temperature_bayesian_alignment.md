# How the water-temperature baseline stands against Bayesian practice

**Verified:** 2026-11-27 · **Issues:** #218 (this review), read beside #217's file on a network model; it reads what #40 (the gap fill) and #213 (the whole-station baseline) built, for the roadmap #214 · **Produced by:** the code at this commit, read line by line; the `statistics` store (McElreath 2020 and Gelman et al. 2013, searched through cred); every quote that cites a page checked on that page, every choice held to its line and every figure to its source by `scripts/temperature_bayesian_alignment_check.R` (log `data/checks/temperature_bayesian_alignment_*.txt`) · **Status:** review complete; nothing was refitted and no figure is new.

The two books are McElreath, *Statistical Rethinking*, 2nd ed. (2020; Rethinking) and Gelman et al., *Bayesian Data Analysis*, 3rd ed. (2013; BDA3). Pages are the printed ones. Quotes are short and only where a passage decides a row; each carries its citekey, the form the check reads. The method's numbers are in `research/station_temperature_fill.md` and the tracked reports it names; this file quotes only the ones a row turns on.

## In brief

**What the method does.** Two pieces. The gap fill (`wet_temp_fill()`) fits air2stream, a three-parameter model of daily water temperature driven by daily air temperature, to each station's own record by least squares, then carries the station's departure from it across a gap with an AR(1) process in a Kalman smoother, nudged by its neighbours' shared errors. Degree days over the growing season (GSDD) are then summed from the filled series (`wet_temp_gsdd()`). The whole-station baseline (`scripts/temp_baseline*.R`) hides a station's whole record, predicts its three parameters from catchment traits with one of three candidates (the population mean, a least-squares regression, the mean of the nearest stations in trait space), runs the model on the station's own air, and scores the GSDD error, with a station's upstream and downstream neighbours removed from training in the leak-free pool.

**What was asked.** Where does each choice sit against Bayesian practice as these two books teach it: aligned, different, different on purpose, or outside what the books cover? And for each difference, what does it cost, in wet's own results?

**How it was judged.** Each statement about the method was read from the code (file and line, in the table under Choices), not from its documentation. Each statement about the books was found through the store and read on its page.

**What stands.** The test design is what the books ask for when the question is a new site: whole stations are held out, the folds follow the drainage, and the leak-free pool removes the neighbours that share a stretch of stream with the station being predicted. The candidates were run first on data simulated from known values, and that recovery checked interval coverage as BDA3's fake-data debugging does. The regression's predictive interval is the one a flat-prior Bayesian regression gives.

**Where it differs.** Everything is a point estimate. Each station's parameters are fitted alone, with no pull toward the other stations, by least squares with no prior; the departure's settings are fitted by maximum likelihood; and every interval is built around those point values. So the fill's interval is too narrow, the baseline's intervals stop at the parameters, and no GSDD carries an interval at all. Air temperature and the observed days are taken as exact. The regression and the simulation treat the three parameters as unrelated, though two of them are correlated at the stations.

**What this is not.** A refit, or a verdict that the method is wrong. Most of the differences are what any fast per-station method does, and several are deliberate. The point is to name which of the baseline's numbers a fuller model is in a position to improve, and why. The list is at the end.

## The questions, one at a time

Each subsection teaches the principle first, then says where the code stands.

### Is each station fitted alone, or pooled? (Rethinking ch. 13–14; BDA3 ch. 5)

*The principle.* With many related units, a model can fit each unit alone, treat them all as one, or let them share information in proportion to how alike they turn out to be. Rethinking describes the first as an assumption: "This means we assume that each pond tells us nothing about any other pond" (mcelreath2020StatisticalRethinking, p. 408). The third, partial pooling, is regularisation learned from the data: "Varying intercepts are just regularized estimates, but adaptively regularized by estimating how diverse the clusters are while estimating the features of each cluster" (mcelreath2020StatisticalRethinking, p. 408). BDA3 puts it the same way: "Hierarchical modeling automatically partially pools estimates" (gelman_etal2013Bayesiandata, p. 96). It is no guarantee for any one unit: "Partial pooling isn't always better. It's just better on average in the long run" (mcelreath2020StatisticalRethinking, p. 413).

Two extensions matter here. When a unit has several parameters, their correlation can be learned too, and "The inferred correlation between these varying effects was used to pool information across them" (mcelreath2020StatisticalRethinking, p. 444). And when units sit along a continuous distance, the sharing can fall off with it, on the reasoning that "individuals of similar ages should have more similar intercepts" (mcelreath2020StatisticalRethinking, p. 468): a Gaussian process. Distance along a stream network is such a dimension, though an ordinary kernel need not be a valid covariance on it; the tail-up and tail-down covariances SSN2 fits are the constructions built for stream distance.

*Where the code stands.* The fill fits each station's three parameters alone (`each_station_alone`): no pooling. A station with one year of record gets parameters as free as one with twenty. The baseline then predicts a new station's parameters from the others, which is pooling of a kind, but of the point estimates, each treated as exact, and with the three parameters predicted separately (`cand_regression`). Its population-mean candidate is complete pooling (`cand_mean`); its regression is pooling through traits with no group-level variance; its nearest-stations mean pools by similarity in trait space with fixed weights (`cand_donor`, `donor_weights`), which no book here teaches. None shares along the stream network on purpose: the leak-free pool exists to stop the candidates from doing it by accident. Beyond the held-out station's own sub-sub-drainage, which both pools leave out, it removes flow-connected stations only, so stations of other sub-sub-drainages on sister tributaries, which a tail-down covariance would borrow from, stay in training.

*What it costs.* The regression's leak-free error is 298.0 °C-days against 97.5 °C-days on a station's own parameters, about three times as large. Neighbours on the same stream are worth 4.1 °C-days to the regression and 11.5 °C-days to the nearest-stations mean when they are allowed in, with no interval given for either difference. The intercept and slope are correlated at −0.49 at the stations' own fits, and nothing uses that. Whether a pooled or network model closes part of the gap is what a fuller model would test; the baseline cannot say.

### Priors and regularisation (Rethinking ch. 7; BDA3 ch. 14)

*The principle.* A flat prior is a choice with a cost: "When the priors are flat or nearly flat, the machine interprets this to mean that every parameter value is equally plausible" (mcelreath2020StatisticalRethinking, p. 214), and the fit then follows the sample as closely as the likelihood allows. A regularising prior trades a little fit in the sample for better prediction out of it. For an ordinary regression with plenty of data the flat prior is harmless: "Under a standard noninformative prior distribution, the Bayesian estimates and standard errors coincide with the classical results" (gelman_etal2013Bayesiandata, p. 355).

*Where the code stands.* Every fit in the fill is unregularised: least squares on the open-loop error for the three parameters (`open_loop_lsq`), maximum likelihood for the departure (`departure_ml`), from two starting values (`two_starts`) rather than a check that the search converged. Where the fits went wrong on real data, hard caps were added in place of a prior: the departure's persistence at most 0.999 and its noise at least 0.01 °C, after a stuck sensor fitted a noise of nearly zero (`departure_caps`). The baseline's regression is ordinary least squares, so the BDA3 passage above makes its estimates and intervals the flat-prior Bayesian ones (`regression_interval`), given the stations' fitted parameters as data; a station with one year of record and one with twenty count alike, though their estimates differ in precision. A trait with no spread in a training set is dropped from that fit (`no_spread_dropped`), and traits are z-scored on the training rows alone (`zscore_training`).

*What it costs.* Where the response rate is poorly identified, the equilibrium intercept (the first parameter over the third, `theta_transform`) runs away: the first end-to-end recovery run found intercepts in the hundreds at stations whose simulated departure was too large, and one such station spoils a mean or a regression (`research/station_temperature_fill.md`). The real fits hold no such station, but nothing in the fit would stop one. A prior on the response rate would.

### Intervals and parameter uncertainty (Rethinking ch. 3; BDA3 ch. 7)

*The principle.* A prediction has two kinds of uncertainty: the noise the model expects around any parameter value, and not knowing the parameter. "We'd like to propagate the parameter uncertainty—carry it forward—as we evaluate the implied predictions" (mcelreath2020StatisticalRethinking, p. 65). Predicting from one parameter value instead means "you'd produce an overconfident distribution of predictions, narrower than the posterior predictive distribution" (mcelreath2020StatisticalRethinking, p. 66).

*Where the code stands.* The fill's interval is the Kalman smoother's variance at the fitted settings, a normal interval about the point fill (`plugin_interval`), clamped at 0 °C (`interval_floor`), and zero width on observed days (`observed_untouched`). None of the uncertainty in the three parameters or in the departure's settings enters it. The baseline's intervals are on the parameters only: a t interval (`t_interval`) at a 90 % interval (`interval_level`), with the regression's and the mean's standard errors the textbook ones (`regression_interval`, `cand_mean`), and the nearest-stations mean's from the donors' weighted spread (`donor_interval`). The run itself uses the predicted parameters as point values (`open_loop_run`).

*What it costs.* The fill's interval covered 89 to 94 % of held-out days at a nominal 95 %: narrower than stated, which is the direction Rethinking predicts for a plug-in interval. The baseline's parameter intervals held the station's own parameters 87 to 94 % of the time at a nominal 90 %, but the station's own parameters are themselves estimates, which that check treats as exact (`theta_coverage`). No interval reaches daily temperature or GSDD from either piece.

### Comparing candidates: held-out stations against PSIS-LOO and WAIC (Rethinking ch. 7, 13; BDA3 ch. 7)

*The principle.* The books score a model by how well it predicts data it was not fitted to, averaged over the posterior; BDA3 prefers WAIC to AIC and DIC because "WAIC has the desirable property of averaging over the posterior distribution rather than conditioning on a point estimate" (gelman_etal2013Bayesiandata, p. 174). Rethinking's PSIS approximates leave-one-out cross-validation because "this importance can be estimated without refitting the model" (mcelreath2020StatisticalRethinking, p. 217). Both lean on splitting the data into pieces, and BDA3 names where that is hard: "A cost of using WAIC is that it relies on a partition of the data into n pieces, which is not so easy to do in some structured-data settings such as time series, spatial, and network data" (gelman_etal2013Bayesiandata, p. 174). With clusters, the question also has to be chosen: "If we wish to validate a model against the specific clusters used to fit the model, that is one thing" (mcelreath2020StatisticalRethinking, p. 426); predicting a new cluster is another.

*Where the code stands.* The baseline asks the new-cluster question, about a station with no record, and answers it by refitting with whole stations held out: blocked by WSC sub-sub-drainage (`folds_blocked`, `pool_blocked`), and in the leak-free pool with every station upstream or downstream removed too (`pool_leakfree`, `related_pairs`). That is the strict, refit form of cross-validation, on exactly the network data BDA3 warns a simple partition handles badly. The fill's validation hides days within a station with its peers left in (`fill_holdout`), and its registered rule compares the fill with open-loop air2stream (`fill_rule`). Neither scores a log predictive density: the baseline's statistic is the mean over stations of each station's mean absolute GSDD error (`statistic_station`), over the station-years where every run has a GSDD (`statistic_paired`), and its rule reads that with thresholds of 10 °C-days and 50 °C-days set before any score (`rule_displace`, `rule_close`, `rule_tie`).

*What it costs.* A point error on GSDD says nothing about whether an interval is honest, so the statistic cannot reward a candidate whose intervals are right or penalise one whose are not; it was chosen because GSDD is the number the product would publish. The benchmark, a station's own parameters, is fitted on the season it is scored on, so it is in-sample by about 11 °C-days. Equal weight per station means a station with one complete season counts as much as one with ten.

### Recovery on simulated data (BDA3 §10.7)

*The principle.* Before trusting a fit on real data, run it on data made from values you chose: "one can perform more elaborate debugging using fake data" (gelman_etal2013Bayesiandata, p. 270). The values should come from the model's own population, the hyperparameters first and the unit-level parameters from them, and intervals should cover at their stated rate: "there should be a 50% probability that its 50% posterior interval contains the truth" (gelman_etal2013Bayesiandata, p. 270).

*Where the code stands.* Aligned in purpose. The recovery simulates the three parameters at the real stations from known trait effects, a part shared between flow-connected stations and noise (`sim_known_values`, `sim_network_part`), splits their variance as traits 50 %, network 25 %, noise 25 % (`sim_known_values`), runs every candidate in both pools 1,600 times and five times end to end (`sim_size`), and checks each candidate's 90 % interval against the simulated values (`sim_coverage`): 89.6 to 90.2 %. It adds a test the books do not have, that replacing a held-out station's network part alone changes no candidate's leak-free error, and shows that test failing on three pools known to leak (`leak_check`).

*What it costs.* It draws the three parameters independently (`sim_independent`), though at the real fits the intercept and slope are correlated at −0.49, so it tests the path, not the size, as its own header says. The end-to-end part gives each station's departure its observed spread rather than its fitted noise (`e2e_departure`), because the fitted noise at a persistence near 1 implies departures far larger than any observed. One fixed split of the variance is a single reasonable choice, which BDA3 allows for debugging; averaging over many would test more of the space.

### Measurement error, outliers and the ice floor (Rethinking ch. 7, 15; BDA3 ch. 8)

*The principle.* An input measured with error, treated as exact, biases what is fitted from it, in no fixed direction: "But you can't safely assume that measurement error makes estimates conservative" (mcelreath2020StatisticalRethinking, p. 494). Extreme values are better met by a likelihood with thicker tails than by cutting them: "A common and useful kind of robust regression is to replace the Gaussian model with a thicker-tailed distribution" (mcelreath2020StatisticalRethinking, p. 233). A value at a physical bound is censored, and BDA3's worked case gives the measured values their density and the bounded ones a probability: "the contributions to the likelihood from the 91 numerical measurements are normal densities" (gelman_etal2013Bayesiandata, p. 226). Which data were collected, and why, is part of the model when it bears on the answer; BDA3 calls this "ignorability, which is crucial in setting up models that correctly account for data collection" (gelman_etal2013Bayesiandata, p. 199).

*Where the code stands.* Air temperature is ERA5-Land at the station's point, taken as exact (`air_exact`), interpolated across gaps of up to three days (`air_gap`), and on a day at a fixed UTC−8 while the water's day follows the station's own offset, an hour apart in the Peace and parts of the Kootenays (`air_day_offset`). The observed daily mean carries a fixed error of 0.1 °C in the smoother (`obs_sd_fixed`), not one estimated. The departure's errors are Gaussian (`gaussian_error`), and a peer's error beyond four of its own noise is clipped (`peer_clip`) rather than down-weighted by a thicker tail. The ice floor holds air2stream's state at 0 °C (`ice_floor`): a physical bound inside the process, not a censored observation, and the same floor clamps the interval. On selection, a station is fitted only with a year of observed days (`min_days`); the truth seasons are those observed from 1 March to 30 November with no gap over two days (`truth_complete`), less a season whose daily means barely vary, under 0.1 degC (`truth_stuck`); and the kept stations snap to the FWA with at least 95 % of the basin inside BC and on the trait grids (`kept_stations`).

*What it costs.* None of the air's error is in any interval, and its effect on the fitted parameters is not measured. The results do not separate the hour's offset from anything else; the fill's whole-season GSDD losses are concentrated in the Peace among other places, which is consistent with it and does not show it. The selection makes the truth set year-round river gauges, so the baseline's scores describe stations like those, and small seasonal streams are not in it (`research/station_temperature_fill.md`, Limits).

### Carrying uncertainty to degree days

*The principle.* GSDD is a function of the whole daily series, so its uncertainty is the uncertainty of that function, not the sum of the daily bounds. With draws from a posterior, it is computed on each draw (Rethinking ch. 3, the propagation passage above).

*Where the code stands.* `wet_temp_gsdd()` takes the point series and sums it over the season gsdd defines, above 5 °C and stays there to below 4 °C on a 7-day mean between March and November (`gsdd_season`, inherited from gsdd 0.3.0.9007), from the daily mean (`gsdd_daily_mean`). It says outright that a fill's daily interval does not carry into GSDD (`gsdd_no_interval`). The validation's truth GSDD interpolates gaps of one or two days (`gsdd_year_interp`).

*What it costs.* Every GSDD in wet, filled or predicted, is a point value. For a whole missing season the fill's GSDD error was 130.4 °C-days against 128.7 °C-days for open-loop air2stream, so the fill is closer day by day without being closer on GSDD, and nothing in its output warns a reader of that.

## Choices

Each row is a choice the code makes, with the line that makes it (held there by the check: a row whose line moves fails until it is updated). Verdicts: **aligned** (what the books do), **differs** (a shortcut the books would not take), **differs by design** (a different question, chosen on purpose), **outside the books** (neither book teaches it).

| id | where | the choice | verdict |
|---|---|---|---|
| `each_station_alone` | `R/wet_temp_fill.R:274` | each station's three parameters fitted from its own record alone | differs |
| `open_loop_lsq` | `R/wet_temp_fill.R:382` | air2stream fitted by least squares on its open-loop error, with no prior | differs |
| `two_starts` | `R/wet_temp_fill.R:386` | two starting response rates, the better fit kept; no check of convergence | differs |
| `ice_floor` | `R/wet_temp_fill.R:369` | the model's state held at zero, for ice | differs by design |
| `air_exact` | `R/wet_temp_fill.R:262` | air temperature at the station's point taken as exact | differs |
| `air_gap` | `R/wet_temp_fill.R:207` | air interpolated linearly across gaps of up to three days | outside the books |
| `air_day_offset` | `R/wet_temp_fill.R:60` | air on a fixed UTC−8 day, an hour off at stations on UTC−7 | outside the books |
| `min_days` | `R/wet_temp_fill.R:268` | a station fitted only with a year of observed days with air | differs by design |
| `fill_range` | `R/wet_temp_fill.R:264` | which days are filled, while the fit uses every observed day | outside the books |
| `pool_by_hand` | `R/wet_temp_fill.R:240` | the stations sharing errors set by hand, the WSC sub-drainage | differs |
| `ar1_kalman` | `R/wet_temp_fill.R:430` | the departure an AR(1) process, filtered and smoothed | outside the books |
| `stationary_start` | `R/wet_temp_fill.R:425` | the smoother started from the AR(1)'s stationary spread | outside the books |
| `obs_sd_fixed` | `R/wet_temp_fill.R:440` | the observed daily mean's error fixed, not estimated | differs |
| `gaussian_error` | `R/wet_temp_fill.R:445` | Gaussian errors in the departure's likelihood, no thick tails | differs |
| `departure_ml` | `R/wet_temp_fill.R:411` | the departure's persistence, peer weight and noise by maximum likelihood | differs |
| `departure_caps` | `R/wet_temp_fill.R:420` | hard caps on persistence and noise in place of a prior | differs |
| `peers_first_fit` | `R/wet_temp_fill.R:276` | peers' errors from a first fit without peers, so none uses its own data | outside the books |
| `peer_clip` | `R/wet_temp_fill.R:281` | a peer's error clipped at four of its own noise | differs |
| `peer_mean` | `R/wet_temp_fill.R:301` | the peers' errors averaged with equal weight | differs |
| `peer_threshold` | `R/wet_temp_fill.R:303` | the peer weight fitted only past a fixed count of days, else none | differs |
| `plugin_interval` | `R/wet_temp_fill.R:321` | the fill's interval from the smoother at the fitted settings | differs |
| `interval_floor` | `R/wet_temp_fill.R:322` | the fill and its interval clamped at zero | differs |
| `observed_untouched` | `R/wet_temp_fill.R:338` | observed days returned as read, with an interval of zero width | differs |
| `gsdd_season` | `R/wet_temp_gsdd.R:79` | gsdd's season rule and window, inherited | outside the books |
| `gsdd_daily_mean` | `R/wet_temp_gsdd.R:53` | degree days from the daily mean, one series per station | outside the books |
| `gsdd_no_interval` | `R/wet_temp_gsdd.R:34` | no interval carried into GSDD | differs |
| `fill_holdout` | `scripts/temp_fill_validate.R:90` | the fill tested by hiding days of a station, its peers left in | aligned |
| `fill_rule` | `scripts/temp_fill_validate.R:218` | the fill's rule, registered before its first run | outside the books |
| `truth_complete` | `scripts/temp_fill_validate.R:84` | truth seasons observed throughout, no gap over two days | differs by design |
| `gsdd_year_interp` | `scripts/temp_fill_validate.R:103` | the truth's gaps of one or two days interpolated | outside the books |
| `truth_stuck` | `scripts/temp_baseline_traits.R:68` | a season whose readings barely vary dropped as a stuck sensor | differs by design |
| `kept_stations` | `scripts/temp_baseline_traits.R:46` | stations kept only when snapped and almost wholly inside BC and the grids | differs by design |
| `trait_set` | `scripts/temp_baseline_lib.R:29` | the eight catchment traits | outside the books |
| `theta_transform` | `scripts/temp_baseline_lib.R:95` | parameters predicted as equilibrium intercept, slope and logit rate | outside the books |
| `cand_mean` | `scripts/temp_baseline_lib.R:137` | the population mean, with its predictive spread for a new station | aligned |
| `cand_regression` | `scripts/temp_baseline_lib.R:148` | least squares per parameter, the three fitted separately | differs |
| `regression_interval` | `scripts/temp_baseline_lib.R:155` | the regression's prediction standard error, the stations' estimates taken as data | aligned |
| `cand_donor` | `scripts/temp_baseline_lib.R:164` | the mean of the nearest stations in trait space | outside the books |
| `donor_weights` | `R/wet_donor_mean.R:19` | inverse-distance weights over the donors | outside the books |
| `donor_k` | `scripts/temp_baseline_lib.R:110` | five donors | outside the books |
| `donor_interval` | `scripts/temp_baseline_lib.R:169` | the donors' weighted spread as the nearest-stations mean's error | outside the books |
| `zscore_training` | `scripts/temp_baseline_lib.R:162` | traits scaled on the training stations alone | aligned |
| `no_spread_dropped` | `scripts/temp_baseline_lib.R:140` | a trait with no spread in a training set left out of that fit | outside the books |
| `t_interval` | `scripts/temp_baseline_lib.R:175` | a t interval about each prediction | aligned |
| `interval_level` | `scripts/temp_baseline_lib.R:111` | the interval's width, ninety percent | outside the books |
| `folds_blocked` | `R/wet_cv_folds.R:37` | folds by WSC sub-sub-drainage | aligned |
| `pool_blocked` | `scripts/temp_baseline_lib.R:195` | a fold's stations held out together, every model refitted | aligned |
| `pool_leakfree` | `scripts/temp_baseline_lib.R:197` | each station held out with its upstream and downstream neighbours removed | aligned |
| `related_pairs` | `scripts/wb_cv_lib.R:227` | neighbours are the stations upstream or downstream on the FWA | aligned |
| `open_loop_run` | `scripts/temp_baseline.R:149` | the station run on point parameters, no departure and no interval | differs |
| `benchmark_own` | `scripts/temp_baseline.R:133` | the benchmark is a station's own parameters, fitted on the season scored | differs |
| `theta_coverage` | `scripts/temp_baseline.R:186` | interval coverage checked against the station's own fitted parameters | differs |
| `statistic_station` | `scripts/temp_baseline_lib.R:310` | the statistic: mean absolute GSDD error per station, stations weighted equally | differs by design |
| `statistic_paired` | `scripts/temp_baseline_lib.R:306` | only station-years where every run has a GSDD | outside the books |
| `rule_displace` | `scripts/temp_baseline_rule.R:9` | a trait candidate displaces the mean only by a margin, in both pools | outside the books |
| `rule_close` | `scripts/temp_baseline_rule.R:8` | close to the benchmark within a margin, in both pools | outside the books |
| `rule_tie` | `scripts/temp_baseline_rule.R:59` | a tie at one decimal goes to the regression | outside the books |
| `sim_known_values` | `scripts/temp_baseline_recover.R:64` | simulated parameters from chosen trait effects, network part and noise | aligned |
| `sim_network_part` | `scripts/temp_baseline_lib.R:255` | a part shared by flow-connected stations, weighted by area | aligned |
| `sim_independent` | `scripts/temp_baseline_lib.R:244` | the three parameters simulated independently | differs |
| `sim_coverage` | `scripts/temp_baseline_recover.R:115` | interval coverage checked against the simulated values | aligned |
| `sim_size` | `scripts/temp_baseline_recover.R:61` | how many simulated sets, and the seed | outside the books |
| `leak_check` | `scripts/temp_baseline_recover.R:116` | a leak test that swaps a held-out station's network part, and a bar for it | outside the books |
| `e2e_departure` | `scripts/temp_baseline_recover.R:166` | the end-to-end departure given its observed spread, not its fitted noise | differs by design |

## Out of scope, and why

- **`scripts/temp_fill_parity.R`**, which compares wet's GSDD with the Skeena network model's output: a comparison with another model, not a choice of this one.
- **`wet_temp_daily()`'s day rule** (hours per day, the bounds on a reading): the definition of the input, read in `research/station_water_temperature.md`.
- **The trait grids and the province run's upstream means**, which the water balance built and `research/water_balance_method.md` reads.

## What a network model could remove, in order of what it costs

These are the departures above that a fuller model of stream temperature on the network is placed to remove, the largest first. Each says which of the baseline's numbers it moves. #217's file (`research/temperature_network_model.md`) is where what we are hoping for from such a model is written down.

1. **No uncertainty reaches daily temperature or GSDD** (`gsdd_no_interval`, `open_loop_run`, `plugin_interval`). Every GSDD the baseline or the fill gives is a point value, and the only intervals stop at the parameters. Draws from a posterior, run through the season rule one by one, would give each reach's GSDD an interval, which is what lets a reader tell whether a reach sits on one side of a threshold.
2. **Stations do not share information, along the network or otherwise** (`each_station_alone`, `cand_regression`, `cand_donor`). The regression, which the baseline's rule chose, misses by 298.0 °C-days where a station's own parameters miss by 97.5 °C-days, and neighbours are worth 4.1 °C-days to the regression when let in. Partial pooling across stations, and a covariance that falls off along the stream, are how the books would use them.
3. **The parameters are fitted with no prior** (`open_loop_lsq`, `departure_ml`, `departure_caps`). The intercept-over-rate ratio is fragile where the rate is poorly identified, and hard caps stand in for a prior. A prior regularises the fit where the record is short.
4. **Correlated parameters are treated as unrelated** (`cand_regression`, `sim_independent`). The intercept and slope are correlated at −0.49, which the regression ignores and the recovery leaves out.
5. **Intervals are plug-in** (`plugin_interval`, `theta_coverage`). The fill's interval covered 89 to 94 % at a nominal 95 %; parameter uncertainty would widen it.
6. **Air temperature and the observations are exact** (`air_exact`, `obs_sd_fixed`, `observed_untouched`). Their errors are in no interval, and their effect on the fit is not measured.

What a fuller model would keep: the held-out design (`pool_blocked`, `pool_leakfree`, `related_pairs`), recovery on simulated data first (`sim_known_values`, `sim_coverage`, `leak_check`), and a rule written before the first score. The baseline's scores on the same frame are the yardstick (`data/temp_baseline/scores_edfbc29809.rds`, `research/station_temperature_fill.md`).
