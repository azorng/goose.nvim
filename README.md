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

- `<leader>gp` (normal/visual mode): Run Goose command continuing previous session
- `<leader>gP` (normal/visual mode): Run Goose command starting a new session

## 🚀 Installation & Configuration

### With lazy.nvim

```lua
{
  'azorng/goose.nvim',
  config = function()
    require('goose').setup({
      -- Optional custom configuration
      keymap = {
        prompt = '<leader>gp',           -- Continue session
        prompt_new_session = '<leader>gP', -- New session
      },
      ui_width = 40,                     -- Width percentage of terminal window
    })
  end
}
```
