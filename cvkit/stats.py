"""stats.py — year extraction, date-range filtering, and the publication /
presentation counts that feed the two summary boxes.

Stats are computed from the *filtered* model, so the summary boxes can never
disagree with the items actually shown (unlike the old two-pass build).
"""
import re

STATUS_WORDS = ("under review", "in review", "in press", "submitted", "accepted")
NUM = {",": ""}


def extract_years(text):
    """Return (min_year, max_year) found in a string, or None."""
    if not text:
        return None
    years = [int(y) for y in re.findall(r"\b(19|20)\d{2}\b", text)]
    # the regex above only captures the century; redo properly:
    years = [int(y) for y in re.findall(r"\b((?:19|20)\d{2})\b", text)]
    if not years:
        return None
    return (min(years), max(years))


def ranges_overlap(item_years, start, end):
    if start is None and end is None:
        return True
    if not item_years:
        return True  # undated items are always kept
    lo, hi = item_years
    s = start if start is not None else -10**9
    e = end if end is not None else 10**9
    return lo <= e and hi >= s


def year_in_range(year, start, end):
    if year is None:
        return True
    s = start if start is not None else -10**9
    e = end if end is not None else 10**9
    return s <= year <= e


def parse_year(heading):
    m = re.match(r"^\s*((?:19|20)\d{2})\s*$", heading)
    return int(m.group(1)) if m else None


def is_status(heading):
    h = heading.lower()
    return any(w in h for w in STATUS_WORDS)


def parse_tags(item_text):
    """Leading [a, b] -> ['a','b']; returns (tags, remaining_text)."""
    m = re.match(r"^\s*\[([^\]]+)\]\s*", item_text)
    if not m:
        return [], item_text
    tags = [t.strip() for t in m.group(1).split(",") if t.strip()]
    return tags, item_text[m.end():]


def has_tag(tags, name):
    return name in tags


def fmt_commas(n):
    try:
        return f"{int(n):,}"
    except (TypeError, ValueError):
        return str(n)
