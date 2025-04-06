local M = {}

local window_config = require("goose.ui.window_config")

function M.run(cmd)
  M.create_windows()
end

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
  local width = math.floor(total_width * 0.3)
  local total_usable_height = total_height - 4
  local input_height = math.floor(total_usable_height * 0.2)

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

  window_config.set_options(windows)
  window_config.set_placeholder(windows)
  window_config.set_autocmds(windows)
end

return M
