local M = {}
local util = require('goose.util')

M.GOOSE_INFO = {
  MODEL = "GOOSE_MODEL",
  PROVIDER = "GOOSE_PROVIDER",
  MODE = "GOOSE_MODE",
  CONFIG = "Config yaml",
}

M.GOOSE_MODE = {
  CHAT = "chat",
  AUTO = "auto"
}

-- Parse the output of `goose info -v` command
function M.parse_goose_info()
  local result = {}

  local handle = io.popen("goose info -v")
  if not handle then
    return result
  end

  local output = handle:read("*a")
  handle:close()

  local model = output:match(M.GOOSE_INFO.MODEL .. ":%s*(.-)\n") or output:match(M.GOOSE_INFO.MODEL .. ":%s*(.-)$")
  if model then
    result.goose_model = vim.trim(model)
  end

  local provider = output:match(M.GOOSE_INFO.PROVIDER .. ":%s*(.-)\n") or
  output:match(M.GOOSE_INFO.PROVIDER .. ":%s*(.-)$")
  if provider then
    result.goose_provider = vim.trim(provider)
  end

  local mode = output:match(M.GOOSE_INFO.MODE .. ":%s*(.-)\n") or output:match(M.GOOSE_INFO.MODE .. ":%s*(.-)$")
  if mode then
    result.goose_mode = vim.trim(mode)
  end

  local config_file = output:match(M.GOOSE_INFO.CONFIG .. ":%s*(.-)\n") or
      output:match(M.GOOSE_INFO.CONFIG .. ":%s*(.-)$")
  if config_file then
    result.config_file = vim.trim(config_file)
  end

  return result
end

-- Set a value in the goose config file
function M.set_config_value(key, value)
  local info = M.parse_goose_info()
  if not info.config_file then
    return false, "Could not find config file path"
  end

  return util.set_yaml_value(info.config_file, key, value)
end

return M
