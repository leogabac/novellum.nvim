local M = {}

local defaults = {
  command = { "novellum" },
  picker = {
    backend = "mini.pick",
  },
  ui = {
    notify = true,
    open = "current",
  },
  documents = {
    open_after_stitch = false,
    quickfix_on_compile_error = true,
  },
  completion = {
    enabled = true,
    filetypes = { "tex", "plaintex" },
    blink_integration = true,
  },
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M
