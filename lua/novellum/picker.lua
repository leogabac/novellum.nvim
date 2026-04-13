local M = {}

local function get_icon(path)
  local ok_mini, mini_icons = pcall(require, "mini.icons")
  if ok_mini and mini_icons.get then
    local icon, _, _ = mini_icons.get("file", path)
    return icon or ""
  end

  local ok_devicons, devicons = pcall(require, "nvim-web-devicons")
  if ok_devicons and devicons.get_icon then
    local icon = devicons.get_icon(path, nil, { default = true })
    return icon or ""
  end

  return ""
end

local function preview_lines(item)
  if not (item.path and vim.uv.fs_stat(item.path)) then
    return { "Preview unavailable." }
  end

  return vim.fn.readfile(item.path)
end

local function preview_filetype(path)
  local extension = path:match("%.([^.]+)$")
  if extension == "tex" then
    return "tex"
  end
  return extension or ""
end

local function shorten(value, width)
  if vim.fn.strdisplaywidth(value) <= width then
    return value .. string.rep(" ", width - vim.fn.strdisplaywidth(value))
  end
  local shortened = vim.fn.strcharpart(value, 0, math.max(width - 1, 1))
  return shortened .. "…"
end

local function make_note_text(note)
  local icon = get_icon(note.path)
  local aliases = note.aliases and #note.aliases > 0 and ("  {" .. table.concat(note.aliases, ", ") .. "}") or ""
  return ("%s %s  [%s]  %s%s"):format(
    icon,
    shorten(note.id, 20),
    shorten(note.type, 10):gsub("%s+$", ""),
    note.title,
    aliases
  )
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
    local pre_mark_ids = {}
    for _, note_id in ipairs(opts.pre_mark_ids or {}) do
      pre_mark_ids[note_id] = true
    end

    MiniPick.start({
      source = {
        name = opts.name or "Novellum Notes",
        items = function()
          vim.schedule(function()
            if not MiniPick.is_picker_active() then
              return
            end

            local marked = {}
            local current = nil
            for index, item in ipairs(items) do
              if pre_mark_ids[item.note.id] then
                table.insert(marked, index)
              end
              if opts.initial_current_id ~= nil and item.note.id == opts.initial_current_id then
                current = index
              end
            end

            if #marked > 0 then
              MiniPick.set_picker_match_inds(marked, "marked")
            end
            if current ~= nil then
              MiniPick.set_picker_match_inds({ current }, "current")
            end
          end)

          return items
        end,
        choose = function(item, modifier)
          if item == nil or opts.on_choice == nil then
            return
          end
          opts.on_choice(item.note, modifier)
        end,
        preview = function(buf_id, item)
          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, preview_lines(item))
          vim.bo[buf_id].filetype = preview_filetype(item.path)
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
