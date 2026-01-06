local M = {}

local state = require("goose.state")
local formatter = require("goose.ui.session_formatter")
local loading = require("goose.ui.loading")
local mention = require("goose.ui.mention")
local topbar = require("goose.ui.topbar")

function M.render_markdown()
  local ok, render_markdown = pcall(require, 'render-markdown')
  if ok and render_markdown.render then
    if not state.windows or not state.windows.output_buf then return end
    render_markdown.render({
      buf = state.windows.output_buf,
      config = {
        debounce = 10,
        anti_conceal = { enabled = false },
        win_options = { concealcursor = { rendered = 'nvic' } }
      }
    })
  end
end

--------------------------------------------------------------------------------
-- Buffer state helpers
--------------------------------------------------------------------------------

---@return boolean
local function is_buffer_empty()
  if not state.windows or not state.windows.output_buf then return true end
  local lines = vim.api.nvim_buf_get_lines(state.windows.output_buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if line:match("%S") then return false end
  end
  return true
end

---@return boolean
local function buffer_has_trailing_newline()
  if not state.windows or not state.windows.output_buf then return false end
  local buf = state.windows.output_buf
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count == 0 then return false end
  local last_line = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1] or ""
  return last_line == ""
end

-- Track the last cursor position we set via auto-scroll
M._last_auto_scroll_line = nil

---@return boolean
function M.is_at_bottom()
  if not state.windows or not state.windows.output_buf or not state.windows.output_win then
    return true
  end
  if not vim.api.nvim_win_is_valid(state.windows.output_win) then
    return true
  end

  local win = state.windows.output_win
  local buf = state.windows.output_buf

  local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Subtract loading lines if visible
  if loading.is_loading() and loading._animation.visible then
    line_count = line_count - (loading._animation.line_count or 0)
  end

  -- First time (new session) - default to scrolling
  if not M._last_auto_scroll_line then
    return true
  end

  -- If we previously auto-scrolled and cursor hasn't moved from where we put it,
  -- user is still "at bottom"
  if cursor_line == M._last_auto_scroll_line then
    return true
  end

  -- If cursor moved from where we last put it, user has scrolled away
  if cursor_line < M._last_auto_scroll_line then
    return false
  end

  -- Cursor is at/near bottom
  return cursor_line >= line_count - 1
end

function M.scroll_to_bottom_and_track()
  if not state.windows or not state.windows.output_win then return end
  local line_count = vim.api.nvim_buf_line_count(state.windows.output_buf)
  vim.api.nvim_win_set_cursor(state.windows.output_win, { line_count, 0 })
  M._last_auto_scroll_line = line_count
end

--------------------------------------------------------------------------------
-- Stream rendering
--
-- Output format: newline, msg, newline, ---, newline, msg, newline
-- - Empty buffer: add leading newline, then message
-- - Non-empty buffer: add separator, then message
-- - Complete messages (user): add trailing newline
-- - Streaming messages (assistant): no trailing newline until complete
--------------------------------------------------------------------------------

M.stream_id = ""

---Build the prefix lines for a new message based on buffer state
---@param is_empty boolean
---@param has_trailing boolean
---@return string[]
local function get_message_prefix(is_empty, has_trailing)
  if is_empty then
    return { "" } -- Leading newline for first message
  end

  local prefix = {}
  -- Close previous message if it doesn't have trailing newline
  if not has_trailing then
    table.insert(prefix, "")
  end
  -- Add separator
  for _, line in ipairs(formatter.SEPARATOR) do
    table.insert(prefix, line)
  end
  return prefix
end

---Append a new message to the stream
---@param message GooseMessage
---@param is_empty boolean
---@param has_trailing boolean
local function append_message(message, is_empty, has_trailing)
  local lines = {}

  -- Add prefix (leading newline or separator)
  vim.list_extend(lines, get_message_prefix(is_empty, has_trailing))

  -- Add message content
  local content = formatter.format_message(message)
  if content then
    vim.list_extend(lines, content)
  end

  -- Add trailing newline for complete messages (user messages) only when not loading
  if formatter.is_complete_message(message) and not loading.is_loading() then
    table.insert(lines, "")
  end

  require('goose.ui.ui').write_to_output(table.concat(lines, "\n"))
end

---@param stream_output GooseStreamOutput|string|nil
function M.render_stream(stream_output)
  if not stream_output then return end

  -- Check if at bottom BEFORE any buffer changes
  local should_scroll = M.is_at_bottom()

  -- Only notify loading for assistant messages (not user input)
  if type(stream_output) ~= "string" then
    loading.on_stream()
  end

  local is_empty = is_buffer_empty()
  local has_trailing = buffer_has_trailing_newline()

  -- User message (string input)
  if type(stream_output) == "string" then
    local message = {
      role = "user",
      content = { { type = "text", text = stream_output } }
    }
    append_message(message, is_empty, has_trailing)

    -- Assistant message (streaming)
  elseif stream_output.type == 'message' and formatter.has_message_contents(stream_output.message) then
    local message = stream_output.message
    local is_continuation = message.id == M.stream_id

    if is_continuation then
      -- Continue existing message - just append text
      for _, part in ipairs(message.content) do
        if part.type == 'text' and part.text and part.text ~= "" then
          require('goose.ui.ui').write_to_output(part.text)
        elseif part.type ~= 'text' then
          -- Tool request in continuation - needs full formatting
          append_message(message, is_empty, has_trailing)
        end
      end
    else
      -- New message
      append_message(message, is_empty, has_trailing)
      M.stream_id = message.id
    end
  end

  if should_scroll then
    M.scroll_to_bottom_and_track()
  end
end

--------------------------------------------------------------------------------
-- Full session rendering
--------------------------------------------------------------------------------

function M.render(windows)
  if not state.active_session then return end

  local output_lines = formatter.format_session(state.active_session.name)
  if not output_lines then return end
  M.write_output(windows, output_lines)

  if not state.windows then return end
  M.render_markdown()
  mention.highlight_all_mentions(windows.output_buf)
  topbar.render()
  M.handle_auto_scroll(state.windows)
end

function M.write_output(windows, output_lines)
  if not windows or not windows.output_buf then return end

  vim.bo[windows.output_buf].modifiable = true
  vim.api.nvim_buf_set_lines(windows.output_buf, 0, -1, false, output_lines)
  vim.bo[windows.output_buf].modifiable = false
end

function M.handle_auto_scroll(windows)
  if not state.windows then return end

  if M.is_at_bottom() then
    M.scroll_to_bottom_and_track()
  end
end

return M
