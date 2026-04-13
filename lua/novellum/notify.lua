local M = {}

local state = {
  ids = {},
}

local function should_notify()
  return require("novellum.config").get().ui.notify
end

local function backend()
  local ok, notify = pcall(require, "notify")
  if ok and type(notify) == "function" then
    return notify, notify
  end
  return vim.notify, nil
end

local function notify_opts(extra)
  return vim.tbl_deep_extend("force", { title = "novellum.nvim" }, extra or {})
end

function M.info(message)
  if not should_notify() then
    return
  end
  local send = backend()
  send(message, vim.log.levels.INFO, notify_opts())
end

function M.warn(message)
  if not should_notify() then
    return
  end
  local send = backend()
  send(message, vim.log.levels.WARN, notify_opts())
end

function M.error(message)
  if not should_notify() then
    return
  end
  local send = backend()
  send(message, vim.log.levels.ERROR, notify_opts())
end

function M.upsert(key, message, level, opts)
  if not should_notify() then
    return nil
  end

  local send = backend()
  local id = send(message, level or vim.log.levels.INFO, notify_opts(vim.tbl_deep_extend("force", {
    replace = state.ids[key],
  }, opts or {})))
  state.ids[key] = id or state.ids[key]
  return state.ids[key]
end

function M.clear(key, message, level, opts)
  if not should_notify() then
    state.ids[key] = nil
    return
  end

  local id = state.ids[key]
  if id == nil then
    return
  end

  local send = backend()
  send(message or " ", level or vim.log.levels.INFO, notify_opts(vim.tbl_deep_extend("force", {
    replace = id,
    timeout = 800,
    hide_from_history = true,
    on_close = function()
      if state.ids[key] == id then
        state.ids[key] = nil
      end
    end,
  }, opts or {})))
end

return M
