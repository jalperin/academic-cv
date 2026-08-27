# Troubleshooting Guide

This guide covers common issues you might encounter with the Academic CV Generator and their solutions.

## Installation Issues

### Pandoc Not Found

**Error:**
```
Error: pandoc is not installed
```

**Solutions:**

**On macOS:**
```bash
# Using Homebrew
brew install pandoc

# Using MacPorts
sudo port install pandoc
```

**On Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install pandoc
```

**On Windows:**
```bash
# Using Chocolatey
choco install pandoc

# Or download installer from https://pandoc.org/installing.html
```

**Verify installation:**
```bash
pandoc --version
```

### Python Package Issues

**Error:**
```
ModuleNotFoundError: No module named 'scholarly'
```

**Solutions:**
```bash
# Install required packages
pip install scholarly python-frontmatter pyyaml

# If using Python 3 specifically
pip3 install scholarly python-frontmatter pyyaml

# If permission issues
pip install --user scholarly python-frontmatter pyyaml

# Using conda
conda install -c conda-forge scholarly pyyaml
pip install python-frontmatter  # Not available in conda
```

**Virtual environment setup:**
```bash
python -m venv cv_env
source cv_env/bin/activate  # On Windows: cv_env\Scripts\activate
pip install scholarly python-frontmatter pyyaml
```

## Build Script Issues

### Permission Denied

**Error:**
```
bash: ./build-cv.sh: Permission denied
```

**Solution:**
```bash
chmod +x build-cv.sh
./build-cv.sh
```

### Missing Files

**Error:**
```
Error: cv-filter.lua not found
Error: cv-template.html not found
Error: Input file 'cv.md' not found
```

**Solutions:**
1. Ensure you're in the correct directory
2. Check that all project files are present:
   ```bash
   ls -la
   # Should show: cv.md, cv-filter.lua, cv-template.html, etc.
   ```
3. Download missing files from the project repository

### Lua Filter Errors

**Error:**
```
Error running filter cv-filter.lua:
lua: cv-filter.lua:123: attempt to index nil value
```

**Common causes and solutions:**

1. **YAML syntax errors in cv.md:**
   ```bash
   # Check YAML syntax
   python -c "import yaml; yaml.safe_load(open('cv.md').read().split('---')[1])"
   ```

2. **Missing metadata:**
   ```yaml
   # Ensure required fields are present
   ---
   gs_author_id: YOUR_ID_HERE
   gs_csv: gs_citations.csv
   ---
   ```

3. **Malformed date attributes:**
   ```markdown
   # Wrong
   ::: {.media-item date=2023}
   
   # Correct
   ::: {.media-item date="2023"}
   ```

## Google Scholar Issues

### Rate Limiting / IP Blocking

**Error:**
```
HTTP Error 429: Too Many Requests
HTTP Error 503: Service Unavailable
```

**Solutions:**

1. **Increase delay between requests:**
   ```yaml
   # In cv.md front matter
   gs_delay_between_requests: 5  # Increase from 2 to 5+ seconds
   ```

2. **Wait before retrying:**
   ```bash
   # Wait 1-24 hours before running update_scholar.py again
   ```

3. **Use VPN or different network:**
   ```bash
   # Try from a different IP address
   ```

4. **Manual citation entry:**
   ```csv
   # Add to gs_citations.csv manually
   author_id,pub_id,title,year,num_citations,url,date_scraped
   YOUR_ID,manual001,Paper Title,2023,15,,2025-01-15 10:30:45
   ```

### Author Not Found

**Error:**
```
Author with ID 'YOUR_ID' not found
```

**Solutions:**

1. **Verify your Google Scholar ID:**
   - Go to your Google Scholar profile
   - Check the URL: `https://scholar.google.com/citations?user=YOUR_ID&hl=en`
   - Copy the exact ID from the URL

2. **Ensure profile is public:**
   - Go to Google Scholar Settings
   - Make sure your profile is set to "Public"

3. **Check for typos:**
   ```yaml
   # Common mistake - extra characters
   gs_author_id: QW-eo0MAAAAJ&hl=en  # Wrong
   gs_author_id: QW-eo0MAAAAJ        # Correct
   ```

### Missing Publications

**Issue:** Some publications don't appear in the CSV file.

