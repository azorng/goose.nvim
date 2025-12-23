local M = {}

local context_module = require('goose.context')

M.separator = {
  "",
  "---",
  ""
}

---@param session_name string
---@return string[]|nil
function M.format_session(session_name)
  local output = require("goose.session").export(session_name)
  if not output then return end

  local success, session = pcall(vim.fn.json_decode, output)
  if not success or not session or not session.conversation then
    return
  end

  ---@cast session GooseSession
  return M.format_messages(session.conversation)
end

function M.messages_to_str_output(messages)
  local message_lines = M.format_messages(messages)
  return table.concat(message_lines, "\n") or ""
end

---@return string[]
---@param messages GooseMessage[]
function M.format_messages(messages)
  local output_lines = { "" }

  for i, message in ipairs(messages) do
    local message_lines

    message_lines = M._format_message(message)
    if message_lines then
      for _, line in ipairs(M.separator) do
        table.insert(output_lines, line)
      end
      vim.list_extend(output_lines, message_lines)
    end
  end

  if require('goose.ui.ui').is_output_empty() then
    --- first separator is not needed for the first message
    output_lines = vim.list_slice(output_lines, #M.separator + 1, #output_lines)
  end

  return output_lines
end

---@param lines string[]
---@param text string
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

---@param message GooseMessage
---@return string[]|nil
function M._format_message(message)
  if not M.has_message_contents(message) then return nil end

  local lines = {}

  for _, part in ipairs(message.content) do
    if part.type == 'text' and part.text and part.text ~= "" then
      local text = vim.trim(part.text)

      if message.role == 'user' then
        M._format_user_message(lines, text)
      elseif message.role == 'assistant' then
        for _, line in ipairs(vim.split(text, "\n")) do
          table.insert(lines, line)
        end
      end
    elseif part.type == 'toolRequest' then
      M._format_tool(lines, part)
    end
  end

  return lines
end

---@param message GooseMessage
function M.has_message_contents(message)
  return (not message.metadata or (message.metadata and message.metadata.userVisible == true))
      and message.content
      and #message.content > 0
      and #vim.tbl_filter(function(part)
        if part.type == 'text' then
          return part.text and part.text ~= ""
        end
        if part.type == 'toolRequest' then return true end
        return false
      end, message.content) > 0
end

---@param lines string[]
---@param type string
---@param value string|nil
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

---@param task_parameters table|string
---@return string
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

---@param lines string[]
---@param tool_request GooseToolRequest
function M._format_tool(lines, tool_request)
  local tool = tool_request.toolCall.value
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
