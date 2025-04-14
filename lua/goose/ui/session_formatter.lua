local M = {}

local context_module = require('goose.context')

M.separator = {
  "---",
  ""
}

function M.format_session(session_path)
  if vim.fn.filereadable(session_path) == 0 then return nil end

  local session_lines = vim.fn.readfile(session_path)
  if #session_lines == 0 then return nil end

  local output_lines = { "" }

  local need_separator = false

  for i = 2, #session_lines do
    local success, message = pcall(vim.fn.json_decode, session_lines[i])
    if not success then goto continue end

    local message_lines = M._format_message(message)
    if message_lines then
      if need_separator then
        for _, line in ipairs(M.separator) do
          table.insert(output_lines, line)
        end
      else
        need_separator = true
      end

      vim.list_extend(output_lines, message_lines)
    end

    ::continue::
  end

  return output_lines
end

function M._format_user_message(lines, text)
  local context = context_module.extract_from_message(text)
  local current_file_name_context = ""

  if context.current_file then
    current_file_name_context = vim.fn.fnamemodify(context.current_file, ":t")

    -- show current file name on prompt? 
    -- table.insert(lines, "@" .. current_file_name_context)
    -- table.insert(lines, "")
  end

  for _, line in ipairs(vim.split(context.prompt, "\n")) do
    table.insert(lines, "> " .. line)
  end

  if context.selected_text then
    local curret_file_extension_context = vim.fn.fnamemodify(current_file_name_context, ":e")
    table.insert(lines, "")
    table.insert(lines,
      "```" .. curret_file_extension_context .. " " .. current_file_name_context .. " " .. context.selected_lines)
    for _, line in ipairs(vim.split(context.selected_text, "\n")) do
      table.insert(lines, line)
    end
    table.insert(lines, "```")
  end
end

function M._format_message(message)
  if not message.content then return nil end

  local lines = {}
  local has_content = false

  for _, part in ipairs(message.content) do
    if part.type == 'text' and part.text and part.text ~= "" then
      has_content = true

      if message.role == 'user' then
        M._format_user_message(lines, part.text)
      elseif message.role == 'assistant' then
        for _, line in ipairs(vim.split(part.text, "\n")) do
          table.insert(lines, line)
        end
      end
    elseif part.type == 'toolRequest' then
      if has_content then
        table.insert(lines, "")
      end
      M._format_tool(lines, part)
      has_content = true
    end
  end

  if has_content then
    table.insert(lines, "")
  end

  return has_content and lines or nil
end

function M._format_context(lines, type, value)
  if not type or not value then return end
  local formatted_action = ' **' .. type .. '** ` ' .. value .. ' `'
  table.insert(lines, formatted_action)
end

function M._format_tool(lines, part)
  local tool = part.toolCall.value
  if not tool then return end


  if tool.name == 'developer__shell' then
    M._format_context(lines, '🚀 run', tool.arguments.command)
  elseif tool.name == 'developer__text_editor' then
    local path = tool.arguments.path
    local file_name = vim.fn.fnamemodify(path, ":t")

    if tool.arguments.command == 'str_replace' or tool.arguments.command == 'write' then
      M._format_context(lines, '✏️ write to', file_name)
    elseif tool.arguments.command == 'view' then
      M._format_context(lines, '👀 view', file_name)
    else
      M._format_context(lines, '✨ command', tool.arguments.command)
    end
  else
    M._format_context(lines, '🔧 tool', tool.name)
  end
end

return M
