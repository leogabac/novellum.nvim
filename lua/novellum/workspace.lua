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

  local root = vim.fs.find(function(name, candidate)
    return name == ".novellum" and path_exists(candidate .. "/config.toml")
  end, { upward = true, path = path, type = "directory" })[1]

  if root == nil then
    return nil
  end
  return vim.fs.dirname(root)
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
