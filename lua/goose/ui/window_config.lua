local M = {}

local INPUT_PLACEHOLDER = 'Plan, search, build anything'
local config = require("goose.config").get()
local state = require("goose.state")
local ui_util = require('goose.ui.util')

M.base_window_opts = {
  relative = 'editor',
  style = 'minimal',
  border = 'rounded',
  zindex = 50,
  width = 1,
  height = 1,
  col = 0,
  row = 0
}

function M.setup_options(windows)
  local highlight = 'Normal:GooseBackground,FloatBorder:GooseBorder,WinBar:GooseBorder,WinBarNC:GooseBorder'

  -- Input window/buffer options
  vim.api.nvim_win_set_option(windows.input_win, 'winhighlight', highlight)
  vim.api.nvim_win_set_option(windows.input_win, 'signcolumn', 'yes')
  vim.api.nvim_win_set_option(windows.input_win, 'cursorline', false)
  vim.api.nvim_win_set_option(windows.input_win, 'number', false)
  vim.api.nvim_buf_set_option(windows.input_buf, 'filetype', 'GooseInput')
  vim.api.nvim_buf_set_option(windows.input_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(windows.input_buf, 'swapfile', false)
  vim.b[windows.input_buf].completion = false

  -- Output window/buffer options
  vim.api.nvim_win_set_option(windows.output_win, 'winhighlight', highlight)
  vim.api.nvim_win_set_option(windows.output_win, 'number', false)
  vim.api.nvim_win_set_option(windows.output_win, 'relativenumber', false)
  vim.api.nvim_buf_set_option(windows.output_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(windows.output_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(windows.output_buf, 'swapfile', false)
end

function M.refresh_placeholder(windows, input_lines)
  -- show placeholder if input buffer is empty - otherwise clear it
  if not input_lines then
    input_lines = vim.api.nvim_buf_get_lines(windows.input_buf, 0, -1, false)
  end

  if #input_lines == 1 and input_lines[1] == "" then
    local ns_id = vim.api.nvim_create_namespace('input-placeholder')
    vim.api.nvim_buf_set_extmark(windows.input_buf, ns_id, 0, 0, {
      virt_text = { { INPUT_PLACEHOLDER, 'Comment' } },
      virt_text_pos = 'overlay',
    })
  else
    vim.api.nvim_buf_clear_namespace(windows.input_buf, vim.api.nvim_create_namespace('input-placeholder'), 0, -1)
  end
end

function M.setup_autocmds(windows)
  local group = vim.api.nvim_create_augroup('GooseWindows', { clear = true })

  -- Output window autocmds
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
    group = group,
    buffer = windows.output_buf,
    callback = function()
      vim.cmd('stopinsert')
      state.last_focused_goose_window = "output"
      M.refresh_placeholder(windows)
    end
  })

  -- Input window autocmds
  vim.api.nvim_create_autocmd('WinEnter', {
    group = group,
    buffer = windows.input_buf,
    callback = function()
      M.refresh_placeholder(windows)
      state.last_focused_goose_window = "input"
    end
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = windows.input_buf,
    callback = function()
      local input_lines = vim.api.nvim_buf_get_lines(windows.input_buf, 0, -1, false)
      state.input_content = input_lines
      M.refresh_placeholder(windows, input_lines)
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

  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    pattern = "*",
    callback = function()
      if not require('goose.ui.ui').is_goose_focused() then
        require('goose.context').load()
        state.last_code_win_before_goose = vim.api.nvim_get_current_win()
      end
    end
  })

  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    buffer = windows.input_buf,
    callback = function()
      state.last_input_window_position = vim.api.nvim_win_get_cursor(0)
    end
  })

  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    buffer = windows.output_buf,
    callback = function()
      state.last_output_window_position = vim.api.nvim_win_get_cursor(0)
    end
  })
end

