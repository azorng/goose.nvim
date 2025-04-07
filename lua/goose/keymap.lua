local ui = require("goose.ui.ui")

local M = {}

function M.setup(keymap)
  vim.keymap.set({ 'n', 'v' }, keymap.focus_input, function()
    ui.focus_input({ new_session = false })
  end, { silent = false, desc = "Focus input (continue session)" })

  vim.keymap.set({ 'n', 'v' }, keymap.focus_input_new_session, function()
    ui.focus_input({ new_session = true })
  end, { silent = false, desc = "Focus input (new session)" })
end

return M
