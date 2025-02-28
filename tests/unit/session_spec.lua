local session = require('goose.session')

describe("goose.session", function()
  local session_mock = require('tests.mocks.session_mock')
  local original_popen = io.popen -- Store the original io.popen

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
  end)

  -- Restore original functions after each test
  after_each(function()
    io.popen = original_popen
  end)

  describe("get_last_session", function()
    it("should get last session from project dir", function()
      local project_dir = '/Users/jimmy/myproject1'

      -- Run the test
      local res = session.get_last_session(project_dir)

      -- Assert the expected result
      -- The result should be the newest session with matching project_dir
      assert.equal('new-8', res.id)
      assert.equal('/Users/jimmy/myproject1', res.metadata.working_dir)
    end)

    it("should return nil if no matching sessions found", function()
      local project_dir = '/Users/jimmy/nonexistent'

      -- Run the test
      local res = session.get_last_session(project_dir)

      -- Assert the expected result
      assert.is_nil(res)
    end)
  end)
end)
