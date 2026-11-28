#!/usr/bin/env python3
"""Candidate finder for the research rewrites (#189).

  numbers_check.py [--new research/x.md=copy.md ...] research/a.md [research/b.md ...]

The files named are compared as one set: origin/main's text against the tree's.
(a) LEFT: number tokens whose count fell, less those on lines the diff adds to
    other research files or to planning/archive/*/README.md.
(b) NEW: number tokens whose count rose.
It finds candidates only. It cannot see a stale number carried over unchanged,
and a token found elsewhere proves nothing about the claim around it.
"""
import re
import subprocess
import sys
from collections import Counter

TOKEN = re.compile(r"(?<![\d.])-?\d+(?:\.\d+)*")


def tokens(text):
    text = text.replace("−", "-")
    text = re.sub(r"(?<=\d),(?=\d{3}(?!\d))", "", text)
    return TOKEN.findall(text)


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def added_elsewhere(files):
    diff = git("diff", "--unified=0", "origin/main", "--", "research", "planning/archive")
    keep, out = False, []
    for line in diff.splitlines():
        if line.startswith("+++ "):
            path = line[6:] if line.startswith("+++ b/") else ""
            keep = path not in files and (
                path.startswith("research/")
                or (path.startswith("planning/archive/") and path.endswith("/README.md")))
        elif keep and line.startswith("+"):
            out.append(line[1:])
    return "\n".join(out)


def contexts(text, tok, n=2):
    hits = []
    for i, line in enumerate(text.splitlines(), 1):
        if tok in tokens(line):
            s = line.replace("−", "-")
            at = max(s.replace(",", "").find(tok) - 50, 0)
            hits.append(f"      L{i}: {s[at:at + 120]}")
        if len(hits) == n:
            break
    return "\n".join(hits)


def main(argv):
    swap, files = {}, []
    it = iter(argv)
    for a in it:
        if a == "--new":
            k, v = next(it).split("=", 1)
            swap[k] = v
        else:
            files.append(a)
    if not files:
        sys.exit(__doc__)
    old = "\n".join(git("show", f"origin/main:{f}") for f in files)
    new = "\n".join(open(swap.get(f, f), encoding="utf-8").read() for f in files)
    co, cn = Counter(tokens(old)), Counter(tokens(new))
    left = (co - cn) - Counter(tokens(added_elsewhere(set(files))))
    rose = cn - co
    for title, c, where in (("LEFT", left, old), ("NEW", rose, new)):
        print(f"== {title}: {len(c)} tokens, {sum(c.values())} occurrences")
        for tok in sorted(c):
            print(f"  {tok}  x{c[tok]}  (old {co[tok]}, new {cn[tok]})")
            print(contexts(where, tok))


if __name__ == "__main__":
    main(sys.argv[1:])
