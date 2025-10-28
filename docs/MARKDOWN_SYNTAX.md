# Markdown Syntax Guide

This document covers all the special Markdown syntax used in the Academic CV Generator, beyond standard Markdown formatting.

## YAML Front Matter

Every CV must start with YAML metadata:

```yaml
---
title: Your Full Name - CV
name: Your Full Name
subtitle: Your Academic Title
sidebar: true
gs_author_id: YOUR_GOOGLE_SCHOLAR_ID
gs_csv: gs_citations.csv
gs_author_stats: gs_author_stats.yaml
gs_delay_between_requests: 2
summary:
  scholarly_pubs: 43
  peer_reviewed: 3
presentation_summary:
  total: 57
  invited: 43
  plenary: 5
  keynote: 14
  peer-reviewed: 10
research-interests:
  - scholarly communication
  - open science
  - your research area
---
```

### Required Fields
- `title`: Page title for HTML
- `name`: Your name (appears as main heading)
- `gs_author_id`: Your Google Scholar author ID
- `gs_csv`: Citation data file name

### Optional Fields
- `subtitle`: Appears below your name
- `sidebar`: Enable sidebar layout
- `summary`: Manual publication counts
- `presentation_summary`: Manual presentation counts
- `research-interests`: List of research areas

## Section Containers

### Section Box
Wrap major sections in containers for proper styling:

```markdown
::: {.section-box}
## EDUCATION

Content here...
:::
```

This creates a styled section with proper spacing and visual hierarchy.

## Item Types

### Media Items
For publications, presentations, awards, etc.:

```markdown
::: {.media-item date="2023"}
*Journal Name*. **Paper Title** {GS:paper_id}
:::

::: {.media-item date="2020—present"}
*Board Member*. **Organization Name**
:::

::: {.media-item date="2019-2021"}
*Position Title*. **Institution Name**
:::
```

**Date Format Options:**
- `date="2023"` - Single year
- `date="2020—present"` - Range to present
- `date="2019-2021"` - Specific range
- `date="Oct 17, 2025"` - Full date

### Line Items
For simple entries without complex formatting:

```markdown
::: {.line-item}
Degree Name | Year Completed
:::

::: {.line-item}
Committee Member | 2020-present
:::
```

## Publication Formatting

### Publication Types with Icons

Add type indicators in square brackets before publications:

```markdown
- [peer-reviewed,journal] Author, A., **Your Name**, & Author, C. Paper title. *Journal Name*. {GS:123}
- [invited,keynote] **Your Name**. Presentation title. *Conference Name*.
- [book] **Your Name** & Coauthor, B. Book title. Publisher.
- [chapter] **Your Name**. Chapter title. In *Book Title* (pp. 1-20). Publisher.
- [dataset] **Your Name** et al. Dataset title. Repository. DOI
```

### Available Type Tags

| Tag | Icon | Use Case |
|-----|------|----------|
| `peer-reviewed` | Review icon | Peer-reviewed publications |
| `invited` | Invitation icon | Invited presentations |
| `journal` | Journal icon | Journal articles |
| `conference` | Conference icon | Conference presentations |
| `book` | Book icon | Books |
| `chapter` | Chapter icon | Book chapters |
| `plenary` | Plenary icon | Plenary talks |
| `keynote` | Keynote icon | Keynote presentations |
| `dataset` | Dataset icon | Datasets |

### Combining Tags
You can combine multiple tags:
```markdown
- [peer-reviewed,journal] for peer-reviewed journal articles
- [invited,keynote] for invited keynote presentations
- [invited,plenary] for invited plenary talks
```

## Author Name Formatting

### Your Name
Always bold your own name:
```markdown
**Your Full Name**
```

### Collaborators
Use special markup to indicate relationship:

```markdown
- **Your Name**, ~~Lab Member~~, & ..External Collaborator.. 
```

**Formatting Rules:**
- `**Your Name**` - Your name (bold)
- `~~Student~~` - Student co-authors (markdown strikethrough styling, but displays as wavy underline)
- `..Postdoc..` - Postdoctoral Fellows (dotted underline)

### Author Order Indicators
Use symbols to indicate contribution:
```markdown
- any name^ - Corresponding author (add ^ after name)
```

## Google Scholar Citations

### Citation Syntax
Reference citations using Google Scholar publication IDs:

```markdown
{GS:GoogleScholar:PaperId} - Is replaced with GS citation count (if scraped)
{GS:25} - Already a number, displays as-is
```

