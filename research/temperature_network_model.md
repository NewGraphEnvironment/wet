# A stream temperature network model: what we can bring, what we are hoping for, and how it is tested

**Verified:** 2026-11-27 · **Issues:** #217 (this file), from the roadmap #214; it rests on the whole-station baseline (#213) and on the baseline read against Bayesian practice (#218) · **Produced by:** the code at this commit and the issues named in the table, read for where each input stands; how SSN2 and SSNbler hold more than one network, read from their documentation (SSN2 0.4.0, SSNbler 1.1.2.9000) · **Status:** written; its open points are listed under the questions, and nothing in it is a commitment to a method, a format or a date.

## What it is for

Growing-season degree days for every stream reach in BC, with their uncertainty, so that a reach can be placed on one side or the other of the degree-day thresholds that matter for fish. A reach is a Freshwater Atlas stream segment, one `linear_feature_id`. Temperature is measured at a few hundred stations, and every reach between them needs a model on the stream network. The roadmap (#214) says where the work stands and what comes next; this file says what such a model could start from, what would make its results usable, and how it would be tested. The method itself is open.

## What we can bring

Each input as a file, with its columns. *In place* means it is built and named here by the function or file that holds it; most of these files are on our machines and not yet published, so formats are open. *Being built* names the issue that builds it. *Not yet anyone's work* names an input no issue builds.

| input | the file and its columns | where it stands |
|---|---|---|
| The network as tables | the main-flow tree, a stream network with no splits computed from the Freshwater Atlas for the province: `linear_feature_id`, `watershed_group_code`, `blue_line_key`, `source`, `upstream_area_ha` (`whse_basemapping.fwa_stream_networks_mainflow_tree`) | in place for the province, computed from [`fwapg`](https://github.com/smnorris/fwapg) (Simon Norris) on the [`newgraph` branch of a fork](https://github.com/NewGraphEnvironment/fwapg/tree/newgraph/extras/mainflow_tree); being checked on every watershed group (NewGraphEnvironment/fwapg#19) |
| The network as an SSN object per region | an SSNbler build of that tree: edges with their additive function values, observation sites and prediction sites; the SSNbler build that made it named beside it | being built (#223) |
| Stations placed on the network | `wet_station_snap()`: `station_number`, `linear_feature_id`, `watershed_feature_id`, `wscode`, `localcode`, `distance_m`, `upstream_area_km2`, `area_ratio`, `accepted`, `reason`, `lake` | in place for the stations; as observation sites in an SSN object, being built (#223) |
| One prediction site per segment | a point on every segment of the main-flow tree, with its segment id | not yet anyone's work |
| Daily observations at stations | `wet_temp_daily()`: `station_number`, `date`, `t_mean_c`, `t_min_c`, `t_max_c`, `n_hours`, `source`, `status` | in place for the hydrometric stations; small-stream logger records being built (#215) |
| Filled series and the fits behind them | `wet_temp_fill()`: the daily columns plus `filled`, `t_lo_c`, `t_hi_c`, and per station `a1`, `a2`, `a3`, `rmse_open`, `rho`, `b`, `sigma`, `n_obs`, `loglik` | in place; a screen for readings beside a gap (#222) and reads that repeat exactly (#224) being built |
| Catchment traits per station | the holdout frame's stations: upstream means of elevation, easting, northing, the date half the snow has melted and peak snow water equivalent; log upstream area; glacier cover and lake and reservoir cover (`scripts/temp_baseline_traits.R`) | in place |
| Catchment traits per segment | the same traits for every segment | not yet anyone's work |
| Daily air temperature per station | `cd::cd_extract_daily()`: `id`, `date`, `variable`, `value` (ERA5-Land) | in place |
| Daily air temperature per segment | a lookup from every segment to its ERA5-Land cell, and each cell's daily series | being built (#216) |
| The holdout frame | stations with their folds, nesting and neighbours removed in the leak-free pool; truth station-years; dropped stations with reasons; each station's own fit (`tb_frame_read()`) | in place |
| The baseline's scores | per station, year and candidate: daily error and bias, the predicted and observed GSDD; the statistic and the rule's verdict (`data/temp_baseline/scores_<frame>.rds`) | in place |

The network stands on `fwapg`, Simon Norris's Freshwater Atlas in PostGIS, and on its upstream and downstream functions. SSN objects come from SSNbler and are fitted with SSN2. The numbers each in-place input gives are in `research/station_temperature_fill.md` and the tracked reports it names.

## What we are hoping for

What the habitat work needs in the end:

- **Temperature at every segment, week by week, with intervals.**
- **Degree days per segment and year, with the uncertainty carried through** from the model to the sum, not added up from weekly bounds.
- **What lets us lean on the results:** convergence diagnostics; posterior predictive checks against the stations; and recovery on data simulated from known values before any real score, as the baseline's recovery run does.

`research/temperature_bayesian_alignment.md` ends with the baseline's departures from Bayesian practice that a network model could remove, largest first: no uncertainty reaching degree days, stations that share no information, no priors, correlated parameters treated as unrelated, plug-in intervals, and air temperature and observations taken as exact.

## Where results would live

Beside wet's other per-segment products, read by segment id, so that anything that reads a `linear_feature_id` can read them. The published discharge (`research/discharge_publish.md`) shows the shape: parquet parts under a manifest, one dataset ID naming the location, the schema and the table. No dataset ID is coined here.

## How it is tested

On the baseline's holdout, so the numbers sit beside each other:

- **The same stations, held out whole,** with the same folds (WSC sub-sub-drainage) and the same two pools: blocked cross-validation, and the leak-free pool that also removes each held-out station's upstream and downstream neighbours. The difference between the two pools is what neighbours on the same stream are worth.
- **The same statistic:** the mean over held-out stations of each station's mean absolute error in growing-season degree days, beside daily error.
- **A rule for what counts as better, written down before the first score,** as the baseline's was. The baseline's own rule already says a later candidate is scored in both pools and reported beside it.
- **Recovery first,** on data simulated from known values with a part shared along the network, including the check that the leak-free pool removes what it claims to.

Kriging the baseline's three parameters on the network (#223) is the first such test and shows the shape for any other.

## Questions to work through

From the roadmap:

- How a station with a short record, or a reach with none, borrows from the others.
- What reaches on the same stream say about each other from week to week.
- How short logger records count beside long gauge records.
- What to do where air temperature does not explain the water: groundwater-fed reaches, lake outlets, glacier melt, regulated flow.
- How uncertainty reaches degree days.

And:

- **Whether the network's gain shows with few stations on one stream.** The whole-station holdout measures what neighbours are worth where they exist; most reaches are small streams with no station on them.
- **Prediction under a changed climate,** which a holdout on the observed record does not test.
- **How a model that predicts temperature directly, not through air2stream's three parameters, is compared on the holdout.** A station's own fitted parameters set a floor only for predictions of those parameters.
- **Which error measure and which time step** any model is compared on.
- **Formats:** whether results are keyed on `linear_feature_id` and the first day of the week (with the rule for a week stated), and whether they come as draws or as quantiles.
- **The size of region fitted at once.**
- **A region with more than one outlet.** The province's network has drainages with outlets of their own (dead ends, and outlets with no parent inside BC). Two ways to hold them, both of which SSN2 supports: each outlet's tree as its own network inside one SSN object, fitted together, where network covariance between two networks is zero and a random effect or a partition on the network id can carry what they share; or one region per outlet, each fitted alone. Which suits a basin is settled when the first SSN objects are built (#223).
