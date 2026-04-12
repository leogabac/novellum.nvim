local M = {}

local function open_in_current(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.open(path, how)
  how = how or require("novellum.config").get().ui.open

  if how == "split" then
    vim.cmd.split()
  elseif how == "vsplit" then
    vim.cmd.vsplit()
  elseif how == "tab" then
    vim.cmd.tabnew()
  end

  open_in_current(path)
end

function M.from_modifier(path, modifier)
  local how = "current"
  if modifier == "split" then
    how = "split"
  elseif modifier == "vsplit" then
    how = "vsplit"
  elseif modifier == "tab split" then
    how = "tab"
  end
  M.open(path, how)
end

return M
