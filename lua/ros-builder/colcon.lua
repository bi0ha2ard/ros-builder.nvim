local M = {}

local h = require("ros-builder.command_building")

-- Construct the build command for the package.
M.build = function(ws, opts, pkg, test_name, test_exe)
  local cmd = h.colcon_base_cmd(opts.colcon, ws, "build")
  h.append_mixins(cmd, opts.mixins)
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  h.append_cmake_args(cmd, opts.cmake_args)
  if test_name then
    vim.list_extend(cmd, { "--cmake-target-skip-unavailable", "--packages-select", pkg, "--cmake-target", test_name })
    if test_exe then
      vim.list_extend(cmd, { "&&", test_exe })
    end
  else
    vim.list_extend(cmd, { "--packages-up-to", pkg })
  end
  return table.concat(cmd, " ")
end

M.test = function(ws, opts, pkg)
  local cmd = h.colcon_base_cmd(opts.colcon, ws, "build")
  h.append_mixins(cmd, opts.mixins)
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  local pkg_arg = { "--packages-select", pkg }
  vim.list_extend(cmd, pkg_arg)
  -- Ensure tests are built
  h.append_cmake_args(cmd, { "-DBUILD_TESTING=ON" })
  vim.list_extend(cmd, opts.cmake_args or {})
  table.insert(cmd, "&&")
  vim.list_extend(cmd, h.colcon_base_cmd(opts.colcon, ws, "test"))
  vim.list_extend(cmd, pkg_arg)
  table.insert(cmd, "&&")
  vim.list_extend(cmd, { opts.colcon, "--log-base", vim.fs.joinpath(ws, "log"), "test-result" })
  return table.concat(cmd, " ")
end

M.opts = {
  colcon = "colcon",
  cmake_args = {},
  mixins = {},
  build = {},
}

return M
