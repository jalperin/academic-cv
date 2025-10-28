# Academic CV Generator

An automated system for generating professional academic CVs from Markdown source files with integrated Google Scholar citation tracking, custom styling, and advanced formatting features.

## Quick Start

### Prerequisites

- [Pandoc](https://pandoc.org/installing.html) (document converter)
- Python 3.x with packages: `scholarly`, `python-frontmatter`, `pyyaml`
- Bash shell environment

### Installation

1. **Clone/Download the project files**
2. **Install Python dependencies:**
   ```bash
   pip install scholarly python-frontmatter pyyaml
   ```

### Basic Usage

1. **Update Google Scholar data** (optional):
   ```bash
   python update_scholar.py cv.md
   ```

2. **Build your CV:**
   ```bash
   ./build-cv.sh
   ```

Your CV will be generated as `cv.html` with professional styling.

### Date Filtering

Generate targeted CVs for specific time periods:

```bash
# Publications from 2020 onwards
./build-cv.sh --start-year 2020

# Publications from 2019-2023
./build-cv.sh --start-year 2019 --end-year 2023
```

## Documentation

- **[Build Pipeline](docs/BUILD_PIPELINE.md)** - How the CV generation process works
- **[Markdown Syntax](docs/MARKDOWN_SYNTAX.md)** - Special syntax for academic CVs
- **[Google Scholar Integration](docs/GOOGLE_SCHOLAR.md)** - Citation tracking setup
- **[Customization Guide](docs/CUSTOMIZATION.md)** - Styling and template modifications
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## Project Structure

```
├── cv.md                    # Main CV content (Markdown with special syntax)
├── build-cv.sh             # Build script with date filtering
├── cv-filter.lua           # Custom Pandoc filter for CV formatting
├── cv-gs-filter.lua        # Google Scholar citation integration
├── cv-template.html        # HTML template for output
├── styles.css              # Professional styling
├── post_process_cv.py      # Post-processing for filtered builds
├── update_scholar.py       # Google Scholar data updater
├── gs_citations.csv        # Citation data from Google Scholar
├── gs_author_stats.yaml    # Author statistics from Google Scholar
└── docs/                   # Documentation files
```

## Credits and License

### Credits

- **Code Author**: Juan Pablo Alperin
- **AI Assistant**: Claude (Anthropic) - assisted with documentation and code organization
- **Original Design**: [Fleck Creative Studio](https://fleckcreativestudio.com/) 
- **InDesign to HTML/CSS Migration**: Angelo Paolo Q. from [Upwork](https://www.upwork.com/freelancers/~01aae9ff826a944971/?mp_source=share)

### License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0).

This means you are free to:
- Use the software for any purpose
- Study how the program works and change it
- Distribute copies of the software
- Distribute copies of your modified versions

Under the conditions that:
- Any distributed copies or modifications must also be under GPL-3.0
- Source code must be made available when distributing
- Changes must be documented

See the full license text at: https://www.gnu.org/licenses/gpl-3.0.en.html

## Contributing

Contributions are welcome! Please see the documentation files for details on the system architecture and customization options.
