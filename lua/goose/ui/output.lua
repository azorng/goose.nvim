local M = {}

local state = require("goose.state")
local session = require("goose.session")

local LABELS = {
  NEW_SESSION_TITLE = "New Goose Session",
  GENERATING_RESPONSE = "Generating response..."
}

M._animation = {
  frames = { "⋯", "⋱", "⋮", "⋰" },
  current_frame = 1,
  timer = nil,
  loading_line = nil
}

function M._extract_core_prompt(text)
  if text:match("\nGoose context:") then
    local parts = vim.split(text, "\nGoose context:", true)
    return vim.trim(parts[1] or text)
  end
  return text
end

function M._format_message(message)
  if not message.content then return nil end

  local lines = {}
  local has_content = false

  for _, part in ipairs(message.content) do
    if part.type == 'text' and part.text and part.text ~= "" then
      has_content = true

      if message.role == 'user' then
        local core_prompt = vim.trim(M._extract_core_prompt(part.text))
        for _, line in ipairs(vim.split(core_prompt, "\n")) do
          if line:match("^```") then
            table.insert(lines, line)
          else
            table.insert(lines, "> " .. line)
          end
        end
      else -- assistant
        for _, line in ipairs(vim.split(part.text, "\n")) do
          table.insert(lines, line)
        end
      end
    end
  end

  return has_content and lines or nil
end

function M._read_session()
  if not state.active_session then return nil end

  local session_path = state.active_session.path
  if vim.fn.filereadable(session_path) == 0 then return nil end

  local session_lines = vim.fn.readfile(session_path)
  if #session_lines == 0 then return nil end

  local success, metadata = pcall(vim.fn.json_decode, session_lines[1])
  if not success then return nil end

  local output_lines = {
    "# " .. (metadata.description or "Goose Session"),
    ""
  }

  local need_separator = false

  for i = 2, #session_lines do
    local success, message = pcall(vim.fn.json_decode, session_lines[i])
    if not success then goto continue end

    local message_lines = M._format_message(message)
    if message_lines then
      if need_separator then
        table.insert(output_lines, "")
        table.insert(output_lines, "---")
        table.insert(output_lines, "")
      else
        need_separator = true
      end

      vim.list_extend(output_lines, message_lines)
    end

    ::continue::
  end

  return output_lines
end

function M._update_loading_animation(windows)
  if not M._animation.loading_line then return false end

  local buffer_line_count = vim.api.nvim_buf_line_count(windows.output_buf)
  if M._animation.loading_line <= 0 or M._animation.loading_line >= buffer_line_count then
    return false
  end

  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', true)
  local zero_index = M._animation.loading_line - 1
  local loading_text = "*" .. LABELS.GENERATING_RESPONSE .. " " ..
      M._animation.frames[M._animation.current_frame] .. "*"

  vim.api.nvim_buf_set_lines(windows.output_buf, zero_index, zero_index + 1, false, { loading_text })
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
  return true
end

function M._animate_loading(windows)
  if M._animation.timer then
    pcall(vim.fn.timer_stop, M._animation.timer)
  end

  M._animation.timer = vim.fn.timer_start(200, function()
    M._animation.current_frame = (M._animation.current_frame % #M._animation.frames) + 1

    vim.schedule_wrap(function()
      if not M._update_loading_animation(windows) then
        M.render(windows)
      end
    end)()

    if state.goose_run_job then
      M._animate_loading(windows)
    else
      if M._animation.timer then
        pcall(vim.fn.timer_stop, M._animation.timer)
        M._animation.timer = nil
      end
      vim.schedule(function() M.render(windows) end)
    end
  end)
end

function M.render(windows, update_animation_only)
  if not state.active_session and not state.new_session_name then
    return
  elseif not state.active_session and state.new_session_name then
    state.active_session = session.get_by_name(state.new_session_name)
  end

  if update_animation_only and M._update_loading_animation(windows) then
    return
  end

  local output_lines = M._read_session()
  local is_new_session = state.new_session_name ~= nil

  if not output_lines then
    if is_new_session then
      output_lines = {
        "# " .. LABELS.NEW_SESSION_TITLE,
        ""
      }
    else
      return
    end
  else
    state.new_session_name = nil
  end

  if state.goose_run_job then
    if #output_lines > 2 then
      table.insert(output_lines, "")
      table.insert(output_lines, "---")
      table.insert(output_lines, "")
    end

    local loading_text = "*" .. LABELS.GENERATING_RESPONSE .. " " ..
        M._animation.frames[M._animation.current_frame] .. "*"
    table.insert(output_lines, loading_text)
    table.insert(output_lines, "")

    M._animation.loading_line = #output_lines - 1

    if not M._animation.timer then
      M._animate_loading(windows)
    end
  else
    M._animation.loading_line = nil
    if M._animation.timer then
      pcall(vim.fn.timer_stop, M._animation.timer)
      M._animation.timer = nil
    end
  end

  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(windows.output_buf, 0, -1, false, output_lines)
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(windows.output_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(windows.output_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(windows.output_buf, 'swapfile', false)

  -- scroll to bottom
  local line_count = vim.api.nvim_buf_line_count(windows.output_buf)
  vim.api.nvim_win_set_cursor(windows.output_win, { line_count, 0 })
end

return M
