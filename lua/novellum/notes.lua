local M = {}

local function with_notes(root, callback)
  local notes, err = require("novellum.cache").get_notes(root)
  if notes ~= nil then
    callback(nil, notes)
    return
  end

  require("novellum.cache").refresh_notes(root, callback)
end

local function absolute_path(root, note)
  return root .. "/" .. note.path
end

local function open_note(root, note, modifier)
  require("novellum.open").from_modifier(absolute_path(root, note), modifier)
end

local function prompt_query(callback)
  vim.ui.input({ prompt = "Novellum search query: " }, function(input)
    if input == nil or input == "" then
      return
    end
    callback(input)
  end)
end

function M.find(root)
  with_notes(root, function(err, notes)
    if err ~= nil then
      require("novellum.notify").error(err)
      return
    end

    require("novellum.picker").pick_notes(root, notes, {
      name = "Novellum Find",
      on_choice = function(note, modifier)
        open_note(root, note, modifier)
      end,
    })
  end)
end

function M.search(root, query)
  local function run_search(value)
    require("novellum.cli").run_json(root, "search", { value }, function(err, payload)
      if err ~= nil then
        require("novellum.notify").error(err)
        return
      end

      local notes = payload.notes or {}
      if #notes == 0 then
        require("novellum.notify").info("No matching notes found.")
        return
      end

      require("novellum.picker").pick_notes(root, notes, {
        name = ("Novellum Search: %s"):format(value),
        on_choice = function(note, modifier)
          open_note(root, note, modifier)
        end,
      })
    end)
  end

  if query == nil or query == "" then
    prompt_query(run_search)
    return
  end
  run_search(query)
end

function M.open_reference(root, reference)
  if reference == nil or reference == "" then
    M.find(root)
    return
  end

  require("novellum.cli").run_json(root, "show", { reference, "--no-interactive" }, function(err, payload)
    if err ~= nil then
      require("novellum.notify").error(err)
      return
    end
    open_note(root, payload.note)
  end)
end

return M
