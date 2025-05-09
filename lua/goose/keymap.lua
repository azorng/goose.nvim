local api = require("goose.api")

local M = {}

function M.setup(keymap)
  local cmds = api.commands
  local global = keymap.global

  vim.keymap.set({ 'n', 'v' }, global.open_input, function()
    api.open_input()
  end, { silent = false, desc = cmds.open_input.desc })

  vim.keymap.set({ 'n', 'v' }, global.open_input_new_session, function()
    api.open_input_new_session()
  end, { silent = false, desc = cmds.open_input_new_session.desc })

  vim.keymap.set({ 'n', 'v' }, global.open_output, function()
    api.open_output()
  end, { silent = false, desc = cmds.open_output.desc })

  vim.keymap.set({ 'n', 'v' }, global.close, function()
    api.close()
  end, { silent = false, desc = cmds.close.desc })

  vim.keymap.set({ 'n', 'v' }, global.toggle_fullscreen, function()
    api.toggle_fullscreen()
  end, { silent = false, desc = cmds.toggle_fullscreen.desc })

  vim.keymap.set({ 'n', 'v' }, global.select_session, function()
    api.select_session()
  end, { silent = false, desc = cmds.select_session.desc })

  vim.keymap.set({ 'n', 'v' }, global.toggle, function()
    api.toggle()
  end, { silent = false, desc = cmds.toggle.desc })

  vim.keymap.set({ 'n', 'v' }, global.toggle_focus, function()
    api.toggle_focus()
  end, { silent = false, desc = cmds.toggle_focus.desc })

  vim.keymap.set({ 'n', 'v' }, global.diff_changes, function()
    api.diff()
  end, { silent = false, desc = cmds.diff.desc })

  vim.keymap.set({ 'n', 'v' }, global.revert_all, function()
    api.revert_all()
  end, { silent = false, desc = cmds.revert_all.desc })

  vim.keymap.set({ 'n', 'v' }, global.revert_this, function()
    api.revert_this()
  end, { silent = false, desc = cmds.revert_this.desc })
end

return M
