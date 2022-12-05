local M = {}

-- Construct the build command for the package.
M.build = function(ws, opts, pkg, test_name, test_exe)
  local cmd = {"colcon", "--log-base", ws .. "/log", "build", "--build-base", ws .. "/build", "--install-base", ws .. "/install"}
  if opts.mixins and #opts.mixins > 0 then
    vim.list_extend(cmd, {"--mixin"})
    vim.list_extend(cmd, opts.mixins)
  end
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  if opts.cmake_args and #opts.cmake_args > 0 then
    vim.list_extend(cmd, {"--cmake-args"})
    vim.list_extend(cmd, opts.cmake_args)
  end
  if test_name then
    vim.list_extend(cmd, {"--cmake-target-skip-unavailable", "--packages-select", pkg, "--cmake-target", test_name})
    if test_exe then
      vim.list_extend(cmd, {"&&", test_exe})
    end
  else
    vim.list_extend(cmd, {"--packages-up-to", pkg})
  end
  return table.concat(cmd, " ")
end

M.test = function(ws, opts, pkg)
  local cmd = {"colcon", "--log-base", ws .. "/log", "build", "--build-base", ws .. "/build", "--install-base", ws .. "/install", "--packages-select", pkg}
  table.insert(cmd, "&&")
  vim.list_extend(cmd, {"colcon", "--log-base", ws .. "/log", "test", "--build-base", ws .. "/build", "--install-base", ws .. "/install", "--packages-select", pkg})
  table.insert(cmd, "&&")
  vim.list_extend(cmd, {"colcon", "--log-base", ws .. "/log", "test-result"})
  return table.concat(cmd, " ")
end

M.opts = {
  cmake_args = {},
  mixins = {},
  build = {},
}

return M
