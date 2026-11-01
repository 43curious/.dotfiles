-- Run from the dotfiles root: nvim --headless -u NONE -l nvim/.config/nvim/tests/mist_index.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)

local vault = vim.fn.tempname()
local ok, err = pcall(function()
  local config = require("mist.config")
  config.defaults.vault = vault
  dofile(root .. "/plugin/mist.lua")
  vim.api.nvim_exec_autocmds("VimEnter", {})
  assert(not vim.uv.fs_stat(vault), "Startup must not scan or create the notes vault")

  vim.fn.mkdir(vault, "p")
  local inbox = vault .. "/inbox.md"
  local project = vault .. "/project.md"
  local today = config.today()
  vim.fn.writefile({ "- [ ] Inbox task @due(" .. today .. ")" }, inbox)
  vim.fn.writefile({ "- [ ] Project task @due(2000-01-01)" }, project)

  local fresh_index = dofile(root .. "/lua/mist/index.lua")
  fresh_index.update_file(inbox)
  assert(#fresh_index.tasks() == 2, "Saving before the first query must still index other notes")

  -- The first agenda must show tasks even though startup did not build the index.
  vim.cmd.MistAgenda()
  local agenda = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(agenda:find("Inbox task", 1, true), "First agenda must index the inbox")
  assert(agenda:find("Project task", 1, true), "First agenda must index other notes")

  local index = require("mist.index")
  assert(#index.tasks() == 2, "Repeated reads must not duplicate tasks")
  assert(#index.file_tasks(inbox) == 1, "File queries must use the index")
  local counts = index.counts(today)
  assert(counts.inbox == 1 and counts.today == 1 and counts.overdue == 1, "Task counts must be complete")

  vim.fn.writefile({ "- [x] Inbox task @due(" .. today .. ")" }, inbox)
  index.update_file(inbox)
  counts = index.counts(today)
  assert(counts.inbox == 0 and counts.today == 0 and counts.overdue == 1, "Updates must preserve other notes")
  assert(#index.query(function(task)
    return task.state == "todo"
  end) == 1, "Queries must reflect updated tasks")

  vim.fn.delete(project)
  index.build_lua()
  assert(#index.tasks() == 1, "An explicit rebuild must remove deleted notes")
end)
vim.fn.delete(vault, "rf")
if not ok then
  error(err)
end
print("Mist: lazy indexing, agenda, queries, updates and rebuild passed")
