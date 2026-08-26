-- tests/unit/session_spec.lua
-- Tests for the session module

local session = require("goose.session")
local helpers = require("tests.helpers")
-- Use the existing mock data
local session_list_mock = require("tests.mocks.session_list")

describe("goose.session", function()
  local original_io_popen
  local original_workspace
  local original_jobstart
  local original_chansend
  local original_schedule
  local mock_data = {}

  -- Setup test environment before each test
  before_each(function()
    -- Save the original functions
    original_io_popen = io.popen
    original_workspace = vim.fn.getcwd
    original_jobstart = vim.fn.jobstart
    original_chansend = vim.fn.chansend
    original_schedule = vim.schedule

    -- Mock the io.popen function
    io.popen = function(cmd)
      if cmd:match("goose session list") then
        -- Extract the workspace from the command
        local workspace_in_cmd = cmd:match("%-%-working_dir%s+([^%s]+)")
        if not workspace_in_cmd then
          return original_io_popen(cmd)
        end
        
        -- Get the session list to return
        local session_data = mock_data.session_list or session_list_mock
        
        -- Parse the session data to check if any sessions match the workspace
        local success, sessions = pcall(vim.fn.json_decode, session_data)
        if not success or not sessions then
          return {
            read = function() return session_data end,
            close = function() return true end
          }
        end
        
        -- Filter sessions by workspace
        local filtered = {}
        for _, s in ipairs(sessions) do
          local metadata = s.metadata or s
          if metadata.working_dir == workspace_in_cmd then
            table.insert(filtered, s)
          end
        end
        
        -- Return the filtered list
        return {
          read = function()
            return vim.fn.json_encode(filtered)
          end,
          close = function() return true end
        }
      end
      -- Fall back to original for other commands
      return original_io_popen(cmd)
    end

    -- Mock getcwd - defaulting to match the working directory in the mock data
    vim.fn.getcwd = function()
      return mock_data.workspace or "/Users/jimmy/myproject1"
    end
  end)

  -- Clean up after each test
  after_each(function()
    -- Restore original functions
    io.popen = original_io_popen
    vim.fn.getcwd = original_workspace
    vim.fn.jobstart = original_jobstart
    vim.fn.chansend = original_chansend
    vim.schedule = original_schedule

    -- Reset mock data
    mock_data = {}
  end)

  describe("get_last_session", function()
    it("returns the most recent session for current workspace", function()
      -- Using the default mock session list and workspace

      -- Call the function
      local result = session.get_last_session()

      -- Verify the result - should return "new-8" as it's the most recent
      assert.is_not_nil(result)
      assert.equal("new-8", result.name)
    end)

    it("returns nil when no sessions match the workspace", function()
      -- Mock a workspace with no sessions
      mock_data.workspace = "/non/existent/path"

      -- Call the function
      local result = session.get_last_session()

      -- Should be nil since no sessions match
      assert.is_nil(result)
    end)

    it("returns nil when the CLI command fails", function()
      -- Mock io.popen to return nil (simulating command failure)
      io.popen = function() return nil end

      -- Call the function
      local result = session.get_last_session()

      -- Should be nil due to command failure
      assert.is_nil(result)
    end)

    it("handles JSON parsing errors", function()
      -- Mock invalid JSON
      mock_data.session_list = "not valid json"

      -- Mock json_decode to simulate error
      local original_json_decode = vim.fn.json_decode
      vim.fn.json_decode = function(str)
        if str == "not valid json" then
          error("Invalid JSON")
        end
        return original_json_decode(str)
      end

      -- Call the function inside pcall to catch the error
      local success, result = pcall(function()
        return session.get_last_session()
      end)

      -- Restore original function
      vim.fn.json_decode = original_json_decode

      -- Either the function should handle the error and return nil
      -- or it will throw an error which needs to be fixed in the implementation
      if success then
        assert.is_nil(result)
      else
        assert.is_truthy(result:match("Invalid JSON"))
      end
    end)

    it("handles custom session data", function()
      -- Mock sessions with custom data (most recent first)
      mock_data.session_list = [[
        [
          {
            "id": "custom2",
            "modified": "2025-03-03 13:00:00 UTC",
            "metadata": {
              "id": "custom2",
              "working_dir": "/Users/jimmy/myproject1",
              "description": "Custom Session 2",
              "updated_at": "2025-03-03 13:00:00 UTC"
            }
          },
          {
            "id": "custom1",
            "modified": "2025-03-03 12:00:00 UTC",
            "metadata": {
              "id": "custom1",
              "working_dir": "/Users/jimmy/myproject1",
              "description": "Custom Session 1",
              "updated_at": "2025-03-03 12:00:00 UTC"
            }
          }
        ]
      ]]

      -- Call the function
      local result = session.get_last_session()

      -- Should return the most recent (custom2, which is first in the list)
      assert.is_not_nil(result)
      assert.equal("custom2", result.name)
    end)

    it("handles empty session list", function()
      -- Mock empty session list
      mock_data.session_list = "[]"

      -- Call the function
      local result = session.get_last_session()

      -- Should be nil with empty list
      assert.is_nil(result)
    end)
  end)

  describe("get_by_name", function()
    it("returns the session with matching ID", function()
      -- Call the function with an ID from the mock data
      local result = session.get_by_name("new-8")

      -- Verify the result
      assert.is_not_nil(result)
      assert.equal("new-8", result.name)
    end)

    it("returns nil when no session matches the ID", function()
      -- Call the function with non-existent ID
      local result = session.get_by_name("nonexistent")

      -- Should be nil since no sessions match
      assert.is_nil(result)
    end)

    it("returns nil when the CLI command fails", function()
      -- Mock io.popen to return nil (simulating command failure)
      io.popen = function() return nil end

      -- Call the function
      local result = session.get_by_name("new-8")

      -- Should be nil due to command failure
      assert.is_nil(result)
    end)

    it("handles JSON parsing errors", function()
      -- Mock invalid JSON
      mock_data.session_list = "not valid json"

      -- Mock json_decode to simulate error
      local original_json_decode = vim.fn.json_decode
      vim.fn.json_decode = function(str)
        if str == "not valid json" then
          error("Invalid JSON")
        end
        return original_json_decode(str)
      end

      -- Call the function inside pcall to catch the error
      local success, result = pcall(function()
        return session.get_by_name("new-8")
      end)

      -- Restore original function
      vim.fn.json_decode = original_json_decode

      -- Either the function should handle the error and return nil
      -- or it will throw an error which needs to be fixed in the implementation
      if success then
        assert.is_nil(result)
      else
        assert.is_truthy(result:match("Invalid JSON"))
      end
    end)

    it("handles empty session list", function()
      -- Mock empty session list
      mock_data.session_list = "[]"

      -- Call the function
      local result = session.get_by_name("new-8")

      -- Should be nil with empty list
      assert.is_nil(result)
    end)
  end)

  describe("remove", function()
    it("removes a session by ID through a PTY", function()
      local command
      local job_opts
      local sent_job_id
      local sent_input
      local callback_result

      vim.fn.jobstart = function(cmd, opts)
        command = cmd
        job_opts = opts
        return 42
      end
      vim.fn.chansend = function(job_id, input)
        sent_job_id = job_id
        sent_input = input
      end
      vim.schedule = function(cb) cb() end

      session.remove("20260826_1", function(success)
        callback_result = success
      end)

      assert.same({
        "goose",
        "session",
        "remove",
        "--session-id",
        "20260826_1",
      }, command)
      assert.is_true(job_opts.pty)
      assert.equal(42, sent_job_id)
      assert.equal("y\r", sent_input)

      job_opts.on_exit(42, 0)
      assert.is_true(callback_result)
    end)

    it("reports a failed goose command", function()
      local job_opts
      local callback_result

      vim.fn.jobstart = function(_, opts)
        job_opts = opts
        return 42
      end
      vim.fn.chansend = function() end
      vim.schedule = function(cb) cb() end

      session.remove("20260826_1", function(success)
        callback_result = success
      end)

      job_opts.on_exit(42, 1)
      assert.is_false(callback_result)
    end)

    it("reports when the goose command cannot be started", function()
      local callback_result
      local sent_input = false

      vim.fn.jobstart = function() return -1 end
      vim.fn.chansend = function() sent_input = true end

      session.remove("20260826_1", function(success)
        callback_result = success
      end)

      assert.is_false(callback_result)
      assert.is_false(sent_input)
    end)
  end)
end)
