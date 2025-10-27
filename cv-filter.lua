-- cv-filter.lua
-- Pandoc Lua filter for CV formatting

-- Helper: format numbers with commas
local function format_with_commas(n)
  local str = tostring(n)
  local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  formatted = formatted:gsub("^,", "")
  return formatted
end

-- Date filtering variables
local date_filter_enabled = false
local filter_start_year = nil
local filter_end_year = nil
local current_year = 2025

-- Helper: extract years from text
local function extract_years(text)
  local years = {}
  -- Extract 4-digit years
  for year in text:gmatch("(%d%d%d%d)") do
    table.insert(years, tonumber(year))
  end
  -- Handle "present" as current year
  if text:match("present") then
    table.insert(years, current_year)
  end
  return years
end

-- Helper: check if year is in range
local function year_in_range(year)
  if not date_filter_enabled then return true end
  return year >= filter_start_year and year <= filter_end_year
end

-- Helper: check if year ranges overlap with filter range
local function ranges_overlap(item_years)
  if not date_filter_enabled then return true end
  if #item_years == 0 then return true end  -- No years found, include by default
  
  -- Get min and max years from item
  local item_start = math.min(table.unpack(item_years))
  local item_end = math.max(table.unpack(item_years))
  
  -- Check for overlap: item_start <= filter_end AND item_end >= filter_start
  return item_start <= filter_end_year and item_end >= filter_start_year
end

-- Icon mappings
local icons = {
  ['peer-reviewed'] = 'juanicons-colour-final-09.png',
  ['invited'] = 'juanicons-colour-final-29.png',
  ['journal'] = 'juanicons-colour-final-12.png',
  ['conference'] = 'juanicons-colour-final-28.png',
  ['book'] = 'juanicons-colour-final-17.png',
  ['chapter'] = 'juanicons-colour-final-18.png',
  ['plenary'] = 'juanicons-colour-final-19.png',
  ['keynote'] = 'juanicons-colour-final-16.png',
  ['dataset'] = 'juanicons-colour-final-13.png',
}

-- Store metadata for summary
local summary_data = {}
local presentation_summary = {}

-- Global variable for sidebar content (research interests)
local sidebar_content = ''

-- Track if we opened a publications or presentations wrapper
local in_publications = false
local in_presentations = false
local current_year_section = nil  -- Track current year for content filtering

-- Helper function to create icon HTML
function make_icon(icon_name)
  local icon_file = icons[icon_name]
  if not icon_file then return nil end
  
  local size_attr = ''
  if icon_name == 'peer-reviewed' or icon_name == 'invited' then
    size_attr = ' style="width: 20px; height: 20px"'
  end
  
  return pandoc.RawInline('html', 
    '<img src="Links/' .. icon_file .. '"' .. size_attr .. ' class="margin-0"/>')
end

-- Helper function to wrap in span
function make_span(class, content)
  return pandoc.RawInline('html', 
    '<span class="' .. class .. '">' .. pandoc.utils.stringify(content) .. '</span>')
end

-- Extract metadata - NOTE: This won't work as Meta() is called after blocks are processed
-- We'll extract metadata in the Pandoc() function instead
function Meta(meta)
  -- This function exists but we process metadata in Pandoc() instead
  return meta
end

