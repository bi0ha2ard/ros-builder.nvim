local M = {}

local colcon_base_cmd = function(ws, verb)
  return { "colcon",
    "--log-base", vim.fs.joinpath(ws, "log"), verb,
    "--build-base", vim.fs.joinpath(ws, "build"),
    "--install-base", vim.fs.joinpath(ws, "install")
  }
end

local append_mixins = function(cmd, mixins)
  if mixins and #mixins > 0 then
    vim.list_extend(cmd, { "--mixin" })
    vim.list_extend(cmd, mixins)
  end
end

local append_cmake_args = function(cmd, cmake)
  if cmake and #cmake > 0 then
    vim.list_extend(cmd, { "--cmake-args" })
    vim.list_extend(cmd, cmake)
  end
end

-- Construct the build command for the package.
M.build = function(ws, opts, pkg, test_name, test_exe)
  local cmd = colcon_base_cmd(ws, "build")
  append_mixins(cmd, opts.mixins)
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  append_cmake_args(cmd, opts.cmake_args)
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
  local cmd = colcon_base_cmd(ws, "build")
  append_mixins(cmd, opts.mixins)
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  local pkg_arg = { "--packages-select", pkg }
  vim.list_extend(cmd, pkg_arg)
  -- Ensure tests are built
  local cmake_args = { "-DBUILD_TESTING=ON" }
  vim.list_extend(cmake_args, opts.cmake_args or {})
  append_cmake_args(cmd, cmake_args)
  table.insert(cmd, "&&")
  vim.list_extend(cmd, colcon_base_cmd(ws, "test"))
  vim.list_extend(cmd, pkg_arg)
  table.insert(cmd, "&&")
  vim.list_extend(cmd, { "colcon", "--log-base", vim.fs.joinpath(ws, "log"), "test-result" })
  return table.concat(cmd, " ")
end

M.opts = {
  cmake_args = {},
  mixins = {},
  build = {},
}

return M
