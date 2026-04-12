local M = {}

local uv = vim.uv

local function path_exists(path)
  return uv.fs_stat(path) ~= nil
end

local function is_workspace_root(path)
  return path_exists(path .. "/.novellum") and path_exists(path .. "/.novellum/config.toml")
end

function M.find_root(start_path)
  local path = start_path
  if path == nil or path == "" then
    path = uv.cwd()
  end

  path = vim.fs.normalize(path)
  local stat = uv.fs_stat(path)
  if stat and stat.type ~= "directory" then
    path = vim.fs.dirname(path)
  end

  local current = path
  while current and current ~= "" do
    if is_workspace_root(current) then
      return current
    end

    local parent = vim.fs.dirname(current)
    if parent == current then
      break
    end
    current = parent
  end

  return nil
end

function M.root_for_buf(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return M.find_root(uv.cwd())
  end
  return M.find_root(name)
end

function M.require_root(bufnr)
  local root = M.root_for_buf(bufnr)
  if root ~= nil then
    return root
  end

  require("novellum.notify").warn("Not inside a novellum workspace.")
  return nil
end

function M.is_workspace(path)
  if path == nil or path == "" then
    return false
  end
  return is_workspace_root(vim.fs.normalize(path))
end

return M
