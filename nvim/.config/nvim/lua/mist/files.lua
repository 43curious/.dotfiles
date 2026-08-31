local buffers = require("mist.buffers")
local config = require("mist.config")
local index = require("mist.index")

local M = {}
local state = { root = nil, line_paths = {}, collapsed = {}, original = {} }

local function today_count(path)
  local n = 0
  for _, task in ipairs(index.file_tasks(path)) do
    if task.state == "todo" and task.due == config.today() then
      n = n + 1
    end
  end
  return n
end

local function list_dir(dir, depth, lines)
  local entries = {}
  for name, typ in vim.fs.dir(dir) do
    if name:sub(1, 1) ~= "." then
      table.insert(entries, { name = name, typ = typ, path = vim.fs.normalize(dir .. "/" .. name) })
    end
  end
  table.sort(entries, function(a, b)
    if a.typ ~= b.typ then
      return a.typ == "directory"
    end
    return a.name < b.name
  end)
  for _, e in ipairs(entries) do
    local prefix = string.rep("  ", depth)
    local marker = e.typ == "directory" and (state.collapsed[e.path] and "▸ " or "▾ ") or "  "
    local suffix = ""
    if e.typ == "file" and e.path:match("%.md$") then
      local count = today_count(e.path)
      if count > 0 then
        suffix = ("  [%d today]"):format(count)
      end
    end
    table.insert(lines, prefix .. marker .. e.name .. (e.typ == "directory" and "/" or "") .. suffix)
    state.line_paths[#lines] = e
    state.original[#lines] = e.name
    if e.typ == "directory" and not state.collapsed[e.path] then
      list_dir(e.path, depth + 1, lines)
    end
  end
end

function M.render(modifiable)
  local bufnr = buffers.bufnr("files")
  if not bufnr then
    return
  end
  state.line_paths = {}
  state.original = {}
  local root = state.root or config.vault()
  local lines = { "MIST FILES  " .. config.relpath(root), "──────────────────────────────" }
  list_dir(root, 0, lines)
  buffers.set_lines(bufnr, lines, modifiable == true)
  vim.bo[bufnr].filetype = "mist_files"
end

function M.toggle(opts)
  opts = opts or {}
  state.root = opts.root or state.root or config.vault()
  local bufnr = buffers.toggle("files", { width = config.get().agenda.split_width })
  if bufnr then
    M.render(true)
  end
end

function M.current()
  return state.line_paths[vim.api.nvim_win_get_cursor(0)[1]]
end

function M.open(split)
  local e = M.current()
  if not e then
    return
  end
  if e.typ == "directory" then
    state.collapsed[e.path] = not state.collapsed[e.path]
    M.render(true)
    return
  end
  if split then
    vim.cmd.split(vim.fn.fnameescape(e.path))
  else
    vim.cmd.edit(vim.fn.fnameescape(e.path))
  end
end

function M.new_file()
  vim.ui.input({ prompt = "New file: " }, function(name)
    if not name or name == "" then
      return
    end
    if not name:match("%.md$") then
      name = name .. ".md"
    end
    local path = vim.fs.normalize((state.root or config.vault()) .. "/" .. name)
    config.ensure_parent(path)
    if vim.fn.filereadable(path) == 0 then
      vim.fn.writefile({ "" }, path)
    end
    index.update_file(path)
    M.render(true)
  end)
end

function M.rename_prompt()
  local e = M.current()
  if not e then
    return
  end
  vim.ui.input({ prompt = "Rename: ", default = e.name }, function(name)
    if not name or name == "" or name == e.name then
      return
    end
    local dest = vim.fs.normalize(vim.fn.fnamemodify(e.path, ":h") .. "/" .. name)
    vim.fn.rename(e.path, dest)
    if e.typ == "file" then
      index.update_file(dest)
    end
    M.render(true)
  end)
end

function M.delete()
  local e = M.current()
  if not e then
    return
  end
  vim.ui.input({ prompt = "Delete " .. e.name .. "? type yes: " }, function(ans)
    if ans == "yes" then
      if e.typ == "directory" then
        vim.fn.delete(e.path, "rf")
      else
        vim.fn.delete(e.path)
      end
      M.render(true)
    end
  end)
end

function M.up()
  local parent = vim.fn.fnamemodify(state.root or config.vault(), ":h")
  if config.is_in_vault(parent) then
    state.root = parent
  else
    state.root = config.vault()
  end
  M.render(true)
end

function M.toggle_dir()
  local e = M.current()
  if e and e.typ == "directory" then
    state.collapsed[e.path] = not state.collapsed[e.path]
    M.render(true)
  end
end

function M.apply_edits()
  local bufnr = buffers.bufnr("files")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, e in pairs(state.line_paths) do
    local raw = lines[lnum]
    if raw and e then
      local name = raw:gsub("^%s*[▸▾ ]%s*", ""):gsub("%s+%[%d+ today%]$", ""):gsub("/$", "")
      if name ~= "" and name ~= e.name then
        local dest = vim.fs.normalize(vim.fn.fnamemodify(e.path, ":h") .. "/" .. name)
        vim.fn.rename(e.path, dest)
      end
    end
  end
  index.build()
  M.render(true)
end

function M.close()
  buffers.close_if_visible("files")
end

return M
