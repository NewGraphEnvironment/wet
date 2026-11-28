# Draft issue (proposed to the owner, not filed)

**Title:** Catchment traits and a prediction point for every stream segment

**If we do it:** a model fitted at stations can be run at every reach, because the traits it reads and the point it predicts at exist there. **If we never do:** a prediction away from the stations has nothing to read, and each attempt computes the traits its own way.

## Problem

The whole-station baseline (#213) computes eight catchment traits upstream of each temperature station: upstream means of elevation, easting, northing, the date half the snow has melted and peak snow water equivalent; log upstream area; and glacier cover and lake and reservoir cover as shares of upstream area (`scripts/temp_baseline_traits.R`). Any model that predicts from traits, the baseline's regression or a network model with traits as fixed effects, needs the same eight at every segment it predicts. And a network model fitted with SSN2 predicts at prediction sites, one per segment. Neither exists per segment, and no issue builds them (`research/temperature_network_model.md`, "What we can bring").

## Proposed approach

- **One row per segment of the main-flow tree,** keyed on `linear_feature_id`: the eight traits, computed upstream of the segment's downstream end by the station recipe (the province run's upstream means for the five averaged traits, accumulated area, the glacier and lake queries), and the point a prediction is made at, with its rule stated (the segment's downstream end or its midpoint; #216 uses the midpoint for air).
- **The same recipe as at the stations, shown to be:** at every station of the holdout frame, the segment's traits equal the frame's.
- **Coverage stated:** segments whose basin runs outside BC or off the trait grids are listed with their share, as the frame lists its dropped stations, not dropped silently.
- **Published as wet's per-segment products are:** parquet parts under a manifest; the dataset ID is set in this issue's plan.

## Out of scope

- New traits, or a choice among them: the eight are the baseline's.
- Prediction itself.

## Done when

- Every segment of the main-flow tree has a row, or is listed with the reason it has none, with counts.
- At every station of the holdout frame the traits match the frame's, in a check report under `data/checks/`.
- The published parts load by segment id for any watershed group.

Relates to #217, #213, #223, #214
