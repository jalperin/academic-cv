# Customization Guide

This guide covers how to customize the appearance, behavior, and functionality of your Academic CV Generator.

## Styling Customization

### CSS File Structure

The main styling is in `styles.css`, organized in logical sections:

```css
/* Typography and base styles */
/* Layout and grid */
/* Section styling */
/* Icon and media item styling */
/* Print styles */
/* Responsive design */
```

### Typography Changes

#### Fonts
Change the primary font family:

```css
body {
    font-family: 'Your-Font', 'Montserrat', sans-serif;
}
```

**Popular academic fonts:**
- `'Times New Roman', serif` - Traditional academic
- `'Georgia', serif` - Modern serif
- `'Source Sans Pro', sans-serif` - Clean sans-serif
- `'Crimson Text', serif` - Elegant serif

#### Font Sizes
Adjust the typography scale:

```css
h1 { font-size: 2.5rem; }     /* Name */
h2 { font-size: 1.8rem; }     /* Section headers */
h3 { font-size: 1.4rem; }     /* Subsections */
.media-item { font-size: 1rem; } /* Content */
```

#### Line Spacing
Modify line heights for readability:

```css
body { line-height: 1.6; }
.media-item { line-height: 1.5; }
h2 { line-height: 1.3; }
```

### Color Scheme

#### Primary Colors
The system uses a professional color palette:

```css
:root {
    --primary-color: #2c3e50;    /* Dark blue-gray */
    --accent-color: #3498db;     /* Blue */
    --text-color: #333;         /* Dark gray */
    --light-gray: #ecf0f1;      /* Light gray */
}
```

#### Customizing Colors

**Academic themes:**

```css
/* Traditional Academic */
:root {
    --primary-color: #1a1a1a;
    --accent-color: #8b0000;
    --text-color: #333;
}

/* Modern Professional */
:root {
    --primary-color: #2c3e50;
    --accent-color: #27ae60;
    --text-color: #2c3e50;
}

/* Minimalist */
:root {
    --primary-color: #000;
    --accent-color: #666;
    --text-color: #333;
}
```

### Layout Modifications

#### Page Margins
Adjust margins for different page sizes:

```css
.custom-page-container {
    max-width: 210mm;  /* A4 width */
    margin: 0 auto;
    padding: 20mm;     /* 20mm margins */
}

/* For US Letter */
.custom-page-container {
    max-width: 8.5in;
    padding: 1in;
}
```

#### Section Spacing
Control spacing between sections:

```css
.section-box {
    margin-bottom: 2rem;  /* Space between sections */
}

h2 {
    margin-top: 2rem;     /* Space above headers */
    margin-bottom: 1rem;  /* Space below headers */
}
```

#### Two-Column Layout
Create a two-column layout for certain sections:

```css
.two-column {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
}

/* Use in HTML template or add class via Lua filter */
```

### Icon Customization

#### Icon Colors
Change icon colors:

```css
.media-item img {
    filter: hue-rotate(45deg);  /* Shift colors */
    opacity: 0.8;               /* Make translucent */
}

/* Specific icon types */
img[src*="peer-reviewed"] {
    filter: sepia(1) hue-rotate(120deg) saturate(2);
}
```

#### Icon Sizes
Adjust icon dimensions:

```css
.media-item img {
    width: 24px;
    height: 24px;
}

/* Smaller icons */
.media-item img {
    width: 16px;
    height: 16px;
}
```

#### Icon Positioning
Change icon placement:

```css
.media-item {
    display: flex;
    align-items: flex-start;
}

.media-item img {
    margin-right: 8px;
    margin-top: 2px;
}
```

## Template Customization

### HTML Template Structure

The `cv-template.html` defines the basic HTML structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>$if(title)$$title$$else$Professional CV$endif$</title>
    <link rel="stylesheet" href="./styles.css">
</head>
<body>
    <div class="custom-page-container">
        $if(name)$<h1>$name$</h1>$endif$
        $if(subtitle)$<div class="subtitle">$subtitle$</div>$endif$
        <div class="highlight-bar"></div>
        $body$
    </div>
</body>
</html>
```

### Adding Metadata

Include additional metadata in the template:

```html
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="author" content="$if(name)$$name$$endif$">
    <meta name="description" content="Academic CV for $if(name)$$name$$endif$">
    <title>$if(title)$$title$$else$Professional CV$endif$</title>
