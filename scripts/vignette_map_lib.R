# Map layers shared by the vignette map data scripts
# (data-raw/station_vignette_map.R, #27; data-raw/monthly_vignette_map.R, #107;
# data-raw/short_record_vignette_map.R, #130; data-raw/chinook_sites_map.R, #126):
# the stations from HYDAT, each one's catchment from its FWA snap, and the
# context in an extent (streams, lakes, place names, the province outline),
# all sf in EPSG:3005. Sourced after load_all(); the scripts choose the
# stations, the stream keys and the place names, and connect to fwapg
# themselves (scripts/vignette_data_lib.R, vd_connect()).
#
# A rerun on the same FWA writes the same file (#155): every query orders its
# rows on a unique key and its aggregates' input, lakes and stream segments
# come from fresh's fetchers (frs_lake_fetch(), frs_stream_fetch(); fresh is
# needed by data-raw/ only), and vm_write() keeps the committed file when
# nothing in it changed, printing what changed otherwise (vm_compare()).
# Polygons are simplified here (vm_simplify()), not in PostGIS: under GEOS
# 3.9.0, ST_SimplifyPreserveTopology() drew Tahtsa Reach with 556 or 557
# vertices on repeated calls in one session, where sf's GEOS 3.13 gave one
# drawing in 60.

