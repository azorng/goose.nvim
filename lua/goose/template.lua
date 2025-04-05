-- Template rendering functionality for goose.nvim
local M = {}

-- Find the plugin root directory
local function get_plugin_root()
  local path = debug.getinfo(1, "S").source:sub(2)
  local lua_dir = vim.fn.fnamemodify(path, ":h:h")
  return vim.fn.fnamemodify(lua_dir, ":h") -- Go up one more level
end

-- Read the Jinja template file
local function read_template(template_path)
  local file = io.open(template_path, "r")
  if not file then
    error("Failed to read template file: " .. template_path)
    return nil
  end

  local content = file:read("*all")
  file:close()
  return content
end

-- Simple Jinja-like template rendering
function M.render_template(template_vars)
  local plugin_root = get_plugin_root()
  local template_path = plugin_root .. "/template/prompt.jinja"

  local template = read_template(template_path)
  if not template then return nil end

  -- Replace variables with values
  local result = template:gsub("{{%s*([%w_]+)%s*}}", function(var)
    return template_vars[var] or ""
  end)

  -- Process if blocks (simple implementation)
  result = result:gsub("{%%(%s*)if(%s+)([%w_]+)(%s*)%%}(.-){%%(%s*)endif(%s*)%%}",
    function(s1, s2, var, s3, content, s4, s5)
      if template_vars[var] and template_vars[var] ~= "" then
        return content
      else
        return ""
      end
    end)

  -- Clean up any empty lines caused by conditional blocks
  result = result:gsub("\n\n\n+", "\n\n")

  return result
end

return M
