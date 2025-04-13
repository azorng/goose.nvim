local api = require("goose.api")

local M = {}

function M.setup(keymap)
  local cmds = api.commands
  local global = keymap.global

  vim.keymap.set({ 'n', 'v' }, global.open_input, function()
    vim.cmd(cmds.open_input.name)
  end, { silent = false, desc = cmds.open_input.desc })

  vim.keymap.set({ 'n', 'v' }, global.open_input_new_session, function()
    vim.cmd(cmds.open_input_new_session.name)
  end, { silent = false, desc = cmds.open_input_new_session.desc })

  vim.keymap.set({ 'n', 'v' }, global.open_output, function()
    vim.cmd(cmds.open_output.name)
  end, { silent = false, desc = cmds.open_output.desc })

  vim.keymap.set({ 'n', 'v' }, global.close, function()
    vim.cmd(cmds.close.name)
  end, { silent = false, desc = cmds.close.desc })

  vim.keymap.set({ 'n', 'v' }, global.toggle_fullscreen, function()
    vim.cmd(cmds.toggle_fullscreen.name)
  end, { silent = false, desc = cmds.toggle_fullscreen.desc })

  vim.keymap.set({ 'n', 'v' }, global.select_session, function()
    vim.cmd(cmds.select_session.name)
  end, { silent = false, desc = cmds.select_session.desc })
  
  vim.keymap.set({ 'n', 'v' }, global.resume_session, function()
    vim.cmd(cmds.resume_session.name)
  end, { silent = false, desc = cmds.resume_session.desc })
end

return M
