# goose.nvim

> goose neovim plugin

### With lazy.nvim

```lua
{
    'sheldonth/goose.nvim',
        branch = 'main',
        config = function()
            require('goose').setup({})
            end,
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "MeanderingProgrammer/render-markdown.nvim",
                opts = {
                    anti_conceal = { enabled = false },
                },
            }
        },
}
```


```lua
-- Default configuration with all available options
require('goose').setup({
  keymap = {
    global = {
      open_input = '<leader>gi',             -- Opens and focuses on input window. Loads current buffer context
      open_input_new_session = '<leader>gI', -- Opens and focuses on input window. Loads current buffer context. Creates a new session
      open_output = '<leader>go',            -- Opens and focuses on output window. Loads current buffer context
      close = '<leader>gq',                  -- Close UI windows
      toggle_fullscreen = '<leader>gf',      -- Toggle between normal and fullscreen mode
      select_session = '<leader>gs',         -- Select and load a goose session
      resume_session = '<leader>gr',         -- Resume a previous session with full conversation history
      toggle_code_ui = '<leader>gt',         -- Toggle between code buffer and goose UI
    },
    window = {
      submit = '<cr>',                     -- Submit prompt
      close = '<esc>',                     -- Close UI windows
      stop = '<C-c>',                      -- Stop a running job
      next_message = ']]',                 -- Navigate to next message in the conversation
      prev_message = '[[',                 -- Navigate to previous message in the conversation
      toggle_input_output = '<C-n>',       -- Toggle between input and output windows
    }
  },
  ui = {
    window_width = 0.35,                   -- Width as percentage of editor width
    input_height = 0.15,                   -- Input height as percentage of window height
    fullscreen = false                     -- Start in fullscreen mode (default: false)
  }
})
```

### Available Actions

| Action | Default keymap | Command | API Function |
|-------------|--------|---------|---------|
| Open input window (current session) | `<leader>gi` | `:GooseOpenInput` | `require('goose.api').open_input()` |
| Open input window (new session) | `<leader>gI` | `:GooseOpenInputNewSession` | `require('goose.api').open_input_new_session()` |
| Open output window | `<leader>go` | `:GooseOpenOutput` | `require('goose.api').open_output()` |
| Close UI windows | `<leader>gq` (global), `<ESC>` (in window) | `:GooseClose` | `require('goose.api').close()` |
| Stop running job | `<C-c>` (in window) | `:GooseStop` | `require('goose.api').stop()` |
| Toggle fullscreen mode | `<leader>gf` | `:GooseToggleFullscreen` | `require('goose.api').toggle_fullscreen()` |
| Resume session with history | `<leader>gr` | `:GooseResumeSession` | `require('goose.api').resume_session()` |
| Toggle between code and goose UI | `<leader>gt` | `:GooseToggleCodeUI` | `require('goose.api').toggle_code_ui()` |
| Run prompt (continue session) | - | `:GooseRun <prompt>` | `require('goose.api').run("prompt")` |
| Run prompt (new session) | - | `:GooseRunNewSession <prompt>` | `require('goose.api').run_new_session("prompt")` |
| Navigate to next message | `]]` | - | - |
| Navigate to previous message | `[[` | - | - |
| Toggle between input and output windows | `<C-n>` | - | - |

### Window Navigation

- Use `<leader>gt` to quickly switch between your code and the Goose UI
- Use `<C-n>` to toggle between the input and output windows within Goose
- After a Goose response completes, the cursor automatically moves to the input window if you were in the output window


