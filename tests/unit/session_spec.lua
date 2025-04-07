local session = require('goose.session')
local goose_module = require('goose.goose')

describe("goose.session", function()
  local session_mock = require('tests.mocks.session_mock')
  local original_popen = io.popen -- Store the original io.popen

  -- Mock functions
  local original_get_last_workspace_session = goose_module.get_last_workspace_session
  local original_get_session_by_name = goose_module.get_session_by_name

  -- Set up mocks before each test
  before_each(function()
    -- Create a proper mock for io.popen
    io.popen = function()
      -- Create a file handle-like object
      return {
        read = function()
          return session_mock
        end,
        close = function()
          -- No-op for close
        end
      }
    end

    -- Mock the goose module functions
    goose_module.get_last_workspace_session = function(workspace)
      if workspace == '/Users/jimmy/myproject1' then
        return {
          id = 'new-8',
          path = '/some/path',
          modified = '2025-04-04',
          metadata = {
            working_dir = '/Users/jimmy/myproject1'
          }
        }
      end
      return nil
    end

    goose_module.get_session_by_name = function(name)
      if name == "test-session" then
        return {
          id = 'test-session',
          path = '/some/path',
          modified = '2025-04-04'
        }
      end
      return nil
    end
  end)

  -- Restore original functions after each test
  after_each(function()
    io.popen = original_popen
    goose_module.get_last_workspace_session = original_get_last_workspace_session
    goose_module.get_session_by_name = original_get_session_by_name
  end)

  describe("get_last_workspace_session", function()
    it("should get last session from project dir", function()
      -- Mock getcwd
      local original_getcwd = vim.fn.getcwd
      vim.fn.getcwd = function() return '/Users/jimmy/myproject1' end

      -- Run the test
      local res = session.get_last_workspace_session()

      -- Restore getcwd
      vim.fn.getcwd = original_getcwd

      -- Assert the expected result
      -- The result should be the newest session with matching project_dir
      assert.equal('new-8', res.id)
      assert.equal('/Users/jimmy/myproject1', res.metadata.working_dir)
    end)

    it("should return nil if no matching sessions found", function()
      -- Mock getcwd
      local original_getcwd = vim.fn.getcwd
      vim.fn.getcwd = function() return '/Users/jimmy/nonexistent' end

      -- Run the test
      local res = session.get_last_workspace_session()

      -- Restore getcwd
      vim.fn.getcwd = original_getcwd

      -- Assert the expected result
      assert.is_nil(res)
    end)
  end)

  describe("get_by_name", function()
    it("should return session by name", function()
      local res = session.get_by_name("test-session")
      assert.equal('test-session', res.id)
    end)

    it("should return nil if no session found with given name", function()
      local res = session.get_by_name("nonexistent-session")
      assert.is_nil(res)
    end)
  end)
end)
