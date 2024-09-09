local M = {}
M.check = function()
  local b = require('ros-builder')
  vim.health.start("ros-buidler.nvim")
  -- make sure setup function parameters are ok
  if b._opts.workspace then
    vim.health.ok("Detected workspace: '" .. b._opts.workspace .. "'")
  else
    vim.health.warn("No workspace detected")
  end
  vim.health.info("Build system: " .. b._opts.build_system)
end
return M
