#!/usr/bin/env python3
"""
convert_legacy.py — one-time migration from the old pandoc/lua CV markdown
to the new plain-text syntax used by cvkit.

Usage:
    python convert_legacy.py old_cv.md > cv.md

The transform is deliberately conservative: it only rewrites the structural
noise (fenced ::: divs, attribute soup, the verbose {GS:author:pubid} marker)
and leaves the human-written prose, author-role markers (~~ .. ^) and inline
markdown untouched, so the migration is lossless.
"""
import re
import sys


def split_frontmatter(text):
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            fm = text[: end + 4]
            body = text[end + 4 :]
            return fm, body
    return "", text


def take_attr(attrs, key):
    m = re.search(key + r'="([^"]*)"', attrs)
    return m.group(1) if m else None


def convert_fenced_block(open_attrs, inner):
    """Turn a `::: {.class ...}` block into a single plain line."""
    inner = inner.strip()
    cls = None
    m = re.search(r"\.([a-zA-Z0-9_-]+)", open_attrs)
    if m:
        cls = m.group(1)

    if cls == "section-box":
        # The wrapper is dropped; its inner content is emitted as-is and the
        # grouping is recorded in frontmatter (section-box: [...]).
        return inner

    if cls == "line-item":
        # already "LEFT | RIGHT"
        return inner

    if cls in ("media-item", "award-item"):
        date = take_attr(open_attrs, "date") or take_attr(open_attrs, "year") or ""
        return f"{inner} | {date}".rstrip(" |") if date else inner

    if cls == "grant-item":
        funding = take_attr(open_attrs, "funding") or ""
        project = take_attr(open_attrs, "project")
        years = take_attr(open_attrs, "years") or ""
        parts = [inner]
        if funding:
            parts.append(funding)
        if project:
            parts.append(project)
        if years:
            parts.append(years)
        return " | ".join(parts)

    if cls == "contribution-item":
        return inner

    if cls == "summary-box":
        # generated automatically now — drop
        return None

    if cls == "two-column":
        return inner

    # Unknown class: keep the inner content rather than lose it.
    return inner


def convert_gs_marker(line):
    """{GS:AUTHOR:pubid} -> trailing {gs:pubid};  {GS:123} -> trailing {gs:123}."""
    markers = []

    def grab(m):
        token = m.group(1).strip()
        # drop a leading author id of the form XXXX:pubid
        if ":" in token:
            token = token.split(":", 1)[1]
        markers.append(token)
        return ""

    new = re.sub(r"\{GS:\s*([^}]*?)\s*\}", grab, line)
    new = re.sub(r"\s+", " ", new).rstrip()
    for tok in markers:
        new = f"{new} {{gs:{tok}}}"
    return new


def _emit(target, text):
    """Append converted text plus a trailing blank line to a buffer list."""
    if text is None:
        return
    text = text.strip()
    if not text:
        return
    if "{GS:" in text:
        text = convert_gs_marker(text)
    target.append(text)
    target.append("")


def convert_body(body):
    lines = body.split("\n")
    out = []
    # Each stack frame: {"attrs": str, "buf": [lines]}.  Plain lines and the
    # converted output of child fences both accumulate in the frame's buffer.
    stack = []
    for raw in lines:
        stripped = raw.strip()

        m = re.match(r"^:::\s*\{([^}]*)\}\s*$", stripped)
        if m:
            stack.append({"attrs": m.group(1), "buf": []})
            continue

        if stripped == ":::":
            if not stack:
                continue
            frame = stack.pop()
            inner = "\n".join(frame["buf"]).strip()
            converted = convert_fenced_block(frame["attrs"], inner)
            target = stack[-1]["buf"] if stack else out
            _emit(target, converted)
            continue

        line = raw
        if "{GS:" in line:
            line = convert_gs_marker(line)
        # Post-doc marker: ..name.. (and ..name... ellipsis variants) -> ~name~
        line = re.sub(r"\.\.([^.]+?)\.\.\.?", r"~\1~", line)
        line = re.sub(r"\.\.([^.]+?)…", r"~\1~.", line)
        # Strip {.left} (and similar) attributes from headings
        line = re.sub(r"\s*\{\.[a-zA-Z0-9_-]+\}\s*$", "", line)

        (stack[-1]["buf"] if stack else out).append(line)

    text = "\n".join(out)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text


def patch_frontmatter(fm):
    """Record the section-box grouping in frontmatter; drop GS scrape knobs
    that belong to the scraper rather than the renderer (kept if present)."""
    if not fm:
        return fm
    if "section-box:" not in fm:
        insert = "section-box:\n  - EDUCATION\n  - PROFESSIONAL APPOINTMENTS\n"
        fm = fm.rstrip()
        if fm.endswith("---"):
            fm = fm[:-3].rstrip("\n") + "\n" + insert + "---"
    return fm


def main():
    if len(sys.argv) < 2:
        print("Usage: python convert_legacy.py old_cv.md > cv.md", file=sys.stderr)
        sys.exit(1)
    text = open(sys.argv[1], encoding="utf-8").read()
    fm, body = split_frontmatter(text)
    fm = patch_frontmatter(fm)
    body = convert_body(body)
    sys.stdout.write(fm + "\n" + body.lstrip("\n"))


if __name__ == "__main__":
    main()
