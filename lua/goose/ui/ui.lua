local M = {}

local state = require("goose.state")
local renderer = require('goose.ui.output_renderer')
local window_config = require("goose.ui.window_config")
local config = require("goose.config")
local topbar = require("goose.ui.topbar")
local util = require("goose.util")

function M.scroll_to_bottom()
  local line_count = vim.api.nvim_buf_line_count(state.windows.output_buf)
  vim.api.nvim_win_set_cursor(state.windows.output_win, { line_count, 0 })
end

function M.close_windows(windows)
  if not windows then return end

  if M.is_goose_focused() then M.return_to_last_code_win() end

  -- Close windows and delete buffers
  pcall(vim.api.nvim_win_close, windows.input_win, true)
  pcall(vim.api.nvim_win_close, windows.output_win, true)
  pcall(vim.api.nvim_buf_delete, windows.input_buf, { force = true })
  pcall(vim.api.nvim_buf_delete, windows.output_buf, { force = true })

  -- Clear autocmd groups
  pcall(vim.api.nvim_del_augroup_by_name, 'GooseResize')
  pcall(vim.api.nvim_del_augroup_by_name, 'GooseWindows')

  state.windows = nil
end

function M.return_to_last_code_win()
  local last_win = state.last_code_win_before_goose
  if last_win and vim.api.nvim_win_is_valid(last_win) then
    vim.api.nvim_set_current_win(last_win)
  end
end

function M.open_in_code_window(content, filetype)
  M.return_to_last_code_win()
  vim.cmd("enew")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, "\n"))
  vim.bo.filetype = filetype or "text"
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
end

function M.open_file_in_code_window(filepath)
  M.return_to_last_code_win()
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

function M.create_windows()
  require("goose.ui.highlight").setup()

  local cfg = config.get()
  local input_buf = vim.api.nvim_create_buf(false, true)
  local output_buf = vim.api.nvim_create_buf(false, true)

  local input_win, output_win

  if cfg.ui.window_type == "split" then
    local split_cmd = cfg.ui.layout == "left" and "topleft vsplit" or "botright vsplit"

    vim.cmd(split_cmd)
    output_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(output_win, output_buf)

    vim.cmd("belowright split")
    input_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(input_win, input_buf)
  else
    input_win = vim.api.nvim_open_win(input_buf, false, window_config.base_window_opts)
    output_win = vim.api.nvim_open_win(output_buf, false, window_config.base_window_opts)
  end

  local windows = {
    input_buf = input_buf,
    output_buf = output_buf,
    input_win = input_win,
    output_win = output_win
  }

  window_config.setup_options(windows)
  window_config.refresh_placeholder(windows)
  window_config.setup_autocmds(windows)
  window_config.setup_resize_handler(windows)
  window_config.setup_keymaps(windows)
  window_config.setup_after_actions(windows)
  window_config.configure_window_dimensions(windows)
  return windows
end

function M.focus_input(opts)
  opts = opts or {}
  local windows = state.windows
  vim.api.nvim_set_current_win(windows.input_win)

  if opts.restore_position and state.last_input_window_position then
    local line_count = vim.api.nvim_buf_line_count(windows.input_buf)
    local target_line = math.min(state.last_input_window_position[1], line_count)
    vim.api.nvim_win_set_cursor(windows.input_win, { target_line, state.last_input_window_position[2] })
  end
end

function M.focus_output(opts)
  opts = opts or {}

  local windows = state.windows
  vim.api.nvim_set_current_win(windows.output_win)

  if opts.restore_position and state.last_output_window_position then
    local line_count = vim.api.nvim_buf_line_count(windows.output_buf)
    local target_line = math.min(state.last_output_window_position[1], line_count)
    vim.api.nvim_win_set_cursor(windows.output_win, { target_line, state.last_output_window_position[2] })
  end
end

function M.is_goose_focused()
  if not state.windows then return false end
  -- are we in a goose window?
  local current_win = vim.api.nvim_get_current_win()
  return M.is_goose_window(current_win)
end

function M.is_goose_window(win)
  local windows = state.windows
  return win == windows.input_win or win == windows.output_win
end

