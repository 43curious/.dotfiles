-- Options are automatically loaded before lazy.nvim startup
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Use Rex's live terminal palette instead of fixed RGB colors.
if vim.env.REX_BLOCK then
  vim.opt.termguicolors = false
end

-- Never show Neovim's tabline/bufferline.
vim.opt.showtabline = 0

-- Keep the native command line at the bottom of the screen.
vim.opt.cmdheight = 1

-- Disable spell checking globally.
vim.opt.spell = false