# The stations from HYDAT STATIONS, in the order given
vm_stations <- function(hydat, stations) {
  con <- wet_hydat_connect(hydat)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  sql <- sprintf("
    SELECT STATION_NUMBER AS station_number, STATION_NAME AS station_name, LONGITUDE AS lon,
           LATITUDE AS lat, DRAINAGE_AREA_GROSS AS drainage_area_gross_km2
    FROM STATIONS WHERE STATION_NUMBER IN (%s)", paste0("'", stations, "'", collapse = ", "))
  st <- DBI::dbGetQuery(con, sql)
  stopifnot(setequal(st$station_number, stations))
  st[match(stations, st$station_number), ]
}

# Topology-preserving simplification in sf, which repeats exactly (above)
vm_simplify <- function(x, simplify_m) {
  sf::st_geometry(x) <- sf::st_simplify(sf::st_geometry(x), preserveTopology = TRUE, dTolerance = simplify_m)
  x
}

# Each station's upstream watershed: the snap picks the segment by drainage
# area, and the catchment is cut at the station's own measure on that
# segment. Area is taken before the simplify, so it is the watershed's, not
# the drawing's, and must be within 10% of HYDAT's gross area.
vm_catchments <- function(conn, st, simplify_m) {
  snap <- wet_station_snap(conn, st)
  if (!all(snap$accepted)) stop("snap not accepted for: ", paste(snap$station_number[!snap$accepted], collapse = ", "))
  catch <- do.call(rbind, lapply(seq_len(nrow(st)), function(i) {
    sql <- sprintf("
      WITH p AS (
        SELECT c.blue_line_key, c.downstream_route_measure
        FROM whse_basemapping.fwa_indexpoint(
          ST_Transform(ST_SetSRID(ST_MakePoint(%.10f, %.10f), 4326), 3005), 1000, 5) c
        WHERE c.linear_feature_id = %.0f)
      SELECT '%s' AS station_number, w.area_ha / 100 AS area_km2,
             ST_Normalize(ST_Force2D(w.geom)) AS geom
      FROM p, whse_basemapping.fwa_watershedatmeasure(p.blue_line_key, p.downstream_route_measure) w",
                   st$lon[i], st$lat[i], snap$linear_feature_id[i], st$station_number[i])
    vm_simplify(sf::st_read(conn, quiet = TRUE, query = sql), simplify_m)
  }))
  stopifnot(nrow(catch) == nrow(st))
  catch$area_ratio <- catch$area_km2 / st$drainage_area_gross_km2[match(catch$station_number, st$station_number)]
  print(sf::st_drop_geometry(catch))
  stopifnot(all(abs(catch$area_ratio - 1) < 0.1))
  catch
}

# The map extent: the catchments' bounding box plus a margin, as sfc and WKT
vm_extent <- function(catch, margin_m) {
  ext <- sf::st_as_sfc(sf::st_bbox(sf::st_buffer(sf::st_union(catch), margin_m)))
  list(sfc = ext, wkt = sf::st_as_text(ext))
}

# Streams of at least `min_order` in the extent (`ext`, from vm_extent()),
# plus the whole of each stream in `blk` (by blue_line_key: GNIS names repeat
# across BC), merged per key. fresh fetches the segments ordered on
# linear_feature_id; they are unioned, merged and simplified per key here, in
# that order, so the drawing does not depend on the row order PostgreSQL
# returns. include_all keeps every FWA segment, as the query before fresh did.
vm_streams <- function(conn, ext, blk, simplify_m, min_order = 5) {
  cols <- c("linear_feature_id", "blue_line_key", "gnis_name", "stream_order", "geom")
  in_ext <- fresh::frs_stream_fetch(conn, stream_order_min = min_order, aoi = ext$sfc, cols = cols,
                                    include_all = TRUE)
  whole <- lapply(unname(blk), function(k) {
    fresh::frs_stream_fetch(conn, blue_line_key = k, cols = cols, include_all = TRUE)
  })
  seg <- do.call(rbind, c(list(in_ext), whole))
  seg <- seg[!duplicated(seg$linear_feature_id), ]
  seg <- seg[order(seg$blue_line_key, seg$linear_feature_id), ]
  geom <- sf::st_zm(sf::st_geometry(seg))
  streams <- do.call(rbind, lapply(unique(seg$blue_line_key), function(k) {
    i <- seg$blue_line_key == k
    nm <- sort(unique(stats::na.omit(seg$gnis_name[i])), method = "radix")
    # a key of one segment unions to a LINESTRING, which st_line_merge() refuses
    u <- sf::st_cast(sf::st_union(geom[i]), "MULTILINESTRING")
    g <- sf::st_simplify(sf::st_line_merge(u), preserveTopology = TRUE, dTolerance = simplify_m)
    sf::st_sf(blue_line_key = as.integer(k), gnis_name = if (length(nm)) nm[length(nm)] else NA_character_,
              stream_order = as.integer(max(seg$stream_order[i])), geom = g)
  }))
  streams$main <- streams$blue_line_key %in% blk
  stopifnot(sum(streams$main) == length(blk))
  streams
}

# FWA lakes of at least `min_ha` in the extent (`ext`, from vm_extent()),
# ordered on waterbody_poly_id by fresh and simplified here (vm_simplify())
vm_lakes <- function(conn, ext, simplify_m, min_ha = 100) {
  lakes <- fresh::frs_lake_fetch(conn, aoi = ext$sfc, area_ha_min = min_ha,
                                 cols = c("waterbody_poly_id", "gnis_name_1", "area_ha", "geom"))
  vm_simplify(sf::st_sf(gnis_name = lakes$gnis_name_1, area_ha = lakes$area_ha, geom = sf::st_geometry(lakes)),
              simplify_m)
}

# The province outline for a keymap an inch wide: parts under 2,000 km2 are
# noise at that size, and the rest is simplified at 5 km (vm_simplify()). The
# union takes its polygons in id order and the parts are collected largest
# first, so the outline does not depend on the order PostgreSQL returns them in
vm_bc <- function(conn) {
  vm_simplify(sf::st_read(conn, quiet = TRUE, query = "
    SELECT ST_Normalize(ST_Collect(d.geom ORDER BY ST_Area(d.geom) DESC, ST_XMin(d.geom), ST_YMin(d.geom))) AS geom
    FROM (SELECT (ST_Dump(ST_Union(geom ORDER BY bcboundary_id))).geom FROM whse_basemapping.fwa_bcboundary) d
    WHERE ST_Area(d.geom) >= 2e9"), 5000)
}

# The rivers each blue line flows into, from its watershed code: `into1` (the
# stream it joins), `into2` (the one that joins after, NA where `into1` runs to
# the sea), `into1_blk` (into1's blue line), `system` (the river at the top of
# the code), and `mouth_x`, `mouth_y`, the downstream end of the blue line
# (EPSG:3005), one row per key in the order given (from
# data-raw/chinook_sites_map.R, #126; shared with station_vignette_map.R, #145)
vm_into <- function(conn, blks) {
  into <- do.call(rbind, lapply(blks, function(blk) {
    # a stream that joins a river running to the sea (Naver into the Fraser) has no second level
    r <- DBI::dbGetQuery(conn, sprintf("
      WITH t AS (SELECT DISTINCT wscode_ltree FROM whse_basemapping.fwa_stream_networks_sp
                 WHERE blue_line_key = %d AND blue_line_key = watershed_key AND gnis_name IS NOT NULL),
           up AS (SELECT n, subpath(t.wscode_ltree, 0, nlevel(t.wscode_ltree) - n) AS code
                  FROM t, (VALUES (1), (2)) v(n))
      SELECT up.n, max(s.gnis_name) AS gnis_name, min(s.blue_line_key) AS blue_line_key
      FROM up JOIN whse_basemapping.fwa_stream_networks_sp s
        ON s.wscode_ltree = up.code AND s.blue_line_key = s.watershed_key
      GROUP BY up.n ORDER BY up.n", as.integer(blk)))
    if (!1 %in% r$n) stop("blue line ", blk, " flows into no named stream", call. = FALSE)
    merge(data.frame(n = 1:2), r, all.x = TRUE)
  }))
  stopifnot(nrow(into) == 2 * length(blks), !anyNA(into$gnis_name[into$n == 1]))
  out <- data.frame(into1 = into$gnis_name[into$n == 1], into2 = into$gnis_name[into$n == 2],
                    into1_blk = as.integer(into$blue_line_key[into$n == 1]))
  # the river system: the stream at the top of the watershed code (the Skeena's 400, the Fraser's 100)
  out$system <- vapply(blks, function(blk) {
    DBI::dbGetQuery(conn, sprintf("
      SELECT max(s.gnis_name) AS gnis_name FROM whse_basemapping.fwa_stream_networks_sp s
      WHERE s.blue_line_key = s.watershed_key AND s.wscode_ltree = (
        SELECT subpath(wscode_ltree, 0, 1) FROM whse_basemapping.fwa_stream_networks_sp
        WHERE blue_line_key = %d AND blue_line_key = watershed_key LIMIT 1)", as.integer(blk)))$gnis_name
  }, "")
  # the mouth: the downstream end of the blue line's lowest segment
  mouth <- sf::st_read(conn, quiet = TRUE, query = sprintf("
    SELECT DISTINCT ON (blue_line_key) blue_line_key, ST_StartPoint(ST_LineMerge(ST_Force2D(geom))) AS geom
    FROM whse_basemapping.fwa_stream_networks_sp WHERE blue_line_key IN (%s)
    ORDER BY blue_line_key, downstream_route_measure", paste(blks, collapse = ", ")))
  mxy <- sf::st_coordinates(mouth)[match(blks, mouth$blue_line_key), , drop = FALSE]
  out$mouth_x <- mxy[, 1]
  out$mouth_y <- mxy[, 2]
  stopifnot(!anyNA(out$mouth_x), !anyNA(out$system))
  out
}

# Named places from BC Geographic Names (bcdata), kept only inside the
# extent: a name is not a key, and the same name sits in several places
vm_places <- function(ext, names) {
  # bcdata translates the filter to a WFS query, so the column is named bare
  gns <- bcdata::bcdc_query_geodata("WHSE_BASEMAPPING.GNS_GEOGRAPHICAL_NAMES_SP") |>
    dplyr::filter(GEOGRAPHICAL_NAME %in% names) |>  # nolint: object_usage_linter.
    bcdata::collect()
  gns <- gns[lengths(sf::st_intersects(gns, ext)) > 0, ]
  # the WFS promises no order: sort on name, then place
  xy <- sf::st_coordinates(sf::st_geometry(gns))
  gns <- gns[order(gns$GEOGRAPHICAL_NAME, xy[, 1], xy[, 2], method = "radix"), ]
  places <- sf::st_sf(name = gns$GEOGRAPHICAL_NAME, feature_type = gns$FEATURE_TYPE,
                      geom = sf::st_geometry(gns))
  print(sf::st_drop_geometry(places))
  places
}

# The stations as points in EPSG:3005
vm_points <- function(st) {
  pts <- sf::st_transform(sf::st_as_sf(st, coords = c("lon", "lat"), crs = 4326), 3005)
  sf::st_geometry(pts) <- "geom"
  pts
}

# The database's PostGIS, GEOS and PROJ, so a rebuild on another database
# explains its own differences (#155)
vm_postgis <- function(conn) {
  DBI::dbGetQuery(conn, "SELECT postgis_full_version() AS v")$v
}

# Every layer with its CRS set, the HYDAT release, the PostGIS that queried
# the layers (vm_postgis()) and the GEOS that merged and simplified them
# (sf's) as provenance
vm_layers <- function(layers, hydat, postgis) {
  stopifnot(is.character(postgis), length(postgis) == 1)
  layers <- lapply(layers, function(x) {
    sf::st_crs(x) <- 3005
    x
  })
  attr(layers, "provenance") <- list(hydat = format(as.Date(wet_hydat_release(hydat), "%Y%m%d")), postgis = postgis,
                                     sf_geos = unname(sf::sf_extSoftVersion()["GEOS"]))
  layers
}

# A bundle's provenance: an attribute where vm_layers() set it, an element in
# the segment map's bundle
vm_provenance <- function(x) {
  if (is.null(attr(x, "provenance"))) x$provenance else attr(x, "provenance")
}

# How each layer of a new bundle compares with an old one, printed and
# returned: identical; identical once both are sorted on every column and the
# geometry's WKB; the same features (equal attributes once sorted) with
# different geometry, with the vertices that differ and the largest Hausdorff
# distance (m) between a feature's two drawings; or different. Elements that
# are not sf (zones, provenance) are identical or different.
vm_compare <- function(new, old) {
  wkb <- function(x) {
    b <- sf::st_as_binary(sf::st_geometry(x), endian = "little")
    vapply(b, function(r) paste(as.character(r), collapse = ""), "")
  }
  sorted <- function(x, with_geom) {
    keys <- c(as.list(sf::st_drop_geometry(x)), if (with_geom) list(wkb(x)))
    if (length(keys)) x <- x[do.call(order, c(unname(keys), list(method = "radix"))), ]
    rownames(x) <- NULL
    x
  }
  verts <- function(x) vapply(sf::st_geometry(x), function(g) nrow(sf::st_coordinates(g)), 0)
  nm <- setdiff(union(names(new), names(old)), "provenance")
  out <- do.call(rbind, lapply(nm, function(k) {
    a <- new[[k]]
    b <- old[[k]]
    row <- function(verdict, n = NA, v = NA, h = NA) {
      data.frame(layer = k, verdict = verdict, features = n, vertices_differ = v, hausdorff_max_m = h)
    }
    if (identical(a, b)) return(row("identical", if (inherits(a, "sf")) nrow(a) else NA))
    if (!inherits(a, "sf") || !inherits(b, "sf") || nrow(a) != nrow(b) ||
          !identical(names(a), names(b))) return(row("different"))
    sa <- sorted(a, TRUE)
    sb <- sorted(b, TRUE)
    if (identical(sa, sb)) return(row("identical after sorting", nrow(a)))
    sa <- sorted(a, FALSE)
    sb <- sorted(b, FALSE)
    if (!identical(sf::st_drop_geometry(sa), sf::st_drop_geometry(sb))) return(row("different", nrow(a)))
    va <- verts(sa)
    vb <- verts(sb)
    h <- vapply(seq_len(nrow(sa)), function(i) {
      as.numeric(sf::st_distance(sf::st_geometry(sa)[i], sf::st_geometry(sb)[i], which = "Hausdorff"))
    }, 0)
    row("same features, different geometry", nrow(a), sum(abs(va - vb)), round(max(h), 1))
  }))
  print(out, row.names = FALSE)
  invisible(out)
}

# Write a bundle as inst/vignette-data/<file>, or under WET_MAP_OUT_DIR for a
# rebuild elsewhere, comparing it first with the committed file
# (vm_compare()). Where every layer, the provenance and the list's other
# attributes are identical, the committed file is left as it is, so a rerun that changes
# nothing changes no bytes.
vm_write <- function(layers, file) {
  ref <- file.path("inst", "vignette-data", file)
  out <- file.path(Sys.getenv("WET_MAP_OUT_DIR", file.path("inst", "vignette-data")), file)
  if (file.exists(ref)) {
    old <- readRDS(ref)
    cmp <- vm_compare(layers, old)
    other <- function(x) {
      a <- attributes(x)
      a[setdiff(names(a), c("names", "provenance"))]
    }
    same_prov <- identical(vm_provenance(layers), vm_provenance(old)) &&
      identical(other(layers), other(old))
    if (!same_prov) message("provenance or attributes differ from ", ref)
    in_place <- identical(normalizePath(dirname(out)), normalizePath(dirname(ref)))
    if (all(cmp$verdict == "identical") && same_prov && in_place) {
      message(file, ": unchanged, ", ref, " left as it is")
      return(invisible(ref))
    }
  }
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  saveRDS(layers, out, compress = "xz")
  message(file, ": wrote ", out, " (", round(file.size(out) / 1024), " KB)")
  invisible(out)
}
