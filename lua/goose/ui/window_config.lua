local M = {}

local INPUT_PLACEHOLDER = 'Ask anything...'

function M.close_windows(windows)
  pcall(vim.api.nvim_win_close, windows.input_win, true)
  pcall(vim.api.nvim_win_close, windows.output_win, true)
  pcall(vim.api.nvim_buf_delete, windows.input_buf, { force = true })
  pcall(vim.api.nvim_buf_delete, windows.output_buf, { force = true })
end

function M.set_options(windows)
  -- Input window/buffer options
  vim.api.nvim_win_set_option(windows.input_win, 'winhighlight', 'Normal:Normal,FloatBorder:Normal')
  vim.api.nvim_win_set_option(windows.input_win, 'signcolumn', 'yes')
  vim.b[windows.input_buf].completion = false

  -- Output window/buffer options
  vim.api.nvim_win_set_option(windows.output_win, 'winhighlight', 'Normal:Normal,FloatBorder:Normal')
  vim.api.nvim_buf_set_option(windows.output_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(windows.output_buf, 'modifiable', false)
end

function M.set_placeholder(windows)
  local ns_id = vim.api.nvim_create_namespace('input-placeholder')
  vim.api.nvim_buf_set_extmark(windows.input_buf, ns_id, 0, 0, {
    virt_text = { { INPUT_PLACEHOLDER, 'Comment' } },
    virt_text_pos = 'overlay',
  })
  vim.api.nvim_win_set_option(windows.input_win, 'cursorline', false)
end

function M.set_autocmds(windows)
  local group = vim.api.nvim_create_augroup('MermaidWindows', { clear = true })

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

  -- Placeholder handling
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer = windows.input_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(windows.input_buf, 0, -1, false)
      if #lines == 1 and lines[1] == "" then
        M.set_placeholder(windows)
      else
        vim.api.nvim_buf_clear_namespace(windows.input_buf, vim.api.nvim_create_namespace('input-placeholder'), 0, -1)
        vim.api.nvim_win_set_option(windows.input_win, 'cursorline', true)
      end
    end
  })

  -- Window close handling
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(windows.input_win) .. ',' .. tostring(windows.output_win),
    callback = function(opts)
      -- Get the window that was closed
      local closed_win = tonumber(opts.match)
      -- If either window is closed, close both
      if closed_win == windows.input_win or closed_win == windows.output_win then
        vim.schedule(function()
          M.close_windows(windows)
        end)
      end
    end
  })
end

return M
