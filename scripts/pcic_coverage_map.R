# The coverage map (#169, #5): two panels across the page, each a watershed-group
# class from scripts/pcic_coverage.R: which published 1981-2010 source covers the
# group, and what wet's scenarios would build on there.
#
#   WET_DATA_ROOT=<data dir> Rscript scripts/pcic_coverage_map.R
#
# Reads the group table scripts/pcic_coverage.R wrote under <data root>/pcic_coverage/,
# refused unless its md5 is the one the tracked report names. The drawn layers (group
# polygons, BC's outline and river labels from fwapg; towns from the BC Data Catalogue)
# are stored once in <data root>/pcic_coverage/map_layers_<key>.rds, keyed on what they are drawn
# from, so a second render asks
# nothing; rivers of stream order 7 and up come from inst/vignette-data/segment_map.rds.
# Colours from inst/cartography/wet_coverage.csv (gq). Writes research/pcic_coverage.png,
# a research figure (not on the site).

source("scripts/vignette_data_lib.R")  # vd_connect()
devtools::load_all(quiet = TRUE)
source("scripts/wb_fit_lib.R")         # wb_release()
source("scripts/vignette_map_lib.R")   # vm_simplify(), vm_bc(), vm_places()
library(ggplot2)
sf::sf_use_s2(FALSE)

release <- wb_release()
data_root <- Sys.getenv("WET_DATA_ROOT", "data")
out_dir <- file.path(data_root, "pcic_coverage")
f_report <- file.path("data", "checks", sprintf("pcic_coverage_%s.txt", release))
f_table <- file.path(out_dir, sprintf("coverage_%s.tsv", release))
f_png <- file.path("research", "pcic_coverage.png")
simplify_m <- 1500
rivers <- c("Fraser River", "Peace River", "Columbia River", "Skeena River", "Liard River")
towns <- c("Prince George", "Vancouver", "Kelowna", "Fort St. John", "Smithers", "Fort Nelson")
main_flow <- c(1000, 1050, 1200, 1250, 1450)

# ---- the table, held to the tracked report -------------------------------------------------------
rep <- readLines(f_report)
want <- sub("^group table: .* md5 ([0-9a-f]{32})$", "\\1", grep("^group table: ", rep, value = TRUE))
if (length(want) != 1L || !identical(unname(tools::md5sum(f_table)), want)) {
  stop(f_table, " is not the table ", f_report, " names: rerun scripts/pcic_coverage.R", call. = FALSE)
}
tb <- utils::read.delim(f_table, quote = "", na.strings = "NA", comment.char = "", colClasses = "character")

# ---- the layers, stored once, named for the code they are drawn with -----------------------------
# (the names asked for, the simplification, main flow, this script's queries and the map lib), so
# an edit to any of them draws new layers rather than the stored ones. The key does not cover the
# data: a render against another fwapg, or after the BC Geographic Names data change, reuses the
# stored layers until their file is removed
layers_key <- substr(wet:::wet_md5_text(c(rivers, towns, simplify_m, main_flow,
                                           unname(tools::md5sum(c("scripts/pcic_coverage_map.R",
                                                                  "scripts/vignette_map_lib.R"))))), 1, 10)
