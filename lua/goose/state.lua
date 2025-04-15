local M = {}

-- ui
M.windows = nil
M.input_content = {}
M.last_focused_goose_window = nil
M.last_input_window_position = nil
M.last_output_window_position = nil
M.last_buf_before_goose = nil

-- session
M.active_session = nil
M.new_session_name = nil

-- job
M.goose_run_job = nil

return M
