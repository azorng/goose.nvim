# 🪿 goose.nvim

> seamless neovim integration with goose - work with a powerful AI agent without leaving your editor

<div align="center">

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![GitHub stars](https://img.shields.io/github/stars/azorng/goose.nvim?style=for-the-badge)](https://github.com/azorng/goose.nvim/stargazers)
![Last Commit](https://img.shields.io/github/last-commit/azorng/goose.nvim?style=for-the-badge)

</div>

## ✨ Description

This plugin provides a bridge between neovim and the [goose](https://github.com/block/goose) AI agent, creating a chat interface while capturing [editor context](#-context) to enhance your prompts. It maintains persistent sessions tied to your workspace, allowing for continuous conversations with the AI assistant similar to what tools like Cursor AI offer.

<div align="center">
  <img src="https://i.imgur.com/2dkDllr.png" alt="Goose.nvim interface" width="85%" />
</div>

## 📑 Table of Contents

- [Requirements](#-requirements)
- [Compatibility](#-compatibility)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Usage](#-usage)
- [Context](#-context)
- [Setting Up Goose CLI](#-setting-up-goose-cli)

## 📋 Requirements

- Goose CLI installed and available (see [Setting Up Goose CLI](#-setting-up-goose-cli) below)

## ⚡ Compatibility

This plugin is compatible with Goose CLI version **`1.0.17`**. 
Future versions may work but are not guaranteed. If you encounter issues with newer Goose CLI versions, please report them in the issues section.

## 🚀 Installation

Install the plugin with your favorite package manager. See the [Configuration](#-configuration) section below for customization options.

### With lazy.nvim

```lua
{
  'azorng/goose.nvim',
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
      close = '<leader>gq',                  -- Close UI windows
      toggle_fullscreen = '<leader>gf',      -- Toggle between normal and fullscreen mode
      select_session = '<leader>gs',         -- Select and load a goose session
    },
    window = {
      submit = '<cr>',                     -- Submit prompt
      close = '<esc>',                     -- Close UI windows
      stop = '<C-c>',                      -- Stop a running job
      next_message = ']]',                 -- Navigate to next message in the conversation
      prev_message = '[[',                 -- Navigate to previous message in the conversation
      mention_file = '@',                  -- Pick a file and add to context. See File Mentions section
      toggle_pane = '<C-n>'                -- Toggle between input and output panes
    }
  },
  ui = {
    window_width = 0.35,                   -- Width as percentage of editor width
    input_height = 0.15,                   -- Input height as percentage of window height
    fullscreen = false                     -- Start in fullscreen mode (default: false)
    layout = "right",                      -- Options: "center" or "right"
    floating_height = 0.8,                 -- Height as percentage of editor height for floating layout
    
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
| Close UI windows | `<leader>gq` | `:GooseClose` | `require('goose.api').close()` |
| Toggle fullscreen mode | `<leader>gf` | `:GooseToggleFullscreen` | `require('goose.api').toggle_fullscreen()` |
| Select and load session | `<leader>gs` | `:GooseSelectSession` | `require('goose.api').select_session()` |
| Stop running job | `<C-c>`  | `:GooseStop` | `require('goose.api').stop()` |
| [Pick a file and add to context](#file-mentions) | `@` |- | -|
| Run prompt (continue session) | - | `:GooseRun <prompt>` | `require('goose.api').run("prompt")` |
| Run prompt (new session) | - | `:GooseRunNewSession <prompt>` | `require('goose.api').run_new_session("prompt")` |
| Navigate to next message | `]]` | - | - |
| Navigate to previous message | `[[` | - | - |
| Toggle input/output panes | `<C-n>` | - | - |

## 📝 Context

The following editor context information is automatically captured and included in your conversations. This contextual information helps Goose understand what you're working on and provide more relevant assistance.

| Context Type | Description |
|-------------|-------------|
| Current File | Path to the file currently open in the editor |
| Selected Text | Text currently selected in visual mode |
| Selected Lines | Line numbers of the current selection (start, end) |
| Cursor Position | Current cursor position (line, column) |
| Additional Files | Other relevant files you've added to the conversation |

<a id="file-mentions"></a>
### Adding more files to context through file mentions

You can reference files in your project directly in your conversations with Goose. This is useful when you want to ask about or provide context about specific files. Type `@` in the input window to trigger the file picker. 
Supported pickers include [`fzf-lua`](https://github.com/ibhagwan/fzf-lua), [`telescope`](https://github.com/nvim-telescope/telescope.nvim), [`mini.pick`](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md), [`snacks`](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md)

## 🔧 Setting Up Goose CLI

If you're new to Goose CLI:

1. **What is Goose CLI?** 
   - Goose is an AI agent developed by Block (the company behind Square, Cash App...)
   - It offers powerful AI assistance with extensible configurations such as LLMs and MCP servers 

2. **Installation:**
   - Visit [Install Goose](https://block.github.io/goose/docs/getting-started/installation/) for installation and configuration instructions
   - Ensure the `goose` command is available after installation

3. **Configuration:**
   - Run `goose configure` to set up your LLM provider (**Claude 3.7 Sonnet is recommended**)

