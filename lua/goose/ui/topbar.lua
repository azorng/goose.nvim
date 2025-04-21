local M = {}

local state = require("goose.state")

local LABELS = {
  NEW_SESSION_TITLE = "New session",
}

local function format_model_name()
  local model = require("goose.info").parse_goose_info().goose_model
  return (model and (model:match("[^/]+$") or model) or "")
end

local function create_winbar_text(description, model_name, win_width)
  local available_width = win_width - 2
  local padding = string.rep(" ", available_width - #description - #model_name)
  return string.format(" %s%s%s ", description, padding, model_name)
end

local function update_winbar_highlights(win_id)
  local current = vim.api.nvim_win_get_option(win_id, 'winhighlight')
  local parts = vim.split(current, ",")

  -- Remove any existing winbar highlights
  parts = vim.tbl_filter(function(part)
    return not part:match("^WinBar:") and not part:match("^WinBarNC:")
  end, parts)

  if not vim.tbl_contains(parts, "Normal:GooseNormal") then
    table.insert(parts, "Normal:GooseNormal")
  end

  table.insert(parts, "WinBar:GooseSessionDescription")
  table.insert(parts, "WinBarNC:GooseSessionDescription")

  vim.api.nvim_win_set_option(win_id, 'winhighlight', table.concat(parts, ","))
end

local function get_session_desc()
  local session_desc = LABELS.NEW_SESSION_TITLE

  if state.active_session then
    local session = require('goose.session').get_by_name(state.active_session.name)
    if session and session.description ~= "" then
      session_desc = session.description
    end
  end

  return session_desc
end

function M.render()
  local win = state.windows.output_win

  vim.schedule(function()
    vim.wo[win].winbar = create_winbar_text(
      get_session_desc(),
      format_model_name(),
      vim.api.nvim_win_get_width(win)
    )

    update_winbar_highlights(win)
  end)
end

return M
