local M = {}

M.defaults = {
  vault = "~/notes",
  inbox = "inbox.md",
  daily_dir = "daily",
  date_format = "%Y-%m-%d",
  capture = {
    key = ",cc",
    width = 60,
  },
  agenda = {
    groups = { "today", "scheduled", "inbox", "someday" },
    split_width = 40,
    done_visible = 24,
  },
  outline = {
    split_width = 30,
  },
  conceal = {
    metadata = true,
    completed = true,
  },
  icons = {
    todo = "□",
    done = "☑",
    cancelled = "⊘",
  },
}

M.options = vim.deepcopy(M.defaults)

local function normalize(path)
  path = vim.fn.expand(path)
  path = vim.fs.normalize(path)
  return path:gsub("/$", "")
end

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  M.options.vault = normalize(M.options.vault)
  return M.options
end

function M.get()
  if M.options.vault:sub(1, 1) == "~" then
    M.options.vault = normalize(M.options.vault)
  end
  return M.options
end

function M.vault()
  return M.get().vault
end

function M.path(...)
  local parts = { M.vault(), ... }
  return vim.fs.normalize(table.concat(parts, "/"))
end

function M.inbox_path()
  return M.path(M.get().inbox)
end

function M.daily_path(date)
  return M.path(M.get().daily_dir, date .. ".md")
end

function M.relpath(path)
  path = normalize(path)
  local vault = M.vault()
  if path == vault then
    return ""
  end
  if vim.startswith(path, vault .. "/") then
    return path:sub(#vault + 2)
  end
  return path
end

function M.is_in_vault(path)
  if not path or path == "" then
    return false
  end
  path = normalize(path)
  local vault = M.vault()
  return path == vault or vim.startswith(path, vault .. "/")
end

function M.is_vault_markdown(path)
  return M.is_in_vault(path) and path:match("%.md$") ~= nil
end

function M.ensure_parent(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
end

function M.today()
  return os.date(M.get().date_format)
end

function M.now_iso()
  return os.date("%Y-%m-%dT%H:%M")
end

return M
