-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local template = require("goose.template")
local state = require("goose.state")
local util = require("goose.util")

local M = {}

M.message_sections = {
  context = 'Goose context:',
  current_file = 'Current file:',
  selection = 'Selected text:',
  additional_files = 'Additional files:'
}

function M.load()
  local file = M.get_current_file()
  local selection = M.get_current_selection()

  if file then state.current_file = file end
  if selection then state.selection = selection end
end

function M.add_file(file)
  if not state.additional_files then
    state.additional_files = {}
  end

  if vim.fn.filereadable(file) == 1 then
    table.insert(state.additional_files, file)
  else
    vim.notify("Could not read file: ")
  end
end

function M.reset()
  state.current_file = nil
  state.selection = nil
  state.additional_files = nil
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
    current_file = state.current_file,
    prompt = prompt,
    selection = state.selection,
    context_section = M.message_sections.context,
    file_path_section = M.message_sections.current_file,
    selection_section = M.message_sections.selection,
    additional_files_section = M.message_sections.additional_files,
    additional_files = state.additional_files
  }

  return template.render_template(template_vars)
end

function M.extract_from_message(text)
  local delimiter = M.message_sections.context
  local result = {
    prompt = vim.trim(text),
    file_path = nil,
    selection = nil,
    additional_files = nil
  }

  if text:match(delimiter) then
    local parts = vim.split(text, delimiter, true)
    result.prompt = vim.trim(parts[1] or "")

    if parts[2] then
      local context_part = parts[2]

      local file_match = context_part:match(M.message_sections.current_file .. "%s*([^\n]+)")
      if file_match then
        result.file_path = vim.trim(file_match)
      end

      -- Use non-greedy pattern to match selection text until the next section
      local selection_match = context_part:match(M.message_sections.selection ..
        "%s*\n(.-)" .. M.message_sections.additional_files)
      if not selection_match then
        -- If no additional_files section, match until the end
        selection_match = context_part:match(M.message_sections.selection .. "%s*\n(.*)")
      end

      if selection_match then
        result.selection = util.indent_code_block(selection_match)
      end

      -- Extract additional files if present
      local additional_files_match = context_part:match(M.message_sections.additional_files .. "(.*)")
      if additional_files_match then
        result.additional_files = {}
        -- Parse the list format: "- file/path"
        for file in additional_files_match:gmatch("%-([^\n]+)") do
          table.insert(result.additional_files, vim.trim(file))
        end
      end
    end
  end

  return result
end

return M
