local M = {}

local kinds = {
  agenda = { name = "mist-agenda", filetype = "mist_agenda", width_key = "agenda" },
  outline = { name = "mist-outline", filetype = "mist_outline", width_key = "outline" },
  files = { name = "mist-files", filetype = "mist_files", width_key = "agenda" },
}

local state = {}

function M.kind(kind)
  return assert(kinds[kind], "unknown Mist buffer kind: " .. tostring(kind))
end

function M.find_window(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end
end

local function hide_buffer_in_window(win, bufnr)
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(win, true)
    return
  end

  -- If this is the only window, do not create/close splits. Replace the Mist
  -- surface with the alternate buffer, or an empty buffer if there is none.
  if vim.api.nvim_get_current_win() ~= win then
    vim.api.nvim_set_current_win(win)
  end
  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= bufnr and vim.api.nvim_buf_is_valid(alt) then
    vim.api.nvim_win_set_buf(win, alt)
  else
    vim.cmd.enew()
  end
end

function M.close_if_visible(kind)
  local bufnr = state[kind]
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local win = M.find_window(bufnr)
  if win then
    hide_buffer_in_window(win, bufnr)
    return true
  end
  return false
end

function M.create_scratch(listed, scratch)
  return vim.api.nvim_create_buf(listed == true, scratch ~= false)
end

function M.get(kind)
  local info = M.kind(kind)
  local bufnr = state[kind]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  end
  bufnr = M.create_scratch(false, true)
  state[kind] = bufnr
  vim.api.nvim_buf_set_name(bufnr, info.name)
  vim.bo[bufnr].filetype = info.filetype
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  return bufnr
end

function M.open_current(kind)
  local bufnr = M.get(kind)
  vim.api.nvim_win_set_buf(0, bufnr)
  return bufnr, vim.api.nvim_get_current_win()
end

function M.open_right(kind, width)
  -- Kept for callers/users that explicitly want a split, but Mist surfaces use
  -- open_current() by default.
  local bufnr = M.get(kind)
  vim.cmd("botright vertical split")
  vim.api.nvim_win_set_buf(0, bufnr)
  if width then
    vim.api.nvim_win_set_width(0, width)
  end
  return bufnr, vim.api.nvim_get_current_win()
end

function M.toggle(kind, _opts)
  if M.close_if_visible(kind) then
    return nil
  end
  return M.open_current(kind)
end

function M.set_lines(bufnr, lines, modifiable)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].modifiable = modifiable == true
end

function M.wipe(kind)
  local bufnr = state[kind]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
  state[kind] = nil
end

function M.bufnr(kind)
  local bufnr = state[kind]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  end
end

return M
