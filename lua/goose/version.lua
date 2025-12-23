local M = {}

M.MIN_GOOSE_VERSION = "1.18.0"

local function parse(version_str)
  local major, minor, patch = version_str:match("^%s*(%d+)%.(%d+)%.(%d+)")
  if major then
    return { tonumber(major), tonumber(minor), tonumber(patch) }
  end
  return nil
end

local function compare(v1, v2)
  for i = 1, 3 do
    if v1[i] > v2[i] then return 1 end
    if v1[i] < v2[i] then return -1 end
  end
  return 0
end

function M.get_current()
  local output = vim.fn.system('goose --version')
  return vim.trim(output)
end

function M.is_supported()
  local current_str = M.get_current()
  local current = parse(current_str)
  local min = parse(M.MIN_GOOSE_VERSION)

  if not current or not min then
    return true, current_str
  end

  return compare(current, min) >= 0, current_str
end

return M
