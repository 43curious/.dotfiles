local M = {}

local function current_dir()
  -- netrw does not always change Neovim's cwd when you browse around.
  -- It stores the directory you're currently viewing in b:netrw_curdir.
  if vim.b.netrw_curdir and vim.b.netrw_curdir ~= "" then
    return vim.b.netrw_curdir
  end

  local name = vim.api.nvim_buf_get_name(0)

  if name ~= "" then
    local stat = vim.uv.fs_stat(name)
    if stat and stat.type == "directory" then
      return name
    end
    if stat and stat.type == "file" then
      return vim.fn.fnamemodify(name, ":h")
    end
  end

  return vim.fn.getcwd(-1, -1)
end

local function current_dir_path()
  local dir = vim.fn.fnamemodify(current_dir(), ":~")
  dir = dir:gsub("/$", "")
  return vim.fn.fnameescape(dir)
end

local function start_cmdline(command)
  vim.fn.feedkeys(":" .. command .. " " .. current_dir_path(), "n")
end

function M.edit_from_cwd()
  start_cmdline("edit")
end

function M.explore_from_cwd()
  start_cmdline("Explore")
end

function M.open_dir(path)
  vim.cmd.edit(vim.fn.fnameescape(path or vim.fn.getcwd(-1, -1)))
end

function M.cmdline_backspace()
  local line = vim.fn.getcmdline()
  local is_path_command = line:match("^%s*e%d*i?t?%s+")
    or line:match("^%s*edit%s+")
    or line:match("^%s*Explore%s+")
    or line:match("^%s*[svt]e%d*i?t?%s+")
    or line:match("^%s*[svt]split%s+")
    or line:match("^%s*tabedit%s+")

  if not is_path_command then
    return "<BS>"
  end

  -- Stop Backspace at the command itself, so `<leader>fe` keeps `:edit `.
  if line:match("^%s*%S+%s*$") then
    return ""
  end

  return "<C-w>"
end

function M.cmdline_select_next()
  return (vim.fn.pumvisible() == 1 or vim.fn.wildmenumode() == 1) and "<C-n>" or "<Down>"
end

function M.cmdline_select_prev()
  return (vim.fn.pumvisible() == 1 or vim.fn.wildmenumode() == 1) and "<C-p>" or "<Up>"
end

function M.setup()
  -- Make `:edit <Tab>` path completion feel like a small fuzzy-ish menu.
  vim.opt.wildmenu = true
  vim.opt.wildmode = { "longest:full", "full" }
  vim.opt.wildoptions = "pum"

  -- In path-editing commands, Backspace deletes one path component:
  -- `:edit ~/.config/nvim` -> Backspace -> `:edit ~/.config/`.
  vim.keymap.set("c", "<BS>", M.cmdline_backspace, { expr = true, desc = "Delete path component" })
  vim.keymap.set("c", "<M-BS>", "<C-w>", { desc = "Delete path component" })
  vim.keymap.set("c", "<M-Del>", "<C-w>", { desc = "Delete path component" })

  -- After pressing Tab to show path completion, use arrow keys to move through it.
  vim.keymap.set("c", "<Down>", M.cmdline_select_next, { expr = true, desc = "Next completion item" })
  vim.keymap.set("c", "<Up>", M.cmdline_select_prev, { expr = true, desc = "Previous completion item" })
end

return M
