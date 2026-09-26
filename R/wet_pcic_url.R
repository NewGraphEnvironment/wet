#' OPeNDAP URL for one PCIC VIC-GL gridded variable
#'
#' PCIC serves its gridded hydrologic model output (`hydro_model_out`) one
#' variable per file. The historical run is `"TPS_gridded_obs_init"`
#' (PNWNAmet forcing, VICGL-RGM, 1945-2012); scenario runs are named
#' `"<GCM>_<rcp>_<member>"`, e.g. `"CanESM2_rcp85_r1i1p1"` (VICGL, 1945-2099).
#' Every file name carries `1945to2099` regardless of the run's real span.
#'
#' @param variable Character. VIC output variable, e.g. `"RUNOFF"` or
#'   `"BASEFLOW"`.
#' @param run Character. Run identifier. Default is the historical run.
#' @param base Character. Base URL of the `hydro_model_out` data service.
#'   Defaults to option `wet.pcic_base`, else
#'   `https://services.pacificclimate.org/data/hydro_model_out`.
#' @return Character URL of the dataset (no OPeNDAP suffix).
#' @export
#' @examples
#' wet_pcic_url("RUNOFF")
#' wet_pcic_url("BASEFLOW", run = "CanESM2_rcp85_r1i1p1")
wet_pcic_url <- function(variable, run = "TPS_gridded_obs_init",
                         base = getOption("wet.pcic_base",
                           "https://services.pacificclimate.org/data/hydro_model_out")) {
  stopifnot(is.character(variable), length(variable) == 1L, !is.na(variable), nzchar(variable),
            is.character(run), length(run) == 1L, !is.na(run), nzchar(run))
  sprintf("%s/allwsbc.%s.1945to2099.%s.nc", sub("/+$", "", base), run, variable)
}
