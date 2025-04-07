-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local template = require("goose.template")
local state = require("goose.state")

local M = {}

function M.get_current_file()
  return vim.fn.expand('%:p')
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
  local current_file = state.current_file

  -- Create template variables
  local template_vars = {
    file_path = current_file ~= "" and current_file or nil,
    prompt = prompt,
    selection = nil
  }

  template_vars.selection = state.selection

  return template.render_template(template_vars)
end

return M
