local buffers = require("mist.buffers")
local config = require("mist.config")
local index = require("mist.index")

local M = {}

local function route(input)
  local text = vim.trim(input)
  local file = config.inbox_path()
  local extra = ""

  if text:sub(1, 1) == "!" then
    text = vim.trim(text:sub(2))
    extra = " @priority(high)"
  else
    local project, rest = text:match("^/%s*([%w_%-]+)%s+(.+)$")
    if project then
      file = config.path("projects", project .. ".md")
      text = rest
    else
      local tag, tagged = text:match("^#([%w_%-/]+)%s+(.+)$")
      if tag then
        text = tagged .. " #" .. tag
      end
    end
  end

  return file, text, extra
end

local function append_capture(input)
  local file, text, extra = route(input)
  if text == "" then
    return
  end
  config.ensure_parent(file)
  local line = "- [ ] " .. text .. extra .. " @captured(" .. config.now_iso() .. ")"
  local lines = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {}
  table.insert(lines, line)
  vim.fn.writefile(lines, file)
  index.update_file(file)
end

function M.open()
  local width = config.get().capture.width
  local height = 1
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local bufnr = buffers.create_scratch(false, true)
  vim.bo[bufnr].buftype = "prompt"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "mist_capture"
  vim.fn.prompt_setprompt(bufnr, "")
  local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })
  vim.wo[win].winhighlight = "Normal:MistCaptureFloat,FloatBorder:MistCaptureFloat"
  vim.cmd.startinsert()

  local function submit()
    local line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
    append_capture(line)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set({ "i", "n" }, "<CR>", submit, { buffer = bufnr, nowait = true })
  vim.keymap.set({ "i", "n" }, "<Esc>", close, { buffer = bufnr, nowait = true })
end

return M
