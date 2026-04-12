local M = {}

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
