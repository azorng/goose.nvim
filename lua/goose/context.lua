-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local M = {}

function M.get_current_file()
  return vim.fn.expand('%:p')
end

-- Get the current visual selection
function M.get_current_selection()
  vim.cmd('normal! "xy')
  local text = vim.fn.getreg('x')

  -- Restore visual mode and exit
  vim.cmd('normal! gv')
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', true)

  return text and text:match("[^%s]") and text or nil
end

function M.format_message(prompt)
  local current_file = M.get_current_file()
  local message_parts = {}

  if current_file ~= "" then
    table.insert(message_parts, string.format("File: %s", current_file))
    table.insert(message_parts, "")
  end

  table.insert(message_parts, prompt)

  -- Add selection if in visual mode
  if vim.fn.mode():match("[vV\022]") then
    local selection = M.get_current_selection()
    table.insert(message_parts, "")
    table.insert(message_parts, "Selected text:")
    table.insert(message_parts, selection)
  end

  return table.concat(message_parts, "\n")
end

return M
