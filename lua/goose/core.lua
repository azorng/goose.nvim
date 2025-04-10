local M = {}
local state = require("goose.state")
local context = require("goose.context")
local session = require("goose.session")
local ui = require("goose.ui.ui")

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
  opts = opts or {}

  -- Reset active session if specified
  if opts.new_session then
    state.active_session = nil
  end

  -- Create UI if needed
  if state.windows == nil and opts.ensure_ui then
    M.open({
      new_session = opts.new_session,
      focus = opts.focus or "output"
    })
  elseif opts.new_session and state.windows then
    ui.clear_output()
  end

  require('goose.job').execute(prompt, function()
    if not state.active_session and state.new_session_name then
      state.active_session = session.get_by_name(state.new_session_name)
    end

    if state.windows then
      ui.render_output()
    end
  end)
end

function M.stop()
  require('goose.job').stop()
end

return M
