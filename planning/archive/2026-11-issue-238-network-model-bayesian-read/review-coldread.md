# Cold read of the two files, as an outside modeller (2026-11-27)

A Plan agent (no project context) read only `research/temperature_network_model.md` (F1) and `research/temperature_bayesian_alignment.md` (F2), as a statistician who builds stream-network models, and returned 25 findings. Each was probed before folding; the partition-factor claim against SSN2 0.4.0's vignette ("the partition factor ensures that observations from separate stream networks are completely uncorrelated"), the leak-free pool against `share_related()` (`up | t(up)`: flow-connected pairs only).

| # | finding | verdict | action |
|---|---|---|---|
| 1 | no way to get the files | owner's call | reported to the owner: whether and how the files are offered is his wording |
| 2 | the response variable and time structure unstated | confirmed | F1 questions: what is modelled (daily or weekly temperature, or air2stream's parameters) and its space-time structure |
| 3 | SSN2 fits by likelihood, gives no posterior draws | confirmed | F1: SSN2 named for what it does; draws for GSDD named as needing joint daily series, whatever the method |
| 4 | a partition factor removes cross-network covariance; a random effect is within-network | confirmed (SSN2 vignette) | F1 outlets question rewritten: Euclidean component or shared covariates carry what networks share |
| 5 | leak-free pool leaves sister tributaries in, which tail-down borrows from | confirmed | F1 testing and F2 pooling section: it removes flow-connected neighbours only |
| 6 | pool difference also reflects a smaller training set | confirmed | F1: "about", with the confound stated |
| 7 | ordinary GP kernels need not be valid on stream distance | confirmed | F2: tail-up and tail-down named as the constructions built for it |
| 8 | fixed statistic against an open error measure | confirmed | F1: the statistic is fixed for comparison with the baseline; further measures open |
| 9 | counts of stations, pairs, segments | declined | the owner's rule: no count that will move; the research files hold the numbers |
| 10 | GSDD undefined in F1; weekly output cannot feed a daily rule | confirmed | F1 defines GSDD by gsdd's rule; question on how weekly results become degree days |
| 11 | "floor" unclear; the benchmark is in-sample | confirmed | F1: a reference for predictions of the three parameters, not a bound |
| 12 | #223 as a template reads as in-house and fixing the shape | confirmed | F1: one such test, not a template |
| 13 | "a third" misread from a threefold error | confirmed | F2: stated as about three times the error |
| 14 | no interval on the neighbour differences | confirmed | F2: says none is given |
| 15 | which candidate the rule chose | confirmed | F2: the regression, which the rule chose |
| 16 | main-flow tree and AFV weighting undefined | confirmed | F1: what the tree keeps; AFV from upstream area |
| 17–19 | jargon (air2stream terms, holdout terms, issue numbers, WSC) | confirmed in part | F1: one-line definitions of air2stream and its fitted terms, the holdout terms where first used, WSC expanded; issue numbers stay as GitHub autolinks |
| 20 | "not yet anyone's work" reads as a gap list | declined for now | the owner's approved wording; becomes an issue number once the traits issue is filed |
| 21 | checks assume a Bayesian method | confirmed | F1: equivalents for another method |
| 22 | holdout is river gauges only | confirmed | F1 testing: small streams untested until loggers (#215) |
| 23 | F2 jargon: cred, store, citekeys, "the owner" | in part | "set by the owner" → "set before any score"; provenance line kept |
| 24 | flat-prior interval treats the stations' estimates as exact | confirmed | F2: caveat in prose and row |
| 25 | no contact or first step | owner's call | reported to the owner |
