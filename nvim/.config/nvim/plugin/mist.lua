if vim.g.loaded_mist_nvim then
  return
end
vim.g.loaded_mist_nvim = 1

local mist = require("mist")
mist.setup({})

vim.api.nvim_create_user_command("MistCapture", function()
  mist.capture()
end, { desc = "Open Mist capture float" })

vim.api.nvim_create_user_command("MistAgenda", function()
  mist.agenda()
end, { desc = "Toggle Mist agenda" })

vim.api.nvim_create_user_command("MistOutline", function()
  mist.outline()
end, { desc = "Toggle Mist outline" })

vim.api.nvim_create_user_command("MistFiles", function()
  mist.files()
end, { desc = "Toggle Mist files" })

vim.api.nvim_create_user_command("MistInbox", function()
  mist.inbox()
end, { desc = "Open Mist inbox" })

vim.api.nvim_create_user_command("MistToday", function()
  mist.today()
end, { desc = "Open today's Mist note" })

vim.api.nvim_create_user_command("MistFilter", function(opts)
  mist.filter(opts.args)
end, { nargs = "*", desc = "Filter Mist agenda" })

vim.api.nvim_create_user_command("MistRefresh", function()
  mist.refresh()
end, { desc = "Refresh Mist index" })

vim.api.nvim_create_user_command("MistReveal", function()
  mist.reveal()
end, { desc = "Toggle Mist metadata conceal" })

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("mist_plugin_startup", { clear = true }),
  once = true,
  callback = function()
    require("mist.index").build()
  end,
})
