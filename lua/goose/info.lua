local M = {}

-- Parse the output of `goose info -v` command
function M.parse_goose_info()
  local result = {}

  local handle = io.popen("goose info -v")
  if not handle then
    return result
  end

  local output = handle:read("*a")
  handle:close()

  local model = output:match("GOOSE_MODEL:%s*(.-)\n") or output:match("GOOSE_MODEL:%s*(.-)$")
  if model then
    result.goose_model = vim.trim(model)
  end

  return result
end

return M
