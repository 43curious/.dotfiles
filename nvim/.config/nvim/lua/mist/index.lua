local config = require("mist.config")
local parser = require("mist.parser")

local M = {}
local tasks_by_file = {}
local all_tasks = {}
local augroup = nil

local function rebuild_flat()
  all_tasks = {}
  for _, tasks in pairs(tasks_by_file) do
    for _, task in ipairs(tasks) do
      table.insert(all_tasks, task)
    end
  end
end

local function scan_files()
  local files = {}
  local vault = config.vault()
  if vim.fn.isdirectory(vault) == 0 then
    vim.fn.mkdir(vault, "p")
  end
  local function walk(dir)
    for name, typ in vim.fs.dir(dir) do
      local path = vim.fs.normalize(dir .. "/" .. name)
      if typ == "directory" then
        walk(path)
      elseif typ == "file" and name:match("%.md$") then
        table.insert(files, path)
      end
    end
  end
  walk(vault)
  table.sort(files)
  return files
end

local function decode_ndjson(lines)
  local by_file = {}
  for _, line in ipairs(lines) do
    if line ~= "" then
      local ok, obj = pcall(vim.json.decode, line)
      if ok and obj and obj.file then
        by_file[obj.file] = by_file[obj.file] or {}
        table.insert(by_file[obj.file], obj)
      end
    end
  end
  return by_file
end

function M.build_with_backend(done)
  if vim.fn.executable("mist-index") ~= 1 then
    return false
  end
  local out = {}
  vim.fn.jobstart({ "mist-index", config.vault() }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(out, data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        tasks_by_file = decode_ndjson(out)
        rebuild_flat()
      else
        M.build_lua()
      end
      if done then
        done()
      end
    end,
  })
  return true
end

function M.build_lua()
  tasks_by_file = {}
  for _, file in ipairs(scan_files()) do
    tasks_by_file[file] = parser.parse_file(file, config.vault())
  end
  rebuild_flat()
end

function M.build(done)
  if not M.build_with_backend(done) then
    M.build_lua()
    if done then
      done()
    end
  end
end

function M.update_file(file)
  file = vim.fs.normalize(vim.fn.expand(file))
  if not config.is_vault_markdown(file) then
    return
  end
  tasks_by_file[file] = parser.parse_file(file, config.vault())
  rebuild_flat()
end

function M.tasks()
  return vim.deepcopy(all_tasks)
end

function M.file_tasks(file)
  file = vim.fs.normalize(file)
  return vim.deepcopy(tasks_by_file[file] or {})
end

function M.query(fn)
  local out = {}
  for _, task in ipairs(all_tasks) do
    if not fn or fn(task) then
      table.insert(out, vim.deepcopy(task))
    end
  end
  return out
end

function M.counts(today)
  today = today or config.today()
  local counts = { inbox = 0, today = 0, overdue = 0 }
  local inbox = config.inbox_path()
  for _, task in ipairs(all_tasks) do
    if task.state == "todo" then
      if task.file == inbox then
        counts.inbox = counts.inbox + 1
      end
      if task.due == today then
        counts.today = counts.today + 1
      elseif task.due and task.due < today then
        counts.overdue = counts.overdue + 1
      end
    end
  end
  return counts
end

function M.setup()
  if augroup then
    return
  end
  augroup = vim.api.nvim_create_augroup("mist_index", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = "*.md",
    callback = function(args)
      M.update_file(args.file)
      pcall(require("mist.agenda").rerender_if_open)
    end,
  })
end

return M
