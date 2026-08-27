-- cv-stats-filter.lua
-- Calculates yearly publication statistics from CV markdown
-- Counts both traditional publications and non-traditional outputs
-- Handles non-numeric sections like "under review", "in press"

-- Track stats
local yearly_stats = {}
local yearly_presentation_stats = {}
local current_year = nil
local in_publications = false
local in_presentations = false
local in_nontraditional = false
local total_publications = 0
local total_peer_reviewed = 0
local total_presentations = 0
local total_invited = 0
local total_keynote = 0
local total_plenary = 0
local total_peer_reviewed_presentations = 0

-- Helper function to extract year from heading
local function extract_year(text)
    local year = string.match(text, "^(%d%d%d%d)$")
    if year then
        return tonumber(year)
    end
    return nil
end

-- Helper function to check if text contains non-numeric section indicators
local function is_nonnumeric_section(text)
    local lower_text = string.lower(text)
    return string.match(lower_text, "under review") or
           string.match(lower_text, "in review") or 
           string.match(lower_text, "in press") or
           string.match(lower_text, "submitted") or
           string.match(lower_text, "accepted")
end

-- Helper function to count publications in a list item
local function count_publication_types(content)
    local text = pandoc.utils.stringify(content)
    local peer_reviewed = 0
    local total = 1  -- Each list item is one publication
    
    -- Check for peer-reviewed indicator
    if string.match(text, "%[peer%-reviewed") then
        peer_reviewed = 1
    end
    
    return total, peer_reviewed
end

-- Helper function to count presentations in a list item
local function count_presentation_types(content)
    local text = pandoc.utils.stringify(content)
    local invited = 0
    local keynote = 0
    local plenary = 0
    local peer_reviewed = 0
    local total = 1  -- Each list item is one presentation
    
    -- Check for presentation type indicators
    if string.match(text, "%[invited") then
        invited = 1
    end
    if string.match(text, "keynote%]") then
        keynote = 1
    end
    if string.match(text, "plenary%]") then
        plenary = 1
    end
    if string.match(text, "%[peer%-reviewed%]") then
        peer_reviewed = 1
    end
    
    return total, invited, keynote, plenary, peer_reviewed
end

-- Simple YAML output function
local function write_yaml(data, filename)
    local file = io.open(filename, "w")
    if not file then
        return false
    end
    
    file:write("# CV Yearly Statistics\n")
    file:write("summary:\n")
    file:write("  scholarly_pubs: " .. data.summary.scholarly_pubs .. "\n")
    file:write("  peer_reviewed: " .. data.summary.peer_reviewed .. "\n")
    file:write("  total_publications: " .. data.summary.total_publications .. "\n")
    file:write("\npresentation_summary:\n")
    file:write("  total: " .. data.presentation_summary.total .. "\n")
    file:write("  invited: " .. data.presentation_summary.invited .. "\n")
    file:write("  keynote: " .. data.presentation_summary.keynote .. "\n")
    file:write("  plenary: " .. data.presentation_summary.plenary .. "\n")
    file:write("  peer_reviewed: " .. data.presentation_summary.peer_reviewed .. "\n")
    
    file:write("\nyearly_stats:\n")
    
    -- Sort years
    local years = {}
    for year in pairs(data.yearly_stats) do
        table.insert(years, year)
    end
    table.sort(years, function(a, b)
        if a == "non_numeric" then return false end
        if b == "non_numeric" then return true end
        return a > b  -- Descending order
    end)
    
    for _, year in ipairs(years) do
        local stats = data.yearly_stats[year]
        if year == "non_numeric" then
            file:write("  non_numeric:\n")
        else
            file:write("  " .. year .. ":\n")
        end
        file:write("    total: " .. stats.total .. "\n")
        file:write("    peer_reviewed: " .. stats.peer_reviewed .. "\n")
        file:write("    traditional: " .. stats.traditional .. "\n")
        file:write("    nontraditional: " .. stats.nontraditional .. "\n")
    end
    
    file:write("\nyearly_presentation_stats:\n")
    
    -- Sort years for presentations
    local pres_years = {}
    for year in pairs(data.yearly_presentation_stats) do
        table.insert(pres_years, year)
    end
    table.sort(pres_years, function(a, b)
        if a == "non_numeric" then return false end
        if b == "non_numeric" then return true end
        return a > b  -- Descending order
    end)
    
    for _, year in ipairs(pres_years) do
        local stats = data.yearly_presentation_stats[year]
        if year == "non_numeric" then
            file:write("  non_numeric:\n")
        else
            file:write("  " .. year .. ":\n")
        end
        file:write("    total: " .. stats.total .. "\n")
        file:write("    invited: " .. stats.invited .. "\n")
        file:write("    keynote: " .. stats.keynote .. "\n")
        file:write("    plenary: " .. stats.plenary .. "\n")
        file:write("    peer_reviewed: " .. stats.peer_reviewed .. "\n")
    end
    
    file:close()
    return true
end

