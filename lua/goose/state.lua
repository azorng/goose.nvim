local M = {}

-- ui
M.windows = nil

-- session
M.active_session = nil
M.new_session_name = nil

-- context
M.current_file = nil
M.selection = nil
M.prompt = nil

-- job
M.goose_run_job = nil

return M
