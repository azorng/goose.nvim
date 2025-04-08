local core = require("goose.core")
local ui = require("goose.ui.ui")
local state = require("goose.state")

local M = {}

function M.setup(keymap)
  vim.keymap.set({ 'n', 'v' }, keymap.prompt, function()
    core.prompt({ new_session = false, focus = "input" })
  end, { silent = false, desc = "Focus input (continue session)" })

  vim.keymap.set({ 'n', 'v' }, keymap.prompt_new_session, function()
    core.prompt({ new_session = true, focus = "input" })
  end, { silent = false, desc = "Focus input (new session)" })

  vim.keymap.set({ 'n', 'v' }, keymap.focus_output, function()
    core.prompt({ new_session = false, focus = "output" })
  end, { silent = false, desc = "Focus output" })

  vim.keymap.set({ 'n', 'v' }, keymap.close, function()
    ui.close_windows(state.windows)
  end, { silent = false, desc = "Focus input (new session)" })

  vim.keymap.set({ 'n', 'v' }, keymap.stop, function()
    core.stop()
  end, { silent = false, desc = "Focus input (new session)" })
end

return M
