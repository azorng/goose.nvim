local M = {}
local state = require("goose.state")
local context = require("goose.context")
local session = require("goose.session")
local ui = require("goose.ui.ui")
local job = require('goose.job')

function M.select_session()
  local all_sessions = session.get_all_workspace_sessions()
  local filtered_sessions = vim.tbl_filter(function(s)
    return s.description ~= '' and s ~= nil
  end, all_sessions)

  ui.select_session(filtered_sessions, function(selected_session)
    if not selected_session then return end
    state.active_session = selected_session
    if state.windows then
      ui.render_output()
      ui.scroll_to_bottom()
    end
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

function M.add_file_to_context(opts)
  if opts.from_mention == true then
    require('goose.ui.file_mention').mention(function(file)
      context.add_files({ file.path })
    end)
  elseif opts.path then
    context.add_files(opts.path)
  end
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

return M
