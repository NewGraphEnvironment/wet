# The README figure (#75): the source each segment's default flow (`pick`)
# comes from, on main-flow rivers of order 5 and up across BC. It is the
# segment article's map without its gauges and labels, drawn from the same
# bundled layers, so it never touches the bucket, fwapg or HYDAT.
#
#   Rscript data-raw/readme_figure.R
#
# Reads inst/vignette-data/segment_map.rds (data-raw/segment_vignette_map.R)
# and station_map.rds (the province outline, data-raw/station_vignette_map.R).
# Colours come from inst/cartography/wet_segment.csv through gq. Writes
# man/figures/readme-pick.png on a white background.

devtools::load_all(quiet = TRUE)
library(ggplot2)
sf::sf_use_s2(FALSE)

out <- file.path("man", "figures", "readme-pick.png")
vd <- function(f) file.path("inst", "vignette-data", f)
map <- readRDS(vd("segment_map.rds"))
bc <- readRDS(vd("station_map.rds"))$bc

# assert each class set, because a malformed CSV row adds a layer silently
reg <- gq::gq_reg_custom(file.path("inst", "cartography", "wet_segment.csv"))
classes <- function(layer, expect) {
  x <- gq::gq_tmap_classes(reg$layers[[layer]])
  stopifnot(identical(names(x$values), expect))
  list(values = x$values, labels = stats::setNames(x$labels, names(x$values)))
}
pal_pick <- classes("pick_source", c("pcic_routed", "wet_balance"))
pal_map <- classes("segment_map", "outline")

r <- map$rivers[map$rivers$class != "none", ]
order_width <- c(`5` = 0.12, `6` = 0.22, `7` = 0.35, `8` = 0.55)
r$w <- order_width[as.character(r$order_band)]
stopifnot(!anyNA(r$w), setequal(unique(r$class), names(pal_pick$values)))

asp <- 7 / 6.4
bb <- gq::gq_bbox_aspect(sf::st_bbox(bc), asp = asp)
dx <- bb[["xmax"]] - bb[["xmin"]]
dy <- bb[["ymax"]] - bb[["ymin"]]
sb_km <- max(gq::gq_scale_breaks(bb))
sb <- data.frame(x = bb[["xmin"]] + 0.05 * dx, y = bb[["ymin"]] + 0.05 * dy)
sb$xend <- sb$x + sb_km * 1000

p <- ggplot() +
  geom_sf(data = bc, fill = "white", colour = pal_map$values[["outline"]], linewidth = 0.25) +
  geom_sf(data = r, aes(colour = class, linewidth = w)) +
  scale_linewidth_identity() +
  scale_colour_manual(values = pal_pick$values, labels = pal_pick$labels, name = NULL,
                      guide = guide_legend(override.aes = list(linewidth = 1.6))) +
  geom_segment(data = sb, aes(x = x, xend = xend, y = y, yend = y), linewidth = 1) +
  geom_text(data = sb, aes(x = (x + xend) / 2, y = y, label = paste(sb_km, "km")), vjust = -0.7, size = 3.6) +
  coord_sf(xlim = bb[c("xmin", "xmax")], ylim = bb[c("ymin", "ymax")], expand = FALSE, datum = NA) +
  theme_void() +
  theme(legend.position = "inside", legend.position.inside = c(0.97, 0.97),
        legend.justification = c(1, 1), legend.text = element_text(size = 12),
        legend.background = element_rect(fill = "white", colour = NA),
        plot.background = element_rect(fill = "white", colour = NA),
        panel.border = element_rect(fill = NA, colour = pal_map$values[["outline"]], linewidth = 0.3))

ggsave(out, p, width = 7, height = 7 / asp, dpi = 150, bg = "white")
message("wrote ", out)
