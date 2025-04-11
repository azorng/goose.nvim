local M = {}

local context_module = require('goose.context')

function M.session_title(title)
  local output_lines = {
    '# ' .. title,
    ""
  }

  return output_lines
end

M.separator = {
  "---",
  ""
}

function M.format_session(session_path)
  if vim.fn.filereadable(session_path) == 0 then return nil end

  local session_lines = vim.fn.readfile(session_path)
  if #session_lines == 0 then return nil end

  local success, metadata = pcall(vim.fn.json_decode, session_lines[1])
  if not success then return nil end

  local output_lines = M.session_title(metadata.description or "Goose Session")

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

  for _, line in ipairs(vim.split(context.prompt, "\n")) do
    table.insert(lines, "> " .. line)
  end

  if context.file_path then
    local file_name = vim.fn.fnamemodify(context.file_path, ":t")
    local file_ext = vim.fn.fnamemodify(context.file_path, ":e")

    -- context selection already includes file name
    if not context.selection then
      -- not convinced how it looks like, maybe for the future
      -- M._format_context(lines, "📄file", file_name)
    end

    if context.selection then
      table.insert(lines, "")
      table.insert(lines, "```" .. file_ext .. " " .. file_name)
      for _, line in ipairs(vim.split(context.selection, "\n")) do
        table.insert(lines, line)
      end
      table.insert(lines, "```")
    end
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
      M._format_tool(lines, part)
    end
  end

  if has_content then
    table.insert(lines, "")
  end

  return has_content and lines or nil
end

function M._format_context(lines, type, value)
  if not type or not value then return end
  table.insert(lines, '')
  local formatted_action = '**' .. type .. '** ` ' .. value .. ' `'
  table.insert(lines, formatted_action)
end

function M._format_tool(lines, part)
  local tool = part.toolCall.value
  if not tool then return end


  if tool.name == 'developer__shell' then
    M._format_context(lines, '⚡run', tool.arguments.command)
  elseif tool.name == 'developer__text_editor' then
    local path = tool.arguments.path
    local file_name = vim.fn.fnamemodify(path, ":t")

    if tool.arguments.command == 'str_replace' or tool.arguments.command == 'write' then
      M._format_context(lines, '✏️write to', file_name)
    elseif tool.arguments.command == 'view' then
      M._format_context(lines, '👁️view', file_name)
    else
      M._format_context(lines, '✨command', tool.arguments.command)
    end
  else
    M._format_context(lines, '🔧tool', tool.name)
  end
end

return M
