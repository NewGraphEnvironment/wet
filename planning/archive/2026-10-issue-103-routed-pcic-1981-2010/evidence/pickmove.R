old_dir <- "~/Projects/repo/wet/data/wb/e675918817/_pre103/segment"
new_dir <- "~/Projects/repo/wet/data/wb/e675918817/fit_20260717/segment"
f <- sort(basename(list.files(old_dir, "parquet$")))
stopifnot(identical(f, sort(basename(list.files(new_dir, "parquet$")))))
cols <- c("linear_feature_id", "month", "source", "pick", "period")
res <- do.call(rbind, lapply(f, function(x) {
  a <- as.data.frame(arrow::read_parquet(file.path(old_dir, x), col_select = dplyr::all_of(cols)))
  b <- as.data.frame(arrow::read_parquet(file.path(new_dir, x), col_select = dplyr::all_of(cols)))
  stopifnot(identical(a[c("linear_feature_id", "month", "source")], b[c("linear_feature_id", "month", "source")]))
  r <- a$source == "pcic_routed" & a$month == 0L
  data.frame(part = x, to_balance = sum(a$pick[r] & !b$pick[r]), to_routed = sum(!a$pick[r] & b$pick[r]),
             routed_period = paste(unique(b$period[b$source == "pcic_routed"]), collapse = ","),
             balance_period = paste(unique(b$period[b$source == "wet_balance"]), collapse = ","))
}))
print(res, row.names = FALSE)
cat("routed -> balance:", sum(res$to_balance), "; balance -> routed:", sum(res$to_routed), "\n")
