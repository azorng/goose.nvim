local M = {}

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

function M._format_message(message)
  if not message.content then return nil end

  local lines = {}
  local has_content = false

  for _, part in ipairs(message.content) do
    if part.type == 'text' and part.text and part.text ~= "" then
      has_content = true

      if message.role == 'user' then
        local core_prompt = vim.trim(M._extract_core_prompt(part.text))
        for _, line in ipairs(vim.split(core_prompt, "\n")) do
          table.insert(lines, "> " .. line)
        end
      else
        for _, line in ipairs(vim.split(part.text, "\n")) do
          table.insert(lines, line)
        end
      end
    end
  end

  if has_content then
    table.insert(lines, "")
  end

  return has_content and lines or nil
end

function M._extract_core_prompt(text)
  if text:match("\nGoose context:") then
    local parts = vim.split(text, "\nGoose context:", true)
    return vim.trim(parts[1] or text)
  end
  return text
end

return M
