-- Default and user-provided settings for goose.nvim

local M = {}

-- Default configuration
M.defaults = {
  default_global_keymaps = true,
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
      configure_provider = '<leader>gp',
      diff_open = '<leader>gd',
      diff_next = '<leader>g]',
      diff_prev = '<leader>g[',
      diff_close = '<leader>gc',
      diff_revert_all = '<leader>gra',
      diff_revert_this = '<leader>grt'
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
  },
  providers = {
    --[[
    Define available providers and their models for quick model switching
    anthropic|azure|bedrock|databricks|google|groq|ollama|openai|openrouter
    Example:
    openrouter = {
      "anthropic/claude-3.5-sonnet",
      "openai/gpt-4.1",
    },
    ollama = {
      "cogito:14b"
    }
    --]]
  }
}

-- Active configuration
M.values = vim.deepcopy(M.defaults)

-- Backward compatibility helper for diff nested mappings
local function ensure_backward_compatibility()
  -- If the old nested format exists in user config, map it to the new flat format
  if M.values.keymap.global.diff then
    if M.values.keymap.global.diff.open and not M.values.keymap.global.diff_open then
      M.values.keymap.global.diff_open = M.values.keymap.global.diff.open
    end
    if M.values.keymap.global.diff.next and not M.values.keymap.global.diff_next then
      M.values.keymap.global.diff_next = M.values.keymap.global.diff.next
    end
    if M.values.keymap.global.diff.prev and not M.values.keymap.global.diff_prev then
      M.values.keymap.global.diff_prev = M.values.keymap.global.diff.prev
    end
    if M.values.keymap.global.diff.close and not M.values.keymap.global.diff_close then
      M.values.keymap.global.diff_close = M.values.keymap.global.diff.close
    end
    if M.values.keymap.global.diff.revert_all and not M.values.keymap.global.diff_revert_all then
      M.values.keymap.global.diff_revert_all = M.values.keymap.global.diff.revert_all
    end
    if M.values.keymap.global.diff.revert_this and not M.values.keymap.global.diff_revert_this then
      M.values.keymap.global.diff_revert_this = M.values.keymap.global.diff.revert_this
    end
  end
end

function M.setup(opts)
  opts = opts or {}

  if opts.default_global_keymaps == false then
    M.values.keymap.global = {}
  end

  -- Merge user options with defaults (deep merge for nested tables)
  for k, v in pairs(opts) do
    if type(v) == "table" and type(M.values[k]) == "table" then
      M.values[k] = vim.tbl_deep_extend("force", M.values[k], v)
    else
      M.values[k] = v
    end
  end

  -- Ensure backward compatibility with old nested diff format
  -- TODO: Remove at some point
  ensure_backward_compatibility()
end

function M.get(key)
  if key then
    return M.values[key]
  end
  return M.values
end

return M
