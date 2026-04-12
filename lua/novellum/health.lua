local M = {}

function M.check()
  vim.health.start("novellum.nvim")

  local config = require("novellum.config").get()
  local command = type(config.command) == "table" and config.command[1] or config.command
  local novellum = vim.fn.executable(command) == 1
  if novellum then
    vim.health.ok(("Found novellum executable: %s"):format(command))
  else
    vim.health.error(("Could not find novellum executable: %s"):format(command))
  end

  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim 0.12+ available")
  else
    vim.health.error("novellum.nvim requires Neovim 0.12+")
  end

  local ok_pick = pcall(require, "mini.pick")
  if ok_pick then
    vim.health.ok("mini.pick available")
  else
    vim.health.warn("mini.pick not available; picker workflows will fall back to vim.ui.select")
  end

  local ok_blink = pcall(require, "blink.cmp")
  if ok_blink then
    vim.health.ok("blink.cmp available")
  else
    vim.health.info("blink.cmp not available; omnifunc completion still works")
  end

  local root = require("novellum.workspace").root_for_buf(0)
  if root then
    vim.health.ok(("Workspace detected: %s"):format(root))
  else
    vim.health.info("Current buffer is not inside a novellum workspace")
  end
end

return M