-- Helper function to create summary box
function create_summary_box(data, labels)
  local html = '    <div class="summary-title">SINCE 2019 SUMMARY</div>\n'
  html = html .. '    <div class="summary-box">\n'
  html = html .. '      <div class="display-flex justify-content-around">\n'
  
  -- First column (if exists)
  if data[labels[1][1]] and data[labels[1][2]] then
    html = html .. '        <div class="display-flex">\n'
    html = html .. '          <div class="display-block margin-right-10">\n'
    html = html .. '            <div class="height-25 float-right">\n'
    html = html .. '              <strong class="font-size-15 align-items-center">' .. data[labels[1][1]] .. '</strong>\n'
    html = html .. '            </div>\n'
    html = html .. '            <div class="height-25">\n'
    html = html .. '              <strong class="font-size-15 align-items-center">' .. data[labels[1][2]] .. '</strong>\n'
    html = html .. '            </div>\n'
    html = html .. '          </div>\n'
    html = html .. '          <div class="display-block">\n'
    html = html .. '            <div class="height-25">\n'
    html = html .. '              <span class="font-size-12 align-items-center">' .. labels[1][3] .. '</span>\n'
    html = html .. '            </div>\n'
    html = html .. '            <div class="height-25">\n'
    html = html .. '              <span class="font-size-12 align-items-center">' .. labels[1][4] .. '</span>\n'
    html = html .. '            </div>\n'
    html = html .. '          </div>\n'
    html = html .. '        </div>\n'
  end
  
  -- Second column (if exists)
  if data[labels[2][1]] and data[labels[2][2]] then
    html = html .. '        <div class="display-flex">\n'
    html = html .. '          <div class="display-block margin-right-10">\n'
    html = html .. '            <div class="height-25">\n'
    html = html .. '              <strong class="font-size-15 align-items-center">' .. data[labels[2][1]] .. '</strong>\n'
    html = html .. '            </div>\n'
    html = html .. '            <div class="height-25 float-right">\n'
    html = html .. '              <strong class="font-size-15 align-items-center">' .. data[labels[2][2]] .. '</strong>\n'
    html = html .. '            </div>\n'
    html = html .. '          </div>\n'
    html = html .. '          <div class="display-block">\n'
    html = html .. '            <div class="height-25">\n'
    html = html .. '              <span class="font-size-12 align-items-center">' .. labels[2][3] .. '</span>\n'
    html = html .. '            </div>\n'
    html = html .. '            <div class="height-25">\n'
    html = html .. '              <span class="font-size-12 align-items-center">' .. labels[2][4] .. '</span>\n'
    html = html .. '            </div>\n'
    html = html .. '          </div>\n'
    html = html .. '        </div>\n'
  end
  
  html = html .. '      </div>\n'
  html = html .. '    </div>\n'
  
  return html
end

-- Helper function to create legend sidebar
function create_legend()
  local html = '  <div class="margin-left-20 width-20">\n'
  html = html .. '    <h3 class="text-align-center">LEGEND</h3>\n'
  html = html .. '    <div class="font-size-14">AUTHORSHIP</div>\n'
  html = html .. '    <div class="display-block">\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-05.png"/><span class="font-size-12">corresponding author</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <span class="wavy-line">w l</span><span class="font-size-12">student</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <span class="dotted-mark-line">w l</span><span class="font-size-12">post doc</span>\n'
  html = html .. '      </div>\n'
  html = html .. '    </div>\n'
  html = html .. '    <div class="font-size-14 margin-top-15">CATEGORY</div>\n'
  html = html .. '    <div class="display-block">\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-09.png" style="width: 20px; height: 20px"/><span class="font-size-12">peer reviewed</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-29.png" style="width: 20px; height: 20px"/><span class="font-size-12">invited</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-12.png"/><span class="font-size-12">journal</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-28.png"/><span class="font-size-12">conference</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-17.png"/><span class="font-size-12">book</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-18.png"/><span class="font-size-12">chapter</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-19.png"/><span class="font-size-12">plenary</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-16.png"/><span class="font-size-12">keynote</span>\n'
  html = html .. '      </div>\n'
  html = html .. '      <div class="display-flex align-items-center margin-top-5">\n'
  html = html .. '        <img src="Links/juanicons-colour-final-13.png"/><span class="font-size-12">dataset</span>\n'
  html = html .. '      </div>\n'
  html = html .. '    </div>\n'
  html = html .. '  </div>\n'
  return html
end

