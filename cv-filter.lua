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
local yearly_stats = {}
local yearly_presentation_stats = {}

-- Helper function to load YAML file content
local function load_yaml_file(filename)
  local file = io.open(filename, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

-- Simple YAML parser for yearly stats (specific to our format)
local function parse_yearly_stats_yaml(content)
  local stats = {}
  local pres_stats = {}
  local current_year = nil
  local in_presentations = false
  
  for line in content:gmatch("[^\r\n]+") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")  -- trim
    
    -- Check for section headers
    if line:match("^yearly_presentation_stats:$") then
      in_presentations = true
      current_year = nil
    elseif line:match("^yearly_stats:$") then
      in_presentations = false
      current_year = nil
    -- Parse year headers
    elseif line:match("^(%d+):$") then
      local year_match = line:match("^(%d+):$")
      current_year = tonumber(year_match)
      if in_presentations then
        pres_stats[current_year] = {}
      else
        stats[current_year] = {}
      end
    elseif line:match("^non_numeric:$") then
      current_year = "non_numeric"
      if in_presentations then
        pres_stats["non_numeric"] = {}
      else
        stats["non_numeric"] = {}
      end
    -- Parse stat values
    elseif current_year and line:match(":") then
      local key, value = line:match("^([^:]+):%s*(.*)$")
      if key and value then
        key = key:gsub("^%s+", ""):gsub("%s+$", "")
        value = value:gsub("^%s+", ""):gsub("%s+$", "")
        if tonumber(value) then
          if in_presentations then
            pres_stats[current_year][key] = tonumber(value)
          else
            stats[current_year][key] = tonumber(value)
          end
        else
          if in_presentations then
            pres_stats[current_year][key] = value
          else
            stats[current_year][key] = value
          end
        end
      end
    end
  end
  
  return stats, pres_stats
end

-- Helper function to calculate filtered summary from yearly stats
local function calculate_filtered_summary()
  if not next(yearly_stats) then return end
  
  local total_pubs = 0
  local total_peer_reviewed = 0
  
  -- If no date filtering, include everything including non_numeric
  if not date_filter_enabled then
    for year, stats in pairs(yearly_stats) do
      if stats.total then
        total_pubs = total_pubs + stats.total
      end
      if stats.peer_reviewed then
        total_peer_reviewed = total_peer_reviewed + stats.peer_reviewed
      end
    end
  else
    -- With date filtering, calculate only for years in range + non_numeric (treated as current year)
    for year, stats in pairs(yearly_stats) do
      local include_year = false
      
      if year == "non_numeric" then
        -- Treat non_numeric as current year for filtering
        include_year = year_in_range(current_year)
      elseif type(year) == "number" then
        include_year = year_in_range(year)
      end
      
      if include_year and stats.total then
        total_pubs = total_pubs + stats.total
        if stats.peer_reviewed then
          total_peer_reviewed = total_peer_reviewed + stats.peer_reviewed
        end
      end
    end
  end
  
  -- Update summary data with calculated values
  summary_data['scholarly_pubs'] = tostring(total_pubs)
  summary_data['peer_reviewed'] = tostring(total_peer_reviewed)
end

-- Helper function to calculate filtered presentation summary from yearly presentation stats
local function calculate_filtered_presentation_summary()
  if not next(yearly_presentation_stats) then return end
  
  local total_presentations = 0
  local total_invited = 0
  local total_keynote = 0
  local total_plenary = 0
  local total_peer_reviewed_presentations = 0
  
  -- If no date filtering, include everything including non_numeric
  if not date_filter_enabled then
    for year, stats in pairs(yearly_presentation_stats) do
      if stats.total then
        total_presentations = total_presentations + stats.total
      end
      if stats.invited then
        total_invited = total_invited + stats.invited
      end
      if stats.keynote then
        total_keynote = total_keynote + stats.keynote
      end
      if stats.plenary then
        total_plenary = total_plenary + stats.plenary
      end
      if stats.peer_reviewed then
        total_peer_reviewed_presentations = total_peer_reviewed_presentations + stats.peer_reviewed
      end
    end
  else
    -- With date filtering, calculate only for years in range + non_numeric (treated as current year)
    for year, stats in pairs(yearly_presentation_stats) do
      local include_year = false
      
      if year == "non_numeric" then
        -- Treat non_numeric as current year for filtering
        include_year = year_in_range(current_year)
      elseif type(year) == "number" then
        include_year = year_in_range(year)
      end
      
      if include_year then
        if stats.total then
          total_presentations = total_presentations + stats.total
        end
        if stats.invited then
          total_invited = total_invited + stats.invited
        end
        if stats.keynote then
          total_keynote = total_keynote + stats.keynote
        end
        if stats.plenary then
          total_plenary = total_plenary + stats.plenary
        end
        if stats.peer_reviewed then
          total_peer_reviewed_presentations = total_peer_reviewed_presentations + stats.peer_reviewed
        end
      end
    end
  end
  
  -- Update presentation summary data with calculated values
  presentation_summary['total'] = tostring(total_presentations)
  presentation_summary['invited'] = tostring(total_invited)
  presentation_summary['keynote'] = tostring(total_keynote)
  presentation_summary['plenary'] = tostring(total_plenary)
  presentation_summary['peer-reviewed'] = tostring(total_peer_reviewed_presentations)
end

-- Global variable for sidebar content (research interests)
local sidebar_content = ''

-- Track if we opened a publications or presentations wrapper
local in_publications = false
local in_presentations = false
local current_year_section = nil  -- Track current year for content filtering
local current_section = nil  -- Track current major section

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
  local title = "SUMMARY"
  if date_filter_enabled then
    if filter_start_year and filter_end_year then
      title = filter_start_year .. "–" .. filter_end_year .. " SUMMARY"
    elseif filter_start_year then
      title = "SINCE " .. filter_start_year .. " SUMMARY"
    elseif filter_end_year then
      title = "THROUGH " .. filter_end_year .. " SUMMARY"
    end
  end
  
  local html = '    <div class="summary-title">' .. title .. '</div>\n'
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
    
    -- Track current section for special formatting
    current_section = content:upper()
    
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
    
    -- Track current section for p-tag removal
    current_section = content
    
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
      -- Conditionally add section-react div
      if not el.classes:includes('no-heading-underline') then
        html = html .. '<div class="section-react"></div>\n\n'
      else
        html = html .. '\n'
      end
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
      -- Conditionally add section-react div
      if not el.attributes['no-react'] then
        html = html .. '<div class="section-react"></div>\n\n'
      else
        html = html .. '\n'
      end
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
        -- EDUCATION: Just render H2 (no section-react since it's in section-box)
        return pandoc.RawBlock('html', closing .. '<h2 class="section-heading">' .. content .. '</h2>')
      elseif is_prof_appts then
        -- PROFESSIONAL APPOINTMENTS: Just render H2 with margin (no section-react since it's in section-box)
        return pandoc.RawBlock('html', '<h2 class="section-heading margin-top-30">' .. content .. '</h2>')
      else
        -- All other sections: regular H2 with conditional section-react
        local react_div = el.classes:includes('no-heading-underline') and '' or '\n<div class="section-react"></div>'
        if content:upper() == 'AWARDS' or content:upper() == 'GRANT FUNDING' then
          return pandoc.RawBlock('html', closing .. '<h2 class="section-heading margin-top-30 margin-bottom-5">' .. content .. '</h2>' .. react_div)
        else
          return pandoc.RawBlock('html', closing .. '<h2 class="section-heading">' .. content .. '</h2>' .. react_div)
        end
      end
    end
  elseif el.level == 3 then
    -- H3 handling depends on context
    local content = pandoc.utils.stringify(el.content)
    
    -- Skip the duplicate SINCE 2019 SUMMARY in PRESENTATIONS markdown
    if content == "SUMMARY" and in_presentations then
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
        -- If end year is not current year, remove non-digit subsections (except .left headings like NON-TRADITIONAL OUTPUTS)
        elseif filter_end_year ~= current_year and not content:match("%d") and not el.classes:includes('left') then
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
    -- Check date filtering first
    if date_filter_enabled and el.attributes['years'] then
      local years_text = el.attributes['years']
      local years = extract_years(years_text)
      if not ranges_overlap(years) then
        return pandoc.RawBlock('html', '')  -- Skip this item
      end
    end
    
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
    local year = el.attributes['date'] or el.attributes['year'] or ''
    
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
  
  -- Special handling for Professional Appointments section
  if current_section == "PROFESSIONAL APPOINTMENTS" then
    local html = '<ul class="no-bullet">\n'
    for i, item in ipairs(el.content) do
      local content = pandoc.write(pandoc.Pandoc(item), 'html')
      -- Remove p tags
      content = content:gsub('^<p>', ''):gsub('</p>$', ''):gsub('</p>\n$', '')
      
      -- Split on <br /> or <br/> to create separate divs
      local parts = {}
      local current_part = ""
      
      -- Split the content by line breaks
      for chunk in (content .. "<br />"):gmatch("(.-)<br%s*/?%s*>") do
        chunk = chunk:match('^%s*(.-)%s*$') or "" -- trim whitespace
        if chunk ~= "" then
          table.insert(parts, chunk)
        end
      end
      
      html = html .. '  <li>\n'
      for j, part in ipairs(parts) do
        if j == 2 then
          -- Second part gets font-agp-regular class
          html = html .. '    <div class="font-agp-regular">' .. part .. '</div>\n'
        else
          html = html .. '    <div>' .. part .. '</div>\n'
        end
      end
      html = html .. '  </li>\n'
    end
    html = html .. '</ul>\n'
    return pandoc.RawBlock('html', html)
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

-- Helper function to remove empty sections when date filtering is enabled
local function remove_empty_sections(blocks)
  local filtered_blocks = {}
  local i = 1
  
  while i <= #blocks do
    local block = blocks[i]
    
    -- Check if this is a section header (H2)
    if block.t == "RawBlock" and block.format == "html" and 
       block.text:match('<h2[^>]*class="section%-heading') then
      
      -- Collect all blocks in this section
      local section_blocks = {block} -- Start with the header
      local j = i + 1
      local has_content = false
      
      -- Collect blocks until next H2 or end
      while j <= #blocks do
        local next_block = blocks[j]
        
        -- Stop if we hit another H2 section
        if next_block.t == "RawBlock" and next_block.format == "html" and
           next_block.text:match('<h2[^>]*class="section%-heading') then
          break
        end
        
        table.insert(section_blocks, next_block)
        
        -- Check if this block contains real content (not just headers/whitespace)
        if next_block.t == "RawBlock" and next_block.format == "html" then
          local content = next_block.text
          -- Look for actual content blocks (swap-item, award-line, content-item, etc.)
          if content:match('<div class="swap%-item">') or
             content:match('<div class="award%-line') or  
             content:match('<div class="content%-item') or
             content:match('<ul') or
             content:match('<li>') then
            has_content = true
          end
        elseif next_block.t ~= "RawBlock" then
          -- Non-raw blocks (like Para, etc.) are considered content
          has_content = true
        end
        
        j = j + 1
      end
      
      -- Only keep the section if it has real content
      if has_content then
        for _, section_block in ipairs(section_blocks) do
          table.insert(filtered_blocks, section_block)
        end
      end
      
      -- Move to next section
      i = j
      
    -- Check if this is an H3 subsection header
    elseif block.t == "RawBlock" and block.format == "html" and 
           block.text:match('<h3[^>]*class="small.heading') then
      
      -- Collect all blocks in this H3 subsection
      local subsection_blocks = {block} -- Start with the H3 header
      local j = i + 1
      local has_content = false
      
      -- Collect blocks until next H2, H3, or end
      while j <= #blocks do
        local next_block = blocks[j]
        
        -- Stop if we hit another H2 or H3 section
        if next_block.t == "RawBlock" and next_block.format == "html" and
           (next_block.text:match('<h2[^>]*class="section.heading') or
            next_block.text:match('<h3[^>]*class="small.heading')) then
          break
        end
        
        table.insert(subsection_blocks, next_block)
        
        -- Check if this block contains real content
        if next_block.t == "RawBlock" and next_block.format == "html" then
          local content = next_block.text
          -- Look for actual content blocks
          if content:match('<div class="swap%-item">') or
             content:match('<div class="award%-line') or  
             content:match('<div class="content%-item') or
             content:match('<ul') or
             content:match('<li>') then
            has_content = true
          end
        elseif next_block.t ~= "RawBlock" then
          -- Non-raw blocks are considered content
          has_content = true
        end
        
        j = j + 1
      end
      
      -- Only keep the H3 subsection if it has real content
      if has_content then
        for _, subsection_block in ipairs(subsection_blocks) do
          table.insert(filtered_blocks, subsection_block)
        end
      end
      
      -- Move to next subsection/section
      i = j
    else
      -- Not a section header, keep the block
      table.insert(filtered_blocks, block)
      i = i + 1
    end
  end
  
  return filtered_blocks
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
  
  -- Load yearly stats from YAML file
  local yaml_content = load_yaml_file("cv_yearly_stats.yaml")
  if yaml_content then
    yearly_stats, yearly_presentation_stats = parse_yearly_stats_yaml(yaml_content)
    io.stderr:write("📊 Loaded yearly stats for dynamic summary calculation\n")
  end
  
  -- Process metadata FIRST before doing anything else
  if doc.meta.summary then
    for k, v in pairs(doc.meta.summary) do
      summary_data[k] = pandoc.utils.stringify(v)
    end
  end
  
  -- Calculate filtered summary from yearly stats (overwrites static values if filtering is enabled)
  calculate_filtered_summary()
  
  -- Process presentation metadata 
  if doc.meta.presentation_summary then
    for k, v in pairs(doc.meta.presentation_summary) do
      presentation_summary[k] = pandoc.utils.stringify(v)
    end
  end
  
  -- Calculate filtered presentation summary from yearly presentation stats
  calculate_filtered_presentation_summary()
  
  -- Auto-update Google Scholar data from gs_author_stats YAML if available
  if doc.meta.total_citations_5y then
    summary_data['citations'] = format_with_commas(pandoc.utils.stringify(doc.meta.total_citations))
  end
  if doc.meta.h_index_5y then
    summary_data['h_index'] = pandoc.utils.stringify(doc.meta.h_index)
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