**Causes and solutions:**

1. **Publications not indexed by Google Scholar:**
   - Add publications manually to your Google Scholar profile
   - Ensure DOIs and proper metadata are available

2. **Recent publications:**
   - Google Scholar may take time to index new papers
   - Run `update_scholar.py` again after a few days

3. **Profile completeness:**
   - Verify all publications are listed in your Google Scholar profile
   - Merge duplicate entries in Google Scholar

### Citation Count Mismatches

**Issue:** Citation counts in CV don't match Google Scholar.

**Solutions:**

1. **Update citation data:**
   ```bash
   python update_scholar.py cv.md
   ```

2. **Check date of last update:**
   ```bash
   head -5 gs_citations.csv
   # Check date_scraped column
   ```

3. **Manual verification:**
   - Compare specific papers between your CV and Google Scholar
   - Note that Google Scholar may show different counts in different views

## Date Filtering Issues

### Items Not Appearing

**Issue:** Content doesn't appear when using date filters.

**Debug steps:**

1. **Check date format:**
   ```markdown
   # These work
   ::: {.media-item date="2023"}
   ::: {.media-item date="2020—2023"}
   ::: {.media-item date="2020-present"}
   
   # These don't work
   ::: {.media-item date=2023}
   ::: {.media-item date="twenty twenty-three"}
   ```

2. **Test without filters:**
   ```bash
   ./build-cv.sh  # Build without date filters first
   ```

3. **Check year extraction:**
   ```bash
   # Add debug output to cv-filter.lua
   io.stderr:write("DEBUG: Found years: " .. table.concat(years, ", ") .. "\n")
   ```

### Empty Sections

**Issue:** Sections appear empty after date filtering.

**Solution:** This is normal behavior. The post-processing script removes empty sections:

```bash
# Check if post_process_cv.py exists and is working
python3 post_process_cv.py cv.html cv_test.html
```

## CSS and Styling Issues

### Icons Not Displaying

**Issue:** Publication type icons don't appear.

**Solutions:**

1. **Check icon files:**
   ```bash
   ls -la Links/
   # Should show .png icon files
   ```

2. **Verify icon paths in Lua filter:**
   ```lua
   -- In cv-filter.lua, check icon file names match actual files
   local icons = {
     ['peer-reviewed'] = 'juanicons-colour-final-09.png',
     -- etc.
   }
   ```

3. **Check CSS for icon styling:**
   ```css
   .media-item img {
       width: 20px;
       height: 20px;
       margin-right: 8px;
   }
   ```

### Layout Issues

**Issue:** CV layout appears broken or misformatted.

**Solutions:**

1. **Check CSS file:**
   ```bash
   # Ensure styles.css exists and is valid
   ls -la styles.css
   ```

2. **Browser compatibility:**
   - Test in different browsers (Chrome, Firefox, Safari)
   - Check for CSS Grid and Flexbox support

3. **Print layout issues:**
   ```css
   /* Add print-specific styles */
   @media print {
       .custom-page-container {
           max-width: none;
           margin: 0;
       }
   }
   ```

### Font Issues

**Issue:** Fonts not loading or appearing incorrectly.

**Solutions:**

1. **Check Google Fonts connection:**
   ```html
   <!-- In cv-template.html -->
   <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700&display=swap" rel="stylesheet">
   ```

2. **Fallback fonts:**
   ```css
   body {
       font-family: 'Montserrat', Arial, sans-serif;
   }
   ```

3. **Local font installation:**
   ```bash
   # Install fonts locally if needed
   ```

## Output Issues

### Large File Size

**Issue:** Generated CV HTML file is very large.

**Solutions:**

1. **Optimize images:**
   ```bash
   # Compress icon files
   optipng Links/*.png
   ```

2. **Remove unused CSS:**
   - Review styles.css for unused rules
   - Use CSS minification tools

3. **External CSS:**
   ```html
   <!-- Link to external CSS instead of embedding -->
   <link rel="stylesheet" href="styles.css">
   ```

### PDF Generation Issues

**Issue:** Converting HTML to PDF doesn't work well.

**Solutions:**

