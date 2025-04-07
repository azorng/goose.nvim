# 🪿 goose.nvim

> A minimal and customizable Neovim plugin for Goose CLI integration.

<div align="center">

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![GitHub stars](https://img.shields.io/github/stars/azorng/goose.nvim?style=for-the-badge)](https://github.com/azorng/goose.nvim/stargazers)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

</div>

## ⚠️ Early Development Stage

**Note:** This plugin is in the early stages of development. Expect significant changes and improvements as the project evolves.

## ✨ Description

This Neovim plugin provides a simple bridge between Neovim and the Goose AI agent CLI. It runs Goose commands with appropriate context from the editor, bringing AI assistant capabilities directly into Neovim similar to what tools like Cursor AI offer. Work with a powerful AI agent without leaving your editor.

## 🗺️ Roadmap

The following features are planned for future releases:

- **Custom UI**: A more intuitive and visually appealing interface
- **Session management and history**: Better handling of conversation sessions and historical interactions
- **Enhanced context provision**: Easier methods to provide file context and code references

## 📋 Requirements

- Goose CLI installed and available in your PATH

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

## ⌨️ Default Keymaps

- `<leader>gi` (normal/visual mode): Open Goose input window continuing previous session
- `<leader>gI` (normal/visual mode): Open Goose input window starting a new session
- `<CR>` (in input window): Submit prompt to Goose

## 🚀 Installation & Configuration

### With lazy.nvim

```lua
{
  'azorng/goose.nvim',
  config = function()
    require('goose').setup({
      -- Optional custom configuration
      keymap = {
        focus_input = '<leader>gi',           -- Focus input window (continue session)
        focus_input_new_session = '<leader>gI', -- Focus input window (new session)
        submit = '<CR>'                        -- Submit prompt
      },
      ui = {
        window_width = 0.3,                   -- Width of the UI windows as decimal (0.3 = 30%)
        input_height = 0.2                    -- Height of the input window as decimal (0.2 = 20%)
      }
    })
  end
}
```