function M.configure_window_dimensions(windows)
  local is_split = config.ui.window_type == "split"

  if is_split then
    local total_width = vim.api.nvim_get_option('columns')
    local total_height = vim.api.nvim_get_option('lines')
    local width = config.ui.fullscreen and total_width or math.floor(total_width * config.ui.window_width)

    vim.api.nvim_win_set_width(windows.output_win, width)
    vim.api.nvim_win_set_width(windows.input_win, width)

    local input_height = math.floor(total_height * config.ui.input_height)
    local output_height = total_height - input_height

    vim.api.nvim_win_set_height(windows.output_win, output_height)
    vim.api.nvim_win_set_height(windows.input_win, input_height)

    if config.ui.window_type == "split" then
      -- input/output separator
      vim.wo[windows.input_win].winbar = "%#GooseBorder#" .. string.rep("─", vim.fn.winwidth(windows.input_win))
    end
    return
  end

  local total_width = vim.api.nvim_get_option('columns')
  local total_height = vim.api.nvim_get_option('lines')
  local is_fullscreen = config.ui.fullscreen

  local width
  if is_fullscreen then
    width = total_width
  else
    width = math.floor(total_width * config.ui.window_width)
  end

  local layout = config.ui.layout
  local total_usable_height
  local row, col

  if layout == "center" then
    local fh = config.ui.floating_height
    total_usable_height = math.floor(total_height * fh)
    row = math.floor((total_height - total_usable_height) / 2)
    col = is_fullscreen and 0 or math.floor((total_width - width) / 2)
  elseif layout == "left" then
    total_usable_height = total_height - 3
    row = 0
    col = 0
  else
    -- "right" layout (default)
    total_usable_height = total_height - 3
    row = 0
    col = is_fullscreen and 0 or (total_width - width)
  end

  local input_height = math.floor(total_usable_height * config.ui.input_height)
  local output_height = total_usable_height - input_height - 2

  vim.api.nvim_win_set_config(windows.output_win, {
    relative = 'editor',
    width = width,
    height = output_height,
    col = col,
    row = row,
  })

  vim.api.nvim_win_set_config(windows.input_win, {
    relative = 'editor',
    width = width,
    height = input_height,
    col = col,
    row = row + output_height + 2,
  })
end

function M.setup_resize_handler(windows)
  local function cb()
    M.configure_window_dimensions(windows)
    require('goose.ui.topbar').render()
  end

  vim.api.nvim_create_autocmd('VimResized', {
    group = vim.api.nvim_create_augroup('GooseResize', { clear = true }),
    callback = cb
  })
end

local function recover_input(windows)
  local input_content = state.input_content
  require('goose.ui.ui').write_to_input(input_content, windows)
  require('goose.ui.mention').highlight_all_mentions(windows.input_buf)
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
  local window_keymap = config.keymap.window
  local api = require('goose.api')

  vim.keymap.set({ 'n' }, window_keymap.submit, function()
    handle_submit(windows)
  end, { buffer = windows.input_buf, silent = false })

  vim.keymap.set({ 'i' }, window_keymap.submit_insert, function()
    handle_submit(windows)
  end, { buffer = windows.input_buf, silent = false })

  vim.keymap.set('n', window_keymap.close, function()
    api.close()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set('n', window_keymap.close, function()
    api.close()
  end, { buffer = windows.output_buf, silent = true })

  vim.keymap.set('n', window_keymap.next_message, function()
    require('goose.ui.navigation').goto_next_message()
  end, { buffer = windows.output_buf, silent = true })

  vim.keymap.set('n', window_keymap.prev_message, function()
    require('goose.ui.navigation').goto_prev_message()
  end, { buffer = windows.output_buf, silent = true })

  vim.keymap.set('n', window_keymap.next_message, function()
    require('goose.ui.navigation').goto_next_message()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set('n', window_keymap.prev_message, function()
    require('goose.ui.navigation').goto_prev_message()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set({ 'n', 'i' }, window_keymap.stop, function()
    api.stop()
  end, { buffer = windows.output_buf, silent = true })

  vim.keymap.set({ 'n', 'i' }, window_keymap.stop, function()
    api.stop()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set('i', window_keymap.mention_file, function()
    require('goose.core').add_file_to_context()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set('i', window_keymap.mention_skill, function()
    require('goose.core').mention_skill()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set({ 'n', 'i' }, window_keymap.toggle_pane, function()
    api.toggle_pane()
  end, { buffer = windows.input_buf, silent = true })

  vim.keymap.set({ 'n', 'i' }, window_keymap.toggle_pane, function()
    api.toggle_pane()
  end, { buffer = windows.output_buf, silent = true })

  vim.keymap.set({ 'n', 'i' }, window_keymap.prev_prompt_history,
    ui_util.navigate_history('prev', window_keymap.prev_prompt_history, api.prev_history, api.next_history),
    { buffer = windows.input_buf, silent = true })

  vim.keymap.set({ 'n', 'i' }, window_keymap.next_prompt_history,
    ui_util.navigate_history('next', window_keymap.next_prompt_history, api.prev_history, api.next_history),
    { buffer = windows.input_buf, silent = true })
end

return M
