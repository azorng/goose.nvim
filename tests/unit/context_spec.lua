-- tests/unit/context_spec.lua
-- Tests for the context module

local context = require("goose.context")
local helpers = require("tests.helpers")
local state = require("goose.state")
local template = require("goose.template")

describe("goose.context", function()
  local test_file, buf_id
  local original_state

  -- Create a temporary file and open it in a buffer before each test
  before_each(function()
    original_state = vim.deepcopy(state)
    test_file = helpers.create_temp_file("Line 1\nLine 2\nLine 3\nLine 4\nLine 5")
    buf_id = helpers.open_buffer(test_file)
  end)

  -- Clean up after each test
  after_each(function()
    -- Restore state
    for k, v in pairs(original_state) do
      state[k] = v
    end

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
      -- Setup a visual selection (line 2 to line 3)
      vim.cmd("normal! 2Gvj$")

      -- Call the function
      local selection = context.get_current_selection()

      -- Check the returned selection contains the expected text
      assert.is_not_nil(selection)
      assert.truthy(selection:match("Line 2"))
      assert.truthy(selection:match("Line 3"))
    end)

    it("returns nil when not in visual mode", function()
      -- Ensure we're in normal mode
      vim.cmd("normal! G")

      -- Call the function
      local selection = context.get_current_selection()

      -- Should be nil since we're not in visual mode
      assert.is_nil(selection)
    end)
  end)

  describe("format_message", function()
    it("formats message with file path and prompt", function()
      -- Mock template.render_template to verify it's called with right params
      local original_render = template.render_template
      local called_with_vars = nil

      template.render_template = function(vars)
        called_with_vars = vars
        return "rendered template"
      end

      -- Set state
      state.current_file = test_file
      state.selection = nil

      local prompt = "Help me with this code"
      local message = context.format_message(prompt)

      -- Restore original function
      template.render_template = original_render

      -- Verify template was called with correct variables
      assert.truthy(called_with_vars)
      assert.equal(test_file, called_with_vars.current_file)
      assert.equal(prompt, called_with_vars.prompt)

      -- Verify the message was returned
      assert.equal("rendered template", message)
    end)

    it("includes selection in template variables when available", function()
      -- Mock template.render_template
      local original_render = template.render_template
      local called_with_vars = nil

      template.render_template = function(vars)
        called_with_vars = vars
        return "rendered template with selection"
      end

      -- Set state
      state.current_file = test_file
      state.selection = "Selected text for testing"

      local prompt = "Help with this selection"
      local message = context.format_message(prompt)

      -- Restore original function
      template.render_template = original_render

      -- Verify template was called with correct variables
      assert.truthy(called_with_vars)
      assert.equal(test_file, called_with_vars.current_file)
      assert.equal(prompt, called_with_vars.prompt)
      assert.equal("Selected text for testing", called_with_vars.selection)

      -- Verify the message was returned
      assert.equal("rendered template with selection", message)
    end)
  end)
end)
