local M = {}

function M.template(str, vars)
  return (str:gsub("{(.-)}", function(key)
    return tostring(vars[key] or "")
  end))
end

function M.uid()
  return tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
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

  return table.concat(content, "\n")
end

-- Convert a Neovim highlight group to ANSI escape sequences
-- @param hl_group string: The name of the highlight group
-- @return string: ANSI escape sequence for the highlight
function M.hl_to_ansi(hl_group)
  -- Get highlight attributes
  local hl = vim.api.nvim_get_hl(0, { name = hl_group })
  local codes = {}

  -- Add style codes
  if hl.bold then table.insert(codes, "1") end      -- Bold
  if hl.italic then table.insert(codes, "3") end    -- Italic
  if hl.underline then table.insert(codes, "4") end -- Underline
  if hl.undercurl then table.insert(codes, "4") end -- Use underline for undercurl
  if hl.reverse then table.insert(codes, "7") end   -- Reverse/inverse
  if hl.standout then table.insert(codes, "7") end  -- Use reverse for standout

  -- Add foreground color
  if hl.fg then
    -- Convert the decimal color value to RGB components
    local hex = string.format("#%06x", hl.fg)
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)

    -- Add RGB color code (24-bit true color)
    table.insert(codes, string.format("38;2;%d;%d;%d", r, g, b))
  end

  -- Add background color
  if hl.bg then
    -- Convert the decimal color value to RGB components
    local hex = string.format("#%06x", hl.bg)
    local r = tonumber(hex:sub(2, 3), 16)
    local g = tonumber(hex:sub(4, 5), 16)
    local b = tonumber(hex:sub(6, 7), 16)

    -- Add RGB color code (24-bit true color)
    table.insert(codes, string.format("48;2;%d;%d;%d", r, g, b))
  end

  -- Build the escape sequence
  if #codes > 0 then
    return "\27[" .. table.concat(codes, ";") .. "m"
  else
    return "" -- No styling needed
  end
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

--- Convert a datetime string to a human-readable "time ago" format
-- @param dateTime string: Datetime string (e.g., "2025-03-02 12:39:02 UTC")
-- @return string: Human-readable time ago string (e.g., "2 hours ago")
function M.time_ago(dateTime)
  -- Parse the input datetime string
  local year, month, day, hour, min, sec, zone = dateTime:match(
    "(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)%s+([%w%+%-/:]+)")

  -- If parsing fails, try another common format
  if not year then
    year, month, day, hour, min, sec = dateTime:match("(%d+)%-(%d+)%-(%d+)[T ](%d+):(%d+):(%d+)")
    -- No timezone specified, treat as local time
  end

  -- Return early if we couldn't parse the date
  if not year then
    return "Invalid date format"
  end

  -- Convert string values to numbers
  year, month, day = tonumber(year), tonumber(month), tonumber(day)
  hour, min, sec = tonumber(hour), tonumber(min), tonumber(sec)

  -- Get current time for comparison
  local now = os.time()

  -- Create date table for the input time
  local date_table = {
    year = year,
    month = month,
    day = day,
    hour = hour,
    min = min,
    sec = sec,
    isdst = false -- Ignore DST for consistency
  }

  -- Calculate timestamp based on whether timezone is specified
  local timestamp

  if zone then
    -- Get the timezone offset from our comprehensive map
    local input_offset_seconds = M.get_timezone_offset(zone)

    -- Get the local timezone offset
    local local_offset_seconds = os.difftime(os.time(os.date("*t", now)), os.time(os.date("!*t", now)))

    -- Calculate the hour in the local timezone
    -- First convert the input time to UTC, then to local time
    local adjusted_hour = hour - (input_offset_seconds / 3600) + (local_offset_seconds / 3600)

    -- Update the date table with adjusted hours and minutes
    date_table.hour = math.floor(adjusted_hour)
    date_table.min = math.floor(min + ((adjusted_hour % 1) * 60))

    -- Get timestamp in local timezone
    timestamp = os.time(date_table)
  else
    -- No timezone specified, assume it's already in local time
    timestamp = os.time(date_table)
  end

  -- Calculate time difference in seconds
  local diff = now - timestamp

  -- Format the relative time based on the difference
  if diff < 0 then
    return "in the future"
  elseif diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins == 1 and "1 minute ago" or mins .. " minutes ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours == 1 and "1 hour ago" or hours .. " hours ago"
  elseif diff < 604800 then
    local days = math.floor(diff / 86400)
    return days == 1 and "1 day ago" or days .. " days ago"
  elseif diff < 2592000 then
    local weeks = math.floor(diff / 604800)
    return weeks == 1 and "1 week ago" or weeks .. " weeks ago"
  elseif diff < 31536000 then
    local months = math.floor(diff / 2592000)
    return months == 1 and "1 month ago" or months .. " months ago"
  else
    local years = math.floor(diff / 31536000)
    return years == 1 and "1 year ago" or years .. " years ago"
  end
end

return M
