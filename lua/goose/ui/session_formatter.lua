local M = {}

local context_module = require('goose.context')

M.separator = {
  "---",
  ""
}

function M.format_session(session_name)
  local output = require("goose.session").export(session_name)
  if not output then return end

  local success, session = pcall(vim.fn.json_decode, output)
  if not success or not session or not session.conversation then
    return
  end

  local output_lines = { "" }

  local need_separator = false

  for i, message in ipairs(session.conversation) do
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

  if context.selected_text then
    table.insert(lines, "")
    for _, line in ipairs(vim.split(context.selected_text, "\n")) do
      table.insert(lines, line)
    end
  end
end

function M._format_message(message)
  if not message.content then return nil end

  local lines = {}
  local has_content = false

  for _, part in ipairs(message.content) do
    if part.type == 'text' and part.text and part.text ~= "" then
      local text = vim.trim(part.text)
      has_content = true

      if message.role == 'user' then
        M._format_user_message(lines, text)
      elseif message.role == 'assistant' then
        for _, line in ipairs(vim.split(text, "\n")) do
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
  if not type then return end

  local formatted_action = ' **' .. type .. '**'

  if value and value ~= '' then
    -- escape new lines
    value = value:gsub("\n", "\\n")
    formatted_action = formatted_action .. ' ` ' .. value .. ' `'
  end

  table.insert(lines, formatted_action)
end

local function extract_task_titles(task_parameters)
  if type(task_parameters) == 'table' then
    local titles = {}
    for _, param in ipairs(task_parameters) do
      if param.title then
        table.insert(titles, param.title)
      end
    end
    return #titles > 0 and table.concat(titles, ", ") or ""
  elseif type(task_parameters) == 'string' then
    local titles = {}
    for title in task_parameters:gmatch('"title"%s*:%s*"([^"]+)"') do
      table.insert(titles, title)
    end
    return #titles > 0 and table.concat(titles, ", ") or ""
  end
  return ""
end

function M._format_tool(lines, part)
  local tool = part.toolCall.value
  if not tool then return end
  local command = tool.arguments.command

  if tool.name == 'skills__loadSkill' then
    M._format_context(lines, '💎 skill', tool.arguments.name)
  elseif tool.name == 'subagent__execute_task' then
    M._format_context(lines, '⚡️ execute task')
  elseif tool.name == 'developer__analyze' then
    local full_path = tool.arguments.path
    local dir = vim.fn.fnamemodify(full_path, ":t")
    M._format_context(lines, '👀 analyze', dir)
  elseif tool.name == 'dynamic_task__create_task' then
    local titles = extract_task_titles(tool.arguments.task_parameters)
    M._format_context(lines, '📋 create task', titles)
  elseif tool.name == 'developer__shell' then
    M._format_context(lines, '🚀 run', command)
  elseif tool.name == 'developer__image_processor' then
    local image_path = tool.arguments.path
    local image_name = vim.fn.fnamemodify(image_path, ":t")
    M._format_context(lines, '🎇 process image', image_name)
  elseif tool.name == 'developer__text_editor' then
    local path = tool.arguments.path
    local file_name = vim.fn.fnamemodify(path, ":t")

    local write_commands = { 'str_replace', 'write', 'edit_file' }
    if vim.tbl_contains(write_commands, command) then
      M._format_context(lines, '✏️ edit', file_name)
    elseif tool.arguments.command == 'view' then
      M._format_context(lines, '👀 view', file_name)
    else
      M._format_context(lines, '✨ command', command)
    end
  else
    M._format_context(lines, '🔧 tool', tool.name)
  end
end

return M
