-- Default and user-provided settings for goose.nvim

local M = {}

-- Default configuration
M.defaults = {
  keymap = {
    focus_input = '<leader>gi',
    focus_input_new_session = '<leader>gI',
    submit = '<CR>'
  },
  ui = {
    window_width = 0.3,
    input_height = 0.2
  }
}

-- Active configuration
M.values = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}

  -- Merge user options with defaults (deep merge for nested tables)
  for k, v in pairs(opts) do
    if type(v) == "table" and type(M.values[k]) == "table" then
      M.values[k] = vim.tbl_deep_extend("force", M.values[k], v)
    else
      M.values[k] = v
    end
  end
end

function M.get(key)
  if key then
    return M.values[key]
  end
  return M.values
end

return M
