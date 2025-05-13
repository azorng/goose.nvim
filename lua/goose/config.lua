-- Default and user-provided settings for goose.nvim

local M = {}

-- Default configuration
M.defaults = {
  keymap = {
    global = {
      toggle = '<leader>gg',
      open_input = '<leader>gi',
      open_input_new_session = '<leader>gI',
      open_output = '<leader>go',
      toggle_focus = '<leader>gt',
      close = '<leader>gq',
      toggle_fullscreen = '<leader>gf',
      select_session = '<leader>gs',
      goose_mode_chat = '<leader>gmc',
      goose_mode_auto = '<leader>gma',

      diff = {
        open = '<leader>gd',
        next = '<leader>g]',
        prev = '<leader>g[',
        close = '<leader>gc',
        revert_all = '<leader>gra',
        revert_this = '<leader>grt'
      }
    },
    window = {
      submit = '<cr>',
      close = '<esc>',
      stop = '<C-c>',
      next_message = ']]',
      prev_message = '[[',
      mention_file = '@',
      toggle_pane = '<tab>',
      prev_prompt_history = '<up>',
      next_prompt_history = '<down>'
    }
  },
  ui = {
    window_width = 0.35,
    input_height = 0.15,
    fullscreen = false,
    layout = "right",
    floating_height = 0.8,
    display_model = true,
    display_goose_mode = true
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
