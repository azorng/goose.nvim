local api = require("goose.api")

local M = {}

-- Binds a keymap config with its api fn
-- Name of api fn & keymap global config should always be the same
function M.setup(keymap)
  local cmds = api.commands
  local global = keymap.global

  for key, mapping in pairs(global) do
    vim.keymap.set(
      { 'n', 'v' },
      mapping,
      function() api[key]() end,
      { silent = false, desc = cmds[key] and cmds[key].desc }
    )
  end
end

return M
