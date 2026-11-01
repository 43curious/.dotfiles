local M = {}

local groups = {
  MistHeading1 = { fg = "#e8e3d8", ctermfg = 7, bold = true },
  MistHeading2 = { fg = "#c4bfb4", ctermfg = 7 },
  MistHeading3 = { fg = "#9a9590", ctermfg = 8, italic = true },
  MistTodoPending = { fg = "#7ab8d9", ctermfg = 6 },
  MistTodoDone = { fg = "#4a4a4a", ctermfg = 8, strikethrough = true },
  MistTodoCancelled = { fg = "#3a3a3a", ctermfg = 8, italic = true },
  MistDueToday = { fg = "#e8a87c", ctermfg = 11, bold = true },
  MistDueOverdue = { fg = "#d45f5f", ctermfg = 9, bold = true },
  MistDueFuture = { fg = "#6a6a6a", ctermfg = 8 },
  MistTag = { fg = "#5a7a5a", ctermfg = 2, italic = true },
  MistMetaTag = { fg = "#3a4a3a", ctermfg = 8 },
  MistAgendaSection = { fg = "#c4bfb4", ctermfg = 7, bold = true, underline = true },
  MistAgendaDate = { fg = "#6a6a6a", ctermfg = 8 },
  MistCaptureFloat = { bg = "#141414", ctermbg = "NONE" },
}

local function apply()
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

function M.setup()
  apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("mist_highlights", { clear = true }),
    callback = apply,
  })
end

return M
