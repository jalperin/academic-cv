"""parse.py — parse the plain-text CV into a structured model.

The grammar is intentionally close to plain Markdown:

    ## SECTION
    ### Subsection
    - bullet item               (publications / presentations / appointments)
    BODY | DATE                 (dated list entries)
    BODY | FUNDING | YEARS      (grants)
    LEFT | RIGHT                (education line items)
    plain paragraph             (significance, contributions, prose)

Item *meaning* is resolved per-section at render time; the parser only
captures structure (sections, subsections, and raw item blocks).
"""
from dataclasses import dataclass, field
import re
import yaml


@dataclass
class Item:
    """A raw item block: one or more source lines that belong together."""
    text: str
    is_bullet: bool = False


@dataclass
class Subsection:
    heading: str
    items: list = field(default_factory=list)


@dataclass
class Section:
    title: str          # upper-cased, e.g. "PUBLICATIONS"
    raw_title: str      # as written
    intro: list = field(default_factory=list)        # items before first ###
    subsections: list = field(default_factory=list)  # list[Subsection]


@dataclass
class Document:
    meta: dict = field(default_factory=dict)
    sections: list = field(default_factory=list)


def _split_frontmatter(text):
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            fm = text[3:end].strip()
            body = text[end + 4 :]
            return yaml.safe_load(fm) or {}, body
    return {}, text


def _blocks(lines):
    """Group lines into item blocks separated by blank lines.

    A line beginning with '- ' starts a bullet item; subsequent indented or
    continuation lines (until a blank line) join that block.
    """
    items = []
    buf = []

    def flush():
        if not buf:
            return
        raw = "\n".join(buf).rstrip()
        if not raw.strip():
            buf.clear()
            return
        is_bullet = raw.lstrip().startswith("- ")
        text = raw
        if is_bullet:
            text = re.sub(r"^\s*-\s+", "", raw, count=1)
        # collapse hard-break continuation lines into newlines without markers
        text = "\n".join(l.strip() for l in text.split("\n"))
        items.append(Item(text=text, is_bullet=is_bullet))
        buf.clear()

    for ln in lines:
        if ln.strip() == "":
            flush()
        else:
            buf.append(ln)
    flush()
    return items


def parse(text):
    meta, body = _split_frontmatter(text)
    doc = Document(meta=meta)

    # Split body into ## sections.
    lines = body.split("\n")
    sections = []
    cur = None
    for ln in lines:
        m2 = re.match(r"^##\s+(?!#)(.*)$", ln)
        if m2:
            cur = {"raw": m2.group(1).strip(), "lines": []}
            sections.append(cur)
        elif cur is not None:
            cur["lines"].append(ln)
        # lines before the first ## (there shouldn't be any) are ignored

    for sec in sections:
        raw_title = sec["raw"]
        s = Section(title=raw_title.upper(), raw_title=raw_title)
        # Split section lines into intro + ### subsections.
        intro_lines = []
        subs = []
        cur_sub = None
        for ln in sec["lines"]:
            m3 = re.match(r"^###\s+(.*)$", ln)
            if m3:
                cur_sub = {"heading": m3.group(1).strip(), "lines": []}
                subs.append(cur_sub)
            elif cur_sub is not None:
                cur_sub["lines"].append(ln)
            else:
                intro_lines.append(ln)
        s.intro = _blocks(intro_lines)
        for sub in subs:
            s.subsections.append(Subsection(heading=sub["heading"], items=_blocks(sub["lines"])))
        doc.sections.append(s)

    return doc
