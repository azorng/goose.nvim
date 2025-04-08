-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local template = require("goose.template")
local state = require("goose.state")

local M = {}

function M.get_current_file()
  local file = vim.fn.expand('%:p')
  if not file or file == "" or vim.fn.filereadable(file) ~= 1 then
    return nil
  end
  return file
end

-- Get the current visual selection
function M.get_current_selection()
  if not vim.fn.mode():match("[vV\022]") then
    return nil
  end

  vim.cmd('normal! "xy')
  local text = vim.fn.getreg('x')

  -- Restore visual mode and exit
  vim.cmd('normal! gv')
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', true)

  return text and text:match("[^%s]") and text or nil
end

function M.format_message(prompt)
  -- Create template variables
  local template_vars = {
    file_path = state.current_file,
    prompt = prompt,
    selection = state.selection
  }

  return template.render_template(template_vars)
end

return M
