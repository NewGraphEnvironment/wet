# The survey's HYDAT match (#123), shared by the scripts that build on it (#142, #179)
#
# Copied from scripts/station_sources_probe.R, which stays as it is (#123's
# record, its md5 in its report); scripts/station_sources_harvest.R reproduces
# the survey's counts through these copies, so a drift from the probe shows there.
#
# hydat_stations(hydat): every HYDAT station with coordinates, its discharge
#   period and the stream its name gives.
# hydat_match(s, hy): matches stations s (station_id, name, lon, lat, first,
#   last; first/last as years) to hy: the same stream name within 1 km is the
#   same site; near misses within 3 km are listed.

match_km <- 1
near_km <- 3

hydat_stations <- function(hydat) {
  con <- wet:::wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con))
  hy <- DBI::dbGetQuery(con, "
    SELECT s.STATION_NUMBER station_number, s.STATION_NAME station_name, s.PROV_TERR_STATE_LOC prov,
           s.HYD_STATUS status, s.LONGITUDE lon, s.LATITUDE lat,
           q.YEAR_FROM q_from, q.YEAR_TO q_to
    FROM STATIONS s
    LEFT JOIN (SELECT STATION_NUMBER, YEAR_FROM, YEAR_TO FROM STN_DATA_RANGE WHERE DATA_TYPE = 'Q') q
      USING (STATION_NUMBER)
    ORDER BY s.STATION_NUMBER")
  stopifnot(!anyDuplicated(hy$station_number))
  hy <- hy[!is.na(hy$lon) & !is.na(hy$lat), ]
  hy$stream <- stream_of(hy$station_name)
  hy
}

# the stream a gauge sits on, from its name: "MAXAN CREEK ABOVE BULKLEY LAKE" and
# "Maxan Ck hydrometric" are both "maxan creek"
stream_of <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9' ]+", " ", x)
  x <- gsub("\\b(ck|cr|crk)\\b", "creek", x)
  x <- gsub("\\br\\b", "river", x)
  x <- gsub("\\btrib\\b", "tributary", x)
  x <- trimws(gsub(" +", " ", x))
  x <- sub("^(upper|lower) ", "", x)
  # up to the first stream noun where there is one, otherwise up to the first word
  # that describes the gauge rather than the stream
  noun <- "^(.*?\\b(creek|river|brook|slough|channel|lake|spring))\\b.*$"
  stop_words <- paste0("\\b(above|below|near|nr|at|on|in|upstream|downstream|abv|blw|",
                       "hydrometric|station|gauge|gage|weir|site|discharge|flow|water|level|",
                       "monitoring|quality|outlet|inlet|mouth)\\b.*$")
  has_noun <- grepl(noun, x, perl = TRUE)
  x[has_noun] <- sub(noun, "\\1", x[has_noun], perl = TRUE)
  x[!has_noun] <- sub(stop_words, "", x[!has_noun])
  trimws(x)
}

albers <- function(lon, lat) {
  sf::st_coordinates(sf::st_transform(sf::st_as_sf(data.frame(lon = lon, lat = lat), coords = c("lon", "lat"),
                                                   crs = 4326), 3005)) / 1000
}

hydat_match <- function(s, hy, wsc = NULL) {
  hy_xy <- albers(hy$lon, hy$lat)
  xy <- albers(s$lon, s$lat)
  stream <- stream_of(s$name)
  res <- lapply(seq_len(nrow(s)), function(i) {
    d <- sqrt((hy_xy[, 1] - xy[i, 1])^2 + (hy_xy[, 2] - xy[i, 2])^2)
    by_number <- !is.null(wsc) && !is.na(s[[wsc]][i]) && s[[wsc]][i] %in% hy$station_number
    j <- if (by_number) match(s[[wsc]][i], hy$station_number) else {
      same <- which(d <= match_km & hy$stream == stream[i] & nzchar(stream[i]))
      if (length(same)) same[which.min(d[same])] else NA_integer_
    }
    near <- which((d <= match_km & hy$stream != stream[i]) |
                  (d > match_km & d <= near_km & hy$stream == stream[i] & nzchar(stream[i])))
    near <- setdiff(near, j)
    far <- which(d > match_km & d <= near_km & hy$stream == stream[i] & nzchar(stream[i]) & !is.na(hy$q_from))
    j3 <- if (length(far)) far[which.min(d[far])] else NA_integer_
    data.frame(
      hydat = if (is.na(j)) NA_character_ else hy$station_number[j],
      hydat_km = if (is.na(j)) NA_real_ else round(d[j], 2),
      hydat_q = if (is.na(j) || is.na(hy$q_from[j])) NA_character_ else sprintf("%d-%d", hy$q_from[j], hy$q_to[j]),
      near_miss = paste(sprintf("%s (%.2f km)", hy$station_number[near], d[near]), collapse = "; "),
      hydat3 = if (is.na(j3)) NA_character_ else sprintf("%s (%.2f km, %d-%d)", hy$station_number[j3], d[j3],
                                                         hy$q_from[j3], hy$q_to[j3]),
      q3_from = if (is.na(j3)) NA_integer_ else hy$q_from[j3],
      q3_to = if (is.na(j3)) NA_integer_ else hy$q_to[j3],
      class = if (is.na(j)) "not in HYDAT" else if (!is.na(hy$q_from[j]) && !is.na(s$first[i]) &&
        s$first[i] >= hy$q_from[j] && s$last[i] <= hy$q_to[j]) "duplicate" else "same site, new years"
    )
  })
  cbind(s, do.call(rbind, res))
}

# a name that says the flow is managed: the regulation flag where a source has none
regulation_of <- function(name) {
  ifelse(grepl("\\b(dam|diversions?|reservoir|intake|spillway|pump|canal|ditch|pumphouse)\\b",
               tolower(name)), "regulated? (name) [I]", "unknown")
}
