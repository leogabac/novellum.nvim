local M = {}

local blink_attached = {}

local function configured_filetypes()
  return require("novellum.config").get().completion.filetypes
end

local function note_candidates(root)
  local notes, err = require("novellum.cache").get_notes(root)
  if err ~= nil then
    return {}
  end

  local seen = {}
  local items = {}

  local function add_item(word, menu, info)
    if seen[word] then
      return
    end
    seen[word] = true
    table.insert(items, {
      word = word,
      abbr = word,
      menu = menu,
      info = info,
      kind = "v",
    })
  end

  for _, note in ipairs(notes) do
    local menu = ("[%s] %s"):format(note.type, note.title)
    add_item(note.id, menu, note.path)
    for _, alias in ipairs(note.aliases or {}) do
      add_item(alias, ("alias of %s • %s"):format(note.id, menu), note.path)
    end
  end

  return items
end

local function base_start(line, col)
  local prefix = line:sub(1, col)
  local with_label = prefix:match(".*\\nvlink%b[]%{()([^}]*)$")
  if with_label ~= nil then
    return with_label
  end
  return prefix:match(".*\\nvlink%{()([^}]*)$")
end

function M.completefunc(findstart, base)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  if findstart == 1 then
    local start = base_start(line, col)
    if start == nil then
      return -3
    end
    return start - 1
  end

  local root = require("novellum.workspace").root_for_buf(0)
  if root == nil then
    return {}
  end

  local lowered = base:lower()
  local matches = {}
  for _, item in ipairs(note_candidates(root)) do
    if lowered == "" or item.word:lower():find("^" .. vim.pesc(lowered)) then
      table.insert(matches, item)
    end
  end
  return matches
end

function M.complete_note_arglead(arglead)
  local root = require("novellum.workspace").root_for_buf(0) or require("novellum.workspace").find_root(vim.uv.cwd())
  if root == nil then
    return {}
  end

  local lowered = (arglead or ""):lower()
  local words = {}
  for _, item in ipairs(note_candidates(root)) do
    if lowered == "" or item.word:lower():find("^" .. vim.pesc(lowered)) then
      table.insert(words, item.word)
    end
  end
  table.sort(words)
  return words
end

local function attach_to_buffer(bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.require'novellum.completion'.completefunc"
end

function M.try_enable_blink()
  if not require("novellum.config").get().completion.blink_integration then
    return
  end

  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    return
  end

  for _, filetype in ipairs(configured_filetypes()) do
    if not blink_attached[filetype] then
      blink.add_filetype_source_provider(filetype, "omni")
      blink_attached[filetype] = true
    end
  end
end

function M.setup()
  if not require("novellum.config").get().completion.enabled then
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("novellum.nvim.completion", { clear = true }),
    pattern = configured_filetypes(),
    callback = function(event)
      if require("novellum.workspace").root_for_buf(event.buf) == nil then
        return
      end
      attach_to_buffer(event.buf)
      M.try_enable_blink()
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = vim.api.nvim_create_augroup("novellum.nvim.blink", { clear = true }),
    callback = function()
      M.try_enable_blink()
    end,
  })
end

return M
