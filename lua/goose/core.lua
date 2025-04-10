local M = {}
local state = require("goose.state")
local context = require("goose.context")
local session = require("goose.session")
local ui = require("goose.ui.ui")
local job = require('goose.job')

function M.open(opts)
  if state.windows == nil then
    state.windows = ui.create_windows()
  end

  if opts.new_session then
    state.active_session = nil
    ui.clear_output()
  else
    state.active_session = session.get_last_workspace_session()
    ui.render_output()
  end

  local file = context.get_current_file()
  if file then state.current_file = file end

  state.selection = context.get_current_selection()

  if opts.focus == "input" then
    ui.focus_input()
  elseif opts.focus == "output" then
    ui.focus_output()
  end
end

function M.run(prompt, opts)
  M.stop()

  opts = opts or {}

  M.open({
    new_session = opts.new_session or not state.active_session,
  })

  -- Add small delay to ensure stop is complete
  vim.defer_fn(function()
    job.execute(prompt, function()
      -- for new sessions, session data can only be retrieved after running the command, retrieve once
      if not state.active_session and state.new_session_name then
        state.active_session = session.get_by_name(state.new_session_name)
      end
    end)

    if state.windows then
      ui.render_output()
    end
  end, 10)
end

function M.stop()
  job.stop()
  if state.windows then
    ui.stop_render_output()
    ui.render_output()
  end
end

return M
