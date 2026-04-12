local M = {}

local function should_notify()
  return require("novellum.config").get().ui.notify
end

function M.info(message)
  if not should_notify() then
    return
  end
  vim.notify(message, vim.log.levels.INFO, { title = "novellum.nvim" })
end

function M.warn(message)
  if not should_notify() then
    return
  end
  vim.notify(message, vim.log.levels.WARN, { title = "novellum.nvim" })
end

function M.error(message)
  if not should_notify() then
    return
  end
  vim.notify(message, vim.log.levels.ERROR, { title = "novellum.nvim" })
end

return M
