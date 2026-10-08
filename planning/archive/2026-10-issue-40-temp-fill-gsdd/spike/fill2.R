# Prototype: open-loop air2stream S_t plus AR(1) departure u_t in a Kalman smoother.
ol_run <- function(p, a) { n <- length(a); x <- numeric(n); x[1] <- max(0, (p[1] + p[2] * a[1]) / p[3])
  for (t in 2:n) x[t] <- max(0, (1 - p[3]) * x[t-1] + p[1] + p[2] * a[t]); x }
ol_fit <- function(y, a) { i <- which(!is.na(y))
  f <- function(th) { p <- c(th[1], th[2], plogis(th[3])); s <- ol_run(p, a); mean((s[i]-y[i])^2) }
  best <- NULL
  for (a3 in c(0.05, 0.15)) { o <- optim(c(0.5, 0.1, qlogis(a3)), f, control = list(maxit = 4000))
    if (is.null(best) || o$value < best$value) best <- o }
  p <- c(best$par[1], best$par[2], plogis(best$par[3])); list(p = p, s = ol_run(p, a)) }
u_run <- function(rho, b, sig, r, ebar, r2, smooth = FALSE) {
  n <- length(r); q <- sig^2; m <- 0; p <- q / (1 - rho^2)
  mp <- pp <- mf <- pf <- numeric(n); ll <- 0
  u <- if (is.null(ebar)) rep(0, n) else b * ebar
  for (t in seq_len(n)) {
    if (t > 1) { mt <- rho * m + u[t]; pt <- rho * rho * p + q } else { mt <- m; pt <- p }
    mp[t] <- mt; pp[t] <- pt; yt <- r[t]
    if (!is.na(yt)) { sv <- pt + r2; v <- yt - mt; k <- pt / sv; m <- mt + k * v; p <- (1 - k) * pt
      ll <- ll - 0.5 * (log(2 * pi * sv) + v * v / sv) } else { m <- mt; p <- pt }
    mf[t] <- m; pf[t] <- p }
  if (!smooth) return(ll)
  ms <- mf; ps <- pf
  for (t in (n - 1):1) { g <- pf[t] * rho / pp[t + 1]; ms[t] <- mf[t] + g * (ms[t + 1] - mp[t + 1]); ps[t] <- pf[t] + g * g * (ps[t + 1] - pp[t + 1]) }
  list(mean = ms, var = ps, fmean = mf) }
u_fit <- function(r, ebar, r2) {
  has_b <- !is.null(ebar)
  nll <- function(th) { v <- -u_run(plogis(th[1]), if (has_b) th[3] else 0, exp(th[2]), r, ebar, r2); if (is.finite(v)) v else 1e10 }
  o <- optim(c(qlogis(0.8), log(0.3), if (has_b) 0), nll, method = "BFGS")
  c(rho = plogis(o$par[1]), sig = exp(o$par[2]), b = if (has_b) o$par[3] else 0) }
# fill a pool: list of stations, each list(date, a, y). Returns per-station list(mean, var, s, fmean)
fill_pool <- function(series, r2 = 0.01, peers = TRUE) {
  st <- names(series)
  ol <- lapply(series, function(z) ol_fit(z$y, z$a))
  res <- lapply(st, function(s) series[[s]]$y - ol[[s]]$s); names(res) <- st
  first <- lapply(st, function(s) u_fit(res[[s]], NULL, r2)); names(first) <- st
  err <- lapply(st, function(s) { r <- res[[s]]; n <- length(r); e <- c(NA, r[-1] - first[[s]][["rho"]] * r[-n])
    lim <- 4 * first[[s]][["sig"]]; setNames(pmin(pmax(e, -lim), lim), as.integer(series[[s]]$date)) })
  names(err) <- st
  out <- lapply(st, function(s) {
    z <- series[[s]]; key <- as.character(as.integer(z$date)); ebar <- NULL
    pe <- setdiff(st, s)
    if (peers && length(pe)) { m <- matrix(vapply(pe, function(p) unname(err[[p]][key]), numeric(length(key))), nrow = length(key))
      cnt <- rowSums(!is.na(m)); ebar <- ifelse(cnt > 0, rowSums(m, na.rm = TRUE) / pmax(cnt, 1), 0)
      if (sum(cnt > 0 & !is.na(z$y)) < 180) ebar <- NULL }
    p <- if (is.null(ebar)) first[[s]] else u_fit(res[[s]], ebar, r2)
    sm <- u_run(p[["rho"]], p[["b"]], p[["sig"]], res[[s]], ebar, r2, smooth = TRUE)
    list(date = z$date, mean = pmax(ol[[s]]$s + sm$mean, 0), sd = sqrt(sm$var), ol = ol[[s]]$s,
         fwd = pmax(ol[[s]]$s + sm$fmean, 0), par = c(ol[[s]]$p, p)) })
  names(out) <- st; out }
