# cvkit

A small, dependency-light Python tool that builds a styled, printable academic
CV from a single plain-text Markdown file. It replaces the previous
pandoc + Lua-filter pipeline with one in-memory pass: parse → filter by date →
compute stats → render. Because the summary boxes are counted from the same
filtered model that gets rendered, the stats can never drift out of sync with
the content (the old build kept counts in a separate `cv_yearly_stats.yaml`
that silently went stale).

## Quick start

```bash
python cv.py                                    # full CV  -> index.html
python cv.py --start-year 2020                  # 2020–present
python cv.py --start-year 2019 --end-year 2023  # a fixed window
python cv.py -i cv.md -o build/cv-2020.html --start-year 2020
python cv.py --update-scholar                   # refresh citation counts, then build
```

`index.html` expects `styles.css`, `Links/`, and `fonts/` beside it (they ship
in the repo root). Open it in a browser and print to PDF; page breaks are tuned
so Publications and Presentations start on fresh pages.

## Migrating existing content

The old `cv.md` (fenced `::: {.class}` divs, `{GS:author:pubid}` markers) is
converted automatically:

```bash
python convert_legacy.py old_cv.md > cv.md
python simplify_citations.py cv.md        # strip now-redundant citation markers
```

The transform only rewrites structural noise; prose and author-role markers are
left untouched, so it is lossless.

## The syntax

Frontmatter is YAML. `section-box` lists the sections that share the pink box;
`sidebar: true` turns on the Research Interests column.

```yaml
---
name: Juan Pablo Alperin
subtitle: Associate Professor
sidebar: true
gs_author_id: QW-eo0MAAAAJ
gs_csv: gs_citations.csv
gs_author_stats: gs_author_stats.yaml
research-interests:
  - scholarly communication
  - open access
section-box:
  - EDUCATION
  - PROFESSIONAL APPOINTMENTS
---
```

Sections are `##`, subsections are `###`. What an item *means* is decided by its
section, so the body stays close to plain Markdown.

| Section | Item shape | Example |
|---|---|---|
| Education | `LEFT \| RIGHT` under a `**bold header**` | `Multidisciplinary Studies in Education \| 2015` |
| Professional Appointments | bullet: title line + org line | `- **Associate Professor**`<br>`  Simon Fraser University` |
| Board / Awards / Media / Teaching / Service | `BODY \| DATE` | `*Board Member*. **OpenAlex** \| 2025–present` |
| Grant Funding | `BODY \| FUNDING \| YEARS` (or `… \| FUNDING \| PROJECT \| YEARS`) | `… Gates Foundation. \| US$750,000 \| 2025-2028` |
| Significant Contributions | first paragraph = citation, then a `**significance:**` paragraph | |
| Publications / Presentations | `- [tags] BODY {gs:ID}` | see below |

Inside Publications / Presentations:

```
### 2025
- [peer-reviewed, journal] van Bellen, S.^, Alperin, J.P. & Larivière, V.
  The oligopoly of academic publishers persists. *arXiv*. doi:10.48550/arXiv.2406.17893
```

- `[tags]` (leading) pick the category icons: `peer-reviewed, invited, journal,
  conference, book, chapter, plenary, keynote, dataset`.
- Author-role markers: `~~name~~` student (wavy), `~name~` post-doc (dotted),
  `^` after a name = corresponding author.
- A `###` heading that is a year or a status (`IN PRESS`, `UNDER REVIEW`) becomes
  a right-hand year marker; any other `###` (e.g. `NON-TRADITIONAL OUTPUTS`)
  becomes a left divider.

### Citation counts

Publications show a Google Scholar citation chip **automatically** — no marker
needed. Each line is matched against the author's own scraped publications by
title; the candidate pool is small and specific, so a distinctive title matches
reliably even through typos. New citations appear on the next scrape, and a paper
with no citations simply shows no chip until it has some. (Presentations are not
auto-matched, since a talk shouldn't inherit a paper's citation count.)

A marker is only needed for the exceptions:

| Marker | When you need it |
|---|---|
| *(none)* | the normal case — a publication auto-matches |
| `{gs:CLUSTERID}` | force a specific Scholar cluster when a title is ambiguous (two Scholar entries share it) |
| `{gs:none}` | suppress a chip (e.g. a publication you don't want counted) |
| `{gs:42}` | a literal count |
| `{gs}` | force auto-match on a *presentation* (opt-in, since presentations are off by default) |

Run `python cv.py --citations-report` to see how every line resolved and a list
of anything ambiguous or low-confidence to eyeball. `simplify_citations.py`
strips redundant markers left over from a migration, keeping only the exceptions.

## Layout

```
cv.py                 CLI (--start-year/--end-year, --citations-report, --update-scholar)
convert_legacy.py     one-time old -> new migration
simplify_citations.py strip redundant citation markers (keep exceptions)
cvkit/
  parse.py            markdown -> Document model
  inline.py           inline markdown + author-role markers -> HTML
  scholar.py          citation counts + author-level stats
  match.py            title-based citation matching
  stats.py            year extraction, date filtering, counts
  render.py           Document -> HTML (section-driven)
  templates/page.html.j2
cv.md                 your content
styles.css  Links/  fonts/  gs_citations.csv  gs_author_stats.yaml
```

`update_scholar.py` (unchanged from before) refreshes `gs_citations.csv` and
`gs_author_stats.yaml`; cvkit only consumes them.
