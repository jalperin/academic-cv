"""cvkit — build a styled, printable academic CV from plain-text markdown."""
import os
from jinja2 import Environment, FileSystemLoader, select_autoescape

from .parse import parse
from .scholar import Scholar
from .render import Renderer

_TEMPLATES = os.path.join(os.path.dirname(__file__), "templates")


def build(md_text, base_dir=".", start=None, end=None, report=None):
    doc = parse(md_text)
    scholar = Scholar.load(doc.meta, base_dir=base_dir)
    renderer = Renderer(doc, scholar, start=start, end=end)
    body = renderer.render_body()
    if report is not None:
        report.extend(renderer.report)

    env = Environment(
        loader=FileSystemLoader(_TEMPLATES),
        autoescape=select_autoescape(enabled_extensions=()),  # body is trusted HTML
    )
    tmpl = env.get_template("page.html.j2")
    return tmpl.render(
        title=doc.meta.get("title") or doc.meta.get("name") or "CV",
        name=doc.meta.get("name"),
        subtitle=doc.meta.get("subtitle"),
        body=body,
    )
