"""inline.py — render inline markdown and the CV's custom author-role markers
to HTML.

Supported inline syntax:
    **bold**            -> <strong>
    *italic*            -> <em>
    [text](url)         -> <a class="content-link">
    `code`              -> blue span
    ~~name~~            -> student   (wavy strike)
    ..name..            -> post doc  (dotted strike)
    ^                   -> corresponding-author superscript icon
    doi: 10.x/y         -> linked DOI
    Alperin, J.P.       -> auto-bold (configurable surname)

The renderer protects link/href payloads with placeholders so later
substitutions never reach inside a URL.
"""
import re
import html

CORRESPONDING_ICON = "Links/juanicons-colour-final-05.png"


def _protect(text, store, html_str):
    key = f"\x00{len(store)}\x00"
    store.append(html_str)
    return key, text


def render_inline(text, owner_name="Alperin, J.P."):
    if text is None:
        return ""
    store = []

    # 1. Links first, so their URLs are shielded from later rules.
    def link_sub(m):
        label = m.group(1)
        url = m.group(2)
        rendered = render_inline(label, owner_name)  # labels may hold markup
        key, _ = _protect("", store, f'<a href="{url}" class="content-link">{rendered}</a>')
        return key

    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", link_sub, text)

    # 2. DOI -> link (before generic formatting).
    def doi_sub(m):
        doi = m.group(1)
        key, _ = _protect("", store, f'doi: <a href="https://doi.org/{doi}" class="content-link">{doi}</a>')
        return key

    text = re.sub(r"doi:\s*([0-9][0-9.]+/[^\s,)]+)", doi_sub, text)

    # 3. Author-role markers. Student (~~name~~) is matched before post-doc
    #    (~name~) so the single-tilde rule never bites into a double tilde.
    text = re.sub(r"~~([^~]+)~~", lambda m: f'<span class="wavy-text">{m.group(1)}</span>', text)
    text = re.sub(r"(?<!~)~([^~\n]+?)~(?!~)", lambda m: f'<span class="dotted-text">{m.group(1)}</span>', text)

    # 4. Bold / italic / code.
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", text)
    text = re.sub(r"`([^`]+)`", r'<span class="color-blue">\1</span>', text)

    # 5. Corresponding-author marker.
    text = text.replace("^", f'<img src="{CORRESPONDING_ICON}" class="super-mail"/>')

    # 6. Auto-bold the CV owner's name.
    if owner_name:
        safe = re.escape(owner_name)
        text = re.sub(safe, f'<span class="font-agp-bold">{owner_name}</span>', text)

    # Restore protected fragments.
    for i, frag in enumerate(store):
        text = text.replace(f"\x00{i}\x00", frag)
    return text
