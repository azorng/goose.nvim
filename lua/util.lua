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

return M
