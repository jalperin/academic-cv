#!/bin/bash
# build-cv.sh
# Build CV HTML from markdown using Pandoc and Lua filter

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
INPUT="cv.md"
OUTPUT="index.html"
START_YEAR=""
END_YEAR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --start-year)
            START_YEAR="$2"
            shift 2
            ;;
        --end-year)
            END_YEAR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--start-year YEAR] [--end-year YEAR]"
            echo "Examples:"
            echo "  $0                           # Build full CV"
            echo "  $0 --start-year 2020         # Items from 2020 onwards"
            echo "  $0 --start-year 2019 --end-year 2023  # Items from 2019-2023"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}Building CV...${NC}"

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}Error: pandoc is not installed${NC}"
    exit 1
fi

# Check if required files exist
if [ ! -f "cv-filter.lua" ]; then
    echo -e "${RED}Error: cv-filter.lua not found${NC}"
    exit 1
fi

if [ ! -f "cv-template.html" ]; then
    echo -e "${RED}Error: cv-template.html not found${NC}"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: Input file '$INPUT' not found${NC}"
    exit 1
fi

# Display filtering info
if [ -n "$START_YEAR" ] || [ -n "$END_YEAR" ]; then
    echo -e "${YELLOW}Date filtering:${NC} ${START_YEAR:-all} to ${END_YEAR:-current}"
fi

echo -e "${YELLOW}Input:${NC}  $INPUT"
echo -e "${YELLOW}Output:${NC} $OUTPUT"

# Build the CV in two passes
# Pass 1: Generate yearly stats
echo -e "${YELLOW}Pass 1: Generating yearly statistics...${NC}"
STATS_CMD="pandoc $INPUT"

# Add date filtering metadata if specified
if [ -n "$START_YEAR" ]; then
    STATS_CMD="$STATS_CMD --metadata filter_start_year=$START_YEAR"
fi
if [ -n "$END_YEAR" ]; then
    STATS_CMD="$STATS_CMD --metadata filter_end_year=$END_YEAR"
fi

# Generate stats only
STATS_CMD="$STATS_CMD --lua-filter=cv-stats-filter.lua -f markdown-strikeout-subscript --to=plain -o /dev/null"

# Execute stats generation
eval $STATS_CMD

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Stats generation failed${NC}"
    exit 1
fi

# Check if stats file was generated
if [ ! -f "cv_yearly_stats.yaml" ]; then
    echo -e "${RED}✗ Stats file not generated${NC}"
    exit 1
fi

echo -e "${YELLOW}Pass 2: Building CV with statistics...${NC}"

# Pass 2: Build CV with stats
PANDOC_CMD="pandoc $INPUT"

# Add date filtering metadata if specified
if [ -n "$START_YEAR" ]; then
    PANDOC_CMD="$PANDOC_CMD --metadata filter_start_year=$START_YEAR"
fi
if [ -n "$END_YEAR" ]; then
    PANDOC_CMD="$PANDOC_CMD --metadata filter_end_year=$END_YEAR"
fi

# Add remaining options (without stats filter since we already ran it)
PANDOC_CMD="$PANDOC_CMD --lua-filter=cv-gs-filter.lua --lua-filter=cv-filter.lua --template=cv-template.html --metadata-file=gs_author_stats.yaml --metadata-file=cv_yearly_stats.yaml --standalone -f markdown-strikeout-subscript -o $OUTPUT"

# Execute the command
eval $PANDOC_CMD

if [ $? -eq 0 ]; then
    # Post-process to remove empty sections if date filtering was used
    if [ -n "$START_YEAR" ] || [ -n "$END_YEAR" ]; then
        if [ -f "post_process_cv.py" ]; then
            # echo -e "${YELLOW}Post-processing to remove empty sections...${NC}"
            python3 post_process_cv.py "$OUTPUT" "${OUTPUT}.tmp"
            if [ $? -eq 0 ]; then
                mv "${OUTPUT}.tmp" "$OUTPUT"
            else
                echo -e "${YELLOW}Warning: Post-processing failed, keeping original${NC}"
                rm -f "${OUTPUT}.tmp"
            fi
        fi
    fi
    
    echo -e "${GREEN}Ã¢Å“â€¦ Successfully built: $OUTPUT${NC}"
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${YELLOW}File size:${NC} $SIZE"
else
    echo -e "${RED}Ã¢ÂÅ’ Build failed${NC}"
    exit 1
fi