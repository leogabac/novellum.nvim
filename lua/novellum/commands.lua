local M = {}

local function complete_notes(arglead)
  return require("novellum.completion").complete_note_arglead(arglead)
end

local function complete_document_targets(arglead)
  local targets = { "workspace", "stitched" }
  return vim.tbl_filter(function(item)
    return arglead == nil or arglead == "" or item:find("^" .. vim.pesc(arglead))
  end, targets)
end

local function complete_stitch_args(arglead)
  local items = complete_notes(arglead)
  local flags = {
    "--all",
    "--concepts",
    "--proofs",
    "--papers",
    "--experiments",
    "--questions",
    "--logs",
    "--refs",
    "--title",
    "--output",
  }
  for _, flag in ipairs(flags) do
    if arglead == nil or arglead == "" or flag:find("^" .. vim.pesc(arglead)) then
      table.insert(items, flag)
    end
  end
  return items
end

local function with_root(fn)
  return function(opts)
    local root = require("novellum.workspace").require_root(0)
    if root == nil then
      return
    end
    fn(root, opts or {})
  end
end

function M.setup()
  vim.api.nvim_create_user_command("NovellumHealth", function()
    vim.cmd.checkhealth("novellum")
  end, {})

  vim.api.nvim_create_user_command("NovellumFind", with_root(function(root)
    require("novellum.notes").find(root)
  end), {})

  vim.api.nvim_create_user_command("NovellumSearch", with_root(function(root, opts)
    require("novellum.notes").search(root, opts.args)
  end), { nargs = "?" })

  vim.api.nvim_create_user_command("NovellumOpenNote", with_root(function(root, opts)
    require("novellum.notes").open_reference(root, opts.args)
  end), { nargs = "?", complete = complete_notes })

  vim.api.nvim_create_user_command("NovellumStitch", with_root(function(root, opts)
    require("novellum.documents").stitch(root, opts.fargs)
  end), { nargs = "*", complete = complete_stitch_args })

  vim.api.nvim_create_user_command("NovellumCompile", with_root(function(root, opts)
    require("novellum.documents").compile(root, opts.args)
  end), { nargs = "?", complete = complete_document_targets })

  vim.api.nvim_create_user_command("NovellumOpen", with_root(function(root, opts)
    require("novellum.documents").open_pdf(root, opts.args)
  end), { nargs = "?", complete = complete_document_targets })

  vim.api.nvim_create_user_command("NovellumRefresh", with_root(function(root)
    require("novellum.cache").refresh_notes(root, function(err, notes)
      if err ~= nil then
        require("novellum.notify").error(err)
        return
      end
      require("novellum.notify").info(("Refreshed %d notes."):format(#notes))
    end)
  end), {})
end

return M
