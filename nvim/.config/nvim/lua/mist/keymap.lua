local config = require("mist.config")

local M = {}
local vault_aug = nil

local function map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

local function current_line_task_state()
  local line = vim.api.nvim_get_current_line()
  local mark = line:match("^(%s*%- %[)([ xX%-])(%] .+)$")
  return mark
end

function M.toggle_task_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local pre, mark, post = line:match("^(%s*%- %[)([ xX%-])(%] .+)$")
  if not pre then
    return
  end
  local next_mark = (mark == "x" or mark == "X") and " " or "x"
  vim.api.nvim_set_current_line(pre .. next_mark .. post)
end

function M.insert_task()
  vim.api.nvim_put({ "- [ ] " }, "l", true, true)
  vim.cmd.startinsert({ bang = true })
end

local function setup_vault_markdown(bufnr)
  if vim.b[bufnr].mist_vault_keymaps then
    return
  end
  vim.b[bufnr].mist_vault_keymaps = true
  map(bufnr, "n", config.get().capture.key, require("mist.capture").open, "Mist capture")
  map(bufnr, "n", ",aa", require("mist.agenda").toggle, "Mist agenda")
  map(bufnr, "n", ",oo", require("mist.outline").toggle, "Mist outline")
  map(bufnr, "n", ",ff", require("mist.files").toggle, "Mist files")
  map(bufnr, "n", ",ii", require("mist").inbox, "Mist inbox")
  map(bufnr, "n", ",gt", require("mist").today, "Mist today")
  map(bufnr, "n", "<Tab>", require("mist.fold").toggle_heading, "Mist fold/indent")
  map(bufnr, "n", "<S-Tab>", require("mist.fold").outdent_or_promote, "Mist promote/outdent")
  map(bufnr, "n", ",zz", require("mist.fold").fold_all, "Mist fold all")
  map(bufnr, "n", ",zo", require("mist.fold").unfold_all, "Mist unfold all")
  map(bufnr, "n", "<C-j>", function()
    require("mist.outline").next_heading(1)
  end, "Mist next heading")
  map(bufnr, "n", "<C-k>", function()
    require("mist.outline").next_heading(-1)
  end, "Mist previous heading")
  map(bufnr, "n", "<Space>", M.toggle_task_at_cursor, "Mist toggle task")
  map(bufnr, "n", ",it", M.insert_task, "Mist insert task")
  map(bufnr, "n", ",ih", require("mist.outline").insert_heading, "Mist insert heading")
  map(bufnr, "n", ",im", require("mist.metadata").toggle, "Mist reveal metadata")
  map(bufnr, "n", "-", function()
    require("mist.files").toggle({ root = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h") })
  end, "Mist parent files")
end

function M.setup_autocmds()
  if vault_aug then
    return
  end
  vault_aug = vim.api.nvim_create_augroup("mist_vault_keymaps", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = vault_aug,
    pattern = "*.md",
    callback = function(args)
      if config.is_vault_markdown(args.file) then
        setup_vault_markdown(args.buf)
        if config.get().conceal.metadata then
          require("mist.metadata").apply(args.buf)
        end
      end
    end,
  })
end

function M.setup_agenda(bufnr)
  map(bufnr, "n", "<CR>", require("mist.agenda").jump, "Mist jump task")
  map(bufnr, "n", "<Space>", require("mist.agenda").toggle_done, "Mist toggle done")
  map(bufnr, "n", "x", require("mist.agenda").cancel, "Mist cancel")
  map(bufnr, "n", "s", require("mist.agenda").schedule, "Mist schedule")
  map(bufnr, "n", "gt", function()
    require("mist.agenda").set_group("today")
  end, "Mist group today")
  map(bufnr, "n", "gp", function()
    require("mist.agenda").set_group("project")
  end, "Mist group project")
  map(bufnr, "n", "gd", function()
    require("mist.agenda").set_group("due")
  end, "Mist group due")
  map(bufnr, "n", "/", require("mist.agenda").prompt_filter, "Mist filter")
  map(bufnr, "n", "r", require("mist.agenda").refresh, "Mist refresh")
  map(bufnr, "n", "q", require("mist.agenda").close, "Mist close")
end

function M.setup_outline(bufnr)
  map(bufnr, "n", "<CR>", require("mist.outline").jump, "Mist jump heading")
  map(bufnr, "n", "q", require("mist.outline").close, "Mist close")
end

function M.setup_files(bufnr)
  map(bufnr, "n", "<CR>", function()
    require("mist.files").open(false)
  end, "Mist open")
  map(bufnr, "n", "o", function()
    require("mist.files").open(true)
  end, "Mist split")
  map(bufnr, "n", "n", require("mist.files").new_file, "Mist new file")
  map(bufnr, "n", "r", require("mist.files").rename_prompt, "Mist rename")
  map(bufnr, "n", "d", require("mist.files").delete, "Mist delete")
  map(bufnr, "n", "<Tab>", require("mist.files").toggle_dir, "Mist fold dir")
  map(bufnr, "n", "-", require("mist.files").up, "Mist up")
  map(bufnr, "n", "q", require("mist.files").close, "Mist close")
end

return M