function M.is_output_empty()
  local windows = state.windows
  if not windows or not windows.output_buf then return true end
  local lines = vim.api.nvim_buf_get_lines(windows.output_buf, 0, -1, false)
  return #lines == 0 or (#lines == 1 and lines[1] == "")
end

function M.clear_output()
  local windows = state.windows
  if not windows or not windows.output_buf then return end

  vim.bo[windows.output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(windows.output_buf, 0, -1, false, {})
  vim.bo[windows.output_buf].modifiable = false

  -- Reset auto-scroll tracker for new session
  renderer._last_auto_scroll_line = nil
end

function M.render_output()
  renderer.render(state.windows)
end

function M.toggle_fullscreen()
  local windows = state.windows
  if not windows then return end

  local ui_config = config.get("ui")
  ui_config.fullscreen = not ui_config.fullscreen

  window_config.configure_window_dimensions(windows)
  topbar.render()

  if not M.is_goose_focused() then
    vim.api.nvim_set_current_win(windows.output_win)
  end
end

function M.select_session(sessions, cb)
  vim.ui.select(sessions, {
    prompt = "",
    format_item = function(session)
      local parts = {}

      if session.description then
        table.insert(parts, session.description)
      end

      if session.message_count then
        table.insert(parts, session.message_count .. " messages")
      end

      local modified = util.time_ago(session.modified)
      if modified then
        table.insert(parts, modified)
      end

      return table.concat(parts, " ~ ")
    end
  }, function(session_choice)
    cb(session_choice)
  end)
end

function M.toggle_pane()
  local current_win = vim.api.nvim_get_current_win()
  if current_win == state.windows.input_win then
    -- When moving from input to output, exit insert mode first
    vim.cmd('stopinsert')
    vim.api.nvim_set_current_win(state.windows.output_win)
  else
    -- When moving from output to input, just change window
    -- (don't automatically enter insert mode)
    vim.api.nvim_set_current_win(state.windows.input_win)

    -- Fix placeholder text when switching to input window
    local lines = vim.api.nvim_buf_get_lines(state.windows.input_buf, 0, -1, false)
    if #lines == 1 and lines[1] == "" then
      -- Only show placeholder if the buffer is empty
      window_config.refresh_placeholder(state.windows)
    else
      -- Clear placeholder if there's text in the buffer
      vim.api.nvim_buf_clear_namespace(state.windows.input_buf, vim.api.nvim_create_namespace('input-placeholder'), 0, -1)
    end
  end
end

function M.write_to_output(str)
  if not state.windows or not state.windows.output_buf then return end

  local buf = state.windows.output_buf
  local last_line_idx = vim.api.nvim_buf_line_count(buf) - 1

  vim.bo[buf].modifiable = true

  -- Get the current content of the last line
  if not state.windows or not state.windows.output_buf then return end
  local current_line = vim.api.nvim_buf_get_lines(buf, last_line_idx, last_line_idx + 1, false)[1] or ""

  -- Split the incoming string by newlines
  local lines = vim.split(str, "\n", { plain = true })

  -- Append the first part to the existing last line
  lines[1] = current_line .. lines[1]

  if not state.windows or not state.windows.output_buf then return end
  vim.api.nvim_buf_set_lines(buf, last_line_idx, last_line_idx + 1, false, lines)
  vim.bo[buf].modifiable = false
end

function M.write_to_input(text, windows)
  if not windows then windows = state.windows end
  if not windows then return end

  -- Check if input_buf is valid
  if not windows.input_buf or type(windows.input_buf) ~= "number" or not vim.api.nvim_buf_is_valid(windows.input_buf) then
    return
  end

  local lines

  -- Check if text is already a table/list of lines
  if type(text) == "table" then
    lines = text
  else
    -- If it's a string, split it into lines
    lines = {}
    for line in (text .. '\n'):gmatch('(.-)\n') do
      table.insert(lines, line)
    end

    -- If no newlines were found (empty result), use the original text
    if #lines == 0 then
      lines = { text }
    end
  end

  vim.api.nvim_buf_set_lines(windows.input_buf, 0, -1, false, lines)
end

return M
