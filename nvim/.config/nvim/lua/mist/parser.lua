local M = {}

local state_map = {
  [" "] = "todo",
  x = "done",
  X = "done",
  ["-"] = "cancelled",
}

local function strip_meta(text)
  return (text:gsub("%s*@[%w_%-]+%([^)]*%)", ""))
end

local function extract_meta(text, key)
  return text:match("@" .. key .. "%(([^)]*)%)")
end

local function extract_tags(text)
  local tags = {}
  for tag in text:gmatch("#([%w_][%w_%-/]*)") do
    table.insert(tags, tag)
  end
  return tags
end

local function project_from_file(file, vault)
  local rel = file
  if vault and vim.startswith(file, vault .. "/") then
    rel = file:sub(#vault + 2)
  end
  local dir, base = rel:match("^(.-)/?([^/]*)$")
  base = (base or rel):gsub("%.md$", "")
  if dir and dir ~= "" and dir ~= "." then
    if dir:match("^projects/") then
      return base
    end
    return dir:match("([^/]+)$") or base
  end
  if base ~= "inbox" then
    return base
  end
end

function M.parse_lines(lines, file, vault)
  local tasks = {}
  for lnum, line in ipairs(lines) do
    local mark, body = line:match("^%s*%- %[([xX%- ])%] (.+)$")
    if mark then
      local text = vim.trim(strip_meta(body))
      table.insert(tasks, {
        text = text,
        state = state_map[mark] or "todo",
        file = file,
        line = lnum,
        due = extract_meta(body, "due"),
        priority = extract_meta(body, "priority"),
        captured = extract_meta(body, "captured"),
        tags = extract_tags(body),
        project = project_from_file(file, vault),
      })
    end
  end
  return tasks
end

function M.parse_file(file, vault)
  if vim.fn.filereadable(file) == 0 then
    return {}
  end
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return {}
  end
  return M.parse_lines(lines, vim.fs.normalize(file), vault)
end

function M.is_task_line(line)
  return line:match("^%s*%- %[([xX%- ])%] .+$") ~= nil
end

function M.toggle_task_line(line, state)
  local mark = state == "cancelled" and "-" or (state == "done" and "x" or " ")
  return (line:gsub("^(%s*%- %[)[xX%- ](%] .+)$", "%1" .. mark .. "%2"))
end

function M.replace_state_at(file, lnum, state)
  local lines = vim.fn.readfile(file)
  if not lines[lnum] then
    return false
  end
  lines[lnum] = M.toggle_task_line(lines[lnum], state)
  vim.fn.writefile(lines, file)
  return true
end

function M.set_due_at(file, lnum, date)
  local lines = vim.fn.readfile(file)
  local line = lines[lnum]
  if not line then
    return false
  end
  if line:find("@due%([^)]*%)") then
    line = line:gsub("@due%([^)]*%)", "@due(" .. date .. ")")
  else
    line = line .. " @due(" .. date .. ")"
  end
  lines[lnum] = line
  vim.fn.writefile(lines, file)
  return true
end

return M
