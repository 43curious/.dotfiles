local M = {}

local comp_buf_name = "*compilation*"
local current_job = nil

vim.g.emacs_last_compile_cmd = vim.g.emacs_last_compile_cmd or "zig build"

local function append_lines(buf, data)
  if not data then
    return
  end

  local lines = vim.split(data, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines, #lines)
  end
  if #lines == 0 then
    return
  end

  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
    vim.bo[buf].modifiable = false

    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
    end
  end)
end

local function get_compilation_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match(vim.pesc(comp_buf_name) .. "$") then
      return buf
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, comp_buf_name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "compilation"
  return buf
end

local function open_compilation_window(buf)
  local current_win = vim.api.nvim_get_current_win()
  local wins = vim.fn.win_findbuf(buf)

  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
  else
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_win_set_height(0, 12)
  end

  return current_win
end

local function run_compile(cmd)
  if not cmd or cmd == "" then
    return
  end

  vim.g.emacs_last_compile_cmd = cmd

  if current_job then
    current_job:kill(15)
    current_job = nil
  end

  local buf = get_compilation_buffer()
  local previous_win = open_compilation_window(buf)

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "$ " .. cmd, "" })
  vim.bo[buf].modifiable = false

  current_job = vim.system({ vim.o.shell, vim.o.shellcmdflag, cmd }, {
    text = true,
    stdout = function(_, data)
      append_lines(buf, data)
    end,
    stderr = function(_, data)
      append_lines(buf, data)
    end,
  }, function(result)
    append_lines(buf, ("\n[Process exited %d]"):format(result.code))
    current_job = nil
  end)

  if vim.api.nvim_win_is_valid(previous_win) then
    vim.api.nvim_set_current_win(previous_win)
  end
end

function M.compile()
  vim.ui.input({
    prompt = "Compile command: ",
    default = vim.g.emacs_last_compile_cmd,
    completion = "shell",
  }, run_compile)
end

function M.recompile()
  run_compile(vim.g.emacs_last_compile_cmd)
end

function M.setup()
  vim.api.nvim_create_user_command("Compile", M.compile, {})
  vim.api.nvim_create_user_command("Recompile", M.recompile, {})
end

return M
