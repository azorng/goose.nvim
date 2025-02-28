local command = require("goose.command")
local config = require("goose.config")
local session = require("goose.session")
local helpers = require("tests.helpers")

describe("goose.command", function()
  local test_file, buf_id
  local original_config
  local original_getcwd = vim.fn.getcwd
  local original_get_last_session = session.get_last_session

  -- Save original functions and config before each test
  before_each(function()
    original_config = vim.deepcopy(config.values)

    -- Create a temporary test file
    test_file = helpers.create_temp_file("Test file content\nLine 2\nLine 3")
    buf_id = helpers.open_buffer(test_file)

    -- Set the test callback
    config.setup({
      command_callback = function(cmd) return cmd end
    })

    -- Mock getcwd
    vim.fn.getcwd = function()
      return "/mock/project/dir"
    end

    -- Mock session.get_last_session
    session.get_last_session = function()
      return {
        id = "20250404_181138",
        path = "/mock/session/path",
        modified = "2025-04-04",
        metadata = {
          working_dir = "/mock/project/dir"
        }
      }
    end
  end)

  -- Restore original functions and config after each test
  after_each(function()
    config.values = original_config
    vim.fn.getcwd = original_getcwd
    session.get_last_session = original_get_last_session

    -- Clean up
    pcall(function()
      if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        helpers.close_buffer(buf_id)
      end
      if test_file then
        helpers.delete_temp_file(test_file)
      end
    end)
    helpers.reset_editor()
  end)

  it("builds a command with the provided prompt", function()
    local prompt = "Help me understand this code"
    local cmd = command.build_command({ prompt = prompt })
    
    -- Check basic components are in the command string
    assert.is_not_nil(cmd)
    assert.truthy(cmd:match("goose run"))
    assert.truthy(cmd:match("--interactive"))
    assert.truthy(cmd:match("--text"))
  end)

  it("builds a command with the provided resume opt", function()
    local prompt = "Help me understand this code"
    local cmd = command.build_command({ prompt = prompt, resume_session = true })

    -- Verify we have the resume flag
    assert.truthy(cmd:match("--resume"))

    -- Verify we're using the session name from the last session
    assert.truthy(cmd:match("--name 20250404_181138"))
  end)

  it("handles resume when no previous session exists", function()
    -- Mock to return nil for no previous session
    session.get_last_session = function() return nil end

    local prompt = "Help me understand this code"
    local cmd = command.build_command({ prompt = prompt, resume_session = true })

    assert.falsy(cmd:match("--resume"))
    assert.falsy(cmd:match("--name"))
  end)
end)
