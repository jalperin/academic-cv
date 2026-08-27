#!/usr/bin/env python3
"""cv.py — command-line interface for building the CV.

Examples:
    python cv.py                                   # full CV -> index.html
    python cv.py --start-year 2020                 # 2020-present
    python cv.py --start-year 2019 --end-year 2023 # 2019-2023
    python cv.py -i cv.md -o build/cv-2020.html --start-year 2020
"""
import argparse
import os
import sys

import cvkit


def _update_scholar(input_path, base_dir):
    """Run update_scholar.py to refresh gs_citations.csv / gs_author_stats.yaml.

    Requires the 'scholarly' and 'python-frontmatter' packages and network
    access. On any failure we warn and fall back to the existing data rather
    than blocking the build.
    """
    import subprocess
    import importlib.util
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "update_scholar.py")
    if not os.path.exists(script):
        print("  (update-scholar: update_scholar.py not found; using existing data)")
        return
    missing = [m for m in ("scholarly", "frontmatter") if importlib.util.find_spec(m) is None]
    if missing:
        print(f"  (update-scholar needs: pip install {' '.join('python-frontmatter' if m=='frontmatter' else m for m in missing)}")
        print("   building with existing data)")
        return
    print("Refreshing Google Scholar data (this can take a few minutes)…")
    try:
        r = subprocess.run([sys.executable, script, os.path.abspath(input_path)],
                           cwd=base_dir)
        if r.returncode != 0:
            print("  (update-scholar failed; building with existing data)")
        else:
            print("  Scholar data refreshed.")
    except Exception as e:  # pragma: no cover
        print(f"  (update-scholar error: {e}; building with existing data)")


def main(argv=None):
    ap = argparse.ArgumentParser(description="Build a styled academic CV from markdown.")
    ap.add_argument("-i", "--input", default="cv.md", help="markdown source (default: cv.md)")
    ap.add_argument("-o", "--output", default="index.html", help="output HTML (default: index.html)")
    ap.add_argument("--start-year", type=int, default=None)
    ap.add_argument("--end-year", type=int, default=None)
    ap.add_argument("--citations-report", action="store_true",
                    help="print how each citation marker resolved, and flag any that need attention")
    ap.add_argument("--update-scholar", action="store_true",
                    help="refresh Scholar citation data (runs update_scholar.py) before building")
    args = ap.parse_args(argv)

    if not os.path.exists(args.input):
        ap.error(f"input file not found: {args.input}")

    base_dir = os.path.dirname(os.path.abspath(args.input)) or "."

    if args.update_scholar:
        _update_scholar(args.input, base_dir)

    md = open(args.input, encoding="utf-8").read()
    report = [] if args.citations_report else None
    html = cvkit.build(md, base_dir=base_dir, start=args.start_year, end=args.end_year,
                       report=report)

    out_dir = os.path.dirname(os.path.abspath(args.output))
    os.makedirs(out_dir, exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html)

    rng = ""
    if args.start_year or args.end_year:
        rng = f"  [{args.start_year or 'all'}–{args.end_year or 'present'}]"
    size = os.path.getsize(args.output) / 1024
    print(f"Built {args.output}  ({size:.0f} KB){rng}")

    if report is not None:
        _print_report(report)


def _print_report(report):
    from collections import Counter
    kinds = Counter(r["kind"] for r in report)
    flagged = [r for r in report if r["flag"]]
    print("\nCitation report")
    print(f"  markers resolved: {len(report)}  "
          + "  ".join(f"{k}={v}" for k, v in sorted(kinds.items())))
    if not flagged:
        print("  no markers need attention.")
        return
    print(f"  {len(flagged)} need attention:")
    for r in flagged:
        cid = f" [{r['cluster']}]" if r["cluster"] else ""
        cites = f" {r['citations']} cites" if r["citations"] is not None else ""
        score = f" score={r['score']}" if r["score"] is not None else ""
        print(f"    - {r['flag']}{cid}{cites}{score}")
        print(f"        {r['line']}")


if __name__ == "__main__":
    main()
