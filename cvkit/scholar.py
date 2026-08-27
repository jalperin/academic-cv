"""scholar.py — load Google Scholar data scraped by update_scholar.py.

Two inputs, both optional:
  * gs_citations.csv      per-publication citation counts (key: pub_id)
  * gs_author_stats.yaml  author-level totals (citations, h-index, ...)

Publication markers in the markdown are:
  {gs}            resolve this line's citation count by title match
  {gs:CLUSTERID}  explicit override (use this Scholar cluster)
  {gs:NUMBER}     literal count
  {gs:none}       suppress (never show a chip here)
"""
import csv
import os
import yaml

from .match import CitationMatcher


class Scholar:
    def __init__(self, citations=None, author_stats=None, author_id="", rows=None):
        self.citations = citations or {}        # cluster_id -> int
        self.author_stats = author_stats or {}
        self.author_id = author_id
        self.rows = rows or []                  # [{cluster, citations, title}]
        self._matcher = None

    @classmethod
    def load(cls, meta, base_dir="."):
        author_id = str(meta.get("gs_author_id", "") or "")
        citations = {}
        rows = []
        csv_path = meta.get("gs_csv")
        if csv_path:
            full = os.path.join(base_dir, csv_path)
            if os.path.exists(full):
                with open(full, newline="", encoding="utf-8") as f:
                    for row in csv.DictReader(f):
                        pid = (row.get("pub_id") or "").strip()
                        if not pid:
                            continue
                        cluster = pid.split(":", 1)[1] if ":" in pid else pid
                        try:
                            n = int(row.get("num_citations") or 0)
                        except ValueError:
                            n = 0
                        citations[cluster] = n
                        rows.append({"cluster": cluster, "citations": n,
                                     "title": row.get("title") or ""})

        author_stats = {}
        stats_path = meta.get("gs_author_stats")
        if stats_path:
            full = os.path.join(base_dir, stats_path)
            if os.path.exists(full):
                with open(full, encoding="utf-8") as f:
                    author_stats = yaml.safe_load(f) or {}

        return cls(citations, author_stats, author_id, rows)

    @property
    def matcher(self):
        if self._matcher is None:
            self._matcher = CitationMatcher(self.rows)
        return self._matcher

    def lookup(self, token):
        """Resolve an explicit {gs:...} token to a count, or None to omit."""
        if token is None:
            return None
        token = token.strip()
        if token.isdigit():                 # literal count
            n = int(token)
            return n if n > 0 else None
        n = self.citations.get(token)       # cluster id
        if n is None:
            return None
        return n if n > 0 else None