-- Helper function to create sidebar (research interests) - uses global sidebar_content
function create_sidebar()
  -- sidebar_content is populated in Pandoc() function
  if sidebar_content and sidebar_content ~= '' then
    publications_sidebar_added = true
    return sidebar_content
  end
  return ''
end

-- Process inline elements for special formatting
function Span(el)
  -- Handle custom classes from markdown
  if el.classes:includes('student') then
    return pandoc.RawInline('html', 
      '<span class="wavy-text">' .. pandoc.utils.stringify(el.content) .. '</span>')
  elseif el.classes:includes('postdoc') then
    return pandoc.RawInline('html', 
      '<span class="dotted-text">' .. pandoc.utils.stringify(el.content) .. '</span>')
  elseif el.classes:includes('me') then
    return pandoc.RawInline('html', 
      '<span class="font-agp-bold">' .. pandoc.utils.stringify(el.content) .. '</span>')
  elseif el.classes:includes('corresponding') then
    return pandoc.RawInline('html', 
      '<img src="Links/juanicons-colour-final-05.png" class="super-mail"/>')
  elseif el.classes:includes('blue') then
    return pandoc.RawInline('html', 
      '<span class="color-blue">' .. pandoc.utils.stringify(el.content) .. '</span>')
  elseif el.classes:includes('icon') then
    local icon_name = el.attributes['name']
    if icon_name then
      return make_icon(icon_name)
    end
  end
end

-- Helper function to determine if a section should be in a section-box
-- NOTE: The markdown already has section-box divs, so we don't need to add them
function should_be_in_section_box(content)
  return false  -- Disabled since markdown already has section-box divs
end

