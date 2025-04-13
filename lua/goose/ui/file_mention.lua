local M = {}

local function insert_mention(windows, row, col, name)
  local current_line = vim.api.nvim_buf_get_lines(windows.input_buf, row - 1, row, false)[1]
  local new_line = current_line:sub(1, col) ..
      '@' .. name .. " " .. current_line:sub(col + 2)

  vim.api.nvim_buf_set_lines(windows.input_buf, row - 1, row, false, { new_line })

  vim.defer_fn(function()
    vim.cmd('startinsert')
    vim.api.nvim_set_current_win(windows.input_win)
    vim.api.nvim_win_set_cursor(windows.input_win, { row, col + 1 + #name + 1 })
  end, 10)
end

function M.mention(on_file_mention)
  local windows = require('goose.state').windows

  local mention_key = require('goose.config').get('keymap').window.mention_file
  -- insert @ in case we just want the character
  if mention_key == '@' then
    vim.api.nvim_feedkeys('@', 'in', true)
  end

  local cursor_pos = vim.api.nvim_win_get_cursor(windows.input_win)
  local row, col = cursor_pos[1], cursor_pos[2]

  local picker = require('goose.ui.file_picker')

  vim.schedule(function()
    picker.open(function(file)
      if file then
        insert_mention(windows, row, col, file.name)
        on_file_mention(file)
      end
    end)
  end)
end

return M
