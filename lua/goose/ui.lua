local config = require("goose.config")

local M = {}

function M.run(cmd)
  -- Remember current window to restore focus later
  local current_win = vim.api.nvim_get_current_win()

  -- Calculate window width based on config percentage
  local percent = config.get("ui_width")
  local total_width = vim.api.nvim_get_option("columns")
  local width = math.floor(total_width * (percent / 100))

  -- Create new window and run terminal command
  vim.cmd('botright vertical ' .. width .. 'new')
  local term_buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen(cmd)

  -- Add escape mapping for easier terminal exit
  vim.api.nvim_buf_set_keymap(term_buf, 't', '<Esc>', [[<C-\><C-n>]],
    { noremap = true, silent = true })

  -- Return focus to original window
  vim.api.nvim_set_current_win(current_win)
end

return M
