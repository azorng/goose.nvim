-- goose.nvim/lua/goose/context.lua
-- Gathers editor context (file paths, selections) for Goose prompts

local template = require("goose.template")
local util = require("goose.util")

local M = {}

M.context = {
  current_file = nil,
  selected_text = nil,
  selected_lines = nil,
  cursor_position = nil,
  additional_files = nil
}

M.message_sections = {
  context = 'Editor context:',
  current_file = 'Current file:',
  selected_text = 'Selected text:',
  selected_lines = 'Selected lines:',
  cursor_position = 'Cursor position:',
  additional_files = 'Additional files:'
}

function M.is_valid_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  local filepath = vim.fn.expand('%:p')

  -- Valid files have empty buftype
  -- This excludes special buffers like help, terminal, nofile, etc.
  return buftype == "" and filepath ~= ""
end

function M.load()
  if not M.is_valid_file() then return end

  local file = M.get_current_file()
  local selection_result = M.get_current_selection()
  local cursor_position = M.get_current_cursor_position()

  M.context.current_file = file
  M.context.selected_text = selection_result and selection_result.text
  M.context.selected_lines = selection_result and selection_result.lines
  M.context.cursor_position = cursor_position
  return M
end

function M.add_file(file)
  if not M.context.additional_files then
    M.context.additional_files = {}
  end

  if vim.fn.filereadable(file) == 1 then
    table.insert(M.context.additional_files, file)
  else
    vim.notify("File not added to context. Could not read.")
  end
end

function M.reset()
  M.context.current_file = nil
  M.context.selected_text = nil
  M.context.selected_lines = nil
  M.context.cursor_position = nil
  M.context.additional_files = nil
end

function M.get_current_file()
  local file = vim.fn.expand('%:p')
  if not file or file == "" or vim.fn.filereadable(file) ~= 1 then
    return nil
  end
  return file
end

function M.get_current_cursor_position()
  -- Get cursor position in the format (line, column)
  local cursor_pos = vim.fn.getcurpos()
  local line = cursor_pos[2]
  local col = cursor_pos[3]
  return "(" .. line .. ", " .. col .. ")"
end

-- Get the current visual selection
function M.get_current_selection()
  -- Return nil if not in a visual mode
  if not vim.fn.mode():match("[vV\022]") then
    return nil
  end

  -- Save current position and register state
  local current_pos = vim.fn.getpos(".")
  local old_reg = vim.fn.getreg('x')
  local old_regtype = vim.fn.getregtype('x')

  -- Capture selection text and position
  vim.cmd('normal! "xy')
  local text = vim.fn.getreg('x')

  -- Get line numbers
  vim.cmd("normal! `<")
  local start_line = vim.fn.line(".")
  vim.cmd("normal! `>")
  local end_line = vim.fn.line(".")

  -- Restore state
  vim.fn.setreg('x', old_reg, old_regtype)
  vim.cmd('normal! gv')
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', true)
  vim.fn.setpos('.', current_pos)

  return {
    text = text and text:match("[^%s]") and text or nil,
    lines = "(" .. start_line .. ", " .. end_line .. ")"
  }
end

function M.format_message(prompt)
  -- Create template variables
  local template_vars = {
    -- context
    prompt = prompt,
    current_file = M.context.current_file,
    selected_text = M.context.selected_text,
    selected_lines = M.context.selected_lines,
    cursor_position = M.context.cursor_position,
    additional_files = M.context.additional_files,

    -- sections
    context_section = M.message_sections.context,
    file_path_section = M.message_sections.current_file,
    selected_text_section = M.message_sections.selected_text,
    selected_lines_section = M.message_sections.selected_lines,
    cursor_position_section = M.message_sections.cursor_position,
    additional_files_section = M.message_sections.additional_files,
  }

  return template.render_template(template_vars)
end

function M.extract_from_message(text)
  local delimiter = M.message_sections.context
  local result = {
    prompt = vim.trim(text),
    current_file = nil,
    selected_text = nil,
    selected_lines = nil,
    cursor_position = nil,
    additional_files = nil
  }

  if text:match(delimiter) then
    local parts = vim.split(text, delimiter, true)
    result.prompt = vim.trim(parts[1] or "")

    if parts[2] then
      local context_part = parts[2]

      local file_match = context_part:match(M.message_sections.current_file .. "%s*([^\n]+)")
      if file_match then
        result.current_file = vim.trim(file_match)
      end

      -- Use non-greedy pattern to match selection text until the next section
      local selection_match = context_part:match(M.message_sections.selected_text ..
        "%s*\n(.-)" .. M.message_sections.selected_lines)
      if not selection_match then
        -- If no selection_lines section, try until additional_files section
        selection_match = context_part:match(M.message_sections.selected_text ..
          "%s*\n(.-)" .. M.message_sections.additional_files)
        if not selection_match then
          -- If no additional_files section, match until the end
          selection_match = context_part:match(M.message_sections.selected_text .. "%s*\n(.*)")
        end
      end

      if selection_match then
        result.selected_text = util.indent_code_block(selection_match)
      end

      -- Match selection lines
      local selection_lines_match = context_part:match(M.message_sections.selected_lines .. "%s*([^\n]+)")
      if selection_lines_match then
        result.selected_lines = vim.trim(selection_lines_match)
      end

      -- Match cursor position
      local cursor_position_match = context_part:match(M.message_sections.cursor_position .. "%s*([^\n]+)")
      if cursor_position_match then
        result.cursor_position = vim.trim(cursor_position_match)
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
