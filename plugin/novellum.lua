if vim.g.loaded_novellum_nvim == 1 then
  return
end
vim.g.loaded_novellum_nvim = 1

require("novellum").setup()
