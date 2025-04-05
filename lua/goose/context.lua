-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local template = require("goose.template")

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

  -- Create template variables
  local template_vars = {
    file_path = current_file ~= "" and current_file or nil,
    prompt = prompt,
    selection = nil
  }

  -- Add selection if in visual mode
  if vim.fn.mode():match("[vV\022]") then
    template_vars.selection = M.get_current_selection()
  end

  local msg = template.render_template(template_vars)
  vim.notify(msg)
  return msg
end

return M
