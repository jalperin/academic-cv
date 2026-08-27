#!/usr/bin/env python3
"""simplify_citations.py — remove redundant citation markers.

Under the auto-match model, publications resolve their Scholar citation count
by title automatically, so most lines need no marker at all. This script strips
a marker from a publication line whenever removing it yields the same chip, and
keeps a marker only where it changes the result:

    {gs}            always redundant on a publication  -> removed
    {gs:CLUSTER}    kept only if auto-match would differ (ambiguous titles)
    {gs:NUMBER}     literal count                       -> kept
    {gs:none}       suppression                         -> kept

Presentation lines are left untouched (they are not auto-matched).

Usage:
    python simplify_citations.py [cv.md] [--dry-run]
"""
import csv
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cvkit.match import CitationMatcher  # noqa: E402
from cvkit.parse import _split_frontmatter  # noqa: E402


def load_matcher(base_dir, meta):
    path = os.path.join(base_dir, meta.get("gs_csv", "gs_citations.csv"))
    rows, cites = [], {}
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            pid = (row.get("pub_id") or "").strip()
            if not pid:
                continue
            cluster = pid.split(":", 1)[1] if ":" in pid else pid
            n = int(row.get("num_citations") or 0)
            cites[cluster] = n
            rows.append({"cluster": cluster, "citations": n, "title": row.get("title") or ""})
    return CitationMatcher(rows), cites


def clean_for_match(line):
    line = re.sub(r"\{gs(?::[^}]*)?\}", "", line)
    line = re.sub(r"^\s*-\s*\[[^\]]*\]\s*", "", line)
    line = re.sub(r"^\s*-\s*", "", line)
    return line


def auto_chip(matcher, line):
    best, ambiguous, _ = matcher.match(clean_for_match(line))
    if best is None or ambiguous or best.citations <= 0:
        return None
    return best.citations


def main():
    dry = "--dry-run" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path = args[0] if args else "cv.md"
    base_dir = os.path.dirname(os.path.abspath(path)) or "."

    text = open(path, encoding="utf-8").read()
    meta, _ = _split_frontmatter(text)
    matcher, cites = load_matcher(base_dir, meta)

    removed = kept = literal = suppress = 0
    kept_ids = []
    section = None
    out_lines = []

    for line in text.split("\n"):
        h = re.match(r"^##\s+(?!#)(.*)$", line)
        if h:
            section = h.group(1).strip().upper()
        m = re.search(r"\{gs(?::\s*([^}]*?))?\s*\}", line)
        if not m or section != "PUBLICATIONS":
            out_lines.append(line)
            continue

        token = (m.group(1) or "").strip()
        strip = False
        if token == "":                       # bare {gs}: auto-match covers it
            strip = True
            removed += 1
        elif token.isdigit():                 # literal count: keep
            literal += 1
        elif token in ("none", "-", "skip"):  # suppression: keep
            suppress += 1
        else:                                 # explicit cluster override
            want = cites.get(token) or None
            if auto_chip(matcher, line) == want and want is not None:
                strip = True
                removed += 1
            else:
                kept += 1
                kept_ids.append((token, clean_for_match(line).strip()[:60]))

        if strip:
            line = (line[:m.start()] + line[m.end():])
            line = re.sub(r"\s+$", "", line)
        out_lines.append(line)

    result = "\n".join(out_lines)
    if not dry:
        open(path, "w", encoding="utf-8").write(result)

    print(f"{'(dry-run) ' if dry else ''}stripped redundant markers in {path}")
    print(f"  {removed} markers removed (auto-match reproduces them)")
    print(f"  {kept} explicit {{gs:CLUSTER}} kept (auto-match would differ)")
    print(f"  {literal} literal {{gs:N}} and {suppress} {{gs:none}} kept")
    if kept_ids:
        print("  explicit ids retained on:")
        for tok, ln in kept_ids:
            print(f"    - {{gs:{tok}}}  {ln}")


if __name__ == "__main__":
    main()
