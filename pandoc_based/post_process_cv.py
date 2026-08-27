#!/usr/bin/env python3
"""
Simplified post-processor to remove empty sections after date filtering.
Uses a two-step approach: strip all non-heading HTML, then check for content.
"""

import re
import sys

def strip_non_heading_html(content):
    """Remove all HTML tags except headings (h1-h6)."""
    # Pattern to match any HTML tag that is NOT a heading
    # This preserves <h1>, <h2>, <h3>, etc. but removes everything else
    non_heading_pattern = r'<(?!/?(h[1-6])\b)[^>]*>'
    
    # Remove all non-heading HTML tags
    clean_content = re.sub(non_heading_pattern, '', content)
    
    # Clean up extra whitespace
    clean_content = re.sub(r'\s+', ' ', clean_content).strip()
    
    return clean_content

def has_real_content(content):
    """Check if content has real text after removing all non-heading HTML."""
    clean_content = strip_non_heading_html(content)
    
    # If there's any meaningful text content left (more than just whitespace), 
    # it's real content
    return len(clean_content) > 0

def remove_empty_h3_sections(html_content):
    """Remove H3 sections that contain only whitespace until the next heading."""
    
    # Pattern to match H3 + content until next H2 or H3
    pattern = r'(<h3[^>]*class="small-heading"[^>]*>[^<]*</h3>)(.*?)(?=<h[23][^>]*>|$)'
    
    def replace_if_empty(match):
        h3_header = match.group(1)
        content = match.group(2)
        
        # Check if content has real text after stripping HTML
        if has_real_content(content):
            return h3_header + content
        else:
            return ''  # Remove empty H3 section
    
    # Apply the replacement
    result = re.sub(pattern, replace_if_empty, html_content, flags=re.DOTALL)
    return result

def remove_empty_right_mark_sections(html_content):
    """Remove right-mark subsections that are empty (publications/presentations context)."""
    
    # Pattern to match right-mark div + content until next right-mark, h2, h3, or major structural element
    pattern = r'(<div class="right-mark">[^<]*</div>)(.*?)(?=<div class="right-mark">|<h[23][^>]*>|<div class="display-flex">|<div class="section-box">|$)'
    
    def replace_if_empty(match):
        right_mark_header = match.group(1)
        content = match.group(2)
        
        # Check if content has real text after stripping HTML
        if has_real_content(content):
            return right_mark_header + content
        else:
            return ''  # Remove empty right-mark section
    
    # Apply the replacement
    result = re.sub(pattern, replace_if_empty, html_content, flags=re.DOTALL)
    return result

def remove_empty_sections(html_content):
    """Remove both H3 and right-mark empty sections."""
    # First remove empty H3 sections
    result = remove_empty_h3_sections(html_content)
    
    # Then remove empty right-mark sections
    result = remove_empty_right_mark_sections(result)
    
    return result

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 simple_post_process.py input.html output.html")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        # Process the HTML to remove empty sections
        processed_content = remove_empty_sections(html_content)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(processed_content)
        
        print(f"Simple post-processing complete: {input_file} -> {output_file}")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()