</head>
```

### Adding a Header/Footer

```html
<body>
    <header class="cv-header">
        $if(name)$<h1>$name$</h1>$endif$
        $if(subtitle)$<div class="subtitle">$subtitle$</div>$endif$
    </header>
    
    <main class="custom-page-container">
        $body$
    </main>
    
    <footer class="cv-footer">
        <p>Last updated: <span id="last-updated"></span></p>
    </footer>
</body>
```

### Conditional Content

Add content based on metadata:

```html
$if(research-interests)$
<div class="research-interests">
    <h3>Research Interests</h3>
    <ul>
    $for(research-interests)$
        <li>$research-interests$</li>
    $endfor$
    </ul>
</div>
$endif$
```

## Lua Filter Customization

### Adding New Icon Types

In `cv-filter.lua`, add new icon mappings:

```lua
local icons = {
  ['peer-reviewed'] = 'juanicons-colour-final-09.png',
  ['invited'] = 'juanicons-colour-final-29.png',
  -- Add your new types
  ['workshop'] = 'workshop-icon.png',
  ['patent'] = 'patent-icon.png',
  ['software'] = 'software-icon.png',
}
```

### Custom Author Formatting

Modify author name processing:

```lua
-- Add support for new author markup
function process_author_markup(text)
  -- Existing patterns
  text = text:gsub("%*%*([^%*]+)%*%*", '<strong>%1</strong>')  -- **Name**
  text = text:gsub("~~([^~]+)~~", '<span class="lab-member">%1</span>')  -- ~~Name~~
  
  -- Add new patterns
  text = text:gsub("@@([^@]+)@@", '<span class="external-collab">%1</span>')  -- @@Name@@
  text = text:gsub("##([^#]+)##", '<span class="emeritus">%1</span>')  -- ##Name##
  
  return text
end
```

### Custom Content Processing

Add processing for new content types:

```lua
-- Process special blocks
function process_special_blocks(elem)
  if elem.classes and elem.classes:includes("award") then
    -- Add special formatting for awards
    local icon = make_icon('award')
    if icon then
      elem.content:insert(1, icon)
    end
  end
  return elem
end
```

### Date Processing Extensions

Extend date filtering for more complex patterns:

```lua
-- Handle academic years (e.g., "2023-2024 academic year")
local function extract_academic_years(text)
  local years = {}
  for year1, year2 in text:gmatch("(%d%d%d%d)-(%d%d%d%d) academic year") do
    table.insert(years, tonumber(year1))
    table.insert(years, tonumber(year2))
  end
  return years
end
```

## JavaScript Enhancements

### Adding Interactive Features

The template includes JavaScript for dynamic dot leaders. You can extend this:

```javascript
// Add smooth scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

// Add table of contents generation
function generateTOC() {
    const headers = document.querySelectorAll('h2, h3');
    const toc = document.createElement('nav');
    toc.className = 'table-of-contents';
    
    headers.forEach(header => {
        const link = document.createElement('a');
        link.href = '#' + header.id;
        link.textContent = header.textContent;
        toc.appendChild(link);
    });
    
    document.body.insertBefore(toc, document.querySelector('main'));
}
```

### Print Optimization

Add print-specific JavaScript:

```javascript
// Optimize for printing
window.addEventListener('beforeprint', function() {
    // Hide interactive elements
    document.querySelectorAll('.interactive').forEach(el => {
        el.style.display = 'none';
    });
});

window.addEventListener('afterprint', function() {
    // Restore interactive elements
    document.querySelectorAll('.interactive').forEach(el => {
        el.style.display = '';
    });
});
```

## Build Script Customization

### Adding Custom Options

Extend `build-cv.sh` with new options:

```bash
# Add new command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        --theme)
            THEME="$2"
            shift 2
            ;;
        --output-format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --include-citations)
            INCLUDE_CITATIONS="true"
            shift
            ;;
        # ... existing options
    esac
done
```

### Multiple Output Formats

Generate different versions:

```bash
# Generate different themed versions
if [ "$THEME" = "traditional" ]; then
    cp styles-traditional.css styles.css
elif [ "$THEME" = "modern" ]; then
    cp styles-modern.css styles.css