### How It Works
1. `update_scholar.py` fetches publication data from Google Scholar
2. Creates mapping of publication IDs to citation counts in `gs_citations.csv`
3. `cv-gs-filter.lua` replaces `{GS:id}` with actual citation numbers
4. Missing IDs generate warnings

### Citation Display
Citations appear with special styling:
- `{GS:45}` displays as a styled citation count
- Hover effects and tooltips (depending on CSS)
- Consistent formatting across all citations

## Date Filtering Syntax

All date-sensitive content should use the `date` attribute for filtering:

### Supported Date Formats

```markdown
::: {.media-item date="2023"}
Single year
:::

::: {.media-item date="2020—2023"}
Year range (em dash)
:::

::: {.media-item date="2020-2023"}
Year range (hyphen, also works)
:::

::: {.media-item date="2020—present"}
Open-ended range
:::

::: {.media-item date="Mar 15, 2023"}
Full date (year extracted)
:::
```

### Filtering Logic
- Items are included if their date range overlaps with the filter range
- "present" is treated as the current year (2025)
- Missing dates include items by default
- Both start and end years are inclusive

## Special Text Formatting

### Emphasis in Academic Context

```markdown
*Journal Name* - Italics for journal names
**Important Term** - Bold for emphasis
***Very Important*** - Bold italic for strong emphasis
```

### Non-English Text
The system handles international characters:
```markdown
*Revista de Ciências* - Portuguese journal name
**José María López** - Author names with accents
```

### Links and URLs
Standard Markdown links work:
```markdown
[Link Text](https://example.com)
[Paper DOI](https://doi.org/10.1000/example)
```

## Section Organization

### Recommended Section Structure

```markdown
::: {.section-box}
## EDUCATION
[education entries]
:::

## PROFESSIONAL APPOINTMENTS
[appointment entries without section-box for variety]

::: {.section-box}
## PUBLICATIONS

### SCHOLARLY PUBLICATIONS
[journal articles]

### BOOKS
[book entries]
:::

## PRESENTATIONS
[presentation entries]

## MEDIA COVERAGE
[media entries]
```

### Section Headers
- Use `##` for major sections
- Use `###` for subsections
- Use `####` for minor subdivisions if needed

## Advanced Formatting

### Conditional Content
Content can be conditionally included based on date filtering:

```markdown
::: {.media-item date="2020"}
This only appears if 2020 is in the filter range
:::
```

### Mixed Content Types
You can mix different item types within sections:

```markdown
## PROFESSIONAL ACTIVITIES

::: {.media-item date="2023—present"}
*Board Member*. **Organization Name**
:::

::: {.line-item}
Committee Member | University of Example
:::

- [invited] Presentation at conference
```

### Custom CSS Classes
You can add custom CSS classes to any container:

```markdown
::: {.media-item .special-highlight date="2023"}
*Important Achievement*. **Special Recognition**
:::
```

## Common Patterns

### Publications by Year
```markdown
### 2023

- [peer-reviewed,journal] **Your Name** et al. Recent paper. *Top Journal*. {GS:123}
- [conference] **Your Name**. Conference presentation. *Major Conference*.

### 2022

- [peer-reviewed,journal] Colleague, A. & **Your Name**. Another paper. *Good Journal*. {GS:456}
```

### Service Entries
```markdown
::: {.media-item date="2020—present"}
*Editorial Board Member*. **Journal of Important Things**
:::

::: {.media-item date="2023"}
*Reviewer*. **Top Conference 2023**
:::
```

### Teaching and Supervision
```markdown
### DOCTORAL SUPERVISION

::: {.media-item date="2019-2023"}
**Student Name** — *Dissertation Title*. University Name
:::

### MASTERS SUPERVISION

::: {.media-item date="expected 2024"}
**Student Name** — *Thesis Title*. University Name
:::
```

## Validation and Testing

### Syntax Checking
- Use a Markdown linter to check basic syntax
- Build frequently to catch formatting errors
- Test date filtering with different ranges

### Common Mistakes
1. **Missing closing `:::`** - Always close container blocks
2. **Wrong date format** - Use `date="YYYY"` not `date=YYYY`
3. **Inconsistent author formatting** - Be consistent with `**Your Name**`
4. **Missing Google Scholar IDs** - Ensure all `{GS:id}` references exist in CSV

### Preview and Debug
```bash
# Build with verbose output to see processing details
./build-cv.sh 2>&1 | tee build.log

# Test specific date ranges
./build-cv.sh --start-year 2020 --end-year 2023
```
