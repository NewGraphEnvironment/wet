# Findings — segment_vignette_data.R refuses after a rerun that leaves every published part identical (#93)

## Issue context

**If done:** `data-raw/segment_vignette_data.R` runs after a rescore or a `segment_output.R` rerun that leaves every published part byte-identical, without a republish. **If never done:** it refuses after every such rerun until the next publish that changes values, as it has since #81 (and again after #91).

## What happens

`data-raw/segment_vignette_data.R:170` requires the tracked segment report to begin `wet commit <segment_commit>;`, where `segment_commit` is the one the live manifest names. The live manifest names 1718a3d (build acb820f). The tracked report has named f854c21 since #81 and e280f5d since #91. Each rerun of `segment_output.R` writes the current HEAD into the report, so the check fails even when the rerun's parts are byte-identical to the live ones, which `discharge_publish.R` BUILD confirms ("parts identical to the published build acb820f: 67 of 67").

`scripts/vignette_data_lib.R` `vd_published()` checks only the publish report's identical-parts line, so `monthly_vignette_data.R` passes the same state.

## Options

1. Accept a segment report whose build fed a passing publish report with every part identical to the live build (the publish report names its segment commit), instead of requiring the live manifest's commit.
2. Leave it, and republish identical parts after each such rerun (#77's pattern: BUILD, `WET_PUBLISH=1`, BUILD again). #91 declined this.

Related: #81, #91, #64.

## Errors Encountered

| Error | Resolution |
|-------|------------|
