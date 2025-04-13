-- Default and user-provided settings for goose.nvim

local M = {}

-- Default configuration
M.defaults = {
  keymap = {
    global = {
      open_input = '<leader>gi',
      open_input_new_session = '<leader>gI',
      open_output = '<leader>go',
      close = '<leader>gq',
      toggle_fullscreen = '<leader>gf',
      select_session = '<leader>gs',
      resume_session = '<leader>gr',
      toggle_code_ui = '<leader>gt',
    },
    window = {
      submit = '<cr>',
      close = '<esc>',
      stop = '<C-c>',
      next_message = ']]',
      prev_message = '[[',
      toggle_input_output = '<C-n>',
    }
  },
  ui = {
    window_width = 0.35,
    input_height = 0.15,
    fullscreen = false,
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
