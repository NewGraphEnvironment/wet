#' Calendar months and seasons as date windows
#'
#' The twelve months and four meteorological seasons in the windows format
#' [wet_window_stats()] takes: a name and month-day `start` and `end`, both
#' inclusive. An `end` of `"02-29"` means the last day of February in leap
#' and common years alike.
#'
#' The seasons are named `djf`, `mam`, `jja` and `son` rather than winter,
#' spring and so on. That is deliberate: `cd::cd_seasons()` builds winter
#' from December, January and February of one calendar year, while here
#' `djf` is the contiguous December to February and takes the year of its
#' December, so the two would disagree under the same name.
#'
#' @return `data.frame(window, start, end)` with 16 rows.
#' @examples
#' wet_windows_calendar()
#'
#' # Add a species window to the calendar ones
#' rbind(wet_windows_calendar(),
#'       data.frame(window = "ch_spawning", start = "08-01", end = "09-15"))
#' @export
wet_windows_calendar <- function() {
  last <- c("01-31", "02-29", "03-31", "04-30", "05-31", "06-30", "07-31", "08-31", "09-30",
            "10-31", "11-30", "12-31")
  data.frame(window = c(tolower(month.abb), "djf", "mam", "jja", "son"),
             start = c(sprintf("%02d-01", 1:12), "12-01", "03-01", "06-01", "09-01"),
             end = c(last, "02-29", "05-31", "08-31", "11-30"))
}
