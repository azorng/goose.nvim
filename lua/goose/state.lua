local M = {}

-- ui
M.windows = nil

-- session
M.active_session = nil
M.new_session_name = nil

-- context
M.current_file = nil
M.selection = nil
M.additional_files = nil
M.prompt = {}

-- job
M.goose_run_job = nil

return M
