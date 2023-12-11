local M = {}

M.build = function(ws, opts, pkg, test_name, test_exe)
  local cmd = { "catkin", "build" }
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  if opts.cmake_args and #opts.cmake_args > 0 then
    table.insert(cmd, "--cmake-args")
    vim.list_extend(cmd, opts.cmake_args)
    table.insert(cmd, "--")
  end
  table.insert(cmd, pkg)
  if test_name then
    vim.list_extend(cmd, { "--no-deps", "--make-args", test_name })
    if test_exe then
      vim.list_extend(cmd, { "&&", test_exe })
    end
  end
  return table.concat(cmd, " ")
end

M.test = function(ws, opts, pkg)
  local cmd = { "catkin", "test", pkg }
  return table.concat(cmd, " ")
end

M.opts = {
  build = {},
}

return M
