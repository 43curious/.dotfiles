vim.bo.buflisted = false
vim.bo.buftype = "nofile"
vim.bo.swapfile = false
vim.bo.modifiable = false
vim.wo.wrap = false
vim.wo.number = false
vim.wo.relativenumber = false
require("mist.keymap").setup_outline(0)
