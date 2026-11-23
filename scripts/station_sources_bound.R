# The plausibility bound for the province's non-integrated discharge (#142, #179)
#
# Usage: WET_HYDAT_RELEASE=20260717 Rscript scripts/station_sources_bound.R
#
# Measures the bound registered in research/station_sources.md ("The
# plausibility bound for the provincial files"). The first registered form, one
# province-wide bound, failed an expected catch (the report's first run,
# 2026-11-22); the owner chose the re-registered form, per WSC sub-drainage:
# - population: every BC station in HYDAT 20260717 with at least 3,650 daily
#   flows in DLY_FLOWS, regulated or not, grouped by the first three characters
#   of its number;
# - per station, its largest daily flow over the median of its positive daily
#   flows; a sub-drainage's bound is the largest such ratio among its stations,
#   and one with fewer than 10 stations takes the province-wide largest
#   (".default");
# - natural stations alone (no STN_REGULATION row with REGULATED = 1) reported
#   beside each, deciding nothing.
# Then applies it to the pinned provincial snapshot (wet_bcenv_daily() with no
# bound) and checks the registered expected catches: every day above
# 1,000 m^3/s at 08HA0036 and 08HD0003 dropped, no day of 08MD0002 or 08MD0003
# dropped. A failed catch is reported and the script exits 1: no bound ships.
# Once the bound ships as wet_bcenv_bound, a rerun also holds that constant to
# the measured values.
#
# Report: data/checks/station_sources_bound_20260717.txt (no timestamp; a rerun
# on the same HYDAT and snapshot reproduces it byte for byte).

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()

release <- wb_release()
if (release != "20260717") stop("the bound is registered on HYDAT 20260717, not ", release, call. = FALSE)
self <- gsub("~+~", " ", sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)), fixed = TRUE)
if (length(self) != 1 || sys.nframe() != 0) {
  stop("run with Rscript, so the script's own md5 can be recorded", call. = FALSE)
}
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
nat <- ratio[!ratio$regulated, ]
ratio$sub <- substr(ratio$station_number, 1, 3)
min_sub <- 10
subs <- do.call(rbind, lapply(split(ratio, ratio$sub), function(x) {
  n <- x[!x$regulated, ]
  i <- which.max(x$ratio)
  data.frame(sub = x$sub[1], n = nrow(x), max = round(max(x$ratio), 2), by = x$station_number[i],
             n_nat = nrow(n), max_nat = if (nrow(n)) round(max(n$ratio), 2) else NA_real_)
}))
default <- round(max(ratio$ratio), 2)
bound <- c(.default = default, stats::setNames(subs$max[subs$n >= min_sub], subs$sub[subs$n >= min_sub]))
bound_nat <- round(max(nat$ratio), 2)

# ---- the provincial snapshot under that bound -------------------------------------------------
pv <- wet_bcenv_daily(NULL, bound = Inf)
pos <- pv$q_m3s > 0
med <- vapply(split(pv$q_m3s[pos], factor(pv$station_number[pos], unique(pv$station_number))), stats::median, 0)
pv$cap <- wet_bcenv_ratio(pv$station_number, bound) * unname(med[pv$station_number])
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
  paste0("Rule: research/station_sources.md, \"The plausibility bound for the provincial files\": one province-wide ",
         paste0("bound, registered before measuring, failed a catch; this form, per",
                  " sub-drainage, was re-registered before it was applied.")),
  "",
  sprintf(paste0("Population: %d BC stations in HYDAT, %d with >= %d daily flows and a",
           " positive flow (%d natural: no REGULATED = 1 row)."),
          nrow(st), nrow(ratio), min_days, nrow(nat)),
  "Ratio: a station's largest daily flow over the median of its positive daily flows.",
  sprintf(paste0("Province-wide largest ratio (.default, for a sub-drainage with",
           " fewer than %d stations): %.2f; natural alone %.2f"),
          min_sub, default, bound_nat),
  "",
  paste0("Per sub-drainage: stations, largest ratio and the station that sets it,",
           " natural stations and their largest (reported only), bound taken"),
  sprintf("  %s  n %3d  max %8.2f (%s)  natural n %3d  max %8s  -> %s", subs$sub, subs$n, subs$max, subs$by, subs$n_nat,
          ifelse(is.na(subs$max_nat), "-", sprintf("%.2f", subs$max_nat)),
          ifelse(subs$n >= min_sub, sprintf("%.2f", subs$max), sprintf(".default %.2f", default))),
  "",
  paste0("As R (wet_bcenv_bound): ", paste(deparse(bound, width.cutoff = 500L), collapse = "")),
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
  paste0("Stations with days above the bound: station, days dropped, median of",
           " positive days (m3/s), cap, largest day dropped, years"),
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
# the constant must be the report's printed line, and that line the measurement
printed <- eval(parse(text = paste(deparse(bound, width.cutoff = 500L), collapse = "")))
if (!isTRUE(all.equal(printed, bound, tolerance = 1e-12)) || !identical(wet_bcenv_bound, printed)) {
  stop("wet_bcenv_bound is not the measured bound; set it to the report's \"As R\" line", call. = FALSE)
}
