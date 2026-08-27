"""match.py — join a publication line to the author's own Google Scholar
publications by title similarity.

The candidate pool is small and author-specific (~160 of the author's own
papers), which is what makes title matching reliable: a distinctive title
matches even through typos because the rest of the string is identical and
there is only one plausible candidate.

No external dependencies; uses difflib for fuzzy token comparison.
"""
import re
import unicodedata
from difflib import SequenceMatcher

# Confidence thresholds on the token-coverage score (fraction of the Scholar
# title's significant words found in the CV line).
HIGH = 0.85     # apply silently
REVIEW = 0.70   # apply, but list in the report for a human to eyeball
AMBIGUOUS_GAP = 0.05  # top two candidates this close -> flag as ambiguous

_STOP = {
    "the", "a", "an", "of", "and", "or", "for", "to", "in", "on", "with",
    "at", "by", "from", "as", "is", "are", "how", "why", "what", "we",
    "do", "does", "it", "its", "into", "not", "no", "over", "under",
}


def normalize(text):
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _sig_tokens(norm):
    return [t for t in norm.split() if len(t) >= 3 and t not in _STOP]


class Candidate:
    __slots__ = ("cluster", "citations", "title", "score")

    def __init__(self, cluster, citations, title, score):
        self.cluster = cluster
        self.citations = citations
        self.title = title
        self.score = score


class CitationMatcher:
    def __init__(self, rows):
        """rows: iterable of dicts with keys cluster, citations, title."""
        self.entries = []
        for r in rows:
            title = r.get("title") or ""
            norm = normalize(title)
            toks = _sig_tokens(norm)
            if toks:
                self.entries.append((r["cluster"], int(r.get("citations") or 0), title, set(toks)))

    @staticmethod
    def _coverage(title_tokens, line_tokens):
        """Fraction of title tokens present in the line (fuzzy on each token)."""
        if not title_tokens:
            return 0.0
        found = 0
        for t in title_tokens:
            if t in line_tokens:
                found += 1
                continue
            # fuzzy: tolerate a typo against any single line token
            if any(len(l) >= 4 and SequenceMatcher(None, t, l).ratio() >= 0.85
                   for l in line_tokens):
                found += 1
        return found / len(title_tokens)

    def match(self, line_text):
        """Return (best: Candidate|None, ambiguous: bool, runner_up: Candidate|None)."""
        line_tokens = set(_sig_tokens(normalize(line_text)))
        if not line_tokens:
            return None, False, None
        scored = []
        for cluster, citations, title, ttoks in self.entries:
            s = self._coverage(ttoks, line_tokens)
            if s >= REVIEW:
                scored.append(Candidate(cluster, citations, title, s))
        if not scored:
            return None, False, None
        scored.sort(key=lambda c: c.score, reverse=True)
        best = scored[0]
        runner = scored[1] if len(scored) > 1 else None
        ambiguous = runner is not None and (best.score - runner.score) < AMBIGUOUS_GAP
        return best, ambiguous, runner
