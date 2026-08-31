local M = {}

function M.expr(lnum)
  local line = vim.fn.getline(lnum)
  local marks = line:match("^(#+)%s")
  if marks then
    return ">" .. tostring(#marks)
  end
  return "="
end

function M.toggle_heading()
  local line = vim.api.nvim_get_current_line()
  if line:match("^#+%s") then
    vim.cmd.normal({ args = { "za" }, bang = true })
  elseif line:match("^%s*[-*+]%s") or line:match("^%s*%d+%.%s") then
    vim.cmd.normal({ args = { ">>" }, bang = true })
  else
    vim.cmd.normal({ args = { "\t" }, bang = true })
  end
end

function M.outdent_or_promote()
  local line = vim.api.nvim_get_current_line()
  if line:match("^##+%s") then
    vim.api.nvim_set_current_line(line:gsub("^#", "", 1))
  elseif line:match("^%s+[-*+]%s") or line:match("^%s+%d+%.%s") then
    vim.cmd.normal({ args = { "<<" }, bang = true })
  end
end

function M.fold_all()
  vim.cmd.normal({ args = { "zM" }, bang = true })
end

function M.unfold_all()
  vim.cmd.normal({ args = { "zR" }, bang = true })
end

return M
