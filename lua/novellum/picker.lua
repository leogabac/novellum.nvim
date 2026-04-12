local M = {}

local function preview_lines(item)
  local note = item.note
  local lines = {
    ("# %s"):format(note.title),
    "",
    ("id: %s"):format(note.id),
    ("type: %s"):format(note.type),
    ("path: %s"):format(note.path),
    ("tags: %s"):format(#(note.tags or {}) > 0 and table.concat(note.tags, ", ") or "-"),
    ("aliases: %s"):format(#(note.aliases or {}) > 0 and table.concat(note.aliases, ", ") or "-"),
    "",
    "---",
    "",
  }

  local path = item.path
  if path and vim.uv.fs_stat(path) then
    local content = table.concat(vim.fn.readfile(path), "\n")
    local body_lines = vim.split(content, "\n", { trimempty = false })
    for index = 1, math.min(#body_lines, 40) do
      table.insert(lines, body_lines[index])
    end
    if #body_lines > 40 then
      table.insert(lines, "")
      table.insert(lines, "... truncated ...")
    end
  else
    table.insert(lines, "Preview unavailable.")
  end

  return lines
end

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
        preview = function(buf_id, item)
          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, preview_lines(item))
          vim.bo[buf_id].filetype = "markdown"
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