-- Process headers to track sections and years
function Header(elem)
    local text = pandoc.utils.stringify(elem.content)
    
    -- Track if we're in publications section
    if elem.level == 2 and string.upper(text) == "PUBLICATIONS" then
        in_publications = true
        in_presentations = false
        in_nontraditional = false
        return elem
    end
    
    -- Track if we're in presentations section
    if elem.level == 2 and string.upper(text) == "PRESENTATIONS" then
        in_presentations = true
        in_publications = false
        in_nontraditional = false
        return elem
    end
    
    -- Track if we're in non-traditional outputs
    if elem.level == 3 and string.match(string.upper(text), "NON%-TRADITIONAL OUTPUTS") then
        in_nontraditional = true
        return elem
    end
    
    -- Reset section tracking for other level 2 headers
    if elem.level == 2 and string.upper(text) ~= "PUBLICATIONS" and string.upper(text) ~= "PRESENTATIONS" then
        in_publications = false
        in_presentations = false
        in_nontraditional = false
        current_year = nil
        return elem
    end
    
    -- Track year headers within publications or presentations
    if (in_publications or in_presentations or in_nontraditional) and elem.level == 3 then
        local year = extract_year(text)
        if year then
            current_year = year
            if not yearly_stats[year] then
                yearly_stats[year] = {
                    total = 0,
                    peer_reviewed = 0,
                    traditional = 0,
                    nontraditional = 0
                }
            end
            if not yearly_presentation_stats[year] then
                yearly_presentation_stats[year] = {
                    total = 0,
                    invited = 0,
                    keynote = 0,
                    plenary = 0,
                    peer_reviewed = 0
                }
            end
        elseif is_nonnumeric_section(text) then
            -- For non-numeric sections, use a special key
            current_year = "non_numeric"
            if not yearly_stats["non_numeric"] then
                yearly_stats["non_numeric"] = {
                    total = 0,
                    peer_reviewed = 0,
                    traditional = 0,
                    nontraditional = 0
                }
            end
            if not yearly_presentation_stats["non_numeric"] then
                yearly_presentation_stats["non_numeric"] = {
                    total = 0,
                    invited = 0,
                    keynote = 0,
                    plenary = 0,
                    peer_reviewed = 0
                }
            end
        else
            current_year = nil
        end
    end
    
    return elem
end

-- Process bullet lists to count publications and presentations
function BulletList(elem)
    if not (in_publications or in_presentations or in_nontraditional) or not current_year then
        return elem
    end
    
    for _, item in ipairs(elem.content) do
        if in_presentations then
            -- Count presentation types
            local total, invited, keynote, plenary, peer_reviewed = count_presentation_types(item)
            
            if yearly_presentation_stats[current_year] then
                yearly_presentation_stats[current_year].total = yearly_presentation_stats[current_year].total + total
                yearly_presentation_stats[current_year].invited = yearly_presentation_stats[current_year].invited + invited
                yearly_presentation_stats[current_year].keynote = yearly_presentation_stats[current_year].keynote + keynote
                yearly_presentation_stats[current_year].plenary = yearly_presentation_stats[current_year].plenary + plenary
                yearly_presentation_stats[current_year].peer_reviewed = yearly_presentation_stats[current_year].peer_reviewed + peer_reviewed
                
                -- Update global totals
                total_presentations = total_presentations + total
                total_invited = total_invited + invited
                total_keynote = total_keynote + keynote
                total_plenary = total_plenary + plenary
                total_peer_reviewed_presentations = total_peer_reviewed_presentations + peer_reviewed
            end
        else
            -- Count publication types (publications or non-traditional)
            local total, peer_reviewed = count_publication_types(item)
            
            if yearly_stats[current_year] then
                yearly_stats[current_year].total = yearly_stats[current_year].total + total
                yearly_stats[current_year].peer_reviewed = yearly_stats[current_year].peer_reviewed + peer_reviewed
                
                -- Track traditional vs non-traditional
                if in_nontraditional then
                    yearly_stats[current_year].nontraditional = yearly_stats[current_year].nontraditional + total
                else
                    yearly_stats[current_year].traditional = yearly_stats[current_year].traditional + total
                end
                
                -- Update global totals
                total_publications = total_publications + total
                total_peer_reviewed = total_peer_reviewed + peer_reviewed
            end
        end
    end
    
    return elem
end

-- Process the document and save stats
function Pandoc(doc)
    -- Calculate overall totals
    local scholarly_pubs = 0
    for year, stats in pairs(yearly_stats) do
        if year ~= "non_numeric" then
            scholarly_pubs = scholarly_pubs + stats.total
        end
    end
    
    -- Prepare stats for saving
    local stats_output = {
        summary = {
            scholarly_pubs = scholarly_pubs,
            peer_reviewed = total_peer_reviewed,
            total_publications = total_publications
        },
        presentation_summary = {
            total = total_presentations,
            invited = total_invited,
            keynote = total_keynote,
            plenary = total_plenary,
            peer_reviewed = total_peer_reviewed_presentations
        },
        yearly_stats = yearly_stats,
        yearly_presentation_stats = yearly_presentation_stats
    }
    
    -- Save to YAML file
    if write_yaml(stats_output, "cv_yearly_stats.yaml") then
        io.stderr:write("📊 Yearly stats saved to cv_yearly_stats.yaml\n")
    else
        io.stderr:write("⚠️  Warning: Could not save yearly stats\n")
    end
    
    -- Update document metadata with calculated stats
    if doc.meta.summary then
        doc.meta.summary.scholarly_pubs = scholarly_pubs
        doc.meta.summary.peer_reviewed = total_peer_reviewed
    else
        doc.meta.summary = {
            scholarly_pubs = scholarly_pubs,
            peer_reviewed = total_peer_reviewed
        }
    end
    
    return doc
end