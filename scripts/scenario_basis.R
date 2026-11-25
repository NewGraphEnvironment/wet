# What wet's scenarios can be built on (#169, #4): the two checks move 6 (#168,
# research/pcic_channel_scale.md) left open, each under a rule registered below
# before any value it scores was read.
#
#   WET_FWAPG_COMMIT=<sha> WET_DATA_ROOT=<data dir> Rscript scripts/scenario_basis.R
#
# Rule 4 reads hydromosaic's listing of each outlet's series (no flow value) and
# says what each CMIP6 run lacks against the crosswalk fwapg stores. Rule 5 scores
# PCIC's six RCP 4.5 CMIP5 gridded runs against PNWNAmet in the Fraser, accumulated
# as the channel-scale pilot accumulated PNWNAmet.
#
# PCIC's robots.txt disallows /data/ and /hydromosaic, and the owner chose to ask
# PCIC first (#169 decision 1, 2026-11-25). So no request is made unless
# WET_SCENARIO_FETCH=1: without it every gridded read goes to an address that
# refuses (option wet.pcic_base), and the checks that need a request report
# "not run". Every request made is logged to
# <data root>/logs/169/scenario_basis_fetch.tsv, which the report reads.
#
# Report: data/checks/scenario_basis_<release>.txt (tracked). Findings:
# research/pcic_scenarios.md. Connection from WET_PG*.
#
# ---- rules registered before any flow value was read (#169) ------------------------------------
# Rule 4, each CMIP6 run against the stored crosswalk. Known before
# registration, from fwapg's own notes: 3 of PNWNAmet's 28 outlets with no
# series also lacked one for CNRM-ESM2-1 when it was last fetched, so that run
# has series where PNWNAmet has none, and fwapg's job, which refuses a run
# whose crosswalk differs from the stored one, would refuse it. The rule
# therefore measures what each run lacks, not whether the job runs unchanged.
# Population: every outlet of pcic.fwa_crosswalk. The reference set S is the
# outlets the stored crosswalk treats as having a series (flag is not
# no_series). An outlet's row for a run (a model and scenario) is its listing's
# streamflow row for that model and scenario; two such rows at one outlet stop
# the script. A row passes the day test when num_times equals the days from
# start_time to end_time, both ends counted, it starts on or before 1951-01-01
# and it ends on or after 2012-12-31 (PNWNAmet, historical) or 2099-12-31 (a
# GCM under "historical, ssp245" or "historical, ssp585"). An outlet has a
# series for the run when its row passes; an outlet whose row fails is counted
# apart ("listed, fails the day test") and has none. No flow value is read.
# Reported first, deciding nothing: the outlets where PNWNAmet's listing and S
# disagree (hydromosaic may have changed since the build). Then, per run of the
# 9 GCMs x 2 scenarios: A, the outlets of S with no series for the run, and B,
# the outlets outside S with one, each counted over the network, by PCIC
# domain (the pilot's domain_of()) and by crosswalk flag. Verdict per run,
# typed in this order: "runs as the job stands" (A and B empty); "runs on the
# stored crosswalk" (A empty, B not: the job need only keep the stored
# crosswalk and leave B's series out); "lacks series the crosswalk places" (A
# holds an outlet whose flag is NULL), with A's placed outlets by domain and
# whether the run's outlets with no series pass 100, where the job stops;
# otherwise "lacks series at unplaced outlets only". A run is "whole in a
# domain" when A holds none of that domain's outlets. A listing is a proxy for
# what a bulk request returns, which is what fwapg's job reads, so the pilot's
# cache is set against it: every outlet in a kept NetCDF of a model and
# scenario must have a series by its listing, and every single-outlet missing
# marker (batch_name() of the one outlet) must have none; the outlets where
# they disagree are listed and that run's verdict gains "listing and bulk
# disagree at n outlets". Nothing here chooses a GCM.
#
# Rule 5, CMIP5 gridded in the Fraser. Population: the pilot's scored gauges
# with an outlet whose domain is the Fraser (73 in the pilot's report), with
# their segments and observed annual flow as the pilot takes them (q_obs: the
# bundle's month-0 obs_mm over area_km2 at 365.25 days). Depth at a gauge, for
# PNWNAmet (TPS_gridded_obs_init) and for each CMIP5 run: RUNOFF + BASEFLOW,
# each month the mean over 1981-2010 of the month's total per cell
# (wet_pcic_monthly(), on the pilot's bbox for the Fraser), accumulated as the
# pilot's "wet's accumulation" was: the polygons of wet_ws_fetch(conn, "100"),
# centroid sampling, and for each month wet_upstream_mean(ws, <the month>,
# "total", irregular_pairs = wet_upstream_irregular(conn, "100")), read at the
# watershed of the gauge's segment. That gives twelve depths in mm. The annual
# flow is wet_mm_to_m3s(their sum, the accumulated area) at its default 365
# days; the monthly shares are the twelve depths over their sum. Parity before
# any CMIP5 file is asked for: PNWNAmet's annual flow at the pilot's sites
# salmon, quesnel, hope and lillooet (segments from
# scripts/channel_scale_sites.csv) equals the "wet acc" column of the pilot's
# tracked report at its two decimals. The rule is the pilot's rule 2 with the
# six RCP 4.5 runs in place of the nine "historical, ssp245" series, all six
# required at every gauge: |median over the 6 GCMs of annual flow -
# PNWNAmet's| / q_obs <= 0.05, and the share NSE (wet:::wet_nse() against the
# gauge's observed shares, the bundle's twelve obs_mm over their sum) of the
# 6-GCM median month (the median of the six depths month by month, then
# shares) no more than 0.05 below PNWNAmet's. The Fraser passes when the
# median over its gauges of each statistic meets it. RCP 8.5: each GCM's
# RCP 8.5 file is set against its RCP 4.5 file for 1981, 1993 and 2005 (the
# CMIP5 historical experiment ends in 2005), day by day and cell by cell, per
# variable, and the largest absolute difference reported; 2008, where the
# scenarios differ by construction, is compared the same way and only
# reported. Where a difference in 1981, 1993 or 2005 exceeds the larger
# scale_factor of the two files, the rule is scored on the six RCP 8.5 runs
# too, and the Fraser passes only if both sets do. Verdict: pass, "the Fraser
# builds on CMIP5 gridded"; fail, "DECISION TO USER: neither generation meets
# rule 2 in the Fraser", with the pilot's CMIP6 statistics for the Fraser
# beside these. Reported, deciding nothing: each GCM's own statistics; the
# rule with the gauges left out whose watershed is more than 5 % glacier (the
# CMIP5 runs carry no glacier model and PNWNAmet's does); the signed annual
# difference.
# ---- end of registered rules --------------------------------------------------------------------
