local utils = require("pandoc.utils")

local citations = {}

-- Robust CSV line splitter (handles quoted fields with commas)
local function split_csv_line(line)
  local res = {}
  local i = 1
  local in_quotes = false
  local field = ""
  while i <= #line do
    local c = line:sub(i,i)
    if c == '"' then
      in_quotes = not in_quotes
    elseif c == "," and not in_quotes then
      table.insert(res, field)
      field = ""
    else
      field = field .. c
    end
    i = i + 1
  end
  table.insert(res, field)
  return res
end

-- Load CSV into citations table keyed by pub_id
local function load_csv(csv_file)
  local f = io.open(csv_file, "r")
  if not f then
    io.stderr:write("ERROR: Could not open CSV file: " .. csv_file .. "\n")
    return
  end

  local header_line = f:read("*l")
  if not header_line then
    io.stderr:write("ERROR: CSV file is empty: " .. csv_file .. "\n")
    f:close()
    return
  end

  local cols = split_csv_line(header_line)

  for line in f:lines() do
    local entry = {}
    local fields = split_csv_line(line)
    for i, col in ipairs(cols) do
      entry[col] = fields[i] or ""
    end
    if entry["pub_id"] and entry["num_citations"] then
      citations[entry["pub_id"]] = entry["num_citations"]
    end
  end
  f:close()
end

-- Replace {GS:ID} in string
local function replace_gs_ids(s)
  return (s:gsub("{GS:%s*(.-)%s*}", function(id)
    local count = citations[id]
    if count then
      -- citation found, format it
      return "{GS:" .. count .. "}" -- formatted citation
    elseif tonumber(id) then
      -- id itself is numeric, leave as-is
      return "{GS:" .. id .. "}"
    else
      -- not found and not numeric, warn and remove
      io.stderr:write("WARNING: No citation found for " .. id .. "\n")
      return ""
    end
  end))
end

-- Process all inline elements in a block
local function process_inlines(inlines)
  for i, elem in ipairs(inlines) do
    if elem.t == "Str" then
      inlines[i] = pandoc.Str(replace_gs_ids(elem.text))
    end
  end
  return inlines
end

-- Pandoc filter
return {
  {
    Meta = function(meta)
      if not meta.gs_csv then
        io.stderr:write("ERROR: gs_csv not defined in YAML metadata.\n")
        os.exit(1)
      end
      local csv_file = utils.stringify(meta.gs_csv)
      load_csv(csv_file)
    end
  },
  {
    Para = function(el)
      el.content = process_inlines(el.content)
      return el
    end
  },
  {
    Plain = function(el)
      el.content = process_inlines(el.content)
      return el
    end
  }
}
