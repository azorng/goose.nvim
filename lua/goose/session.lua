local M = {}
local goose = require('goose.goose')

function M.get_last_workspace_session()
  local current_dir = vim.fn.getcwd()
  return goose.get_last_workspace_session(current_dir)
end

function M.get_by_name(name)
  return goose.get_session_by_name(name)
end

return M
