## Checklist read
code-check.md Mechanisms (guard that fails toward pass, guard scope/escape hatches, one fact derived twice); code-check-r.md sections on DBI driver values, match(), data.frame/rbind, paste/zero-length; code-check-shell.md git pathspec excludes. Read the changed files and the callers (pcic_routed_lib.R routed_annual, segment_vignette_data.R, monthly_vignette_data.R, wet_flow_window).

## Clean
- pick is as.logical(match()) on a grid; missing rows give NA; empty-ids and empty-source frames carry logical(). The fwapg path rbinds before adding pick, so no type clash.
- publish_own: both guards use `:(exclude)` long form; the daily script stays out of the shared list in the BUILD monthly check. The added entries are not sourced or called by segment_output.R, wb_output.R, segment_daily_output.R, pcic_routed_lib.R (grep: wet_pcic_years only reached via routed_years_dir, which those table scripts do not call).
- Consumers (routed_annual, wet_flow_window, vignette data scripts) select by name, so the extra column breaks nothing.
