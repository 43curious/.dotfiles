-- Keymaps are automatically loaded on the VeryLazy event
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local file_nav = require("config.file_nav")
file_nav.setup()

local compile = require("config.compile")
compile.setup()

-- Use netrw for file browsing instead of a Snacks file tree.
vim.keymap.set("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Explorer netrw" })
vim.keymap.set("n", "<leader>E", function()
  file_nav.open_dir(vim.uv.cwd())
end, { desc = "Explorer netrw (cwd)" })

-- `:e {pwd}/` style path editing with built-in command-line completion.
vim.keymap.set("n", "<leader>fe", file_nav.edit_from_cwd, { desc = "Edit path from cwd" })
vim.keymap.set("n", "<leader>fd", file_nav.explore_from_cwd, { desc = "Explore path from cwd" })

vim.keymap.set("n", "<leader>cc", "<cmd>Compile<cr>", { desc = "Emacs M-x compile" })
vim.keymap.set("n", "<leader>cg", "<cmd>Recompile<cr>", { desc = "Emacs recompile" })
