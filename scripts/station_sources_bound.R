# The plausibility bound for the province's non-integrated discharge (#142, #179)
#
# Usage: WET_HYDAT_RELEASE=20260717 Rscript scripts/station_sources_bound.R
#
# Measures the bound registered in research/station_sources.md ("The
# plausibility bound for the provincial files") before it was measured:
# - population: every BC station in HYDAT 20260717 with at least 3,650 daily
#   flows in DLY_FLOWS, regulated or not;
# - per station, its largest daily flow over the median of its positive daily
#   flows; the bound is the largest such ratio;
# - the natural stations alone (no STN_REGULATION row with REGULATED = 1)
#   reported beside it, deciding nothing.
# Then applies it to the pinned provincial snapshot (wet_bcenv_daily() with no
# bound) and checks the registered expected catches: every day above
# 1,000 m^3/s at 08HA0036 and 08HD0003 dropped, no day of 08MD0002 or 08MD0003
# dropped. A failed catch is reported and the script exits 1: no bound ships.
# Once the bound ships as wet_bcenv_bound, a rerun also holds that constant to
# the measured value.
#
# Report: data/checks/station_sources_bound_20260717.txt (no timestamp; a rerun
# on the same HYDAT and snapshot reproduces it byte for byte).

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()

release <- wb_release()
if (release != "20260717") stop("the bound is registered on HYDAT 20260717, not ", release, call. = FALSE)
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) stop("run with Rscript, so the script's own md5 can be recorded", call. = FALSE)
code_md5 <- unname(tools::md5sum(self))
hydat <- wb_hydat(release)
report <- file.path("data", "checks", sprintf("station_sources_bound_%s.txt", release))
min_days <- 3650

# ---- HYDAT: the population and each station's ratio -------------------------------------------
con <- wet_hydat_connect(hydat)
st <- DBI::dbGetQuery(con, "
  SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name,
         EXISTS (SELECT 1 FROM STN_REGULATION r WHERE r.STATION_NUMBER = s.STATION_NUMBER AND r.REGULATED = 1) regulated
  FROM STATIONS s WHERE s.PROV_TERR_STATE_LOC = 'BC' ORDER BY s.STATION_NUMBER")
DBI::dbDisconnect(con)
st$regulated <- as.logical(st$regulated)
ratio <- lapply(st$station_number, function(s) {
  d <- wet_hydat_daily(hydat, s)
  pos <- d$q_m3s[d$q_m3s > 0]
  if (nrow(d) < min_days || !length(pos)) return(NULL)
  i <- which.max(d$q_m3s)
  data.frame(station_number = s, days = nrow(d), median_pos = stats::median(pos), max = d$q_m3s[i],
             max_date = d$date[i], ratio = d$q_m3s[i] / stats::median(pos))
})
ratio <- do.call(rbind, ratio)
ratio <- merge(ratio, st, by = "station_number")
ratio <- ratio[order(-ratio$ratio, ratio$station_number, method = "radix"), ]
bound <- round(max(ratio$ratio), 2)
nat <- ratio[!ratio$regulated, ]
bound_nat <- round(max(nat$ratio), 2)

# ---- the provincial snapshot under that bound -------------------------------------------------
pv <- wet_bcenv_daily(NULL, bound = Inf)
pos <- pv$q_m3s > 0
med <- vapply(split(pv$q_m3s[pos], factor(pv$station_number[pos], unique(pv$station_number))), stats::median, 0)
pv$cap <- bound * unname(med[pv$station_number])
pv$dropped <- !is.na(pv$cap) & pv$q_m3s > pv$cap
neg <- wet_bcenv_days_read(wet_bcenv_days(wet_bcenv_snapshot, tools::R_user_dir("wet", "cache")), NULL)
neg <- neg[neg$hours >= 20 & neg$q_m3s < 0, ]
catch <- data.frame(
  check = c("08HA0036: every day above 1,000 m3/s dropped", "08HD0003: every day above 1,000 m3/s dropped",
            "08MD0002: no day dropped", "08MD0003: no day dropped"),
  pass = c(all(pv$dropped[pv$station_number == "08HA0036" & pv$q_m3s > 1000]) &&
             any(pv$station_number == "08HA0036" & pv$q_m3s > 1000),
           all(pv$dropped[pv$station_number == "08HD0003" & pv$q_m3s > 1000]) &&
             any(pv$station_number == "08HD0003" & pv$q_m3s > 1000),
           any(pv$station_number == "08MD0002") && !any(pv$dropped[pv$station_number == "08MD0002"]),
           any(pv$station_number == "08MD0003") && !any(pv$dropped[pv$station_number == "08MD0003"])))

# ---- report -----------------------------------------------------------------------------------
out <- c(
  "The plausibility bound for the province's non-integrated discharge (#142, #179)",
  sprintf("HYDAT release %s; code_md5 %s", release, code_md5),
  sprintf("Provincial snapshot %s, reader v%d (wet_bcenv_daily(), complete days of >= 20 hours, local standard time)",
          wet_bcenv_snapshot, wet_bcenv_reader),
  "Rule registered before measuring: research/station_sources.md, \"The plausibility bound for the provincial files\".",
  "",
  sprintf("Population: %d BC stations in HYDAT, %d with >= %d daily flows and a positive flow (%d natural: no REGULATED = 1 row).",
          nrow(st), nrow(ratio), min_days, nrow(nat)),
  sprintf("Bound (largest ratio of a station's largest daily flow to the median of its positive daily flows): %.2f", bound),
  sprintf("Natural stations alone (reported, deciding nothing): %.2f", bound_nat),
  "",
  "The ten largest ratios:",
  sprintf("  %s  %-45s %s  days %5d  median %9.3f  max %9.1f on %s  ratio %8.2f",
          ratio$station_number[1:10], substr(ratio$station_name[1:10], 1, 45),
          ifelse(ratio$regulated[1:10], "regulated", "natural  "), ratio$days[1:10], ratio$median_pos[1:10],
          ratio$max[1:10], format(ratio$max_date[1:10]), ratio$ratio[1:10]),
  "",
  "Expected catches (registered):",
  sprintf("  %s  %s", ifelse(catch$pass, "PASS", "FAIL"), catch$check),
  "",
  sprintf("Applied to the snapshot: %d complete days at %d stations; %d days at %d stations above the bound, dropped;",
          nrow(pv), length(unique(pv$station_number)), sum(pv$dropped),
          length(unique(pv$station_number[pv$dropped]))),
  sprintf("  %d negative complete days at %d stations, dropped.", nrow(neg), length(unique(neg$station_number))),
  "",
  "Stations with days above the bound: station, days dropped, median of positive days (m3/s), cap, largest day dropped, years",
  vapply(split(pv[pv$dropped, ], pv$station_number[pv$dropped]), function(x) {
    sprintf("  %s  %5d  %9.3f  %10.1f  %12.1f  %s-%s", x$station_number[1], nrow(x), med[[x$station_number[1]]],
            x$cap[1], max(x$q_m3s), format(min(x$date), "%Y"), format(max(x$date), "%Y"))
  }, "")
)
writeLines(out, report)
message("wrote ", report)
if (!all(catch$pass)) {
  message("an expected catch failed: the bound does not ship; the choice goes back to the owner")
  quit(status = 1)
}
if (is.finite(wet_bcenv_bound) && !isTRUE(all.equal(wet_bcenv_bound, bound, tolerance = 0))) {
  stop("wet_bcenv_bound is ", wet_bcenv_bound, ", the measured bound ", bound, call. = FALSE)
}
