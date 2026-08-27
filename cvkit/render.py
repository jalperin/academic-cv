"""render.py — turn the parsed Document into the CV's HTML body.

Rendering is section-driven: the section title selects a renderer, which is
why the markdown body can stay close to plain text. Statistics for the two
summary boxes are computed from the already-filtered model.
"""
import datetime
from .inline import render_inline
from . import stats as S

ICONS = {
    "peer-reviewed": "juanicons-colour-final-09.png",
    "peer-review": "juanicons-colour-final-09.png",
    "invited": "juanicons-colour-final-29.png",
    "journal": "juanicons-colour-final-12.png",
    "conference": "juanicons-colour-final-28.png",
    "book": "juanicons-colour-final-17.png",
    "chapter": "juanicons-colour-final-18.png",
    "plenary": "juanicons-colour-final-19.png",
    "keynote": "juanicons-colour-final-16.png",
    "dataset": "juanicons-colour-final-13.png",
}
BIG_ICON = {"peer-reviewed", "peer-review", "invited"}

CURRENT_YEAR = datetime.date.today().year


class Renderer:
    def __init__(self, doc, scholar, start=None, end=None):
        self.doc = doc
        self.sch = scholar
        self.start = start
        self.end = end
        self.owner = str(doc.meta.get("name_short") or "Alperin, J.P.")
        self.filtering = start is not None or end is not None
        self.report = []  # citation-resolution records for --citations-report

    # ---- citation resolution ------------------------------------------
    def _resolve_citation(self, token, line_text, explicit=True):
        """Resolve a citation marker to a count (or None). Records a report row.

        explicit=False means the line had no marker and we are auto-matching a
        publication; a miss there is normal (editorials, datasets, talks) and is
        not flagged.
        """
        from .match import HIGH
        rec = {"line": line_text[:70], "kind": None, "token": token,
               "cluster": None, "citations": None, "score": None, "flag": None,
               "explicit": explicit}

        if token is not None:
            token = token.strip()
        if token in ("none", "-", "skip"):        # explicit suppress
            rec["kind"] = "suppressed"
            self.report.append(rec)
            return None
        if token:                                  # explicit override or literal
            if token.isdigit():
                rec["kind"] = "literal"
                rec["citations"] = int(token)
            else:
                rec["kind"] = "override"
                rec["cluster"] = token
                rec["citations"] = self.sch.citations.get(token)
                if rec["citations"] is None:
                    rec["flag"] = "override id not found in CSV"
            self.report.append(rec)
            return self.sch.lookup(token)

        # Resolve by title (bare {gs}, or a publication with no marker).
        best, ambiguous, runner = self.sch.matcher.match(line_text)
        rec["kind"] = "auto" if not explicit else "matched"
        if best is None:
            if explicit:
                rec["flag"] = "no title match — remove {gs} or add {gs:CLUSTER}"
                self.report.append(rec)
            return None
        rec["cluster"] = best.cluster
        rec["score"] = round(best.score, 2)
        if best.citations <= 0:
            rec["kind"] += " (0 cites)"
            if explicit:
                self.report.append(rec)
            return None
        rec["citations"] = best.citations
        if ambiguous:
            rec["flag"] = f"ambiguous with {runner.cluster} (score {round(runner.score,2)})"
        elif best.score < HIGH:
            rec["flag"] = "low confidence — review"
        self.report.append(rec)
        return best.citations

    # ---- inline helper -------------------------------------------------
    def inl(self, text):
        return render_inline(text, self.owner)

    # ---- summary box ---------------------------------------------------
    def summary_title(self):
        if not self.filtering:
            return "SUMMARY"
        if self.start and self.end:
            return f"{self.start}\u2013{self.end} SUMMARY"
        if self.start:
            return f"SINCE {self.start} SUMMARY"
        return f"THROUGH {self.end} SUMMARY"

    def summary_box(self, col1, col2):
        """col1/col2 = ((value, label), (value, label))."""
        def column(pairs, float_top=False):
            (v1, l1), (v2, l2) = pairs
            top = ' float-right' if float_top else ''
            bot = '' if float_top else ' float-right'
            return f"""        <div class="display-flex">
          <div class="display-block margin-right-10">
            <div class="height-25{top}"><strong class="font-size-15 align-items-center">{v1}</strong></div>
            <div class="height-25{bot}"><strong class="font-size-15 align-items-center">{v2}</strong></div>
          </div>
          <div class="display-block">
            <div class="height-25"><span class="font-size-12 align-items-center">{l1}</span></div>
            <div class="height-25"><span class="font-size-12 align-items-center">{l2}</span></div>
          </div>
        </div>"""
        return f"""    <div class="summary-title">{self.summary_title()}</div>
    <div class="summary-box">
      <div class="display-flex justify-content-around">
{column(col1, float_top=True)}
{column(col2, float_top=False)}
      </div>
    </div>
"""

    # ---- research sidebar & legend ------------------------------------
    def research_sidebar(self):
        interests = self.doc.meta.get("research-interests") or []
        if not interests or str(self.doc.meta.get("sidebar", "")).lower() != "true":
            return ""
        lis = "\n".join(f"    <li>{self.inl(str(i))}</li>" for i in interests)
        return (
            '<div class="research-box width-30">\n'
            "  <h2>RESEARCH<br/>INTERESTS</h2>\n  <ul>\n" + lis + "\n  </ul>\n</div>\n"
        )

    def legend(self):
        def row(left_html, label):
            return (f'      <div class="display-flex align-items-center margin-top-5">'
                    f'{left_html}<span class="font-size-12">{label}</span></div>')
        def icon(name):
            return f'<img src="Links/{ICONS[name]}" style="width: 20px; height: 20px"/>'
        cat_order = ["peer-reviewed", "invited", "journal", "conference",
                     "book", "chapter", "plenary", "keynote", "dataset"]
        cat_labels = {"peer-reviewed": "peer reviewed", "invited": "invited",
                      "journal": "journal", "conference": "conference",
                      "book": "book", "chapter": "chapter", "plenary": "plenary",
                      "keynote": "keynote", "dataset": "dataset"}
        cat_rows = "\n".join(row(icon(n), cat_labels[n]) for n in cat_order)
        return f"""  <div class="margin-left-20 width-20">
    <h3 class="text-align-center">LEGEND</h3>
    <div class="font-size-14">AUTHORSHIP</div>
    <div class="display-block">
{row('<img src="Links/juanicons-colour-final-05.png"/>', "corresponding author")}
{row('<span class="wavy-line">w l</span>', "student")}
{row('<span class="dotted-mark-line">w l</span>', "post doc")}
    </div>
    <div class="font-size-14 margin-top-15">CATEGORY</div>
    <div class="display-block">
{cat_rows}
    </div>
  </div>
"""

    # ---- generic item helpers -----------------------------------------
    def _split_pipes(self, text):
        return [p.strip() for p in text.split("|")]

    def swap_item(self, body, date):
        return (f'<div class="swap-item">\n'
                f'<span class="swap-text">{self.inl(body)}</span>\n'
                f'<span class="swap-fill"></span>\n'
                f'<div class="award-year">{self.inl(date)}</div>\n</div>')

    def line_item(self, left, right):
        return (f'<div class="line-item">\n'
                f'  <div class="line-left">{self.inl(left)}</div>\n'
                f'  <div class="dotted-line"></div>\n'
                f'  <div class="line-right">{self.inl(right)}</div>\n</div>')

    def small_heading(self, text):
        return f'<h3 class="small-heading">{self.inl(text)}</h3>'

    # ---- section dispatch ---------------------------------------------
    def render_top_section(self, sec, boxed):
        title = sec.title
        if title == "GRANT FUNDING":
            return self.render_grants(sec)
        if title == "SIGNIFICANT CONTRIBUTIONS":
            return self.render_contributions(sec)
        if title == "PROFESSIONAL APPOINTMENTS":
            return self.render_appointments(sec)
        if title == "EDUCATION":
            return self.render_education(sec)
        return self.render_dated(sec)

    def heading_html(self, sec, extra=""):
        cls = "section-heading"
        if extra:
            cls += " " + extra
        return f'<h2 class="{cls}">{sec.raw_title}</h2>'

    def render_education(self, sec):
        out = [self.heading_html(sec)]
        for it in sec.intro:
            out.append(self._edu_block(it))
        for sub in sec.subsections:
            out.append(self.small_heading(sub.heading))
            for it in sub.items:
                out.append(self._edu_block(it))
        return "\n".join(x for x in out if x)

    def _edu_block(self, it):
        if " | " in it.text:
            left, right = it.text.split("|", 1)
            return self.line_item(left.strip(), right.strip())
        return f"<p><strong>{self.inl(it.text.strip('*'))}</strong></p>" \
            if it.text.startswith("**") else f"<p>{self.inl(it.text)}</p>"

    def render_appointments(self, sec):
        out = [self.heading_html(sec, "margin-top-30")]
        out.append('<ul class="no-bullet">')
        for it in sec.intro + [i for s in sec.subsections for i in s.items]:
            lines = [l for l in it.text.split("\n") if l.strip()]
            li = "  <li>\n"
            for j, ln in enumerate(lines):
                cls = ' class="font-agp-regular"' if j == 1 else ""
                inner = self.inl(ln.strip())
                if j == 0:
                    inner = f"<strong>{self.inl(ln.strip('* '))}</strong>" if ln.strip().startswith("**") else inner
                li += f"    <div{cls}>{inner}</div>\n"
            li += "  </li>"
            out.append(li)
        out.append("</ul>")
        return "\n".join(out)

    def render_dated(self, sec):
        extra = "margin-top-30 margin-bottom-5" if sec.title in ("AWARDS",) else ""
        out = [self.heading_html(sec, extra), '<div class="section-react"></div>'
               if sec.title not in ("EDUCATION", "PROFESSIONAL APPOINTMENTS") else ""]
        for it in sec.intro:
            r = self._dated_item(it)
            if r:
                out.append(r)
        for sub in sec.subsections:
            kept = [self._dated_item(it) for it in sub.items]
            kept = [k for k in kept if k]
            if kept:
                out.append(self.small_heading(sub.heading))
                out.extend(kept)
        return "\n".join(x for x in out if x)

    def _dated_item(self, it):
        parts = self._split_pipes(it.text)
        if len(parts) >= 2:
            body = parts[0]
            date = parts[-1]
        else:
            body, date = it.text, ""
        if self.filtering and date:
            if not S.ranges_overlap(S.extract_years(date), self.start, self.end):
                return None
        return self.swap_item(body, date)

    def render_grants(self, sec):
        out = [self.heading_html(sec, "margin-top-30 margin-bottom-5"),
               '<div class="section-react"></div>']
        for sub in sec.subsections:
            kept = [self._grant_item(it) for it in sub.items]
            kept = [k for k in kept if k]
            if kept:
                out.append(self.small_heading(sub.heading))
                out.extend(kept)
        for it in sec.intro:
            r = self._grant_item(it)
            if r:
                out.append(r)
        return "\n".join(x for x in out if x)

    def _grant_item(self, it):
        parts = self._split_pipes(it.text)
        body = parts[0]
        years = parts[-1] if len(parts) >= 2 else ""
        funding = parts[1] if len(parts) >= 3 else ""
        project = parts[2] if len(parts) >= 4 else ""
        if self.filtering and years:
            if not S.ranges_overlap(S.extract_years(years), self.start, self.end):
                return None
        fund_line = ""
        if funding:
            fund_line = f"requested funding: {funding}"
            if project:
                fund_line += f", total project: {project}"
        return f"""<div class="award-line display-block">
<span class="award-title">{self.inl(body)}</span>
<div class="award-under">
  <div class="margin-right-10 font-size-12 f-b-b"><strong>{fund_line}</strong></div>
  <div class="dotted-line"></div>
  <div class="margin-left-10"><strong>{self.inl(years)}</strong></div>
</div>
</div>"""

    def render_contributions(self, sec):
        out = [self.heading_html(sec)]
        for sub in sec.subsections:
            out.append(self.small_heading(sub.heading))
            for k, it in enumerate(sub.items):
                if k == 0:
                    out.append(f'<div class="award-line display-block">\n'
                               f'<span class="award-title">{self.inl(it.text)}</span>\n</div>')
                else:
                    out.append(f"<p>{self.inl(it.text)}</p>")
        return "\n".join(out)

    # ---- publications / presentations ---------------------------------
    def render_pub_like(self, sec, kind):
        """kind in {'pub','pres'}."""
        body_parts = []
        counts = self._init_counts(kind)
        nontraditional = False
        for sub in sec.subsections:
            heading = sub.heading.strip()
            year = S.parse_year(heading)
            status = S.is_status(heading)
            is_year_mark = (year is not None) or status

            if not is_year_mark:
                nontraditional = True  # e.g. NON-TRADITIONAL OUTPUTS divider

            # date filtering at the subsection level
            if self.filtering:
                if year is not None and not S.year_in_range(year, self.start, self.end):
                    continue
                if status and self.end is not None and self.end < CURRENT_YEAR:
                    continue

            items_html = []
            for it in sub.items:
                html = self._pub_item(it, kind, counts, year, status, nontraditional)
                if html:
                    items_html.append(html)
            if not items_html:
                continue
            if is_year_mark:
                body_parts.append(f'<div class="right-mark">{heading}</div>')
            else:
                body_parts.append(self.small_heading(heading))
            body_parts.extend(items_html)

        summary = self._summary_for(kind, counts)
        legend = self.legend()
        inner = summary + '    <div class="left-bar-content margin-bottom-20">\n' \
            + "\n".join(body_parts) + "\n    </div>\n"
        return f"""<h2 class="section-heading margin-top-30 margin-bottom-5 page-break-before">{sec.raw_title}</h2>
<div class="section-react"></div>
<div class="display-flex">
  <div class="width-80">
{inner}  </div>
{legend}</div>"""

    def _init_counts(self, kind):
        if kind == "pub":
            return {"scholarly": 0, "peer_reviewed": 0, "total": 0}
        return {"total": 0, "invited": 0, "keynote": 0, "plenary": 0}

    def _pub_item(self, it, kind, counts, year, status, nontraditional):
        tags, rest = S.parse_tags(it.text)
        # Citation chips. Publications auto-match against Scholar by default, so
        # no marker is needed on a normal paper. A marker only handles exceptions:
        #   {gs:CLUSTER}   force a specific Scholar cluster (ambiguous titles)
        #   {gs:NUMBER}    literal count
        #   {gs:none|-}    suppress (e.g. a non-cited item)
        #   {gs}           force auto-match (only needed on presentations, which
        #                  are not auto-matched)
        gs_value = None
        import re
        m = re.search(r"\{gs(?::\s*([^}]*?))?\s*\}", rest)
        if m:
            token = m.group(1)  # None for bare {gs}, else the inner text
            rest = (rest[:m.start()] + rest[m.end():]).strip()
            gs_value = self._resolve_citation(token, rest, explicit=True)
        elif kind == "pub":
            gs_value = self._resolve_citation(None, rest, explicit=False)

        # counts
        if kind == "pub":
            counts["total"] += 1
            if year is not None:
                counts["scholarly"] += 1
            if S.has_tag(tags, "peer-reviewed") or S.has_tag(tags, "peer-review"):
                counts["peer_reviewed"] += 1
        else:
            counts["total"] += 1
            if S.has_tag(tags, "invited"):
                counts["invited"] += 1
            if S.has_tag(tags, "keynote"):
                counts["keynote"] += 1
            if S.has_tag(tags, "plenary"):
                counts["plenary"] += 1

        # icon column
        icon_imgs = []
        for t in tags:
            f = ICONS.get(t)
            if not f:
                continue
            style = ' style="width: 20px; height: 20px"' if t in BIG_ICON else ""
            icon_imgs.append(f'      <img src="Links/{f}"{style} class="margin-0"/>')

        body_html = self.inl(rest.strip())

        if icon_imgs or gs_value is not None:
            preview = '    <div class="content-preview">\n'
            if not icon_imgs:
                preview += '      <div style="width: 22px"></div>\n'
            preview += ("\n".join(icon_imgs) + "\n") if icon_imgs else ""
            preview += "    </div>\n"
            gs_html = ""
            if gs_value is not None:
                gs_html = ('    <div>\n      <span class="google-scholar-mark">'
                           f'<strong>GS</strong> {S.fmt_commas(gs_value)}</span>\n    </div>\n')
            left = f'  <div class="display-block">\n{preview}{gs_html}  </div>\n'
        else:
            left = ('  <div class="content-preview">\n'
                    '    <div style="width: 22px"></div>\n  </div>\n')

        return (f'<div class="content-item margin-top-10">\n{left}'
                f'  <div class="content-text">\n    {body_html}\n  </div>\n</div>')

    def _summary_for(self, kind, counts):
        if kind == "pub":
            astats = self.sch.author_stats
            citations = S.fmt_commas(astats.get("total_citations", 0))
            hindex = astats.get("h_index", 0)
            col1 = ((counts["scholarly"], "SCHOLARLY PUBLICATIONS"),
                    (counts["peer_reviewed"], "PEER REVIEWED"))
            col2 = ((citations, "GOOGLE SCHOLAR CITATIONS"),
                    (hindex, "GOOGLE SCHOLAR H-INDEX"))
            return self.summary_box(col1, col2)
        col1 = ((counts["total"], "PRESENTATIONS"), (counts["invited"], "INVITED"))
        col2 = ((counts["plenary"], "PLENARY PRESENTATIONS"),
                (counts["keynote"], "KEYNOTE PRESENTATIONS"))
        return self.summary_box(col1, col2)

    # ---- top-level assembly -------------------------------------------
    def render_body(self):
        sections = self.doc.sections
        titles = [s.title for s in sections]
        pub_idx = titles.index("PUBLICATIONS") if "PUBLICATIONS" in titles else len(sections)
        pres_idx = titles.index("PRESENTATIONS") if "PRESENTATIONS" in titles else pub_idx

        top = [s for s in sections[:pub_idx]]
        rest = [s for s in sections if s.title not in ("PUBLICATIONS", "PRESENTATIONS")
                and sections.index(s) > pres_idx]

        boxed = set(str(x).upper() for x in (self.doc.meta.get("section-box") or []))

        # --- top region: width-70 (with optional section-box) + research sidebar
        top_html = ['<div class="display-flex">', '<div class="width-70">']
        i = 0
        while i < len(top):
            sec = top[i]
            if sec.title in boxed:
                # gather a contiguous run of boxed sections into one section-box
                top_html.append('<div class="section-box">')
                while i < len(top) and top[i].title in boxed:
                    top_html.append(self.render_top_section(top[i], boxed=True))
                    i += 1
                top_html.append("</div>")
            else:
                top_html.append(self.render_top_section(sec, boxed=False))
                i += 1
        top_html.append("</div>")  # close width-70
        sidebar = self.research_sidebar()
        if sidebar:
            top_html.append(sidebar)
        top_html.append("</div>")  # close display-flex

        parts = ["\n".join(top_html)]

        # --- publications & presentations
        for sec in sections:
            if sec.title == "PUBLICATIONS":
                parts.append(self.render_pub_like(sec, "pub"))
            elif sec.title == "PRESENTATIONS":
                parts.append(self.render_pub_like(sec, "pres"))

        # --- remaining sections at width-70
        if rest:
            rest_html = ['<div class="display-flex">', '<div class="width-70">']
            for sec in rest:
                rest_html.append(self.render_top_section(sec, boxed=False))
            rest_html.append("</div>\n</div>")
            parts.append("\n".join(rest_html))

        return "\n\n".join(parts)
