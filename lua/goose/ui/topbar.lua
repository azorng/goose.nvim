local M = {}

local state = require("goose.state")

local LABELS = {
  NEW_SESSION_TITLE = "New session",
}

local function format_model_info()
  local info = require("goose.info").parse_goose_info()
  local config = require("goose.config").get()
  local parts = {}

  if config.ui.display_model then
    local model = info.goose_model and (info.goose_model:match("[^/]+$") or info.goose_model) or ""
    if model ~= "" then
      table.insert(parts, model)
    end
  end

  if config.ui.display_goose_mode then
    local mode = info.goose_mode
    if mode then
      table.insert(parts, "[" .. mode .. "]")
    end
  end

  return table.concat(parts, " ")
end


local function create_winbar_text(description, model_info, win_width)
  local available_width = win_width - 2 -- 2 padding spaces

  -- If total length exceeds available width, truncate description
  if #description + 1 + #model_info > available_width then
    local space_for_desc = available_width - #model_info - 4 -- -4 for "... "
    description = description:sub(1, space_for_desc) .. "... "
  end

  local padding = string.rep(" ", available_width - #description - #model_info)
  return string.format(" %s%s%s ", description, padding, model_info)
end

local function get_session_desc()
  local session_desc = LABELS.NEW_SESSION_TITLE

  if state.active_session then
    local session = require('goose.session').get_by_name(state.active_session.name)
    if session and session.description ~= "" and session.description ~= nil then
      session_desc = session.description
    end
  end

  return session_desc
end

function M.render()
  local win = state.windows.output_win

  vim.schedule(function()
    vim.wo[win].winhighlight = 'WinBar:Comment,WinBarNC:Comment'
    vim.wo[win].winbar = create_winbar_text(
      get_session_desc(),
      format_model_info(),
      vim.api.nvim_win_get_width(win)
    )
  end)
end

return M
