-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local template = require("goose.template")
local state = require("goose.state")
local util = require("util")

local M = {}

M.message_sections = {
  context = 'Goose context:',
  file_path = 'File:',
  selection = 'Selected text:',
}

function M.load()
  local file = M.get_current_file()
  local selection = M.get_current_selection()

  if file then state.current_file = file end
  if selection then state.selection = selection end
end

function M.reset()
  state.current_file = nil
  state.selection = nil
end

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
    selection = state.selection,
    context_section = M.message_sections.context,
    file_path_section = M.message_sections.file_path,
    selection_section = M.message_sections.selection
  }

  return template.render_template(template_vars)
end

function M.extract_from_message(text)
  local delimiter = M.message_sections.context
  local result = {
    prompt = vim.trim(text),
    file_path = nil,
    selection = nil
  }

  if text:match(delimiter) then
    local parts = vim.split(text, delimiter, true)
    result.prompt = vim.trim(parts[1] or "")

    if parts[2] then
      local context_part = parts[2]

      local file_match = context_part:match(M.message_sections.file_path .. "%s*([^\n]+)")
      if file_match then
        result.file_path = vim.trim(file_match)
      end

      local selection_match = context_part:match(M.message_sections.selection .. "%s*\n(.*)")
      if selection_match then
        result.selection = util.indent_code_block(selection_match)
      end
    end
  end

  return result
end

return M