1. **Use specialized tools:**
   ```bash
   # wkhtmltopdf (good for academic CVs)
   wkhtmltopdf --page-size A4 --margin-top 20mm cv.html cv.pdf
   
   # Puppeteer (modern Chrome engine)
   npm install -g puppeteer
   ```

2. **Print from browser:**
   - Use browser's "Print to PDF" feature
   - Set margins and page size appropriately

3. **CSS print optimization:**
   ```css
   @media print {
       .no-print { display: none; }
       .page-break { page-break-before: always; }
       body { font-size: 12pt; }
   }
   ```

## Performance Issues

### Slow Build Times

**Issue:** CV generation takes a long time.

**Solutions:**

1. **Profile the build:**
   ```bash
   time ./build-cv.sh
   ```

2. **Optimize Lua filters:**
   - Remove debug output
   - Optimize string operations
   - Cache expensive computations

3. **Reduce content size:**
   - Split very large CVs into sections
   - Use date filtering for shorter builds

### Memory Issues

**Issue:** Build process runs out of memory.

**Solutions:**

1. **Increase available memory:**
   ```bash
   # On Linux/macOS
   ulimit -v 2097152  # 2GB limit
   ```

2. **Optimize content:**
   - Reduce image sizes
   - Minimize embedded content
   - Split large sections

## Debugging Techniques

### Enable Verbose Output

**Pandoc verbose mode:**
```bash
# Modify build-cv.sh to add --verbose
PANDOC_CMD="$PANDOC_CMD --verbose"
```

**Lua filter debugging:**
```lua
-- Add to cv-filter.lua
function debug_print(msg)
    io.stderr:write("DEBUG: " .. msg .. "\n")
end

-- Use throughout filter
debug_print("Processing element: " .. elem.t)
```

### Isolate Issues

**Test components separately:**

1. **Test Google Scholar filter only:**
   ```bash
   pandoc cv.md --lua-filter=cv-gs-filter.lua -o test-gs.html
   ```

2. **Test main filter only:**
   ```bash
   pandoc cv.md --lua-filter=cv-filter.lua -o test-main.html
   ```

3. **Test without filters:**
   ```bash
   pandoc cv.md --template=cv-template.html -o test-basic.html
   ```

### Validate Input Files

**Check Markdown syntax:**
```bash
# Use a Markdown linter
markdownlint cv.md
```

**Validate YAML:**
```python
import yaml
with open('cv.md') as f:
    content = f.read()
    yaml_content = content.split('---')[1]
    try:
        yaml.safe_load(yaml_content)
        print("YAML is valid")
    except yaml.YAMLError as e:
        print(f"YAML error: {e}")
```

**Check CSV format:**
```python
import csv
try:
    with open('gs_citations.csv') as f:
        reader = csv.DictReader(f)
        for row in reader:
            pass
    print("CSV is valid")
except Exception as e:
    print(f"CSV error: {e}")
```

## Getting Help

### Log Files

Create detailed logs for troubleshooting:

```bash
# Capture all output
./build-cv.sh > build.log 2>&1

# Review the log
cat build.log
```

### Version Information

Collect version information for bug reports:

```bash
echo "=== System Information ==="
uname -a
echo "=== Pandoc Version ==="
pandoc --version
echo "=== Python Version ==="
python --version
echo "=== Python Packages ==="
pip list | grep -E "(scholarly|frontmatter|yaml)"
```

### Creating Minimal Test Cases

When reporting issues, create a minimal example:

1. **Minimal cv.md:**
   ```markdown
   ---
   title: Test CV
   name: Test User
   gs_author_id: test123
   gs_csv: test_citations.csv
   ---

   ## TEST SECTION

   - [journal] Test publication {GS:123}
   ```

2. **Minimal citations CSV:**
   ```csv
   author_id,pub_id,title,year,num_citations,url,date_scraped
   test123,123,Test Paper,2023,5,,2025-01-15 10:30:45
   ```

3. **Test the minimal case:**
   ```bash
   ./build-cv.sh
   ```

### Community Resources

- Check project documentation
- Search existing issues on the project repository
- Create detailed bug reports with:
  - Exact error messages
  - Steps to reproduce
  - System information
  - Minimal test case

### Professional Support

For critical issues in production environments:

- Consider hiring a consultant familiar with Pandoc and Lua
- Contact the original developers
- Review the GPL v3 license for commercial support options
