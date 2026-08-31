-- Autocmds are automatically loaded on the VeryLazy event
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("disable_spellcheck", { clear = true }),
  callback = function()
    vim.opt_local.spell = false
  end,
})
