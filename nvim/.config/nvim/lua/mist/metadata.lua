local M = {}
local ns = vim.api.nvim_create_namespace("mist_metadata")

function M.apply(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nc"
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local start = 1
    while true do
      local s, e = line:find("@[%w_]+%([^)]*%)", start)
      if not s then
        break
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, s - 1, {
        end_col = e,
        conceal = "",
        hl_group = "MistMetaTag",
      })
      start = e + 1
    end
  end
end

function M.toggle()
  if vim.wo.conceallevel == 0 then
    vim.wo.conceallevel = 2
    vim.wo.concealcursor = "nc"
    M.apply(0)
  else
    vim.wo.conceallevel = 0
  end
end

return M
