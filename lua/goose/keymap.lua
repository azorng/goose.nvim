local command = require("goose.command")

local M = {}

function M.setup(keymap)
  -- Setup keymap for continuing a session
  vim.keymap.set({ 'n', 'v' }, keymap.prompt, function()
    command.execute_command({ resume_session = true })
  end, { silent = false, desc = "Run Goose command (continue session)" })

  -- Setup keymap for starting a new session
  vim.keymap.set({ 'n', 'v' }, keymap.prompt_new_session, function()
    command.execute_command({ resume_session = false })
  end, { silent = false, desc = "Run Goose command (new session)" })
end

return M
