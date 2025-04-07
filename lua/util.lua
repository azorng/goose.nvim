local M = {}

function M.template(str, vars)
  return (str:gsub("{(.-)}", function(key)
    return tostring(vars[key] or "")
  end))
end

function M.uid()
  return tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
end

return M
