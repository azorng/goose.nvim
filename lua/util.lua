local M = {}

function M.template(str, vars)
  return (str:gsub("{(.-)}", function(key)
    return tostring(vars[key] or "")
  end))
end

return M
