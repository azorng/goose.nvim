# 🪿 goose.nvim

> A minimal and customizable Neovim plugin for Goose CLI integration.

<div align="center">

![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)
[![GitHub stars](https://img.shields.io/github/stars/azorng/goose.nvim?style=for-the-badge)](https://github.com/azorng/goose.nvim/stargazers)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

</div>

## ✨ Description

This Neovim plugin provides a simple bridge between Neovim and the Goose AI agent CLI. It runs Goose commands with appropriate context from the editor.

## 📋 Requirements

- Goose CLI installed and available in your PATH

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
