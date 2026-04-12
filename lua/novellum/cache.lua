local M = {}

local state = {
  notes = {},
}

local function cache_key(root)
  return vim.fs.normalize(root)
end

function M.invalidate(root)
  if root == nil then
    state.notes = {}
    return
  end
  state.notes[cache_key(root)] = nil
end

function M.get_notes(root)
  local cached = state.notes[cache_key(root)]
  if cached then
    return cached
  end

  local payload, err = require("novellum.cli").run_json_sync(root, "list", {})
  if err ~= nil then
    return nil, err
  end

  local notes = payload.notes or {}
  state.notes[cache_key(root)] = notes
  return notes
end

function M.refresh_notes(root, callback)
  require("novellum.cli").run_json(root, "list", {}, function(err, payload)
    if err ~= nil then
      callback(err)
      return
    end

    local notes = payload.notes or {}
    state.notes[cache_key(root)] = notes
    callback(nil, notes)
  end)
end

return M
