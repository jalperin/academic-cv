# Google Scholar Integration

This guide covers how to set up and maintain automatic citation tracking using Google Scholar data.

## Initial Setup

### 1. Find Your Google Scholar Author ID

1. Go to [Google Scholar](https://scholar.google.com)
2. Search for your name and click on your profile
3. Look at the URL, which will be like: `https://scholar.google.com/citations?user=QW-eo0MAAAAJ&hl=en`
4. Your Author ID is the part after `user=` and before `&` (e.g., `QW-eo0MAAAAJ`)

### 2. Configure Your CV

Add the Author ID to your `cv.md` YAML front matter:

```yaml
---
title: Your Name - CV
name: Your Name
gs_author_id: QW-eo0MAAAAJ  # Your actual ID here
gs_csv: gs_citations.csv
gs_author_stats: gs_author_stats.yaml
gs_delay_between_requests: 2
---
```

### 3. Install Required Python Packages

```bash
pip install scholarly python-frontmatter pyyaml
```

## Fetching Citation Data

### Running the Update Script

```bash
python update_scholar.py cv.md
```

**What this does:**
- Reads your configuration from `cv.md`
- Fetches all publications from your Google Scholar profile
- Updates citation counts in `gs_citations.csv`
- Updates author statistics in `gs_author_stats.yaml`
- Respects rate limiting to avoid being blocked

### Output Files

#### `gs_citations.csv`
Contains publication data with citation counts:

```csv
author_id,pub_id,title,year,num_citations,url,date_scraped
QW-eo0MAAAAJ,abc123def,Paper Title,2023,15,https://scholar.google.com/...,2025-01-15 10:30:45
```

**Fields:**
- `author_id`: Your Google Scholar ID
- `pub_id`: Unique publication ID from Google Scholar
- `title`: Publication title
- `year`: Publication year
- `num_citations`: Current citation count
- `url`: Google Scholar URL for the publication
- `date_scraped`: When the data was last updated

#### `gs_author_stats.yaml`
Contains your overall Google Scholar metrics:

```yaml
author_id: QW-eo0MAAAAJ
name: Your Name
affiliation: Your Institution
total_citations: 1234
total_citations_5y: 890
h_index: 25
h_index_5y: 20
i10_index: 35
i10_index_5y: 28
num_publications: 45
date_scraped: '2025-01-15 10:30:45'
```

## Using Citations in Your CV

### Adding Citation References

In your publications, use the Google Scholar publication ID:

```markdown
- [peer-reviewed,journal] **Your Name** et al. Amazing research paper. *Top Journal*. {GS:abc123def}
```

### How Citations Are Processed

1. **Before processing:** `{GS:abc123def}`
2. **After cv-gs-filter.lua:** `{GS:15}` (where 15 is the citation count)
3. **After cv-filter.lua:** Styled citation display

### Finding Publication IDs

#### Method 1: From the CSV File
After running `update_scholar.py`, check `gs_citations.csv` for the mapping between titles and `pub_id` values.

#### Method 2: From Google Scholar URLs
Publication IDs are in the Google Scholar URLs:
```
https://scholar.google.com/citations?view_op=view_citation&hl=en&user=QW-eo0MAAAAJ&citation_for_view=QW-eo0MAAAAJ:abc123def
```
The ID is the part after the last colon: `abc123def`

#### Method 3: Manual Search
```python
# Quick script to find a publication ID
import csv

def find_publication(title_search):
    with open('gs_citations.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if title_search.lower() in row['title'].lower():
                print(f"Title: {row['title']}")
                print(f"ID: {row['pub_id']}")
                print(f"Citations: {row['num_citations']}")
                print("---")

find_publication("machine learning")  # Search for papers with "machine learning"
```

## Rate Limiting and Best Practices

### Avoiding IP Blocks

Google Scholar has rate limiting. The update script includes safeguards:

```yaml
gs_delay_between_requests: 2  # Seconds between requests
```

**Recommendations:**
- Use 2+ second delays (default: 2 seconds)
- Don't run updates too frequently (weekly/monthly is fine)
- If blocked, wait several hours before trying again
- Consider using a VPN if repeatedly blocked

### Update Frequency

**Suggested schedule:**
- **Daily**: Not recommended (too frequent)
- **Weekly**: Good for active researchers
- **Monthly**: Suitable for most academics
- **Before important deadlines**: Job applications, tenure reviews

### Handling Errors

Common issues and solutions:

```bash
# Error: "scholarly" module not found
pip install scholarly

# Error: "Rate limit exceeded"
# Increase delay in cv.md:
gs_delay_between_requests: 5

# Error: "Author not found"
# Check your Author ID in the URL
```

## Advanced Usage

### Selective Updates

You can modify `update_scholar.py` to update only recent publications:

```python
# Add date filtering to the update script
from datetime import datetime, timedelta

# Only update publications from the last 2 years
cutoff_date = datetime.now() - timedelta(days=730)
```

### Manual Citation Entry

For publications not in Google Scholar, you can manually add entries to `gs_citations.csv`:

```csv
QW-eo0MAAAAJ,manual001,Book Chapter Title,2023,5,,2025-01-15 10:30:45
```

Then reference with `{GS:manual001}` in your CV.

### Citation Verification

Check for missing or outdated citations:

```bash
# Find all GS references in your CV
grep -o '{GS:[^}]*}' cv.md

# Compare with available IDs in CSV
cut -d',' -f2 gs_citations.csv
```

## Data Privacy and Ethics

### Google Scholar Terms of Service

- Use automated access responsibly
- Don't overload Google's servers
- Respect rate limits
- Data is for personal/academic use

### Citation Accuracy

- Google Scholar citation counts may include:
  - Self-citations
  - Non-peer-reviewed sources
  - Duplicates
- Consider this when presenting citation metrics
- Supplement with other metrics when appropriate

### Data Backup

Your citation data is valuable:

```bash
# Backup your data regularly
cp gs_citations.csv gs_citations_backup_$(date +%Y%m%d).csv
cp gs_author_stats.yaml gs_author_stats_backup_$(date +%Y%m%d).yaml
```

## Troubleshooting

### Common Issues

#### 1. "No publications found"
- Check your Author ID is correct
- Ensure your Google Scholar profile is public
- Verify you have publications listed on Google Scholar

#### 2. "Citation count mismatch"
- Google Scholar data may be cached
- Different views (public vs. personal) may show different counts
- Citations may have been updated since last fetch

#### 3. "Missing publication IDs"
When building, you see warnings like:
```
WARNING: No citation found for xyz123
```

**Solutions:**
- Run `update_scholar.py` to refresh data
- Check that the publication exists on Google Scholar
- Verify the publication ID is correct

#### 4. "Rate limiting errors"
```python
# Increase delay in your cv.md
gs_delay_between_requests: 5  # or higher
```

### Debug Mode

Add debugging to the update script:

```python
# Add to update_scholar.py
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Validation Script

Create a simple validation script:

```python
#!/usr/bin/env python3
import csv
import re

def validate_citations():
    # Read CV file
    with open('cv.md', 'r') as f:
        cv_content = f.read()
    
    # Find all GS references
    gs_refs = re.findall(r'{GS:([^}]+)}', cv_content)
    
    # Read CSV data
    csv_ids = set()
    with open('gs_citations.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            csv_ids.add(row['pub_id'])
    
    # Check for missing IDs
    for ref in gs_refs:
        if ref not in csv_ids and not ref.isdigit():
            print(f"Warning: {ref} not found in CSV")
    
    print(f"Found {len(gs_refs)} GS references")
    print(f"Have data for {len(csv_ids)} publications")

if __name__ == "__main__":
    validate_citations()
```

### Alternative Data Sources

If Google Scholar is unavailable, consider:
- Manual citation counts
- Crossref API for DOI-based papers
- ORCID integration
- Institutional repository data

## Integration with Other Services

### ORCID Sync
While this system focuses on Google Scholar, you could extend it to sync with ORCID:

```python
# Pseudocode for ORCID integration
import orcid
# Fetch ORCID data and merge with Google Scholar
```

### Institutional Systems
Many universities have research information systems that could be integrated similarly.

### Export Formats
The citation data could be exported to other formats:
- BibTeX for reference managers
- JSON for web APIs
- XML for institutional repositories
