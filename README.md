# 🪿 goose.nvim

> seamless neovim integration with goose CLI - work with a powerful AI agent without leaving your editor

<div align="center">

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![GitHub stars](https://img.shields.io/github/stars/azorng/goose.nvim?style=for-the-badge)](https://github.com/azorng/goose.nvim/stargazers)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

</div>

## ✨ Description

This Neovim plugin provides a simple bridge between Neovim and the Goose AI agent CLI. It runs Goose commands with appropriate context from the editor, bringing AI assistant capabilities directly into Neovim similar to what tools like Cursor AI offer. Work with a powerful AI agent without leaving your editor.

## ⚠️ Early Development Stage

**Note:** This plugin is in the early stages of development. Expect significant changes and improvements as the project evolves.

## 📑 Table of Contents

- [Requirements](#-requirements)
- [Compatibility](#-compatibility)
- [Installation](#-installation)
- [Configuration](#️-configuration)
- [Usage](#-usage)
- [Setting Up Goose CLI](#-setting-up-goose-cli)

## 📋 Requirements

- Goose CLI installed and available in your PATH (see [Setting Up Goose CLI](#-setting-up-goose-cli) below)

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
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
      },
    }
  },
  config = function()
    require('goose').setup()
  end,
}
```

## ⚙️ Configuration

```lua
-- Default configuration with all available options
require('goose').setup({
  keymap = {
    open_input = '<leader>gi',            -- Open/focus input window with last session
    open_input_new_session = '<leader>gI', -- Open/focus input window with new session
    open_output = '<leader>go',           -- Open/focus output window
    submit_prompt = '<cr>',               -- Submit prompt 
    close = '<leader>gc',                 -- Close UI windows
    close_when_focused = '<esc>',         -- Close when windows are focused 
    stop = '<leader>gs'                   -- Stop running job
  },
  ui = {
    window_width = 0.35,                  -- Width as percentage of editor width
    input_height = 0.15                   -- Input height as percentage of window height
  }
})
```

## 🧰 Usage

### Available Actions

The plugin provides the following actions that can be triggered via keymaps, commands, or Lua API:

| Action | Default keymap | Command | Lua API |
|-------------|--------|---------|---------|
| Open/focus on input (last session) | `<leader>gi` | `:GooseOpenInput` | `require('goose.api').open_input()` |
| Open/focus on input (new session) | `<leader>gI` | `:GooseOpenInputNewSession` | `require('goose.api').open_input_new_session()` |
| Open/focus on output (last session) | `<leader>go` | `:GooseOpenOutput` | `require('goose.api').open_output()` |
| Close UI windows | `<leader>gc` | `:GooseClose` | `require('goose.api').close()` |
| Stop a running job | `<leader>gs` | `:GooseStop` | `require('goose.api').stop()` |
| Run Goose with prompt (continue session) | - | `:GooseRun <prompt>` | `require('goose.api').run("prompt")` |
| Run Goose with prompt (new session) | - | `:GooseRunNewSession <prompt>` | `require('goose.api').run_new_session("prompt")` |

## 🔧 Setting Up Goose CLI

If you're new to Goose CLI:

1. **What is Goose CLI?** 
   - Goose is an AI agent developed by Block (the company behind Square, Cash App, and Tidal)
   - It offers powerful AI assistance through a command-line interface

2. **Installation:**
   - Visit [Goose's official repository](https://github.com/block/goose) for installation instructions
   - Ensure the `goose` command is available in your PATH after installation

3. **Basic Configuration:**
   - Run `goose configure` to set up your provider and other configurations
   - For more configuration options, refer to the [Goose Website](https://block.github.io/goose/)

