# The 365-day common year that the daily shape (#70) and wet_flow_window()'s
# `doy` share: 29 February is folded into 28 February. wet_month_days() (28.25
# for February, 365.25 in all) is the volume convention of the monthly
# product and stays where it is; these are the day counts of the calendar
# the daily flows are laid on.

# The number of days in each month of a common year
wet_doy_days <- function() {
  stats::setNames(c(31L, 28L, 31L, 30L, 31L, 30L, 31L, 31L, 30L, 31L, 30L, 31L), month.abb)
}

# The month of each day 1-365 of a common year
wet_doy_month <- function() {
  rep(1:12, wet_doy_days())
}

# "MM-DD" of each day 1-365 of a common year
wet_doy_md <- function() {
  format(as.Date("2001-01-01") + 0:364, "%m-%d")
}
