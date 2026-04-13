local M = {}

local state = {
  session = nil,
  running = false,
  pending = false,
  watch_enabled = false,
  timer = nil,
}

local function is_note_buffer(root, path)
  if path == nil or path == "" then
    return false
  end

  local normalized = vim.fs.normalize(path)
  local notes_root = vim.fs.normalize(root .. "/notes/")
  return normalized:find("^" .. vim.pesc(notes_root)) ~= nil and normalized:match("%.tex$") ~= nil
end

local function ensure_timer()
  if state.timer == nil then
    state.timer = vim.uv.new_timer()
  end
  return state.timer
end

local function stop_timer()
  if state.timer ~= nil then
    state.timer:stop()
  end
end

function M.set_session(session)
  state.session = vim.deepcopy(session)
end

function M.get_session()
  return state.session and vim.deepcopy(state.session) or nil
end

function M.has_session()
  return state.session ~= nil
end

function M.watch_enabled()
  return state.watch_enabled
end

function M.start_watch()
  if state.session == nil then
    require("novellum.notify").warn("No Novellum build session recorded yet.")
    return false
  end
  state.watch_enabled = true
  require("novellum.notify").info("Novellum auto build enabled.")
  return true
end

function M.stop_watch()
  state.watch_enabled = false
  state.pending = false
  stop_timer()
  require("novellum.notify").info("Novellum auto build disabled.")
end

function M.status()
  local session = state.session
  if session == nil then
    return "No build session."
  end

  local args = table.concat(session.stitch_args or {}, " ")
  local watch = state.watch_enabled and "on" or "off"
  local running = state.running and "running" or "idle"
  return ("watch=%s state=%s target=%s args=%s"):format(watch, running, session.compile_target or "stitched", args)
end

function M.run_now()
  local session = state.session
  if session == nil then
    require("novellum.notify").warn("No Novellum build session recorded yet.")
    return
  end

  if state.running then
    state.pending = true
    return
  end

  state.running = true
  require("novellum.notify").info("Rebuilding last Novellum stitch...")
  require("novellum.documents").run_session(session, function(ok)
    state.running = false
    if state.pending then
      state.pending = false
      M.run_now()
      return
    end

    if ok then
      require("novellum.notify").info("Novellum rebuild finished.")
    end
  end)
end

function M.schedule_from_buffer(bufnr)
  local session = state.session
  if not state.watch_enabled or session == nil then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if not is_note_buffer(session.root, path) then
    return
  end

  local timer = ensure_timer()
  timer:stop()
  timer:start(require("novellum.config").get().documents.debounce_ms, 0, vim.schedule_wrap(function()
    M.run_now()
  end))
end

function M.setup()
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("novellum.nvim.build", { clear = true }),
    callback = function(event)
      M.schedule_from_buffer(event.buf)
    end,
  })
end

return M
