local command = require("goose.command")
local config = require("goose.config")
local state = require("goose.state")
local Job = require('plenary.job')
local helpers = require("tests.helpers")

describe("goose.command", function()
  local test_file, buf_id
  local original_config
  local original_state

  -- Save original functions and config before each test
  before_each(function()
    original_config = vim.deepcopy(config.values)
    original_state = vim.deepcopy(state)

    -- Create a temporary test file
    test_file = helpers.create_temp_file("Test file content\nLine 2\nLine 3")
    buf_id = helpers.open_buffer(test_file)

    -- Set up state for testing
    state.current_file = test_file
    state.active_session = nil
  end)

  -- Restore original functions and config after each test
  after_each(function()
    config.values = original_config

    -- Restore state
    for k, v in pairs(original_state) do
      state[k] = v
    end

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
    local args = command.build_args({ prompt = prompt })

    -- Check basic components are in the args table
    assert.is_not_nil(args)
    assert.truthy(#args >= 2, "Args table should have at least 2 elements")
    assert.equal("run", args[1])
    assert.equal("--text", args[2])

    -- Verify a session name is generated
    local session_name_found = false
    for i, arg in ipairs(args) do
      if arg == "--name" and args[i + 1] then
        session_name_found = true
        break
      end
    end
    assert.truthy(session_name_found, "Should include --name argument")
  end)

  it("builds a command with the provided resume opt", function()
    local test_session = {
      id = "test-session-123",
      path = "/mock/session/path",
      modified = "2025-04-04"
    }
    state.active_session = test_session

    local prompt = "Help me understand this code"
    local args = command.build_args({ prompt = prompt })

    -- Find the "--name" argument and check value
    local name_index = nil
    local resume_found = false

    for i, arg in ipairs(args) do
      if arg == "--name" then
        name_index = i
      elseif arg == "--resume" then
        resume_found = true
      end
    end

    assert.truthy(name_index, "Should include --name argument")
    assert.truthy(resume_found, "Should include --resume argument")
    assert.equal("test-session-123", args[name_index + 1], "Session ID should match active session")
  end)

  it("handles new session creation correctly", function()
    -- Ensure no active session
    state.active_session = nil
    state.new_session_name = nil

    local prompt = "Help me understand this code"
    local args = command.build_args({ prompt = prompt })

    -- Should not have "--resume" flag
    local resume_found = false
    local name_index = nil

    for i, arg in ipairs(args) do
      if arg == "--resume" then
        resume_found = true
      elseif arg == "--name" then
        name_index = i
      end
    end

    assert.falsy(resume_found, "Should not include --resume argument for new session")
    assert.truthy(name_index, "Should include --name argument")
    assert.truthy(state.new_session_name, "Should generate new session name")
    assert.equal(state.new_session_name, args[name_index + 1], "Generated session name should match arg")
  end)
end)
