vim.bo.buflisted = false
vim.bo.buftype = "nofile"
vim.bo.swapfile = false
vim.bo.modifiable = true
vim.wo.wrap = false
vim.wo.number = false
vim.wo.relativenumber = false
vim.api.nvim_create_autocmd("BufWriteCmd", {
  buffer = 0,
  callback = function()
    require("mist.files").apply_edits()
  end,
})
require("mist.keymap").setup_files(0)