-- Process headers to add special classes
function Header(el)
  -- Check for filter-exclude-when-dating attribute
  if date_filter_enabled and el.classes:includes('filter-exclude-when-dating') then
    return pandoc.RawBlock('html', '')
  end
  
  if el.level == 2 then
    -- Add section styling
    local id = el.identifier or ''
    local content = pandoc.utils.stringify(el.content)
    
    -- Reset year section tracking for any H2 (major section)
    current_year_section = "valid"
    
    -- Check for explicit attributes
    local is_subsection = el.classes:includes('subsection')
    local is_major = el.classes:includes('major')
    
    -- PUBLICATIONS and PRESENTATIONS are ALWAYS major sections
    local is_publications = content:upper() == 'PUBLICATIONS'
    local is_presentations_sec = content:upper() == 'PRESENTATIONS'
    
    if is_publications or is_presentations_sec then
      is_major = true
      is_subsection = false
    elseif not is_subsection and not is_major then
      -- Default: H2s are major sections
      -- Only mark as subsection if explicitly requested
      is_subsection = false
      is_major = true
    end
    
    -- Track sections
    local closing = ''
    
    -- Special handling: EDUCATION and PROFESSIONAL APPOINTMENTS
    local is_education = content:upper() == 'EDUCATION'
    local is_prof_appts = content:upper() == 'PROFESSIONAL APPOINTMENTS'
    
    -- Close publications/presentations wrapper if this is a major section
    if in_publications and is_major then
      closing = closing .. '    </div>\n  </div>\n' .. create_legend() .. '</div>\n\n'
      -- Reopen the full layout structure for subsequent sections
      closing = closing .. '<div class="display-flex">\n<div class="width-70">\n'
      in_publications = false
    end
    if in_presentations and is_major then
      closing = closing .. '    </div>\n  </div>\n' .. create_legend() .. '</div>\n\n'
      -- Reopen the full layout structure for subsequent sections
      closing = closing .. '<div class="display-flex">\n<div class="width-70">\n'
      in_presentations = false
    end
    
    -- Special handling for PUBLICATIONS section with summary
    if content:upper() == 'PUBLICATIONS' and next(summary_data) ~= nil then
      -- Close the main width-70 div and add sidebar BEFORE starting publications
      closing = closing .. '</div>\n' .. create_sidebar() .. '</div>\n\n'
      
      in_publications = true
      current_year_section = "valid"  -- Reset year tracking for new section
      local html = closing .. '<h2 class="section-heading margin-top-30 margin-bottom-5">' .. content .. '</h2>\n'
      html = html .. '<div class="section-react"></div>\n\n'
      html = html .. '<div class="display-flex">\n'
      html = html .. '  <div class="width-80">\n'
      
      -- Add summary box
      local pub_labels = {
        {'scholarly_pubs', 'peer_reviewed', 'SCHOLARLY PUBLICATIONS', 'PEER REVIEWED'},
        {'citations', 'h_index', 'GOOGLE SCHOLARLY CITATIONS', 'GOOGLE SCHOLARLY H-INDEX'}
      }
      html = html .. create_summary_box(summary_data, pub_labels)
      
      html = html .. '    <div class="left-bar-content margin-bottom-20">\n'
      
      return pandoc.RawBlock('html', html)
    -- Special handling for PRESENTATIONS section with summary
    elseif content:upper() == 'PRESENTATIONS' and next(presentation_summary) ~= nil then
      -- Close the main width-70 div BEFORE starting presentations (like publications does)
      closing = closing .. '</div>\n</div>\n\n'
      
      in_presentations = true
      current_year_section = "valid"  -- Reset year tracking for new section
      local html = closing .. '<h2 class="section-heading margin-top-30 margin-bottom-5">' .. content .. '</h2>\n'
      html = html .. '<div class="section-react"></div>\n\n'
      html = html .. '<div class="display-flex">\n'
      html = html .. '  <div class="width-80">\n'
      
      -- Add summary box
      local pres_labels = {
        {'total', 'invited', 'PRESENTATIONS', 'INVITED'},
        {'plenary', 'keynote', 'PLENARY PRESENTATIONS', 'KEYNOTE PRESENTATIONS'}
      }
      html = html .. create_summary_box(presentation_summary, pres_labels)
      
      html = html .. '    <div class="left-bar-content margin-bottom-20">\n'
      
      return pandoc.RawBlock('html', html)
    -- If this is a subsection in publications/presentations, use right-mark
    elseif is_subsection and (in_publications or in_presentations) then
      return pandoc.RawBlock('html', '<div class="right-mark">' .. content .. '</div>')
    else
      -- Regular section headings
      if is_education then
        -- EDUCATION: Just render H2, let markdown section-box handle it
        return pandoc.RawBlock('html', closing .. '<h2 class="section-heading">' .. content .. '</h2>\n<div class="section-react"></div>')
      elseif is_prof_appts then
        -- PROFESSIONAL APPOINTMENTS: Just render H2 with margin, stay in same section-box
        return pandoc.RawBlock('html', '<h2 class="section-heading margin-top-30">' .. content .. '</h2>\n<div class="section-react"></div>')
      else
        -- All other sections: regular H2 with section-react
        if content:upper() == 'AWARDS' or content:upper() == 'GRANT FUNDING' then
          return pandoc.RawBlock('html', closing .. '<h2 class="section-heading margin-top-30 margin-bottom-5">' .. content .. '</h2>\n<div class="section-react"></div>')
        else
          return pandoc.RawBlock('html', closing .. '<h2 class="section-heading">' .. content .. '</h2>\n<div class="section-react"></div>')
        end
      end
    end
  elseif el.level == 3 then
    -- H3 handling depends on context
    local content = pandoc.utils.stringify(el.content)
    
    -- Skip the duplicate SINCE 2019 SUMMARY in PRESENTATIONS markdown
    if content == "SINCE 2019 SUMMARY" and in_presentations then
      return pandoc.RawBlock('html', '')
    end
    
    -- Inside PUBLICATIONS or PRESENTATIONS: H3 becomes right-mark (subsection)
    if in_publications or in_presentations then
      -- Filter year subsections if date filtering enabled
      if date_filter_enabled then
        -- Check if this is a year (4 digits)
        if content:match("^%d%d%d%d$") then
          local year = tonumber(content)
          if not year_in_range(year) then
            current_year_section = nil  -- Mark that we're in a filtered-out year
            return pandoc.RawBlock('html', '')  -- Skip this year section
          else
            current_year_section = year  -- Track current valid year
          end
        -- If end year is not current year, remove non-digit subsections
        elseif filter_end_year ~= current_year and not content:match("%d") then
          current_year_section = nil  -- Mark non-year sections as filtered when end_year != current
          return pandoc.RawBlock('html', '')  -- Skip non-year subsections
        else
          -- For non-year subsections when end_year == current_year, allow them
          current_year_section = "valid"
        end
      else
        current_year_section = "valid"  -- No filtering, all sections valid
      end
      
      -- Special case: H3 with .left attribute gets left-aligned heading
      if el.classes:includes('left') then
        return pandoc.RawBlock('html', '<div class="small-heading">' .. content .. '</div>')
      else
        return pandoc.RawBlock('html', '<div class="right-mark">' .. content .. '</div>')
      end
    else
      -- Outside: H3 becomes small-heading
      return pandoc.RawBlock('html', '<h3 class="small-heading">' .. content .. '</h3>')
    end
  end
