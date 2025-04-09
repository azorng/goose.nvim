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

## 📋 Requirements

- Goose CLI installed and available in your PATH

## ⚡ Compatibility

This plugin is compatible with Goose CLI version 1.0.17. 
Future versions may work but are not guaranteed. If you encounter issues with newer Goose CLI versions, please report them in the issues section.

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
    branch = 'main',
    config = function()
        require('goose').setup({
            -- Optional custom configuration
            keymap = {
                prompt = '<leader>gi',
                prompt_new_session = '<leader>gI',
                focus_output = '<leader>go',
                submit_prompt = '<cr>',
                close = '<leader>gc',
                stop = '<leader>gs'
            },
            ui = {
                window_width = 0.35, -- Width of the UI windows as decimal (0.3 = 30%)
                input_height = 0.15 -- Height of the input window as decimal (0.2 = 20%)
            }
        })
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