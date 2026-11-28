# The files under R/ and scripts/ that no segment table is built from (#171), the one list the two
# code guards exclude: scripts/discharge_publish.R (the BUILD's monthly and daily checks) and
# scripts/segment_daily_output.R (its check that the monthly table is current). Sourced by both.
#
# Each guard compares every file under R/ and scripts/ with the commit its table was built at, rather
# than a list of what the tables depend on: a list misses a dependency and passes, while a file left
# off these exclusions only forces a rebuild. So an entry here is a claim that no table reads the
# file, and a file gains one only after checking what scripts/segment_output.R, scripts/wb_output.R
# and scripts/segment_daily_output.R source or call.
#
# What the daily script alone changes is kept out: scripts/segment_daily_output.R must still show as
# changed to the BUILD's daily check (it is added in the daily script's own `own`, not here).
publish_own <- c(
  # the publish side: it reads the product and the tables, and writes no table
  "R/wet_catalog.R", "R/wet_db_load.R", "R/wet_values_compare.R",
  "scripts/discharge_publish.R", "scripts/discharge_publish_lib.R", "scripts/discharge_publish_own.R",
  "scripts/vignette_data_lib.R", "scripts/segment_group.R",
  # the readers of the published product (#164, #177). R/wet_segment_monthly.R also holds
  # wet_segment_sources(), the run and table scripts/pcic_routed_lib.R reads; the routed-line check
  # in both scripts (the report's `routed:` line against the run named) covers part of that
  "R/wet_segment_daily.R", "R/wet_segment_monthly.R",
  # the chinook-site and departure work, which reads the product and the fit and feeds no table:
  # none is sourced by segment_output.R, wb_output.R or segment_daily_output.R, and none of its
  # functions is called by them (checked against the code at the commit the segment report names)
  "R/wet_departure_carry.R", "R/wet_pcic_years.R",
  "scripts/departure_pcic.R", "scripts/departure_site.R", "scripts/departure_site_lib.R",
  "scripts/departure_site_snow.R", "scripts/gauge_monthly_compare.R", "scripts/vignette_map_lib.R",
  # the channel-scale pilot (#168) and its site table: a script of its own, called by none
  "scripts/channel_scale_pilot.R", "scripts/channel_scale_sites.csv",
  # PCIC's gridded readers and what scenarios and coverage build on (#169): R/wet_pcic_fetch.R is
  # called by the MAD and term scripts, not by the three table scripts or what they source
  "R/wet_pcic_fetch.R", "R/wet_pcic_monthly.R", "R/wet_runoff_monthly.R",
  "scripts/scenario_basis.R", "scripts/scenario_basis_lib.R", "scripts/pcic_coverage.R",
  "scripts/pcic_coverage_map.R",
  # the air temperature tree (#216): its reader and its build, which read the Freshwater Atlas
  # and cd's cube and no discharge table; none is sourced or called by the three table scripts
  "R/wet_air_daily.R", "scripts/air_publish.R", "scripts/air_publish_lib.R", "scripts/air_station_check.R"
)