fi

# Generate PDF version
if [ "$OUTPUT_FORMAT" = "pdf" ]; then
    wkhtmltopdf cv.html cv.pdf
fi
```

### Custom Post-Processing

Add additional post-processing steps:

```bash
# Add custom post-processing
if [ -f "custom_postprocess.py" ]; then
    echo -e "${YELLOW}Running custom post-processing...${NC}"
    python3 custom_postprocess.py "$OUTPUT"
fi

# Optimize images
if command -v optipng &> /dev/null; then
    echo -e "${YELLOW}Optimizing images...${NC}"
    find . -name "*.png" -exec optipng {} \;
fi
```

## Creating Custom Themes

### Theme Structure

Create a complete theme package:

```
themes/
├── academic-traditional/
│   ├── styles.css
│   ├── template.html
│   └── icons/
├── modern-minimal/
│   ├── styles.css
│   ├── template.html
│   └── icons/
└── corporate/
    ├── styles.css
    ├── template.html
    └── icons/
```

### Theme Switching

Implement theme switching in the build script:

```bash
apply_theme() {
    local theme=$1
    local theme_dir="themes/$theme"
    
    if [ -d "$theme_dir" ]; then
        cp "$theme_dir/styles.css" ./styles.css
        cp "$theme_dir/template.html" ./cv-template.html
        if [ -d "$theme_dir/icons" ]; then
            cp -r "$theme_dir/icons/"* ./Links/
        fi
        echo -e "${GREEN}Applied theme: $theme${NC}"
    else
        echo -e "${RED}Theme not found: $theme${NC}"
        exit 1
    fi
}
```

## Advanced Customizations

### Multi-Language Support

Add language detection and switching:

```yaml
# In YAML front matter
languages:
  - en
  - es
  - fr
default_language: en
```

```lua
-- In Lua filter
function handle_multilingual_content(elem)
  local lang = elem.attributes.lang or default_lang
  if current_lang ~= lang then
    return {}  -- Skip content in other languages
  end
  return elem
end
```

### Dynamic Content Loading

Load content from external sources:

```lua
-- Load publication data from ORCID, arXiv, etc.
function fetch_external_publications()
  -- Implementation to fetch from APIs
end
```

### Integration with Other Tools

#### LaTeX Output
Generate LaTeX alongside HTML:

```bash
# Generate LaTeX version
pandoc cv.md \
  --lua-filter=cv-gs-filter.lua \
  --lua-filter=cv-latex-filter.lua \
  --template=cv-template.tex \
  -o cv.tex
```

#### Word Export
Convert to Word format:

```bash
# Generate Word document
pandoc cv.html -o cv.docx
```

### Performance Optimization

#### Caching
Implement caching for expensive operations:

```python
# Cache Google Scholar data
import pickle
import os

cache_file = 'scholar_cache.pkl'
if os.path.exists(cache_file):
    with open(cache_file, 'rb') as f:
        cached_data = pickle.load(f)
```

#### Lazy Loading
Implement lazy loading for images:

```javascript
// Lazy load icons
const images = document.querySelectorAll('img[data-src]');
const imageObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            imageObserver.unobserve(img);
        }
    });
});

images.forEach(img => imageObserver.observe(img));
```

## Testing Customizations

### Validation Tools

Create validation scripts for your customizations:

```python
#!/usr/bin/env python3
# validate_customization.py

def validate_css():
    # Check CSS syntax
    pass

def validate_html_template():
    # Check HTML structure
    pass

def validate_lua_filters():
    # Check Lua syntax
    pass

if __name__ == "__main__":
    validate_css()
    validate_html_template()
    validate_lua_filters()
    print("All customizations validated!")
```

### Cross-Browser Testing

Test your customizations across different contexts:

```bash
# Test different browsers/engines
python -m http.server 8000 &
# Open localhost:8000/cv.html in different browsers

# Test print layouts
# Use browser dev tools print preview

# Test PDF generation
wkhtmltopdf cv.html test.pdf
```

### Responsive Testing

Test responsive behavior:

```css
/* Add responsive breakpoints for testing */
@media (max-width: 768px) {
    .custom-page-container {
        padding: 1rem;
    }
}

@media print {
    .no-print {
        display: none;
    }
}
```
