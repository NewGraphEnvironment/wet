# Chinook use at #126's candidate streams, the evidence that fixes its targets.
#
#   WET_HYDAT_RELEASE=20260717 Rscript scripts/chinook_sites_use.R
#
# For each candidate (by blue_line_key, since GNIS names repeat across BC):
#   - NuSEDS (DFO's escapement database, open.canada.ca record
#     c48669a3-045b-400d-b730-48aafe8c5ee6, the All Areas file of 2026-06-01),
#     Chinook rows whose FWA_WATERSHED_CDE is the stream's fwa_watershed_code:
#     every row, and the use records among them, a row whose ADULT_PRESENCE is
#     PRESENT or whose NATURAL_ADULT_SPAWNERS is above 0. Downloaded once into
#     data/chinook_sites/raw/ (gitignored); the report gives its md5.
#   - the provincial fish observations (fwapg's bcfishobs.observations), Chinook
#     rows on the stream's blue line, with their activities; a spawning record is
#     one whose activity names spawning.
#   - the stream's area at its mouth, the fundamental watersheds under its
#     watershed code in its group, and the HYDAT stations inside them.
#
# The Morice rule (user, 2026-10-28): of Gosnell and Lamprey Creek, the target
# is the ungauged one with more use records (NuSEDS use records plus provincial
# observations); a tie goes to the one with a spawning record (a NuSEDS use
# record is an adult spawner record), then to the larger area. Owen Creek, the
# issue's first choice, is reported and not a candidate: the provincial
# observations record no Chinook there.
#
# Writes data/checks/chinook_sites_use.txt, with no timestamp. fwapg through
# the WET_PG* variables (scripts/vignette_data_lib.R's vd_connect()).

devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")  # wb_release(), wb_hydat()
source("scripts/vignette_data_lib.R")  # vd_connect()

release <- wb_release()
hydat <- wb_hydat(release)
report <- file.path("data", "checks", "chinook_sites_use.txt")
raw_dir <- file.path("data", "chinook_sites", "raw")
nuseds_zip <- file.path(raw_dir, "nuseds_all_areas_20260601.zip")
nuseds_url <- paste0("https://api-proxy.edh-cde.dfo-mpo.gc.ca/catalogue/records/",
                     "c48669a3-045b-400d-b730-48aafe8c5ee6/attachments/All%20Areas%20NuSEDS_20260601.zip")

cand <- data.frame(
  stream = c("Swift Creek", "Naver Creek", "Gosnell Creek", "Lamprey Creek", "Owen Creek"),
  wsg = c("UFRA", "COTR", "MORR", "MORR", "MORR"),
  blue_line_key = c(356345574L, 356363814L, 360885021L, 360880441L, 360819468L),
  role = c("extend", "extend", "morice", "morice", "dropped")
)

# ---- NuSEDS ----------------------------------------------------------------------------------
if (!file.exists(nuseds_zip)) {
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  h <- curl::new_handle(useragent = "wet R package (NewGraphEnvironment/wet)")
  r <- curl::curl_fetch_disk(nuseds_url, nuseds_zip, handle = h)
  if (r$status_code != 200) {
    unlink(nuseds_zip)
    stop("NuSEDS download answered HTTP ", r$status_code, call. = FALSE)
  }
}
nuseds_md5 <- unname(tools::md5sum(nuseds_zip))
td <- tempfile("nuseds")
csv <- utils::unzip(nuseds_zip, exdir = td)
stopifnot(length(csv) == 1)

