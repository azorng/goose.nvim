local M = {}
local state = require("goose.state")
local context = require("goose.context")
local session = require("goose.session")
local ui = require("goose.ui.ui")
local job = require('goose.job')

function M.select_session()
  local all_sessions = session.get_sessions()
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
      state.active_session = session.get_last_session()
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
  if not M.goose_ok() then return false end
  M.before_run(opts)

  -- Add small delay to ensure stop is complete
  vim.defer_fn(function()
    job.execute(prompt,
      {
        on_start = function()
          M.after_run(prompt)
        end,
        on_output = function(output)
          -- Reload all modified file buffers
          vim.cmd('checktime')

          -- for new sessions, set session data after running the command
          if not state.active_session then
            local session_id = output:match("session id:%s*([%w_]+)")
            if session_id then
              vim.defer_fn(function()
                state.active_session = session.get_by_name(session_id)
              end, 100)
            end
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
          require('goose.review').check_cleanup_breakpoint()
        end
      }
    )
  end, 10)
end

function M.after_run(prompt)
  require('goose.review').set_breakpoint()
  context.unload_attachments()
  state.last_sent_context = vim.deepcopy(context.context)
  require('goose.history').write(prompt)

  if state.windows then
    ui.render_output()
  end
end

function M.before_run(opts)
  M.stop()

  opts = opts or {}

  M.open({
    new_session = opts.new_session or not state.active_session,
  })
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

function M.configure_provider()
  local info_mod = require("goose.info")
  require("goose.provider").select(function(selection)
    if not selection then return end

    info_mod.set_config_value(info_mod.GOOSE_INFO.PROVIDER, selection.provider)
    info_mod.set_config_value(info_mod.GOOSE_INFO.MODEL, selection.model)

    if state.windows then
      require('goose.ui.topbar').render()
    else
      vim.notify("Changed provider to " .. selection.display, vim.log.levels.INFO)
    end
  end)
end

function M.stop()
  if (state.goose_run_job) then job.stop(state.goose_run_job) end
  state.goose_run_job = nil
  if state.windows then
    ui.stop_render_output()
    ui.render_output()
    ui.write_to_input({})
    require('goose.history').index = nil
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
