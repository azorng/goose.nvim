local M = {}

local config = require("goose.config").get()
local state = require("goose.state")
local renderer = require('goose.ui.output_renderer')

local function open_win(buf, opts)
  local base_opts = {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  }

  opts = vim.tbl_extend('force', base_opts, opts)

  return vim.api.nvim_open_win(buf, false, opts)
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
  -- Create new buffers
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  -- Make sure highlights are set up
  require('goose.ui.highlight').setup()

  -- Calculate window dimensions
  local total_width = vim.api.nvim_get_option('columns')
  local total_height = vim.api.nvim_get_option('lines')
  local width = math.floor(total_width * config.ui.window_width)
  local total_usable_height = total_height - 4
  local input_height = math.floor(total_usable_height * config.ui.input_height)

  -- Create output window
  local output_win = open_win(output_buf, {
    width = width,
    height = total_usable_height - input_height - 3,
    col = total_width - width,
    row = 0
  })

  -- Create input window
  local input_win = open_win(input_buf, {
    width = width,
    height = input_height,
    col = total_width - width,
    row = total_usable_height - input_height - 1
  })

  local windows = {
    input_buf = input_buf,
    output_buf = output_buf,
    input_win = input_win,
    output_win = output_win
  }

  local configurator = require("goose.ui.window_config")
  configurator.setup_options(windows)
  configurator.setup_placeholder(windows)
  configurator.setup_autocmds(windows)
  configurator.setup_resize_handler(windows)
  configurator.setup_keymaps(windows)
  configurator.setup_after_actions(windows)

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
end

function M.render_output(force_refresh)
  renderer.render(state.windows, force_refresh or false)
end

return M
