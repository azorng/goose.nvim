local M = {}

local INPUT_PLACEHOLDER = 'Plan, search, build anything'
local config = require("goose.config").get()
local state = require("goose.state")

function M.setup_options(windows)
  -- Input window/buffer options
  vim.api.nvim_win_set_option(windows.input_win, 'winhighlight', 'Normal:GooseBackground,FloatBorder:GooseBorder')
  vim.api.nvim_win_set_option(windows.input_win, 'signcolumn', 'yes')
  vim.api.nvim_win_set_option(windows.input_win, 'cursorline', false)
  vim.api.nvim_buf_set_option(windows.input_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(windows.input_buf, 'swapfile', false)
  vim.b[windows.input_buf].completion = false

  -- Output window/buffer options
  vim.api.nvim_win_set_option(windows.output_win, 'winhighlight', 'Normal:GooseBackground,FloatBorder:GooseBorder')
  vim.api.nvim_buf_set_option(windows.output_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(windows.output_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(windows.output_buf, 'swapfile', false)
end

function M.setup_placeholder(windows)
  local ns_id = vim.api.nvim_create_namespace('input-placeholder')
  vim.api.nvim_buf_set_extmark(windows.input_buf, ns_id, 0, 0, {
    virt_text = { { INPUT_PLACEHOLDER, 'Comment' } },
    virt_text_pos = 'overlay',
  })
end

function M.setup_autocmds(windows)
  local group = vim.api.nvim_create_augroup('GooseWindows', { clear = true })

  -- Output window autocmds
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
    group = group,
    buffer = windows.output_buf,
    callback = function() vim.cmd('stopinsert') end
  })

  -- Input window autocmds
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    buffer = windows.input_buf,
    callback = function() vim.cmd('startinsert') end
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = windows.input_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(windows.input_buf, 0, -1, false)
      state.prompt = lines
      if #lines == 1 and lines[1] == "" then
        M.setup_placeholder(windows)
      else
        vim.api.nvim_buf_clear_namespace(windows.input_buf, vim.api.nvim_create_namespace('input-placeholder'), 0, -1)
      end
    end
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(windows.input_win) .. ',' .. tostring(windows.output_win),
    callback = function(opts)
      -- Get the window that was closed
      local closed_win = tonumber(opts.match)
      -- If either window is closed, close both
      if closed_win == windows.input_win or closed_win == windows.output_win then
        vim.schedule(function()
          require('goose.ui.ui').close_windows(windows)
        end)
      end
    end
  })
end

function M.setup_resize_handler(windows)
  local function update_windows()
    local total_width = vim.api.nvim_get_option('columns')
    local total_height = vim.api.nvim_get_option('lines')
    local width = math.floor(total_width * config.ui.window_width)

    local total_usable_height = total_height - 4
    local input_height = math.floor(total_usable_height * config.ui.input_height)

    vim.api.nvim_win_set_config(windows.output_win, {
      relative = 'editor',
      width = width,
      height = total_usable_height - input_height - 3,
      col = total_width - width,
      row = 0
    })

    vim.api.nvim_win_set_config(windows.input_win, {
      relative = 'editor',
      width = width,
      height = input_height,
      col = total_width - width,
      row = total_usable_height - input_height - 1
    })
  end

  vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('GooseResize', { clear = true }),
    callback = update_windows
  })
end

local function recover_input(windows)
  local input_content = state.prompt
  vim.api.nvim_buf_set_lines(windows.input_buf, 0, -1, false, input_content)
end

function M.setup_after_actions(windows)
  recover_input(windows)
end

local function handle_submit(windows)
  local input_content = table.concat(vim.api.nvim_buf_get_lines(windows.input_buf, 0, -1, false), '\n')
  vim.api.nvim_buf_set_lines(windows.input_buf, 0, -1, false, {})
  vim.api.nvim_exec_autocmds('TextChanged', {
    buffer = windows.input_buf,
    modeline = false
  })

  -- Switch to the output window
  vim.api.nvim_set_current_win(windows.output_win)

  -- Always scroll to the bottom when submitting a new prompt
  local line_count = vim.api.nvim_buf_line_count(windows.output_buf)
  vim.api.nvim_win_set_cursor(windows.output_win, { line_count, 0 })

  -- Run the command with the input content
  require("goose.core").run(input_content)
end

function M.setup_keymaps(windows)
  vim.keymap.set({ 'n', 'i' }, config.keymap.submit_prompt, function()
    handle_submit(windows)
  end, { buffer = windows.input_buf, silent = false })

  vim.keymap.set('n', config.keymap.close_when_focused, function()
    require('goose.ui.ui').close_windows(windows)
  end, { buffer = windows.input_buf, silent = true })
  vim.keymap.set('n', config.keymap.close_when_focused, function()
    require('goose.ui.ui').close_windows(windows)
  end, { buffer = windows.output_buf, silent = true })
end

return M
