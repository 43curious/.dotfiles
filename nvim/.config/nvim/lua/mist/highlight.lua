local M = {}

local groups = {
  MistHeading1 = { fg = "#e8e3d8", bold = true },
  MistHeading2 = { fg = "#c4bfb4" },
  MistHeading3 = { fg = "#9a9590", italic = true },
  MistTodoPending = { fg = "#7ab8d9" },
  MistTodoDone = { fg = "#4a4a4a", strikethrough = true },
  MistTodoCancelled = { fg = "#3a3a3a", italic = true },
  MistDueToday = { fg = "#e8a87c", bold = true },
  MistDueOverdue = { fg = "#d45f5f", bold = true },
  MistDueFuture = { fg = "#6a6a6a" },
  MistTag = { fg = "#5a7a5a", italic = true },
  MistMetaTag = { fg = "#3a4a3a" },
  MistAgendaSection = { fg = "#c4bfb4", bold = true, underline = true },
  MistAgendaDate = { fg = "#6a6a6a" },
  MistCaptureFloat = { bg = "#141414" },
}

function M.setup()
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

return M
