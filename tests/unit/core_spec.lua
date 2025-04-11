local core = require("goose.core")
local state = require("goose.state")
local ui = require("goose.ui.ui")
local session = require("goose.session")
local job = require("goose.job")

describe("goose.core", function()
  local original_state

  before_each(function()
    original_state = vim.deepcopy(state)

    -- Mock required functions
    ui.create_windows = function() return { mock = "windows" } end
    ui.clear_output = function() end
    ui.render_output = function() end
    ui.focus_input = function() end
    ui.focus_output = function() end
    session.get_last_workspace_session = function() return { id = "test-session" } end
    job.execute = function() end
  end)

  after_each(function()
    -- Restore state
    for k, v in pairs(original_state) do
      state[k] = v
    end
  end)

  describe("open", function()
    it("creates windows if they don't exist", function()
      state.windows = nil

      core.open({ new_session = false, focus = "input" })

      assert.truthy(state.windows, "Windows should be created")
      assert.same({ mock = "windows" }, state.windows)
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

      job.execute = function(prompt, callback)
        job_execute_called = true
        execute_prompt = prompt
        if callback then callback() end
      end

      core.run("test prompt")

      -- Restore original function
      vim.defer_fn = original_defer_fn

      assert.is_true(job_execute_called)
      assert.equal("test prompt", execute_prompt)
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
end)
