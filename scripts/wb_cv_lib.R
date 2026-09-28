# Shared by scripts/wb_validate.R and scripts/wb_aet_compare.R (#11, #15):
# the calibration stations with their upstream predictors, their blocked-CV
# folds, and the cross-validation procedure. Sourced, not run on its own. The
# caller sets `cal$raw` for the AET variant it scores (wet:::wet_wb_raw()).

devtools::load_all(quiet = TRUE)
stamp <- function(...) message(format(Sys.time(), "%H:%M:%S"), " ", ...)
keys <- list.dirs("data/wb", recursive = FALSE, full.names = TRUE)
keys <- keys[file.exists(file.path(keys, "upstream", "_complete"))]
if (length(keys) != 1) stop("expected one complete province run under data/wb, found ", length(keys))
key_dir <- keys
min_frac <- 0.95  # basin share inside BC and on the grid, to calibrate on

# ---- stations with their upstream predictors --------------------------------------------
s <- readRDS("data/wb/stations.rds")
st <- s$stations[s$stations$accepted, ]
# Basins carry columns only for the zones present in them: fill the rest with
# share 0 before stacking.
up <- lapply(list.files(file.path(key_dir, "upstream"), "\\.rds$", full.names = TRUE), function(f) {
  x <- readRDS(f)
  x[x$watershed_feature_id %in% st$watershed_feature_id, ]
})
up <- up[vapply(up, nrow, 1L) > 0]  # basins with no stations
all_cols <- unique(unlist(lapply(up, names)))
up <- do.call(rbind, lapply(up, function(x) {
  for (k in setdiff(all_cols, names(x))) x[[k]] <- 0
  x[all_cols]
}))
cols_up <- setdiff(names(up), c("wscode", "localcode", "area_m2"))
zc <- grep("^zp?[0-9]+$", cols_up, value = TRUE)
st <- merge(st, up[cols_up], by = "watershed_feature_id")
st$area_km2 <- st$upstream_area_m2 / 1e6
st$area_ratio_fwa <- st$area_km2 / st$drainage_area_gross_km2

# observed runoff in mm over the accumulated FWA area (decision 9)
mon <- s$monthly
days <- c(365.25, wet_month_days())
mon$area_m2 <- st$upstream_area_m2[match(mon$station_number, st$station_number)]
mon <- mon[!is.na(mon$area_m2), ]
mon$obs_mm <- mon$q_m3s * days[mon$month + 1] * 86400 / mon$area_m2 * 1000
st$obs <- mon$obs_mm[mon$month == 0][match(st$station_number, mon$station_number[mon$month == 0])]
for (m in 1:12) {
  i <- mon$month == m
  st[[sprintf("share_%02d", m)]] <- mon$share[i][match(st$station_number, mon$station_number[i])]
}

cal <- st[st$bc_fraction >= min_frac & st$coverage >= min_frac & !is.na(st$obs), ]
# a zone no calibration station touches carries no information: drop it, so
# it gets no adjustment everywhere (as in scripts/wb_output.R)
zc_all <- sub("^z", "", grep("^z[0-9]+$", names(cal), value = TRUE))
unseen <- zc_all[colSums(cal[paste0("z", zc_all)]) == 0]
cal <- cal[setdiff(names(cal), c(paste0("z", unseen), paste0("zp", unseen)))]
z_only <- grep("^z[0-9]+$", names(cal), value = TRUE)
cal$zone <- sub("^z", "", z_only)[max.col(as.matrix(cal[z_only]), ties.method = "first")]
cal$area_class <- cut(cal$area_km2, c(0, 100, 1000, 10000, Inf),
                      labels = c("<100 km2", "100-1000", "1000-10000", ">10000"))
stamp(nrow(st), " accepted stations with predictors; ", nrow(cal), " to calibrate on")

# ---- cross-validation --------------------------------------------------------------------
folds <- wet_cv_folds(data.frame(station_number = cal$station_number, wscode = cal$wscode,
                                 localcode = cal$localcode, upstream_area_km2 = cal$area_km2))
loo <- wet_cv_folds(data.frame(station_number = cal$station_number, wscode = cal$wscode,
                               localcode = cal$localcode, upstream_area_km2 = cal$area_km2),
                    block = "station")
cal <- merge(cal, folds, by = "station_number")
# Each fold runs the whole procedure on its training stations, pooling
# included (decided from locations only), which is the honest simulation of
# predicting an ungauged basin. The report counts held-out stations whose
# zone was pooled in their fold, and predictions floored to 0.
pooled <- wet_wb_pooled(cal)

variants <- c("other", "none")
# annual only, one variant: held-out predictions for a fold assignment
cv_annual <- function(d, fold, variant) {
  ann <- rep(NA_real_, nrow(d))
  for (f in unique(fold)) {
    tr <- fold != f
    ann[!tr] <- wet_wb_adjust(wet_wb_fit(d[tr, ], pooled_adjust = variant), d[!tr, ])
  }
  ann
}
mae <- function(obs, mod) mean(abs(100 * (mod - obs) / obs), na.rm = TRUE)
# choose how pooled zones are adjusted by blocked CV inside the stations given
choose_variant <- function(d) {
  inner <- substr(d$station_number, 1, 4)
  m <- vapply(variants, function(v) mae(d$obs, cv_annual(d, inner, v)), numeric(1))
  variants[which.min(m)]
}
# held-out annual and monthly predictions; each outer fold runs the whole
# procedure on its training stations: pooling from their locations, and the
# pooled-zone variant chosen by an inner blocked CV (plan decision 5)
predict_cv <- function(d, fold, variant = "nested") {
  ann <- rep(NA_real_, nrow(d))
  raw_adj <- rep(NA_real_, nrow(d))
  was_pooled <- rep(FALSE, nrow(d))
  chosen <- character()
  sh <- matrix(NA_real_, nrow(d), 12)
  for (f in unique(fold)) {
    tr <- fold != f
    v <- if (variant == "nested") choose_variant(d[tr, ]) else variant
    chosen <- c(chosen, v)
    fit <- wet_wb_fit(d[tr, ], pooled_adjust = v)
    ann[!tr] <- wet_wb_adjust(fit, d[!tr, ])
    raw_adj[!tr] <- wet_wb_adjust(fit, d[!tr, ], floor = FALSE)
    was_pooled[!tr] <- d$zone[!tr] %in% fit$pooled
    sf <- wet_share_fit(d[tr, ])
    sh[!tr, ] <- wet_share_predict(sf, d[!tr, ])
  }
  list(ann = ann, share = sh, n_floored = sum(raw_adj < 0), n_pooled = sum(was_pooled),
       was_pooled = was_pooled,
       chosen = table(factor(chosen, levels = variants)))
}
long <- function(d, ann, share) {
  obs_m <- as.matrix(d[sprintf("share_%02d", 1:12)]) * d$obs
  rbind(data.frame(station_number = d$station_number, month = 0L, obs = d$obs, mod = ann),
        data.frame(station_number = rep(d$station_number, 12), month = rep(1:12, each = nrow(d)),
                   obs = as.vector(obs_m), mod = as.vector(share * ann)))
}
groups <- cal[c("station_number", "nesting", "zone", "area_class")]
groups$lake <- ifelse(cal$lake %in% TRUE, "lake outlet", "not lake outlet")

source("scripts/wb_score_md5.R")  # score_code_md5
