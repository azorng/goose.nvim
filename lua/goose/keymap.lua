local api = require("goose.api")

local M = {}

function M.setup(keymap)
  local cmds = api.commands
  local global = keymap.global

  local mappings = {
    'open_input',
    'open_input_new_session',
    'open_output',
    'close',
    'toggle_fullscreen',
    'select_session',
    'toggle',
    'toggle_focus',
  }

  for _, action in ipairs(mappings) do
    if global[action] then
      vim.keymap.set(
        { 'n', 'v' },
        global[action],
        function() api[action](); end,
        { silent = false, desc = cmds[action] and cmds[action].desc }
      )
    end
  end
end

return M
