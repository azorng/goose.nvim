local M = {}

local window_configurator = require("goose.ui.window_config")
local config = require("goose.config").get()
local state = require("goose.state")
local output = require("goose.ui.output")
local session = require("goose.session")
local context = require("goose.context")

local function open_win(buf, opts)
  local base_opts = {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  }

  opts = vim.tbl_extend('force', base_opts, opts)

  return vim.api.nvim_open_win(buf, false, opts)
end

function M.create_windows()
  -- Create new buffers
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

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

  window_configurator.setup_options(windows)
  window_configurator.setup_placeholder(windows)
  window_configurator.setup_autocmds(windows)
  window_configurator.setup_resize_handler(windows)
  window_configurator.setup_keymaps(windows)
  state.windows = windows

  return windows
end

function M.focus_input(opts)
  local windows = state.windows

  if windows == nil then
    windows = M.create_windows()
  end

  if opts.new_session then
    state.active_session = nil
    vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(windows.output_buf, 0, -1, false, {})
    vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
  else
    state.active_session = session.get_last_workspace_session()
    output.render(windows)
  end

  state.current_file = context.get_current_file()
  state.selection = context.get_current_selection()
  vim.api.nvim_set_current_win(windows.input_win)
end

return M
