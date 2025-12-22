local M = {}

local mentions_namespace = vim.api.nvim_create_namespace("GooseMentions")

function M.highlight_all_mentions(buf)
  local patterns = {
    { prefix = "@", pattern = "@[%w_%-%.]+",  is_file = true },
    { prefix = "#", pattern = "#[%w_%-%%.]+", is_file = false }
  }

  vim.api.nvim_buf_clear_namespace(buf, mentions_namespace, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for row, line in ipairs(lines) do
    for _, pat_info in ipairs(patterns) do
      local start_idx = 1
      while true do
        local mention_start, mention_end = line:find(pat_info.pattern, start_idx)
        if not mention_start then break end

        -- Check if preceded by a word character (skip if true)
        local prev_char = mention_start > 1 and line:sub(mention_start - 1, mention_start - 1) or ""
        local is_word_boundary = prev_char == "" or not prev_char:match("[%w_]")

        if is_word_boundary then
          vim.api.nvim_buf_set_extmark(buf, mentions_namespace, row - 1, mention_start - 1, {
            end_col = mention_end,
            hl_group = "Special",
          })
        end

        start_idx = mention_end + 1
      end
    end
  end
end

local function insert_mention(windows, row, col, name, mention_key)
  local current_line = vim.api.nvim_buf_get_lines(windows.input_buf, row - 1, row, false)[1]

  local insert_name = mention_key .. name .. " "

  local new_line = current_line:sub(1, col) .. insert_name .. current_line:sub(col + 2)
  vim.api.nvim_buf_set_lines(windows.input_buf, row - 1, row, false, { new_line })

  -- Highlight all mentions in the updated buffer
  M.highlight_all_mentions(windows.input_buf)

  vim.defer_fn(function()
    vim.cmd('startinsert')
    vim.api.nvim_set_current_win(windows.input_win)
    vim.api.nvim_win_set_cursor(windows.input_win, { row, col + 1 + #insert_name + 1 })
  end, 100)
end

function M.mention(get_name, mention_key)
  local windows = require('goose.state').windows

  local cursor_pos = vim.api.nvim_win_get_cursor(windows.input_win)
  local row, col = cursor_pos[1], cursor_pos[2]

  -- Check if we're at a word boundary
  local current_line = vim.api.nvim_buf_get_lines(windows.input_buf, row - 1, row, false)[1]
  local prev_char = col > 0 and current_line:sub(col, col) or ""
  local is_word_boundary = prev_char == "" or not prev_char:match("[%w_]")

  -- If not at word boundary, just insert the character
  if not is_word_boundary then
    vim.api.nvim_feedkeys(mention_key, 'in', true)
    return
  end

  -- insert mention key in case we just want the character
  vim.api.nvim_feedkeys(mention_key, 'in', true)

  get_name(function(name)
    insert_mention(windows, row, col, name, mention_key)
  end)
end

return M
