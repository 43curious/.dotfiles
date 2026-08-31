-- Disable spell checking in Markdown to remove red squiggly underlines.
vim.opt_local.spell = false

local config = require("mist.config")
if not config.is_vault_markdown(vim.api.nvim_buf_get_name(0)) then
  return
end

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.require'mist.fold'.expr(v:lnum)"
vim.wo.foldlevel = 99

if config.get().conceal.metadata then
  require("mist.metadata").apply(0)
end