end

-- Process divs
function Div(el)
  -- Check for filter-exclude-when-dating attribute
  if date_filter_enabled and el.classes:includes('filter-exclude-when-dating') then
    return pandoc.RawBlock('html', '')
  end
  
  -- Date filtering for items with date attributes
  if date_filter_enabled and el.attributes['date'] then
    local date_text = el.attributes['date']
    local years = extract_years(date_text)
    if not ranges_overlap(years) then
      return pandoc.RawBlock('html', '')  -- Skip this item
    end
  end
  
  if el.classes:includes('line-item') then
    -- Handle line items (text | date format)
    local left = ''
    local right = ''
    
    -- Try to extract from div attributes or parse content
    if el.attributes['left'] and el.attributes['right'] then
      left = el.attributes['left']
      right = el.attributes['right']
    else
      -- Parse from first paragraph or plain content
      local block = el.content[1]
      local text = pandoc.utils.stringify(block)
      if text:match('|') then
        left, right = text:match('(.+)|(.+)')
        left = left and left:gsub('^%s*(.-)%s*$', '%1') or ''
        right = right and right:gsub('^%s*(.-)%s*$', '%1') or ''
      end
    end
    
    if left ~= '' and right ~= '' then
      return pandoc.RawBlock('html', [[
<div class="line-item">
  <div class="line-left">]] .. left .. [[</div>
  <div class="dotted-line"></div>
  <div class="line-right">]] .. right .. [[</div>
</div>]])
    end
  elseif el.classes:includes('summary-box') and in_presentations then
    -- Skip the manual summary-box in PRESENTATIONS markdown (we generate it)
    return pandoc.RawBlock('html', '')
  elseif el.classes:includes('grant-item') then
    -- Handle grant items with funding, optional project, and years
    local content = pandoc.utils.stringify(el.content)
    -- Process content for Alperin bold wrapping
    content = content:gsub('Alperin, J%.P%.', '<span class="font-agp-bold">Alperin, J.P.</span>')
    -- Process markdown formatting
    content = content:gsub('%*%*([^%*]+)%*%*', '<strong>%1</strong>')
    content = content:gsub('%*([^%*]+)%*', '<em>%1</em>')
    
    local funding = el.attributes['funding'] or ''
    local project = el.attributes['project'] or ''
    local years = el.attributes['years'] or ''
    
    local html = '<div class="award-line display-block">\n'
    html = html .. '<span class="award-title">' .. content .. '</span>\n'
    html = html .. '<div class="award-under">\n'
    html = html .. '  <div class="margin-right-10 font-size-12 f-b-b">\n'
    html = html .. '    <strong>requested funding: ' .. funding
    if project ~= '' then
      html = html .. ', total project: ' .. project
    end
    html = html .. '</strong>\n  </div>\n'
    html = html .. '  <div class="dotted-line"></div>\n'
    html = html .. '  <div class="margin-left-10"><strong>' .. years .. '</strong></div>\n'
    html = html .. '</div>\n</div>\n'
    return pandoc.RawBlock('html', html)
  elseif el.classes:includes('contribution-item') then
    -- Handle contribution items
    local content = pandoc.utils.stringify(el.content)
    content = content:gsub('Alperin, J%.P%.', '<span class="font-agp-bold">Alperin, J.P.</span>')
    content = content:gsub('%*%*([^%*]+)%*%*', '<strong>%1</strong>')
    content = content:gsub('%*([^%*]+)%*', '<em>%1</em>')
    
    return pandoc.RawBlock('html', 
      '<div class="award-line display-block">\n' ..
      '<span class="award-title">' .. content .. '</span>\n' ..
      '</div>')
  elseif el.classes:includes('media-item') then
    -- Handle media items (used in Professional Service, etc.)
    -- TWO-PASS APPROACH: preserve links while adding custom formatting
    
    -- PASS 1: Get text for custom patterns
    local text = pandoc.utils.stringify(el.content)
    
    -- PASS 2: Convert AST to HTML (preserving links and standard markdown)
    local content = pandoc.write(pandoc.Pandoc(el.content), 'html')
    -- Remove the wrapping <p> tags that pandoc adds
    content = content:gsub('^<p>', ''):gsub('</p>$', ''):gsub('</p>\n$', '')
    -- Add content-link class to all links
    content = content:gsub('<a%s+href="([^"]*)">', '<a href="%1" class="content-link">')
    
    -- PASS 3: Apply custom formatting that pandoc doesn't handle
    content = content:gsub('%.%.([^%.]+)%.%.', '<span class="dotted-text">%1</span>')
    content = content:gsub('%^', '<img src="Links/juanicons-colour-final-05.png" class="super-mail"/>')
    content = content:gsub('`([^`]+)`', '<span class="color-blue">%1</span>')
    
    local date = el.attributes['date'] or ''
    
    return pandoc.RawBlock('html', 
      '<div class="swap-item">\n' ..
      '<span class="swap-text">' .. content .. '</span>\n' ..
      '<div class="award-year">' .. date .. '</div>\n' ..
      '</div>')
  elseif el.classes:includes('award-item') then
    -- Handle award items with year on right
    local text_content = pandoc.utils.stringify(el.content)
    text_content = text_content:gsub('%*([^%*]+)%*', '<em>%1</em>')
    local year = el.attributes['year'] or ''
    
    return pandoc.RawBlock('html', [[
<div class="swap-item">
<span class="swap-text">]] .. text_content .. [[</span>
<div class="award-year">]] .. year .. [[</div>
</div>]])
  elseif el.classes:includes('summary-stats') then
    -- Handle summary statistics
    return pandoc.RawBlock('html', pandoc.utils.stringify(el.content))
  elseif el.classes:includes('two-column') then
    -- Two column layout
    local html = '<div class="display-flex">\n'
    local left_content = ''
    local right_content = ''
    local in_right = false
    
    for i, block in ipairs(el.content) do
      if block.t == 'HorizontalRule' then
        in_right = true
      elseif in_right then
        right_content = right_content .. pandoc.write(pandoc.Pandoc({block}), 'html')
      else
        left_content = left_content .. pandoc.write(pandoc.Pandoc({block}), 'html')
      end
    end
    
    html = html .. '  <div class="width-70">\n' .. left_content .. '\n  </div>\n'
    html = html .. '  <div class="width-30">\n' .. right_content .. '\n  </div>\n'
    html = html .. '</div>'
    
    return pandoc.RawBlock('html', html)
  end
