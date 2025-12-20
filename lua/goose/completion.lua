local M = {}

---@type table<string, fun(trigger: string): OmniFnCompleteItem[]>
M.omni_sources = {
  ['/'] = require('goose.slash_commands').get_completable,
  -- ['#'] = function() return {} end, -- Future: skills
  -- ['@'] = function() return {} end, -- Future: file mentions
}

_G.goose_omnifunc = function(findstart, base)
  return require('goose.completion').complete(findstart, base)
end

function M.setup(bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.goose_omnifunc')

  M.setup_cmp_plugins()

  vim.api.nvim_create_autocmd('CompleteDone', {
    buffer = bufnr,
    callback = function()
      M.on_complete_done(vim.v.completed_item)
    end,
  })
end

function M.on_complete_done(item)
  -- complete done trigger handler
  return
end

function M.complete(findstart, base)
  if findstart == 1 then
    return M.find_completion_start()
  else
    return M.get_completions(base)
  end
end

---Scans backwards from cursor to find completion start position for trigger characters.
---@return number column 0-indexed start position, or -3 to cancel completion
function M.find_completion_start()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col('.') - 1

  if col == 0 then
    return -3 -- Cancel completion
  end

  local start_col = col
  while start_col > 0 do
    local char = line:sub(start_col, start_col)
    if M.omni_sources[char] then
      -- Special handling for '/' - only at buffer start
      if char == '/' then
        local line_num = vim.fn.line('.')
        if line_num == 1 and start_col == 1 then
          return start_col - 1 -- Return 0-indexed column
        else
          return -3            -- Cancel - '/' not at buffer start
        end
      end

      -- Other trigger chars: at line start or after whitespace
      if start_col == 1 or line:sub(start_col - 1, start_col - 1):match('%s') then
        return start_col - 1 -- Return 0-indexed column
      else
        return -3            -- Cancel - trigger char not after whitespace
      end
    elseif char:match('%s') then
      break -- Stop at whitespace
    end
    start_col = start_col - 1
  end

  return -3 -- Cancel completion
end

---@return OmniFnCompleteItem[]
function M.get_completions(base)
  local trigger = base:sub(1, 1)
  local source_fn = M.omni_sources[trigger]
  if not source_fn then return {} end
  return source_fn(trigger)
end

---In case other completion plugins are used, setup any necessary integration here.
function M.setup_cmp_plugins()
  -- Blink
  local blink_enabled, blink_config = pcall(require, 'blink.cmp.config')
  if blink_enabled then
    blink_config.sources.per_filetype.GooseInput = { 'omni' }
    blink_config.sources.providers.omni.override = {
      get_trigger_characters = function()
        if vim.bo.filetype == 'GooseInput' then
          return vim.tbl_keys(M.omni_sources)
        end
        return {}
      end
    }
  end
end

return M
