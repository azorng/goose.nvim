local M = {}
local state = require("goose.state")
local context = require("goose.context")
local session = require("goose.session")
local ui = require("goose.ui.ui")
local job = require('goose.job')

function M.select_session(callback)
  local all_sessions = session.get_all_workspace_sessions()
  local filtered_sessions = vim.tbl_filter(function(s)
    return s.description ~= '' and s ~= nil
  end, all_sessions)

  if not filtered_sessions or #filtered_sessions == 0 then
    vim.notify("No named sessions found for this workspace.", vim.log.levels.INFO)
    return
  end

  ui.select_session(filtered_sessions, function(selected_session)
    if not selected_session then return end
    state.active_session = selected_session
    if state.windows then
      ui.render_output()
      ui.scroll_to_bottom()
    end
    if callback then callback(selected_session) end
  end)
end

function M.resume_session()
  if not M.goose_ok() then return end

  -- Get all workspace sessions
  local all_sessions = session.get_all_workspace_sessions()
  if not all_sessions or #all_sessions == 0 then
    vim.notify("No sessions found for this workspace.", vim.log.levels.INFO)
    return
  end

  -- Filter sessions to only keep those with descriptions (avoid empty sessions)
  local filtered_sessions = vim.tbl_filter(function(s)
    return s.description ~= '' and s ~= nil
  end, all_sessions)

  if #filtered_sessions == 0 then
    vim.notify("No named sessions found for this workspace.", vim.log.levels.INFO)
    return
  end

  -- Show a selection prompt with clear instructions
  vim.ui.select(filtered_sessions, {
    prompt = "Select a session to resume (by number):",
    format_item = function(sess)
      local modified = sess.modified and require("util").time_ago(sess.modified) or "unknown time"
      return sess.description .. " ~ " .. modified .. " [" .. sess.name .. "]"
    end
  }, function(selected_session)
    if not selected_session then return end

    -- Set the selected session as active
    state.active_session = selected_session

    -- Open the UI windows if they're not already open
    if state.windows == nil then
      state.windows = ui.create_windows()
    end

    -- Force a complete refresh of the session content
    ui.render_output(true) -- passing true to force a full refresh

    -- Focus the input window to make it ready for the user
    ui.focus_input()

    -- Confirm to the user that the session was loaded
    vim.notify("Resumed session: " .. selected_session.description, vim.log.levels.INFO)
  end)
end

function M.open(opts)
  if not M.goose_ok() then return end

  if state.windows == nil then
    state.windows = ui.create_windows()
  end

  if opts.new_session then
    state.active_session = nil
    ui.clear_output()
  else
    if not state.active_session then
      state.active_session = session.get_last_workspace_session()
    end
    ui.render_output()
  end

  context.load()

  if opts.focus == "input" then
    ui.focus_input()
  elseif opts.focus == "output" then
    ui.focus_output()
  end
end

function M.run(prompt, opts)
  if not M.goose_ok() then return end

  M.stop()

  opts = opts or {}

  M.open({
    new_session = opts.new_session or not state.active_session,
  })

  -- Add small delay to ensure stop is complete
  vim.defer_fn(function()
    job.execute(prompt,
      function(out) -- stdout
        -- for new sessions, session data can only be retrieved after running the command, retrieve once
        if not state.active_session and state.new_session_name then
          state.active_session = session.get_by_name(state.new_session_name)
        end
      end,
      function(err) -- stderr
        vim.notify(
          err,
          vim.log.levels.ERROR
        )

        ui.close_windows(state.windows)
      end
    )

    context.reset()

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

function M.goose_ok()
  if vim.fn.executable('goose') == 0 then
    vim.notify(
      "goose command not found - please install and configure goose before using this plugin",
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

function M.toggle_focus()
  -- If Goose windows aren't open, nothing to toggle
  if not state.windows then
    vim.notify("Goose windows are not open", vim.log.levels.INFO)
    return
  end
  
  local current_win = vim.api.nvim_get_current_win()
  
  -- Check if we're in a Goose window
  if current_win == state.windows.input_win or current_win == state.windows.output_win then
    -- We're in a Goose window, switch to the previous buffer if it exists
    if state.previous_window and vim.api.nvim_win_is_valid(state.previous_window) then
      vim.api.nvim_set_current_win(state.previous_window)
    else
      -- Fallback: find a non-Goose window
      local windows = vim.api.nvim_list_wins()
      for _, win in ipairs(windows) do
        if win ~= state.windows.input_win and win ~= state.windows.output_win then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
  else
    -- We're in a non-Goose window, store it and switch to Goose
    state.previous_window = current_win
    -- Focus the output window by default
    vim.api.nvim_set_current_win(state.windows.output_win)
  end
end

return M
