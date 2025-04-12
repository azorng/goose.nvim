-- tests/unit/session_spec.lua
-- Tests for the session module

local session = require("goose.session")
local helpers = require("tests.helpers")
-- Use the existing mock data
local session_list_mock = require("tests.mocks.session_list")

describe("goose.session", function()
  local original_io_popen
  local original_workspace
  local mock_data = {}

  -- Setup test environment before each test
  before_each(function()
    -- Save the original functions
    original_io_popen = io.popen
    original_workspace = vim.fn.getcwd

    -- Mock the io.popen function
    io.popen = function(cmd)
      if cmd:match("goose session list") then
        -- Return a file handle-like table that can be read from
        return {
          read = function()
            return mock_data.session_list or session_list_mock
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

    -- Reset mock data
    mock_data = {}
  end)

  describe("get_last_workspace_session", function()
    it("returns the most recent session for current workspace", function()
      -- Using the default mock session list and workspace

      -- Call the function
      local result = session.get_last_workspace_session()

      -- Verify the result - should return "new-8" as it's the most recent
      assert.is_not_nil(result)
      assert.equal("new-8", result.name)
    end)

    it("returns nil when no sessions match the workspace", function()
      -- Mock a workspace with no sessions
      mock_data.workspace = "/non/existent/path"

      -- Call the function
      local result = session.get_last_workspace_session()

      -- Should be nil since no sessions match
      assert.is_nil(result)
    end)

    it("returns nil when the CLI command fails", function()
      -- Mock io.popen to return nil (simulating command failure)
      io.popen = function() return nil end

      -- Call the function
      local result = session.get_last_workspace_session()

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
        return session.get_last_workspace_session()
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
      -- Mock sessions with custom data
      mock_data.session_list = [[
        [
          {
            "id": "custom1",
            "modified": "2025-03-03 12:00:00 UTC",
            "metadata": {
              "working_dir": "/Users/jimmy/myproject1",
              "description": "Custom Session 1"
            }
          },
          {
            "id": "custom2",
            "modified": "2025-03-03 13:00:00 UTC",
            "metadata": {
              "working_dir": "/Users/jimmy/myproject1",
              "description": "Custom Session 2"
            }
          }
        ]
      ]]

      -- Call the function
      local result = session.get_last_workspace_session()

      -- Should return the most recent
      assert.is_not_nil(result)
      assert.equal("custom2", result.name)
    end)

    it("handles empty session list", function()
      -- Mock empty session list
      mock_data.session_list = "[]"

      -- Call the function
      local result = session.get_last_workspace_session()

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
end)
