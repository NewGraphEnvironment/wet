# /code-check verdict (#188)

mode: branch
ended: enumeration
rounds: 5
inside-fix: yes
reviewed: 638796b7f9522eda60d5c9f0abb0d30c8acbf3ef
set: every value check C reads from #45's cache and script, parsed by round 5: 13 constants and keys, 16 derived columns, lerr, omega_implied, ec, med and verdict() (whose 4 free variables are among them), 13 fit columns, 6 PCIC columns and the row set (54 places), each tied to its source
