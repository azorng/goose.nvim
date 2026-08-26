local core = require("goose.core")
local state = require("goose.state")
local ui = require("goose.ui.ui")
local session = require("goose.session")
local job = require("goose.job")
local topbar = require("goose.ui.topbar")
local helpers = require("tests.helpers")

describe("goose.core", function()
  local original_state

  before_each(function()
    original_state = vim.deepcopy(state)

    -- Mock required functions
    ui.create_windows = function()
      return {
        mock = "windows",
        input_buf = 1,
        output_buf = 2,
        input_win = 3,
        output_win = 4
      }
    end
    ui.clear_output = function() end
    ui.render_output = function() end
    ui.focus_input = function() end
    ui.focus_output = function() end
    ui.scroll_to_bottom = function() end
    ui.is_output_empty = function() return true end
    ui.confirm_session_deletion = function(_, callback) callback(true) end
    session.get_last_session = function() return nil end
    session.get_sessions = function() return {} end
    session.remove = function(_, callback) callback(true) end
    job.execute = function() end
    topbar.render = function() end
  end)

  after_each(function()
    -- Restore state
    for k, v in pairs(original_state) do
      state[k] = v
    end
  end)

  describe("open", function()
    it("loads the latest session on first use", function()
      state.windows = nil
      state.active_session = nil
      state.session_initialized = false

      local session_queries = 0
      session.get_last_session = function()
        session_queries = session_queries + 1
        return { name = "test-session" }
      end

      core.open({ new_session = false, focus = "input" })
      core.open({ new_session = false, focus = "input" })

      assert.equal(1, session_queries)
      assert.equal("test-session", state.active_session.name)
    end)

    it("does not query sessions when opening a new session", function()
      state.windows = nil
      state.active_session = nil
      state.session_initialized = false

      local queried_sessions = false
      session.get_last_session = function()
        queried_sessions = true
      end

      core.open({ new_session = true, focus = "input" })

      assert.is_false(queried_sessions)
      assert.is_true(state.session_initialized)
    end)

    it("creates windows if they don't exist", function()
      state.windows = nil

      core.open({ new_session = false, focus = "input" })

      assert.truthy(state.windows, "Windows should be created")
      -- Fix the expected output to match mocked window structure
      assert.same({
        mock = "windows",
        input_buf = 1,
        output_buf = 2,
        input_win = 3,
        output_win = 4
      }, state.windows)
    end)

    it("handles new session properly", function()
      state.windows = nil
      state.active_session = { id = "old-session" }

      local ui_clear_called = false
      ui.clear_output = function() ui_clear_called = true end

      core.open({ new_session = true, focus = "input" })

      assert.is_nil(state.active_session)
      assert.is_true(ui_clear_called)
    end)

    it("focuses the appropriate window", function()
      state.windows = nil

      local input_focused = false
      local output_focused = false

      ui.focus_input = function() input_focused = true end
      ui.focus_output = function() output_focused = true end

      core.open({ new_session = false, focus = "input" })
      assert.is_true(input_focused)
      assert.is_false(output_focused)

      -- Reset
      input_focused = false
      output_focused = false

      core.open({ new_session = false, focus = "output" })
      assert.is_false(input_focused)
      assert.is_true(output_focused)
    end)
  end)

  describe("select_session", function()
    it("filters sessions and sets the active session based on user selection", function()
      -- Mock sessions data
      local mock_sessions = {
        { name = "session1", description = "First session", modified = "2025-04-01" },
        { name = "session2", description = "",              modified = "2025-04-02" }, -- This one should be filtered out
        { name = "session3", description = "Third session", modified = "2025-04-03" }
      }

      -- Mock get_sessions to return our mock data
      session.get_sessions = function() return mock_sessions end

      -- Mock ui.select_session to simulate user selection
      local filtered_sessions_passed
      local callback_passed

      ui.select_session = function(sessions, callback)
        filtered_sessions_passed = sessions
        callback_passed = callback

        -- Simulate user selecting the third session
        callback(sessions[2]) -- This should be session3 after filtering
      end

      -- Mock render_output to verify it's called
      local render_output_called = false
      ui.render_output = function() render_output_called = true end

      local scroll_to_bottom_called = false
      ui.scroll_to_bottom = function() scroll_to_bottom_called = true end

      -- Set up state for the test
      state.windows = {
        input_buf = 1,
        output_buf = 2,
        input_win = 3,
        output_win = 4
      }
      state.active_session = nil

      -- Call the function being tested
      core.select_session()

      -- Verify results
      assert.truthy(filtered_sessions_passed, "Sessions should be passed to UI select")
      assert.equal(2, #filtered_sessions_passed, "Empty descriptions should be filtered out")
      assert.equal("session3", filtered_sessions_passed[2].name, "Session should be in filtered list")

      -- Verify active session was set
      assert.truthy(state.active_session, "Active session should be set")
      assert.equal("session3", state.active_session.name, "Active session should match selected session")

      -- Verify output is rendered
      assert.is_true(render_output_called, "Output should be rendered")
      assert.is_true(scroll_to_bottom_called, "Windows should scroll to bottom")
    end)

    it("handles case where no windows exist", function()
      -- Mock sessions data
      local mock_sessions = {
        { name = "session1", description = "First session", modified = "2025-04-01" }
      }

      -- Mock get_sessions to return our mock data
      session.get_sessions = function() return mock_sessions end

      -- Mock ui.select_session to simulate user selection
      ui.select_session = function(sessions, callback)
        callback(sessions[1])
      end

      -- Mock functions that would be called by open()
      local open_called = false
      local original_open = core.open
      core.open = function()
        open_called = true
        state.windows = ui.create_windows()
      end

      -- Set up state for the test
      state.windows = nil
      state.active_session = nil

      -- Call the function being tested
      core.select_session()

      -- Restore original open function
      core.open = original_open

      -- Verify active session was set
      assert.truthy(state.active_session, "Active session should be set")
      assert.equal("session1", state.active_session.name, "Active session should match selected session")

      -- Verify open was called when windows don't exist
      assert.is_true(open_called, "core.open should be called when windows don't exist")
    end)
  end)

  describe("select_session delete action", function()
    it("deletes the highlighted session and clears it when active", function()
      local selected_session = {
        name = "session1",
        description = "First session",
        modified = "2025-04-01"
      }
      session.get_sessions = function() return { selected_session } end
      ui.select_session = function(sessions, callback) callback(sessions[1], "delete") end

      local removed_session_id
      session.remove = function(session_id, callback)
        removed_session_id = session_id
        callback(true)
      end

      local output_cleared = false
      local topbar_rendered = false
      ui.clear_output = function() output_cleared = true end
      topbar.render = function() topbar_rendered = true end

      state.active_session = selected_session
      state.last_sent_context = { "context" }
      state.windows = { mock = "windows" }

      local notifications = helpers.mock_notify()
      core.select_session()

      assert.equal("session1", removed_session_id)
      assert.is_nil(state.active_session)
      assert.is_nil(state.last_sent_context)
      assert.is_true(output_cleared)
      assert.is_true(topbar_rendered)
      assert.equal("Deleted session: First session", notifications.get_notifications()[1].msg)
      notifications.reset()
    end)

    it("does not delete a session when confirmation is cancelled", function()
      session.get_sessions = function()
        return { { name = "session1", description = "First session" } }
      end
      ui.select_session = function(sessions, callback) callback(sessions[1], "delete") end
      ui.confirm_session_deletion = function(_, callback) callback(false) end

      local remove_called = false
      session.remove = function() remove_called = true end

      core.select_session()

      assert.is_false(remove_called)
    end)

    it("preserves the active session when deletion fails", function()
      local selected_session = { name = "session1", description = "First session" }
      session.get_sessions = function() return { selected_session } end
      ui.select_session = function(sessions, callback) callback(sessions[1], "delete") end
      session.remove = function(_, callback) callback(false) end
      state.active_session = selected_session

      local notifications = helpers.mock_notify()
      core.select_session()

      assert.same(selected_session, state.active_session)
      assert.equal(vim.log.levels.ERROR, notifications.get_notifications()[1].level)
      notifications.reset()
    end)
  end)

  describe("run", function()
    it("executes a job with the provided prompt", function()
      state.windows = { mock = "windows" }

      local original_defer_fn = vim.defer_fn
      vim.defer_fn = function(callback, timeout)
        -- Execute the callback immediately for testing
        callback()
      end

      local job_execute_called = false
      local execute_prompt = nil
      local execute_handlers = nil

      job.execute = function(prompt, handlers)
        job_execute_called = true
        execute_prompt = prompt
        execute_handlers = handlers
        -- Call the start handler to simulate job start
        if handlers and handlers.on_start then
          handlers.on_start()
        end
      end

      core.run("test prompt")

      -- Restore original function
      vim.defer_fn = original_defer_fn

      assert.is_true(job_execute_called)
      assert.equal("test prompt", execute_prompt)
      assert.truthy(execute_handlers)
    end)

    it("creates UI when running a job even without ensure_ui option", function()
      state.windows = nil

      local windows_created = false
      ui.create_windows = function()
        windows_created = true
        return { mock = "windows" }
      end

      core.run("test prompt")

      assert.is_true(windows_created)
      assert.truthy(state.windows)
    end)

    it("respects new_session option when creating UI", function()
      state.windows = nil
      state.active_session = { id = "old-session" }

      local ui_clear_called = false
      ui.clear_output = function() ui_clear_called = true end

      core.run("test prompt", { new_session = true })

      assert.is_nil(state.active_session)
      assert.is_true(ui_clear_called)
    end)

    it("respects new_session option even when UI already exists", function()
      state.windows = { mock = "windows" }
      state.active_session = { id = "old-session" }

      core.run("test prompt", { new_session = true })

      assert.is_nil(state.active_session, "Active session should be nil when new_session is true")
    end)

    it("defaults to creating a new session when active_session is nil", function()
      state.windows = nil
      state.active_session = nil

      local open_new_session_called = false
      local open_new_session_param = nil

      -- Save original open function
      local original_open = core.open

      -- Mock the open function
      core.open = function(opts)
        open_new_session_called = true
        open_new_session_param = opts.new_session

        -- Call the original to maintain functionality
        state.windows = ui.create_windows()
      end

      core.run("test prompt")

      -- Restore original open function
      core.open = original_open

      assert.is_true(open_new_session_called)
      assert.is_true(open_new_session_param)
    end)
  end)

  describe("session id extraction from banner", function()
    it("extracts session id from goose CLI banner line", function()
      local banner_line = "   \\____)    20260320_185 · /Users/azor/projects/goose.nvim"
      local session_id = banner_line:match("(%w+_%w+)%s+·")
      assert.equal("20260320_185", session_id)
    end)

    it("does not match non-banner lines", function()
      local lines = {
        '    __( O)>  ● new session · openrouter anthropic/claude-opus-4.6',
        '     L L     goose is ready',
        '{"type":"message","message":{"id":"gen-123"}}',
        '{"type":"complete","total_tokens":5666}',
      }
      for _, line in ipairs(lines) do
        local session_id = line:match("(%w+_%w+)%s+·")
        assert.is_nil(session_id, "Should not match: " .. line)
      end
    end)

    it("sets active_session when on_output receives banner with session id", function()
      state.windows = { mock = "windows" }
      state.active_session = nil

      local captured_handlers = nil

      local original_defer_fn = vim.defer_fn
      vim.defer_fn = function(callback, _timeout)
        callback()
      end

      job.execute = function(_prompt, handlers)
        captured_handlers = handlers
        if handlers and handlers.on_start then
          handlers.on_start("test message")
        end
      end

      local mock_session = { name = "20260320_185", description = "test" }
      session.get_by_name = function(name)
        if name == "20260320_185" then return mock_session end
        return nil
      end

      core.run("test prompt")

      assert.truthy(captured_handlers, "Handlers should be captured")
      captured_handlers.on_output("   \\____)    20260320_185 · /Users/azor/projects/goose.nvim")

      assert.same(mock_session, state.active_session, "Active session should be set from banner")

      vim.defer_fn = original_defer_fn
    end)
  end)
end)
