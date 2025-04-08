local M = {}

function M.get_last_workspace_session()
  local workspace = vim.fn.getcwd()
  local handle = io.popen('goose session list --format json')
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  -- Use pcall to safely decode JSON
  local success, sessions = pcall(vim.fn.json_decode, result)
  if not success or not sessions then return nil end

  -- Find sessions matching the working directory
  local matches = {}
  for _, session in ipairs(sessions) do
    if session.metadata and session.metadata.working_dir == workspace then
      table.insert(matches, session)
    end
  end

  -- Sort by modification time (newest last)
  table.sort(matches, function(a, b)
    return a.modified < b.modified
  end)

  -- Return most recent session if available
  return matches[#matches]
end

function M.get_by_name(name)
  local handle = io.popen('goose session list --format json')
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  -- Use pcall to safely decode JSON
  local success, sessions = pcall(vim.fn.json_decode, result)
  if not success or not sessions then return nil end

  for _, session in ipairs(sessions) do
    if session.id == name then
      return session
    end
  end

  return nil
end

return M
