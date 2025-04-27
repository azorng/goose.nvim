local api = require("goose.api")

local M = {}

function M.setup(keymap)
  local cmds = api.commands
  local global = keymap.global

  local all_mappings = {
    'open_input',
    'open_input_new_session',
    'open_output',
    'close',
    'toggle_fullscreen',
    'select_session',
    'toggle',
    'toggle_focus',
    'configure_provider',
    'goose_mode_chat',
    'goose_mode_auto',
    'diff_open',
    'diff_next',
    'diff_prev',
    'diff_close',
    'diff_revert_all',
    'diff_revert_this',
  }

  for _, key in ipairs(all_mappings) do
    if global[key] then
      vim.keymap.set(
        { 'n', 'v' },
        global[key],
        function() api[key]() end,
        { silent = false, desc = cmds[key] and cmds[key].desc }
      )
    end
  end
end

return M
