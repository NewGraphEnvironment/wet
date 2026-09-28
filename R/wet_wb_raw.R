# Raw annual runoff P - AET (mm) for one AET variant of the ET experiment (#15),
# from upstream means (or cell layers) named as scripts/wb_province.R names
# them. cgiar keeps the stored ro_raw (p - aet per cell before accumulation,
# equal to p_yr - aet_yr within float rounding), so the #11 numbers reproduce
# exactly. Shared by scripts/wb_validate.R and scripts/wb_output.R so the two
# cannot disagree about which column a variant is.
wet_wb_aet_cols <- function() {
  c(cgiar = "aet_yr", lc = "aet_lc", tc = "aet_tc", fu = "aet_fu", cfu = "aet_cfu",
    fu15 = "aet_fu15", fu20 = "aet_fu20", fu35 = "aet_fu35")
}

wet_wb_raw <- function(d, aet = "cgiar") {
  cols <- wet_wb_aet_cols()
  if (length(aet) != 1 || !aet %in% names(cols)) {
    stop("unknown AET variant '", aet, "'; one of ", paste(names(cols), collapse = ", "), call. = FALSE)
  }
  need <- if (aet == "cgiar") "ro_raw" else c("p_yr", cols[[aet]])
  miss <- setdiff(need, names(d))
  if (length(miss)) stop("missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (aet == "cgiar") d[["ro_raw"]] else d[["p_yr"]] - d[[cols[[aet]]]]
}
