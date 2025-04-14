local M = {}

local state = require("goose.state")
local renderer = require('goose.ui.output_renderer')

function M.scroll_to_bottom()
  local line_count = vim.api.nvim_buf_line_count(state.windows.output_buf)
  vim.api.nvim_win_set_cursor(state.windows.output_win, { line_count, 0 })

  vim.defer_fn(function()
    renderer.render_markdown()
  end, 200)
end

function M.close_windows(windows)
  if not windows then return end

  renderer.stop()

  -- Clear autocmd groups
  pcall(vim.api.nvim_del_augroup_by_name, 'GooseResize')
  pcall(vim.api.nvim_del_augroup_by_name, 'GooseWindows')

  -- Close windows and delete buffers
  pcall(vim.api.nvim_win_close, windows.input_win, true)
  pcall(vim.api.nvim_win_close, windows.output_win, true)
  pcall(vim.api.nvim_buf_delete, windows.input_buf, { force = true })
  pcall(vim.api.nvim_buf_delete, windows.output_buf, { force = true })
  state.windows = nil
end

function M.create_windows()
  local configurator = require("goose.ui.window_config")
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  require('goose.ui.highlight').setup()

  local input_win = vim.api.nvim_open_win(input_buf, false, configurator.base_window_opts)
  local output_win = vim.api.nvim_open_win(output_buf, false, configurator.base_window_opts)
  local windows = {
    input_buf = input_buf,
    output_buf = output_buf,
    input_win = input_win,
    output_win = output_win
  }

  configurator.setup_options(windows)
  configurator.setup_placeholder(windows)
  configurator.setup_autocmds(windows)
  configurator.setup_resize_handler(windows)
  configurator.setup_keymaps(windows)
  configurator.setup_after_actions(windows)
  configurator.configure_window_dimentions(windows)
  return windows
end

function M.focus_input()
  local windows = state.windows
  vim.api.nvim_set_current_win(windows.input_win)
  vim.cmd('startinsert')
end

function M.focus_output()
  local windows = state.windows
  vim.api.nvim_set_current_win(windows.output_win)
end

function M.clear_output()
  local windows = state.windows

  -- Clear any extmarks/namespaces first
  local ns_id = vim.api.nvim_create_namespace('loading_animation')
  vim.api.nvim_buf_clear_namespace(windows.output_buf, ns_id, 0, -1)

  -- Stop any running timers in the output module
  if renderer._animation.timer then
    pcall(vim.fn.timer_stop, renderer._animation.timer)
    renderer._animation.timer = nil
  end
  if renderer._refresh_timer then
    pcall(vim.fn.timer_stop, renderer._refresh_timer)
    renderer._refresh_timer = nil
  end

  -- Reset animation state
  renderer._animation.loading_line = nil

  -- Clear cache to force refresh on next render
  renderer._cache = {
    last_modified = 0,
    output_lines = nil,
    session_path = nil,
    check_counter = 0
  }

  -- Clear all buffer content
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(windows.output_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)

  renderer.render_session_bar()
  renderer.render_markdown()
end

function M.render_output()
  renderer.render(state.windows, false)
end

function M.stop_render_output()
  renderer.stop()
end

function M.toggle_fullscreen()
  local windows = state.windows
  if not windows then return end

  local ui_config = require("goose.config").get("ui")
  ui_config.fullscreen = not ui_config.fullscreen

  require("goose.ui.window_config").configure_window_dimentions(windows)

  local current_win = vim.api.nvim_get_current_win()
  local is_goose_focused = current_win == windows.input_win or current_win == windows.output_win

  if not is_goose_focused then
    vim.api.nvim_set_current_win(windows.output_win)
  end
end

function M.select_session(sessions, cb)
  local util = require("goose.util")

  vim.ui.select(sessions, {
    prompt = "",
    format_item = function(session)
      if not session.modified then
        return session.description
      end

      local modified = util.time_ago(session.modified)
      return session.description .. " ~ " .. modified
    end
  }, function(session_choice)
    cb(session_choice)
  end)
end

return M
