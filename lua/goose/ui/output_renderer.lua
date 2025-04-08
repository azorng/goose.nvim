local M = {}

local state = require("goose.state")
local formatter = require("goose.ui.session_formatter")

local LABELS = {
  NEW_SESSION_TITLE = "New session",
  GENERATING_RESPONSE = "Thinking..."
}

M._cache = {
  last_modified = 0,
  output_lines = nil,
  session_path = nil,
  check_counter = 0
}

M._animation = {
  frames = { "·", "․", "•", "∙", "●", "⬤", "●", "∙", "•", "․" },
  current_frame = 1,
  timer = nil,
  loading_line = nil,
  fps = 10,
}

function M._should_refresh_content()
  if not state.active_session then return true end

  local session_path = state.active_session.path

  if session_path ~= M._cache.session_path then
    M._cache.session_path = session_path
    return true
  end

  if vim.fn.filereadable(session_path) == 0 then return false end

  local stat = vim.loop.fs_stat(session_path)
  if not stat then return false end

  if state.goose_run_job then
    M._cache.check_counter = (M._cache.check_counter + 1) % 3
    if M._cache.check_counter == 0 then
      M._cache.last_modified = stat.mtime.sec
      return true
    end
  end

  if stat.mtime.sec > M._cache.last_modified then
    M._cache.last_modified = stat.mtime.sec
    return true
  end

  return false
end

function M._read_session(force_refresh)
  if not state.active_session then return nil end

  if not force_refresh and not M._should_refresh_content() and M._cache.output_lines then
    return M._cache.output_lines
  end

  local session_path = state.active_session.path
  local output_lines = formatter.format_session(session_path)
  M._cache.output_lines = output_lines
  return output_lines
end

function M._update_loading_animation(windows)
  if not M._animation.loading_line then return false end

  local buffer_line_count = vim.api.nvim_buf_line_count(windows.output_buf)
  if M._animation.loading_line <= 0 or M._animation.loading_line >= buffer_line_count then
    return false
  end

  -- Use extmarks to update the loading indicator text without modifying the buffer
  local zero_index = M._animation.loading_line - 1
  local loading_text = LABELS.GENERATING_RESPONSE .. " " ..
      M._animation.frames[M._animation.current_frame]

  -- Use a virtual text overlay that replaces the entire line
  local ns_id = vim.api.nvim_create_namespace('loading_animation')
  vim.api.nvim_buf_clear_namespace(windows.output_buf, ns_id, zero_index, zero_index + 1)

  -- Update just the loading text using virtual text
  vim.api.nvim_buf_set_extmark(windows.output_buf, ns_id, zero_index, 0, {
    virt_text = { { loading_text, "Comment" } },
    virt_text_pos = "overlay",
    hl_mode = "replace"
  })

  return true
end

-- Separate timers for animation and content refresh
M._refresh_timer = nil

function M._start_content_refresh_timer(windows)
  if M._refresh_timer then
    pcall(vim.fn.timer_stop, M._refresh_timer)
  end

  -- Check for updates every 300ms - less frequently than animation
  M._refresh_timer = vim.fn.timer_start(300, function()
    -- Check if we need to refresh content
    if state.goose_run_job then
      if M._should_refresh_content() then
        -- If content has changed, do a full render but preserve the animation
        vim.schedule(function()
          -- Force a refresh of the session content but don't re-render the animation
          local current_frame = M._animation.current_frame
          M.render(windows, true)
          M._animation.current_frame = current_frame -- Keep the animation in sync
        end)
      end

      -- Continue checking
      if state.goose_run_job then
        M._start_content_refresh_timer(windows)
      end
    else
      if M._refresh_timer then
        pcall(vim.fn.timer_stop, M._refresh_timer)
        M._refresh_timer = nil
      end
      vim.schedule(function() M.render(windows, true) end)
    end
  end)
end

function M._animate_loading(windows)
  -- Simplify the animation approach to avoid issues with timers
  local function start_animation_timer()
    if M._animation.timer then
      pcall(vim.fn.timer_stop, M._animation.timer)
    end

    M._animation.timer = vim.fn.timer_start(math.floor(1000 / M._animation.fps), function()
      -- Update the animation frame
      M._animation.current_frame = (M._animation.current_frame % #M._animation.frames) + 1

      -- Schedule the UI update
      vim.schedule(function()
        M._update_loading_animation(windows)
      end)

      -- If we're still running, continue the animation
      if state.goose_run_job then
        start_animation_timer()
      else
        M._animation.timer = nil
      end
    end)
  end

  -- Start content refresh timer if needed
  if not M._refresh_timer and state.goose_run_job then
    M._start_content_refresh_timer(windows)
  end

  -- Start the animation
  start_animation_timer()
end

function M.render(windows, force_refresh)
  if not state.active_session and not state.new_session_name then
    return
  end

  -- If we're just updating the animation frame and not doing a full refresh, use the lightweight update
  if not force_refresh and state.goose_run_job and M._animation.loading_line then
    if M._update_loading_animation(windows) then
      return
    end
  end

  local output_lines = M._read_session(force_refresh)
  local is_new_session = state.new_session_name ~= nil

  if not output_lines then
    if is_new_session then
      output_lines = formatter.session_title(LABELS.NEW_SESSION_TITLE)
    else
      return
    end
  else
    state.new_session_name = nil
  end

  if state.goose_run_job then
    if #output_lines > 2 then
      for _, line in ipairs(formatter.separator) do
        table.insert(output_lines, line)
      end
    end

    -- Replace this line with our extmark animation
    local empty_loading_line = " " -- Just needs to be a non-empty string for the extmark to attach to
    table.insert(output_lines, empty_loading_line)
    table.insert(output_lines, "")

    M._animation.loading_line = #output_lines - 1

    -- Start animation with the separated timer approach
    if not M._animation.timer and not M._refresh_timer then
      M._animate_loading(windows)
    end

    -- Trigger an immediate update of the loading animation
    vim.schedule(function()
      M._update_loading_animation(windows)
    end)
  else
    -- Clean up both timers when job is done
    M._animation.loading_line = nil

    -- Clear any loading animation extmarks
    local ns_id = vim.api.nvim_create_namespace('loading_animation')
    vim.api.nvim_buf_clear_namespace(windows.output_buf, ns_id, 0, -1)

    if M._animation.timer then
      pcall(vim.fn.timer_stop, M._animation.timer)
      M._animation.timer = nil
    end

    if M._refresh_timer then
      pcall(vim.fn.timer_stop, M._refresh_timer)
      M._refresh_timer = nil
    end
  end

  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(windows.output_buf, 0, -1, false, output_lines)
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(windows.output_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(windows.output_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(windows.output_buf, 'swapfile', false)

  local line_count = vim.api.nvim_buf_line_count(windows.output_buf)

  -- Get the current topline (first visible line) and botline (last visible line)
  local topline = vim.fn.line('w0', windows.output_win)
  local botline = vim.fn.line('w$', windows.output_win)

  -- Store the previous total line count
  local prev_line_count = vim.b[windows.output_buf].prev_line_count or 0
  vim.b[windows.output_buf].prev_line_count = line_count

  -- Check if user was already viewing the bottom
  local was_at_bottom = (botline >= prev_line_count) or prev_line_count == 0

  -- Only auto-scroll if we were already at the bottom
  if was_at_bottom then
    -- Scroll to bottom
    vim.api.nvim_win_set_cursor(windows.output_win, { line_count, 0 })
  end
end

return M
