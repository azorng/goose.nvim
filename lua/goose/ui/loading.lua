local M = {}

local state = require("goose.state")

M._animation = {
  frames = { "·", "․", "•", "∙", "●", "⬤", "●", "∙", "•", "․" },
  current_frame = 1,
  timer = nil,
  show_timer = nil,
  active = false,
  visible = false,
  start_line = nil, -- line where loading content starts
  line_count = 0,   -- number of loading lines
  has_leading_newline = false,
}

local FPS = 10
local SHOW_DELAY_MS = 400

local function get_loading_lines(needs_leading_newline)
  local frame = M._animation.frames[M._animation.current_frame]
  local text = "Thinking... " .. frame
  local lines = {
    "---",
    "",
    text,
    "",
  }
  if needs_leading_newline then
    table.insert(lines, 1, "")
  end
  return lines, text
end

local function clear_loading_lines()
  if not M._animation.start_line then return end
  if M._animation.line_count == 0 then return end
  if not state.windows or not state.windows.output_buf then return end
  if not vim.api.nvim_buf_is_valid(state.windows.output_buf) then return end

  local buf = state.windows.output_buf
  local buf_line_count = vim.api.nvim_buf_line_count(buf)
  local end_line = M._animation.start_line + M._animation.line_count - 1

  if M._animation.start_line <= buf_line_count then
    local actual_end = math.min(end_line, buf_line_count)
    vim.bo[buf].modifiable = true
    pcall(vim.api.nvim_buf_set_lines, buf, M._animation.start_line - 1, actual_end, false, {})
    vim.bo[buf].modifiable = false
  end

  M._animation.start_line = nil
  M._animation.line_count = 0
end

local function render_loading(should_scroll)
  if not M._animation.visible then return end
  if not M._animation.active then return end
  if not state.windows or not state.windows.output_buf then return end
  if not vim.api.nvim_buf_is_valid(state.windows.output_buf) then return end

  local buf = state.windows.output_buf
  local ns = vim.api.nvim_create_namespace("goose_loading_hl")

  vim.bo[buf].modifiable = true

  -- If loading lines already exist, just update the text line
  if M._animation.start_line and M._animation.line_count > 0 then
    local lines, _ = get_loading_lines(M._animation.has_leading_newline)
    local text_offset = M._animation.has_leading_newline and 3 or 2
    local text_line_idx = M._animation.start_line - 1 + text_offset
    if text_line_idx < vim.api.nvim_buf_line_count(buf) then
      local text_index = M._animation.has_leading_newline and 4 or 3
      pcall(vim.api.nvim_buf_set_lines, buf, text_line_idx, text_line_idx + 1, false, { lines[text_index] })
      pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Comment", text_line_idx, 0, -1)
      vim.bo[buf].modifiable = false
      return
    end
  end

  -- Initial render: determine if we need leading newline
  local buf_line_count = vim.api.nvim_buf_line_count(buf)
  local last_line = ""
  if buf_line_count > 0 then
    last_line = vim.api.nvim_buf_get_lines(buf, buf_line_count - 1, buf_line_count, false)[1] or ""
  end
  M._animation.has_leading_newline = last_line ~= ""

  local lines, _ = get_loading_lines(M._animation.has_leading_newline)
  M._animation.start_line = buf_line_count + 1
  M._animation.line_count = #lines

  vim.api.nvim_buf_set_lines(buf, buf_line_count, buf_line_count, false, lines)

  -- Add Comment highlight to the loading text line
  local text_offset = M._animation.has_leading_newline and 3 or 2
  pcall(vim.api.nvim_buf_add_highlight, buf, ns, "Comment", buf_line_count + text_offset, 0, -1)

  vim.bo[buf].modifiable = false

  -- Trigger render-markdown on the separator
  local ok, render_markdown = pcall(require, 'render-markdown')
  if ok and render_markdown.render then
    render_markdown.render({ buf = buf })
  end

  -- Scroll to show loading only if this is initial render
  if should_scroll then
    local new_line_count = vim.api.nvim_buf_line_count(buf)
    pcall(vim.api.nvim_win_set_cursor, state.windows.output_win, { new_line_count, 0 })
  end
end

local function advance_frame()
  M._animation.current_frame = (M._animation.current_frame % #M._animation.frames) + 1
end

local function cancel_show_timer()
  if M._animation.show_timer then
    pcall(function()
      M._animation.show_timer:stop()
      M._animation.show_timer:close()
    end)
    M._animation.show_timer = nil
  end
end

local function hide()
  if not M._animation.visible then return end
  M._animation.visible = false
  clear_loading_lines()
end

local function show()
  if M._animation.visible then return end
  if not M._animation.active then return end
  M._animation.visible = true
  local should_scroll = require('goose.ui.output_renderer').is_at_bottom()
  render_loading(should_scroll)
end

local function schedule_show()
  cancel_show_timer()

  M._animation.show_timer = vim.uv.new_timer()
  M._animation.show_timer:start(SHOW_DELAY_MS, 0, vim.schedule_wrap(function()
    if M._animation.active then
      show()
    end
    cancel_show_timer()
  end))
end

-- Call this when streaming writes happen
function M.on_stream()
  if not M._animation.active then return end
  hide()
  schedule_show()
end

function M.start()
  if M._animation.active then return end

  M._animation.active = true
  M._animation.current_frame = 1
  M._animation.start_line = nil
  M._animation.line_count = 0
  M._animation.visible = true

  local should_scroll = require('goose.ui.output_renderer').is_at_bottom()
  render_loading(should_scroll)

  M._animation.timer = vim.uv.new_timer()
  M._animation.timer:start(math.floor(1000 / FPS), math.floor(1000 / FPS), vim.schedule_wrap(function()
    if not M._animation.active then return end
    advance_frame()
    render_loading(false)
  end))
end

function M.stop()
  M._animation.active = false

  cancel_show_timer()

  if M._animation.timer then
    M._animation.timer:stop()
    M._animation.timer:close()
    M._animation.timer = nil
  end

  vim.schedule(function()
    hide()
  end)

  M._animation.current_frame = 1
end

function M.is_loading()
  return M._animation.active
end

return M
