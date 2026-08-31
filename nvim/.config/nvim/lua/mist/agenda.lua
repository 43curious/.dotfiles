local buffers = require("mist.buffers")
local config = require("mist.config")
local index = require("mist.index")
local parser = require("mist.parser")
local query = require("mist.query")

local M = {}
local state = { group = "today", filter = nil, line_tasks = {} }

local function weekday_line()
  return os.date("%A %-d %B %Y")
end

local function icon(task)
  local icons = config.get().icons
  if task.state == "done" then
    return icons.done
  elseif task.state == "cancelled" then
    return icons.cancelled
  end
  return icons.todo
end

local function due_short(due)
  if not due then
    return ""
  end
  local y, m, d = due:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  if not y then
    return due
  end
  return os.date("%b %-d", os.time({ year = y, month = m, day = d }))
end

function M.render()
  local bufnr = buffers.bufnr("agenda")
  if not bufnr then
    return
  end
  state.line_tasks = {}
  local tasks = query.filter(index.tasks(), { hide_done = false, query = state.filter })
  local order, groups = query.group(tasks, state.group)
  local lines = { "AGENDA", "──────────────────────────────────────────", "Today — " .. weekday_line(), "" }

  for _, name in ipairs(order) do
    table.insert(lines, name)
    for _, task in ipairs(groups[name]) do
      local project = task.project or ""
      local due = due_short(task.due)
      local line = ("  %s  %-28s %-12s %s"):format(icon(task), task.text, project, due)
      table.insert(lines, line)
      state.line_tasks[#lines] = task
    end
    table.insert(lines, "")
  end
  table.insert(lines, "──────────────────────────────────────────")
  if state.filter and state.filter ~= "" then
    table.insert(lines, "filter: " .. state.filter)
  end

  buffers.set_lines(bufnr, lines, false)
  vim.bo[bufnr].filetype = "mist_agenda"
  M.highlight(bufnr)
end

function M.highlight(bufnr)
  local ns = vim.api.nvim_create_namespace("mist_agenda_hl")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:match("^%S") and not line:match("^[─filter]") then
      vim.api.nvim_buf_add_highlight(bufnr, ns, "MistAgendaSection", i - 1, 0, -1)
    end
    local task = state.line_tasks[i]
    if task then
      local group = task.state == "done" and "MistTodoDone" or (task.state == "cancelled" and "MistTodoCancelled" or "MistTodoPending")
      vim.api.nvim_buf_add_highlight(bufnr, ns, group, i - 1, 0, -1)
      if task.due == config.today() then
        vim.api.nvim_buf_add_highlight(bufnr, ns, "MistDueToday", i - 1, 45, -1)
      elseif task.due and task.due < config.today() then
        vim.api.nvim_buf_add_highlight(bufnr, ns, "MistDueOverdue", i - 1, 45, -1)
      elseif task.due then
        vim.api.nvim_buf_add_highlight(bufnr, ns, "MistDueFuture", i - 1, 45, -1)
      end
    end
  end
end

function M.toggle(opts)
  opts = opts or {}
  if opts.filter ~= nil then
    state.filter = opts.filter
  end
  local bufnr = buffers.toggle("agenda", { width = config.get().agenda.split_width })
  if bufnr then
    M.render()
  end
end

function M.filter(q)
  state.filter = q or ""
  local bufnr = buffers.bufnr("agenda")
  if not bufnr or not buffers.find_window(bufnr) then
    bufnr = buffers.open_current("agenda")
  end
  M.render()
end

function M.rerender_if_open()
  if buffers.bufnr("agenda") then
    M.render()
  end
end

function M.current_task()
  return state.line_tasks[vim.api.nvim_win_get_cursor(0)[1]]
end

function M.jump()
  local task = M.current_task()
  if not task then
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(task.file))
  vim.api.nvim_win_set_cursor(0, { task.line, 0 })
end

local function write_state(task, new_state)
  if parser.replace_state_at(task.file, task.line, new_state) then
    index.update_file(task.file)
    M.render()
  end
end

function M.toggle_done()
  local task = M.current_task()
  if task then
    write_state(task, task.state == "done" and "todo" or "done")
  end
end

function M.cancel()
  local task = M.current_task()
  if task then
    write_state(task, "cancelled")
  end
end

function M.schedule()
  local task = M.current_task()
  if not task then
    return
  end
  vim.ui.input({ prompt = "Due date: ", default = task.due or config.today() }, function(date)
    if date and date ~= "" and parser.set_due_at(task.file, task.line, date) then
      index.update_file(task.file)
      M.render()
    end
  end)
end

function M.set_group(group)
  state.group = group
  M.render()
end

function M.prompt_filter()
  vim.ui.input({ prompt = "Filter: ", default = state.filter or "" }, function(q)
    if q ~= nil then
      state.filter = q
      M.render()
    end
  end)
end

function M.refresh()
  index.build(function()
    M.render()
  end)
end

function M.close()
  buffers.close_if_visible("agenda")
end

return M
