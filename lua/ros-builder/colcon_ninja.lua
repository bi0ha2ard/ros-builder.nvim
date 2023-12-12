local M = {}

local h = require("ros-builder.command_building")

local build_upstream = function(ws, opts, pkg)
  local cmd = h.colcon_base_cmd(opts.colcon, ws, "build")
  h.append_mixins(cmd, opts.mixins)
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  h.append_cmake_args(cmd, { "-GNinja", "-DBUILD_TESTING=OFF" })
  vim.list_extend(cmd, opts.cmake_args or {})
  vim.list_extend(cmd, { "--packages-up-to", pkg, "--packages-skip", pkg })
  return cmd
end

local build_current = function(ws, opts, pkg)
  local cmd = h.colcon_base_cmd(opts.colcon, ws, "build")
  h.append_mixins(cmd, opts.mixins)
  -- ensure we see something
  vim.list_extend(cmd, { "--event-handlers", "console_cohesion+" })
  if opts.build then
    vim.list_extend(cmd, opts.build)
  end
  h.append_cmake_args(cmd, { "-GNinja", "-DBUILD_TESTING=ON" })
  vim.list_extend(cmd, opts.cmake_args or {})
  vim.list_extend(cmd, { "--packages-select", pkg })
  return cmd
end

-- Build the target directly with ninja
local build_and_test = function(ws, opts, pkg, test_name, test_exe)
  local cmd = { "ninja", "-C", vim.fs.joinpath(ws, "build", pkg), test_name }
  if test_exe then
    table.insert(cmd, h.append_with_message(h.divider("Executing '" .. test_exe .. "'...")))
    table.insert(cmd, test_exe)
  end
  return table.concat(cmd, " ")
end

-- Construct the build command for the package.
M.build = function(ws, opts, pkg, test_name, test_exe)
  if test_name then
    -- just builds the selected test and potentially runs it
    return build_and_test(ws, opts, pkg, test_name, test_exe)
  end
  -- builds current package, including tests
  local cmd = build_upstream(ws, opts, pkg)
  table.insert(cmd, h.append_with_message(h.divider("Building '" .. pkg .. "'...")))
  vim.list_extend(cmd, build_current(ws, opts, pkg))
  return table.concat(cmd, " ")
end

-- Test entire package
-- Note: doesn't build upstream
M.test = function(ws, opts, pkg)
  local cmd = build_current(ws, opts, pkg)
  table.insert(cmd, h.append_with_message(h.divider("Testing '" .. pkg .. "'...")))
  vim.list_extend(cmd, h.colcon_base_cmd(opts.colcon, ws, "test"))
  vim.list_extend(cmd, { "--packages-select", pkg })
  table.insert(cmd, h.append_with_message({ "", "Test results for '" .. pkg .. "':" }))
  vim.list_extend(cmd,
  { opts.colcon, "--log-base", vim.fs.joinpath(ws, "log"), "test-result", "--test-result-base",
    vim.fs.joinpath(ws, "build", pkg), "--all" })
  return table.concat(cmd, " ")
end

M.opts = {
  colcon = "colcon",
  cmake_args = {},
  mixins = {},
  build = {},
}

return M
