local M = {}

function M.get_sessions()
  local workspace = vim.fn.getcwd()
  local handle = io.popen('goose session list --format json --limit 50 --working_dir ' .. workspace)
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  local success, sessions = pcall(vim.fn.json_decode, result)
  if not success or not sessions or next(sessions) == nil then return nil end

  return vim.tbl_map(function(session)
    local metadata = session.metadata or session
    return {
      workspace = metadata.working_dir,
      description = metadata.description or metadata.name,
      message_count = metadata.message_count,
      tokens = metadata.total_tokens,
      modified = metadata.updated_at or session.modified,
      name = metadata.id or session.id,
      path = metadata.path or session.path
    }
  end, sessions)
end

function M.get_last_session()
  local sessions = M.get_sessions()
  if not sessions then return nil end
  return sessions[1]
end

function M.export(session_name)
  local handle = io.popen('goose session export --format json --name "' .. session_name .. '"')
  if not handle then
    vim.notify("Failed to export session", vim.log.levels.ERROR)
    return nil
  end

  local json_content = handle:read("*a")
  handle:close()

  if not json_content or json_content == "" then
    vim.notify("No content exported", vim.log.levels.WARN)
    return nil
  end

  return json_content
end

function M.get_by_name(name)
  local sessions = M.get_sessions()
  if not sessions then return nil end

  for _, session in ipairs(sessions) do
    if session.name == name then
      return session
    end
  end

  return nil
end

function M.update_session_workspace(session_name, workspace_path)
  local session = M.get_by_name(session_name)
  if not session then return false end

  local file = io.open(session.path, "r")
  if not file then return false end

  local first_line = file:read("*line")
  local rest = file:read("*all")
  file:close()

  -- Parse and update metadata
  local success, metadata = pcall(vim.fn.json_decode, first_line)
  if not success then return false end

  metadata.working_dir = workspace_path

  -- Write back: metadata line + rest of the file
  file = io.open(session.path, "w")
  if not file then return false end

  file:write(vim.fn.json_encode(metadata) .. "\n")
  if rest and rest ~= "" then
    file:write(rest)
  end
  file:close()

  return true
end

return M
