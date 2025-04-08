-- Default and user-provided settings for goose.nvim

local M = {}

-- Default configuration
M.defaults = {
  keymap = {
    prompt = '<leader>gi',
    prompt_new_session = '<leader>gI',
    focus_output = '<leader>go',
    submit_prompt = '<cr>',
    close = '<leader>gc',
    stop = '<leader>gs'
  },
  ui = {
    window_width = 0.35,
    input_height = 0.15,
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
