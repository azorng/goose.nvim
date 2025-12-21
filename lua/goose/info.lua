local M = {}

M.MODE = {
  CHAT = "chat",
  AUTO = "auto"
}

M.KEY = {
  MODE = "GOOSE_MODE",
  MODEL = "GOOSE_MODEL",
  PROVIDER = "GOOSE_PROVIDER"
}

local cache = nil

local function load_config()
  if cache then return cache end

  local result = vim.system({ 'goose', 'info', '-v' }):wait()
  if result.code ~= 0 then return nil end

  local config_path = result.stdout:match("Config yaml:%s*(.-)[\n$]")
  if not config_path then return nil end

  config_path = vim.trim(config_path)

  local file = io.open(config_path, "r")
  if not file then return nil end

  local content = file:read("*a")
  file:close()

  local data = require('goose.util').parse_yaml(content)
  if data then
    cache = {
      path = config_path,
      data = data
    }
  end

  return cache
end

function M.model()
  local cfg = load_config()
  return cfg and cfg.data[M.KEY.MODEL]
end

function M.provider()
  local cfg = load_config()
  return cfg and cfg.data[M.KEY.PROVIDER]
end

function M.mode()
  local cfg = load_config()
  return cfg and cfg.data[M.KEY.MODE]
end

function M.extensions()
  local cfg = load_config()
  return cfg and cfg.data.extensions or {}
end

function M.is_extension_enabled(name)
  local exts = M.extensions()
  return exts[name] and exts[name].enabled == true
end

function M.slash_commands()
  local cfg = load_config()
  return cfg and cfg.data.slash_commands or {}
end

function M.set(key, value)
  local cfg = load_config()
  if not cfg then return false, "Could not load config" end

  local util = require('goose.util')
  local ok, err = util.set_yaml_value(cfg.path, key, value)
  if ok then cache = nil end

  return ok, err
end

function M.invalidate()
  cache = nil
end

return M
