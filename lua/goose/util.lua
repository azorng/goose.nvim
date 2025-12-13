local M = {}

function M.template(str, vars)
  return (str:gsub("{(.-)}", function(key)
    return tostring(vars[key] or "")
  end))
end

function M.uid()
  return tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
end

function M.is_current_buf_a_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  local filepath = vim.fn.expand('%:p')

  -- Valid files have empty buftype
  -- This excludes special buffers like help, terminal, nofile, etc.
  return buftype == "" and filepath ~= ""
end

function M.indent_code_block(text)
  if not text then return nil end
  local lines = vim.split(text, "\n", true)

  local first, last = nil, nil
  for i, line in ipairs(lines) do
    if line:match("[^%s]") then
      first = first or i
      last = i
    end
  end

  if not first then return "" end

  local content = {}
  for i = first, last do
    table.insert(content, lines[i])
  end

  local min_indent = math.huge
  for _, line in ipairs(content) do
    if line:match("[^%s]") then
      min_indent = math.min(min_indent, line:match("^%s*"):len())
    end
  end

  if min_indent < math.huge and min_indent > 0 then
    for i, line in ipairs(content) do
      if line:match("[^%s]") then
        content[i] = line:sub(min_indent + 1)
      end
    end
  end

  return vim.trim(table.concat(content, "\n"))
end

-- Get timezone offset in seconds for various timezone formats
function M.get_timezone_offset(timezone)
  -- Handle numeric timezone formats (+HHMM, -HHMM)
  if timezone:match("^[%+%-]%d%d:?%d%d$") then
    local sign = timezone:sub(1, 1) == "+" and 1 or -1
    local hours = tonumber(timezone:match("^[%+%-](%d%d)"))
    local mins = tonumber(timezone:match("^[%+%-]%d%d:?(%d%d)$") or "00")
    return sign * (hours * 3600 + mins * 60)
  end

  -- Map of common timezone abbreviations to their offset in seconds from UTC
  local timezone_map = {
    -- Zero offset timezones
    ["UTC"] = 0,
    ["GMT"] = 0,

    -- North America
    ["EST"] = -5 * 3600,
    ["EDT"] = -4 * 3600,
    ["CST"] = -6 * 3600,
    ["CDT"] = -5 * 3600,
    ["MST"] = -7 * 3600,
    ["MDT"] = -6 * 3600,
    ["PST"] = -8 * 3600,
    ["PDT"] = -7 * 3600,
    ["AKST"] = -9 * 3600,
    ["AKDT"] = -8 * 3600,
    ["HST"] = -10 * 3600,

    -- Europe
    ["WET"] = 0,
    ["WEST"] = 1 * 3600,
    ["CET"] = 1 * 3600,
    ["CEST"] = 2 * 3600,
    ["EET"] = 2 * 3600,
    ["EEST"] = 3 * 3600,
    ["MSK"] = 3 * 3600,
    ["BST"] = 1 * 3600,

    -- Asia & Middle East
    ["IST"] = 5.5 * 3600,
    ["PKT"] = 5 * 3600,
    ["HKT"] = 8 * 3600,
    ["PHT"] = 8 * 3600,
    ["JST"] = 9 * 3600,
    ["KST"] = 9 * 3600,

    -- Australia & Pacific
    ["AWST"] = 8 * 3600,
    ["ACST"] = 9.5 * 3600,
    ["AEST"] = 10 * 3600,
    ["AEDT"] = 11 * 3600,
    ["NZST"] = 12 * 3600,
    ["NZDT"] = 13 * 3600,
  }

  -- Handle special cases for ambiguous abbreviations
  if timezone == "CST" and not timezone_map[timezone] then
    -- In most contexts, CST refers to Central Standard Time (US)
    return -6 * 3600
  end

  -- Return the timezone offset or default to UTC (0)
  return timezone_map[timezone] or 0
end

-- Reset all ANSI styling
function M.ansi_reset()
  return "\27[0m"
end

-- Convert a datetime to a human-readable "time ago" format
-- @param dateTime string|number ISO 8601 datetime string (e.g., "2025-10-18T20:44:05Z") or Unix timestamp
-- @return string Human-readable time ago (e.g., "5 minutes ago", "2 hours ago", "just now")
function M.time_ago(dateTime)
  local timestamp

  if type(dateTime) == "number" then
    timestamp = dateTime
  else
    local year, month, day, hour, min, sec = dateTime:match("(%d+)%-(%d+)%-(%d+)[T ](%d+):(%d+):(%d+)")
    if not year then return "Invalid date format" end

    -- Calculate timezone offset by comparing formatted strings
    local now = os.time()
    local local_hour = tonumber(os.date("%H", now))
    local utc_hour = tonumber(os.date("!%H", now))
    local local_day = tonumber(os.date("%d", now))
    local utc_day = tonumber(os.date("!%d", now))

    local hour_diff = local_hour - utc_hour
    if local_day > utc_day then
      hour_diff = hour_diff + 24
    elseif local_day < utc_day then
      hour_diff = hour_diff - 24
    end

    local offset = hour_diff * 3600

    -- Parse the UTC time and convert to local timestamp
    local utc_time_table = {
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = tonumber(sec),
    }

    timestamp = os.time(utc_time_table) + offset
  end

  local diff = os.time() - timestamp

  if diff < 0 then return "in the future" end
  if diff < 60 then return "just now" end

  local intervals = {
    { 31536000, "year" },
    { 2592000,  "month" },
    { 604800,   "week" },
    { 86400,    "day" },
    { 3600,     "hour" },
    { 60,       "minute" },
  }

  for _, interval in ipairs(intervals) do
    local count = math.floor(diff / interval[1])
    if count > 0 then
      return count == 1 and "1 " .. interval[2] .. " ago" or count .. " " .. interval[2] .. "s ago"
    end
  end
end

local function parse_yaml_value(value)
  if value == "true" then
    return true
  elseif value == "false" then
    return false
  elseif value == "null" or value == "~" then
    return nil
  elseif tonumber(value) then
    return tonumber(value)
  else
    return value
  end
end

local function get_indent(line)
  return #line:match("^%s*")
end

function M.parse_yaml(content)
  local result = {}
  local stack = { { data = result, indent = -1 } }

  for line in content:gmatch("[^\r\n]+") do
    if not line:match("^%s*#") and not line:match("^%s*$") then
      local indent = get_indent(line)
      local key, value = line:match("^%s*([^:]+):%s*(.*)$")

      if key then
        while #stack > 1 and stack[#stack].indent >= indent do
          table.remove(stack)
        end

        local parent = stack[#stack].data
        key = vim.trim(key)
        value = vim.trim(value)

        if value == "" then
          parent[key] = {}
          table.insert(stack, { data = parent[key], indent = indent })
        else
          parent[key] = parse_yaml_value(value)
        end
      end
    end
  end

  return result
end

function M.set_yaml_value(path, key, value)
  if not path then return false, "No file path provided" end

  local file = io.open(path, "r")
  if not file then return false, "Could not open file" end

  local lines = {}
  local key_pattern = "^%s*" .. vim.pesc(key) .. ":%s*"
  local found = false

  for line in file:lines() do
    if line:match(key_pattern) then
      lines[#lines + 1] = string.format("%s: %s", key, value)
      found = true
    else
      lines[#lines + 1] = line
    end
  end
  file:close()

  if not found then
    lines[#lines + 1] = string.format("%s: %s", key, value)
  end

  file = io.open(path, "w")
  if not file then return false, "Could not open file for writing" end
  file:write(table.concat(lines, "\n"))
  file:close()

  return true
end

return M
