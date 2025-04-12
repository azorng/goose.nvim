local M = {}

-- Helper function to get all sessions as JSON
function M.get_all_sessions()
  local handle = io.popen('goose session list --format json')
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  -- Use pcall to safely decode JSON
  local success, sessions = pcall(vim.fn.json_decode, result)
  -- vim.notify(vim.inspect(next(sessions)))
  if not success or not sessions or next(sessions) == nil then return nil end

  return vim.tbl_map(function(session)
    return {
      workspace = session.metadata.working_dir,
      description = session.metadata.description,
      modified = session.modified,
      name = session.id,
      path = session.path
    }
  end, sessions)
end

-- Helper function to get all sessions as JSON
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

return M