end

-- Process list items for publications/presentations
function BulletList(el)
  -- Skip content if we're in a filtered-out year section
  if date_filter_enabled and current_year_section == nil then
    return pandoc.RawBlock('html', '')
  end
  
  -- Check if this is a publication/presentation list (contains icons or special markers)
  local first_item = el.content[1]
  if not first_item then return nil end
  
  local first_text = pandoc.utils.stringify(first_item)
  
  -- Check if it looks like a publication (has icons or author names or dates in parens)
  -- OR if we're in publications/presentations context
  if (in_publications or in_presentations) or 
     first_text:match('%[') or first_text:match('%*%*') or first_text:match('%(.*%d%d%d%d.*%)') then
    local items = {}
    
    for i, item in ipairs(el.content) do
      local text = pandoc.utils.stringify(item)
      
      -- Extract icons from [icon1,icon2]
      local icons_list = {}
      local content = text
      local icon_str = text:match('^%[([^%]]+)%]')
      if icon_str then
        for icon_name in icon_str:gmatch('[^,]+') do
          table.insert(icons_list, icon_name:match('^%s*(.-)%s*$'))
        end
        content = text:gsub('^%[[^%]]+%]%s*', '')
      end
      
      -- Extract GS citations {GS:123}
      local gs_citations = content:match('{GS:(%d+)}')
      if gs_citations then
        content = content:gsub('%{GS:%d+%}', '')
      end
      
      -- Build HTML for this item
      local html = '<div class="content-item margin-top-10">\n'
      
      -- Icons and GS citations
      if #icons_list > 0 or gs_citations then
        html = html .. '  <div class="display-block">\n'
        html = html .. '    <div class="content-preview">\n'
        
        if #icons_list == 0 then
          html = html .. '      <div style="width: 22px"></div>\n'
        end
        
        for _, icon_name in ipairs(icons_list) do
          local icon_file = icons[icon_name]
          if icon_file then
            local size = ''
            if icon_name == 'peer-reviewed' or icon_name == 'invited' then
              size = ' style="width: 20px; height: 20px"'
            end
            html = html .. '      <img src="Links/' .. icon_file .. '"' .. size .. ' class="margin-0"/>\n'
          end
        end
        
        html = html .. '    </div>\n'
        
        if gs_citations then
          html = html .. '    <div>\n'
          html = html .. '      <span class="google-scholar-mark"><strong>GS</strong> ' .. format_with_commas(gs_citations) .. '</span>\n'
          html = html .. '    </div>\n'
        end
        
        html = html .. '  </div>\n'
      else
        html = html .. '  <div class="content-preview">\n'
        html = html .. '    <div style="width: 22px"></div>\n'
        html = html .. '  </div>\n'
      end
      
      -- Format the content text
      -- Bold for **text**
      content = content:gsub('%*%*([^%*]+)%*%*', '<span class="font-agp-bold">%1</span>')
      -- Wrap "Alperin, J.P." in bold
      content = content:gsub('Alperin, J%.P%.', '<span class="font-agp-bold">Alperin, J.P.</span>')
      -- Italic for *text*
      content = content:gsub('%*([^%*]+)%*', '<em class="font-agp-italic">%1</em>')
      -- Wavy for ~~text~~
      content = content:gsub('~~([^~]+)~~', '<span class="wavy-text">%1</span>')
      -- Dotted for ..text.. (handle both dots and ellipsis)
      content = content:gsub('%.%.([^%.…]+)%.%.', '<span class="dotted-text">%1</span>')
      content = content:gsub('%.%.([^%.…]+)…', '<span class="dotted-text">%1</span>')
      -- Corresponding author ^
      content = content:gsub('%^', '<img src="Links/juanicons-colour-final-05.png" class="super-mail"/>')
      -- Blue text `text`
      content = content:gsub('`([^`]+)`', '<span class="color-blue">%1</span>')
      -- Links {text}(url)
      content = content:gsub('{([^}]+)}%(([^)]+)%)', '<a class="content-link">%1</a>')
      
      html = html .. '  <div class="content-text">\n'
      html = html .. '    ' .. content .. '\n'
      html = html .. '  </div>\n'
      html = html .. '</div>\n'
      
      table.insert(items, pandoc.RawBlock('html', html))
    end
    
    return items
  end
