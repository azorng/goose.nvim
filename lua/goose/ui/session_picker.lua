local M = {}

local function get_best_picker()
  local prefered_picker = require("goose.config").get("prefered_picker")
  if prefered_picker and prefered_picker ~= "" then
    return prefered_picker
  end

  if pcall(require, "telescope") then return "telescope" end
  if pcall(require, "fzf-lua") then return "fzf" end
  if pcall(require, "mini.pick") then return "mini.pick" end
  if pcall(require, "snacks") then return "snacks" end
  return nil
end

local function dispatch(callback, session, action)
  if not session then return end

  vim.schedule(function()
    callback(session, action)
  end)
end

local function telescope_ui(sessions, opts, callback)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local telescope_config = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = opts.prompt,
    previewer = false,
    finder = finders.new_table({
      results = sessions,
      entry_maker = function(session)
        local display = opts.format_item(session)
        return {
          display = display,
          ordinal = display,
          value = session,
        }
      end,
    }),
    sorter = telescope_config.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function choose(action)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        dispatch(callback, selection and selection.value, action)
      end

      actions.select_default:replace(function()
        choose("select")
      end)
      map({ "i", "n" }, "<C-x>", function()
        choose("delete")
      end)
      return true
    end,
  }):find()
end

local function fzf_ui(sessions, opts, callback)
  local fzf_lua = require("fzf-lua")
  local entries = {}
  for index, session in ipairs(sessions) do
    table.insert(entries, string.format("%d\t%s", index, opts.format_item(session)))
  end

  local function choose(selected, action)
    if not selected or not selected[1] then return end

    local index = tonumber(selected[1]:match("^(%d+)\t"))
    dispatch(callback, index and sessions[index], action)
  end

  fzf_lua.fzf_exec(entries, {
    prompt = opts.prompt .. "> ",
    fzf_opts = {
      ["--delimiter"] = "\t",
      ["--with-nth"] = "2..",
      ["--no-multi"] = true,
    },
    actions = {
      ["enter"] = function(selected)
        choose(selected, "select")
      end,
      ["ctrl-x"] = function(selected)
        choose(selected, "delete")
      end,
    },
  })
end

local function mini_pick_ui(sessions, opts, callback)
  local mini_pick = require("mini.pick")
  local items = vim.tbl_map(function(session)
    return {
      text = opts.format_item(session),
      session = session,
    }
  end, sessions)

  mini_pick.start({
    source = {
      name = opts.prompt,
      items = items,
      choose = function(item)
        dispatch(callback, item and item.session, "select")
        return false
      end,
    },
    mappings = {
      mark = "",
      delete_session = {
        char = "<C-x>",
        func = function()
          local matches = mini_pick.get_picker_matches()
          local item = matches and matches.current
          dispatch(callback, item and item.session, "delete")
          return true
        end,
      },
    },
  })
end

local function snacks_ui(sessions, opts, callback)
  local Snacks = require("snacks")
  local completed = false

  local function delete_session(picker, item)
    if completed then return end
    completed = true
    picker:close()
    dispatch(callback, item and item.item, "delete")
  end

  Snacks.picker.select(sessions, {
    prompt = opts.prompt,
    format_item = opts.format_item,
    snacks = {
      actions = {
        delete_session = delete_session,
      },
      win = {
        input = {
          keys = {
            ["<C-x>"] = { "delete_session", mode = { "i", "n" }, desc = "Delete session" },
          },
        },
        list = {
          keys = {
            ["<C-x>"] = { "delete_session", mode = { "n", "x" }, desc = "Delete session" },
          },
        },
      },
    },
  }, function(session)
    if completed or not session then return end
    completed = true
    dispatch(callback, session, "select")
  end)
end

local function native_ui(sessions, opts, callback)
  local lines = vim.tbl_map(opts.format_item, sessions)
  local width = vim.api.nvim_strwidth(opts.prompt)
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end

  width = math.min(width + 2, math.max(vim.o.columns - 4, 1))
  local height = math.min(#lines, math.max(vim.o.lines - 4, 1))
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.bo[buffer].modifiable = false
  vim.bo[buffer].bufhidden = "wipe"

  local win_opts = {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
  }
  if vim.fn.has("nvim-0.9") == 1 then
    win_opts.title = " " .. opts.prompt .. " "
    win_opts.title_pos = "center"
  end

  local window = vim.api.nvim_open_win(buffer, true, win_opts)
  vim.wo[window].cursorline = true

  local closed = false
  local function close()
    if closed then return end
    closed = true
    pcall(vim.api.nvim_win_close, window, true)
  end

  local function choose(action)
    local row = vim.api.nvim_win_get_cursor(window)[1]
    local selected = sessions[row]
    close()
    dispatch(callback, selected, action)
  end

  vim.keymap.set("n", "<CR>", function() choose("select") end, { buffer = buffer, nowait = true })
  vim.keymap.set("n", "<C-x>", function() choose("delete") end, { buffer = buffer, nowait = true })
  vim.keymap.set("n", "q", close, { buffer = buffer, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buffer, nowait = true })
end

function M.select(sessions, opts, callback)
  local picker = get_best_picker()

  vim.schedule(function()
    if picker == "telescope" then
      telescope_ui(sessions, opts, callback)
    elseif picker == "fzf" then
      fzf_ui(sessions, opts, callback)
    elseif picker == "mini.pick" then
      mini_pick_ui(sessions, opts, callback)
    elseif picker == "snacks" then
      snacks_ui(sessions, opts, callback)
    else
      native_ui(sessions, opts, callback)
    end
  end)
end

return M
