local M = {}

function M.get_all_sessions()
  local handle = io.popen('goose session list --format json')
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  local success, sessions = pcall(vim.fn.json_decode, result)
  if not success or not sessions or next(sessions) == nil then return nil end

  return vim.tbl_map(function(session)
    local metadata = session.metadata or session
    return {
      workspace = metadata.working_dir,
      description = metadata.description,
      message_count = metadata.message_count,
      tokens = metadata.total_tokens,
      modified = metadata.updated_at,
      name = metadata.id,
      path = metadata.path
    }
  end, sessions)
end

function M.get_all_workspace_sessions()
  local sessions = M.get_all_sessions()
  if not sessions then return nil end

  local workspace = vim.fn.getcwd()
  sessions = vim.tbl_filter(function(session)
    return session.workspace == workspace
  end, sessions)

  table.sort(sessions, function(a, b)
    return a.modified > b.modified
  end)

  return sessions
end

function M.get_last_workspace_session()
  local sessions = M.get_all_workspace_sessions()
  if not sessions then return nil end
  return sessions[1]
end

function M.get_by_name(name)
  local sessions = M.get_all_sessions()
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
