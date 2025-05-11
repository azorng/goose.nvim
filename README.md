# 🪿 goose.nvim

> seamless neovim integration with goose - work with a powerful AI agent without leaving your editor

<div align="center">

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![GitHub stars](https://img.shields.io/github/stars/azorng/goose.nvim?style=for-the-badge)](https://github.com/azorng/goose.nvim/stargazers)
![Last Commit](https://img.shields.io/github/last-commit/azorng/goose.nvim?style=for-the-badge)

</div>

## ✨ Description

This plugin provides a bridge between neovim and the [goose](https://github.com/block/goose) AI agent, creating a chat interface while capturing editor context (current file, selections) to enhance your prompts. It maintains persistent sessions tied to your workspace, allowing for continuous conversations with the AI assistant similar to what tools like Cursor AI offer.

<div align="center">
  <img src="https://i.imgur.com/2dkDllr.png" alt="Goose.nvim interface" width="90%" />
</div>

## 📑 Table of Contents

- [Requirements](#-requirements)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Usage](#-usage)
- [Context](#-context)
- [Setting up goose](#-setting-up-goose)

## 📋 Requirements

- Goose CLI installed and available (see [Setting up goose](#-setting-up-goose) below)

## 🚀 Installation

Install the plugin with your favorite package manager. See the [Configuration](#️-configuration) section below for customization options.

### With lazy.nvim

```lua
{
  "azorng/goose.nvim",
  version = "*",
  config = function()
    require("goose").setup({})
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

## ⚙️ Configuration

```lua
-- Default configuration with all available options
require('goose').setup({
  keymap = {
    global = {
      toggle = '<leader>gg',                 -- Open goose. Close if opened 
      open_input = '<leader>gi',             -- Opens and focuses on input window on insert mode
      open_input_new_session = '<leader>gI', -- Opens and focuses on input window on insert mode. Creates a new session
      open_output = '<leader>go',            -- Opens and focuses on output window 
      toggle_focus = '<leader>gt',           -- Toggle focus between goose and last window
      close = '<leader>gq',                  -- Close UI windows
      toggle_fullscreen = '<leader>gf',      -- Toggle between normal and fullscreen mode
      select_session = '<leader>gs',         -- Select and load a goose session
      goose_mode_chat = '<leader>gmc',       -- Set goose mode to `chat`. (Tool calling disabled. No editor context besides selections)
      goose_mode_auto = '<leader>gma'        -- Set goose mode to `auto`. (Default mode with full agent capabilities)

      diff = {
        open = '<leader>gd',                 -- Opens a diff tab of a modified file since the last goose prompt
        next = '<leader>g]',                 -- Navigate to next file diff
        prev = '<leader>g[',                 -- Navigate to previous file diff
        close = '<leader>gc',                -- Close diff view tab and return to normal editing
        revert_all = '<leader>gra',          -- Revert all file changes since the last goose prompt
        revert_this = '<leader>grt',         -- Revert current file changes since the last goose prompt
      }
    },
    window = {
      submit = '<cr>',                     -- Submit prompt
      close = '<esc>',                     -- Close UI windows
      stop = '<C-c>',                      -- Stop goose while it is running
      next_message = ']]',                 -- Navigate to next message in the conversation
      prev_message = '[[',                 -- Navigate to previous message in the conversation
      mention_file = '@',                  -- Pick a file and add to context. See File Mentions section
      toggle_pane = '<tab>'                -- Toggle between input and output panes
    }
  },
  ui = {
    window_width = 0.35,                   -- Width as percentage of editor width
    input_height = 0.15,                   -- Input height as percentage of window height
    fullscreen = false,                    -- Start in fullscreen mode (default: false)
    layout = "right",                      -- Options: "center" or "right"
    floating_height = 0.8,                 -- Height as percentage of editor height for "center" layout
    display_model = true,                  -- Display model name on top winbar
    display_goose_mode = true              -- Display mode on top winbar: auto|chat
  }
})
```

## 🧰 Usage

### Available Actions

The plugin provides the following actions that can be triggered via keymaps, commands, or the Lua API:

| Action | Default keymap | Command | API Function |
|-------------|--------|---------|---------|
|  Open goose. Close if opened | `<leader>gg` | `:Goose` | `require('goose.api').toggle()` |
| Open input window (current session) | `<leader>gi` | `:GooseOpenInput` | `require('goose.api').open_input()` |
| Open input window (new session) | `<leader>gI` | `:GooseOpenInputNewSession` | `require('goose.api').open_input_new_session()` |
| Open output window | `<leader>go` | `:GooseOpenOutput` | `require('goose.api').open_output()` |
|  Toggle focus goose / last window | `<leader>gt` | `:GooseToggleFocus` | `require('goose.api').toggle_focus()` |
| Close UI windows | `<leader>gq` | `:GooseClose` | `require('goose.api').close()` |
| Toggle fullscreen mode | `<leader>gf` | `:GooseToggleFullscreen` | `require('goose.api').toggle_fullscreen()` |
| Select and load session | `<leader>gs` | `:GooseSelectSession` | `require('goose.api').select_session()` |
| Stop goose while it is running | `<C-c>`  | `:GooseStop` | `require('goose.api').stop()` |
| [Pick a file and add to context](#file-mentions) | `@` |- | -|
| Run prompt (continue session) | - | `:GooseRun <prompt>` | `require('goose.api').run("prompt")` |
| Run prompt (new session) | - | `:GooseRunNewSession <prompt>` | `require('goose.api').run_new_session("prompt")` |
| Navigate to next message | `]]` | - | - |
| Navigate to previous message | `[[` | - | - |
| Toggle input/output panes | `<tab>` | - | - |
| Open diff view of changes | `<leader>gd` | `:GooseDiff` | `require('goose.api').diff()` |
| Navigate to next file diff | `<leader>g]` | `:GooseDiffNext` | `require('goose.api').next_diff()` |
| Navigate to previous file diff | `<leader>g[` | `:GooseDiffPrev` | `require('goose.api').prev_diff()` |
| Close diff view tab | `<leader>gc` | `:GooseDiffClose` | `require('goose.api').close_diff()` |
| Revert all file changes | `<leader>gra` | `:GooseRevertAll` | `require('goose.api').revert_all()` |
| Revert current file changes | `<leader>grt` | `:GooseRevertThis` | `require('goose.api').revert_this()` |

## 📝 Context

The following editor context is automatically captured and included in your conversations.

| Context Type | Description |
|-------------|-------------|
| Current file | Path to the focused file before entering goose |
| Selected text | Text and lines currently selected in visual mode |
| Mentioned files | File info added through [mentions](#file-mentions) |

<a id="file-mentions"></a>
### Adding more files to context through file mentions

You can reference files in your project directly in your conversations with Goose. This is useful when you want to ask about or provide context about specific files. Type `@` in the input window to trigger the file picker. 
Supported pickers include [`fzf-lua`](https://github.com/ibhagwan/fzf-lua), [`telescope`](https://github.com/nvim-telescope/telescope.nvim), [`mini.pick`](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md), [`snacks`](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md)

## 🔧 Setting up goose 

If you're new to goose:

1. **What is Goose?** 
   - Goose is an AI agent developed by Block (the company behind Square, Cash App...)
   - It offers powerful AI assistance with extensible configurations such as LLMs and MCP servers 

2. **Installation:**
   - Visit [Install Goose](https://block.github.io/goose/docs/getting-started/installation/) for installation and configuration instructions
   - Ensure the `goose` command is available after installation

3. **Configuration:**
   - Run `goose configure` to set up your LLM provider (**Claude 3.7 Sonnet is recommended**)

