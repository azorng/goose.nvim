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


function M.render_template(template_vars)
  local plugin_root = get_plugin_root()
  local template_path = plugin_root .. "/template/prompt.jinja"

  local template = read_template(template_path)
  if not template then return nil end

  -- Replace variables with values
  local result = template:gsub("{{%s*([%w_]+)%s*}}", function(var)
    return template_vars[var] or ""
  end)

  -- Process if blocks with support for logical operators
  result = result:gsub("{%%(%s*)if(.-)%%}(.-){%%(%s*)endif(%s*)%%}", function(s1, condition, content, s2, s3)
    -- Evaluate the condition
    local should_render = false

    -- Parse 'or' condition
    if condition:match("or") then
      local var_names = {}
      for var in condition:gmatch("([%w_]+)") do
        table.insert(var_names, var)
      end

      -- Check if any variable is truthy
      for _, var in ipairs(var_names) do
        if template_vars[var] and template_vars[var] ~= "" then
          should_render = true
          break
        end
      end
    else
      -- Single variable check
      local var = condition:match("%s*([%w_]+)%s*")
      should_render = template_vars[var] and template_vars[var] ~= ""
    end

    return should_render and content or ""
  end)

  -- Clean up any empty lines caused by conditional blocks
  result = result:gsub("\n\n\n+", "\n\n")

  return result
end

return M
