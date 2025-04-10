local api = require("goose.api")

local M = {}

function M.setup(keymap)
  local cmds = api.commands

  vim.keymap.set({ 'n', 'v' }, keymap.open_input, function()
    vim.cmd(cmds.open_input.name)
  end, { silent = false, desc = cmds.open_input.desc })

  vim.keymap.set({ 'n', 'v' }, keymap.open_input_new_session, function()
    vim.cmd(cmds.open_input_new_session.name)
  end, { silent = false, desc = cmds.open_input_new_session.desc })

  vim.keymap.set({ 'n', 'v' }, keymap.open_output, function()
    vim.cmd(cmds.open_output.name)
  end, { silent = false, desc = cmds.open_output.desc })

  vim.keymap.set({ 'n', 'v' }, keymap.close, function()
    vim.cmd(cmds.close.name)
  end, { silent = false, desc = cmds.close.desc })

  vim.keymap.set({ 'n', 'v' }, keymap.stop, function()
    vim.cmd(cmds.stop.name)
  end, { silent = false, desc = cmds.stop.desc })
end

return M