end

-- At the end of the document, handle sidebars and close any open wrappers
function Pandoc(doc)
  local new_blocks = {}
  local has_sidebar = false
  
  -- Setup date filtering from metadata
  if doc.meta.filter_start_year then
    filter_start_year = tonumber(pandoc.utils.stringify(doc.meta.filter_start_year))
    filter_end_year = doc.meta.filter_end_year and tonumber(pandoc.utils.stringify(doc.meta.filter_end_year)) or current_year
    date_filter_enabled = true
  elseif doc.meta.filter_end_year then
    filter_start_year = 1900  -- Default very early start
    filter_end_year = tonumber(pandoc.utils.stringify(doc.meta.filter_end_year))
    date_filter_enabled = true
  end
  
  -- Process metadata FIRST before doing anything else
  if doc.meta.summary then
    for k, v in pairs(doc.meta.summary) do
      summary_data[k] = pandoc.utils.stringify(v)
    end
  end
  
  -- Auto-update Google Scholar data from gs_author_stats YAML if available
  if doc.meta.total_citations_5y then
    summary_data['citations'] = format_with_commas(pandoc.utils.stringify(doc.meta.total_citations_5y))
  end
  if doc.meta.h_index_5y then
    summary_data['h_index'] = pandoc.utils.stringify(doc.meta.h_index_5y)
  end
  if doc.meta.presentation_summary then
    for k, v in pairs(doc.meta.presentation_summary) do
      presentation_summary[k] = pandoc.utils.stringify(v)
    end
  end
  
  -- Check if we have sidebar in metadata and build it
  if doc.meta.sidebar and pandoc.utils.stringify(doc.meta.sidebar) == 'true' then
    has_sidebar = true
    -- Build sidebar content (research interests)
    if doc.meta['research-interests'] then
      sidebar_content = '<div class="research-box width-30">\n'
      sidebar_content = sidebar_content .. '  <h2>RESEARCH<br/>INTERESTS</h2>\n'
      sidebar_content = sidebar_content .. '  <ul>\n'
      for k, v in pairs(doc.meta['research-interests']) do
        sidebar_content = sidebar_content .. '    <li>' .. pandoc.utils.stringify(v) .. '</li>\n'
      end
      sidebar_content = sidebar_content .. '  </ul>\n'
      sidebar_content = sidebar_content .. '</div>\n'
    end
  end
  
  -- ALWAYS add the display-flex wrapper at the document level
  table.insert(new_blocks, pandoc.RawBlock('html', '<div class="display-flex">\n<div class="width-70">'))
  
  -- Add all document blocks
  for i, block in ipairs(doc.blocks) do
    table.insert(new_blocks, block)
  end
  
  -- Close any open publications/presentations wrappers
  if in_publications or in_presentations then
    table.insert(new_blocks, pandoc.RawBlock('html', '    </div>\n  </div>\n' .. create_legend() .. '</div>'))
    in_publications = false
    in_presentations = false
    -- In this case, the main containers were already closed, don't close again
  else
    -- Close the width-70 wrapper
    table.insert(new_blocks, pandoc.RawBlock('html', '</div>'))
    -- Close the display-flex wrapper  
    table.insert(new_blocks, pandoc.RawBlock('html', '</div>'))
  end
  
  doc.blocks = new_blocks
  return doc
end

-- Return filter with explicit execution order
-- This ensures Pandoc() runs first to load metadata, then other filters run
return {
  {Pandoc = Pandoc},
  {Header = Header, Div = Div, BulletList = BulletList, Span = Span, Meta = Meta}
}