f_layers <- file.path(out_dir, sprintf("map_layers_%s.rds", layers_key))
if (!file.exists(f_layers)) {
  conn <- vd_connect()
  grp <- vm_simplify(sf::st_read(conn, quiet = TRUE, query = "
    SELECT watershed_group_code, ST_Normalize(geom) AS geom
    FROM whse_basemapping.fwa_watershed_groups_poly ORDER BY watershed_group_code"), simplify_m)
  bc <- vm_bc(conn)
  lab <- sf::st_read(conn, quiet = TRUE, query = sprintf("
    WITH s AS (
      SELECT gnis_name, blue_line_key, geom FROM whse_basemapping.fwa_stream_networks_sp
      WHERE gnis_name IN (%s) AND stream_order >= 7 AND edge_type IN (%s)
    ), one AS (
      SELECT gnis_name, count(DISTINCT blue_line_key) AS n_blk, min(blue_line_key) AS blue_line_key,
             ST_LineMerge(ST_Union(geom ORDER BY ST_XMin(geom), ST_YMin(geom))) AS geom
      FROM s GROUP BY gnis_name
    )
    SELECT gnis_name AS name, n_blk, ST_ClosestPoint(geom, ST_Centroid(geom)) AS geom FROM one ORDER BY gnis_name",
    paste0("'", rivers, "'", collapse = ", "), paste(main_flow, collapse = ", ")))
  DBI::dbDisconnect(conn)
  if (!setequal(lab$name, rivers) || any(lab$n_blk != 1)) {
    stop("each river name must give one blue line of order 7 and up: ",
         paste(sprintf("%s %s", lab$name, lab$n_blk), collapse = ", "), call. = FALSE)
  }
  pl <- vm_places(bc, towns)
  pl <- pl[grepl("City|Town|Municipality|Village|Community", pl$feature_type), ]
  if (!setequal(pl$name, towns) || anyDuplicated(pl$name)) {
    stop("each town must give one populated place: ", paste(pl$name, pl$feature_type, collapse = "; "), call. = FALSE)
  }
  saveRDS(list(groups = grp, bc = bc, rivers = lab[c("name")], towns = sf::st_transform(pl[c("name")], 3005)),
          f_layers)
}
ly <- readRDS(f_layers)
rv <- readRDS(file.path("inst", "vignette-data", "segment_map.rds"))$rivers
rv <- rv[rv$order_band >= 7, ]
grp <- merge(ly$groups, tb[c("watershed_group_code", "class_pub", "class_scen")], by = "watershed_group_code")
stopifnot(nrow(grp) == 246L, !anyNA(grp$class_pub), !anyNA(grp$class_scen))

# ---- styles from the registry --------------------------------------------------------------------
reg <- gq::gq_reg_custom(file.path("inst", "cartography", "wet_coverage.csv"))
cls <- function(layer, expect) {
  x <- gq::gq_tmap_classes(reg$layers[[layer]])
  stopifnot(all(expect %in% names(x$values)))
  list(values = x$values[expect], labels = stats::setNames(x$labels, names(x$values))[expect])
}
pal_pub <- cls("coverage_published", c("both", "routed on part", "balance alone"))
scen_lev <- intersect(c("CMIP6 routed", "CMIP5 gridded", "undecided", "part or mixed", "none"), grp$class_scen)
pal_scen <- cls("coverage_scenarios", scen_lev)
lines <- cls("coverage_lines", c("group", "bc", "river"))
ln <- reg$layers$coverage_lines$classification$classes
lb <- reg$layers$coverage_labels
stopifnot(all(unique(grp$class_scen) %in% scen_lev), all(unique(grp$class_pub) %in% names(pal_pub$values)))

# ---- the panels ----------------------------------------------------------------------------------
bb <- sf::st_bbox(ly$bc)
asp <- as.numeric((bb$ymax - bb$ymin) / (bb$xmax - bb$xmin))
sb_km <- 200
sb <- data.frame(x = bb[["xmin"]] + 0.04 * (bb$xmax - bb$xmin), y = bb[["ymin"]] + 0.04 * (bb$ymax - bb$ymin))
sb$xend <- sb$x + sb_km * 1000
xy <- function(x) cbind(sf::st_drop_geometry(x), sf::st_coordinates(x))
rl <- xy(ly$rivers)
rl$label <- sub(" River$", "", rl$name)
tw <- xy(ly$towns)
panel <- function(field, pal, title, scale_bar) {
  p <- ggplot() +
    geom_sf(data = grp, aes(fill = .data[[field]]), colour = lines$values[["group"]], linewidth = 0.1) +
    scale_fill_manual(values = pal$values, labels = pal$labels, breaks = names(pal$values), name = title,
                      drop = FALSE, guide = guide_legend(order = 1)) +
    geom_sf(data = rv, aes(colour = "river"), linewidth = 0.3) +
    scale_colour_manual(values = lines$values["river"], labels = lines$labels["river"], name = NULL,
                        guide = guide_legend(order = 2, override.aes = list(linewidth = 0.8))) +
    geom_sf(data = ly$bc, fill = NA, colour = lines$values[["bc"]], linewidth = 0.3) +
    geom_point(data = tw, aes(X, Y), colour = "#2c3e50", fill = "#2c3e50", size = 0.9, shape = 21, stroke = 0.3) +
    ggrepel::geom_text_repel(data = tw, aes(X, Y, label = name), size = lb$label$size, colour = "#2c3e50",
                             bg.colour = "white", bg.r = lb$label$halo$width, seed = 1, min.segment.length = Inf,
                             box.padding = 0.15, point.padding = 0.1) +
    ggrepel::geom_text_repel(data = rl, aes(X, Y, label = label), size = lb$label$size, colour = lb$label$color,
                             fontface = "italic", bg.colour = "white", bg.r = lb$label$halo$width, seed = 2,
                             min.segment.length = Inf, box.padding = 0.1) +
    coord_sf(xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")], expand = FALSE, datum = NA) +
    theme_void(base_size = 8) +
    theme(legend.position = "bottom", legend.direction = "vertical", legend.box = "vertical",
          legend.box.just = "left", legend.spacing.y = unit(2, "pt"), legend.title = element_text(size = 9.5),
          legend.text = element_text(size = 9), legend.key.size = unit(10, "pt"),
          plot.margin = margin(2, 2, 2, 2))
  if (scale_bar) {
    p <- p + geom_segment(data = sb, aes(x = x, xend = xend, y = y, yend = y), linewidth = 0.8) +
      geom_text(data = sb, aes(x = (x + xend) / 2, y = y, label = paste(sb_km, "km")), vjust = -0.7, size = 3.2)
  }
  p
}
p1 <- panel("class_pub", pal_pub, "Published 1981\u20132010 flow", TRUE)
p2 <- panel("class_scen", pal_scen, "What scenarios build on", FALSE)
w <- 3.5
h <- w * asp + 1.45  # the map's own shape, plus the legend below it
tmp <- c(tempfile(fileext = ".png"), tempfile(fileext = ".png"))
ggsave(tmp[1], p1, width = w, height = h, dpi = 200, bg = "white")
ggsave(tmp[2], p2, width = w, height = h, dpi = 200, bg = "white")
img <- magick::image_append(c(magick::image_read(tmp[1]), magick::image_read(tmp[2])))
# no date chunks, so a render of the same layers writes the same bytes
img <- magick::image_strip(img)
magick::image_set_defines(img, c("png:exclude-chunks" = "date,time"))   # in place; returns NULL
magick::image_write(img, f_png, format = "png")
message("wrote ", f_png)
