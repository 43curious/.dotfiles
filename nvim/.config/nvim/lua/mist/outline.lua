local buffers = require("mist.buffers")
local config = require("mist.config")

local M = {}
local state = { source = nil, line_map = {} }

local function headings(bufnr)
  local out = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local marks, title = line:match("^(#+)%s+(.+)$")
    if marks then
      table.insert(out, { level = #marks, title = title, line = i })
    end
  end
  return out
end

function M.render()
  local bufnr = buffers.bufnr("outline")
  if not bufnr or not state.source or not vim.api.nvim_buf_is_valid(state.source) then
    return
  end
  state.line_map = {}
  local lines = { "OUTLINE", "──────────────────────────────" }
  for _, h in ipairs(headings(state.source)) do
    local indent = string.rep("  ", math.max(h.level - 1, 0))
    table.insert(lines, indent .. h.title)
    state.line_map[#lines] = h.line
  end
  buffers.set_lines(bufnr, lines, false)
  vim.bo[bufnr].filetype = "mist_outline"
end

function M.toggle(opts)
  opts = opts or {}
  state.source = opts.source or vim.api.nvim_get_current_buf()
  local bufnr = buffers.toggle("outline", { width = config.get().outline.split_width })
  if bufnr then
    M.render()
  end
end

function M.jump()
  local lnum = state.line_map[vim.api.nvim_win_get_cursor(0)[1]]
  if not lnum or not state.source or not vim.api.nvim_buf_is_valid(state.source) then
    return
  end
  local src_win
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == state.source then
      src_win = win
      break
    end
  end
  if src_win then
    vim.api.nvim_set_current_win(src_win)
  else
    vim.api.nvim_win_set_buf(0, state.source)
  end
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
end

function M.close()
  buffers.close_if_visible("outline")
end

function M.next_heading(dir)
  dir = dir or 1
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local i = cur + dir
  while i >= 1 and i <= #lines do
    if lines[i]:match("^#+%s+") then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
    i = i + dir
  end
end

function M.insert_heading()
  vim.api.nvim_put({ "# New heading" }, "l", true, true)
end

return M
