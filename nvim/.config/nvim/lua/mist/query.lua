local config = require("mist.config")

local M = {}

local priority_rank = { high = 1, medium = 2, low = 3 }

function M.filter(tasks, opts)
  opts = opts or {}
  local q = opts.query and opts.query:lower() or nil
  local out = {}
  for _, task in ipairs(tasks) do
    local ok = true
    if opts.state and task.state ~= opts.state then
      ok = false
    end
    if opts.hide_done and task.state ~= "todo" then
      ok = false
    end
    if q and q ~= "" then
      local hay = table.concat({ task.text or "", task.project or "", task.due or "", table.concat(task.tags or {}, " ") }, " "):lower()
      ok = hay:find(q, 1, true) ~= nil
    end
    if ok then
      table.insert(out, task)
    end
  end
  return out
end

function M.sort(tasks)
  table.sort(tasks, function(a, b)
    local ad = a.due or "9999-99-99"
    local bd = b.due or "9999-99-99"
    if ad ~= bd then
      return ad < bd
    end
    local ap = priority_rank[a.priority or ""] or 9
    local bp = priority_rank[b.priority or ""] or 9
    if ap ~= bp then
      return ap < bp
    end
    if (a.project or "") ~= (b.project or "") then
      return (a.project or "") < (b.project or "")
    end
    return (a.text or "") < (b.text or "")
  end)
  return tasks
end

function M.group(tasks, mode)
  local today = config.today()
  local groups = {}
  local order = {}
  local function add(name, task)
    if not groups[name] then
      groups[name] = {}
      table.insert(order, name)
    end
    table.insert(groups[name], task)
  end

  for _, task in ipairs(tasks) do
    if mode == "project" then
      add(task.project or "Inbox", task)
    elseif mode == "due" then
      add(task.due or "No due date", task)
    else
      if task.due and task.due <= today then
        add("Today", task)
      elseif task.due then
        add("Scheduled", task)
      elseif task.file == config.inbox_path() then
        add("Inbox — unscheduled, unfiled", task)
      else
        add("Someday", task)
      end
    end
  end

  for _, name in ipairs(order) do
    M.sort(groups[name])
  end
  return order, groups
end

return M
