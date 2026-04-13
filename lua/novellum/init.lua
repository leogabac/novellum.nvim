local M = {}

local initialized = false

function M.setup(opts)
  require("novellum.config").setup(opts)

  if initialized then
    return
  end
  initialized = true

  require("novellum.commands").setup()
  require("novellum.completion").setup()
  require("novellum.build").setup()
end

return M