# ---- fwapg: each stream's code, area, observations and gauges --------------------------------
conn <- vd_connect()
keys <- paste(cand$blue_line_key, collapse = ",")
code <- DBI::dbGetQuery(conn, sprintf("
  SELECT DISTINCT blue_line_key, gnis_name, watershed_group_code, fwa_watershed_code, wscode_ltree::text wscode
  FROM whse_basemapping.fwa_stream_networks_sp
  WHERE blue_line_key IN (%s) AND blue_line_key = watershed_key AND gnis_name IS NOT NULL
  ORDER BY blue_line_key", keys))
if (anyDuplicated(code$blue_line_key) || !setequal(code$blue_line_key, cand$blue_line_key)) {
  stop("each candidate's blue line must carry one watershed code", call. = FALSE)
}
code <- code[match(cand$blue_line_key, code$blue_line_key), ]
stopifnot(identical(code$gnis_name, cand$stream), identical(code$watershed_group_code, cand$wsg))

basin <- do.call(rbind, lapply(seq_len(nrow(cand)), function(i) {
  DBI::dbGetQuery(conn, sprintf("
    SELECT %d::bigint blue_line_key, sum(ST_Area(geom) ORDER BY watershed_feature_id) / 1e6 km2, ST_AsText(ST_Union(geom)) wkt
    FROM whse_basemapping.fwa_watersheds_poly
    WHERE watershed_group_code = '%s' AND wscode_ltree <@ '%s'::ltree",
    cand$blue_line_key[i], cand$wsg[i], code$wscode[i]))
}))
obs <- DBI::dbGetQuery(conn, sprintf("
  SELECT s.blue_line_key, o.observation_date, o.activity, o.life_stage, o.source,
         round(o.downstream_route_measure) measure_m
  FROM bcfishobs.observations o
  JOIN whse_basemapping.fwa_stream_networks_sp s USING (linear_feature_id)
  WHERE o.species_code = 'CH' AND s.blue_line_key IN (%s)
  ORDER BY s.blue_line_key, o.observation_date, o.fish_observation_point_id", keys))
n_obs_all <- as.integer(DBI::dbGetQuery(conn, "SELECT count(*) n FROM bcfishobs.observations")$n)

con_h <- wet:::wet_hydat_connect(hydat)
st <- DBI::dbGetQuery(con_h, "SELECT STATION_NUMBER station_number, STATION_NAME station_name,
  LONGITUDE lon, LATITUDE lat FROM STATIONS WHERE PROV_TERR_STATE_LOC = 'BC' ORDER BY STATION_NUMBER")
DBI::dbDisconnect(con_h)
st_sf <- sf::st_transform(sf::st_as_sf(st, coords = c("lon", "lat"), crs = 4326), 3005)
gauged <- lapply(seq_len(nrow(basin)), function(i) {
  poly <- sf::st_as_sfc(basin$wkt[i], crs = 3005)
  st$station_number[lengths(sf::st_within(st_sf, poly)) > 0]
})
DBI::dbDisconnect(conn)

nus_con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(nus_con, sprintf("CREATE VIEW n AS SELECT * FROM read_csv(%s, all_varchar = true)",
                                DBI::dbQuoteString(nus_con, csv)))
nus <- DBI::dbGetQuery(nus_con, sprintf("
  SELECT FWA_WATERSHED_CDE fwa_watershed_code, AREA area, WATERBODY waterbody,
         try_cast(ANALYSIS_YR AS INTEGER) yr, ADULT_PRESENCE presence,
         try_cast(NATURAL_ADULT_SPAWNERS AS DOUBLE) spawners
  FROM n WHERE SPECIES = 'Chinook' AND FWA_WATERSHED_CDE IN (%s)
  ORDER BY FWA_WATERSHED_CDE, yr", paste(DBI::dbQuoteString(nus_con, code$fwa_watershed_code), collapse = ",")))
n_nus_all <- as.integer(DBI::dbGetQuery(nus_con, "SELECT count(*) n FROM n")$n)
DBI::dbDisconnect(nus_con, shutdown = TRUE)
nus$use <- nus$presence %in% "PRESENT" | (!is.na(nus$spawners) & nus$spawners > 0)

# ---- the table and the Morice rule -----------------------------------------------------------
yrs <- function(y) if (length(y <- y[!is.na(y)])) sprintf("%d-%d", min(y), max(y)) else "-"
tab <- do.call(rbind, lapply(seq_len(nrow(cand)), function(i) {
  k <- cand$blue_line_key[i]
  nu <- nus[nus$fwa_watershed_code == code$fwa_watershed_code[i], ]
  ob <- obs[obs$blue_line_key == k, ]
  data.frame(stream = cand$stream[i], wsg = cand$wsg[i], blue_line_key = k, role = cand$role[i],
             km2 = basin$km2[basin$blue_line_key == k],
             gauges = paste(c(gauged[[i]], character(0)), collapse = " "),
             nus_rows = nrow(nu), nus_use = sum(nu$use), nus_use_years = length(unique(stats::na.omit(nu$yr[nu$use]))),
             nus_years = yrs(nu$yr[nu$use]),
             obs = nrow(ob), obs_spawning = sum(grepl("spawn", ob$activity, ignore.case = TRUE)),
             obs_years = yrs(as.integer(format(ob$observation_date, "%Y"))))
}))
tab$use <- tab$nus_use + tab$obs
tab$spawning_record <- tab$nus_use > 0 | tab$obs_spawning > 0

mor <- tab[tab$role == "morice", ]
if (any(nzchar(mor$gauges))) stop("a Morice candidate holds a HYDAT station: ", paste(mor$gauges, collapse = " "), call. = FALSE)
ord <- order(-mor$use, -mor$spawning_record, -mor$km2)
pick <- mor$stream[ord[1]]
why <- if (mor$use[ord[1]] > mor$use[ord[2]]) {
  "more use records"
} else if (mor$spawning_record[ord[1]] && !mor$spawning_record[ord[2]]) {
  "tied on use records; it alone has a spawning record"
} else {
  "tied on use records and spawning records; the larger area"
}

# ---- report ----------------------------------------------------------------------------------
out <- c("# Chinook use at #126's candidate streams", "",
         sprintf("NuSEDS All Areas 2026-06-01 (%s, md5 %s): %d rows; Chinook rows matched on FWA_WATERSHED_CDE.",
                 basename(nuseds_zip), nuseds_md5, n_nus_all),
         sprintf("Provincial fish observations (fwapg bcfishobs.observations, %d rows): Chinook rows on the stream's blue line.", n_obs_all),
         sprintf("Area: the fundamental watersheds under the stream's watershed code in its group. Gauges: HYDAT %s BC stations inside that area.", release),
         "A NuSEDS use record: ADULT_PRESENCE PRESENT or NATURAL_ADULT_SPAWNERS > 0. A spawning record: a NuSEDS use record, or an observation whose activity names spawning.",
         "", sprintf("  %-14s %-4s %-10s %-8s %7s %-9s %8s %7s %6s %-10s %4s %5s %-10s %4s",
                     "stream", "wsg", "blkey", "role", "km2", "gauges", "nuseds", "use", "uyrs", "years", "obs", "spawn", "years", "use"))
for (i in seq_len(nrow(tab))) {
  out <- c(out, sprintf("  %-14s %-4s %-10d %-8s %7.1f %-9s %8d %7d %6d %-10s %4d %5d %-10s %4d",
                        tab$stream[i], tab$wsg[i], tab$blue_line_key[i], tab$role[i], tab$km2[i],
                        if (nzchar(tab$gauges[i])) tab$gauges[i] else "none",
                        tab$nus_rows[i], tab$nus_use[i], tab$nus_use_years[i], tab$nus_years[i], tab$obs[i], tab$obs_spawning[i],
                        tab$obs_years[i], tab$use[i]))
}
out <- c(out, "", "nuseds: Chinook rows; use: of them, use records; uyrs: the distinct years with a use record. obs: provincial Chinook observations; spawn: of them, spawning records. Last column: use records in all.",
         "", "Provincial Chinook observations, per stream:", "")
for (i in seq_len(nrow(cand))) {
  ob <- obs[obs$blue_line_key == cand$blue_line_key[i], ]
  for (j in seq_len(nrow(ob))) {
    out <- c(out, sprintf("  %-14s %s  %6d m  %-40s %-8s %s", cand$stream[i], format(ob$observation_date[j]),
                          as.integer(ob$measure_m[j]), substr(ifelse(is.na(ob$activity[j]), "-", ob$activity[j]), 1, 40),
                          ifelse(is.na(ob$life_stage[j]), "-", ob$life_stage[j]), ob$source[j]))
  }
}
out <- c(out, "", sprintf("The Morice rule (more use records, then a spawning record, then the larger area): %s, %s.", pick, why))
writeLines(out, report)
message("wrote ", report, "; Morice target: ", pick)
