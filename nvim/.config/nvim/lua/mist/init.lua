local M = {}

function M.setup(opts)
  local config = require("mist.config")
  config.setup(opts)
  require("mist.highlight").setup()
  require("mist.keymap").setup_autocmds()
  require("mist.index").setup()
  return M
end

local function ensure_setup()
  local config = require("mist.config")
  if config.get().vault:sub(1, 1) == "~" then
    M.setup({})
  end
end

function M.capture()
  ensure_setup()
  require("mist.capture").open()
end

function M.agenda(opts)
  ensure_setup()
  require("mist.agenda").toggle(opts)
end

function M.outline(opts)
  ensure_setup()
  require("mist.outline").toggle(opts)
end

function M.files(opts)
  ensure_setup()
  require("mist.files").toggle(opts)
end

function M.inbox()
  ensure_setup()
  local config = require("mist.config")
  config.ensure_parent(config.inbox_path())
  vim.cmd.edit(vim.fn.fnameescape(config.inbox_path()))
end

function M.today()
  ensure_setup()
  local config = require("mist.config")
  local path = config.daily_path(config.today())
  config.ensure_parent(path)
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({ "# " .. config.today(), "" }, path)
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.filter(query)
  ensure_setup()
  require("mist.agenda").filter(query or "")
end

function M.refresh()
  ensure_setup()
  require("mist.index").build()
  require("mist.agenda").rerender_if_open()
end

function M.reveal()
  ensure_setup()
  require("mist.metadata").toggle()
end

function M.statusline()
  ensure_setup()
  local index = require("mist.index")
  local today = require("mist.config").today()
  local counts = index.counts(today)
  local parts = {}
  if counts.inbox > 0 then
    table.insert(parts, ("[inbox: %d]"):format(counts.inbox))
  end
  if counts.today > 0 then
    table.insert(parts, ("[today: %d]"):format(counts.today))
  end
  if counts.overdue > 0 then
    table.insert(parts, ("[overdue: %d]"):format(counts.overdue))
  end
  return table.concat(parts, "  ")
end

return M
