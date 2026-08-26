local session_picker = require("goose.ui.session_picker")
local config = require("goose.config")

describe("goose.ui.session_picker", function()
  local original_schedule
  local original_picker
  local original_modules = {}
  local module_names = {
    "telescope.pickers",
    "telescope.finders",
    "telescope.config",
    "telescope.actions",
    "telescope.actions.state",
    "fzf-lua",
    "mini.pick",
    "snacks",
  }

  local sessions = {
    { name = "session1", description = "First session" },
    { name = "session2", description = "Second session" },
  }
  local picker_opts = {
    prompt = "Sessions (<C-x> delete)",
    format_item = function(session) return session.description end,
  }

  before_each(function()
    original_schedule = vim.schedule
    original_picker = config.values.prefered_picker
    vim.schedule = function(callback) callback() end

    for _, name in ipairs(module_names) do
      original_modules[name] = package.loaded[name]
    end
  end)

  after_each(function()
    vim.schedule = original_schedule
    config.values.prefered_picker = original_picker

    for _, name in ipairs(module_names) do
      package.loaded[name] = original_modules[name]
    end
  end)

  it("maps <C-x> to delete in telescope", function()
    config.values.prefered_picker = "telescope"
    local delete_action
    local default_action
    local picker_spec
    local closed_buffer

    package.loaded["telescope.pickers"] = {
      new = function(_, spec)
        picker_spec = spec
        return {
          find = function()
            spec.attach_mappings(42, function(modes, key, callback)
              if key == "<C-x>" then
                assert.same({ "i", "n" }, modes)
                delete_action = callback
              end
            end)
          end,
        }
      end,
    }
    package.loaded["telescope.finders"] = {
      new_table = function(opts) return opts end,
    }
    package.loaded["telescope.config"] = {
      values = { generic_sorter = function() return "sorter" end },
    }
    package.loaded["telescope.actions"] = {
      select_default = {
        replace = function(_, callback) default_action = callback end,
      },
      close = function(buffer) closed_buffer = buffer end,
    }
    package.loaded["telescope.actions.state"] = {
      get_selected_entry = function() return { value = sessions[2] } end,
    }

    local selected_session
    local selected_action
    session_picker.select(sessions, picker_opts, function(session, action)
      selected_session = session
      selected_action = action
    end)

    assert.equal(picker_opts.prompt, picker_spec.prompt_title)
    assert.is_function(default_action)
    assert.is_function(delete_action)
    default_action()

    assert.same(sessions[2], selected_session)
    assert.equal("select", selected_action)

    selected_session = nil
    selected_action = nil
    delete_action()

    assert.equal(42, closed_buffer)
    assert.same(sessions[2], selected_session)
    assert.equal("delete", selected_action)
  end)

  it("maps <C-x> to delete in fzf-lua", function()
    config.values.prefered_picker = "fzf"
    local entries
    local opts

    package.loaded["fzf-lua"] = {
      fzf_exec = function(picker_entries, picker_options)
        entries = picker_entries
        opts = picker_options
      end,
    }

    local selected_session
    local selected_action
    session_picker.select(sessions, picker_opts, function(session, action)
      selected_session = session
      selected_action = action
    end)

    assert.same({ "1\tFirst session", "2\tSecond session" }, entries)
    assert.is_function(opts.actions["ctrl-x"])
    opts.actions["ctrl-x"]({ entries[2] })

    assert.same(sessions[2], selected_session)
    assert.equal("delete", selected_action)
  end)

  it("maps <C-x> to delete in mini.pick", function()
    config.values.prefered_picker = "mini.pick"
    local opts

    package.loaded["mini.pick"] = {
      start = function(picker_options) opts = picker_options end,
      get_picker_matches = function()
        return { current = opts.source.items[2] }
      end,
    }

    local selected_session
    local selected_action
    session_picker.select(sessions, picker_opts, function(session, action)
      selected_session = session
      selected_action = action
    end)

    local delete_mapping = opts.mappings.delete_session
    assert.equal("", opts.mappings.mark)
    assert.equal("<C-x>", delete_mapping.char)
    assert.is_true(delete_mapping.func())
    assert.same(sessions[2], selected_session)
    assert.equal("delete", selected_action)
  end)

  it("maps <C-x> to delete in snacks", function()
    config.values.prefered_picker = "snacks"
    local opts

    package.loaded["snacks"] = {
      picker = {
        select = function(_, picker_options)
          opts = picker_options
        end,
      },
    }

    local selected_session
    local selected_action
    session_picker.select(sessions, picker_opts, function(session, action)
      selected_session = session
      selected_action = action
    end)

    assert.same({ "delete_session", mode = { "i", "n" }, desc = "Delete session" },
      opts.snacks.win.input.keys["<C-x>"])

    local picker_closed = false
    opts.snacks.actions.delete_session({
      close = function() picker_closed = true end,
    }, { item = sessions[2] })

    assert.is_true(picker_closed)
    assert.same(sessions[2], selected_session)
    assert.equal("delete", selected_action)
  end)

  it("maps <C-x> to delete in the native fallback", function()
    config.values.prefered_picker = "native"
    local original_window = vim.api.nvim_get_current_win()
    local selected_session
    local selected_action

    session_picker.select(sessions, picker_opts, function(session, action)
      selected_session = session
      selected_action = action
    end)

    local picker_window = vim.api.nvim_get_current_win()
    local picker_buffer = vim.api.nvim_get_current_buf()
    assert.not_equal(original_window, picker_window)
    vim.api.nvim_win_set_cursor(picker_window, { 2, 0 })

    local delete_mapping
    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(picker_buffer, "n")) do
      if mapping.lhs == "<C-X>" then
        delete_mapping = mapping.callback
        break
      end
    end

    assert.is_function(delete_mapping)
    delete_mapping()

    assert.is_false(vim.api.nvim_win_is_valid(picker_window))
    assert.same(sessions[2], selected_session)
    assert.equal("delete", selected_action)
  end)
end)
