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
    else
      M.open()
    end
  end)
end

function M.open(opts)
  opts = opts or { focus = "input", new_session = false }

  if not M.goose_ok() then return end

  local are_windows_closed = state.windows == nil

  if are_windows_closed then
    state.windows = ui.create_windows()
  end

  if opts.new_session then
    state.active_session = nil
    state.last_sent_context = nil
    ui.clear_output()
  else
    if not state.active_session then
      state.active_session = session.get_last_workspace_session()
    end

    if are_windows_closed or ui.is_output_empty() then
      ui.render_output()
      ui.scroll_to_bottom()
    end
  end

  if opts.focus == "input" then
    ui.focus_input({ restore_position = are_windows_closed })
  elseif opts.focus == "output" then
    ui.focus_output({ restore_position = are_windows_closed })
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
      {
        on_start = function()
          M.after_send()
        end,
        on_output = function(output)
          -- Reload all modified file buffers
          vim.cmd('checktime')

          -- for new sessions, session data can only be retrieved after running the command, retrieve once
          if not state.active_session and state.new_session_name then
            state.active_session = session.get_by_name(state.new_session_name)
          end
        end,
        on_error = function(err)
          vim.notify(
            err,
            vim.log.levels.ERROR
          )

          ui.close_windows(state.windows)
        end,
        on_exit = function()
          state.goose_run_job = nil
        end
      }
    )
  end, 10)
end

function M.after_send()
  context.unload_attachments()
  state.last_sent_context = vim.deepcopy(context.context)

  if state.windows then
    ui.render_output()
  end
end

function M.add_file_to_context()
  local picker = require('goose.ui.file_picker')
  require('goose.ui.mention').mention(function(mention_cb)
    picker.pick(function(file)
      mention_cb(file.name)
      context.add_file(file.path)
    end)
  end)
end

function M.stop()
  if (state.goose_run_job) then job.stop(state.goose_run_job) end
  state.goose_run_job = nil
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
