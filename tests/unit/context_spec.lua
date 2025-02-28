-- tests/unit/context_spec.lua
-- Tests for the context module

local context = require("goose.context")
local helpers = require("tests.helpers")

describe("goose.context", function()
  local test_file, buf_id

  -- Create a temporary file and open it in a buffer before each test
  before_each(function()
    test_file = helpers.create_temp_file("Line 1\nLine 2\nLine 3\nLine 4\nLine 5")
    buf_id = helpers.open_buffer(test_file)
  end)

  -- Clean up after each test
  after_each(function()
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

  describe("get_current_file", function()
    it("returns the correct file path", function()
      local file_path = context.get_current_file()
      assert.equal(test_file, file_path)
    end)
  end)

  describe("get_current_selection", function()
    it("returns selected text when in visual mode", function()
      -- Setup a visual selection (line 2 to line 4)
      vim.cmd("normal! 2Gvj$")

      -- Call the function
      local selection = context.get_current_selection()

      -- Check the returned selection contains the expected text
      assert.is_not_nil(selection)
      assert.truthy(selection:match("Line 2"))
      assert.truthy(selection:match("Line 3"))
    end)
  end)

  describe("format_message", function()
    it("formats message with file path and prompt", function()
      local prompt = "Help me with this code"
      local message = context.format_message(prompt)

      assert.truthy(string.match(message, "File: .*"))
      assert.truthy(string.match(message, prompt))
    end)
  end)
end)
