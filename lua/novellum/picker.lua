local M = {}

local function make_note_text(note)
  local aliases = note.aliases and #note.aliases > 0 and table.concat(note.aliases, ",") or "-"
  return ("%s\t%s\t%s\t%s"):format(note.id, note.type, note.title, aliases)
end

local function note_item(root, note)
  return {
    text = make_note_text(note),
    path = root .. "/" .. note.path,
    note = note,
  }
end

local function mini_pick_available()
  return pcall(require, "mini.pick")
end

function M.pick_notes(root, notes, opts)
  opts = opts or {}
  local items = vim.tbl_map(function(note)
    return note_item(root, note)
  end, notes)

  if mini_pick_available() then
    local MiniPick = require("mini.pick")
    MiniPick.start({
      source = {
        name = opts.name or "Novellum Notes",
        items = items,
        choose = function(item, modifier)
          if item == nil or opts.on_choice == nil then
            return
          end
          opts.on_choice(item.note, modifier)
        end,
        choose_marked = function(marked)
          if opts.on_choice_marked == nil then
            return
          end
          local selected = vim.tbl_map(function(item)
            return item.note
          end, marked or {})
          opts.on_choice_marked(selected)
        end,
      },
    })
    return
  end

  vim.ui.select(items, {
    prompt = opts.name or "Novellum Notes",
    format_item = function(item)
      return item.text
    end,
  }, function(item)
    if item == nil or opts.on_choice == nil then
      return
    end
    opts.on_choice(item.note)
  end)
end

return M
